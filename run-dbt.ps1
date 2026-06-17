# Wrapper that runs dbt for this project with all environment workarounds baked in:
#  • a dedicated Python 3.12 venv (system Python may be 3.14, which dbt cannot run on),
#  • package + target paths OUTSIDE OneDrive (sync locks corrupt dbt file ops).
#
# Usage:   . .\.env.ps1 ;  .\run-dbt.ps1 deps
#          .\run-dbt.ps1 seed  --target dev
#          .\run-dbt.ps1 build --target uat
param([Parameter(ValueFromRemainingArguments = $true)] $DbtArgs)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$venv = Join-Path $root ".venv"
$dbt  = Join-Path $venv "Scripts\dbt.exe"

if (-not (Test-Path $dbt)) {
    Write-Host "Creating dbt venv (Python 3.12)..." -ForegroundColor Cyan
    py -V:3.12 -m venv $venv
    & (Join-Path $venv "Scripts\python.exe") -m pip install --quiet --upgrade pip
    & (Join-Path $venv "Scripts\python.exe") -m pip install --quiet dbt-snowflake
}

$targetPath = Join-Path $env:LOCALAPPDATA "dbt-targets\ascend-quality-management"
$projectDir = Join-Path $root "dbt"
# Route dbt package installs outside OneDrive (read by dbt_project.yml packages-install-path).
$env:DBT_PACKAGES_PATH = Join-Path $env:LOCALAPPDATA "dbt-packages\ascend-quality-management"

# deps/clean/init don't take --profiles-dir/--target-path; everything else does.
$cmd = if ($DbtArgs.Count -gt 0) { $DbtArgs[0] } else { "" }
$common = @("--project-dir", $projectDir)
if ($cmd -notin @("deps", "clean", "init")) {
    $common += @("--profiles-dir", $projectDir, "--target-path", $targetPath)
}

& $dbt @DbtArgs @common
exit $LASTEXITCODE
