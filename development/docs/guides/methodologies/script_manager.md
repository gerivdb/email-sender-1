# Guide du Gestionnaire de Scripts

## Introduction

Le gestionnaire de scripts est un composant essentiel du système qui gère l'organisation, l'exécution et la maintenance des scripts PowerShell. Ce document détaille son fonctionnement, ses paramètres, et fournit des exemples d'utilisation pour vous aider à l'utiliser efficacement.

## Objectif

L'objectif principal du gestionnaire de scripts est de fournir une interface unifiée pour gérer tous les scripts du projet. Il permet notamment de :

- Organiser les scripts selon une structure cohérente
- Exécuter des scripts avec les paramètres appropriés
- Maintenir un inventaire des scripts disponibles
- Assurer la qualité et la conformité des scripts

## Architecture

### Structure des répertoires

Le gestionnaire de scripts est organisé selon la structure de répertoires suivante :

```
development/managers/script-manager/
├── scripts/
│   ├── script-manager.ps1           # Script principal
│   ├── install-script-manager.ps1   # Script d'installation
│   └── ...                          # Autres scripts
├── modules/
│   └── ...                          # Modules PowerShell
├── tests/
│   ├── Test-ScriptManager.ps1       # Tests unitaires
│   └── ...                          # Autres tests
└── config/
    └── ...                          # Fichiers de configuration locaux
```

### Fichiers de configuration

Les fichiers de configuration du gestionnaire sont stockés dans :

```
projet/config/managers/script-manager/
└── script-manager.config.json       # Configuration principale
```

## Prérequis

Avant d'utiliser le gestionnaire de scripts, assurez-vous que :

1. PowerShell 5.1 ou supérieur est installé sur votre système
2. Le gestionnaire intégré est installé
3. Les droits d'accès appropriés sont configurés

## Installation

### Installation automatique

Pour installer le gestionnaire de scripts, utilisez le script d'installation :

```powershell
.\development\managers\script-manager\scripts\install-script-manager.ps1
```

### Installation manuelle

Si vous préférez une installation manuelle, suivez ces étapes :

1. Copiez les fichiers du gestionnaire dans le répertoire approprié
2. Créez le fichier de configuration dans le répertoire approprié
3. Vérifiez que le gestionnaire fonctionne correctement

## Configuration

### Fichier de configuration principal

Le fichier de configuration principal du gestionnaire est situé à :

```
projet/config/managers/script-manager/script-manager.config.json
```

Voici un exemple de configuration :

```json
{
  "Enabled": true,
  "LogLevel": "Info",
  "ScriptPaths": {
    "Maintenance": "development/scripts/maintenance",
    "Reporting": "development/scripts/reporting",
    "Utilities": "development/scripts/utils",
    "RoadmapParser": "development/scripts/roadmap-parser"
  },
  "DefaultScriptPath": "development/scripts",
  "ScriptExtensions": [".ps1", ".psm1"],
  "TemplateDirectory": "development/templates/scripts",
  "HygenIntegration": {
    "Enabled": true,
    "TemplatesPath": "development/_templates"
  }
}
```

### Options de configuration

| Option | Type | Description | Valeur par défaut |
|--------|------|-------------|-------------------|
| Enabled | boolean | Active ou désactive le gestionnaire | true |
| LogLevel | string | Niveau de journalisation (Debug, Info, Warning, Error) | "Info" |
| ScriptPaths | object | Chemins vers les différentes catégories de scripts | {} |
| DefaultScriptPath | string | Chemin par défaut pour les scripts | "development/scripts" |
| ScriptExtensions | array | Extensions de fichiers considérées comme des scripts | [".ps1", ".psm1"] |
| TemplateDirectory | string | Répertoire contenant les modèles de scripts | "development/templates/scripts" |
| HygenIntegration | object | Configuration de l'intégration avec Hygen | {} |

## Utilisation

### Commandes principales

Le gestionnaire de scripts expose les commandes suivantes :

#### Commande 1 : RunScript

```powershell
.\development\managers\script-manager\scripts\script-manager.ps1 -Command RunScript -ScriptPath "development/scripts/maintenance/find-managers.ps1"
```

**Description :** Exécute un script spécifique

**Paramètres :**
- `-ScriptPath` : Chemin vers le script à exécuter
- `-ScriptParameters` : Paramètres à passer au script (optionnel)

**Exemple :**
```powershell
.\development\managers\script-manager\scripts\script-manager.ps1 -Command RunScript -ScriptPath "development/scripts/maintenance/find-managers.ps1" -ScriptParameters @{ProjectRoot="D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"}
```

#### Commande 2 : OrganizeScripts

```powershell
.\development\managers\script-manager\scripts\script-manager.ps1 -Command OrganizeScripts
```

**Description :** Organise les scripts selon la structure définie

**Paramètres :**
- `-Force` : Force la réorganisation même si des scripts sont déjà organisés (optionnel)

**Exemple :**
```powershell
.\development\managers\script-manager\scripts\script-manager.ps1 -Command OrganizeScripts -Force
```

### Exemples d'utilisation

#### Exemple 1 : Exécution d'un script de maintenance

```powershell
# Exécuter un script de maintenance
.\development\managers\script-manager\scripts\script-manager.ps1 -Command RunScript -ScriptPath "development/scripts/maintenance/find-managers.ps1"
```

#### Exemple 2 : Création d'un nouveau script à partir d'un modèle

```powershell
# Créer un nouveau script à partir d'un modèle
.\development\managers\script-manager\scripts\script-manager.ps1 -Command CreateScript -TemplateName "maintenance" -ScriptName "cleanup-logs" -OutputPath "development/scripts/maintenance"
```

## Intégration avec d'autres gestionnaires

Le gestionnaire de scripts s'intègre avec les autres gestionnaires du système :

### Intégration avec le gestionnaire intégré

```powershell
# Utiliser le gestionnaire de scripts via le gestionnaire intégré
.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Manager ScriptManager -Command RunScript -ScriptPath "development/scripts/maintenance/find-managers.ps1"
```

### Intégration avec le gestionnaire de modes

```powershell
# Utiliser le gestionnaire de scripts avec le gestionnaire de modes
.\development\managers\mode-manager\scripts\mode-manager.ps1 -Mode DEV-R -UseManager ScriptManager -Command RunScript -ScriptPath "development/scripts/maintenance/find-managers.ps1"
```

## Dépannage

### Problèmes courants et solutions

#### Problème 1 : Script non trouvé

**Symptômes :**
- Message d'erreur indiquant que le script n'existe pas
- La commande échoue avec une erreur de chemin

**Causes possibles :**
- Le chemin vers le script est incorrect
- Le script n'existe pas

**Solutions :**
1. Vérifiez que le chemin vers le script est correct
2. Assurez-vous que le script existe
3. Utilisez la commande ListScripts pour voir les scripts disponibles

#### Problème 2 : Erreurs lors de l'exécution d'un script

**Symptômes :**
- Le script échoue avec des erreurs
- Le script ne produit pas les résultats attendus

**Causes possibles :**
- Paramètres incorrects passés au script
- Erreurs dans le script
- Dépendances manquantes

**Solutions :**
1. Vérifiez que les paramètres passés au script sont corrects
2. Consultez les journaux pour plus d'informations
3. Assurez-vous que toutes les dépendances sont installées

### Journalisation

Le gestionnaire de scripts génère des journaux dans le répertoire suivant :

```
logs/script-manager/
```

Les niveaux de journalisation peuvent être configurés dans le fichier de configuration principal.

## Tests

### Exécution des tests

Pour exécuter les tests du gestionnaire de scripts, utilisez la commande suivante :

```powershell
.\development\managers\script-manager\tests\Test-ScriptManager.ps1
```

### Types de tests disponibles

- **Tests unitaires :** Testent les fonctions individuelles du gestionnaire
- **Tests d'intégration :** Testent l'intégration avec d'autres composants
- **Tests de performance :** Évaluent les performances du gestionnaire

## Bonnes pratiques

### Recommandations d'utilisation

1. Utilisez le gestionnaire de scripts pour exécuter tous les scripts du projet
2. Organisez vos scripts selon la structure définie
3. Utilisez les modèles pour créer de nouveaux scripts

### Sécurité

1. N'exécutez pas les scripts avec des privilèges administrateur sauf si nécessaire
2. Vérifiez les scripts avant de les exécuter
3. Limitez l'accès aux scripts sensibles

## Références

- [Documentation du gestionnaire intégré](integrated_manager.md)
- [Documentation du gestionnaire de modes](mode_manager.md)
- [Guide des bonnes pratiques PowerShell](../best-practices/powershell_best_practices.md)

## Historique des versions

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-04-29 | Version initiale |
