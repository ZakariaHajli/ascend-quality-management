-- Example staging model (seed source, env-aware via ref).
-- For a real declared external source, call instead (note: no leading dashes):
--   generate_staging('sap', 'your_table', business_key='your_key')
{{ generate_staging(relation=ref('example_source'), business_key='entity_code') }}
