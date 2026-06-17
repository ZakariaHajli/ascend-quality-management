{#-
    ACCESS POLICY (component A), environment-aware.
    Mart post-hook: GRANT SELECT to <DOMAIN>_CONSUMER_<TARGET> — the per-environment BI role
    provisioned by Terraform. No env var needed; it follows --target.
-#}
{% macro grant_select_to_consumer() -%}
    {%- set consumer_role = (var('domain_database_base') ~ '_CONSUMER_' ~ target.name) | upper -%}
    grant select on {{ this }} to role {{ consumer_role }}
{%- endmacro %}
