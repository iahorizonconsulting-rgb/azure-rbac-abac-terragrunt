output "groups" {
  value = azuread_group.groups
}

output "group_ids" {
  value = { for k, v in azuread_group.groups : k => v.object_id }
}
