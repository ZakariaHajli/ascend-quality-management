{{
    config(
        materialized='incremental',
        unique_key='inspection_lot_number',
        incremental_strategy='merge',
        merge_exclude_columns=['creation_datetime'],
        access='protected'
    )
}}

/*
    Canonical inspection lot (Pattern 1 — watermarked two-pass incremental merge).
    Assembled from QALS (lot header) + QAVE (usage decision), which change independently.
    Captures the lot lifecycle status used by the accumulating-snapshot fact downstream.
*/

with

{% if is_incremental() %}
watermark as (
    select coalesce(max(sync_datetime), '1900-01-01'::timestamp_ntz) as max_sync from {{ this }}
),
changed as (
    select prueflos from {{ ref('stg_qm__inspection_lot') }} where sync_datetime >= (select max_sync from watermark)
    union
    select prueflos from {{ ref('stg_qm__usage_decision') }} where sync_datetime >= (select max_sync from watermark)
),
{% endif %}

qals as (
    select * from {{ ref('stg_qm__inspection_lot') }}
    {% if is_incremental() %} where prueflos in (select prueflos from changed) {% endif %}
),

qave as (
    select * from {{ ref('stg_qm__usage_decision') }}
    {% if is_incremental() %} where prueflos in (select prueflos from changed) {% endif %}
),

joined as (
    select
        qals.prueflos                                   as inspection_lot_number,
        qals.matnr                                      as material_number,
        qals.werks                                      as plant,
        qals.aufnr                                      as production_order_number,
        qals.art                                        as inspection_type,
        qals.losmenge                                   as lot_quantity,
        {{ sap_date('qals.entstehdat') }}               as lot_creation_date,
        qave.vcode                                      as usage_decision_code,
        qave.vmenge                                     as accepted_quantity,
        {{ sap_date('qave.vdatum') }}                   as usage_decision_date,
        iff(qave.vcode is not null, true, false)        as is_decision_made,
        iff(qave.vcode = 'A', true, false)              as is_accepted,
        iff(qave.vcode = 'R', true, false)              as is_rejected,
        case
            when qave.vcode is null then 'IN_INSPECTION'
            when qave.vcode = 'A'   then 'ACCEPTED'
            when qave.vcode = 'R'   then 'REJECTED'
            else 'UNKNOWN'
        end                                             as lot_status,
        greatest(
            coalesce(qals.sync_datetime, '1900-01-01'::timestamp_ntz),
            coalesce(qave.sync_datetime, '1900-01-01'::timestamp_ntz)
        )                                               as _sync_datetime
    from qals
    left join qave on qals.prueflos = qave.prueflos
)

select
    joined.* exclude (_sync_datetime),
    {{ intermediate_technical_columns(
        hash_columns=['inspection_lot_number', 'usage_decision_code', 'lot_status', 'accepted_quantity'],
        sync_expression='_sync_datetime') }}
from joined
