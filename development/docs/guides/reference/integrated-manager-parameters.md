# RÃ©fÃ©rence des paramÃ¨tres du gestionnaire intÃ©grÃ©

Ce document prÃ©sente une rÃ©fÃ©rence complÃ¨te des paramÃ¨tres du gestionnaire intÃ©grÃ© et des modes associÃ©s.

## Table des matiÃ¨res

1. [Gestionnaire intÃ©grÃ©](#gestionnaire-intÃ©grÃ©)

2. [Mode CHECK](#mode-check)

3. [Mode GRAN](#mode-gran)

4. [Mode ROADMAP-SYNC](#mode-roadmap-sync)

5. [Mode ROADMAP-REPORT](#mode-roadmap-report)

6. [Mode ROADMAP-PLAN](#mode-roadmap-plan)

7. [Workflow quotidien](#workflow-quotidien)

8. [Workflow hebdomadaire](#workflow-hebdomadaire)

9. [Workflow mensuel](#workflow-mensuel)

10. [Installation des tÃ¢ches planifiÃ©es](#installation-des-tÃ¢ches-planifiÃ©es)

## Gestionnaire intÃ©grÃ©

Script : `development\scripts\integrated-manager.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| Mode | Le mode Ã  exÃ©cuter (ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, ROADMAP-PLAN, ROADMAP-REPORT, ROADMAP-SYNC, TEST) | Non | - |
| Workflow | Le workflow Ã  exÃ©cuter | Non | - |
| RoadmapPath | Chemin vers le fichier de roadmap | Non | Valeur de la configuration |
| TaskIdentifier | Identifiant de la tÃ¢che Ã  traiter | Non | - |
| OutputPath | Chemin vers le rÃ©pertoire de sortie | Non | Valeur de la configuration |
| ReportFormat | Format des rapports Ã  gÃ©nÃ©rer (HTML, JSON, CSV, Markdown, All) | Non | HTML |
| TargetFormat | Format cible pour la synchronisation (Markdown, JSON, HTML, CSV) | Non | JSON |
| DaysToForecast | Nombre de jours Ã  prÃ©voir dans le plan | Non | 30 |
| Force | Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation | Non | $false |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| ListModes | Affiche la liste des modes disponibles | Non | $false |
| ListWorkflows | Affiche la liste des workflows disponibles | Non | $false |
| WhatIf | Indique ce qui se passerait si la commande s'exÃ©cutait | Non | $false |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# ExÃ©cuter le mode CHECK

.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# ExÃ©cuter le workflow RoadmapManagement

.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

# Afficher la liste des modes disponibles

.\development\scripts\integrated-manager.ps1 -ListModes

# Afficher la liste des workflows disponibles

.\development\scripts\integrated-manager.ps1 -ListWorkflows
```plaintext
## Mode CHECK

Script : `development\scripts\maintenance\modes\check.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| FilePath | Chemin vers le fichier de roadmap Ã  vÃ©rifier | Non | Valeur de la configuration |
| TaskIdentifier | Identifiant de la tÃ¢che Ã  vÃ©rifier | Non | - |
| ImplementationPath | Chemin vers le rÃ©pertoire d'implÃ©mentation | Non | - |
| TestsPath | Chemin vers le rÃ©pertoire de tests | Non | - |
| UpdateRoadmap | Indique si la roadmap doit Ãªtre mise Ã  jour | Non | $true |
| GenerateReport | Indique si un rapport doit Ãªtre gÃ©nÃ©rÃ© | Non | $true |
| ReportPath | Chemin vers le rÃ©pertoire de sortie pour les rapports | Non | Valeur de la configuration |
| Force | Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation | Non | $false |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exÃ©cutait | Non | $false |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# VÃ©rifier l'Ã©tat d'avancement d'une tÃ¢che

.\development\scripts\maintenance\modes\check.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# VÃ©rifier l'Ã©tat d'avancement d'une tÃ¢che et mettre Ã  jour la roadmap

.\development\scripts\maintenance\modes\check.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -UpdateRoadmap

# VÃ©rifier l'Ã©tat d'avancement d'une tÃ¢che et gÃ©nÃ©rer un rapport

.\development\scripts\maintenance\modes\check.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -GenerateReport -ReportPath "projet\roadmaps\Reports"
```plaintext
## Mode GRAN

Script : `development\scripts\maintenance\modes\gran-mode.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| FilePath | Chemin vers le fichier de roadmap Ã  modifier | Non | Valeur de la configuration |
| TaskIdentifier | Identifiant de la tÃ¢che Ã  dÃ©composer | Non | - |
| SubTasksFile | Chemin vers un fichier contenant les sous-tÃ¢ches Ã  crÃ©er | Non | - |
| IndentationStyle | Style d'indentation Ã  utiliser (Spaces2, Spaces4, Tab, Auto) | Non | Auto |
| CheckboxStyle | Style de case Ã  cocher Ã  utiliser (GitHub, Custom, Auto) | Non | Auto |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exÃ©cutait | Non | $false |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# DÃ©composer une tÃ¢che en sous-tÃ¢ches

.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# DÃ©composer une tÃ¢che en sous-tÃ¢ches avec un fichier de sous-tÃ¢ches

.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"

# DÃ©composer une tÃ¢che en sous-tÃ¢ches avec un style d'indentation personnalisÃ©

.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -IndentationStyle "Spaces4"
```plaintext
## Mode ROADMAP-SYNC

Script : `development\scripts\maintenance\modes\roadmap-sync-mode.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| SourcePath | Chemin vers le fichier de roadmap source (peut Ãªtre un tableau) | Non | Valeur de la configuration |
| TargetPath | Chemin vers le fichier de roadmap cible (peut Ãªtre un tableau) | Non | GÃ©nÃ©rÃ© automatiquement |
| SourceFormat | Format du fichier source (Markdown, JSON, HTML, CSV) | Non | Markdown |
| TargetFormat | Format du fichier cible (Markdown, JSON, HTML, CSV) | Non | JSON |
| Force | Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation | Non | $false |
| MultiSync | Indique si plusieurs roadmaps doivent Ãªtre synchronisÃ©es en une seule opÃ©ration | Non | $false |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exÃ©cutait | Non | $false |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# Synchroniser une roadmap Markdown vers JSON

.\development\scripts\maintenance\modes\roadmap-sync-mode.ps1 -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"

# Synchroniser une roadmap Markdown vers HTML

.\development\scripts\maintenance\modes\roadmap-sync-mode.ps1 -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "HTML"

# Synchroniser plusieurs roadmaps en une seule opÃ©ration

$sourcePaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\maintenance\modes\roadmap-sync-mode.ps1 -SourcePath $sourcePaths -MultiSync -TargetFormat "JSON"
```plaintext
## Mode ROADMAP-REPORT

Script : `development\scripts\maintenance\modes\roadmap-report-mode.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| RoadmapPath | Chemin vers le fichier de roadmap Ã  analyser | Non | Valeur de la configuration |
| OutputPath | Chemin vers le rÃ©pertoire de sortie pour les rapports | Non | Valeur de la configuration |
| ReportFormat | Format des rapports Ã  gÃ©nÃ©rer (HTML, JSON, CSV, Markdown, All) | Non | HTML |
| IncludeCharts | Indique si les rapports doivent inclure des graphiques | Non | $true |
| IncludeTrends | Indique si les rapports doivent inclure des analyses de tendances | Non | $true |
| IncludePredictions | Indique si les rapports doivent inclure des prÃ©visions | Non | $true |
| DaysToAnalyze | Nombre de jours Ã  analyser pour les tendances et les prÃ©visions | Non | 30 |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exÃ©cutait | Non | $false |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# GÃ©nÃ©rer un rapport HTML

.\development\scripts\maintenance\modes\roadmap-report-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"

# GÃ©nÃ©rer des rapports dans tous les formats

.\development\scripts\maintenance\modes\roadmap-report-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "All"

# GÃ©nÃ©rer un rapport sans graphiques ni prÃ©visions

.\development\scripts\maintenance\modes\roadmap-report-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML" -IncludeCharts:$false -IncludePredictions:$false
```plaintext
## Mode ROADMAP-PLAN

Script : `development\scripts\maintenance\modes\roadmap-plan-mode.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| RoadmapPath | Chemin vers le fichier de roadmap Ã  analyser | Non | Valeur de la configuration |
| OutputPath | Chemin vers le fichier de sortie pour le plan | Non | GÃ©nÃ©rÃ© automatiquement |
| DaysToForecast | Nombre de jours Ã  prÃ©voir dans le plan | Non | 30 |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exÃ©cutait | Non | $false |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# GÃ©nÃ©rer un plan d'action

.\development\scripts\maintenance\modes\roadmap-plan-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

# GÃ©nÃ©rer un plan d'action avec une pÃ©riode de prÃ©vision personnalisÃ©e

.\development\scripts\maintenance\modes\roadmap-plan-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -DaysToForecast 60

# GÃ©nÃ©rer un plan d'action dans un fichier spÃ©cifique

.\development\scripts\maintenance\modes\roadmap-plan-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -OutputPath "projet\roadmaps\Plans\plan_action_q3_2023.md"
```plaintext
## Workflow quotidien

Script : `development\scripts\workflows\workflow-quotidien.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| RoadmapPath | Chemin vers le fichier de roadmap principal | Non | projet\roadmaps\Roadmap\roadmap_complete_converted.md |
| LogPath | Chemin vers le rÃ©pertoire de journalisation | Non | projet\roadmaps\Logs |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# ExÃ©cuter le workflow quotidien

.\development\scripts\workflows\workflow-quotidien.ps1

# ExÃ©cuter le workflow quotidien avec un chemin de roadmap personnalisÃ©

.\development\scripts\workflows\workflow-quotidien.ps1 -RoadmapPath "projet\roadmaps\mes-plans\roadmap_perso.md"

# ExÃ©cuter le workflow quotidien avec un rÃ©pertoire de journalisation personnalisÃ©

.\development\scripts\workflows\workflow-quotidien.ps1 -LogPath "projet\roadmaps\Logs\quotidien"
```plaintext
## Workflow hebdomadaire

Script : `development\scripts\workflows\workflow-hebdomadaire.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| RoadmapPaths | Tableau des chemins vers les fichiers de roadmap Ã  traiter | Non | @("projet\roadmaps\Roadmap\roadmap_complete_converted.md") |
| OutputPath | Chemin vers le rÃ©pertoire de sortie pour les rapports et les plans | Non | projet\roadmaps |
| LogPath | Chemin vers le rÃ©pertoire de journalisation | Non | projet\roadmaps\Logs |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# ExÃ©cuter le workflow hebdomadaire

.\development\scripts\workflows\workflow-hebdomadaire.ps1

# ExÃ©cuter le workflow hebdomadaire avec plusieurs chemins de roadmap

$roadmapPaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\workflows\workflow-hebdomadaire.ps1 -RoadmapPaths $roadmapPaths

# ExÃ©cuter le workflow hebdomadaire avec un rÃ©pertoire de sortie personnalisÃ©

.\development\scripts\workflows\workflow-hebdomadaire.ps1 -OutputPath "projet\roadmaps\output"
```plaintext
## Workflow mensuel

Script : `development\scripts\workflows\workflow-mensuel.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| RoadmapPaths | Tableau des chemins vers les fichiers de roadmap Ã  traiter | Non | @("projet\roadmaps\Roadmap\roadmap_complete_converted.md") |
| OutputPath | Chemin vers le rÃ©pertoire de sortie pour les rapports et les plans | Non | projet\roadmaps |
| LogPath | Chemin vers le rÃ©pertoire de journalisation | Non | projet\roadmaps\Logs |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# ExÃ©cuter le workflow mensuel

.\development\scripts\workflows\workflow-mensuel.ps1

# ExÃ©cuter le workflow mensuel avec plusieurs chemins de roadmap

$roadmapPaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\workflows\workflow-mensuel.ps1 -RoadmapPaths $roadmapPaths

# ExÃ©cuter le workflow mensuel avec un rÃ©pertoire de sortie personnalisÃ©

.\development\scripts\workflows\workflow-mensuel.ps1 -OutputPath "projet\roadmaps\output"
```plaintext
## Installation des tÃ¢ches planifiÃ©es

Script : `development\scripts\workflows\install-scheduled-tasks.ps1`

### ParamÃ¨tres

| ParamÃ¨tre | Description | Obligatoire | Valeur par dÃ©faut |
|-----------|-------------|-------------|-------------------|
| ProjectRoot | Chemin vers la racine du projet | Non | Le rÃ©pertoire parent du rÃ©pertoire du script |
| TaskPrefix | PrÃ©fixe pour les noms des tÃ¢ches planifiÃ©es | Non | roadmap-manager |
| Force | Indique si les tÃ¢ches existantes doivent Ãªtre remplacÃ©es | Non | $false |
| WhatIf | Indique ce qui se passerait si la commande s'exÃ©cutait | Non | $false |
| Verbose | Affiche des informations dÃ©taillÃ©es sur l'exÃ©cution | Non | $false |

### Exemples

```powershell
# Installer les tÃ¢ches planifiÃ©es

.\development\scripts\workflows\install-scheduled-tasks.ps1

# Installer les tÃ¢ches planifiÃ©es avec un prÃ©fixe personnalisÃ©

.\development\scripts\workflows\install-scheduled-tasks.ps1 -TaskPrefix "MonProjet"

# Remplacer les tÃ¢ches existantes

.\development\scripts\workflows\install-scheduled-tasks.ps1 -Force

# Voir ce que l'installation ferait sans l'exÃ©cuter rÃ©ellement

.\development\scripts\workflows\install-scheduled-tasks.ps1 -WhatIf
```plaintext