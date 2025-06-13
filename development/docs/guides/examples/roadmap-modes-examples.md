# Exemples d'utilisation des modes de gestion de roadmap

Ce document présente des exemples d'utilisation des modes de gestion de roadmap (ROADMAP-SYNC, ROADMAP-REPORT, ROADMAP-PLAN) via le gestionnaire intégré.

## Mode ROADMAP-SYNC

Le mode ROADMAP-SYNC permet de synchroniser les roadmaps entre différents formats (Markdown, JSON, HTML, CSV).

### Exemple 1: Convertir une roadmap Markdown en JSON

```powershell
# Convertir une roadmap Markdown en JSON

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"
```plaintext
### Exemple 2: Convertir une roadmap Markdown en HTML avec des graphiques

```powershell
# Convertir une roadmap Markdown en HTML

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "HTML"
```plaintext
### Exemple 3: Synchroniser plusieurs roadmaps en une seule opération

```powershell
# Synchroniser plusieurs roadmaps en une seule opération

$sourcePaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath $sourcePaths -MultiSync -TargetFormat "JSON"
```plaintext
### Exemple 4: Synchroniser plusieurs roadmaps vers des cibles spécifiques

```powershell
# Synchroniser plusieurs roadmaps vers des cibles spécifiques

$sourcePaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete_converted.md",
    "projet\roadmaps\mes-plans\roadmap_perso.md"
)

$targetPaths = @(
    "projet\roadmaps\Roadmap\roadmap_complete.json",
    "projet\roadmaps\mes-plans\roadmap_perso.json"
)

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath $sourcePaths -TargetPath $targetPaths -MultiSync
```plaintext
## Mode ROADMAP-REPORT

Le mode ROADMAP-REPORT génère des rapports détaillés sur l'état d'avancement des roadmaps.

### Exemple 1: Générer un rapport HTML

```powershell
# Générer un rapport HTML

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML"
```plaintext
### Exemple 2: Générer des rapports dans tous les formats

```powershell
# Générer des rapports dans tous les formats

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "All"
```plaintext
### Exemple 3: Générer un rapport sans graphiques ni prévisions

```powershell
# Générer un rapport sans graphiques ni prévisions

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML" -IncludeCharts:$false -IncludePredictions:$false
```plaintext
### Exemple 4: Générer un rapport avec une période d'analyse personnalisée

```powershell
# Générer un rapport avec une période d'analyse personnalisée

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML" -DaysToAnalyze 60
```plaintext
## Mode ROADMAP-PLAN

Le mode ROADMAP-PLAN planifie les tâches futures en fonction de l'état actuel de la roadmap.

### Exemple 1: Générer un plan d'action

```powershell
# Générer un plan d'action

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
```plaintext
### Exemple 2: Générer un plan d'action avec une période de prévision personnalisée

```powershell
# Générer un plan d'action avec une période de prévision personnalisée

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -DaysToForecast 60
```plaintext
### Exemple 3: Générer un plan d'action dans un fichier spécifique

```powershell
# Générer un plan d'action dans un fichier spécifique

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -OutputPath "projet\roadmaps\Plans\plan_action_q3_2023.md"
```plaintext
## Workflow de gestion de roadmap

Le gestionnaire intégré propose également un workflow de gestion de roadmap qui exécute les trois modes en séquence.

### Exemple 1: Exécuter le workflow de gestion de roadmap

```powershell
# Exécuter le workflow de gestion de roadmap

.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
```plaintext
### Exemple 2: Exécuter le workflow avec des paramètres personnalisés

```powershell
# Exécuter le workflow avec des paramètres personnalisés

.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML" -TargetFormat "JSON" -DaysToForecast 60
```plaintext
## Utilisation avec la configuration unifiée

Tous les exemples ci-dessus peuvent être simplifiés en utilisant la configuration unifiée. Il suffit de définir les valeurs par défaut dans le fichier de configuration et d'omettre les paramètres correspondants.

### Exemple: Configuration unifiée

```json
{
  "Modes": {
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
    "RoadmapManagement": {
      "Description": "Workflow de gestion de roadmap",
      "Modes": ["ROADMAP-SYNC", "ROADMAP-REPORT", "ROADMAP-PLAN"],
      "AutoContinue": true,
      "StopOnError": true
    }
  }
}
```plaintext
### Exemple: Utilisation simplifiée

```powershell
# Exécuter le mode ROADMAP-SYNC avec les valeurs par défaut

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC

# Exécuter le mode ROADMAP-REPORT avec les valeurs par défaut

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT

# Exécuter le mode ROADMAP-PLAN avec les valeurs par défaut

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN

# Exécuter le workflow de gestion de roadmap avec les valeurs par défaut

.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement"
```plaintext
## Bonnes pratiques

1. **Utilisez la configuration unifiée** pour définir les valeurs par défaut et simplifier les commandes.
2. **Synchronisez régulièrement** vos roadmaps pour maintenir la cohérence entre les différents formats.
3. **Générez des rapports périodiques** pour suivre l'avancement des projets.
4. **Planifiez à l'avance** en utilisant le mode ROADMAP-PLAN pour anticiper les tâches futures.
5. **Automatisez les workflows** en utilisant des scripts PowerShell ou des tâches planifiées.

## Dépannage

### Problème: Le mode ROADMAP-SYNC échoue avec une erreur de conversion

Vérifiez que le format source est correctement spécifié et que le fichier source existe. Si le problème persiste, essayez de convertir manuellement le fichier en utilisant les fonctions du module RoadmapParser.

```powershell
# Importer le module RoadmapParser

Import-Module "development\roadmap\parser\module\RoadmapParser.psm1"

# Convertir manuellement

ConvertFrom-MarkdownToJson -MarkdownPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -JsonPath "projet\roadmaps\Roadmap\roadmap_complete.json"
```plaintext
### Problème: Le mode ROADMAP-REPORT ne génère pas de graphiques

Vérifiez que le paramètre IncludeCharts est défini à $true et que le module Chart.js est disponible. Si le problème persiste, essayez de générer un rapport sans graphiques.

```powershell
# Générer un rapport sans graphiques

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML" -IncludeCharts:$false
```plaintext
### Problème: Le mode ROADMAP-PLAN génère un plan vide

Vérifiez que la roadmap contient des tâches non complétées. Si le problème persiste, essayez de générer un plan avec une période de prévision plus longue.

```powershell
# Générer un plan avec une période de prévision plus longue

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -DaysToForecast 90
```plaintext