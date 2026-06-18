{#-
    Quality-domain self-serve macros. Centralising these guarantees every model computes
    in-spec status and PPM identically (no metric drift — the thesis's semantic-consistency point).
-#}

{# TRUE when a measured value lies within [lsl, usl] inclusive. #}
{% macro is_in_spec(measured, lsl, usl) -%}
    ({{ measured }} >= {{ lsl }} and {{ measured }} <= {{ usl }})
{%- endmacro %}

{# Defects per million: defects / units * 1e6, null-safe. #}
{% macro ppm(defects, units) -%}
    iff({{ units }} > 0, ({{ defects }} * 1000000.0) / {{ units }}, null)
{%- endmacro %}
