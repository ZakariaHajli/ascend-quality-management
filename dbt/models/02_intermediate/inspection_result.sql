{{
    config(
        materialized='incremental',
        unique_key=['inspection_lot_number', 'characteristic_code'],
        incremental_strategy='merge',
        merge_exclude_columns=['creation_datetime'],
        access='protected'
    )
}}

-- Characteristic results (QAMR), one row per (lot, characteristic). Incremental on sync_datetime.
-- In-spec status is computed via the shared is_in_spec() macro (no metric drift).

with qamr as (
    select * from {{ ref('stg_qm__inspection_result') }}
    {% if is_incremental() %}
    where sync_datetime >= (select coalesce(max(sync_datetime), '1900-01-01'::timestamp_ntz) from {{ this }})
    {% endif %}
),

computed as (
    select
        prueflos                                                    as inspection_lot_number,
        merknr                                                      as characteristic_code,
        mittelwert                                                  as measured_value,
        sollwert                                                    as target_value,
        toleranzun                                                  as lower_spec_limit,
        toleranzob                                                  as upper_spec_limit,
        round(mittelwert - sollwert, 4)                             as deviation_from_target,
        {{ is_in_spec('mittelwert', 'toleranzun', 'toleranzob') }}  as is_in_spec,
        sync_datetime                                               as _sync_datetime
    from qamr
)

select
    computed.* exclude (_sync_datetime),
    {{ intermediate_technical_columns(
        hash_columns=['inspection_lot_number', 'characteristic_code', 'measured_value'],
        sync_expression='_sync_datetime') }}
from computed
