{{
    config(
        materialized='table',
        access='protected'
    )
}}

-- Effective-dated characteristic spec history (versioned). Backs the Type-2 dimension and
-- the bi-temporal ASOF join, so an in-spec verdict can be evaluated against the spec that was
-- valid at the moment of inspection.

with src as (
    select * from {{ ref('qm_characteristic_history') }}
)

select
    merknr      as characteristic_code,
    version,
    valid_from,
    valid_to,
    sollwert    as target_value,
    toleranzun  as lower_spec_limit,
    toleranzob  as upper_spec_limit,
    unit
from src
