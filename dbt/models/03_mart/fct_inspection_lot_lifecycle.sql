{{
    config(
        materialized='table',
        access='public',
        contract={'enforced': true}
    )
}}

/*
    ACCUMULATING SNAPSHOT fact (advanced Kimball) — one row per inspection lot, carrying its
    lifecycle milestones (created -> usage decision) and the lag/age metrics that accumulate as
    the lot progresses, plus a rollup of its defects. Inner join to dim_inspection_lot inherits
    the perimeter.
*/

with lots as (
    select * from {{ ref('dim_inspection_lot') }}
),

defect_agg as (
    select
        inspection_lot_number,
        sum(defect_quantity) as total_defect_quantity,
        count(*)             as defect_line_count
    from {{ ref('defect') }}
    group by inspection_lot_number
),

dim_order as (
    select production_order_sid, production_order_number from {{ ref('dim_production_order') }}
)

select
    cast(lots.inspection_lot_sid as number)                                     as inspection_lot_sid,
    cast(dim_order.production_order_sid as number)                              as production_order_sid,
    cast(lots.inspection_lot_number as varchar)                                 as inspection_lot_number,
    cast(lots.material_number as varchar)                                       as material_number,
    cast(lots.lot_status as varchar)                                            as lot_status,
    cast(lots.lot_creation_date as date)                                        as created_date,
    cast(lots.usage_decision_date as date)                                      as decision_date,
    cast(datediff(day, lots.lot_creation_date, lots.usage_decision_date) as number) as days_to_decision,
    cast(datediff(day, lots.lot_creation_date, current_date) as number)         as lot_age_days,
    cast(lots.is_accepted as boolean)                                           as is_accepted,
    cast(lots.is_rejected as boolean)                                           as is_rejected,
    cast(coalesce(defect_agg.total_defect_quantity, 0) as number)               as total_defect_quantity,
    cast(coalesce(defect_agg.defect_line_count, 0) as number)                   as defect_line_count
from lots
left join defect_agg on lots.inspection_lot_number = defect_agg.inspection_lot_number
left join dim_order  on lots.production_order_number = dim_order.production_order_number
