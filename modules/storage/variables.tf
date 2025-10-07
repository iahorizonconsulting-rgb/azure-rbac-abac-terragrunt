variable "storage_account_name" {
  description = "Nom du compte de stockage"
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

variable "account_tier" {
  description = "Tier du compte de stockage"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Type de réplication"
  type        = string
  default     = "GZRS"
}

variable "min_tls_version" {
  description = "Version TLS minimum"
  type        = string
  default     = "TLS1_2"
}

variable "allow_blob_public_access" {
  description = "Autoriser l'accès public aux blobs"
  type        = bool
  default     = false
}

variable "shared_key_access_enabled" {
  description = "Activer l'authentification par clé partagée"
  type        = bool
  default     = false
}

variable "https_traffic_only_enabled" {
  description = "Forcer HTTPS uniquement"
  type        = bool
  default     = true
}

variable "enable_hierarchical_namespace" {
  description = "Activer hierarchical namespace (Data Lake Gen2)"
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

variable "blob_delete_retention_days" {
  description = "Jours de rétention pour soft delete des blobs"
  type        = number
  default     = 30
}

variable "container_delete_retention_days" {
  description = "Jours de rétention pour soft delete des conteneurs"
  type        = number
  default     = 30
}

variable "enable_point_in_time_restore" {
  description = "Activer la restauration point-in-time"
  type        = bool
  default     = false
}

variable "containers" {
  description = "Map des conteneurs à créer (nom => description)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}
