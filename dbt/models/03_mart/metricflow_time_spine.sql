{{
    config(
        materialized='table',
        access='public',
        group='referential_data'
    )
}}

-- Time spine required by the dbt semantic layer (MetricFlow) for time-based metrics.

with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-01-01' as date)",
        end_date="cast('2027-01-01' as date)"
    ) }}
)

select cast(date_day as date) as date_day
from spine
