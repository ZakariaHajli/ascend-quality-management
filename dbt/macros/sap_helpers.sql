{#-
    CDC timestamp helpers. The platform convention is a change column 'glchangetime' in the
    SAP format 'YYYYMMDDHH24MISS.FF9'. Adapt these if your source uses a different format.
-#}

{% macro sap_change_timestamp(col) -%}
    try_to_timestamp_ntz(cast({{ col }} as varchar), 'YYYYMMDDHH24MISS.FF9')
{%- endmacro %}

{% macro sap_date(col) -%}
    try_to_date(nullif(cast({{ col }} as varchar), '00000000'), 'YYYYMMDD')
{%- endmacro %}

{% macro sap_datetime(date_col, time_col) -%}
    try_to_timestamp_ntz(
        nullif(cast({{ date_col }} as varchar), '00000000')
            || lpad(coalesce(cast({{ time_col }} as varchar), '0'), 6, '0'),
        'YYYYMMDDHH24MISS'
    )
{%- endmacro %}
