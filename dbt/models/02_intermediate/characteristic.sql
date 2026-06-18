{{
    config(
        materialized='table',
        access='protected'
    )
}}

-- Inspection characteristic master (target + spec limits). Snapshotted (SCD2) downstream so
-- historical spec changes are queryable.

with src as (
    select * from {{ ref('stg_qm__characteristic') }}
)

select
    merknr          as characteristic_code,
    kurztext        as characteristic_name,
    sollwert        as target_value,
    toleranzun      as lower_spec_limit,
    toleranzob      as upper_spec_limit,
    unit,
    {{ intermediate_technical_columns(
        hash_columns=['merknr', 'sollwert', 'toleranzun', 'toleranzob'],
        sync_expression='sync_datetime') }}
from src
