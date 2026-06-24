{#
    SCD2 via the TIMESTAMP strategy (the complement to characteristic_snapshot's 'check' strategy).
    Tracks history of the CONSUMED production-order product using its change signal (sync_datetime =
    last_changed). A new version opens only when sync_datetime advances — robust against no-op runs.
#}
{% snapshot production_order_snapshot %}

{{
    config(
        unique_key='production_order_number',
        strategy='timestamp',
        updated_at='sync_datetime',
        invalidate_hard_deletes=true
    )
}}

select
    production_order_number,
    material_number,
    product_family,
    plant,
    creation_date,
    order_quantity,
    sync_datetime
from {{ ref('stg_production__order') }}

{% endsnapshot %}
