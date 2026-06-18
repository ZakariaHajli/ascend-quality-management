{{
    config(
        materialized='table',
        access='public',
        group='referential_data'
    )
}}

-- Referential shared calendar product (cross-domain interface, access: public).

with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-01-01' as date)",
        end_date="cast('2027-01-01' as date)"
    ) }}
)

select
    cast(date_day as date)                  as date_day,
    cast(year(date_day) as number)          as calendar_year,
    cast(month(date_day) as number)         as calendar_month,
    cast(yearofweekiso(date_day) as number) as iso_year,
    cast(weekiso(date_day) as number)       as iso_week,
    cast(to_char(date_day, 'YYYY-MM') as varchar) as year_month
from spine
