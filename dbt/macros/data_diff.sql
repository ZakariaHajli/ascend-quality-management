{% macro audit_data_products(models=[]) %}
  {#-
    DATA DIFF (PR impact analysis).
    For each given mart model, compare its CURRENT-target build (e.g. the dev PR build) against
    its UAT baseline (what is live on `main`) using a full-row HASH(*):
      • column-agnostic — no primary key needed;
      • a changed value flips the row hash, so it counts in BOTH "added_or_changed"
        (rows in current not matching any baseline row) and "removed_or_changed"
        (baseline rows not matching any current row);
      • a schema change makes every row's hash differ (correctly flagged as high impact).
    Emits a single-line JSON payload between markers for the CI step to render into the PR comment.
  -#}
  {% if not execute %}{% do return(none) %}{% endif %}
  {% set base_db = ('UAT_' ~ var('domain_database_base')) | upper %}
  {% set out = [] %}
  {% for m in models %}
    {% set dev_rel = ref(m) %}
    {% set uat_rel = api.Relation.create(database=base_db, schema=dev_rel.schema, identifier=dev_rel.identifier) %}
    {% set baseline = adapter.get_relation(database=uat_rel.database, schema=uat_rel.schema, identifier=uat_rel.identifier) %}
    {% if baseline is none %}
      {% set qn %}select count(*) as c from {{ dev_rel }}{% endset %}
      {% set rn = run_query(qn) %}
      {% set after = rn.rows[0][0] %}
      {% do out.append({'model': m, 'status': 'new', 'rows_before': 0, 'rows_after': after,
                        'added_or_changed': after, 'removed_or_changed': 0}) %}
    {% else %}
      {% set q %}
        with base as (select hash(*) as _h from {{ uat_rel }}),
             curr as (select hash(*) as _h from {{ dev_rel }})
        select
          (select count(*) from base) as rows_before,
          (select count(*) from curr) as rows_after,
          (select count(*) from curr where _h not in (select _h from base)) as added_or_changed,
          (select count(*) from base where _h not in (select _h from curr)) as removed_or_changed
      {% endset %}
      {% set r = run_query(q) %}
      {% set row = r.rows[0] %}
      {% do out.append({'model': m, 'status': 'changed', 'rows_before': row[0], 'rows_after': row[1],
                        'added_or_changed': row[2], 'removed_or_changed': row[3]}) %}
    {% endif %}
  {% endfor %}
  {% do log('ASCEND_DATA_DIFF_JSON_BEGIN' ~ tojson(out) ~ 'ASCEND_DATA_DIFF_JSON_END', info=true) %}
{% endmacro %}
