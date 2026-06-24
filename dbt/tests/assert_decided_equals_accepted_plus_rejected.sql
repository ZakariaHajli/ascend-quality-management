{{ config(store_failures=true) }}
-- KPI integrity: decided lots must equal accepted + rejected for every material.
-- Passes when zero rows are returned. Failures persisted to TEST_AUDIT for governance.

select
    material_number,
    lots_decided,
    lots_accepted,
    lots_rejected
from {{ ref('agg_quality_kpi') }}
where lots_decided <> (lots_accepted + lots_rejected)
