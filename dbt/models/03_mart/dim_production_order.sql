{{
    config(
        materialized='table',
        access='public',
        group='production_management'
    )
}}

-- Conformed dimension of the CONSUMED production-order product (Data Mesh cross-domain).
-- The quality domain joins its facts to this declared interface instead of reproducing logic.

with consumed as (
    select * from {{ ref('stg_production__order') }}
)

select
    {{ generate_integer_surrogate_key(['production_order_number']) }} as production_order_sid,
    production_order_number,
    material_number,
    product_family,
    plant,
    creation_date,
    order_quantity
from consumed
