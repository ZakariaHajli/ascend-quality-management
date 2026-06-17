# ════════════════════════════════════════════════════════════════════════════
#  One domain environment (dev | uat | prod): database, warehouse, transform role,
#  consumer role, and the grants wiring them together.
# ════════════════════════════════════════════════════════════════════════════

locals {
  env_upper      = upper(var.environment)
  database_name  = "${local.env_upper}_${var.domain_upper}"
  warehouse_name = "WH_${var.domain_upper}_${local.env_upper}"
  transform_role = "${var.domain_upper}_TRANSFORM_${local.env_upper}"
  consumer_role  = "${var.domain_upper}_CONSUMER_${local.env_upper}"
}

resource "snowflake_warehouse" "wh" {
  name                = local.warehouse_name
  warehouse_size      = var.warehouse_size
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "${var.domain_upper} ${local.env_upper} transform warehouse"
}

resource "snowflake_database" "db" {
  name    = local.database_name
  comment = "${var.domain_upper} ${local.env_upper} — RAW / STG / DSO / DPA / SNAPSHOTS schemas"
}

resource "snowflake_account_role" "transform" {
  name    = local.transform_role
  comment = "dbt transform/deploy role for ${var.domain_upper} ${local.env_upper}."
}

resource "snowflake_account_role" "consumer" {
  name    = local.consumer_role
  comment = "BI consumer role for ${var.domain_upper} ${local.env_upper} (mart GRANT SELECT target)."
}

# ── Warehouse grants ────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_account_role" "transform_wh" {
  account_role_name = snowflake_account_role.transform.name
  privileges        = ["USAGE", "OPERATE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "consumer_wh" {
  account_role_name = snowflake_account_role.consumer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.wh.name
  }
}

# ── Database grants ─────────────────────────────────────────────────────────
resource "snowflake_grant_privileges_to_account_role" "transform_db" {
  account_role_name = snowflake_account_role.transform.name
  privileges        = ["USAGE", "CREATE SCHEMA", "MONITOR"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "consumer_db" {
  account_role_name = snowflake_account_role.consumer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.db.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "consumer_future_schemas" {
  account_role_name = snowflake_account_role.consumer.name
  privileges        = ["USAGE"]
  on_schema {
    future_schemas_in_database = snowflake_database.db.name
  }
}

# ── Role memberships ────────────────────────────────────────────────────────
resource "snowflake_grant_account_role" "transform_to_user" {
  role_name = snowflake_account_role.transform.name
  user_name = var.deploy_user
}

resource "snowflake_grant_account_role" "consumer_to_user" {
  role_name = snowflake_account_role.consumer.name
  user_name = var.deploy_user
}

resource "snowflake_grant_account_role" "transform_to_sysadmin" {
  role_name        = snowflake_account_role.transform.name
  parent_role_name = "SYSADMIN"
}
