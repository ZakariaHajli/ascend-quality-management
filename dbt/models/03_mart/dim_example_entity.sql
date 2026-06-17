{{
    config(
        materialized='table',
        access='public',
        tags=['quality_management'],
        contract={'enforced': true}
    )
}}

-- Example contracted data product. The project post-hooks add CHANGE_TRACKING and
-- GRANT SELECT to the environment consumer role. Replace with your domain's dims/facts.

with entity as (
    select * from {{ ref('example_entity') }}
)

select
    cast({{ generate_integer_surrogate_key(['entity_code']) }} as number) as example_entity_sid,
    cast(entity_code as varchar)    as entity_code,
    cast(entity_label as varchar)   as entity_label,
    cast(entity_value as number)    as entity_value
from entity
