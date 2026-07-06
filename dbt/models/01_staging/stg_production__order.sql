{{ config(group='production_management') }}

/*
    CROSS-DOMAIN CONSUMPTION (Data Mesh P1/P4).
    The production_management domain publishes `dim_production_order` as a contracted data
    product; the quality domain consumes it here through the declared source — it does not
    reproduce production logic, it depends on the published interface. Access is governed by
    the producer (database USAGE via its Terraform, schema USAGE + SELECT via its product
    post-hook grants).
*/

with consumed as (
    select * from {{ source('production_management', 'dim_production_order') }}
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
