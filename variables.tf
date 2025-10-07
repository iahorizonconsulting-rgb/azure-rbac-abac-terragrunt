# ============================================================================
# VARIABLES CONFIGURATION
# ============================================================================

variable "app_name" {
  description = "Nom de l'application (utilisé pour le nommage des ressources)"
  type        = string
  default     = "MySecureApp"

  validation {
    condition     = length(var.app_name) >= 3 && length(var.app_name) <= 24
    error_message = "Le nom de l'application doit contenir entre 3 et 24 caractères."
  }
}

variable "location" {
  description = "Région Azure pour le déploiement"
  type        = string
  default     = "westeurope"

  validation {
    condition     = contains(["westeurope", "northeurope", "francecentral", "eastus", "westus2"], var.location)
    error_message = "La région doit être une région Azure valide."
  }
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être dev, staging ou prod."
  }
}

# ============================================================================
# STORAGE ACCOUNT VARIABLES
# ============================================================================

variable "storage_account_tier" {
  description = "Tier du compte de stockage"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Le tier doit être Standard ou Premium."
  }
}

variable "storage_replication_type" {
  description = "Type de réplication du stockage - Impact sur coût et résilience"
  type        = string
  default     = "GZRS" # AMÉLIORATION CRITIQUE: Geo-Zone-Redundant Storage

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Type de réplication invalide. Options: LRS (économique), GRS (géo-réplication), GZRS (recommandé prod)."
  }

  # Guide de choix par environnement :
  # - Dev/Test: LRS (Local Redundant Storage) - Économique
  # - Staging: GRS (Geo Redundant Storage) - Test de la réplication
  # - Production: GZRS (Geo-Zone Redundant Storage) - Résilience maximale
}

variable "enable_hierarchical_namespace" {
  description = "Activer hierarchical namespace pour Data Lake Storage Gen2"
  type        = bool
  default     = true # AMÉLIORATION: Requis pour ABAC avancé et analytics

  # Avantages HNS (Hierarchical Namespace) :
  # ✅ Conditions ABAC avec chemins hiérarchiques
  # ✅ Performance améliorée pour big data (Spark, Hadoop)
  # ✅ Compatibilité Azure Synapse, Databricks, HDInsight
  # ❌ Incompatible avec versioning des blobs (limitation Azure)
  # ❌ Coût légèrement supérieur pour les opérations
}

# ============================================================================
# KEY VAULT VARIABLES
# ============================================================================

variable "key_vault_sku" {
  description = "SKU du Key Vault"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "Le SKU doit être standard ou premium."
  }
}

# ============================================================================
# MONITORING VARIABLES
# ============================================================================

variable "log_retention_days" {
  description = "Nombre de jours de rétention des logs"
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "La rétention doit être entre 30 et 730 jours."
  }
}

variable "enable_alerting" {
  description = "Activer les alertes Azure Monitor (AMÉLIORATION du rapport)"
  type        = bool
  default     = true
}

# ============================================================================
# ABAC CONFIGURATION VARIABLES
# ============================================================================

variable "abac_time_restrictions" {
  description = "Configuration des restrictions temporelles ABAC"
  type = object({
    start_hour = number
    end_hour   = number
  })
  default = {
    start_hour = 8
    end_hour   = 18
  }

  validation {
    condition     = var.abac_time_restrictions.start_hour >= 0 && var.abac_time_restrictions.start_hour <= 23
    error_message = "start_hour doit être entre 0 et 23."
  }

  validation {
    condition     = var.abac_time_restrictions.end_hour >= 0 && var.abac_time_restrictions.end_hour <= 23
    error_message = "end_hour doit être entre 0 et 23."
  }
}

# ============================================================================
# TAGS VARIABLES
# ============================================================================

variable "tags" {
  description = "Tags supplémentaires à appliquer aux ressources"
  type        = map(string)
  default = {
    Owner      = "Platform Team"
    CostCenter = "IT"
    Compliance = "GDPR"
  }
}

# ============================================================================
# NETWORK VARIABLES (pour Private Link - amélioration future)
# ============================================================================

variable "enable_private_endpoints" {
  description = "Activer les Private Endpoints pour Storage et Key Vault"
  type        = bool
  default     = false # TODO: Activer en production pour sécurité maximale

  # Private Endpoints - Avantages sécurité :
  # ✅ Trafic reste dans le réseau privé Azure (pas d'internet)
  # ✅ Protection contre exfiltration de données
  # ✅ Conformité réglementaire (GDPR, HIPAA, SOC2)
  # ❌ Complexité réseau supplémentaire
  # ❌ Coût additionnel (~€4/mois par endpoint)
}

variable "virtual_network_id" {
  description = "ID du Virtual Network pour Private Endpoints"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "ID du Subnet pour Private Endpoints"
  type        = string
  default     = null
}

variable "allowed_ip_addresses" {
  description = "Liste des adresses IP autorisées à accéder au Storage et Key Vault"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Liste des subnet IDs autorisés à accéder au Storage et Key Vault"
  type        = list(string)
  default     = []
}
