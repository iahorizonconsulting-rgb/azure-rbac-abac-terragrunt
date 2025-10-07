# ============================================================================
# TERRAGRUNT ROOT CONFIGURATION
# Configuration partagée pour tous les environnements Azure RBAC + ABAC
# ============================================================================

# ============================================================================
# BACKEND REMOTE STATE CONFIGURATION
# Génération automatique du backend Azure Storage pour tous les modules
# Chaque module aura sa propre clé d'état unique basée sur son chemin
# ============================================================================
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"                    # Fichier généré automatiquement
    if_exists = "overwrite_terragrunt"          # Écrase le fichier existant
  }
  config = {
    resource_group_name  = "terragrunt-state-rg"                           # RG dédié au state
    storage_account_name = "tgstate${get_env("TF_VAR_environment", "dev")}" # Nom unique par env
    container_name       = "tfstate"                                       # Conteneur pour les states
    key                  = "${path_relative_to_include()}/terraform.tfstate" # Clé unique par module
  }
}

# ============================================================================
# PROVIDERS CONFIGURATION GENERATION
# Génère automatiquement le fichier provider.tf dans chaque module
# Évite la duplication de configuration des providers dans chaque module
# ============================================================================
generate "provider" {
  path      = "provider.tf"                    # Fichier généré dans chaque module
  if_exists = "overwrite_terragrunt"          # Écrase si existe déjà
  contents = <<EOF
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
}

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
}

provider "azuread" {}
EOF
}

# ============================================================================
# INPUTS GLOBAUX
# Variables partagées par tous les modules enfants
# Ces inputs sont automatiquement fusionnés avec les inputs spécifiques
# ============================================================================
inputs = {
  # Tags communs appliqués à toutes les ressources Azure
  common_tags = {
    ManagedBy   = "Terragrunt"              # Indique que la ressource est gérée par Terragrunt
    CreatedDate = timestamp()               # Timestamp de création pour audit
  }
}