{{
    config(
        materialized='table',
        access='public'
    )
}}

-- Defect-grain fact for Pareto analysis (defect quantity by code / group / order).
-- Inner join to dim_inspection_lot inherits the perimeter; dimension keys are deterministic.

with defects as (
    select * from {{ ref('defect') }}
),

dim_lot as (
    select inspection_lot_sid, inspection_lot_number from {{ ref('dim_inspection_lot') }}
),

dim_code as (
    select defect_code_sid, defect_code, code_group from {{ ref('dim_defect_code') }}
),

dim_order as (
    select production_order_sid, production_order_number from {{ ref('dim_production_order') }}
)

select
    dim_lot.inspection_lot_sid,
    dim_code.defect_code_sid,
    dim_order.production_order_sid,
    defects.notification_number,
    defects.defect_item_number,
    defects.defect_code,
    defects.code_group,
    defects.defect_description,
    defects.defect_quantity,
    defects.notification_date
from defects
join dim_lot   on defects.inspection_lot_number = dim_lot.inspection_lot_number
left join dim_code  on defects.code_group = dim_code.code_group and defects.defect_code = dim_code.defect_code
left join dim_order on defects.production_order_number = dim_order.production_order_number
