# Guide du Gestionnaire Mode Manager

## Introduction

Le gestionnaire Mode Manager est un composant essentiel du système qui gère les modes opérationnels du projet. Ce document détaille son fonctionnement, ses paramètres, et fournit des exemples d'utilisation pour vous aider à l'utiliser efficacement.

## Objectif

L'objectif principal du gestionnaire Mode Manager est de fournir une interface unifiée pour basculer entre différents modes opérationnels. Il permet notamment de :

- Gérer les différents modes opérationnels (CHECK, GRAN, DEV-R, etc.)
- Configurer et personnaliser les comportements des modes
- Intégrer les modes avec d'autres gestionnaires
- Journaliser et surveiller l'utilisation des modes

## Architecture

### Structure des répertoires

Le gestionnaire Mode Manager est organisé selon la structure de répertoires suivante :

```
development/managers/mode-manager/
├── scripts/
│   ├── mode-manager.ps1           # Script principal
│   ├── install-mode-manager.ps1   # Script d'installation
│   └── ...                        # Autres scripts
├── modules/
│   └── ...                        # Modules PowerShell
├── tests/
│   ├── Test-ModeManager.ps1       # Tests unitaires
│   └── ...                        # Autres tests
└── config/
    └── ...                        # Fichiers de configuration locaux
```

### Fichiers de configuration

Les fichiers de configuration du gestionnaire sont stockés dans :

```
projet/config/managers/mode-manager/
└── mode-manager.config.json       # Configuration principale
```

## Prérequis

Avant d'utiliser le gestionnaire Mode Manager, assurez-vous que :

1. PowerShell 5.1 ou supérieur est installé sur votre système
2. Le gestionnaire intégré est installé
3. Les droits d'accès appropriés sont configurés

## Installation

### Installation automatique

Pour installer le gestionnaire Mode Manager, utilisez le script d'installation :

```powershell
.\development\managers\mode-manager\scripts\install-mode-manager.ps1
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
projet/config/managers/mode-manager/mode-manager.config.json
```

Voici un exemple de configuration :

```json
{
  "Enabled": true,
  "LogLevel": "Info",
  "DefaultMode": "DEV-R",
  "Modes": {
    "CHECK": {
      "Description": "Vérifie et met à jour l'état des tâches",
      "ScriptPath": "development/scripts/mode-manager/modes/check-mode.ps1"
    },
    "GRAN": {
      "Description": "Décompose les tâches en sous-tâches",
      "ScriptPath": "development/scripts/mode-manager/modes/gran-mode.ps1"
    },
    "DEV-R": {
      "Description": "Implémente les tâches de la roadmap",
      "ScriptPath": "development/scripts/mode-manager/modes/dev-r-mode.ps1"
    }
  }
}
```

### Options de configuration

| Option | Type | Description | Valeur par défaut |
|--------|------|-------------|-------------------|
| Enabled | boolean | Active ou désactive le gestionnaire | true |
| LogLevel | string | Niveau de journalisation (Debug, Info, Warning, Error) | "Info" |
| DefaultMode | string | Mode par défaut à utiliser | "DEV-R" |
| Modes | object | Configuration des modes disponibles | {} |

## Utilisation

### Commandes principales

Le gestionnaire Mode Manager expose les commandes suivantes :

#### Commande 1 : SetMode

```powershell
.\development\managers\mode-manager\scripts\mode-manager.ps1 -Command SetMode -Mode CHECK
```

**Description :** Définit le mode opérationnel actif

**Paramètres :**
- `-Mode` : Le mode à activer (CHECK, GRAN, DEV-R, etc.)

**Exemple :**
```powershell
.\development\managers\mode-manager\scripts\mode-manager.ps1 -Command SetMode -Mode GRAN
```

#### Commande 2 : RunMode

```powershell
.\development\managers\mode-manager\scripts\mode-manager.ps1 -Command RunMode -Mode CHECK -FilePath "path/to/file.md"
```

**Description :** Exécute une opération dans le mode spécifié

**Paramètres :**
- `-Mode` : Le mode à utiliser (CHECK, GRAN, DEV-R, etc.)
- `-FilePath` : Chemin vers le fichier à traiter

**Exemple :**
```powershell
.\development\managers\mode-manager\scripts\mode-manager.ps1 -Command RunMode -Mode CHECK -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```

### Exemples d'utilisation

#### Exemple 1 : Utilisation du mode GRAN

```powershell
# Décomposer une tâche en sous-tâches
.\development\managers\mode-manager\scripts\mode-manager.ps1 -Command RunMode -Mode GRAN -FilePath "projet/roadmaps/roadmap_complete_converted.md" -Selection "1.2.3"
```

#### Exemple 2 : Vérification des tâches complétées

```powershell
# Vérifier et mettre à jour l'état des tâches
.\development\managers\mode-manager\scripts\mode-manager.ps1 -Command RunMode -Mode CHECK -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```

## Intégration avec d'autres gestionnaires

Le gestionnaire Mode Manager s'intègre avec les autres gestionnaires du système :

### Intégration avec le gestionnaire intégré

```powershell
# Utiliser le gestionnaire Mode Manager via le gestionnaire intégré
.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Manager ModeManager -Command SetMode -Mode CHECK
```

### Intégration avec le gestionnaire de roadmap

```powershell
# Utiliser le gestionnaire Mode Manager avec le gestionnaire de roadmap
.\development\managers\roadmap-manager\scripts\roadmap-manager.ps1 -UseMode CHECK -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```

## Dépannage

### Problèmes courants et solutions

#### Problème 1 : Le mode ne s'active pas correctement

**Symptômes :**
- Le mode ne répond pas comme prévu
- Des erreurs s'affichent dans la console

**Causes possibles :**
- Le script du mode est manquant ou corrompu
- Les dépendances ne sont pas installées

**Solutions :**
1. Vérifiez que le script du mode existe et est accessible
2. Installez les dépendances manquantes
3. Vérifiez les journaux pour plus d'informations

#### Problème 2 : Erreurs lors de l'exécution d'un mode

**Symptômes :**
- Le mode s'arrête avec des erreurs
- Le fichier n'est pas modifié comme prévu

**Causes possibles :**
- Problèmes de permissions sur les fichiers
- Format de fichier incompatible
- Erreurs dans le script du mode

**Solutions :**
1. Vérifiez les permissions sur les fichiers
2. Assurez-vous que le format du fichier est compatible avec le mode
3. Consultez les journaux pour identifier les erreurs spécifiques

### Journalisation

Le gestionnaire Mode Manager génère des journaux dans le répertoire suivant :

```
logs/mode-manager/
```

Les niveaux de journalisation peuvent être configurés dans le fichier de configuration principal.

## Tests

### Exécution des tests

Pour exécuter les tests du gestionnaire Mode Manager, utilisez la commande suivante :

```powershell
.\development\managers\mode-manager\tests\Test-ModeManager.ps1
```

### Types de tests disponibles

- **Tests unitaires :** Testent les fonctions individuelles du gestionnaire
- **Tests d'intégration :** Testent l'intégration avec d'autres composants
- **Tests de performance :** Évaluent les performances du gestionnaire

## Bonnes pratiques

### Recommandations d'utilisation

1. Utilisez le gestionnaire intégré pour accéder à ce gestionnaire lorsque c'est possible
2. Configurez correctement le fichier de configuration avant d'utiliser le gestionnaire
3. Consultez les journaux en cas de problème

### Sécurité

1. N'exécutez pas le gestionnaire avec des privilèges administrateur sauf si nécessaire
2. Protégez l'accès aux fichiers de configuration
3. Utilisez des mots de passe forts pour les services associés

## Références

- [Documentation du gestionnaire intégré](integrated_manager.md)
- [Documentation du gestionnaire de roadmap](roadmap_manager.md)
- [Guide des bonnes pratiques](../best-practices/powershell_best_practices.md)

## Historique des versions

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-04-29 | Version initiale |
