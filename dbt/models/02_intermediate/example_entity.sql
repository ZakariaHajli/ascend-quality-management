{{
    config(
        materialized='table',
        access='protected',
        tags=['quality_management']
    )
}}

-- Canonical example entity. Replace with your domain's real entities. Carries the eight
-- standard technical columns (is_active, sync_datetime, raw_hash, creation/update, ...).

with source as (
    select * from {{ ref('stg_example__source') }}
)

select
    entity_code,
    entity_label,
    entity_value,
    {{ intermediate_technical_columns(
        hash_columns=['entity_code', 'entity_label', 'entity_value'],
        sync_expression='sync_datetime') }}
from source
