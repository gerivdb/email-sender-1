# Guide d'utilisation du gestionnaire intÃ©grÃ©

Ce guide prÃ©sente l'utilisation du gestionnaire intÃ©grÃ©, qui unifie les fonctionnalitÃ©s du Mode Manager et du Roadmap Manager pour offrir une interface unique pour la gestion des modes opÃ©rationnels et des roadmaps.

## Table des matiÃ¨res

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Utilisation des modes](#utilisation-des-modes)
5. [Utilisation des workflows](#utilisation-des-workflows)
6. [Automatisation](#automatisation)
7. [IntÃ©gration avec d'autres outils](#intÃ©gration-avec-dautres-outils)
8. [RÃ©solution des problÃ¨mes](#rÃ©solution-des-problÃ¨mes)
9. [Ressources supplÃ©mentaires](#ressources-supplÃ©mentaires)

## Introduction

Le gestionnaire intÃ©grÃ© est un outil qui unifie les fonctionnalitÃ©s du Mode Manager et du Roadmap Manager. Il permet de :

- ExÃ©cuter les modes opÃ©rationnels (CHECK, GRAN, etc.)
- GÃ©rer les roadmaps (synchronisation, rapports, planification)
- ExÃ©cuter des workflows prÃ©dÃ©finis
- Automatiser les tÃ¢ches rÃ©currentes

## Installation

### PrÃ©requis

- PowerShell 5.1 ou supÃ©rieur
- Module RoadmapParser installÃ©

### VÃ©rification de l'installation

Pour vÃ©rifier que le gestionnaire intÃ©grÃ© est correctement installÃ©, exÃ©cutez la commande suivante :

```powershell
.\development\scripts\integrated-manager.ps1 -ListModes
```

Cette commande devrait afficher la liste des modes disponibles.

## Configuration

Le gestionnaire intÃ©grÃ© utilise un fichier de configuration unifiÃ© pour stocker les paramÃ¨tres des diffÃ©rents modes et workflows.

### Fichier de configuration

Le fichier de configuration par dÃ©faut se trouve Ã  l'emplacement suivant :

```
development\config\unified-config.json
```

### Structure du fichier de configuration

Le fichier de configuration est au format JSON et contient les sections suivantes :

- `General` : ParamÃ¨tres gÃ©nÃ©raux
- `Modes` : Configuration des modes opÃ©rationnels
- `Roadmaps` : Configuration des roadmaps
- `Workflows` : Configuration des workflows
- `Integration` : ParamÃ¨tres d'intÃ©gration

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
      "Description": "Workflow de dÃ©veloppement complet",
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

Vous pouvez personnaliser la configuration en modifiant le fichier `unified-config.json` ou en spÃ©cifiant un fichier de configuration personnalisÃ© avec le paramÃ¨tre `-ConfigPath` :

```powershell
.\development\scripts\integrated-manager.ps1 -Mode CHECK -ConfigPath "my-config.json"
```

## Utilisation des modes

Le gestionnaire intÃ©grÃ© prend en charge les modes opÃ©rationnels suivants :

### Modes opÃ©rationnels

- `CHECK` : VÃ©rifie l'Ã©tat d'avancement des tÃ¢ches
- `GRAN` : DÃ©compose les tÃ¢ches en sous-tÃ¢ches plus granulaires
- `DEV-R` : ImplÃ©mente les tÃ¢ches de la roadmap
- `TEST` : ExÃ©cute les tests
- `DEBUG` : Aide au dÃ©bogage
- `REVIEW` : Revoit le code
- `ARCHI` : Analyse l'architecture
- `C-BREAK` : DÃ©tecte et corrige les dÃ©pendances circulaires
- `OPTI` : Optimise le code
- `PREDIC` : PrÃ©dit les performances et dÃ©tecte les anomalies

### Modes de gestion de roadmap

- `ROADMAP-SYNC` : Synchronise les roadmaps entre diffÃ©rents formats
- `ROADMAP-REPORT` : GÃ©nÃ¨re des rapports sur l'Ã©tat des roadmaps
- `ROADMAP-PLAN` : Planifie les tÃ¢ches futures

### Exemples d'utilisation des modes

#### Mode CHECK

```powershell
# VÃ©rifier l'Ã©tat d'avancement d'une tÃ¢che
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# VÃ©rifier l'Ã©tat d'avancement d'une tÃ¢che et mettre Ã  jour la roadmap
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -UpdateRoadmap
```

#### Mode GRAN

```powershell
# DÃ©composer une tÃ¢che en sous-tÃ¢ches
.\development\scripts\integrated-manager.ps1 -Mode GRAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# DÃ©composer une tÃ¢che en sous-tÃ¢ches avec un fichier de sous-tÃ¢ches
.\development\scripts\integrated-manager.ps1 -Mode GRAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"
```

#### Mode ROADMAP-SYNC

```powershell
# Synchroniser une roadmap Markdown vers JSON
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"

# Synchroniser plusieurs roadmaps en une seule opÃ©ration
$sourcePaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath $sourcePaths -MultiSync -TargetFormat "JSON"
```

#### Mode ROADMAP-REPORT

```powershell
# GÃ©nÃ©rer un rapport HTML
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"

# GÃ©nÃ©rer des rapports dans tous les formats
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "All"
```

#### Mode ROADMAP-PLAN

```powershell
# GÃ©nÃ©rer un plan d'action
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

# GÃ©nÃ©rer un plan d'action avec une pÃ©riode de prÃ©vision personnalisÃ©e
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -DaysToForecast 60
```

## Utilisation des workflows

Les workflows permettent d'exÃ©cuter plusieurs modes en sÃ©quence.

### Workflows prÃ©dÃ©finis

- `Development` : Workflow de dÃ©veloppement complet (GRAN, DEV-R, TEST, CHECK)
- `Optimization` : Workflow d'optimisation (REVIEW, OPTI, TEST, CHECK)
- `Debugging` : Workflow de dÃ©bogage (DEBUG, TEST, CHECK)
- `Architecture` : Workflow d'architecture (ARCHI, C-BREAK, REVIEW)
- `Analysis` : Workflow d'analyse (CHECK, PREDIC, REVIEW)
- `RoadmapManagement` : Workflow de gestion de roadmap (ROADMAP-SYNC, ROADMAP-REPORT, ROADMAP-PLAN)

### Exemples d'utilisation des workflows

```powershell
# ExÃ©cuter le workflow de dÃ©veloppement
.\development\scripts\integrated-manager.ps1 -Workflow "Development" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# ExÃ©cuter le workflow de gestion de roadmap
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
```

### CrÃ©ation de workflows personnalisÃ©s

Vous pouvez crÃ©er des workflows personnalisÃ©s en ajoutant une section dans le fichier de configuration :

```json
"Workflows": {
  "MyCustomWorkflow": {
    "Description": "Mon workflow personnalisÃ©",
    "Modes": ["CHECK", "GRAN", "ROADMAP-SYNC"],
    "AutoContinue": true,
    "StopOnError": true
  }
}
```

## Automatisation

Le gestionnaire intÃ©grÃ© peut Ãªtre automatisÃ© Ã  l'aide de scripts PowerShell et de tÃ¢ches planifiÃ©es.

### Scripts d'automatisation

Les scripts d'automatisation suivants sont disponibles :

- `workflow-quotidien.ps1` : ExÃ©cute les tÃ¢ches quotidiennes de gestion de roadmap
- `workflow-hebdomadaire.ps1` : ExÃ©cute les tÃ¢ches hebdomadaires de gestion de roadmap
- `workflow-mensuel.ps1` : ExÃ©cute les tÃ¢ches mensuelles de gestion de roadmap

### Installation des tÃ¢ches planifiÃ©es

Pour installer les tÃ¢ches planifiÃ©es qui exÃ©cuteront automatiquement les workflows, utilisez le script `install-scheduled-tasks.ps1` :

```powershell
# Installer les tÃ¢ches planifiÃ©es avec les paramÃ¨tres par dÃ©faut
.\development\scripts\workflows\install-scheduled-tasks.ps1

# Installer les tÃ¢ches planifiÃ©es avec un prÃ©fixe personnalisÃ©
.\development\scripts\workflows\install-scheduled-tasks.ps1 -TaskPrefix "MonProjet"

# Remplacer les tÃ¢ches existantes
.\development\scripts\workflows\install-scheduled-tasks.ps1 -Force
```

### TÃ¢ches planifiÃ©es

Les tÃ¢ches planifiÃ©es suivantes sont installÃ©es :

- `roadmap-manager-Quotidien` : ExÃ©cute le workflow quotidien tous les jours Ã  9h00
- `roadmap-manager-Hebdomadaire` : ExÃ©cute le workflow hebdomadaire tous les vendredis Ã  16h00
- `roadmap-manager-Mensuel` : ExÃ©cute le workflow mensuel le premier jour de chaque mois Ã  10h00

## IntÃ©gration avec d'autres outils

Le gestionnaire intÃ©grÃ© peut Ãªtre intÃ©grÃ© avec d'autres outils.

### Git

Vous pouvez intÃ©grer le gestionnaire intÃ©grÃ© avec Git en ajoutant des commandes Git dans les scripts d'automatisation :

```powershell
# Ajouter Ã  la fin du workflow quotidien
git add "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
git add "projet\roadmaps\Roadmap\roadmap_complete.json"
git commit -m "Mise Ã  jour quotidienne de la roadmap - $(Get-Date -Format 'yyyy-MM-dd')"
git push
```

### n8n

Vous pouvez crÃ©er un workflow n8n qui exÃ©cute les scripts PowerShell et traite les rÃ©sultats :

```javascript
// Exemple de nÅ“ud Execute Command dans n8n
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
# Ajouter Ã  la fin du workflow hebdomadaire
$emailParams = @{
    From = "roadmap@example.com"
    To = "equipe@example.com"
    Subject = "Rapport hebdomadaire de roadmap - $(Get-Date -Format 'yyyy-MM-dd')"
    Body = "Le rapport hebdomadaire de roadmap est disponible Ã  l'adresse suivante : $reportPath"
    SmtpServer = "smtp.example.com"
}
Send-MailMessage @emailParams
```

## RÃ©solution des problÃ¨mes

### ProblÃ¨mes courants

#### Le gestionnaire intÃ©grÃ© ne trouve pas le module RoadmapParser

**SymptÃ´me** : Le gestionnaire intÃ©grÃ© affiche une erreur indiquant que le module RoadmapParser est introuvable.

**Solution** : VÃ©rifiez que le module RoadmapParser est installÃ© et que le chemin du module est correct dans le fichier de configuration.

```powershell
# VÃ©rifier que le module RoadmapParser est installÃ©
Get-Module -Name RoadmapParser -ListAvailable

# Importer le module RoadmapParser
Import-Module "development\roadmap\parser\module\RoadmapParser.psm1" -Force
```

#### Les modes ne s'exÃ©cutent pas correctement

**SymptÃ´me** : Les modes ne s'exÃ©cutent pas correctement ou affichent des erreurs.

**Solution** : VÃ©rifiez que les chemins des scripts des modes sont corrects dans le fichier de configuration et que les scripts existent.

```powershell
# VÃ©rifier que les scripts des modes existent
Test-Path -Path "development\scripts\maintenance\modes\check.ps1"
Test-Path -Path "development\scripts\maintenance\modes\gran-mode.ps1"
Test-Path -Path "development\scripts\maintenance\modes\roadmap-sync-mode.ps1"
```

#### Les workflows ne s'exÃ©cutent pas correctement

**SymptÃ´me** : Les workflows ne s'exÃ©cutent pas correctement ou affichent des erreurs.

**Solution** : VÃ©rifiez que les modes spÃ©cifiÃ©s dans les workflows existent et sont correctement configurÃ©s.

```powershell
# VÃ©rifier que les modes spÃ©cifiÃ©s dans les workflows existent
.\development\scripts\integrated-manager.ps1 -ListModes
```

#### Les tÃ¢ches planifiÃ©es ne s'exÃ©cutent pas

**SymptÃ´me** : Les tÃ¢ches planifiÃ©es sont installÃ©es mais ne s'exÃ©cutent pas.

**Solution** : VÃ©rifiez que le service de planification des tÃ¢ches est en cours d'exÃ©cution et que l'utilisateur qui exÃ©cute les tÃ¢ches a les droits nÃ©cessaires.

```powershell
# VÃ©rifier l'Ã©tat du service de planification des tÃ¢ches
Get-Service -Name "Schedule"

# VÃ©rifier les tÃ¢ches planifiÃ©es
Get-ScheduledTask -TaskName "roadmap-manager-*"

# VÃ©rifier l'historique d'exÃ©cution des tÃ¢ches
Get-ScheduledTaskInfo -TaskName "roadmap-manager-Quotidien"
```

### Journalisation

Tous les modes et workflows gÃ©nÃ¨rent des journaux dÃ©taillÃ©s qui peuvent Ãªtre utilisÃ©s pour diagnostiquer les problÃ¨mes.

Les journaux sont stockÃ©s dans le rÃ©pertoire spÃ©cifiÃ© dans le fichier de configuration (`LogPath`) et sont nommÃ©s selon le format suivant :

- `workflow-quotidien-YYYY-MM-DD.log` pour le workflow quotidien
- `workflow-hebdomadaire-YYYY-MM-DD.log` pour le workflow hebdomadaire
- `workflow-mensuel-YYYY-MM.log` pour le workflow mensuel

```powershell
# Afficher les journaux
Get-Content -Path "projet\roadmaps\Logs\workflow-quotidien-$(Get-Date -Format 'yyyy-MM-dd').log"
```

## Ressources supplÃ©mentaires

### Documentation

- [Documentation du gestionnaire intÃ©grÃ©](../methodologies/integrated_manager.md)
- [Exemples d'utilisation des modes de roadmap](../examples/roadmap-modes-examples.md)
- [Bonnes pratiques pour la gestion des roadmaps](../best-practices/roadmap-management.md)
- [Workflows automatisÃ©s](../automation/roadmap-workflows.md)

### Scripts

- [Gestionnaire intÃ©grÃ©](../../../scripts/integrated-manager.ps1)
- [Mode CHECK adaptÃ©](../../../scripts/maintenance/modes/check.ps1)
- [Mode GRAN adaptÃ©](../../../scripts/maintenance/modes/gran-mode.ps1)
- [Mode ROADMAP-SYNC](../../../scripts/maintenance/modes/roadmap-sync-mode.ps1)
- [Mode ROADMAP-REPORT](../../../scripts/maintenance/modes/roadmap-report-mode.ps1)
- [Mode ROADMAP-PLAN](../../../scripts/maintenance/modes/roadmap-plan-mode.ps1)
- [Workflow quotidien](../../../scripts/workflows/workflow-quotidien.ps1)
- [Workflow hebdomadaire](../../../scripts/workflows/workflow-hebdomadaire.ps1)
- [Workflow mensuel](../../../scripts/workflows/workflow-mensuel.ps1)
- [Installation des tÃ¢ches planifiÃ©es](../../../scripts/workflows/install-scheduled-tasks.ps1)

### Tests

- [Tests du gestionnaire intÃ©grÃ©](../../../scripts/mode-manager/tests/Test-IntegratedManager.ps1)
- [Tests des modes adaptÃ©s](../../../scripts/mode-manager/tests/Test-IntegratedManagerModes.ps1)
- [Tests des modes de roadmap](../../../scripts/mode-manager/tests/Test-RoadmapModes.ps1)
- [Tests d'intÃ©gration complÃ¨te](../../../scripts/mode-manager/tests/Test-CompleteIntegration.ps1)


