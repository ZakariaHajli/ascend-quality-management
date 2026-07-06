{{
    config(
        materialized='table',
        access='public'
    )
}}

/*
    JUNK DIMENSION (Kimball): the low-cardinality lot flags and statuses, one row per distinct
    observed combination, keyed deterministically. Facts/dims reference lot_profile_sid instead
    of carrying N correlated flag columns; slicing by "profile" (e.g. rejected + decision made)
    becomes a single-attribute filter.

    The sid is a pure function of the attributes (deterministic surrogate identity), so any
    model can compute the FK locally without joining this dimension.
*/

with lots as (
    select * from {{ ref('inspection_lot') }}
),

profiles as (
    select distinct
        inspection_type,
        lot_status,
        usage_decision_code,
        is_decision_made,
        is_accepted,
        is_rejected
    from lots
)

select
    {{ generate_integer_surrogate_key([
        'inspection_type', 'lot_status', 'usage_decision_code',
        'is_decision_made', 'is_accepted', 'is_rejected'
    ]) }}                              as lot_profile_sid,
    inspection_type,
    lot_status,
    usage_decision_code,
    is_decision_made,
    is_accepted,
    is_rejected,
    -- readable label for BI slicers
    lot_status || iff(usage_decision_code is not null, ' (' || usage_decision_code || ')', '')
                                       as profile_label
from profiles
