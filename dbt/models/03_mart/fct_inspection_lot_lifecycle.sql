{{
    config(
        materialized='incremental',
        unique_key='inspection_lot_sid',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns',
        cluster_by=['created_date'],
        access='public'
    )
}}

/*
    ACCUMULATING SNAPSHOT, incrementally merged (advanced Kimball + robust incremental).
    One row per lot; as a lot progresses (created -> usage decision) its milestone/lag columns
    are UPDATED in place via merge on inspection_lot_sid. Sourced from the change-tracked
    intermediate (inspection_lot.sync_datetime) with a 3-day lookback; the inner join to
    dim_inspection_lot inherits the perimeter. cluster_by(created_date) prunes time-scoped scans.
*/

with lots as (
    select * from {{ ref('inspection_lot') }}
    {% if is_incremental() %}
    where sync_datetime >= dateadd(day, -3, (select coalesce(max(lot_sync_datetime), '1900-01-01'::timestamp_ntz) from {{ this }}))
    {% endif %}
),

perimeter as (
    select inspection_lot_sid, inspection_lot_number from {{ ref('dim_inspection_lot') }}
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
    perimeter.inspection_lot_sid,
    dim_order.production_order_sid,
    lots.inspection_lot_number,
    lots.material_number,
    lots.lot_status,
    lots.lot_creation_date                                              as created_date,
    lots.usage_decision_date                                           as decision_date,
    datediff(day, lots.lot_creation_date, lots.usage_decision_date)     as days_to_decision,
    datediff(day, lots.lot_creation_date, current_date)                as lot_age_days,
    lots.is_accepted,
    lots.is_rejected,
    coalesce(defect_agg.total_defect_quantity, 0)                      as total_defect_quantity,
    coalesce(defect_agg.defect_line_count, 0)                          as defect_line_count,
    lots.sync_datetime                                                as lot_sync_datetime
from lots
join perimeter  on lots.inspection_lot_number = perimeter.inspection_lot_number
left join defect_agg on lots.inspection_lot_number = defect_agg.inspection_lot_number
left join dim_order  on lots.production_order_number = dim_order.production_order_number
