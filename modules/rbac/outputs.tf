output "role_assignments" {
  description = "Liste des role assignments créés"
  value = {
    storage_assignments = [
      azurerm_role_assignment.public_users.id,
      azurerm_role_assignment.finance.id,
      azurerm_role_assignment.sales.id,
      azurerm_role_assignment.executives.id,
      azurerm_role_assignment.contractors.id
    ]
  }
}
