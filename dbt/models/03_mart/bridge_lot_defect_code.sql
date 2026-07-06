{{
    config(
        materialized='table',
        access='public',
        contract={'enforced': true}
    )
}}

/*
    BRIDGE TABLE (Kimball multi-valued dimension): an inspection lot carries MANY defect codes.
    The bridge assigns each (lot, defect code) pair an allocation_factor — the code's share of
    the lot's total defect quantity, summing to 1.0 per lot — so measures can be spread across
    defect codes WITHOUT fan-out double counting:

        fct ⨝ bridge (on inspection_lot_sid) ⨝ dim_defect_code, weight by allocation_factor.

    Perimeter is inherited from dim_inspection_lot (inner join), like every fact.
*/

with defects as (
    select * from {{ ref('defect') }}
),

perimeter as (
    select inspection_lot_sid, inspection_lot_number
    from {{ ref('dim_inspection_lot') }}
),

in_scope as (
    select
        p.inspection_lot_sid,
        {{ generate_integer_surrogate_key(['d.code_group', 'd.defect_code']) }} as defect_code_sid,
        d.defect_quantity
    from defects d
    inner join perimeter p on d.inspection_lot_number = p.inspection_lot_number
),

weighted as (
    select
        inspection_lot_sid,
        defect_code_sid,
        sum(defect_quantity) as defect_quantity,
        sum(defect_quantity) / nullif(sum(sum(defect_quantity)) over (partition by inspection_lot_sid), 0)
            as allocation_factor
    from in_scope
    group by inspection_lot_sid, defect_code_sid
)

select
    cast(inspection_lot_sid as number(38,0)) as inspection_lot_sid,
    cast(defect_code_sid as number(38,0))    as defect_code_sid,
    cast(defect_quantity as number(38,0))    as defect_quantity,
    cast(allocation_factor as float)         as allocation_factor
from weighted
