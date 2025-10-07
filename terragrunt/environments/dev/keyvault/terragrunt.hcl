# ============================================================================
# TERRAGRUNT: KEY VAULT
# Déploiement du Key Vault avec RBAC et sécurité renforcée
# ============================================================================

include "root" {
  path = find_in_parent_folders()
}

# Chargement de la configuration d'environnement
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
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
  source = "../../../modules/keyvault"
}

inputs = {
  # Configuration de base depuis le resource group
  resource_group_name = dependency.resource_group.outputs.resource_group_name
  location           = dependency.resource_group.outputs.location
  
  # Nom du Key Vault (limité à 24 caractères)
  key_vault_name = "tg-kv-dev-001"
  
  # Configuration spécifique à l'environnement
  sku_name                   = local.env_vars.locals.keyvault_config.sku_name
  enable_rbac_authorization  = local.env_vars.locals.keyvault_config.enable_rbac_authorization
  soft_delete_retention_days = local.env_vars.locals.keyvault_config.soft_delete_retention_days
  purge_protection_enabled   = local.env_vars.locals.keyvault_config.purge_protection_enabled
  
  # Règles réseau
  default_network_action = local.env_vars.locals.keyvault_config.network_rules.default_action
  allowed_ip_addresses   = local.env_vars.locals.keyvault_config.network_rules.allowed_ip_addresses
  allowed_subnet_ids     = local.env_vars.locals.keyvault_config.network_rules.allowed_subnet_ids
  
  # Tags
  tags = merge(
    local.env_vars.locals.environment_tags,
    {
      Component = "KeyVault"
    }
  )
}

# Configuration simplifiée