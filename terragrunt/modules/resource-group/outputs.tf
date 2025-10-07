# ============================================================================
# OUTPUTS: RESOURCE GROUP MODULE
# ============================================================================

output "resource_group_name" {
  description = "Nom du resource group créé"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID du resource group créé"
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Localisation du resource group"
  value       = azurerm_resource_group.main.location
}