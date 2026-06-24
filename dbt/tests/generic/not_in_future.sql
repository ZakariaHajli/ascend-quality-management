{#-
    Custom GENERIC test (reusable, framework-extending): asserts a date/timestamp column is not
    in the future. Use in YAML as:  data_tests: [not_in_future]
-#}
{% test not_in_future(model, column_name) %}

select {{ column_name }} as offending_value
from {{ model }}
where {{ column_name }} > current_date

{% endtest %}
