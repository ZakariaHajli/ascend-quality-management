{#-
    Use the configured +schema as-is (RAW / STG / DSO / DPA / SNAPSHOTS) within the
    environment database chosen by generate_database_name.
-#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim | upper }}
    {%- endif -%}
{%- endmacro %}
