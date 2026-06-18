{{
    config(
        materialized='table',
        access='public'
    )
}}

with characteristic as (
    select * from {{ ref('characteristic') }}
)

select
    {{ generate_integer_surrogate_key(['characteristic_code']) }} as characteristic_sid,
    characteristic_code,
    characteristic_name,
    target_value,
    lower_spec_limit,
    upper_spec_limit,
    unit
from characteristic
