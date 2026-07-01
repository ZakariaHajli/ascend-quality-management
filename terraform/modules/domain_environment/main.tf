# ════════════════════════════════════════════════════════════════════════════
#  One domain environment (dev | uat | prod): database, warehouse, transform role,
#  consumer role, and the grants wiring them together.
# ════════════════════════════════════════════════════════════════════════════

locals {
  env_upper         = upper(var.environment)
  database_name     = "${local.env_upper}_${var.domain_upper}"
  warehouse_name    = "WH_${var.domain_upper}_${local.env_upper}"
  bi_warehouse_name = "WH_${var.domain_upper}_BI_${local.env_upper}"
  transform_role    = "${var.domain_upper}_TRANSFORM_${local.env_upper}"
  consumer_role     = "${var.domain_upper}_CONSUMER_${local.env_upper}"
  powerbi_user      = "${var.domain_upper}_PBI_${local.env_upper}"
  gold_namespace    = "${local.database_name}.DPA" # gold layer = the DPA schema
  create_pbi_user   = trimspace(var.powerbi_rsa_public_key) != ""
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

# ════════════════════════════════════════════════════════════════════════════
#  POWER BI → GOLD LAYER (DPA schema)
#
#  • a dedicated BI warehouse so Power BI query load is isolated from transform compute,
#  • a Power BI service user (key-pair auth) defaulted into the gold layer with the consumer role.
#
#  Gold-layer SELECT itself is granted per data product by the dbt mart post-hook
#  (GRANT SELECT ... TO ROLE <consumer>), so the consumer role can read ONLY the published
#  gold tables — never the STG/DSO internals (it has schema USAGE but no table SELECT there).
#  CHANGE_TRACKING = TRUE on every mart (also a dbt post-hook) powers Power BI incremental refresh.
# ════════════════════════════════════════════════════════════════════════════

resource "snowflake_warehouse" "bi" {
  name                = local.bi_warehouse_name
  warehouse_size      = var.bi_warehouse_size
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true
  comment             = "${var.domain_upper} ${local.env_upper} — Power BI / consumer query warehouse"
}

resource "snowflake_grant_privileges_to_account_role" "consumer_bi_wh" {
  account_role_name = snowflake_account_role.consumer.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.bi.name
  }
}

# Power BI service account — created only when an RSA public key is supplied (key-pair auth,
# no password in state). The private key goes into the Power BI Snowflake connection.
resource "snowflake_user" "powerbi" {
  count             = local.create_pbi_user ? 1 : 0
  name              = local.powerbi_user
  login_name        = local.powerbi_user
  comment           = "Power BI service account for the ${var.domain_upper} ${local.env_upper} gold layer."
  default_role      = snowflake_account_role.consumer.name
  default_warehouse = snowflake_warehouse.bi.name
  default_namespace = local.gold_namespace
  rsa_public_key    = var.powerbi_rsa_public_key
}

resource "snowflake_grant_account_role" "consumer_to_pbi" {
  count     = local.create_pbi_user ? 1 : 0
  role_name = snowflake_account_role.consumer.name
  user_name = snowflake_user.powerbi[0].name
}
