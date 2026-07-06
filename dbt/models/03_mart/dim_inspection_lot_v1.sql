{{
    config(
        materialized='table',
        access='public',
        contract={'enforced': true}
    )
}}

/*
    VERSION 1 — the frozen ORIGINAL interface of dim_inspection_lot, kept as a compatibility
    surface while consumers migrate to v2 (deprecation date in the YAML). Implemented as a thin
    projection of v2, so both versions are always consistent; only the shape differs.

    Pin from a consumer with:  {{ "{{ ref('dim_inspection_lot', v=1) }}" }}
*/

select
    inspection_lot_sid,
    inspection_lot_number,
    material_number,
    plant,
    production_order_number,
    inspection_type,
    lot_quantity,
    lot_creation_date,
    usage_decision_code,
    usage_decision_date,
    lot_status,
    is_accepted,
    is_rejected,
    is_decision_made
from {{ ref('dim_inspection_lot', v=2) }}
