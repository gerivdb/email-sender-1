# Référence des paramètres du gestionnaire intégré

Ce document présente une référence complète des paramètres du gestionnaire intégré et des modes associés.

## Table des matières

1. [Gestionnaire intégré](#gestionnaire-intégré)
2. [Mode CHECK](#mode-check)
3. [Mode GRAN](#mode-gran)
4. [Mode ROADMAP-SYNC](#mode-roadmap-sync)
5. [Mode ROADMAP-REPORT](#mode-roadmap-report)
6. [Mode ROADMAP-PLAN](#mode-roadmap-plan)
7. [Workflow quotidien](#workflow-quotidien)
8. [Workflow hebdomadaire](#workflow-hebdomadaire)
9. [Workflow mensuel](#workflow-mensuel)
10. [Installation des tâches planifiées](#installation-des-tâches-planifiées)

## Gestionnaire intégré

Script : `development\scripts\integrated-manager.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| Mode | Le mode à exécuter (ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, ROADMAP-PLAN, ROADMAP-REPORT, ROADMAP-SYNC, TEST) | Non | - |
| Workflow | Le workflow à exécuter | Non | - |
| RoadmapPath | Chemin vers le fichier de roadmap | Non | Valeur de la configuration |
| TaskIdentifier | Identifiant de la tâche à traiter | Non | - |
| OutputPath | Chemin vers le répertoire de sortie | Non | Valeur de la configuration |
| ReportFormat | Format des rapports à générer (HTML, JSON, CSV, Markdown, All) | Non | HTML |
| TargetFormat | Format cible pour la synchronisation (Markdown, JSON, HTML, CSV) | Non | JSON |
| DaysToForecast | Nombre de jours à prévoir dans le plan | Non | 30 |
| Force | Indique si les modifications doivent être appliquées sans confirmation | Non | $false |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| ListModes | Affiche la liste des modes disponibles | Non | $false |
| ListWorkflows | Affiche la liste des workflows disponibles | Non | $false |
| WhatIf | Indique ce qui se passerait si la commande s'exécutait | Non | $false |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Exécuter le mode CHECK
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Exécuter le workflow RoadmapManagement
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

# Afficher la liste des modes disponibles
.\development\scripts\integrated-manager.ps1 -ListModes

# Afficher la liste des workflows disponibles
.\development\scripts\integrated-manager.ps1 -ListWorkflows
```

## Mode CHECK

Script : `development\scripts\maintenance\modes\check.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| FilePath | Chemin vers le fichier de roadmap à vérifier | Non | Valeur de la configuration |
| TaskIdentifier | Identifiant de la tâche à vérifier | Non | - |
| ImplementationPath | Chemin vers le répertoire d'implémentation | Non | - |
| TestsPath | Chemin vers le répertoire de tests | Non | - |
| UpdateRoadmap | Indique si la roadmap doit être mise à jour | Non | $true |
| GenerateReport | Indique si un rapport doit être généré | Non | $true |
| ReportPath | Chemin vers le répertoire de sortie pour les rapports | Non | Valeur de la configuration |
| Force | Indique si les modifications doivent être appliquées sans confirmation | Non | $false |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exécutait | Non | $false |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Vérifier l'état d'avancement d'une tâche
.\development\scripts\maintenance\modes\check.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Vérifier l'état d'avancement d'une tâche et mettre à jour la roadmap
.\development\scripts\maintenance\modes\check.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -UpdateRoadmap

# Vérifier l'état d'avancement d'une tâche et générer un rapport
.\development\scripts\maintenance\modes\check.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -GenerateReport -ReportPath "projet\roadmaps\Reports"
```

## Mode GRAN

Script : `development\scripts\maintenance\modes\gran-mode.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| FilePath | Chemin vers le fichier de roadmap à modifier | Non | Valeur de la configuration |
| TaskIdentifier | Identifiant de la tâche à décomposer | Non | - |
| SubTasksFile | Chemin vers un fichier contenant les sous-tâches à créer | Non | - |
| IndentationStyle | Style d'indentation à utiliser (Spaces2, Spaces4, Tab, Auto) | Non | Auto |
| CheckboxStyle | Style de case à cocher à utiliser (GitHub, Custom, Auto) | Non | Auto |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exécutait | Non | $false |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Décomposer une tâche en sous-tâches
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3"

# Décomposer une tâche en sous-tâches avec un fichier de sous-tâches
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -SubTasksFile "templates\subtasks.txt"

# Décomposer une tâche en sous-tâches avec un style d'indentation personnalisé
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TaskIdentifier "1.2.3" -IndentationStyle "Spaces4"
```

## Mode ROADMAP-SYNC

Script : `development\scripts\maintenance\modes\roadmap-sync-mode.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| SourcePath | Chemin vers le fichier de roadmap source (peut être un tableau) | Non | Valeur de la configuration |
| TargetPath | Chemin vers le fichier de roadmap cible (peut être un tableau) | Non | Généré automatiquement |
| SourceFormat | Format du fichier source (Markdown, JSON, HTML, CSV) | Non | Markdown |
| TargetFormat | Format du fichier cible (Markdown, JSON, HTML, CSV) | Non | JSON |
| Force | Indique si les modifications doivent être appliquées sans confirmation | Non | $false |
| MultiSync | Indique si plusieurs roadmaps doivent être synchronisées en une seule opération | Non | $false |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exécutait | Non | $false |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Synchroniser une roadmap Markdown vers JSON
.\development\scripts\maintenance\modes\roadmap-sync-mode.ps1 -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"

# Synchroniser une roadmap Markdown vers HTML
.\development\scripts\maintenance\modes\roadmap-sync-mode.ps1 -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "HTML"

# Synchroniser plusieurs roadmaps en une seule opération
$sourcePaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\maintenance\modes\roadmap-sync-mode.ps1 -SourcePath $sourcePaths -MultiSync -TargetFormat "JSON"
```

## Mode ROADMAP-REPORT

Script : `development\scripts\maintenance\modes\roadmap-report-mode.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| RoadmapPath | Chemin vers le fichier de roadmap à analyser | Non | Valeur de la configuration |
| OutputPath | Chemin vers le répertoire de sortie pour les rapports | Non | Valeur de la configuration |
| ReportFormat | Format des rapports à générer (HTML, JSON, CSV, Markdown, All) | Non | HTML |
| IncludeCharts | Indique si les rapports doivent inclure des graphiques | Non | $true |
| IncludeTrends | Indique si les rapports doivent inclure des analyses de tendances | Non | $true |
| IncludePredictions | Indique si les rapports doivent inclure des prévisions | Non | $true |
| DaysToAnalyze | Nombre de jours à analyser pour les tendances et les prévisions | Non | 30 |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exécutait | Non | $false |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Générer un rapport HTML
.\development\scripts\maintenance\modes\roadmap-report-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"

# Générer des rapports dans tous les formats
.\development\scripts\maintenance\modes\roadmap-report-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "All"

# Générer un rapport sans graphiques ni prévisions
.\development\scripts\maintenance\modes\roadmap-report-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML" -IncludeCharts:$false -IncludePredictions:$false
```

## Mode ROADMAP-PLAN

Script : `development\scripts\maintenance\modes\roadmap-plan-mode.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| RoadmapPath | Chemin vers le fichier de roadmap à analyser | Non | Valeur de la configuration |
| OutputPath | Chemin vers le fichier de sortie pour le plan | Non | Généré automatiquement |
| DaysToForecast | Nombre de jours à prévoir dans le plan | Non | 30 |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| WhatIf | Indique ce qui se passerait si la commande s'exécutait | Non | $false |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Générer un plan d'action
.\development\scripts\maintenance\modes\roadmap-plan-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

# Générer un plan d'action avec une période de prévision personnalisée
.\development\scripts\maintenance\modes\roadmap-plan-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -DaysToForecast 60

# Générer un plan d'action dans un fichier spécifique
.\development\scripts\maintenance\modes\roadmap-plan-mode.ps1 -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -OutputPath "projet\roadmaps\Plans\plan_action_q3_2023.md"
```

## Workflow quotidien

Script : `development\scripts\workflows\workflow-quotidien.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| RoadmapPath | Chemin vers le fichier de roadmap principal | Non | projet\roadmaps\Roadmap\roadmap_complete_converted.md |
| LogPath | Chemin vers le répertoire de journalisation | Non | projet\roadmaps\Logs |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Exécuter le workflow quotidien
.\development\scripts\workflows\workflow-quotidien.ps1

# Exécuter le workflow quotidien avec un chemin de roadmap personnalisé
.\development\scripts\workflows\workflow-quotidien.ps1 -RoadmapPath "projet\roadmaps\mes-plans\roadmap_perso.md"

# Exécuter le workflow quotidien avec un répertoire de journalisation personnalisé
.\development\scripts\workflows\workflow-quotidien.ps1 -LogPath "projet\roadmaps\Logs\quotidien"
```

## Workflow hebdomadaire

Script : `development\scripts\workflows\workflow-hebdomadaire.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| RoadmapPaths | Tableau des chemins vers les fichiers de roadmap à traiter | Non | @("projet\roadmaps\Roadmap\roadmap_complete_converted.md") |
| OutputPath | Chemin vers le répertoire de sortie pour les rapports et les plans | Non | projet\roadmaps |
| LogPath | Chemin vers le répertoire de journalisation | Non | projet\roadmaps\Logs |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Exécuter le workflow hebdomadaire
.\development\scripts\workflows\workflow-hebdomadaire.ps1

# Exécuter le workflow hebdomadaire avec plusieurs chemins de roadmap
$roadmapPaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\workflows\workflow-hebdomadaire.ps1 -RoadmapPaths $roadmapPaths

# Exécuter le workflow hebdomadaire avec un répertoire de sortie personnalisé
.\development\scripts\workflows\workflow-hebdomadaire.ps1 -OutputPath "projet\roadmaps\output"
```

## Workflow mensuel

Script : `development\scripts\workflows\workflow-mensuel.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| RoadmapPaths | Tableau des chemins vers les fichiers de roadmap à traiter | Non | @("projet\roadmaps\Roadmap\roadmap_complete_converted.md") |
| OutputPath | Chemin vers le répertoire de sortie pour les rapports et les plans | Non | projet\roadmaps |
| LogPath | Chemin vers le répertoire de journalisation | Non | projet\roadmaps\Logs |
| ConfigPath | Chemin vers le fichier de configuration | Non | development\config\unified-config.json |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Exécuter le workflow mensuel
.\development\scripts\workflows\workflow-mensuel.ps1

# Exécuter le workflow mensuel avec plusieurs chemins de roadmap
$roadmapPaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)
.\development\scripts\workflows\workflow-mensuel.ps1 -RoadmapPaths $roadmapPaths

# Exécuter le workflow mensuel avec un répertoire de sortie personnalisé
.\development\scripts\workflows\workflow-mensuel.ps1 -OutputPath "projet\roadmaps\output"
```

## Installation des tâches planifiées

Script : `development\scripts\workflows\install-scheduled-tasks.ps1`

### Paramètres

| Paramètre | Description | Obligatoire | Valeur par défaut |
|-----------|-------------|-------------|-------------------|
| ProjectRoot | Chemin vers la racine du projet | Non | Le répertoire parent du répertoire du script |
| TaskPrefix | Préfixe pour les noms des tâches planifiées | Non | RoadmapManager |
| Force | Indique si les tâches existantes doivent être remplacées | Non | $false |
| WhatIf | Indique ce qui se passerait si la commande s'exécutait | Non | $false |
| Verbose | Affiche des informations détaillées sur l'exécution | Non | $false |

### Exemples

```powershell
# Installer les tâches planifiées
.\development\scripts\workflows\install-scheduled-tasks.ps1

# Installer les tâches planifiées avec un préfixe personnalisé
.\development\scripts\workflows\install-scheduled-tasks.ps1 -TaskPrefix "MonProjet"

# Remplacer les tâches existantes
.\development\scripts\workflows\install-scheduled-tasks.ps1 -Force

# Voir ce que l'installation ferait sans l'exécuter réellement
.\development\scripts\workflows\install-scheduled-tasks.ps1 -WhatIf
```
