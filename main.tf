# ============================================================================
# MAIN TERRAFORM CONFIGURATION
# Infrastructure Azure avec RBAC + ABAC
# Basé sur deploy.sh avec améliorations du rapport cloudeanalyse.md
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }

  # Backend configuration - uncomment for remote state
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstate"
  #   container_name       = "tfstate"
  #   key                  = "myapp.terraform.tfstate"
  # }
}

# ============================================================================
# PROVIDERS CONFIGURATION
# ============================================================================

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }

  # Dev: use shared keys for Terraform, production: use Entra ID
  # storage_use_azuread = true
}

provider "azuread" {}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

# ============================================================================
# LOCALS: CONFIGURATION DES RESSOURCES
# Définit les noms, tags et configurations partagées entre tous les modules
# Permet une gestion centralisée et cohérente des ressources Azure
# ============================================================================

locals {
  # Configuration de base héritée des variables d'entrée
  app_name    = var.app_name
  location    = var.location
  environment = var.environment

  # Tags standardisés appliqués à toutes les ressources Azure
  # Permet le suivi des coûts, la gouvernance et la conformité GDPR/SOC2
  # CreatedDate en timestamp pour audit et lifecycle management
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Application = local.app_name
      ManagedBy   = "Terraform"
      CreatedDate = timestamp()
    }
  )

  # Convention de nommage Azure cohérente et prévisible
  # Format: {app}-{env}-{type} pour faciliter l'identification
  resource_group_name  = "${local.app_name}-${var.environment}-rg"
  
  # Nom du Storage Account - doit être unique globalement (3-24 chars, alphanumériques)
  # Suppression des caractères spéciaux pour respecter les contraintes Azure
  storage_account_name = lower(replace("${local.app_name}${var.environment}st${random_string.suffix.result}", "/[^a-z0-9]/", ""))
  
  # Key Vault limité à 24 caractères maximum par Azure
  key_vault_name       = "kv-${var.environment}-${random_string.suffix.result}"
  
  # Noms des ressources de monitoring pour traçabilité
  log_analytics_name   = "${local.app_name}-${var.environment}-logs"
  app_insights_name    = "${local.app_name}-${var.environment}-insights"

  # Conteneurs blob organisés par domaine métier et niveau de sécurité
  # Chaque conteneur correspond à une condition ABAC spécifique
  # Utilisés pour la ségrégation des données et le contrôle d'accès granulaire
  blob_containers = {
    "public-documents"   = "Documents publics - accès lecture pour tous (condition ABAC PublicUsers)"
    "department-finance" = "Département Finance uniquement (condition ABAC FinanceTeam)"
    "department-sales"   = "Département Sales uniquement (condition ABAC SalesTeam)"
    "department-it"      = "Département IT - gestion technique (accès complet sans ABAC)"
    "department-hr"      = "Département Ressources Humaines (accès complet HRTeam)"
    "project-alpha"      = "Projet Alpha (condition ABAC ProjectAlpha avec tags)"
    "project-beta"       = "Projet Beta (accès équipe projet uniquement)"
    "project-gamma"      = "Projet Gamma (accès équipe projet uniquement)"
    "confidential"       = "Documents confidentiels - haute sécurité (exclus des Executives)"
    "temporary-uploads"  = "Zone temporaire - nettoyage automatique 7 jours"
    "archives"           = "Archives - lifecycle policy vers stockage froid"
  }

  # Groupes Entra ID organisés par fonction métier et niveau d'accès
  # Chaque groupe correspond à un rôle RBAC et potentiellement une condition ABAC
  # Les rôles définissent les permissions de base, les conditions ABAC ajoutent des restrictions
  entra_groups = {
    # ========== GROUPES AVEC CONDITIONS ABAC ==========
    "PublicUsers" = {
      description = "Utilisateurs externes - Accès lecture documents publics uniquement (ABAC: conteneur public-documents)"
      role        = "Reader"  # Storage Blob Data Reader avec condition ABAC
    }
    "Executives" = {
      description = "Cadres dirigeants - Accès lecture tous départements sauf confidentiels (ABAC: exclusion Classification=Confidential)"
      role        = "Reader"  # Condition ABAC pour exclure les documents confidentiels
    }
    "FinanceTeam" = {
      description = "Équipe Finance - Accès complet département Finance (ABAC: conteneur department-finance OU tag Department=Finance)"
      role        = "Contributor"  # Lecture/écriture avec condition ABAC
    }
    "SalesTeam" = {
      description = "Équipe Sales - Accès complet département Sales (ABAC: conteneur department-sales OU tag Department=Sales)"
      role        = "Contributor"  # Lecture/écriture avec condition ABAC
    }
    "ProjectAlpha" = {
      description = "Membres projet Alpha - Accès ressources projet (ABAC: conteneur project-alpha OU tag Project=Alpha)"
      role        = "Contributor"  # Condition ABAC basée sur conteneur et tags
    }
    "Contractors" = {
      description = "Contractuels externes - Accès limité et temporaire (ABAC: tag ExternalAccess=Allowed + restrictions horaires)"
      role        = "Reader"  # Accès très restreint avec conditions ABAC multiples
    }
    
    # ========== GROUPES SANS CONDITIONS ABAC ==========
    "SecurityOfficers" = {
      description = "Officiers de sécurité - Accès complet SANS restriction (pas de condition ABAC)"
      role        = "Owner"  # Accès total pour gestion sécurité et incidents
    }
    "Auditors" = {
      description = "Auditeurs - Accès lecture complète pour conformité (pas de condition ABAC)"
      role        = "Reader"  # Lecture seule sur toutes les ressources
    }
    "ITTeam" = {
      description = "Équipe IT - Accès complet pour gestion technique (pas de condition ABAC)"
      role        = "Contributor"  # Gestion technique sans restriction
    }
    "HRTeam" = {
      description = "Équipe RH - Accès complet département Ressources Humaines"
      role        = "Contributor"  # Accès complet conteneur department-hr
    }
    "ProjectBeta" = {
      description = "Membres projet Beta - Accès ressources projet Beta"
      role        = "Contributor"  # Accès conteneur project-beta
    }
    "ProjectGamma" = {
      description = "Membres projet Gamma - Accès ressources projet Gamma"
      role        = "Contributor"  # Accès conteneur project-gamma
    }
    "DataScientists" = {
      description = "Data Scientists - Accès lecture données pour analyse et ML"
      role        = "Reader"  # Lecture seule pour analyse de données
    }
  }
}

# ============================================================================
# RANDOM RESOURCES
# ============================================================================

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.common_tags
}

# ============================================================================
# MODULES
# ============================================================================

# Module: Entra ID Groups
module "entra_groups" {
  source = "./modules/entra"

  app_name = local.app_name
  groups   = local.entra_groups
  tags     = local.common_tags
}

# ============================================================================
# MODULE: STORAGE ACCOUNT AVEC ABAC
# Déploie un Storage Account Azure avec Data Lake Gen2 et conditions ABAC
# Sécurité progressive : permissive en dev, restrictive en production
# ============================================================================
module "storage" {
  source = "./modules/storage"

  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  storage_account_name = local.storage_account_name

  # AMÉLIORATION CRITIQUE: Geo-redundancy pour haute disponibilité
  # Dev: LRS (économique), Prod: GZRS (résilience géographique)
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  # AMÉLIORATION: Hierarchical Namespace pour Data Lake Gen2
  # Requis pour les conditions ABAC avancées et l'organisation hiérarchique
  # Note: Incompatible avec le versioning (limitation Azure)
  enable_hierarchical_namespace = var.enable_hierarchical_namespace

  # Configuration de sécurité renforcée (conformité GDPR/SOC2)
  min_tls_version            = "TLS1_2"                    # TLS 1.2 minimum obligatoire
  allow_blob_public_access   = false                      # Pas d'accès public anonyme
  https_traffic_only_enabled = true                       # HTTPS uniquement
  
  # Gestion des clés d'accès adaptée par environnement
  # Dev: Shared keys activées pour faciliter Terraform et tests
  # Prod: Entra ID uniquement pour sécurité maximale
  shared_key_access_enabled  = var.environment == "dev" ? true : false

  # Règles réseau progressives selon l'environnement
  # Dev: "Allow" pour faciliter développement et débogage
  # Prod: "Deny" avec whitelist IP pour sécurité maximale
  default_network_action = var.environment == "dev" ? "Allow" : "Deny"
  allowed_ip_addresses   = var.environment == "dev" ? [] : var.allowed_ip_addresses
  allowed_subnet_ids     = var.environment == "dev" ? [] : var.allowed_subnet_ids

  # Conteneurs organisés par domaine métier (voir local.blob_containers)
  containers = local.blob_containers

  tags = local.common_tags

  # Dépendance explicite pour s'assurer que le RG existe avant le Storage
  depends_on = [azurerm_resource_group.main]
}

# ============================================================================
# MODULE: KEY VAULT AVEC RBAC
# Déploie un Key Vault sécurisé pour la gestion des secrets et clés
# Configuration haute sécurité avec Purge Protection (fix critique)
# ============================================================================
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  key_vault_name      = local.key_vault_name

  tenant_id = data.azurerm_client_config.current.tenant_id

  # Configuration de sécurité maximale
  enable_rbac_authorization  = true  # RBAC au lieu des Access Policies legacy
  soft_delete_retention_days = 90    # Rétention soft delete pour récupération

  # FIX CRITIQUE: Purge Protection activée (était false dans deploy.sh)
  # Une fois activée, ne peut plus être désactivée - protection permanente
  # Empêche la suppression définitive accidentelle des secrets critiques
  purge_protection_enabled = true

  # Règles réseau identiques au Storage Account pour cohérence
  # Dev: Accès ouvert pour développement, Prod: Accès restreint
  default_network_action = var.environment == "dev" ? "Allow" : "Deny"
  allowed_ip_addresses   = var.environment == "dev" ? [] : var.allowed_ip_addresses
  allowed_subnet_ids     = var.environment == "dev" ? [] : var.allowed_subnet_ids

  tags = local.common_tags

  # Dépendance explicite pour ordre de création
  depends_on = [azurerm_resource_group.main]
}

# Module: Monitoring (Log Analytics + App Insights)
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  log_analytics_name  = local.log_analytics_name
  app_insights_name   = local.app_insights_name

  log_retention_days = var.log_retention_days

  tags = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

# ============================================================================
# MODULE: RBAC + ABAC ROLE ASSIGNMENTS
# Configure les permissions d'accès avec conditions ABAC sophistiquées
# 15 role assignments dont 7 avec conditions ABAC version 2.0
# ============================================================================
module "rbac" {
  source = "./modules/rbac"

  storage_account_id = module.storage.storage_account_id
  key_vault_id       = module.keyvault.key_vault_id

  # Groupes Entra ID créés par le module entra (object_id requis)
  entra_groups = module.entra_groups.groups

  # Dépendances explicites requises pour :
  # - module.storage : Besoin de l'ID du Storage Account pour les role assignments
  # - module.keyvault : Besoin de l'ID du Key Vault pour les permissions RBAC
  # - module.entra_groups : Besoin des object_id des groupes pour les assignments
  depends_on = [
    module.storage,
    module.keyvault,
    module.entra_groups
  ]
}

# ============================================================================
# DIAGNOSTIC SETTINGS: MONITORING ET AUDIT
# Configure la collecte des logs pour surveillance des accès et conformité
# Logs envoyés vers Log Analytics pour analyse et alerting
# ============================================================================
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "${local.app_name}-storage-blob-diagnostics"
  target_resource_id         = "${module.storage.storage_account_id}/blobServices/default"
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  # Logs d'accès en lecture - Audit des consultations
  # Utile pour détecter les accès non autorisés ou suspects
  enabled_log {
    category = "StorageRead"
  }

  # Logs d'écriture - Traçabilité des modifications
  # Critique pour audit et investigation d'incidents
  enabled_log {
    category = "StorageWrite"
  }

  # Logs de suppression - Audit des destructions de données
  # Essentiel pour conformité GDPR (droit à l'oubli)
  enabled_log {
    category = "StorageDelete"
  }

  # Métriques de transaction - Performance et volumétrie
  # Permet le monitoring des violations ABAC (StatusCode 403)
  metric {
    category = "Transaction"
    enabled  = true
  }

  depends_on = [module.storage]
}

# ============================================================================
# EXEMPLES D'USAGE DES CONDITIONS ABAC
# 
# Test PublicUsers (lecture seule conteneur public) :
# az storage blob upload --account-name {storage} --container-name public-documents --name test.txt --file test.txt --auth-mode login
# → Succès (200)
# az storage blob upload --account-name {storage} --container-name confidential --name test.txt --file test.txt --auth-mode login  
# → Échec (403 Forbidden)
#
# Test FinanceTeam (conteneur + tags) :
# az storage blob upload --account-name {storage} --container-name department-finance --name budget.xlsx --file budget.xlsx --auth-mode login
# → Succès (200)
# az storage blob upload --account-name {storage} --container-name archives --name report.pdf --file report.pdf --tags Department=Finance --auth-mode login
# → Succès (200) - Tag Department=Finance autorise l'accès
#
# Test Executives (exclusion confidentiels) :
# az storage blob upload --account-name {storage} --container-name department-sales --name prospects.xlsx --file prospects.xlsx --auth-mode login
# → Succès (200)
# az storage blob upload --account-name {storage} --container-name confidential --name secret.txt --file secret.txt --auth-mode login
# → Échec (403 Forbidden) - Exclusion des confidentiels
# ============================================================================

# ============================================================================
# OUTPUTS
# ============================================================================

output "resource_group_name" {
  description = "Nom du resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Nom du compte de stockage"
  value       = module.storage.storage_account_name
}

output "storage_account_id" {
  description = "ID du compte de stockage"
  value       = module.storage.storage_account_id
}

output "key_vault_name" {
  description = "Nom du Key Vault"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "URI du Key Vault"
  value       = module.keyvault.key_vault_uri
}

output "log_analytics_workspace_id" {
  description = "ID du Log Analytics Workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "app_insights_instrumentation_key" {
  description = "Clé d'instrumentation App Insights"
  value       = module.monitoring.app_insights_instrumentation_key
  sensitive   = true
}

output "entra_groups" {
  description = "Groupes Entra ID créés"
  value       = { for k, v in module.entra_groups.groups : k => v.display_name }
}

output "portal_links" {
  description = "Liens vers le portail Azure"
  value = {
    resource_group = "https://portal.azure.com/#resource${azurerm_resource_group.main.id}"
    storage        = "https://portal.azure.com/#resource${module.storage.storage_account_id}"
    key_vault      = "https://portal.azure.com/#resource${module.keyvault.key_vault_id}"
    log_analytics  = "https://portal.azure.com/#resource${module.monitoring.log_analytics_workspace_id}"
  }
}
