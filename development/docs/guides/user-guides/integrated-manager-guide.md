# Guide d'utilisation du gestionnaire intégré

Ce guide présente l'utilisation du gestionnaire intégré, qui unifie les fonctionnalités du Mode Manager et du Roadmap Manager pour offrir une interface unique pour la gestion des modes opérationnels et des roadmaps.

## Table des matières

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Utilisation des modes](#utilisation-des-modes)
5. [Utilisation des workflows](#utilisation-des-workflows)
6. [Automatisation](#automatisation)
7. [Intégration avec d'autres outils](#intégration-avec-dautres-outils)
8. [Résolution des problèmes](#résolution-des-problèmes)
9. [Ressources supplémentaires](#ressources-supplémentaires)

## Introduction

Le gestionnaire intégré est un outil qui unifie les fonctionnalités du Mode Manager et du Roadmap Manager. Il permet de :

- Exécuter les modes opérationnels (CHECK, GRAN, etc.)
- Gérer les roadmaps (synchronisation, rapports, planification)
- Exécuter des workflows prédéfinis
- Automatiser les tâches récurrentes

## Installation

### Prérequis

- PowerShell 5.1 ou supérieur
- Module RoadmapParser installé

### Vérification de l'installation

Pour vérifier que le gestionnaire intégré est correctement installé, exécutez la commande suivante :

```powershell
.\development\scripts\integrated-manager.ps1 -ListModes
```

Cette commande devrait afficher la liste des modes disponibles.

## Configuration

Le gestionnaire intégré utilise un fichier de configuration unifié pour stocker les paramètres des différents modes et workflows.

### Fichier de configuration

Le fichier de configuration par défaut se trouve à l'emplacement suivant :

```
development\config\unified-config.json
```

### Structure du fichier de configuration

Le fichier de configuration est au format JSON et contient les sections suivantes :

- `General` : Paramètres généraux
- `Modes` : Configuration des modes opérationnels
- `Roadmaps` : Configuration des roadmaps
- `Workflows` : Configuration des workflows
- `Integration` : Paramètres d'intégration

### Exemple de configuration

```json
{
  "General": {
    "RoadmapPath": "projet\\roadmaps\\Roadmap\\roadmap_complete_converted.md",
    "ActiveDocumentPath": "projet\\roadmaps\\Roadmap\\roadmap_complete_converted.md",
    "ReportPath": "projet\\roadmaps\\Reports",
    "LogPath": "projet\\roadmaps\\Logs",
    "DefaultLanguage": "fr-FR",
    "DefaultEncoding": "UTF8-BOM",
    "ProjectRoot": "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
  },
  "Modes": {
    "Check": {
      "Enabled": true,
      "ScriptPath": "development\\scripts\\maintenance\\modes\\check.ps1",
      "DefaultRoadmapFile": "projet\\roadmaps\\Roadmap\\roadmap_complete_converted.md",
      "DefaultActiveDocumentPath": "projet\\roadmaps\\Roadmap\\roadmap_complete_converted.md",
      "AutoUpdateRoadmap": true,
      "GenerateReport": true,
      "ReportPath": "projet\\roadmaps\\Reports",
      "AutoUpdateCheckboxes": true,
      "RequireFullTestCoverage": true,
      "SimulationModeDefault": true
    },
    "Gran": {
      "Enabled": true,
      "ScriptPath": "development\\scripts\\maintenance\\modes\\gran-mode.ps1",
      "DefaultRoadmapFile": "projet\\roadmaps\\Roadmap\\roadmap_complete_converted.md",
      "MaxTaskSize": 5,
      "MaxComplexity": 7,
      "AutoIndent": true,
      "GenerateSubtasks": true,
      "UpdateInPlace": true,
      "IndentationStyle": "Spaces2",
      "CheckboxStyle": "GitHub"
    },
    "RoadmapSync": {
      "Enabled": true,
      "ScriptPath": "development\\scripts\\maintenance\\modes\\roadmap-sync-mode.ps1",
      "DefaultSourceFormat": "Markdown",
      "DefaultTargetFormat": "JSON",
      "DefaultSourcePath": "projet\\roadmaps\\Roadmap\\roadmap_complete_converted.md",
      "DefaultTargetPath": "projet\\roadmaps\\Roadmap\\roadmap_complete.json"
    },
    "RoadmapReport": {
      "Enabled": true,
      "ScriptPath": "development\\scripts\\maintenance\\modes\\roadmap-report-mode.ps1",
      "DefaultReportFormat": "HTML",
      "DefaultOutputPath": "projet\\roadmaps\\Reports",
      "IncludeCharts": true,
      "IncludeTrends": true,
      "IncludePredictions": true,
      "DaysToAnalyze": 30
    },
    "RoadmapPlan": {
      "Enabled": true,
      "ScriptPath": "development\\scripts\\maintenance\\modes\\roadmap-plan-mode.ps1",
      "DefaultOutputPath": "projet\\roadmaps\\Plans",
      "DaysToForecast": 30
    }
  },
  "Workflows": {
    "Development": {
      "Description": "Workflow de développement complet",
      "Modes": ["GRAN", "DEV-R", "TEST", "CHECK"],
      "AutoContinue": true,
      "StopOnError": true
    },
    "RoadmapManagement": {
      "Description": "Workflow de gestion de roadmap",
      "Modes": ["ROADMAP-SYNC", "ROADMAP-REPORT", "ROADMAP-PLAN"],
      "AutoContinue": true,
      "StopOnError": true
    }
  }
}
```

### Personnalisation de la configuration

Vous pouvez personnaliser la configuration en modifiant le fichier `unified-config.json` ou en spécifiant un fichier de configuration personnalisé avec le paramètre `-ConfigPath` :

```powershell
.\development\scripts\integrated-manager.ps1 -Mode CHECK -ConfigPath "my-config.json"
```

## Utilisation des modes

Le gestionnaire intégré prend en charge les modes opérationnels suivants :

### Modes opérationnels

- `CHECK` : Vérifie l'état d'avancement des tâches
- `GRAN` : Décompose les tâches en sous-tâches plus granulaires
- `DEV-R` : Implémente les tâches de la roadmap
- `TEST` : Exécute les tests
- `DEBUG` : Aide au débogage
- `REVIEW` : Revoit le code
- `ARCHI` : Analyse l'architecture
- `C-BREAK` : Détecte et corrige les dépendances circulaires
- `OPTI` : Optimise le code
- `PREDIC` : Prédit les performances et détecte les anomalies

### Modes de gestion de roadmap

- `ROADMAP-SYNC` : Synchronise les roadmaps entre différents formats
- `ROADMAP-REPORT` : Génère des rapports sur l'état des roadmaps
- `ROADMAP-PLAN` : Planifie les tâches futures

### Exemples d'utilisation des modes

#### Mode CHECK

```powershell
# Vérifier l'état d'avancement d'une tâche
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Vérifier l'état d'avancement d'une tâche et mettre à jour la roadmap
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -UpdateRoadmap
```

#### Mode GRAN

```powershell
# Décomposer une tâche en sous-tâches
.\development\scripts\integrated-manager.ps1 -Mode GRAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Décomposer une tâche en sous-tâches avec un fichier de sous-tâches
.\development\scripts\integrated-manager.ps1 -Mode GRAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"
```

#### Mode ROADMAP-SYNC

```powershell
# Synchroniser une roadmap Markdown vers JSON
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"

# Synchroniser plusieurs roadmaps en une seule opération
$sourcePaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath $sourcePaths -MultiSync -TargetFormat "JSON"
```

#### Mode ROADMAP-REPORT

```powershell
# Générer un rapport HTML
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"

# Générer des rapports dans tous les formats
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "All"
```

#### Mode ROADMAP-PLAN

```powershell
# Générer un plan d'action
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

# Générer un plan d'action avec une période de prévision personnalisée
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -DaysToForecast 60
```

## Utilisation des workflows

Les workflows permettent d'exécuter plusieurs modes en séquence.

### Workflows prédéfinis

- `Development` : Workflow de développement complet (GRAN, DEV-R, TEST, CHECK)
- `Optimization` : Workflow d'optimisation (REVIEW, OPTI, TEST, CHECK)
- `Debugging` : Workflow de débogage (DEBUG, TEST, CHECK)
- `Architecture` : Workflow d'architecture (ARCHI, C-BREAK, REVIEW)
- `Analysis` : Workflow d'analyse (CHECK, PREDIC, REVIEW)
- `RoadmapManagement` : Workflow de gestion de roadmap (ROADMAP-SYNC, ROADMAP-REPORT, ROADMAP-PLAN)

### Exemples d'utilisation des workflows

```powershell
# Exécuter le workflow de développement
.\development\scripts\integrated-manager.ps1 -Workflow "Development" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Exécuter le workflow de gestion de roadmap
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
```

### Création de workflows personnalisés

Vous pouvez créer des workflows personnalisés en ajoutant une section dans le fichier de configuration :

```json
"Workflows": {
  "MyCustomWorkflow": {
    "Description": "Mon workflow personnalisé",
    "Modes": ["CHECK", "GRAN", "ROADMAP-SYNC"],
    "AutoContinue": true,
    "StopOnError": true
  }
}
```

## Automatisation

Le gestionnaire intégré peut être automatisé à l'aide de scripts PowerShell et de tâches planifiées.

### Scripts d'automatisation

Les scripts d'automatisation suivants sont disponibles :

- `workflow-quotidien.ps1` : Exécute les tâches quotidiennes de gestion de roadmap
- `workflow-hebdomadaire.ps1` : Exécute les tâches hebdomadaires de gestion de roadmap
- `workflow-mensuel.ps1` : Exécute les tâches mensuelles de gestion de roadmap

### Installation des tâches planifiées

Pour installer les tâches planifiées qui exécuteront automatiquement les workflows, utilisez le script `install-scheduled-tasks.ps1` :

```powershell
# Installer les tâches planifiées avec les paramètres par défaut
.\development\scripts\workflows\install-scheduled-tasks.ps1

# Installer les tâches planifiées avec un préfixe personnalisé
.\development\scripts\workflows\install-scheduled-tasks.ps1 -TaskPrefix "MonProjet"

# Remplacer les tâches existantes
.\development\scripts\workflows\install-scheduled-tasks.ps1 -Force
```

### Tâches planifiées

Les tâches planifiées suivantes sont installées :

- `RoadmapManager-Quotidien` : Exécute le workflow quotidien tous les jours à 9h00
- `RoadmapManager-Hebdomadaire` : Exécute le workflow hebdomadaire tous les vendredis à 16h00
- `RoadmapManager-Mensuel` : Exécute le workflow mensuel le premier jour de chaque mois à 10h00

## Intégration avec d'autres outils

Le gestionnaire intégré peut être intégré avec d'autres outils.

### Git

Vous pouvez intégrer le gestionnaire intégré avec Git en ajoutant des commandes Git dans les scripts d'automatisation :

```powershell
# Ajouter à la fin du workflow quotidien
git add "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
git add "projet\roadmaps\Roadmap\roadmap_complete.json"
git commit -m "Mise à jour quotidienne de la roadmap - $(Get-Date -Format 'yyyy-MM-dd')"
git push
```

### n8n

Vous pouvez créer un workflow n8n qui exécute les scripts PowerShell et traite les résultats :

```javascript
// Exemple de nœud Execute Command dans n8n
{
  "parameters": {
    "command": "powershell.exe",
    "arguments": "-NoProfile -ExecutionPolicy Bypass -File D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\development\\scripts\\workflows\\workflow-quotidien.ps1",
    "executeOnce": true
  }
}
```

### Notification par e-mail

Vous pouvez ajouter des notifications par e-mail dans les scripts d'automatisation :

```powershell
# Ajouter à la fin du workflow hebdomadaire
$emailParams = @{
    From = "roadmap@example.com"
    To = "equipe@example.com"
    Subject = "Rapport hebdomadaire de roadmap - $(Get-Date -Format 'yyyy-MM-dd')"
    Body = "Le rapport hebdomadaire de roadmap est disponible à l'adresse suivante : $reportPath"
    SmtpServer = "smtp.example.com"
}
Send-MailMessage @emailParams
```

## Résolution des problèmes

### Problèmes courants

#### Le gestionnaire intégré ne trouve pas le module RoadmapParser

**Symptôme** : Le gestionnaire intégré affiche une erreur indiquant que le module RoadmapParser est introuvable.

**Solution** : Vérifiez que le module RoadmapParser est installé et que le chemin du module est correct dans le fichier de configuration.

```powershell
# Vérifier que le module RoadmapParser est installé
Get-Module -Name RoadmapParser -ListAvailable

# Importer le module RoadmapParser
Import-Module "development\roadmap\parser\module\RoadmapParser.psm1" -Force
```

#### Les modes ne s'exécutent pas correctement

**Symptôme** : Les modes ne s'exécutent pas correctement ou affichent des erreurs.

**Solution** : Vérifiez que les chemins des scripts des modes sont corrects dans le fichier de configuration et que les scripts existent.

```powershell
# Vérifier que les scripts des modes existent
Test-Path -Path "development\scripts\maintenance\modes\check.ps1"
Test-Path -Path "development\scripts\maintenance\modes\gran-mode.ps1"
Test-Path -Path "development\scripts\maintenance\modes\roadmap-sync-mode.ps1"
```

#### Les workflows ne s'exécutent pas correctement

**Symptôme** : Les workflows ne s'exécutent pas correctement ou affichent des erreurs.

**Solution** : Vérifiez que les modes spécifiés dans les workflows existent et sont correctement configurés.

```powershell
# Vérifier que les modes spécifiés dans les workflows existent
.\development\scripts\integrated-manager.ps1 -ListModes
```

#### Les tâches planifiées ne s'exécutent pas

**Symptôme** : Les tâches planifiées sont installées mais ne s'exécutent pas.

**Solution** : Vérifiez que le service de planification des tâches est en cours d'exécution et que l'utilisateur qui exécute les tâches a les droits nécessaires.

```powershell
# Vérifier l'état du service de planification des tâches
Get-Service -Name "Schedule"

# Vérifier les tâches planifiées
Get-ScheduledTask -TaskName "RoadmapManager-*"

# Vérifier l'historique d'exécution des tâches
Get-ScheduledTaskInfo -TaskName "RoadmapManager-Quotidien"
```

### Journalisation

Tous les modes et workflows génèrent des journaux détaillés qui peuvent être utilisés pour diagnostiquer les problèmes.

Les journaux sont stockés dans le répertoire spécifié dans le fichier de configuration (`LogPath`) et sont nommés selon le format suivant :

- `workflow-quotidien-YYYY-MM-DD.log` pour le workflow quotidien
- `workflow-hebdomadaire-YYYY-MM-DD.log` pour le workflow hebdomadaire
- `workflow-mensuel-YYYY-MM.log` pour le workflow mensuel

```powershell
# Afficher les journaux
Get-Content -Path "projet\roadmaps\Logs\workflow-quotidien-$(Get-Date -Format 'yyyy-MM-dd').log"
```

## Ressources supplémentaires

### Documentation

- [Documentation du gestionnaire intégré](../methodologies/integrated_manager.md)
- [Exemples d'utilisation des modes de roadmap](../examples/roadmap-modes-examples.md)
- [Bonnes pratiques pour la gestion des roadmaps](../best-practices/roadmap-management.md)
- [Workflows automatisés](../automation/roadmap-workflows.md)

### Scripts

- [Gestionnaire intégré](../../../scripts/integrated-manager.ps1)
- [Mode CHECK adapté](../../../scripts/maintenance/modes/check.ps1)
- [Mode GRAN adapté](../../../scripts/maintenance/modes/gran-mode.ps1)
- [Mode ROADMAP-SYNC](../../../scripts/maintenance/modes/roadmap-sync-mode.ps1)
- [Mode ROADMAP-REPORT](../../../scripts/maintenance/modes/roadmap-report-mode.ps1)
- [Mode ROADMAP-PLAN](../../../scripts/maintenance/modes/roadmap-plan-mode.ps1)
- [Workflow quotidien](../../../scripts/workflows/workflow-quotidien.ps1)
- [Workflow hebdomadaire](../../../scripts/workflows/workflow-hebdomadaire.ps1)
- [Workflow mensuel](../../../scripts/workflows/workflow-mensuel.ps1)
- [Installation des tâches planifiées](../../../scripts/workflows/install-scheduled-tasks.ps1)

### Tests

- [Tests du gestionnaire intégré](../../../scripts/manager/tests/Test-IntegratedManager.ps1)
- [Tests des modes adaptés](../../../scripts/manager/tests/Test-IntegratedManagerModes.ps1)
- [Tests des modes de roadmap](../../../scripts/manager/tests/Test-RoadmapModes.ps1)
- [Tests d'intégration complète](../../../scripts/manager/tests/Test-CompleteIntegration.ps1)
