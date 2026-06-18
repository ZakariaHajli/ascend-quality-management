{{
    config(
        materialized='table',
        access='protected'
    )
}}

-- Canonical defect, one row per notification defect item (QMFE), enriched with the
-- notification header (QMEL: lot, order, date) and the defect code catalog (QPCT).

with qmfe as (
    select * from {{ ref('stg_qm__defect_item') }}
),

qmel as (
    select
        qmnum,
        prueflos,
        aufnr,
        {{ sap_date('erdat') }} as notification_date,
        sync_datetime
    from {{ ref('stg_qm__notification') }}
),

qpct as (
    select codegruppe, code, kurztext from {{ ref('stg_qm__defect_code') }}
),

joined as (
    select
        qmfe.qmnum                          as notification_number,
        qmfe.fenum                          as defect_item_number,
        qmel.prueflos                       as inspection_lot_number,
        qmel.aufnr                          as production_order_number,
        qmel.notification_date,
        qmfe.fecod                          as defect_code,
        qmfe.fegrp                          as code_group,
        qpct.kurztext                       as defect_description,
        qmfe.anzfehler                      as defect_quantity,
        greatest(
            coalesce(qmfe.sync_datetime, '1900-01-01'::timestamp_ntz),
            coalesce(qmel.sync_datetime, '1900-01-01'::timestamp_ntz)
        )                                   as _sync_datetime
    from qmfe
    left join qmel on qmfe.qmnum = qmel.qmnum
    left join qpct on qmfe.fegrp = qpct.codegruppe and qmfe.fecod = qpct.code
)

select
    joined.* exclude (_sync_datetime),
    {{ intermediate_technical_columns(
        hash_columns=['notification_number', 'defect_item_number', 'defect_code', 'defect_quantity'],
        sync_expression='_sync_datetime') }}
from joined
