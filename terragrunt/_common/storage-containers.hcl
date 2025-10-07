# ============================================================================
# CONFIGURATION COMMUNE: CONTENEURS BLOB STORAGE
# Définition centralisée des conteneurs pour tous les environnements
# ============================================================================

locals {
  # Conteneurs blob organisés par domaine métier et niveau de sécurité
  # Chaque conteneur correspond à une condition ABAC spécifique
  blob_containers = {
    "public-documents"   = "Documents publics - accès lecture pour tous (condition ABAC PublicUsers)"
    "department-finance" = "Département Finance uniquement (condition ABAC FinanceTeam)"
    "department-sales"   = "Département Sales uniquement (condition ABAC SalesTeam)"
    "department-it"      = "Département IT - gestion technique (accès complet sans ABAC)"
    "department-hr"      = "Département Ressources Humaines (accès complet HRTeam)"
    "project-alpha"      = "Projet Alpha (condition ABAC ProjectAlpha avec tags)"
    "project-beta"       = "Projet Beta (accès équipe projet uniquement)"
    "project-gamma"      = "Projet Gamma (accès équipe projet uniquement)"
    "confidential"       = "Documents confidentiels - haute sécurité (exclus des Executives)"
    "temporary-uploads"  = "Zone temporaire - nettoyage automatique 7 jours"
    "archives"           = "Archives - lifecycle policy vers stockage froid"
  }
}