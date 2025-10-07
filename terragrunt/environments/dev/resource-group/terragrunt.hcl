# ============================================================================
# TERRAGRUNT: RESOURCE GROUP
# Déploiement du groupe de ressources Azure
# ============================================================================

include "root" {
  path = find_in_parent_folders()
}

# Chargement de la configuration d'environnement
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../modules/resource-group"
}

inputs = {
  # Configuration de base
  app_name    = local.env_vars.locals.app_name
  environment = local.env_vars.locals.environment
  location    = local.env_vars.locals.location
  
  # Tags fusionnés
  tags = merge(
    local.env_vars.locals.environment_tags,
    {
      Component = "ResourceGroup"
    }
  )
}