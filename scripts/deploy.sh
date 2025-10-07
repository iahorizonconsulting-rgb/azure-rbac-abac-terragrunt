#!/bin/bash

# ============================================================================
# SCRIPT DE DÉPLOIEMENT TERRAFORM
# Implémente les bonnes pratiques Azure Terraform
# ============================================================================

set -e

# Couleurs pour output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction pour vérifier l'installation de Terraform
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform n'est pas installé"
        log_info "Installation recommandée (macOS): brew install terraform"
        log_info "Installation Windows: winget install Hashicorp.Terraform"
        exit 1
    fi

    log_info "Terraform version: $(terraform version -json | jq -r '.terraform_version')"
}

# Fonction pour vérifier l'authentification Azure
check_azure_auth() {
    if ! az account show &> /dev/null; then
        log_error "Vous n'êtes pas connecté à Azure"
        log_info "Exécutez: az login"
        exit 1
    fi

    SUBSCRIPTION=$(az account show --query name -o tsv)
    log_info "Subscription Azure: $SUBSCRIPTION"
}

# Afficher le banner
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║          Déploiement Terraform - Azure RBAC + ABAC            ║
║                   Basé sur les meilleures pratiques           ║
╚═══════════════════════════════════════════════════════════════╝
EOF

echo ""

# Variables
ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="../"
ENV_DIR="../environments/${ENVIRONMENT}"

log_info "Environnement: $ENVIRONMENT"
log_info "Répertoire Terraform: $TERRAFORM_DIR"

# Vérifications préalables
log_info "Vérification des prérequis..."
check_terraform
check_azure_auth

# Naviguer vers le répertoire Terraform
cd "$TERRAFORM_DIR"

# ============================================================================
# ÉTAPE 1: TERRAFORM INIT
# ============================================================================

log_info "Étape 1/5: Terraform Init"
terraform init -upgrade

# ============================================================================
# ÉTAPE 2: TERRAFORM FORMAT
# ============================================================================

log_info "Étape 2/5: Terraform Format"
if ! terraform fmt -check -recursive; then
    log_warn "Fichiers non formatés détectés. Application du formatage..."
    terraform fmt -recursive
fi

# ============================================================================
# ÉTAPE 3: TERRAFORM VALIDATE
# ============================================================================

log_info "Étape 3/5: Terraform Validate (CRITIQUE - Bonne pratique Azure)"
if ! terraform validate; then
    log_error "La validation Terraform a échoué"
    exit 1
fi

log_info "✓ Validation réussie"

# ============================================================================
# ÉTAPE 4: TERRAFORM PLAN
# ============================================================================

log_info "Étape 4/5: Terraform Plan"
log_info "Génération du plan d'exécution..."

if [ -f "${ENV_DIR}/terraform.tfvars" ]; then
    terraform plan \
        -var-file="${ENV_DIR}/terraform.tfvars" \
        -out=tfplan
else
    log_warn "Fichier terraform.tfvars non trouvé pour ${ENVIRONMENT}"
    terraform plan -out=tfplan
fi

echo ""
log_warn "Veuillez vérifier le plan ci-dessus avant de continuer"
read -p "Voulez-vous appliquer ce plan? (oui/non): " CONFIRM

if [ "$CONFIRM" != "oui" ]; then
    log_info "Déploiement annulé"
    rm -f tfplan
    exit 0
fi

# ============================================================================
# ÉTAPE 5: TERRAFORM APPLY
# ============================================================================

log_info "Étape 5/5: Terraform Apply"
terraform apply tfplan

# Nettoyer le plan
rm -f tfplan

# ============================================================================
# AFFICHAGE DES OUTPUTS ET LIENS PORTAIL AZURE
# ============================================================================

echo ""
log_info "═══════════════════════════════════════════════════════════"
log_info "Déploiement terminé avec succès!"
log_info "═══════════════════════════════════════════════════════════"
echo ""

log_info "📋 OUTPUTS:"
terraform output

echo ""
log_info "🔗 LIENS PORTAIL AZURE:"

# Extraire et afficher les liens
if terraform output -json portal_links &> /dev/null; then
    PORTAL_LINKS=$(terraform output -json portal_links)

    echo "  Resource Group: $(echo $PORTAL_LINKS | jq -r '.resource_group')"
    echo "  Storage Account: $(echo $PORTAL_LINKS | jq -r '.storage')"
    echo "  Key Vault: $(echo $PORTAL_LINKS | jq -r '.key_vault')"
    echo "  Log Analytics: $(echo $PORTAL_LINKS | jq -r '.log_analytics')"
fi

echo ""
log_info "📝 PROCHAINES ÉTAPES:"
echo "  1. Vérifier les ressources dans le portail Azure"
echo "  2. Ajouter des utilisateurs aux groupes Entra ID"
echo "  3. Tester les accès avec différents utilisateurs"
echo "  4. Consulter les logs dans Log Analytics"

echo ""
log_info "✅ Script terminé"
