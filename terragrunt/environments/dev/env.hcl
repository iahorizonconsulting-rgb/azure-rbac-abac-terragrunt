# ============================================================================
# CONFIGURATION ENVIRONNEMENT: DÉVELOPPEMENT
# Variables spécifiques à l'environnement de développement
# ============================================================================

locals {
  # Configuration de base
  environment = "dev"
  app_name    = "TerragruntSecureApp"  # Nom différent pour éviter les conflits
  location    = "westeurope"

  # Tags spécifiques à l'environnement
  environment_tags = {
    Environment = "dev"
    CostCenter  = "Development"
    Owner       = "Dev Team"
  }

  # Configuration Storage Account - Permissive pour développement
  storage_config = {
    account_tier                      = "Standard"
    account_replication_type          = "LRS"  # Économique pour dev
    enable_hierarchical_namespace     = true
    min_tls_version                  = "TLS1_2"
    allow_blob_public_access         = false
    https_traffic_only_enabled       = true
    shared_key_access_enabled        = true   # Facilite les tests
    
    # Règles réseau permissives pour développement
    network_rules = {
      default_action       = "Allow"  # Accès ouvert pour dev
      allowed_ip_addresses = []
      allowed_subnet_ids   = []
    }
  }

  # Configuration Key Vault - Sécurité standard
  keyvault_config = {
    sku_name                   = "standard"
    enable_rbac_authorization  = true
    soft_delete_retention_days = 90
    purge_protection_enabled   = false  # Permet suppression en dev
    
    # Règles réseau identiques au storage
    network_rules = {
      default_action       = "Allow"
      allowed_ip_addresses = []
      allowed_subnet_ids   = []
    }
  }

  # Configuration Monitoring - Léger pour dev
  monitoring_config = {
    log_retention_days = 30    # Court pour économiser
    enable_alerting   = false  # Pas d'alertes en dev
  }

  # Configuration ABAC - Restrictions temporelles pour tests
  abac_config = {
    time_restrictions = {
      start_hour = 0   # 24h/24 en dev
      end_hour   = 23
    }
  }
}