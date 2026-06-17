{#-
    DETERMINISTIC SURROGATE IDENTITY.
    A surrogate key that is a pure function of the normalised natural key
    (trim -> upper -> coalesce -> MD5_NUMBER_UPPER64). Stable across rebuilds; integer joins.

        {{ generate_integer_surrogate_key(['entity_code']) }} as example_entity_sid
-#}
{% macro generate_integer_surrogate_key(columns) -%}
    md5_number_upper64(
        concat_ws('||'
        {%- for c in columns -%}
            , coalesce(trim(upper(cast({{ c }} as varchar))), '«null»')
        {%- endfor -%}
        )
    )
{%- endmacro %}
