# ── Connection (from TF_VAR_* env vars) ───────────────────────────────────
variable "snowflake_organization_name" { type = string }
variable "snowflake_account_name" { type = string }
variable "snowflake_user" { type = string }
variable "snowflake_password" {
  type      = string
  sensitive = true
}
variable "snowflake_role" {
  type    = string
  default = "ACCOUNTADMIN"
}

# ── Domain settings (written by bootstrap.ps1 into terraform.auto.tfvars) ──
variable "domain_upper" {
  type        = string
  description = "Domain in UPPER_SNAKE — the DB/role base (e.g. QUALITY_MANAGEMENT)."
}

variable "environments" {
  type    = list(string)
  default = ["dev", "uat", "prod"]
}

variable "warehouse_sizes" {
  type = map(string)
  default = {
    dev  = "XSMALL"
    uat  = "XSMALL"
    prod = "SMALL"
  }
}
