{{
    config(
        materialized='table',
        access='public',
        contract={'enforced': true}
    )
}}

/*
    Canonical quality KPI product (semantic layer realised, per material): First Pass Yield,
    reject rate, defect PPM, in-spec rate. Defining these ONCE here (and in the semantic model,
    _semantic__quality.yml) prevents the metric drift the thesis warns about. Combines three
    grains — lot, characteristic result, defect — each aggregated to material.
*/

with lots as (
    select * from {{ ref('dim_inspection_lot') }}
),

lot_agg as (
    select
        material_number,
        count(*)                       as lots_total,
        count_if(is_decision_made)     as lots_decided,
        count_if(is_accepted)          as lots_accepted,
        count_if(is_rejected)          as lots_rejected,
        sum(lot_quantity)              as inspected_quantity
    from lots
    group by material_number
),

result_agg as (
    select
        lots.material_number,
        count(*)                       as results_total,
        count_if(r.is_in_spec)         as in_spec_results
    from {{ ref('inspection_result') }} r
    join lots on r.inspection_lot_number = lots.inspection_lot_number
    group by lots.material_number
),

defect_agg as (
    select
        lots.material_number,
        sum(d.defect_quantity)         as defect_quantity
    from {{ ref('defect') }} d
    join lots on d.inspection_lot_number = lots.inspection_lot_number
    group by lots.material_number
)

select
    cast(lot_agg.material_number as varchar)                                                 as material_number,
    cast(lot_agg.lots_total as number)                                                       as lots_total,
    cast(lot_agg.lots_decided as number)                                                     as lots_decided,
    cast(lot_agg.lots_accepted as number)                                                    as lots_accepted,
    cast(lot_agg.lots_rejected as number)                                                    as lots_rejected,
    cast(round(iff(lot_agg.lots_decided > 0, lot_agg.lots_accepted / lot_agg.lots_decided, null), 4) as float) as first_pass_yield,
    cast(round(iff(lot_agg.lots_decided > 0, lot_agg.lots_rejected / lot_agg.lots_decided, null), 4) as float) as reject_rate,
    cast(lot_agg.inspected_quantity as number)                                               as inspected_quantity,
    cast(coalesce(defect_agg.defect_quantity, 0) as number)                                  as defect_quantity,
    cast(round({{ ppm('coalesce(defect_agg.defect_quantity, 0)', 'lot_agg.inspected_quantity') }}, 2) as float) as defect_ppm,
    cast(coalesce(result_agg.results_total, 0) as number)                                    as results_total,
    cast(coalesce(result_agg.in_spec_results, 0) as number)                                  as in_spec_results,
    cast(round(iff(result_agg.results_total > 0, result_agg.in_spec_results / result_agg.results_total, null), 4) as float) as in_spec_rate
from lot_agg
left join result_agg on lot_agg.material_number = result_agg.material_number
left join defect_agg on lot_agg.material_number = defect_agg.material_number
