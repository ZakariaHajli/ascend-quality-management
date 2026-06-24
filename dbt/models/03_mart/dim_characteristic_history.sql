{{
    config(
        materialized='table',
        access='public'
    )
}}

-- TYPE-2 (SCD2) characteristic dimension: one row per (characteristic, version) with
-- valid_from/valid_to and an is_current flag. Consumed by the ASOF point-in-time join.

with hist as (
    select * from {{ ref('characteristic_history') }}
)

select
    {{ generate_integer_surrogate_key(['characteristic_code', 'version']) }} as characteristic_version_sid,
    {{ generate_integer_surrogate_key(['characteristic_code']) }}            as characteristic_sid,
    characteristic_code,
    version,
    valid_from,
    valid_to,
    iff(current_date between valid_from and valid_to, true, false)           as is_current,
    target_value,
    lower_spec_limit,
    upper_spec_limit,
    unit
from hist
