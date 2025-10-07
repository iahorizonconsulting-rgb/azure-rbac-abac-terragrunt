# ============================================================================
# TERRAGRUNT: RBAC + ABAC
# Déploiement des role assignments avec conditions ABAC
# ============================================================================

include "root" {
  path = find_in_parent_folders()
}

# ============================================================================
# CONFIGURATION LOCALE
# Chargement des variables d'environnement depuis le fichier env.hcl parent
# ============================================================================
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# ============================================================================
# DÉPENDANCES INTER-MODULES
# Définit les dépendances explicites et l'ordre de déploiement
# Mock outputs permettent les plans même si les dépendances ne sont pas déployées
# ============================================================================

# Dépendance sur le module Storage Account
# Nécessaire pour récupérer l'ID du Storage Account pour les role assignments
dependency "storage" {
  config_path = "../storage"
  
  # Commandes Terraform autorisées à utiliser les mock outputs
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  
  # Valeurs fictives utilisées pendant les plans avant déploiement réel
  mock_outputs = {
    storage_account_id = "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.Storage/storageAccounts/mockst"
  }
}

# Dépendance sur le module Key Vault
# Nécessaire pour les role assignments sur le Key Vault
dependency "keyvault" {
  config_path = "../keyvault"
  
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    key_vault_id = "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.KeyVault/vaults/mock-kv"
  }
}

# Dépendance sur le module Entra ID Groups
# Nécessaire pour récupérer les object_id des groupes pour les role assignments
dependency "entra" {
  config_path = "../entra"
  
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    groups = {
      "PublicUsers" = {
        object_id = "mock-group-id"
      }
    }
  }
}

# Dépendance sur le module Monitoring (optionnelle)
# Utilisée pour configurer les diagnostic settings si nécessaire
dependency "monitoring" {
  config_path = "../monitoring"
  
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    log_analytics_workspace_id = "/subscriptions/mock/resourceGroups/mock-rg/providers/Microsoft.OperationalInsights/workspaces/mock-logs"
  }
}

# ============================================================================
# MODULE SOURCE ET HOOKS
# ============================================================================
terraform {
  source = "../../../modules/rbac"           # Chemin vers le module Terraform RBAC
  
  # Hook de post-déploiement pour validation automatique
  # Exécute les tests de permissions ABAC après un apply réussi
  after_hook "test_rbac" {
    commands = ["apply"]                      # Déclenché uniquement après apply
    execute  = ["bash", "../../../scripts/test-rbac-permissions.sh", local.env_vars.locals.environment]
  }
}

# ============================================================================
# INPUTS DU MODULE
# Variables passées au module Terraform RBAC
# ============================================================================
inputs = {
  # ========== RESSOURCES AZURE ==========
  # IDs des ressources récupérés depuis les modules dépendants
  storage_account_id = dependency.storage.outputs.storage_account_id    # Pour les role assignments Storage
  key_vault_id      = dependency.keyvault.outputs.key_vault_id         # Pour les role assignments Key Vault
  
  # ========== IDENTITÉS ENTRA ID ==========
  # Groupes Entra ID avec leurs object_id pour les role assignments
  entra_groups = dependency.entra.outputs.groups
  
  # ========== CONFIGURATION ABAC ==========
  # Paramètres spécifiques à l'environnement pour les conditions ABAC
  abac_config = local.env_vars.locals.abac_config
}