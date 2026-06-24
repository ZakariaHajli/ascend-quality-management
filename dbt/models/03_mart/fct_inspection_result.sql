{{
    config(
        materialized='table',
        access='public',
        cluster_by=['inspection_date'],
        contract={'enforced': true}
    )
}}

/*
    Characteristic-result fact with BI-TEMPORAL point-in-time correctness (thesis Pattern 2 / axis B2).
      • Perimeter inherited via inner join to dim_inspection_lot (Pattern 4).
      • ASOF JOIN to the Type-2 spec history selects the spec version valid AT the inspection date,
        so is_in_spec reflects the limits in force then — not today's limits.
      • is_in_spec_current re-evaluates against the current spec; verdict_differs flags rows whose
        conformance verdict changed because the spec was revised (e.g. a tightened tolerance).
      • cluster_by(inspection_date) prunes time-scoped scans.
*/

with results as (
    select * from {{ ref('inspection_result') }}
),

dim_lot as (
    select inspection_lot_sid, inspection_lot_number, lot_creation_date from {{ ref('dim_inspection_lot') }}
),

spec_history as (
    select characteristic_code, valid_from, lower_spec_limit as eff_lsl, upper_spec_limit as eff_usl
    from {{ ref('dim_characteristic_history') }}
),

current_spec as (
    select characteristic_code, lower_spec_limit as cur_lsl, upper_spec_limit as cur_usl
    from {{ ref('dim_characteristic') }}
),

-- perimeter inner join; carry the inspection date (lot creation) as the as-of anchor
base as (
    select
        dim_lot.inspection_lot_sid,
        results.inspection_lot_number,
        results.characteristic_code,
        dim_lot.lot_creation_date as inspection_date,
        results.measured_value
    from results
    join dim_lot on results.inspection_lot_number = dim_lot.inspection_lot_number
),

-- PATTERN 2: spec valid as of the inspection date
as_of as (
    select base.*, h.eff_lsl, h.eff_usl
    from base
    asof join spec_history h
        match_condition (base.inspection_date >= h.valid_from)
        on base.characteristic_code = h.characteristic_code
),

evaluated as (
    select
        as_of.*,
        current_spec.cur_lsl,
        current_spec.cur_usl,
        {{ is_in_spec('as_of.measured_value', 'as_of.eff_lsl', 'as_of.eff_usl') }} as in_spec_asof,
        {{ is_in_spec('as_of.measured_value', 'current_spec.cur_lsl', 'current_spec.cur_usl') }} as in_spec_current
    from as_of
    left join current_spec on as_of.characteristic_code = current_spec.characteristic_code
)

select
    cast(inspection_lot_sid as number)                                          as inspection_lot_sid,
    cast({{ generate_integer_surrogate_key(['characteristic_code']) }} as number) as characteristic_sid,
    cast(inspection_lot_number as varchar)                                      as inspection_lot_number,
    cast(characteristic_code as varchar)                                        as characteristic_code,
    cast(inspection_date as date)                                               as inspection_date,
    cast(measured_value as float)                                               as measured_value,
    cast(eff_lsl as float)                                                      as effective_lower_spec_limit,
    cast(eff_usl as float)                                                      as effective_upper_spec_limit,
    cast(cur_lsl as float)                                                      as current_lower_spec_limit,
    cast(cur_usl as float)                                                      as current_upper_spec_limit,
    cast(in_spec_asof as boolean)                                               as is_in_spec,
    cast(in_spec_current as boolean)                                            as is_in_spec_current,
    cast((in_spec_asof and not in_spec_current) or (not in_spec_asof and in_spec_current) as boolean) as verdict_differs
from evaluated
