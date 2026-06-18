-- Consistency: the usage-decision code, the boolean flags, and the derived lot_status must
-- agree on every lot in the lifecycle fact. Passes when zero rows are returned.

select
    inspection_lot_number,
    lot_status,
    is_accepted,
    is_rejected
from {{ ref('fct_inspection_lot_lifecycle') }}
where (lot_status = 'ACCEPTED' and not is_accepted)
   or (lot_status = 'REJECTED' and not is_rejected)
   or (is_accepted and is_rejected)
