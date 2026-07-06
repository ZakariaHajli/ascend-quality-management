{{
    config(
        materialized='table',
        access='public',
        contract={'enforced': true}
    )
}}

/*
    Conformed MATERIAL dimension (Kimball). material_number is the mesh's central polyseme —
    the same identifier in production orders, inspection lots and quality KPIs. product_family
    comes from the consumed production_management product, so family rollups of quality KPIs
    agree with the producing domain by construction.
*/

with materials as (
    select * from {{ ref('material') }}
)

select
    cast({{ generate_integer_surrogate_key(['material_number']) }} as number(38,0)) as material_sid,
    cast(material_number as varchar)  as material_number,
    cast(product_family as varchar)   as product_family,
    cast(plant_count as number(38,0)) as plant_count,
    cast(first_lot_date as date)      as first_lot_date,
    cast(latest_lot_date as date)     as latest_lot_date
from materials
