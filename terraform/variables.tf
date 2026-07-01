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

variable "powerbi_rsa_public_key" {
  type        = string
  default     = ""
  description = <<-EOT
    RSA public key (PEM body only, no BEGIN/END lines) for the per-environment Power BI service
    users. Generate with:
      openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out pbi_key.p8 -nocrypt
      openssl rsa -in pbi_key.p8 -pubout -out pbi_key.pub
    then paste the body of pbi_key.pub here. Empty = skip creating the Power BI users.
  EOT
}
