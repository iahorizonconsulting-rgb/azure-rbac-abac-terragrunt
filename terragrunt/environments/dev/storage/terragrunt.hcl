# ============================================================================
# TERRAGRUNT: STORAGE ACCOUNT
# Déploiement du Storage Account avec Data Lake Gen2 et conteneurs
# ============================================================================

include "root" {
  path = find_in_parent_folders()
}

# ============================================================================
# CONFIGURATION LOCALE
# Chargement des configurations depuis les fichiers partagés
# ============================================================================
locals {
  # Variables spécifiques à l'environnement (dev/staging/prod)
  env_vars   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # Configuration des conteneurs blob partagée entre tous les environnements
  containers = read_terragrunt_config("../../../_common/storage-containers.hcl")
}

# Dépendance sur le resource group
dependency "resource_group" {
  config_path = "../resource-group"
  
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    resource_group_name = "mock-rg"
    location           = "westeurope"
  }
}

terraform {
  source = "../../../modules/storage"
}

# ============================================================================
# INPUTS DU MODULE STORAGE
# Configuration complète du Storage Account Azure avec Data Lake Gen2
# ============================================================================
inputs = {
  # ========== CONFIGURATION DE BASE ==========
  # Informations héritées du resource group parent
  resource_group_name = dependency.resource_group.outputs.resource_group_name
  location           = dependency.resource_group.outputs.location
  
  # Nom unique du Storage Account (doit être globalement unique sur Azure)
  storage_account_name = "tgsecureappdevst001"
  
  # ========== CONFIGURATION STORAGE ==========
  # Paramètres de performance et réplication adaptés à l'environnement
  account_tier                     = local.env_vars.locals.storage_config.account_tier              # Standard/Premium
  account_replication_type         = local.env_vars.locals.storage_config.account_replication_type  # LRS/GRS/GZRS
  enable_hierarchical_namespace    = local.env_vars.locals.storage_config.enable_hierarchical_namespace # Data Lake Gen2
  
  # ========== SÉCURITÉ ==========
  # Configuration de sécurité progressive selon l'environnement
  min_tls_version                 = local.env_vars.locals.storage_config.min_tls_version            # TLS 1.2 minimum
  allow_blob_public_access        = local.env_vars.locals.storage_config.allow_blob_public_access   # Pas d'accès public
  https_traffic_only_enabled      = local.env_vars.locals.storage_config.https_traffic_only_enabled # HTTPS uniquement
  shared_key_access_enabled       = local.env_vars.locals.storage_config.shared_key_access_enabled  # Clés partagées (dev only)
  
  # ========== RÈGLES RÉSEAU ==========
  # Contrôle d'accès réseau adapté par environnement (permissif en dev, restrictif en prod)
  default_network_action = local.env_vars.locals.storage_config.network_rules.default_action        # Allow/Deny
  allowed_ip_addresses   = local.env_vars.locals.storage_config.network_rules.allowed_ip_addresses  # Whitelist IP
  allowed_subnet_ids     = local.env_vars.locals.storage_config.network_rules.allowed_subnet_ids    # Whitelist subnets
  
  # ========== CONTENEURS BLOB ==========
  # Conteneurs organisés par domaine métier pour les conditions ABAC
  containers = local.containers.locals.blob_containers
  
  # ========== TAGS ==========
  # Tags de gouvernance et traçabilité
  tags = merge(
    local.env_vars.locals.environment_tags,    # Tags d'environnement (dev/staging/prod)
    {
      Component = "Storage"                     # Identification du composant
    }
  )
}

# Nom fixe pour éviter les conflits