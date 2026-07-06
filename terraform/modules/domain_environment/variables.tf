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

variable "bi_warehouse_size" {
  type        = string
  default     = "XSMALL"
  description = "Size of the dedicated Power BI / consumer warehouse."
}

variable "powerbi_rsa_public_key" {
  type        = string
  default     = ""
  description = "RSA public key (PEM body, no header/footer) for the Power BI service user. Empty = do not create the user."
}
