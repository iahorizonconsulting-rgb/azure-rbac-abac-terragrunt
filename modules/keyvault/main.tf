# ============================================================================
# MODULE: AZURE KEY VAULT WITH RBAC
# ============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

# ============================================================================
# KEY VAULT
# ============================================================================

resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  sku_name = var.sku_name

  # ========== PROTECTION CRITIQUE DES DONNÉES ==========
  # FIX MAJEUR: Purge Protection activée (était false dans deploy.sh original)
  # ATTENTION: Une fois activée, cette protection ne peut JAMAIS être désactivée
  # Empêche la suppression définitive du Key Vault même par les administrateurs
  # Requis pour conformité SOC2, GDPR et protection contre les menaces internes
  purge_protection_enabled   = var.purge_protection_enabled
  
  # Soft Delete avec rétention longue (90 jours vs 7 par défaut)
  # Permet la récupération des secrets supprimés accidentellement
  soft_delete_retention_days = var.soft_delete_retention_days

  # ========== MODÈLE D'AUTORISATION MODERNE ==========
  # RBAC au lieu des Access Policies legacy (deprecated)
  # Avantages: Intégration Entra ID, audit centralisé, conditions ABAC futures
  # Permet l'utilisation des rôles Azure built-in (Key Vault Administrator, etc.)
  enable_rbac_authorization = var.enable_rbac_authorization

  # Network ACLs
  network_acls {
    bypass                     = "AzureServices"
    default_action             = var.default_network_action
    ip_rules                   = var.allowed_ip_addresses
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  # ÉVOLUTION TERRAFORM: Contact deprecated dans azurerm_key_vault
  # Nouvelle approche: Utiliser azurerm_key_vault_certificate_contacts séparément
  # Permet une gestion plus granulaire des contacts pour les certificats
  # TODO: Implémenter azurerm_key_vault_certificate_contacts si certificats requis

  tags = var.tags

  lifecycle {
    prevent_destroy = false # Dev uniquement - activer en production
  }
}

# ============================================================================
# PRIVATE ENDPOINT (optionnel, pour production)
# ============================================================================

resource "azurerm_private_endpoint" "kv" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.key_vault_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  tags = var.tags
}
