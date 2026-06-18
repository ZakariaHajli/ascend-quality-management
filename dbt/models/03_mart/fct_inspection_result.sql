{{
    config(
        materialized='table',
        access='public',
        contract={'enforced': true}
    )
}}

-- Transaction-grain fact: one row per (inspection lot x characteristic). Inner join to
-- dim_inspection_lot inherits the perimeter (Pattern 4); keys are deterministic (Pattern 5).

with results as (
    select * from {{ ref('inspection_result') }}
),

dim_lot as (
    select inspection_lot_sid, inspection_lot_number from {{ ref('dim_inspection_lot') }}
)

select
    cast(dim_lot.inspection_lot_sid as number)                              as inspection_lot_sid,
    cast({{ generate_integer_surrogate_key(['results.characteristic_code']) }} as number) as characteristic_sid,
    cast(results.inspection_lot_number as varchar)                          as inspection_lot_number,
    cast(results.characteristic_code as varchar)                            as characteristic_code,
    cast(results.measured_value as float)                                   as measured_value,
    cast(results.target_value as float)                                     as target_value,
    cast(results.lower_spec_limit as float)                                 as lower_spec_limit,
    cast(results.upper_spec_limit as float)                                 as upper_spec_limit,
    cast(results.deviation_from_target as float)                            as deviation_from_target,
    cast(results.is_in_spec as boolean)                                     as is_in_spec
from results
join dim_lot on results.inspection_lot_number = dim_lot.inspection_lot_number
