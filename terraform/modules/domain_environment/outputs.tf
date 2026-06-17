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
