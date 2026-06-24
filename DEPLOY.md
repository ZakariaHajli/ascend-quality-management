# Quality Management — deploy & promotion runbook

## 0. Credentials (once)

```powershell
Copy-Item .env.ps1.example .env.ps1   # fill Org / Account / User / Password
. .\.env.ps1
```

## 1. Provision infrastructure (dev + uat + prod)

> Usually already done by the platform bootstrap. Re-run any time to reconcile.

```powershell
$tf = "$env:USERPROFILE\bin\terraform.exe"      # or wherever terraform is installed
& $tf -chdir=terraform init
& $tf -chdir=terraform plan
& $tf -chdir=terraform apply                    # creates the 3 environments
```

## 2. Build & test (per environment)

```powershell
.\run-dbt.ps1 deps
.\run-dbt.ps1 seed  --target dev
.\run-dbt.ps1 build --target dev
```

`run-dbt.ps1` self-provisions a Python 3.12 venv on first run and routes dbt's package/target
dirs outside OneDrive.

## 3. Promote

Same code, higher environment — no edits:

```powershell
.\run-dbt.ps1 build --target uat
.\run-dbt.ps1 build --target prod
```

This promotion is automated by the included GitHub Actions workflow (section 5).

## 4. Consume

Point Power BI (or any client) at the `DPA` schema of the target database using the
environment **consumer** role, e.g. `QUALITY_MANAGEMENT_CONSUMER_PROD`. The marts already have
`CHANGE_TRACKING = TRUE` and `GRANT SELECT` to that role.

## 5. CI/CD (GitHub Actions)

An advanced, state-aware pipeline built from a **reusable** workflow (`_dbt-build.yml`):

| Workflow | Trigger | What runs |
|---|---|---|
| `pr.yml` | PR → `main` | **lint & governance gate** (parse + policy-as-code, no Snowflake) → **Slim CI** (`--select state:modified+ --defer`) into `dev` |
| `deploy.yml` | Push → `main` | build **uat**; publish defer state |
| `deploy.yml` | Release | build **prod** (Environment-gated) |
| `deploy.yml` | Nightly cron | source freshness + build **prod** |
| `deploy.yml` | Manual dispatch | build any env on demand |

Advanced: **Slim CI** (state compare + defer to prod), **policy-as-code** governance gate
(`ci/check_governance.py`), pip + dbt-package **caching**, artifact upload, per-env concurrency.

**One-time setup after pushing this repo to GitHub:**

1. Create three repository **Secrets** (Settings → Secrets and variables → Actions):
   `ASCEND_SF_ACCOUNT` (e.g. `MYORG-MYACCOUNT`), `ASCEND_SF_USER`, `ASCEND_SF_PASSWORD`.
   The CI user must have the `QUALITY_MANAGEMENT_TRANSFORM_{DEV,UAT,PROD}` roles granted.
2. Create three **Environments** named `dev`, `uat`, `prod`. Optionally add **required reviewers**
   on `prod` for manual approval, and scope per-environment secrets there.

> The runner installs dbt from `requirements.txt` (no OneDrive/venv concerns on Linux), so the
> `run-dbt.ps1` wrapper is for local development only.

## Teardown (per domain)

```powershell
. .\.env.ps1
& "$env:USERPROFILE\bin\terraform.exe" -chdir=terraform destroy
```
