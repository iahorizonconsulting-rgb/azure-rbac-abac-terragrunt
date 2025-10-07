# ============================================================================
# TERRAGRUNT: ENTRA ID GROUPS
# Déploiement des groupes Entra ID pour RBAC
# ============================================================================

include "root" {
  path = find_in_parent_folders()
}

# Chargement des configurations
locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  entra_groups = read_terragrunt_config("../../../_common/entra-groups.hcl")
}

terraform {
  source = "../../../modules/entra"
}

inputs = {
  # Configuration de base
  app_name = local.env_vars.locals.app_name
  
  # Groupes Entra ID depuis la configuration commune
  groups = local.entra_groups.locals.entra_groups
  
  # Tags
  tags = merge(
    local.env_vars.locals.environment_tags,
    {
      Component = "EntraID"
    }
  )
}