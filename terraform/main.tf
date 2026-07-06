# Build every environment (dev/uat/prod) for this domain from one module.
module "environment" {
  for_each = toset(var.environments)
  source   = "./modules/domain_environment"

  environment            = each.key
  domain_upper           = var.domain_upper
  warehouse_size         = lookup(var.warehouse_sizes, each.key, "XSMALL")
  deploy_user            = var.snowflake_user
  powerbi_rsa_public_key = var.powerbi_rsa_public_key
}
