# 🔐 Azure RBAC + ABAC Infrastructure with Terragrunt

Salut ! 👋 Bienvenue dans ce projet qui m'a pris pas mal de temps à peaufiner. Si vous cherchez à comprendre comment implémenter du contrôle d'accès sophistiqué sur Azure, vous êtes au bon endroit.

## Pourquoi ce projet existe ?

Franchement, quand j'ai commencé à bosser avec Azure, j'étais un peu perdu avec toutes les options de sécurité. RBAC par ci, ABAC par là... Et puis j'ai réalisé qu'il n'y avait pas vraiment d'exemple concret qui montrait comment tout ça s'articule dans la vraie vie.

Ce repository, c'est ma façon de partager ce que j'ai appris. C'est du **vrai code** que vous pouvez déployer, pas juste de la théorie. J'ai essayé de couvrir les cas d'usage les plus courants qu'on rencontre en entreprise.

## Ce que vous allez trouver ici

### � **L'hidée principale**
On va créer une infrastructure Azure où les utilisateurs n'ont pas tous les mêmes droits. Ça peut paraître évident, mais c'est fou le nombre de boîtes où tout le monde a accès à tout "parce que c'est plus simple".

Ici, on va faire les choses bien :
- **RBAC** pour les rôles de base (qui peut faire quoi)
- **ABAC** pour les conditions fines (quand, où, comment)

### 🏗️ **Ce qu'on va construire ensemble**

Imaginez une entreprise avec :
- Des **développeurs** qui bossent en journée depuis le bureau
- Des **admins** qui peuvent intervenir 24/7 mais seulement depuis certains pays
- Des **auditeurs** qui ont accès en lecture seule aux logs
- Des **contractors** qui n'ont accès qu'à certains types de fichiers

Notre infrastructure va gérer tout ça automatiquement. Pas de "ah merde, j'ai oublié de retirer les droits à machin qui a quitté la boîte il y a 3 mois".

### 🔒 **Les 7 conditions ABAC qu'on implémente**

J'ai choisi ces conditions parce que ce sont celles que j'ai le plus souvent vues en entreprise :

1. **"Pas d'accès à 3h du mat"** - Restriction par heure (sauf pour les admins, évidemment)
2. **"Pas depuis la Corée du Nord"** - Restriction géographique (vous voyez l'idée)
3. **"Seulement depuis le bureau"** - Restriction par IP (télétravail autorisé avec VPN)
4. **"Ton laptop doit être à jour"** - Restriction par conformité d'appareil
5. **"Pas si tu as l'air louche"** - Restriction par niveau de risque (merci Azure AD Identity Protection)
6. **"Pas les .exe dans le dossier docs"** - Restriction par type de contenu
7. **"Pas de fichiers de 10GB"** - Restriction par taille (pour éviter les abus)

## 🚀 **Comment démarrer (sans se prendre la tête)**

### **Ce dont vous avez besoin**
- Un compte Azure (même un trial ça marche)
- Azure CLI installé et connecté (`az login`)
- Terraform (version récente, genre 1.5+)
- Terragrunt (pareil, version récente)
- Un peu de patience pour la première fois 😅

### **La méthode "ça marche du premier coup"**

```bash
# 1. Récupérer le code
git clone https://github.com/votre-username/azure-rbac-abac-terragrunt.git
cd azure-rbac-abac-terragrunt

# 2. Aller dans le bon dossier
cd terragrunt

# 3. Configurer vos infos (c'est important !)
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars

# 4. Éditer le fichier avec vos vraies valeurs
# (subscription_id, tenant_id, etc. - je détaille plus bas)
nano environments/dev/terraform.tfvars

# 5. Déployer (et croiser les doigts)
terragrunt run-all apply --terragrunt-working-dir environments/dev
```

**Pro tip** : La première fois, ça va prendre 10-15 minutes. C'est normal, Azure doit créer plein de trucs.

## 📁 **Comment c'est organisé (et pourquoi)**

J'ai essayé de faire quelque chose de logique :

```
├── modules/                    # Les "briques" Terraform
│   ├── rbac/                  # Le cœur du système (rôles + conditions)
│   ├── storage/               # Storage Account avec toutes les protections
│   ├── keyvault/              # Pour les secrets (mots de passe, clés, etc.)
│   ├── entra/                 # Groupes d'utilisateurs dans Azure AD
│   └── monitoring/            # Pour savoir ce qui se passe
├── terragrunt/                # La "recette" pour tout assembler
│   ├── environments/          # dev, staging, prod (chacun sa config)
│   ├── modules/               # Adaptateurs Terragrunt
│   └── _common/               # Ce qui est partagé entre environnements
└── scripts/                   # Petits outils pratiques
```

**Pourquoi Terragrunt ?** Parce que gérer plusieurs environnements avec Terraform vanilla, c'est l'enfer. Terragrunt nous évite de copier-coller du code partout.

## 🔧 **Configuration (la partie chiante mais importante)**

### **Les variables à remplir absolument**

Dans votre fichier `terraform.tfvars`, vous devez mettre :

```hcl
# Vos infos Azure (trouvables avec 'az account show')
subscription_id = "12345678-1234-1234-1234-123456789012"
tenant_id      = "87654321-4321-4321-4321-210987654321"

# Où déployer (choisissez proche de chez vous)
location = "West Europe"  # ou "East US", "Southeast Asia", etc.

# Comment nommer vos ressources
environment  = "dev"           # ou "staging", "prod"
project_name = "MonSuperProjet" # évitez les espaces et caractères bizarres

# Optionnel : vos plages IP autorisées
allowed_ip_ranges = ["203.0.113.0/24", "198.51.100.0/24"]
```

### **Personnaliser les conditions ABAC**

Si vous voulez changer les règles (par exemple, autoriser l'accès 24/7 ou depuis d'autres pays), regardez dans `modules/rbac/main.tf`. J'ai essayé de commenter au maximum.

Exemple pour changer les heures autorisées :
```hcl
# Dans modules/rbac/main.tf, cherchez cette section :
condition = <<-EOT
  (
    @Request[Microsoft.DateTime] >= '08:00' &&
    @Request[Microsoft.DateTime] <= '18:00'
  )
EOT
```

## 🧪 **Vérifier que ça marche**

J'ai inclus quelques scripts pour vous rassurer :

```bash
# Vérifier que la structure est cohérente
./scripts/validate-structure.sh

# Tester les permissions (après déploiement)
cd terragrunt
./scripts/test-rbac-permissions.sh
```

## 🤔 **Questions fréquentes (que je me pose moi-même)**

**Q: Ça coûte combien ?**
R: Avec les ressources de base, comptez 10-20€/mois pour un environnement de dev. La plupart du coût vient du Storage Account et du Key Vault.

**Q: Je peux utiliser ça en prod ?**
R: Oui, mais adaptez les conditions à vos besoins. Et testez d'abord en dev, évidemment.

**Q: Pourquoi pas du ARM ou Bicep ?**
R: Parce que Terraform, c'est plus portable. Et puis j'aime bien la syntaxe HCL.

**Q: Et si je veux ajouter d'autres services Azure ?**
R: Créez un nouveau module dans `modules/` et ajoutez-le dans la config Terragrunt. J'ai essayé de faire quelque chose d'extensible.

## 🔍 **Ce qui se passe concrètement**

Une fois déployé, voici ce que vous aurez :

### **13 groupes d'utilisateurs** dans Azure AD
- `PublicUsers` : Accès aux docs publiques seulement
- `FinanceTeam` : Accès aux données finance + conditions horaires
- `SalesTeam` : Accès aux données ventes + restrictions IP
- `ProjectAlpha` : Accès projet spécifique + conformité appareil
- etc.

### **11 conteneurs** dans le Storage Account
- `public-documents` : Accessible à tous
- `department-finance` : Finance seulement
- `confidential` : Executives et admins seulement
- etc.

### **7 conditions ABAC** qui s'appliquent automatiquement
Pas besoin de gérer ça manuellement, tout est dans le code.

## 🚨 **Les pièges à éviter (j'ai testé pour vous)**

1. **Ne pas oublier les permissions sur le Resource Group** - Sinon personne ne peut rien faire
2. **Tester avec de vrais utilisateurs** - Les conditions ABAC peuvent être sournoises
3. **Vérifier les fuseaux horaires** - Les conditions d'heure sont en UTC
4. **Attention aux IP publiques** - Elles changent plus souvent qu'on ne le croit
5. **Monitorer les logs** - Pour voir qui essaie d'accéder à quoi

## 🤝 **Contribuer (si ça vous dit)**

Si vous trouvez des bugs, des améliorations possibles, ou si vous voulez ajouter des fonctionnalités, n'hésitez pas ! 

Le process classique :
1. Fork le projet
2. Créez votre branche (`git checkout -b ma-super-feature`)
3. Commitez vos changements (`git commit -am 'Ajout de ma super feature'`)
4. Pushez (`git push origin ma-super-feature`)
5. Ouvrez une Pull Request

Je regarde régulièrement et je réponds assez vite.

## 📄 **Licence et tout le tralala**

C'est du MIT, donc faites-en ce que vous voulez. Utilisez-le, modifiez-le, vendez-le (bon courage), je m'en fiche. Juste, si ça vous aide, un petit ⭐ sur GitHub me ferait plaisir.

## 🆘 **Besoin d'aide ?**

Si vous êtes bloqués :
1. Regardez d'abord les [issues existantes](https://github.com/votre-username/azure-rbac-abac-terragrunt/issues)
2. Si vous ne trouvez pas, créez une nouvelle issue avec un maximum de détails
3. En dernier recours, la [doc Microsoft](https://docs.microsoft.com/azure/) est plutôt bien faite

---

**Voilà !** J'espère que ce projet vous sera utile. N'hésitez pas à me faire des retours, ça m'aide à améliorer les choses.

Bon déploiement ! 🚀