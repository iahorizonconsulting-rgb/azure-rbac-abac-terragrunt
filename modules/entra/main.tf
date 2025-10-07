# ============================================================================
# MODULE: MICROSOFT ENTRA ID GROUPS
# ============================================================================

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
  }
}

resource "azuread_group" "groups" {
  for_each = var.groups

  display_name     = "${var.app_name}_${each.key}"
  security_enabled = true
  description      = each.value.description
  mail_enabled     = false

  lifecycle {
    ignore_changes = [members] # Ne pas gérer les membres via Terraform
  }
}
