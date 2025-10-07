variable "storage_account_id" {
  description = "ID du Storage Account"
  type        = string
}

variable "key_vault_id" {
  description = "ID du Key Vault"
  type        = string
}

variable "entra_groups" {
  description = "Map des groupes Entra ID"
  type        = any
}
