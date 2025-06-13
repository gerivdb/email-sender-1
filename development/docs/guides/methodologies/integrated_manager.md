# Guide du Gestionnaire Intégré

## Introduction

Le gestionnaire intégré est un composant central du système qui coordonne et unifie l'accès à tous les autres gestionnaires. Ce document détaille son fonctionnement, ses paramètres, et fournit des exemples d'utilisation pour vous aider à l'utiliser efficacement.

## Objectif

L'objectif principal du gestionnaire intégré est de fournir un point d'entrée unique pour accéder à toutes les fonctionnalités du système. Il permet notamment de :

- Centraliser l'accès à tous les gestionnaires du système
- Simplifier l'utilisation des différents gestionnaires
- Gérer les dépendances entre les gestionnaires
- Assurer la cohérence des opérations entre les gestionnaires

## Architecture

### Structure des répertoires

Le gestionnaire intégré est organisé selon la structure de répertoires suivante :

```plaintext
development/managers/integrated-manager/
├── scripts/
│   ├── integrated-manager.ps1           # Script principal

│   ├── install-integrated-manager.ps1   # Script d'installation

│   └── ...                              # Autres scripts

├── modules/
│   └── ...                              # Modules PowerShell

├── tests/
│   ├── Test-IntegratedManager.ps1       # Tests unitaires

│   └── ...                              # Autres tests

└── config/
    └── ...                              # Fichiers de configuration locaux

```plaintext
### Fichiers de configuration

Les fichiers de configuration du gestionnaire sont stockés dans :

```plaintext
projet/config/managers/integrated-manager/
└── integrated-manager.config.json       # Configuration principale

```plaintext
## Prérequis

Avant d'utiliser le gestionnaire intégré, assurez-vous que :

1. PowerShell 5.1 ou supérieur est installé sur votre système
2. Les gestionnaires que vous souhaitez utiliser sont installés
3. Les droits d'accès appropriés sont configurés

## Installation

### Installation automatique

Pour installer le gestionnaire intégré, utilisez le script d'installation :

```powershell
.\development\managers\integrated-manager\scripts\install-integrated-manager.ps1
```plaintext
### Installation manuelle

Si vous préférez une installation manuelle, suivez ces étapes :

1. Copiez les fichiers du gestionnaire dans le répertoire approprié
2. Créez le fichier de configuration dans le répertoire approprié
3. Vérifiez que le gestionnaire fonctionne correctement

## Configuration

### Fichier de configuration principal

Le fichier de configuration principal du gestionnaire est situé à :

```plaintext
projet/config/managers/integrated-manager/integrated-manager.config.json
```plaintext
Voici un exemple de configuration :

```json
{
  "Enabled": true,
  "LogLevel": "Info",
  "Managers": {
    "ModeManager": {
      "Path": "development/managers/mode-manager/scripts/mode-manager.ps1",
      "Enabled": true
    },
    "RoadmapManager": {
      "Path": "development/managers/roadmap-manager/scripts/roadmap-manager.ps1",
      "Enabled": true
    },
    "ScriptManager": {
      "Path": "development/managers/script-manager/scripts/script-manager.ps1",
      "Enabled": true
    },
    "ErrorManager": {
      "Path": "development/managers/error-manager/scripts/error-manager.ps1",
      "Enabled": true
    }
  }
}
```plaintext
### Options de configuration

| Option | Type | Description | Valeur par défaut |
|--------|------|-------------|-------------------|
| Enabled | boolean | Active ou désactive le gestionnaire | true |
| LogLevel | string | Niveau de journalisation (Debug, Info, Warning, Error) | "Info" |
| Managers | object | Configuration des gestionnaires disponibles | {} |

## Utilisation

### Commandes principales

Le gestionnaire intégré expose les commandes suivantes :

#### Commande 1 : RunManager

```powershell
.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Command RunManager -Manager ModeManager -ManagerCommand SetMode -Mode CHECK
```plaintext
**Description :** Exécute une commande sur un gestionnaire spécifique

**Paramètres :**
- `-Manager` : Le gestionnaire à utiliser
- `-ManagerCommand` : La commande à exécuter sur le gestionnaire
- Paramètres supplémentaires spécifiques au gestionnaire

**Exemple :**
```powershell
.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Command RunManager -Manager RoadmapManager -ManagerCommand ParseRoadmap -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```plaintext
#### Commande 2 : ListManagers

```powershell
.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Command ListManagers
```plaintext
**Description :** Liste tous les gestionnaires disponibles

**Exemple :**
```powershell
.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Command ListManagers -Detailed
```plaintext
### Exemples d'utilisation

#### Exemple 1 : Utilisation du gestionnaire de modes

```powershell
# Activer le mode CHECK via le gestionnaire intégré

.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Command RunManager -Manager ModeManager -ManagerCommand SetMode -Mode CHECK
```plaintext
#### Exemple 2 : Utilisation du gestionnaire de roadmap

```powershell
# Analyser une roadmap via le gestionnaire intégré

.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Command RunManager -Manager RoadmapManager -ManagerCommand ParseRoadmap -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```plaintext
## Intégration avec d'autres gestionnaires

Le gestionnaire intégré est conçu pour s'intégrer avec tous les autres gestionnaires du système :

### Intégration avec le gestionnaire de modes

```powershell
# Utiliser le gestionnaire de modes via le gestionnaire intégré

.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Command RunManager -Manager ModeManager -ManagerCommand RunMode -Mode CHECK -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```plaintext
### Intégration avec le gestionnaire de scripts

```powershell
# Utiliser le gestionnaire de scripts via le gestionnaire intégré

.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Command RunManager -Manager ScriptManager -ManagerCommand RunScript -ScriptPath "development/scripts/maintenance/find-managers.ps1"
```plaintext
## Dépannage

### Problèmes courants et solutions

#### Problème 1 : Gestionnaire non trouvé

**Symptômes :**
- Message d'erreur indiquant que le gestionnaire n'existe pas
- La commande échoue avec une erreur de chemin

**Causes possibles :**
- Le gestionnaire n'est pas configuré correctement
- Le chemin vers le script du gestionnaire est incorrect

**Solutions :**
1. Vérifiez que le gestionnaire est correctement configuré dans le fichier de configuration
2. Assurez-vous que le chemin vers le script du gestionnaire est correct
3. Vérifiez que le gestionnaire est installé

#### Problème 2 : Erreurs lors de l'exécution d'une commande

**Symptômes :**
- La commande échoue avec des erreurs
- Le gestionnaire ne répond pas comme prévu

**Causes possibles :**
- Paramètres incorrects passés au gestionnaire
- Problèmes dans le gestionnaire cible
- Conflits entre les gestionnaires

**Solutions :**
1. Vérifiez que les paramètres passés au gestionnaire sont corrects
2. Consultez les journaux du gestionnaire cible pour plus d'informations
3. Assurez-vous qu'il n'y a pas de conflits entre les gestionnaires

### Journalisation

Le gestionnaire intégré génère des journaux dans le répertoire suivant :

```plaintext
logs/integrated-manager/
```plaintext
Les niveaux de journalisation peuvent être configurés dans le fichier de configuration principal.

## Tests

### Exécution des tests

Pour exécuter les tests du gestionnaire intégré, utilisez la commande suivante :

```powershell
.\development\managers\integrated-manager\tests\Test-IntegratedManager.ps1
```plaintext
### Types de tests disponibles

- **Tests unitaires :** Testent les fonctions individuelles du gestionnaire
- **Tests d'intégration :** Testent l'intégration avec d'autres gestionnaires
- **Tests de performance :** Évaluent les performances du gestionnaire

## Bonnes pratiques

### Recommandations d'utilisation

1. Utilisez le gestionnaire intégré comme point d'entrée principal pour toutes les opérations
2. Configurez correctement tous les gestionnaires avant d'utiliser le gestionnaire intégré
3. Consultez les journaux en cas de problème

### Sécurité

1. N'exécutez pas le gestionnaire avec des privilèges administrateur sauf si nécessaire
2. Protégez l'accès aux fichiers de configuration
3. Limitez l'accès aux gestionnaires sensibles

## Références

- [Documentation du gestionnaire de modes](mode_manager.md)
- [Documentation du gestionnaire de roadmap](roadmap_manager.md)
- [Guide des bonnes pratiques](../best-practices/powershell_best_practices.md)

## Historique des versions

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-04-29 | Version initiale |
