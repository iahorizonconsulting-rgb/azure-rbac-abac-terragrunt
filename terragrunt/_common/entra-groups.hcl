# ============================================================================
# CONFIGURATION COMMUNE: GROUPES ENTRA ID
# Définition centralisée des groupes et rôles pour tous les environnements
# ============================================================================

locals {
  # ============================================================================
  # DÉFINITION DES GROUPES ENTRA ID
  # Architecture RBAC + ABAC : Chaque groupe a un rôle de base (RBAC) 
  # et optionnellement des conditions d'accès granulaires (ABAC)
  # ============================================================================
  entra_groups = {
    
    # ========== GROUPES AVEC CONDITIONS ABAC ==========
    # Ces groupes ont des restrictions d'accès basées sur des conditions
    # Les conditions ABAC sont implémentées dans le module rbac/main.tf
    
    "PublicUsers" = {
      description = "Utilisateurs externes - Accès lecture documents publics uniquement (ABAC: conteneur public-documents)"
      role        = "Reader"              # Rôle de base : lecture seule
      # Condition ABAC : Accès uniquement au conteneur 'public-documents'
    }
    "Executives" = {
      description = "Cadres dirigeants - Accès lecture tous départements sauf confidentiels (ABAC: exclusion Classification=Confidential)"
      role        = "Reader"              # Rôle de base : lecture seule
      # Condition ABAC : Accès à tout SAUF conteneur 'confidential' et blobs taggés 'Classification=Confidential'
    }
    
    "FinanceTeam" = {
      description = "Équipe Finance - Accès complet département Finance (ABAC: conteneur department-finance OU tag Department=Finance)"
      role        = "Contributor"         # Rôle de base : lecture + écriture
      # Condition ABAC : Accès au conteneur 'department-finance' OU blobs taggés 'Department=Finance'
    }
    
    "SalesTeam" = {
      description = "Équipe Sales - Accès complet département Sales (ABAC: conteneur department-sales OU tag Department=Sales)"
      role        = "Contributor"         # Rôle de base : lecture + écriture
      # Condition ABAC : Accès au conteneur 'department-sales' OU blobs taggés 'Department=Sales'
    }
    
    "ProjectAlpha" = {
      description = "Membres projet Alpha - Accès ressources projet (ABAC: conteneur project-alpha OU tag Project=Alpha)"
      role        = "Contributor"         # Rôle de base : lecture + écriture
      # Condition ABAC : Accès au conteneur 'project-alpha' OU blobs taggés 'Project=Alpha'
    }
    
    "Contractors" = {
      description = "Contractuels externes - Accès limité et temporaire (ABAC: tag ExternalAccess=Allowed + restrictions horaires)"
      role        = "Reader"              # Rôle de base : lecture seule
      # Condition ABAC : Accès uniquement aux blobs taggés 'ExternalAccess=Allowed' OU conteneur 'temporary-uploads'
    }
    
    # ========== GROUPES SANS CONDITIONS ABAC ==========
    # Ces groupes ont un accès basé uniquement sur leur rôle RBAC
    # Pas de restrictions granulaires supplémentaires
    
    "SecurityOfficers" = {
      description = "Officiers de sécurité - Accès complet SANS restriction (pas de condition ABAC)"
      role        = "Owner"               # Rôle maximum : contrôle total + gestion des ACL
      # Pas de condition ABAC : Accès complet à toutes les ressources pour gestion sécurité
    }
    
    "Auditors" = {
      description = "Auditeurs - Accès lecture complète pour conformité (pas de condition ABAC)"
      role        = "Reader"              # Lecture seule sur toutes les ressources
      # Pas de condition ABAC : Accès lecture complet pour audit et conformité
    }
    
    "ITTeam" = {
      description = "Équipe IT - Accès complet pour gestion technique (pas de condition ABAC)"
      role        = "Contributor"         # Lecture + écriture pour gestion technique
      # Pas de condition ABAC : Accès complet pour maintenance et support
    }
    
    "HRTeam" = {
      description = "Équipe RH - Accès complet département Ressources Humaines"
      role        = "Contributor"         # Lecture + écriture sur conteneur department-hr
      # Pas de condition ABAC : Accès complet au domaine RH
    }
    
    "ProjectBeta" = {
      description = "Membres projet Beta - Accès ressources projet Beta"
      role        = "Contributor"         # Lecture + écriture sur conteneur project-beta
      # Pas de condition ABAC : Accès complet au projet Beta
    }
    
    "ProjectGamma" = {
      description = "Membres projet Gamma - Accès ressources projet Gamma"
      role        = "Contributor"         # Lecture + écriture sur conteneur project-gamma
      # Pas de condition ABAC : Accès complet au projet Gamma
    }
    
    "DataScientists" = {
      description = "Data Scientists - Accès lecture données pour analyse et ML"
      role        = "Reader"              # Lecture seule pour analyse de données
      # Pas de condition ABAC : Accès lecture sur toutes les données pour analyse
    }
  }
}