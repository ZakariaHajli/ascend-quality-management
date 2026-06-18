{{
    config(
        materialized='table',
        access='public',
        contract={'enforced': true}
    )
}}

/*
    PATTERN 4 — Perimeter-via-dimension. The domain scope (final inspections '04', rolling
    3-year window) lives here once; every fact inherits it through an inner join on
    inspection_lot_sid, so no fact restates the filter.
*/

with lots as (
    select * from {{ ref('inspection_lot') }}
),

filtered as (
    select *
    from lots
    where inspection_type = '04'
      and lot_creation_date >= dateadd(year, -3, current_date)
)

select
    cast({{ generate_integer_surrogate_key(['inspection_lot_number']) }} as number) as inspection_lot_sid,
    cast(inspection_lot_number as varchar)  as inspection_lot_number,
    cast(material_number as varchar)        as material_number,
    cast(plant as varchar)                  as plant,
    cast(production_order_number as varchar) as production_order_number,
    cast(inspection_type as varchar)        as inspection_type,
    cast(lot_quantity as number)            as lot_quantity,
    cast(lot_creation_date as date)         as lot_creation_date,
    cast(usage_decision_code as varchar)    as usage_decision_code,
    cast(usage_decision_date as date)       as usage_decision_date,
    cast(lot_status as varchar)             as lot_status,
    cast(is_accepted as boolean)            as is_accepted,
    cast(is_rejected as boolean)            as is_rejected,
    cast(is_decision_made as boolean)       as is_decision_made
from filtered
