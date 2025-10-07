# ============================================================================
# MODULE: AZURE STORAGE ACCOUNT WITH ABAC
# ============================================================================

# Providers définis dans la configuration racine Terragrunt

# ============================================================================
# STORAGE ACCOUNT
# ============================================================================

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = "StorageV2"

  # ========== CONFIGURATION DE SÉCURITÉ RENFORCÉE ==========
  # Conformité aux standards de sécurité GDPR/SOC2/ISO27001
  min_tls_version                 = var.min_tls_version          # TLS 1.2 minimum obligatoire
  allow_nested_items_to_be_public = var.allow_blob_public_access # Désactivé: pas d'accès anonyme
  https_traffic_only_enabled      = var.https_traffic_only_enabled # HTTPS uniquement
  
  # Gestion des clés d'accès adaptée par environnement
  # IMPORTANT: En production, utiliser uniquement Entra ID (shared_access_key_enabled = false)
  # En développement, autorisé pour faciliter Terraform et outils CLI
  shared_access_key_enabled       = true  # TODO: Désactiver en production

  # ========== DATA LAKE STORAGE GEN2 ==========
  # Hierarchical Namespace requis pour :
  # - Conditions ABAC avancées avec chemins hiérarchiques
  # - Performance améliorée pour big data et analytics
  # - Compatibilité avec Azure Synapse et Databricks
  # LIMITATION: Incompatible avec le versioning des blobs
  is_hns_enabled = var.enable_hierarchical_namespace

  # ========== RÈGLES RÉSEAU PROGRESSIVES ==========
  # Stratégie de sécurité adaptée par environnement
  network_rules {
    default_action             = var.default_network_action  # Allow (dev) / Deny (prod)
    bypass                     = ["AzureServices"]           # Autoriser services Azure (monitoring, backup)
    ip_rules                   = var.allowed_ip_addresses    # Whitelist IP en production
    virtual_network_subnet_ids = var.allowed_subnet_ids     # Accès VNet restreint
  }

  # ========== PROPRIÉTÉS BLOB ET PROTECTION DES DONNÉES ==========
  blob_properties {
    # Versioning des blobs - LIMITATION AZURE: incompatible avec HNS
    # Si HNS activé (Data Lake Gen2), le versioning est automatiquement désactivé
    # Alternative: Utiliser les snapshots manuels ou Azure Backup
    versioning_enabled = !var.enable_hierarchical_namespace

    # Soft delete pour protection contre suppression accidentelle
    # Permet la récupération des blobs supprimés pendant la période de rétention
    delete_retention_policy {
      days = var.blob_delete_retention_days  # Défaut: 7 jours
    }

    # Soft delete pour les conteneurs (protection supplémentaire)
    container_delete_retention_policy {
      days = var.container_delete_retention_days  # Défaut: 7 jours
    }

    # Point-in-Time Restore (optionnel) - Restauration à un moment précis
    # Utile pour récupération après corruption ou attaque ransomware
    # ATTENTION: Coût supplémentaire et complexité opérationnelle
    dynamic "restore_policy" {
      for_each = var.enable_point_in_time_restore ? [1] : []
      content {
        days = 7  # Fenêtre de restauration de 7 jours
      }
    }
  }

  # Identity pour Managed Identity
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false # Dev uniquement - activer en production
  }
}

# ============================================================================
# BLOB CONTAINERS
# ============================================================================

resource "azurerm_storage_container" "containers" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private" # Toujours privé

  # LIMITATION TECHNIQUE: Metadata désactivée temporairement
  # Problème: Terraform provider nécessite shared_access_key pour metadata
  # Solution temporaire: Metadata gérée manuellement ou via Azure CLI
  # TODO: Réactiver quand Entra ID sera supporté pour metadata
  # metadata = {
  #   description = each.value
  #   managed_by  = "terraform"
  #   created_by  = "terraform-abac-deployment"
  # }
}

# ============================================================================
# LIFECYCLE MANAGEMENT (AMÉLIORATION du rapport)
# ============================================================================

resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "archive-old-blobs"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["archives/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }

      snapshot {
        delete_after_days_since_creation_greater_than = 90
      }
    }
  }

  rule {
    name    = "delete-temporary-uploads"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["temporary-uploads/"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 7
      }
    }
  }
}

# ============================================================================
# DIAGNOSTIC SETTINGS
# ============================================================================

# Note: Diagnostic settings sont configurés dans le module parent
# pour permettre la liaison avec Log Analytics Workspace
