output "storage_account_id" {
  description = "ID du compte de stockage"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Nom du compte de stockage"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Endpoint primaire Blob"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "Host primaire Blob"
  value       = azurerm_storage_account.main.primary_blob_host
}

output "containers" {
  description = "Conteneurs créés"
  value       = { for k, v in azurerm_storage_container.containers : k => v.id }
}

output "identity_principal_id" {
  description = "Principal ID de l'identité managée du Storage Account"
  value       = azurerm_storage_account.main.identity[0].principal_id
}
