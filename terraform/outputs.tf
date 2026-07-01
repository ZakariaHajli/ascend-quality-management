output "environments" {
  description = "Per-environment Snowflake objects created for this domain."
  value = {
    for env, m in module.environment : env => {
      database       = m.database
      warehouse      = m.warehouse
      transform_role = m.transform_role
      consumer_role  = m.consumer_role
    }
  }
}

output "powerbi_connections" {
  description = "Per-environment Power BI → gold-layer (DPA) connection parameters."
  value       = { for env, m in module.environment : env => m.powerbi_connection }
}
