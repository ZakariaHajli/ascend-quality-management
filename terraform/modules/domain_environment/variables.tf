variable "environment" {
  type        = string
  description = "Environment key, e.g. dev / uat / prod."
}

variable "domain_upper" {
  type        = string
  description = "Domain name in UPPER_SNAKE, used as the DB/role base (e.g. QUALITY_MANAGEMENT)."
}

variable "warehouse_size" {
  type    = string
  default = "XSMALL"
}

variable "deploy_user" {
  type        = string
  description = "Login name of the deploying user; both roles are granted to it."
}
