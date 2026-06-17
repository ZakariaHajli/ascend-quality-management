{#-
    SELF-SERVE STAGING GENERATOR (Data Mesh Principle 3).
    Standardised staging in one call: dedup to latest change per business key, trim strings,
    append source metadata. Accepts EITHER a declared source (source_name + table_name) OR a
    pre-resolved relation (e.g. ref() to a seed) — the latter is environment-aware for free.

        {{ generate_staging(relation=ref('example_source'), business_key='entity_code') }}
        {{ generate_staging('sap', 'aufk', business_key='aufnr') }}
-#}
{% macro generate_staging(source_name=none, table_name=none, relation=none, business_key=none, change_col='glchangetime') %}

{%- set source_rel = relation if relation is not none else source(source_name, table_name) -%}
{%- set bk = business_key if business_key is string else business_key | join(', ') -%}

with source as (
    select * from {{ source_rel }}
),

trimmed as (
    select
        {%- if execute %}
        {%- set cols = adapter.get_columns_in_relation(source_rel) %}
        {%- for c in cols %}
        {% if c.is_string() %}trim({{ c.name }}){% else %}{{ c.name }}{% endif %} as {{ c.name }}{{ "," if not loop.last }}
        {%- endfor %}
        {%- else %}
        *
        {%- endif %}
    from source
),

staged as (
    select
        trimmed.*,
        'sap'                    as source_system,
        {{ sap_change_timestamp(change_col) }} as sync_datetime
    from trimmed
    qualify row_number() over (
        partition by {{ bk }}
        order by {{ change_col }} desc nulls last
    ) = 1
)

select * from staged

{% endmacro %}
