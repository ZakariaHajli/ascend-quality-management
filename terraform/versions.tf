terraform {
  required_version = ">= 1.5.0"
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 1.0"
    }
  }
}

# Auth comes from TF_VAR_* env vars (set by .env.ps1). The role must be able to
# CREATE DATABASE/WAREHOUSE/ROLE and MANAGE GRANTS (ACCOUNTADMIN works).
provider "snowflake" {
  organization_name = var.snowflake_organization_name
  account_name      = var.snowflake_account_name
  user              = var.snowflake_user
  password          = var.snowflake_password
  role              = var.snowflake_role
  authenticator     = "snowflake"
}
