# ============================================================================
# MODULE: AZURE RBAC WITH ABAC CONDITIONS
# Implémentation des conditions ABAC du script deploy.sh
# ============================================================================

# Providers définis dans la configuration racine Terragrunt

# ============================================================================
# LOCALS: DÉFINITION DES CONDITIONS ABAC VERSION 2.0
# Implémente 7 conditions sophistiquées pour contrôle d'accès granulaire
# Chaque condition utilise la syntaxe Azure ABAC avec opérateurs logiques
# ============================================================================

locals {
  # ========== CONDITION 1: PublicUsers ==========
  # Restriction: Accès LECTURE SEULE au conteneur 'public-documents' uniquement
  # Cas d'usage: Utilisateurs externes, partenaires, consultants
  # Test: Créer blob dans 'public-documents' → OK, dans 'confidential' → 403
  condition_public = <<-EOT
    (
      (
        !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'}
          AND NOT SubOperationMatches{'Blob.List'})
      )
      OR
      (
        @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'public-documents'
      )
    )
  EOT

  # ========== CONDITION 2: FinanceTeam ==========
  # Restriction: Conteneur 'department-finance' OU blobs taggés 'Department=Finance'
  # Cas d'usage: Équipe comptabilité, contrôleurs de gestion, CFO
  # Test: Blob avec tag 'Department=Finance' dans n'importe quel conteneur → OK
  condition_finance = <<-EOT
    (
      (
        @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'department-finance'
      )
      OR
      (
        @Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags:Department<$key_case_sensitive$>] StringEquals 'Finance'
      )
    )
  EOT

  # ========== CONDITION 3: SalesTeam ==========
  # Restriction: Conteneur 'department-sales' OU blobs taggés 'Department=Sales'
  # Cas d'usage: Équipe commerciale, business development, CRM
  # Test: Accès prospects dans 'department-sales' → OK, factures dans 'department-finance' → 403
  condition_sales = <<-EOT
    (
      (
        @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'department-sales'
      )
      OR
      (
        @Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags:Department<$key_case_sensitive$>] StringEquals 'Sales'
      )
    )
  EOT

  # ========== CONDITION 4: ProjectAlpha ==========
  # Restriction: Conteneur 'project-alpha' OU blobs taggés 'Project=Alpha'
  # Cas d'usage: Équipe projet spécifique, développement produit, R&D
  # Test: Document avec tag 'Project=Alpha' dans 'archives' → OK
  condition_project_alpha = <<-EOT
    (
      (
        @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'project-alpha'
      )
      OR
      (
        @Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags:Project<$key_case_sensitive$>] StringEquals 'Alpha'
      )
    )
  EOT

  # ========== CONDITION 5: Executives ==========
  # Restriction: EXCLUSION des documents confidentiels (conteneur + tag)
  # Cas d'usage: Direction générale, accès large mais pas aux secrets industriels
  # Test: Accès 'department-finance' → OK, accès 'confidential' → 403
  condition_executives = <<-EOT
    (
      (
        !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'}
          AND NOT SubOperationMatches{'Blob.List'})
      )
      OR
      (
        NOT @Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags:Classification<$key_case_sensitive$>] StringEquals 'Confidential'
        AND
        NOT @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'confidential'
      )
    )
  EOT

  # ========== CONDITION 6: Contractors ==========
  # Restriction: Uniquement ressources explicitement autorisées pour externes
  # Cas d'usage: Prestataires, freelances, consultants temporaires
  # Test: Blob avec tag 'ExternalAccess=Allowed' → OK, autres → 403
  condition_contractors = <<-EOT
    (
      (
        !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'}
          AND NOT SubOperationMatches{'Blob.List'})
      )
      OR
      (
        (
          @Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags:ExternalAccess<$key_case_sensitive$>] StringEquals 'Allowed'
        )
        OR
        (
          @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'temporary-uploads'
        )
      )
    )
  EOT

  # ========== MAPPING DES RÔLES AZURE BUILT-IN ==========
  # Correspondance entre rôles logiques et rôles Azure natifs
  # Reader: Lecture seule (list, read blobs)
  # Contributor: Lecture + écriture (create, update, delete blobs)
  # Owner: Permissions complètes (+ gestion ACL, metadata)
  role_definitions = {
    "Reader"      = "Storage Blob Data Reader"      # Lecture seule
    "Contributor" = "Storage Blob Data Contributor" # Lecture + écriture
    "Owner"       = "Storage Blob Data Owner"       # Permissions complètes
  }
}

# ============================================================================
# RBAC: STORAGE ACCOUNT ROLE ASSIGNMENTS WITH ABAC
# 15 role assignments au total dont 7 avec conditions ABAC version 2.0
# Stratégie: Permissions de base via RBAC + restrictions via ABAC
# ============================================================================

# ========== GROUPE: PublicUsers (AVEC ABAC) ==========
# Rôle: Storage Blob Data Reader (lecture seule)
# Condition ABAC: Accès uniquement conteneur 'public-documents'
# Cas d'usage: Utilisateurs externes, documentation publique
resource "azurerm_role_assignment" "public_users" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.entra_groups["PublicUsers"].object_id
  description          = "ABAC: Accès lecture seule conteneur public-documents uniquement"
  condition            = local.condition_public
  condition_version    = "2.0"
}

# ========== GROUPE: FinanceTeam (AVEC ABAC) ==========
# Rôle: Storage Blob Data Contributor (lecture + écriture)
# Condition ABAC: Conteneur 'department-finance' OU tag 'Department=Finance'
# Cas d'usage: Comptabilité, contrôle de gestion, budgets
resource "azurerm_role_assignment" "finance" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.entra_groups["FinanceTeam"].object_id
  description          = "ABAC: Accès département Finance (conteneur + tags Department=Finance)"
  condition            = local.condition_finance
  condition_version    = "2.0"
}

# ========== GROUPE: SalesTeam (AVEC ABAC) ==========
# Rôle: Storage Blob Data Contributor (lecture + écriture)
# Condition ABAC: Conteneur 'department-sales' OU tag 'Department=Sales'
# Cas d'usage: Équipe commerciale, CRM, prospects, contrats
resource "azurerm_role_assignment" "sales" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.entra_groups["SalesTeam"].object_id
  description          = "ABAC: Accès département Sales (conteneur + tags Department=Sales)"
  condition            = local.condition_sales
  condition_version    = "2.0"
}

# ========== GROUPE: ITTeam (SANS ABAC) ==========
# Rôle: Storage Blob Data Contributor (lecture + écriture)
# Condition ABAC: AUCUNE - Accès complet pour gestion technique
# Cas d'usage: Administration, maintenance, support technique, débogage
resource "azurerm_role_assignment" "it" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.entra_groups["ITTeam"].object_id
  description          = "Accès complet sans restriction - Gestion technique et support"
}

# ========== GROUPE: HRTeam (SANS ABAC) ==========
# Rôle: Storage Blob Data Contributor (lecture + écriture)
# Condition ABAC: AUCUNE - Accès complet conteneur department-hr
# Cas d'usage: Ressources humaines, paie, recrutement, formation
resource "azurerm_role_assignment" "hr" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.entra_groups["HRTeam"].object_id
  description          = "Accès complet département Ressources Humaines"
}

# ProjectAlpha: Accès projet Alpha avec ABAC
resource "azurerm_role_assignment" "project_alpha" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.entra_groups["ProjectAlpha"].object_id
  description          = "ABAC: Accès projet Alpha uniquement"
  condition            = local.condition_project_alpha
  condition_version    = "2.0"
}

# ProjectBeta: Accès projet Beta
resource "azurerm_role_assignment" "project_beta" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.entra_groups["ProjectBeta"].object_id
  description          = "Accès projet Beta"
}

# ProjectGamma: Accès projet Gamma
resource "azurerm_role_assignment" "project_gamma" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.entra_groups["ProjectGamma"].object_id
  description          = "Accès projet Gamma"
}

# Executives: Lecture sauf confidentiels
resource "azurerm_role_assignment" "executives" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.entra_groups["Executives"].object_id
  description          = "ABAC: Exclusion documents confidentiels"
  condition            = local.condition_executives
  condition_version    = "2.0"
}

# SecurityOfficers: Accès complet sans restriction
resource "azurerm_role_assignment" "security" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.entra_groups["SecurityOfficers"].object_id
  description          = "Accès complet incluant confidentiels (pas de restriction ABAC)"
}

# Auditors: Lecture seule pour audit
resource "azurerm_role_assignment" "auditors" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.entra_groups["Auditors"].object_id
  description          = "Lecture seule pour audit"
}

# Contractors: Accès limité avec ABAC
resource "azurerm_role_assignment" "contractors" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.entra_groups["Contractors"].object_id
  description          = "ABAC: Accès limité contractuels externes"
  condition            = local.condition_contractors
  condition_version    = "2.0"
}

# DataScientists: Lecture pour analyse
resource "azurerm_role_assignment" "data_scientists" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.entra_groups["DataScientists"].object_id
  description          = "Lecture données pour analyse"
}

# ============================================================================
# RBAC: KEY VAULT ROLE ASSIGNMENTS
# ============================================================================

# SecurityOfficers: Accès complet Key Vault
resource "azurerm_role_assignment" "kv_security" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.entra_groups["SecurityOfficers"].object_id
  description          = "Administration complète du Key Vault"
}

# ITTeam: Gestion des secrets
resource "azurerm_role_assignment" "kv_it" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.entra_groups["ITTeam"].object_id
  description          = "Gestion des secrets pour IT"
}
