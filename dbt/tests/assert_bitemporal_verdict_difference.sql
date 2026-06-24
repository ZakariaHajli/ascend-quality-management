{{ config(store_failures=true) }}
-- Proves the bi-temporal ASOF join is doing real work: lot 100000001 / C10 was measured at
-- 302.5 and inspected under the pre-2025-07 spec (USL 303 -> in spec), but the current spec
-- (USL 302) would mark it out of spec. is_in_spec (as-of) and is_in_spec_current must disagree.
-- Passes (0 rows) only when that differing verdict is present.

select 'expected bi-temporal verdict difference is missing' as failure
where not exists (
    select 1
    from {{ ref('fct_inspection_result') }}
    where inspection_lot_number = '100000001'
      and characteristic_code = 'C10'
      and is_in_spec = true
      and is_in_spec_current = false
      and verdict_differs = true
)
