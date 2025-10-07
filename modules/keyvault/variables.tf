variable "key_vault_name" {
  description = "Nom du Key Vault"
  type        = string
}

variable "resource_group_name" {
  description = "Nom du resource group"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID Azure AD"
  type        = string
}

variable "sku_name" {
  description = "SKU du Key Vault"
  type        = string
  default     = "standard"
}

variable "purge_protection_enabled" {
  description = "Activer la protection contre la purge (CRITIQUE)"
  type        = bool
  default     = true # AMÉLIORATION: était false dans le script
}

variable "soft_delete_retention_days" {
  description = "Jours de rétention pour soft delete"
  type        = number
  default     = 90
}

variable "enable_rbac_authorization" {
  description = "Utiliser RBAC au lieu d'access policies"
  type        = bool
  default     = true
}

variable "default_network_action" {
  description = "Action par défaut pour les règles réseau"
  type        = string
  default     = "Deny"
}

variable "allowed_ip_addresses" {
  description = "Adresses IP autorisées"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "IDs des subnets autorisés"
  type        = list(string)
  default     = []
}

variable "admin_contact_email" {
  description = "Email de contact administrateur"
  type        = string
  default     = "security@company.com"
}

variable "admin_contact_phone" {
  description = "Téléphone de contact administrateur"
  type        = string
  default     = "+33123456789"
}

variable "enable_private_endpoint" {
  description = "Activer le Private Endpoint"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "ID du subnet pour Private Endpoint"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}
