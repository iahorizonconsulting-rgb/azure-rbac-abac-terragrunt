# ============================================================================
# TERRAGRUNT: MONITORING
# Déploiement de Log Analytics et Application Insights
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
  source = "../../../modules/monitoring"
}

inputs = {
  # Configuration de base depuis le resource group
  resource_group_name = dependency.resource_group.outputs.resource_group_name
  location           = dependency.resource_group.outputs.location
  
  # Noms des ressources de monitoring
  log_analytics_name = "${local.env_vars.locals.app_name}-${local.env_vars.locals.environment}-logs"
  app_insights_name  = "${local.env_vars.locals.app_name}-${local.env_vars.locals.environment}-insights"
  
  # Configuration spécifique à l'environnement
  log_retention_days = local.env_vars.locals.monitoring_config.log_retention_days
  enable_alerting   = local.env_vars.locals.monitoring_config.enable_alerting
  
  # Tags
  tags = merge(
    local.env_vars.locals.environment_tags,
    {
      Component = "Monitoring"
    }
  )
}