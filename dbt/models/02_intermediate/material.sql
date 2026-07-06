{{
    config(
        materialized='table',
        access='protected'
    )
}}

/*
    Canonical material (domain-internal). Assembled from the domain's own inspection lots and
    ENRICHED with the consumed production_management product (product_family) — a conformed
    dimension built across the mesh through published interfaces, joined on the
    material_number polyseme.
*/

with lots as (
    select * from {{ ref('inspection_lot') }}
),

production as (
    select distinct material_number, product_family
    from {{ ref('stg_production__order') }}
),

per_material as (
    select
        material_number,
        count(distinct plant)          as plant_count,
        min(lot_creation_date)         as first_lot_date,
        max(lot_creation_date)         as latest_lot_date,
        count(*)                       as lots_seen
    from lots
    group by material_number
)

select
    m.material_number,
    coalesce(p.product_family, 'UNASSIGNED') as product_family,
    m.plant_count,
    m.first_lot_date,
    m.latest_lot_date,
    m.lots_seen
from per_material m
left join production p on m.material_number = p.material_number
