{#
    ACTIVE SCD2 — tracks historical changes to a characteristic's target/spec limits, so
    in-spec evaluations can be reconciled against the limits that were valid at inspection time.
    'check' strategy opens a new version whenever a spec column changes (dbt_valid_from/to).
#}
{% snapshot characteristic_snapshot %}

{{
    config(
        unique_key='characteristic_code',
        strategy='check',
        check_cols=['target_value', 'lower_spec_limit', 'upper_spec_limit']
    )
}}

select
    characteristic_code,
    characteristic_name,
    target_value,
    lower_spec_limit,
    upper_spec_limit,
    unit
from {{ ref('characteristic') }}

{% endsnapshot %}
