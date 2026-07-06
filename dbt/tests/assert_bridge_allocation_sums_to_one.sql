-- Kimball bridge invariant: allocation factors must sum to exactly 1.0 per lot,
-- otherwise weighted measures silently under/over-count.
select
    inspection_lot_sid,
    sum(allocation_factor) as total_allocation
from {{ ref('bridge_lot_defect_code') }}
group by inspection_lot_sid
having abs(total_allocation - 1.0) > 0.0001
