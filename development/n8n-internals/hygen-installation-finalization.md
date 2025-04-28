# Guide de finalisation de l'installation de Hygen

Ce guide explique comment finaliser l'installation de Hygen dans le projet n8n.

## Prérequis

- Node.js et npm installés
- Projet n8n initialisé
- Hygen installé en tant que dépendance de développement

## Étapes de finalisation

### 1. Vérification de l'installation

La première étape consiste à vérifier que Hygen est correctement installé et accessible.

```powershell
# Vérifier la version de Hygen
npx hygen --version

# Vérifier l'installation complète
.\n8n\scripts\setup\verify-hygen-installation.ps1
```

### 2. Validation de la structure de dossiers

La deuxième étape consiste à vérifier que la structure de dossiers nécessaire est en place.

```powershell
# Vérifier la structure de dossiers
.\n8n\scripts\setup\validate-hygen-structure.ps1

# Corriger la structure de dossiers si nécessaire
.\n8n\scripts\setup\validate-hygen-structure.ps1 -Fix
```

### 3. Test de l'installation dans un environnement propre

La troisième étape consiste à tester l'installation dans un environnement propre pour s'assurer que le script d'installation fonctionne correctement.

```powershell
# Tester l'installation dans un environnement propre
.\n8n\scripts\setup\test-hygen-clean-install.ps1

# Tester l'installation et conserver le dossier temporaire
.\n8n\scripts\setup\test-hygen-clean-install.ps1 -KeepTemp
```

### 4. Finalisation complète

La dernière étape consiste à exécuter le script de finalisation qui effectue toutes les vérifications et corrections nécessaires.

```powershell
# Vérifier uniquement
.\n8n\scripts\setup\finalize-hygen-installation.ps1

# Vérifier et corriger
.\n8n\scripts\setup\finalize-hygen-installation.ps1 -Fix

# Vérifier et corriger (sans test propre)
.\n8n\scripts\setup\finalize-hygen-installation.ps1 -Fix -SkipCleanTest
```

Vous pouvez également utiliser le script de commande pour faciliter l'exécution de la finalisation :

```batch
.\n8n\cmd\utils\finalize-hygen.cmd
```

## Structure des scripts

### Scripts de finalisation

| Script | Description |
|--------|-------------|
| `verify-hygen-installation.ps1` | Vérifie que Hygen est correctement installé et accessible |
| `validate-hygen-structure.ps1` | Vérifie que la structure de dossiers nécessaire est en place |
| `test-hygen-clean-install.ps1` | Teste l'installation dans un environnement propre |
| `finalize-hygen-installation.ps1` | Exécute toutes les vérifications et corrections nécessaires |
| `finalize-hygen.cmd` | Script de commande pour faciliter l'exécution de la finalisation |

### Structure de dossiers

La structure de dossiers suivante est nécessaire pour Hygen :

```
n8n/development/templates/
  n8n-script/
    new/
      hello.ejs.t
      prompt.js
  n8n-workflow/
    new/
      hello.ejs.t
      prompt.js
  n8n-doc/
    new/
      hello.ejs.t
      prompt.js
  n8n-integration/
    new/
      hello.ejs.t
      prompt.js
n8n/
  automation/
    deployment/
    monitoring/
    diagnostics/
    notification/
    maintenance/
    dashboard/
    development/testing/tests/
  core/
    workflows/
      local/
      ide/
      archive/
  integrations/
    mcp/
    ide/
    api/
    augment/
  projet/documentation/
    architecture/
    workflows/
    api/
    guides/
    installation/
  projet/config/
  data/
  development/scripts/
    setup/
    utils/
    sync/
  cmd/
    utils/
    start/
    stop/
  development/testing/tests/
    unit/
```

## Résolution des problèmes

### Hygen n'est pas installé

Si Hygen n'est pas installé, exécutez la commande suivante :

```powershell
npm install --save-dev hygen
```

### Structure de dossiers incomplète

Si la structure de dossiers est incomplète, exécutez la commande suivante :

```powershell
.\n8n\scripts\setup\validate-hygen-structure.ps1 -Fix
```

### Fichiers manquants

Si des fichiers sont manquants, exécutez la commande suivante :

```powershell
.\n8n\scripts\setup\install-hygen.ps1
```

### Erreurs lors de l'exécution des scripts

Si vous rencontrez des erreurs lors de l'exécution des scripts, vérifiez les points suivants :

- Assurez-vous que PowerShell est configuré pour exécuter des scripts
- Assurez-vous que Node.js et npm sont installés et accessibles
- Assurez-vous que vous êtes dans le répertoire racine du projet

## Prochaines étapes

Une fois l'installation finalisée, vous pouvez passer aux étapes suivantes :

1. Tester les templates Hygen
2. Valider les scripts d'utilitaires
3. Finaliser les tests et la documentation
4. Valider les bénéfices et l'utilité

Pour plus d'informations, consultez le guide d'utilisation de Hygen :

```powershell
.\n8n\projet/documentation\hygen-guide.md
```
