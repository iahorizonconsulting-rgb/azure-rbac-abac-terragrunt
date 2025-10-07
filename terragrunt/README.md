# 🚀 Guide Terragrunt - Parce que Terraform tout seul, c'est l'enfer

Alors, vous avez vu le README principal et vous vous dites "OK, ça a l'air cool, mais comment ça marche concrètement ?" Vous êtes au bon endroit !

## Pourquoi Terragrunt ? (La vraie question)

Laissez-moi vous raconter une histoire. Au début, j'utilisais Terraform vanilla. Ça marchait bien... jusqu'au jour où j'ai eu besoin de gérer 3 environnements (dev, staging, prod). 

Résultat : 
- Du code dupliqué partout
- Des variables à maintenir dans 15 fichiers différents
- Des erreurs de copier-coller qui m'ont fait perdre des nuits
- L'envie de tout jeter par la fenêtre

Terragrunt, c'est la solution à ce cauchemar. Une seule configuration, plusieurs environnements. Magique.

## Comment c'est organisé (sans se perdre)

```
terragrunt/
├── terragrunt.hcl                    # Le "chef d'orchestre"
├── environments/                     # Vos environnements
│   ├── dev/                         # Pour casser des trucs en toute sécurité
│   ├── staging/                     # Pour faire semblant que ça marche
│   └── prod/                        # Pour stresser
├── _common/                         # Ce qui ne change jamais
│   ├── entra-groups.hcl            # Vos groupes d'utilisateurs
│   └── storage-containers.hcl       # Vos conteneurs de stockage
├── modules/                         # Les "briques" Terraform
└── scripts/                         # Petits outils pratiques
```

**La logique** : On écrit le code une fois dans `modules/`, on configure les différences dans `environments/`, et Terragrunt fait le reste.

## Démarrer sans se planter

### Ce qu'il vous faut (vraiment)

```bash
# Installer Terragrunt (sur Mac)
brew install terragrunt

# Ou sur Linux/Windows, suivez le guide officiel
# https://terragrunt.gruntwork.io/docs/getting-started/install/

# Vérifier que tout est OK
terragrunt --version
terraform --version
az --version
```

### Le déploiement "je croise les doigts"

```bash
# 1. Aller dans le bon dossier
cd terragrunt

# 2. Configurer vos variables (IMPORTANT !)
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
# Éditez ce fichier avec vos vraies valeurs Azure

# 3. La commande magique
terragrunt run-all apply --terragrunt-working-dir environments/dev
```

**Ce qui va se passer** : Terragrunt va déployer tous les modules dans le bon ordre. Resource Group d'abord, puis Storage, puis RBAC, etc. Pas besoin de réfléchir à l'ordre, il gère ça tout seul.

**Temps d'attente** : 10-15 minutes la première fois. Parfait pour aller se faire un café.

## Les environnements expliqués (enfin !)

### Dev - "L'environnement où on peut tout casser"
```hcl
# Dans environments/dev/env.hcl
locals {
  environment = "dev"
  
  # Pas cher, pas sécurisé, mais pratique
  storage_replication = "LRS"          # Local seulement
  network_access = "Allow"             # Ouvert à tous
  key_vault_sku = "standard"           # Pas de HSM
  log_retention_days = 30              # On garde pas longtemps
  
  # ABAC permissif pour les tests
  abac_time_restriction = false        # Accès 24h/24
  abac_ip_restriction = false          # Depuis n'importe où
}
```

### Staging - "L'environnement où on fait semblant"
```hcl
# Dans environments/staging/env.hcl
locals {
  environment = "staging"
  
  # Un peu plus sérieux
  storage_replication = "GRS"          # Geo-réplication
  network_access = "Deny"              # Accès restreint
  key_vault_sku = "standard"           # Toujours pas de HSM
  log_retention_days = 90              # On garde plus longtemps
  
  # ABAC plus strict
  abac_time_restriction = true         # Heures bureau seulement
  abac_ip_restriction = true           # IP autorisées seulement
}
```

### Prod - "L'environnement où on stresse"
```hcl
# Dans environments/prod/env.hcl
locals {
  environment = "prod"
  
  # Configuration blindée
  storage_replication = "GZRS"         # Geo-zone redundancy
  network_access = "Deny"              # Très restreint
  key_vault_sku = "premium"            # HSM activé
  log_retention_days = 365             # On garde tout
  
  # ABAC strict
  abac_time_restriction = true         # Heures bureau
  abac_ip_restriction = true           # IP très restreintes
  abac_device_compliance = true        # Appareils conformes seulement
}
```

## Les groupes et permissions (le cœur du système)

Voici qui peut faire quoi (et surtout, qui ne peut PAS faire quoi) :

### **PublicUsers** - "Les visiteurs"
- **Ce qu'ils peuvent faire** : Lire les documents publics
- **Où** : Conteneur `public-documents` seulement
- **Quand** : Toujours (pas de restriction ABAC)
- **Exemple concret** : Télécharger le catalogue produits

### **FinanceTeam** - "Les comptables"
- **Ce qu'ils peuvent faire** : Lire/écrire dans les données finance
- **Où** : Conteneur `department-finance` + fichiers taggés "Finance"
- **Quand** : Heures bureau seulement (8h-18h)
- **Exemple concret** : Uploader le budget mensuel

### **SalesTeam** - "Les commerciaux"
- **Ce qu'ils peuvent faire** : Gérer les données ventes
- **Où** : Conteneur `department-sales` + fichiers taggés "Sales"
- **Quand** : Depuis le bureau ou VPN seulement
- **Exemple concret** : Mettre à jour les prospects

### **Executives** - "Les chefs"
- **Ce qu'ils peuvent faire** : Lire (presque) tout
- **Où** : Tous les conteneurs SAUF `confidential`
- **Quand** : Appareils conformes seulement
- **Exemple concret** : Consulter les rapports de vente

### **SecurityOfficers** - "Les gardiens"
- **Ce qu'ils peuvent faire** : TOUT
- **Où** : Partout
- **Quand** : Toujours
- **Exemple concret** : Auditer les accès, gérer les incidents

## Tester que ça marche (sans tout casser)

### Test rapide avec Azure CLI

```bash
# Test 1 : Accès autorisé (PublicUsers -> public-documents)
az storage blob upload \
  --account-name votre-storage-account \
  --container-name public-documents \
  --name test.txt \
  --file test.txt \
  --auth-mode login

# Résultat attendu : ✅ Ça marche

# Test 2 : Accès refusé (PublicUsers -> confidential)
az storage blob upload \
  --account-name votre-storage-account \
  --container-name confidential \
  --name secret.txt \
  --file secret.txt \
  --auth-mode login

# Résultat attendu : ❌ Erreur 403 Forbidden
```

### Script automatique (plus pratique)

```bash
# Lancer tous les tests d'un coup
./scripts/test-rbac-permissions.sh dev

# Ça va tester tous les groupes, tous les conteneurs
# Et vous dire ce qui marche et ce qui ne marche pas
```

## Modifier la configuration (sans tout péter)

### Ajouter un nouveau groupe d'utilisateurs

1. **Éditer** `_common/entra-groups.hcl` :
```hcl
# Ajouter votre nouveau groupe
marketing_team = {
  display_name = "MarketingTeam"
  description  = "Équipe marketing - accès aux campagnes"
  members      = ["user1@domain.com", "user2@domain.com"]
}
```

2. **Ajouter les permissions** dans `modules/rbac/main.tf`

3. **Déployer** :
```bash
terragrunt apply --terragrunt-working-dir environments/dev/entra
terragrunt apply --terragrunt-working-dir environments/dev/rbac
```

### Changer les conditions ABAC

Exemple : autoriser l'accès 24h/24 pour les développeurs

```hcl
# Dans modules/rbac/main.tf, modifier la condition
condition = <<-EOT
  (
    @Subject[Microsoft.Graph.Group.DisplayName] == 'DeveloperTeam' ||
    (
      @Request[Microsoft.DateTime] >= '08:00' &&
      @Request[Microsoft.DateTime] <= '18:00'
    )
  )
EOT
```

## Dépannage (quand ça merde)

### "Terragrunt dit que le state est locké"
```bash
# Identifier le lock
terragrunt plan --terragrunt-working-dir environments/dev/storage

# Forcer le déverrouillage (ATTENTION : dangereux si quelqu'un d'autre travaille)
terragrunt force-unlock LOCK-ID --terragrunt-working-dir environments/dev/storage
```

### "Les permissions ABAC ne marchent pas"
1. **Vérifier les logs** dans Azure Portal > Storage Account > Monitoring > Logs
2. **Chercher les erreurs 403** avec cette requête KQL :
```kql
StorageBlobLogs
| where StatusCode == 403
| project TimeGenerated, CallerIpAddress, OperationName, Uri
```

### "Terragrunt ne trouve pas mes modules"
```bash
# Vérifier la structure
terragrunt graph-dependencies --terragrunt-working-dir environments/dev

# Nettoyer le cache
rm -rf .terragrunt-cache/
```

## Ajouter un nouvel environnement (preprod, par exemple)

```bash
# 1. Copier la config staging
cp -r environments/staging environments/preprod

# 2. Modifier les valeurs dans preprod/env.hcl
# (changer les noms, les configs, etc.)

# 3. Déployer
terragrunt run-all apply --terragrunt-working-dir environments/preprod
```

## Monitoring (pour dormir tranquille)

### Requêtes KQL utiles

```kql
// Qui accède à quoi ?
StorageBlobLogs
| where TimeGenerated > ago(24h)
| summarize count() by CallerIpAddress, OperationName
| order by count_ desc

// Violations ABAC
StorageBlobLogs
| where StatusCode == 403
| project TimeGenerated, CallerIpAddress, Uri, StatusText

// Accès aux données sensibles
StorageBlobLogs
| where Uri contains "confidential" or Uri contains "finance"
| project TimeGenerated, CallerIpAddress, OperationName, StatusCode
```

## Conseils de survie

### **DO** (à faire)
- ✅ Toujours tester en dev d'abord
- ✅ Faire des `plan` avant les `apply`
- ✅ Monitorer les logs après déploiement
- ✅ Documenter vos changements
- ✅ Faire des backups des states Terraform

### **DON'T** (à éviter)
- ❌ Modifier directement en prod
- ❌ Ignorer les erreurs de `plan`
- ❌ Oublier de tester les permissions
- ❌ Hardcoder des secrets dans le code
- ❌ Supprimer des ressources sans backup

## Questions que vous allez vous poser

**Q: Pourquoi mes changements ne s'appliquent pas ?**
R: Vérifiez que vous êtes dans le bon environnement et que vous avez fait `terragrunt apply` dans le bon module.

**Q: Comment je rollback si j'ai merdé ?**
R: `git revert` votre commit, puis `terragrunt apply` pour revenir à l'état précédent.

**Q: Ça coûte combien de faire tourner ça ?**
R: Dev : ~15€/mois, Staging : ~30€/mois, Prod : ~50€/mois (selon l'usage).

**Q: Je peux utiliser ça avec d'autres clouds ?**
R: Oui, mais il faudra adapter les modules. Le principe Terragrunt reste le même.

---

**Voilà !** Avec ça, vous devriez pouvoir vous en sortir. Et si vous êtes perdus, n'hésitez pas à ouvrir une issue sur GitHub, je réponds assez vite.

Bon courage ! 💪