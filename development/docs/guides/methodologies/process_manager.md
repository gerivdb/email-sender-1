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
│   ├── install-process-manager.ps1   # Script d'installation
│   └── ...                           # Autres scripts
├── modules/
│   └── ...                           # Modules PowerShell
├── tests/
│   ├── Test-ProcessManager.ps1       # Tests unitaires
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

### Installation manuelle

Si vous préférez une installation manuelle, suivez ces étapes :

1. Copiez les fichiers du gestionnaire dans le répertoire approprié
2. Créez le fichier de configuration dans le répertoire approprié
3. Vérifiez que le gestionnaire fonctionne correctement

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

Pour exécuter les tests du gestionnaire de processus, utilisez la commande suivante :

```powershell
.\development\managers\process-manager\tests\Test-ProcessManager.ps1
```

### Types de tests disponibles

- **Tests unitaires :** Testent les fonctions individuelles du gestionnaire
- **Tests d'intégration :** Testent l'intégration avec d'autres composants
- **Tests de performance :** Évaluent les performances du gestionnaire

## Bonnes pratiques

### Recommandations d'utilisation

1. Utilisez la commande Discover pour découvrir automatiquement les gestionnaires
2. Configurez correctement les gestionnaires avant de les utiliser
3. Utilisez la commande List pour vérifier l'état des gestionnaires

### Sécurité

1. N'exécutez pas le gestionnaire avec des privilèges administrateur sauf si nécessaire
2. Protégez l'accès aux fichiers de configuration
3. Limitez l'accès aux gestionnaires sensibles

## Références

- [Documentation du gestionnaire intégré](integrated_manager.md)
- [Documentation du gestionnaire de modes](mode_manager.md)
- [Documentation du gestionnaire de roadmap](roadmap_manager.md)
- [Documentation du gestionnaire de scripts](script_manager.md)
- [Documentation du gestionnaire d'erreurs](error_manager.md)

## Historique des versions

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-05-02 | Version initiale |
