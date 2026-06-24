{% docs __overview__ %}

# Quality Management — Data Product Domain

This domain publishes governed, contracted **quality data products** built from SAP QM
(QALS/QAVE/QAMR/QMEL/QMFE) and the **consumed production-order product** from the
production_management domain.

## Governance at a glance
- **Ownership:** every mart object carries `meta` (domain, owner, classification, certification,
  PII flag) and a dbt **group** with an accountable owner; internal models use `access` modifiers,
  published products are `access: public`.
- **Contracts:** the core products enforce dbt **contracts** (typed, named columns + constraints).
- **Access:** mart products grant `SELECT` to the environment **consumer role** and enable
  Change Tracking via post-hooks.
- **Quality:** tests at every layer (uniqueness, referential integrity, accepted values/ranges,
  freshness-of-logic, custom generic `not_in_future`, **2 unit tests**); singular tests persist
  failures to the **`TEST_AUDIT`** schema for an auditable DQ history.
- **Lineage:** an **exposure** declares the downstream Power BI consumer; docs are persisted to
  Snowflake's information schema.

## Headline products
- `dim_inspection_lot` — perimeter-owning lot dimension
- `dim_characteristic_history` — **Type-2 (SCD2)** spec history
- `fct_inspection_result` — **bi-temporal** in-spec (ASOF point-in-time)
- `fct_inspection_lot_lifecycle` — **accumulating-snapshot** (incrementally merged)
- `fct_quality_defect` — defect Pareto
- `agg_quality_kpi` — canonical KPIs (FPY, defect PPM, in-spec rate)

{% enddocs %}
