# Guide du Gestionnaire de Roadmap

## Introduction

Le gestionnaire de roadmap est un composant essentiel du système qui gère le suivi, l'analyse et la mise à jour des roadmaps du projet. Ce document détaille son fonctionnement, ses paramètres, et fournit des exemples d'utilisation pour vous aider à l'utiliser efficacement.

## Objectif

L'objectif principal du gestionnaire de roadmap est de fournir une interface unifiée pour gérer les roadmaps du projet. Il permet notamment de :

- Analyser et parser les fichiers de roadmap
- Suivre l'avancement des tâches
- Mettre à jour l'état des tâches
- Générer des rapports sur l'avancement du projet

## Architecture

### Structure des répertoires

Le gestionnaire de roadmap est organisé selon la structure de répertoires suivante :

```
development/managers/roadmap-manager/
├── scripts/
│   ├── roadmap-manager.ps1           # Script principal
│   ├── install-roadmap-manager.ps1   # Script d'installation
│   └── ...                           # Autres scripts
├── modules/
│   └── ...                           # Modules PowerShell
├── tests/
│   ├── Test-RoadmapManager.ps1       # Tests unitaires
│   └── ...                           # Autres tests
└── config/
    └── ...                           # Fichiers de configuration locaux
```

### Fichiers de configuration

Les fichiers de configuration du gestionnaire sont stockés dans :

```
projet/config/managers/roadmap-manager/
└── roadmap-manager.config.json       # Configuration principale
```

## Prérequis

Avant d'utiliser le gestionnaire de roadmap, assurez-vous que :

1. PowerShell 5.1 ou supérieur est installé sur votre système
2. Le gestionnaire intégré est installé
3. Les droits d'accès appropriés sont configurés

## Installation

### Installation automatique

Pour installer le gestionnaire de roadmap, utilisez le script d'installation :

```powershell
.\development\managers\roadmap-manager\scripts\install-roadmap-manager.ps1
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
projet/config/managers/roadmap-manager/roadmap-manager.config.json
```

Voici un exemple de configuration :

```json
{
  "Enabled": true,
  "LogLevel": "Info",
  "RoadmapPaths": {
    "Main": "projet/roadmaps/roadmap_complete_converted.md",
    "Development": "development/roadmap/Roadmap/roadmap_development.md"
  },
  "DefaultRoadmapPath": "projet/roadmaps/roadmap_complete_converted.md",
  "TaskCompletionPattern": "\\[x\\]",
  "TaskPendingPattern": "\\[ \\]",
  "TaskIdPattern": "\\d+\\.\\d+(\\.\\d+)*",
  "ReportOutputPath": "projet/reports/roadmap",
  "PerformanceMeasurement": {
    "Enabled": true,
    "OutputPath": "logs/performance/roadmap-manager"
  }
}
```

### Options de configuration

| Option | Type | Description | Valeur par défaut |
|--------|------|-------------|-------------------|
| Enabled | boolean | Active ou désactive le gestionnaire | true |
| LogLevel | string | Niveau de journalisation (Debug, Info, Warning, Error) | "Info" |
| RoadmapPaths | object | Chemins vers les différentes roadmaps | {} |
| DefaultRoadmapPath | string | Chemin par défaut pour la roadmap principale | "projet/roadmaps/roadmap_complete_converted.md" |
| TaskCompletionPattern | string | Expression régulière pour identifier les tâches complétées | "\\[x\\]" |
| TaskPendingPattern | string | Expression régulière pour identifier les tâches en attente | "\\[ \\]" |
| TaskIdPattern | string | Expression régulière pour identifier les identifiants de tâches | "\\d+\\.\\d+(\\.\\d+)*" |
| ReportOutputPath | string | Chemin de sortie pour les rapports | "projet/reports/roadmap" |
| PerformanceMeasurement | object | Configuration de la mesure de performance | {} |

## Utilisation

### Commandes principales

Le gestionnaire de roadmap expose les commandes suivantes :

#### Commande 1 : ParseRoadmap

```powershell
.\development\managers\roadmap-manager\scripts\roadmap-manager.ps1 -Command ParseRoadmap -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```

**Description :** Analyse un fichier de roadmap

**Paramètres :**
- `-FilePath` : Chemin vers le fichier de roadmap
- `-OutputFormat` : Format de sortie (JSON, CSV, Object) (optionnel)

**Exemple :**
```powershell
.\development\managers\roadmap-manager\scripts\roadmap-manager.ps1 -Command ParseRoadmap -FilePath "projet/roadmaps/roadmap_complete_converted.md" -OutputFormat "JSON"
```

#### Commande 2 : UpdateTaskStatus

```powershell
.\development\managers\roadmap-manager\scripts\roadmap-manager.ps1 -Command UpdateTaskStatus -FilePath "projet/roadmaps/roadmap_complete_converted.md" -TaskId "1.2.3" -Status "Completed"
```

**Description :** Met à jour le statut d'une tâche

**Paramètres :**
- `-FilePath` : Chemin vers le fichier de roadmap
- `-TaskId` : Identifiant de la tâche
- `-Status` : Nouveau statut de la tâche (Completed, Pending)

**Exemple :**
```powershell
.\development\managers\roadmap-manager\scripts\roadmap-manager.ps1 -Command UpdateTaskStatus -FilePath "projet/roadmaps/roadmap_complete_converted.md" -TaskId "1.2.3" -Status "Completed"
```

### Exemples d'utilisation

#### Exemple 1 : Génération d'un rapport d'avancement

```powershell
# Générer un rapport d'avancement
.\development\managers\roadmap-manager\scripts\roadmap-manager.ps1 -Command GenerateReport -FilePath "projet/roadmaps/roadmap_complete_converted.md" -OutputFormat "HTML" -OutputPath "projet/reports/roadmap/progress_report.html"
```

#### Exemple 2 : Vérification des tâches complétées

```powershell
# Vérifier les tâches complétées
.\development\managers\roadmap-manager\scripts\roadmap-manager.ps1 -Command GetCompletedTasks -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```

## Intégration avec d'autres gestionnaires

Le gestionnaire de roadmap s'intègre avec les autres gestionnaires du système :

### Intégration avec le gestionnaire intégré

```powershell
# Utiliser le gestionnaire de roadmap via le gestionnaire intégré
.\development\managers\integrated-manager\scripts\integrated-manager.ps1 -Manager RoadmapManager -Command ParseRoadmap -FilePath "projet/roadmaps/roadmap_complete_converted.md"
```

### Intégration avec le gestionnaire de modes

```powershell
# Utiliser le gestionnaire de roadmap avec le gestionnaire de modes
.\development\managers\mode-manager\scripts\mode-manager.ps1 -Mode CHECK -UseManager RoadmapManager -Command UpdateTaskStatus -FilePath "projet/roadmaps/roadmap_complete_converted.md" -TaskId "1.2.3" -Status "Completed"
```

## Dépannage

### Problèmes courants et solutions

#### Problème 1 : Erreurs de parsing de la roadmap

**Symptômes :**
- Le parsing de la roadmap échoue
- Des erreurs de format sont signalées

**Causes possibles :**
- Format incorrect du fichier de roadmap
- Expressions régulières incorrectes dans la configuration
- Fichier de roadmap corrompu

**Solutions :**
1. Vérifiez que le format du fichier de roadmap est correct
2. Assurez-vous que les expressions régulières dans la configuration sont adaptées au format du fichier
3. Vérifiez l'intégrité du fichier de roadmap

#### Problème 2 : Erreurs lors de la mise à jour des tâches

**Symptômes :**
- La mise à jour des tâches échoue
- Les changements ne sont pas enregistrés

**Causes possibles :**
- Identifiant de tâche incorrect
- Problèmes de permissions sur le fichier de roadmap
- Conflits de modification

**Solutions :**
1. Vérifiez que l'identifiant de tâche est correct
2. Assurez-vous d'avoir les permissions nécessaires pour modifier le fichier
3. Vérifiez qu'il n'y a pas de conflits de modification

### Journalisation

Le gestionnaire de roadmap génère des journaux dans le répertoire suivant :

```
logs/roadmap-manager/
```

Les niveaux de journalisation peuvent être configurés dans le fichier de configuration principal.

## Tests

### Exécution des tests

Pour exécuter les tests du gestionnaire de roadmap, utilisez la commande suivante :

```powershell
.\development\managers\roadmap-manager\tests\Test-RoadmapManager.ps1
```

### Types de tests disponibles

- **Tests unitaires :** Testent les fonctions individuelles du gestionnaire
- **Tests d'intégration :** Testent l'intégration avec d'autres composants
- **Tests de performance :** Évaluent les performances du gestionnaire

## Bonnes pratiques

### Recommandations d'utilisation

1. Utilisez le gestionnaire de roadmap pour toutes les opérations sur les roadmaps
2. Maintenez un format cohérent pour les fichiers de roadmap
3. Générez régulièrement des rapports d'avancement

### Sécurité

1. Limitez l'accès en écriture aux fichiers de roadmap
2. Sauvegardez régulièrement les fichiers de roadmap
3. Vérifiez les modifications avant de les appliquer

## Références

- [Documentation du gestionnaire intégré](integrated_manager.md)
- [Documentation du gestionnaire de modes](mode_manager.md)
- [Guide des bonnes pratiques Markdown](../best-practices/markdown_best_practices.md)

## Historique des versions

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-04-29 | Version initiale |
