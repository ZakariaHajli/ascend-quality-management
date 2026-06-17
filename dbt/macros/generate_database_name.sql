{#-
    ENVIRONMENT ROUTING.
    Every node is routed to the database <TARGET>_<domain_database_base>, so the same code
    builds DEV_<DOMAIN> / UAT_<DOMAIN> / PROD_<DOMAIN> depending only on `dbt --target`.
    Layer separation is by schema (RAW/STG/DSO/DPA/SNAPSHOTS via generate_schema_name).
-#}
{% macro generate_database_name(custom_database_name=none, node=none) -%}
    {{ (target.name ~ '_' ~ var('domain_database_base')) | upper }}
{%- endmacro %}
