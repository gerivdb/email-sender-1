# Guide du Gestionnaire de Processus (Process Manager)

## Introduction

Le gestionnaire de processus (Process Manager) est un composant central qui coordonne et gère tous les gestionnaires et processus du système. Ce document détaille son fonctionnement, ses paramètres, et fournit des exemples d'utilisation pour vous aider à l'utiliser efficacement.

## Objectif

L'objectif principal du gestionnaire de processus est de fournir une interface unifiée pour gérer tous les gestionnaires du système. Il permet notamment de :

- Découvrir automatiquement les gestionnaires disponibles
- Enregistrer et configurer les gestionnaires
- Exécuter des commandes sur les gestionnaires
- Surveiller l'état des gestionnaires
- Centraliser la journalisation des opérations

## Architecture

### Structure des répertoires

Le gestionnaire de processus est organisé selon la structure de répertoires suivante :

```
development/managers/process-manager/
├── scripts/
│   ├── process-manager.ps1           # Script principal
│   ├── install-modules.ps1           # Script d'installation des modules
│   ├── integrate-modules.ps1         # Script d'intégration des modules
│   └── ...                           # Autres scripts
├── modules/
│   ├── ManagerRegistrationService/   # Service d'enregistrement des gestionnaires
│   ├── ManifestParser/               # Analyseur de manifestes
│   ├── ValidationService/            # Service de validation
│   ├── DependencyResolver/           # Résolveur de dépendances
│   └── ...                           # Autres modules PowerShell
├── tests/
│   ├── Test-ProcessManager.ps1       # Tests unitaires de base
│   ├── Test-ProcessManagerAll.ps1    # Tests complets
│   ├── Test-ManifestParser.ps1       # Tests du module ManifestParser
│   ├── Test-ValidationService.ps1    # Tests du module ValidationService
│   ├── Test-DependencyResolver.ps1   # Tests du module DependencyResolver
│   ├── Test-Integration.ps1          # Tests d'intégration
│   ├── Test-ProcessManagerFunctionality.ps1 # Tests fonctionnels
│   ├── Test-ProcessManagerPerformance.ps1  # Tests de performance
│   ├── Test-ProcessManagerLoad.ps1   # Tests de charge
│   └── ...                           # Autres tests
└── config/
    └── ...                           # Fichiers de configuration locaux
```

### Fichiers de configuration

Les fichiers de configuration du gestionnaire sont stockés dans :

```
projet/config/managers/process-manager/
└── process-manager.config.json       # Configuration principale
```

## Prérequis

Avant d'utiliser le gestionnaire de processus, assurez-vous que :

1. PowerShell 5.1 ou supérieur est installé sur votre système
2. Les droits d'accès appropriés sont configurés
3. Les gestionnaires que vous souhaitez utiliser sont installés

## Installation

### Installation automatique

Pour installer le gestionnaire de processus, utilisez le script d'installation :

```powershell
.\development\managers\process-manager\scripts\install-process-manager.ps1
```

### Installation des modules améliorés

Pour installer les modules améliorés (ManagerRegistrationService, ManifestParser, ValidationService, DependencyResolver), suivez ces étapes :

1. Exécutez le script d'installation des modules :

```powershell
.\development\managers\process-manager\scripts\install-modules.ps1
```

2. Vérifiez l'installation des modules :

```powershell
Import-Module ProcessManager
Get-Module ProcessManager
```

### Installation manuelle

Si vous préférez une installation manuelle, suivez ces étapes :

1. Copiez les fichiers du gestionnaire dans le répertoire approprié
2. Créez le fichier de configuration dans le répertoire approprié
3. Vérifiez que le gestionnaire fonctionne correctement

### Installation manuelle des modules

Si vous préférez installer les modules manuellement :

1. Copiez les modules dans le répertoire des modules PowerShell :

```powershell
$modulesPath = Join-Path -Path $env:PSModulePath.Split(';')[0] -ChildPath "ProcessManager"
New-Item -Path $modulesPath -ItemType Directory -Force
Copy-Item -Path "development\managers\process-manager\modules\*" -Destination $modulesPath -Recurse -Force
```

2. Importez le module :

```powershell
Import-Module ProcessManager
```

### Intégration des modules

Pour intégrer les modules au Process Manager existant :

1. Exécutez le script d'intégration des modules :

```powershell
.\development\managers\process-manager\scripts\integrate-modules.ps1
```

2. Vérifiez l'intégration :

```powershell
.\development\managers\process-manager\scripts\process-manager.ps1 -Command List
```

## Configuration

### Fichier de configuration principal

Le fichier de configuration principal du gestionnaire est situé à :

```
projet/config/managers/process-manager/process-manager.config.json
```

Voici un exemple de configuration :

```json
{
  "Enabled": true,
  "LogLevel": "Info",
  "LogPath": "logs/process-manager",
  "Managers": {
    "ModeManager": {
      "Path": "development/managers/mode-manager/scripts/mode-manager.ps1",
      "Enabled": true,
      "RegisteredAt": "2025-05-02 10:00:00"
    },
    "RoadmapManager": {
      "Path": "development/managers/roadmap-manager/scripts/roadmap-manager.ps1",
      "Enabled": true,
      "RegisteredAt": "2025-05-02 10:00:00"
    },
    "ScriptManager": {
      "Path": "development/managers/script-manager/scripts/script-manager.ps1",
      "Enabled": true,
      "RegisteredAt": "2025-05-02 10:00:00"
    },
    "ErrorManager": {
      "Path": "development/managers/error-manager/scripts/error-manager.ps1",
      "Enabled": true,
      "RegisteredAt": "2025-05-02 10:00:00"
    },
    "IntegratedManager": {
      "Path": "development/managers/integrated-manager/scripts/integrated-manager.ps1",
      "Enabled": true,
      "RegisteredAt": "2025-05-02 10:00:00"
    }
  }
}
```

### Options de configuration

| Option | Type | Description | Valeur par défaut |
|--------|------|-------------|-------------------|
| Enabled | boolean | Active ou désactive le gestionnaire | true |
| LogLevel | string | Niveau de journalisation (Debug, Info, Warning, Error) | "Info" |
| LogPath | string | Chemin vers le répertoire des journaux | "logs/process-manager" |
| Managers | object | Configuration des gestionnaires enregistrés | {} |

## Modules

Le gestionnaire de processus utilise plusieurs modules pour fournir des fonctionnalités avancées :

### Module ManagerRegistrationService

Ce module gère l'enregistrement, la mise à jour et la suppression des gestionnaires dans le Process Manager.

#### Fonctions principales

- `Register-Manager` : Enregistre un gestionnaire dans le Process Manager.
- `Unregister-Manager` : Désenregistre un gestionnaire du Process Manager.
- `Update-Manager` : Met à jour un gestionnaire enregistré.
- `Get-RegisteredManager` : Récupère les informations sur un gestionnaire enregistré.
- `Find-Manager` : Recherche des gestionnaires selon des critères spécifiques.

#### Exemple d'utilisation

```powershell
Import-Module ProcessManager
Register-Manager -Name "ModeManager" -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -Version "1.0.0"
```

### Module ManifestParser

Ce module analyse, valide et manipule les manifestes des gestionnaires.

#### Fonctions principales

- `Get-ManagerManifest` : Extrait le manifeste d'un gestionnaire à partir de différentes sources.
- `Test-ManifestValidity` : Valide un manifeste selon le schéma défini.
- `Convert-ToManifest` : Convertit un gestionnaire en manifeste.

#### Exemple d'utilisation

```powershell
Import-Module ProcessManager
$manifest = Get-ManagerManifest -Path "development\managers\mode-manager\scripts\mode-manager.ps1"
Test-ManifestValidity -Manifest $manifest
```

### Module ValidationService

Ce module valide les gestionnaires avant leur enregistrement dans le Process Manager.

#### Fonctions principales

- `Test-ManagerValidity` : Valide un gestionnaire en vérifiant sa syntaxe, ses fonctions requises et sa fonctionnalité.
- `Test-ManagerInterface` : Vérifie si un gestionnaire implémente les fonctions requises pour une interface spécifique.
- `Test-ManagerFunctionality` : Teste la fonctionnalité d'un gestionnaire en exécutant des commandes spécifiques.

#### Exemple d'utilisation

```powershell
Import-Module ProcessManager
Test-ManagerValidity -Path "development\managers\mode-manager\scripts\mode-manager.ps1"
```

### Module DependencyResolver

Ce module analyse, valide et résout les dépendances entre gestionnaires.

#### Fonctions principales

- `Get-ManagerDependencies` : Extrait les dépendances d'un gestionnaire à partir de son manifeste.
- `Test-DependenciesAvailability` : Vérifie si les dépendances d'un gestionnaire sont disponibles et compatibles.
- `Resolve-DependencyConflicts` : Détecte et résout les conflits de dépendances entre gestionnaires.
- `Get-ManagerLoadOrder` : Détermine l'ordre de chargement des gestionnaires en fonction de leurs dépendances.

#### Exemple d'utilisation

```powershell
Import-Module ProcessManager
$dependencies = Get-ManagerDependencies -Path "development\managers\mode-manager\scripts\mode-manager.ps1"
Test-DependenciesAvailability -Dependencies $dependencies
```

## Utilisation

### Commandes principales

Le gestionnaire de processus expose les commandes suivantes :

#### Commande 1 : Register

```powershell
.\development\managers\process-manager\scripts\process-manager.ps1 -Command Register -ManagerName "ModeManager" -ManagerPath "development\managers\mode-manager\scripts\mode-manager.ps1"
```

**Description :** Enregistre un nouveau gestionnaire

**Paramètres :**
- `-ManagerName` : Nom du gestionnaire à enregistrer
- `-ManagerPath` : Chemin vers le script du gestionnaire
- `-Force` : Force l'enregistrement même si le gestionnaire existe déjà (optionnel)

**Exemple :**
```powershell
.\development\managers\process-manager\scripts\process-manager.ps1 -Command Register -ManagerName "ModeManager" -ManagerPath "development\managers\mode-manager\scripts\mode-manager.ps1" -Force
```

#### Commande 2 : Discover

```powershell
.\development\managers\process-manager\scripts\process-manager.ps1 -Command Discover
```

**Description :** Découvre automatiquement les gestionnaires disponibles

**Paramètres :**
- `-Force` : Force la découverte même si les gestionnaires sont déjà enregistrés (optionnel)

**Exemple :**
```powershell
.\development\managers\process-manager\scripts\process-manager.ps1 -Command Discover -Force
```

### Exemples d'utilisation

#### Exemple 1 : Lister les gestionnaires enregistrés

```powershell
# Lister tous les gestionnaires enregistrés
.\development\managers\process-manager\scripts\process-manager.ps1 -Command List
```

#### Exemple 2 : Exécuter une commande sur un gestionnaire

```powershell
# Exécuter la commande SetMode sur le gestionnaire de modes
.\development\managers\process-manager\scripts\process-manager.ps1 -Command Run -ManagerName "ModeManager" -ManagerCommand "SetMode" -Mode "CHECK"
```

## Intégration avec d'autres gestionnaires

Le gestionnaire de processus s'intègre avec tous les autres gestionnaires du système :

### Intégration avec le gestionnaire de modes

```powershell
# Utiliser le gestionnaire de modes via le gestionnaire de processus
.\development\managers\process-manager\scripts\process-manager.ps1 -Command Run -ManagerName "ModeManager" -ManagerCommand "SetMode" -Mode "CHECK"
```

### Intégration avec le gestionnaire de roadmap

```powershell
# Utiliser le gestionnaire de roadmap via le gestionnaire de processus
.\development\managers\process-manager\scripts\process-manager.ps1 -Command Run -ManagerName "RoadmapManager" -ManagerCommand "ParseRoadmap" -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```

## Dépannage

### Problèmes courants et solutions

#### Problème 1 : Gestionnaire non trouvé

**Symptômes :**
- Message d'erreur indiquant que le gestionnaire n'existe pas
- La commande échoue avec une erreur de chemin

**Causes possibles :**
- Le gestionnaire n'est pas enregistré
- Le chemin vers le script du gestionnaire est incorrect

**Solutions :**
1. Vérifiez que le gestionnaire est correctement enregistré
2. Assurez-vous que le chemin vers le script du gestionnaire est correct
3. Utilisez la commande Discover pour découvrir automatiquement les gestionnaires

#### Problème 2 : Erreurs lors de l'exécution d'une commande

**Symptômes :**
- La commande échoue avec des erreurs
- Le gestionnaire ne répond pas comme prévu

**Causes possibles :**
- Paramètres incorrects passés au gestionnaire
- Problèmes dans le gestionnaire cible
- Gestionnaire désactivé

**Solutions :**
1. Vérifiez que les paramètres passés au gestionnaire sont corrects
2. Assurez-vous que le gestionnaire cible fonctionne correctement
3. Vérifiez que le gestionnaire est activé

### Journalisation

Le gestionnaire de processus génère des journaux dans le répertoire suivant :

```
logs/process-manager/
```

Les niveaux de journalisation peuvent être configurés dans le fichier de configuration principal.

## Tests

### Exécution des tests

Pour exécuter tous les tests du gestionnaire de processus, utilisez la commande suivante :

```powershell
.\development\managers\process-manager\tests\Test-ProcessManagerAll.ps1
```

Pour exécuter un type de test spécifique :

```powershell
.\development\managers\process-manager\tests\Test-ProcessManagerAll.ps1 -TestType Functional
```

Pour générer un rapport HTML des résultats des tests :

```powershell
.\development\managers\process-manager\tests\Test-ProcessManagerAll.ps1 -GenerateReport
```

### Types de tests disponibles

- **Tests unitaires :** Testent les fonctions individuelles du gestionnaire et des modules
  - `Test-ProcessManager.ps1` : Tests unitaires de base
  - `Test-ManifestParser.ps1` : Tests du module ManifestParser
  - `Test-ValidationService.ps1` : Tests du module ValidationService
  - `Test-DependencyResolver.ps1` : Tests du module DependencyResolver

- **Tests d'intégration :** Testent l'intégration entre les différents modules
  - `Test-Integration.ps1` : Tests d'intégration

- **Tests fonctionnels :** Testent le comportement du gestionnaire dans des scénarios réels
  - `Test-ProcessManagerFunctionality.ps1` : Tests fonctionnels

- **Tests de performance :** Évaluent les performances du gestionnaire
  - `Test-ProcessManagerPerformance.ps1` : Tests de performance

- **Tests de charge :** Évaluent la capacité du gestionnaire à gérer un grand nombre de gestionnaires et d'opérations
  - `Test-ProcessManagerLoad.ps1` : Tests de charge

## Bonnes pratiques

### Recommandations d'utilisation

1. Utilisez la commande Discover pour découvrir automatiquement les gestionnaires
2. Configurez correctement les gestionnaires avant de les utiliser
3. Utilisez la commande List pour vérifier l'état des gestionnaires
4. Utilisez les modules du Process Manager pour des fonctionnalités avancées
5. Validez les gestionnaires avant de les enregistrer
6. Vérifiez les dépendances des gestionnaires avant de les utiliser
7. Utilisez les manifestes pour documenter les gestionnaires

### Utilisation des modules

#### Bonnes pratiques pour le module ManagerRegistrationService

1. Utilisez `Register-Manager` avec le paramètre `-Version` pour spécifier la version du gestionnaire
2. Utilisez `Find-Manager` pour rechercher des gestionnaires selon des critères spécifiques
3. Utilisez `Update-Manager` pour mettre à jour un gestionnaire existant

#### Bonnes pratiques pour le module ManifestParser

1. Utilisez des manifestes pour documenter les gestionnaires
2. Placez les manifestes dans le même répertoire que les scripts des gestionnaires
3. Utilisez `Test-ManifestValidity` pour valider les manifestes avant de les utiliser

#### Bonnes pratiques pour le module ValidationService

1. Utilisez `Test-ManagerValidity` avant d'enregistrer un gestionnaire
2. Utilisez `Test-ManagerInterface` pour vérifier la compatibilité avec d'autres gestionnaires
3. Utilisez `Test-ManagerFunctionality` pour tester la fonctionnalité d'un gestionnaire

#### Bonnes pratiques pour le module DependencyResolver

1. Utilisez `Get-ManagerDependencies` pour extraire les dépendances d'un gestionnaire
2. Utilisez `Test-DependenciesAvailability` pour vérifier la disponibilité des dépendances
3. Utilisez `Get-ManagerLoadOrder` pour déterminer l'ordre de chargement des gestionnaires

### Sécurité

1. N'exécutez pas le gestionnaire avec des privilèges administrateur sauf si nécessaire
2. Protégez l'accès aux fichiers de configuration
3. Limitez l'accès aux gestionnaires sensibles

## Références

- [Guide de création d'un gestionnaire](creating_manager.md)
- [Documentation du gestionnaire intégré](integrated_manager.md)
- [Documentation du gestionnaire de modes](mode_manager.md)
- [Documentation du gestionnaire de roadmap](roadmap_manager.md)
- [Documentation du gestionnaire de scripts](script_manager.md)
- [Documentation du gestionnaire d'erreurs](error_manager.md)

## Historique des versions

| Version | Date | Description |
|---------|------|-------------|
| 1.1.0 | 2025-05-15 | Ajout des modules améliorés (ManagerRegistrationService, ManifestParser, ValidationService, DependencyResolver) |
| 1.0.0 | 2025-05-02 | Version initiale |
