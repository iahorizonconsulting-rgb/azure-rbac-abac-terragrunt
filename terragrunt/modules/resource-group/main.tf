# ============================================================================
# MODULE: AZURE RESOURCE GROUP
# Création du groupe de ressources Azure
# ============================================================================

# Providers définis dans la configuration racine Terragrunt

# ============================================================================
# LOCALS
# ============================================================================

locals {
  resource_group_name = "${var.app_name}-${var.environment}-rg"
  
  # Tags avec timestamp pour audit
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Application = var.app_name
      ManagedBy   = "Terragrunt"
      CreatedDate = timestamp()
    }
  )
}

# ============================================================================
# RESOURCE GROUP
# ============================================================================

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}