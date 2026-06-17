# Quality Management — Data Product Domain

Bootstrapped from the ASCEND domain platform template (dbt + Snowflake + Terraform), with
**dev / uat / prod** environments and the platform standards baked in: medallion layers,
reusable macros, deterministic surrogate keys, technical columns, enforced contracts, RBAC,
groups/ownership, and tests.

## Environments

| | dev | uat | prod |
|---|---|---|---|
| Database | `DEV_QUALITY_MANAGEMENT` | `UAT_QUALITY_MANAGEMENT` | `PROD_QUALITY_MANAGEMENT` |
| Warehouse | `WH_QUALITY_MANAGEMENT_DEV` | `WH_QUALITY_MANAGEMENT_UAT` | `WH_QUALITY_MANAGEMENT_PROD` |
| Transform role | `QUALITY_MANAGEMENT_TRANSFORM_DEV` | `…_UAT` | `…_PROD` |
| Consumer role | `QUALITY_MANAGEMENT_CONSUMER_DEV` | `…_UAT` | `…_PROD` |

Schemas in each database: `RAW`, `STG`, `DSO`, `DPA`, `SNAPSHOTS`. dbt picks the database
from `--target` automatically (the `generate_database_name` macro).

## Develop

```powershell
Copy-Item .env.ps1.example .env.ps1   # fill Org / Account / User / Password
. .\.env.ps1
.\run-dbt.ps1 deps
.\run-dbt.ps1 seed  --target dev
.\run-dbt.ps1 build --target dev      # runs the example pipeline + tests
```

Promote the same code to higher environments with `--target uat` then `--target prod`.

## Where to add your work

- `dbt/seeds/` — replace `example_source.csv` with your domain seeds/reference data.
- `dbt/models/01_staging/` — one staging model per source (`generate_staging`).
- `dbt/models/02_intermediate/` — canonical business entities (`intermediate_technical_columns`).
- `dbt/models/03_mart/` — dimensions and facts, the consumable products (contracts + RBAC).
- `dbt/models/_groups.yml` — domain ownership; mark cross-domain interfaces `access: public`.

See **[DEPLOY.md](DEPLOY.md)** for provisioning and promotion.
