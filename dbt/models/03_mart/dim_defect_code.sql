{{
    config(
        materialized='table',
        access='public'
    )
}}

-- Defect code dimension with a code-group rollup (for defect Pareto by group)..

with codes as (
    select * from {{ ref('stg_qm__defect_code') }}
)

select
    {{ generate_integer_surrogate_key(['codegruppe', 'code']) }} as defect_code_sid,
    code                        as defect_code,
    codegruppe                  as code_group,
    kurztext                    as defect_description,
    case codegruppe
        when 'VIS' then 'Visuel'
        when 'DIM' then 'Dimensionnel'
        when 'FUN' then 'Fonctionnel'
        else codegruppe
    end                         as code_group_label,
    case codegruppe
        when 'FUN' then 1
        when 'DIM' then 2
        when 'VIS' then 3
        else 9
    end                         as code_group_priority,
    iff(codegruppe = 'VIS', true, false) as is_visual_defect
from codes
