{{
    config(
        materialized='table',
        access='public',
        group='referential_data'
    )
}}

/*
    CROSS-DOMAIN CONSUMPTION (Data Mesh P1/P4).
    This domain no longer re-implements a calendar — it CONSUMES the referential_data domain's
    published `dim_calendar` product through a declared cross-domain source. The referential
    domain owns the logic and the contract; this domain depends on the interface.
*/

select
    date_day,
    calendar_year,
    calendar_month,
    iso_year,
    iso_week,
    year_month
from {{ source('referential_data', 'dim_calendar') }}
