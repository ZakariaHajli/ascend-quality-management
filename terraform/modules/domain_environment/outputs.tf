output "database" {
  value = snowflake_database.db.name
}

output "warehouse" {
  value = snowflake_warehouse.wh.name
}

output "transform_role" {
  value = snowflake_account_role.transform.name
}

output "consumer_role" {
  value = snowflake_account_role.consumer.name
}

output "powerbi_connection" {
  description = "Power BI → gold layer connection parameters for this environment."
  value = {
    warehouse  = snowflake_warehouse.bi.name
    role       = snowflake_account_role.consumer.name
    database   = snowflake_database.db.name
    schema     = "DPA"
    user       = local.create_pbi_user ? snowflake_user.powerbi[0].name : "(set powerbi_rsa_public_key to create)"
  }
}
