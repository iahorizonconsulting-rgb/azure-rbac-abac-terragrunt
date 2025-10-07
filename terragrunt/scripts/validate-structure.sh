#!/bin/bash
# ============================================================================
# SCRIPT: VALIDATION DE LA STRUCTURE TERRAGRUNT
# Vérifie que tous les fichiers nécessaires sont présents
# ============================================================================

set -e

echo "🔍 Validation de la structure Terragrunt..."

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Compteurs
TOTAL_CHECKS=0
PASSED_CHECKS=0

check_file() {
    local file=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $description: $file"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌${NC} $description: $file (MANQUANT)"
    fi
}

check_dir() {
    local dir=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅${NC} $description: $dir"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌${NC} $description: $dir (MANQUANT)"
    fi
}

echo ""
echo "📁 Vérification de la structure des dossiers..."

# Structure principale
check_dir "environments" "Dossier environnements"
check_dir "modules" "Dossier modules"
check_dir "_common" "Dossier configurations communes"
check_dir "scripts" "Dossier scripts"

# Environnements
for env in dev staging prod; do
    check_dir "environments/$env" "Environnement $env"
    for module in resource-group entra storage keyvault monitoring rbac; do
        check_dir "environments/$env/$module" "Module $module ($env)"
    done
done

echo ""
echo "📄 Vérification des fichiers de configuration..."

# Fichiers racine
check_file "terragrunt.hcl" "Configuration racine Terragrunt"
check_file "README.md" "Documentation"

# Configurations communes
check_file "_common/entra-groups.hcl" "Configuration groupes Entra ID"
check_file "_common/storage-containers.hcl" "Configuration conteneurs Storage"

# Configurations d'environnement
for env in dev staging prod; do
    check_file "environments/$env/env.hcl" "Configuration environnement $env"
    
    for module in resource-group entra storage keyvault monitoring rbac; do
        check_file "environments/$env/$module/terragrunt.hcl" "Configuration $module ($env)"
    done
done

echo ""
echo "🔧 Vérification des modules Terraform..."

# Modules
for module in resource-group entra storage keyvault monitoring rbac; do
    check_dir "modules/$module" "Module $module"
    check_file "modules/$module/main.tf" "Main.tf du module $module"
    check_file "modules/$module/variables.tf" "Variables.tf du module $module"
    check_file "modules/$module/outputs.tf" "Outputs.tf du module $module"
done

echo ""
echo "📜 Vérification des scripts..."

check_file "scripts/test-rbac-permissions.sh" "Script de test RBAC"
check_file "scripts/validate-structure.sh" "Script de validation (ce script)"

echo ""
echo "📊 Résumé de la validation"
echo "=========================="

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}🎉 Tous les tests sont passés !${NC}"
    echo -e "${GREEN}✅ $PASSED_CHECKS/$TOTAL_CHECKS vérifications réussies${NC}"
    echo ""
    echo "🚀 La structure Terragrunt est prête pour le déploiement !"
    echo ""
    echo "Prochaines étapes :"
    echo "1. cd terragrunt"
    echo "2. terragrunt run-all plan --terragrunt-working-dir environments/dev"
    echo "3. terragrunt run-all apply --terragrunt-working-dir environments/dev"
    exit 0
else
    echo -e "${RED}❌ Certains fichiers sont manquants${NC}"
    echo -e "${RED}✅ $PASSED_CHECKS/$TOTAL_CHECKS vérifications réussies${NC}"
    echo ""
    echo "🔧 Veuillez créer les fichiers manquants avant de continuer."
    exit 1
fi