{{ config(group='production_management') }}

/*
    CROSS-DOMAIN CONSUMPTION (Data Mesh P1/P4).
    The production_management domain publishes `dim_production_order` as a data product; the
    quality domain consumes it here. Runnable from a seed for this prototype. In production,
    swap the ref() below for a declared cross-domain source pointing at the producing domain's
    product (see models/01_staging/_staging__sources.example.yml):

        source('production_management', 'dim_production_order')

    The quality domain treats the production order as an external, contracted interface — it does
    not reproduce production logic, it depends on the published product.
*/

with consumed as (
    select * from {{ ref('production_order_product') }}
)

select
    production_order_number,
    material_number,
    product_family,
    plant,
    creation_date,
    order_quantity,
    'production_management'             as source_system,
    cast(last_changed as timestamp_ntz) as sync_datetime  -- stable change signal (for the timestamp-strategy snapshot)
from consumed
