# Bonnes pratiques pour la gestion des roadmaps

Ce document présente les bonnes pratiques pour la gestion des roadmaps dans le projet, en utilisant les modes de gestion de roadmap (ROADMAP-SYNC, ROADMAP-REPORT, ROADMAP-PLAN) via le gestionnaire intégré.

## Organisation des roadmaps

### Structure des répertoires

Les roadmaps doivent être organisées selon la structure suivante :

```
projet/
  roadmaps/
    Roadmap/
      roadmap_complete_converted.md  # Roadmap principale au format Markdown
      roadmap_complete.json          # Version JSON de la roadmap principale
    mes-plans/                       # Plans personnels
      roadmap_perso.md
    Reports/                         # Rapports générés
      roadmap-report.html
      roadmap-report.json
    Plans/                           # Plans d'action générés
      roadmap-plan.md
```

### Format des roadmaps

Les roadmaps doivent être au format Markdown avec la structure suivante :

```markdown
# Titre de la roadmap

## Tâche 1

### Description
Description de la tâche 1.

### Sous-tâches
- [ ] **1.1** Sous-tâche 1.1
- [ ] **1.2** Sous-tâche 1.2
- [x] **1.3** Sous-tâche 1.3 (complétée)

## Tâche 2

### Description
Description de la tâche 2.

### Sous-tâches
- [ ] **2.1** Sous-tâche 2.1
- [ ] **2.2** Sous-tâche 2.2
```

## Synchronisation des roadmaps

### Quand synchroniser

- Après chaque modification de la roadmap principale
- Avant de générer des rapports ou des plans d'action
- Avant de partager la roadmap avec d'autres équipes

### Formats à utiliser

- **Markdown** : Format principal pour l'édition manuelle
- **JSON** : Format pour l'intégration avec d'autres outils
- **HTML** : Format pour la visualisation et le partage
- **CSV** : Format pour l'analyse et l'exportation vers des outils tiers

### Commandes recommandées

```powershell
# Synchroniser la roadmap principale vers tous les formats
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "HTML"
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "CSV"

# Ou en utilisant le mode multi-synchronisation
$sourcePath = "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
$targetFormats = @("JSON", "HTML", "CSV")

foreach ($format in $targetFormats) {
    .\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath $sourcePath -TargetFormat $format
}
```

## Génération de rapports

### Fréquence des rapports

- Rapport hebdomadaire : Tous les lundis matin
- Rapport mensuel : Le premier jour de chaque mois
- Rapport ad hoc : Après des jalons importants ou des changements majeurs

### Types de rapports

- **Rapport HTML** : Pour la visualisation et le partage
- **Rapport JSON** : Pour l'intégration avec d'autres outils
- **Rapport Markdown** : Pour l'inclusion dans la documentation
- **Rapport CSV** : Pour l'analyse et l'exportation vers des outils tiers

### Commandes recommandées

```powershell
# Générer un rapport hebdomadaire
$date = Get-Date -Format "yyyy-MM-dd"
$outputPath = "projet\roadmaps\Reports\hebdomadaire-$date"

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -OutputPath $outputPath -ReportFormat "HTML"

# Générer un rapport mensuel complet
$mois = Get-Date -Format "yyyy-MM"
$outputPath = "projet\roadmaps\Reports\mensuel-$mois"

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -OutputPath $outputPath -ReportFormat "All" -DaysToAnalyze 30
```

## Planification des tâches

### Horizons de planification

- **Court terme** : 30 jours (planification détaillée)
- **Moyen terme** : 90 jours (planification générale)
- **Long terme** : 180 jours (planification stratégique)

### Fréquence de planification

- Planification hebdomadaire : Tous les vendredis après-midi
- Planification mensuelle : Le dernier jour de chaque mois
- Planification trimestrielle : Le dernier mois de chaque trimestre

### Commandes recommandées

```powershell
# Planification hebdomadaire (court terme)
$date = Get-Date -Format "yyyy-MM-dd"
$outputPath = "projet\roadmaps\Plans\hebdomadaire-$date.md"

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -OutputPath $outputPath -DaysToForecast 30

# Planification mensuelle (moyen terme)
$mois = Get-Date -Format "yyyy-MM"
$outputPath = "projet\roadmaps\Plans\mensuel-$mois.md"

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -OutputPath $outputPath -DaysToForecast 90

# Planification trimestrielle (long terme)
$trimestre = "Q" + [Math]::Ceiling((Get-Date).Month / 3) + "-" + (Get-Date).Year
$outputPath = "projet\roadmaps\Plans\trimestriel-$trimestre.md"

.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -OutputPath $outputPath -DaysToForecast 180
```

## Automatisation des workflows

### Workflow quotidien

```powershell
# Script pour le workflow quotidien
$date = Get-Date -Format "yyyy-MM-dd"
$logPath = "projet\roadmaps\Logs\workflow-quotidien-$date.log"

# Synchroniser la roadmap
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"

# Vérifier l'état d'avancement
.\development\scripts\integrated-manager.ps1 -Mode CHECK -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

# Journaliser les résultats
"Workflow quotidien exécuté le $(Get-Date)" | Out-File -FilePath $logPath -Append
```

### Workflow hebdomadaire

```powershell
# Script pour le workflow hebdomadaire
$date = Get-Date -Format "yyyy-MM-dd"
$logPath = "projet\roadmaps\Logs\workflow-hebdomadaire-$date.log"

# Exécuter le workflow de gestion de roadmap
.\development\scripts\integrated-manager.ps1 -Workflow "RoadmapManagement" -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md"

# Journaliser les résultats
"Workflow hebdomadaire exécuté le $(Get-Date)" | Out-File -FilePath $logPath -Append
```

### Tâches planifiées

Vous pouvez automatiser ces workflows en utilisant des tâches planifiées :

```powershell
# Créer une tâche planifiée pour le workflow quotidien
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\workflows\workflow-quotidien.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Workflow quotidien de gestion de roadmap" -Description "Exécute le workflow quotidien de gestion de roadmap"

# Créer une tâche planifiée pour le workflow hebdomadaire
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\workflows\workflow-hebdomadaire.ps1"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At 4pm
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Workflow hebdomadaire de gestion de roadmap" -Description "Exécute le workflow hebdomadaire de gestion de roadmap"
```

## Intégration avec d'autres outils

### Git

```powershell
# Script pour synchroniser la roadmap et pousser les changements vers Git
$date = Get-Date -Format "yyyy-MM-dd"

# Synchroniser la roadmap
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-SYNC -SourcePath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -TargetFormat "JSON"

# Ajouter les fichiers modifiés
git add "projet\roadmaps\Roadmap\roadmap_complete_converted.md"
git add "projet\roadmaps\Roadmap\roadmap_complete.json"

# Committer les changements
git commit -m "Mise à jour de la roadmap - $date"

# Pousser les changements
git push
```

### n8n

Vous pouvez créer un workflow n8n qui appelle le gestionnaire intégré via PowerShell et traite les résultats.

```javascript
// Exemple de nœud Execute Command dans n8n
{
  "parameters": {
    "command": "powershell.exe",
    "arguments": "-File D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\development\\scripts\\integrated-manager.ps1 -Workflow \"RoadmapManagement\" -RoadmapPath \"projet\\roadmaps\\Roadmap\\roadmap_complete_converted.md\"",
    "executeOnce": true
  }
}
```

### Notion

Vous pouvez exporter les rapports au format CSV et les importer dans Notion pour créer des tableaux de bord.

```powershell
# Générer un rapport CSV
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "CSV"

# Importer le rapport dans Notion (manuellement ou via l'API Notion)
```

## Résolution des problèmes courants

### Problème: Erreur de conversion de format

**Symptôme**: Le mode ROADMAP-SYNC échoue avec une erreur de conversion.

**Solution**:
1. Vérifiez que le format source est correctement spécifié.
2. Vérifiez que le fichier source existe et est accessible.
3. Essayez de convertir manuellement le fichier en utilisant les fonctions du module RoadmapParser.

```powershell
# Importer le module RoadmapParser
Import-Module "development\roadmap\parser\module\RoadmapParser.psm1"

# Convertir manuellement
ConvertFrom-MarkdownToJson -MarkdownPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -JsonPath "projet\roadmaps\Roadmap\roadmap_complete.json"
```

### Problème: Rapports incomplets

**Symptôme**: Les rapports générés sont incomplets ou manquent d'informations.

**Solution**:
1. Vérifiez que la roadmap est correctement formatée.
2. Vérifiez que les tâches ont des identifiants uniques.
3. Essayez de générer un rapport avec une période d'analyse plus longue.

```powershell
# Générer un rapport avec une période d'analyse plus longue
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-REPORT -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -ReportFormat "HTML" -DaysToAnalyze 90
```

### Problème: Plans d'action vides

**Symptôme**: Le mode ROADMAP-PLAN génère un plan vide ou avec peu de tâches.

**Solution**:
1. Vérifiez que la roadmap contient des tâches non complétées.
2. Vérifiez que les tâches ont des identifiants uniques.
3. Essayez de générer un plan avec une période de prévision plus longue.

```powershell
# Générer un plan avec une période de prévision plus longue
.\development\scripts\integrated-manager.ps1 -Mode ROADMAP-PLAN -RoadmapPath "projet\roadmaps\Roadmap\roadmap_complete_converted.md" -DaysToForecast 90
```

## Conclusion

En suivant ces bonnes pratiques, vous pourrez gérer efficacement vos roadmaps et maintenir une vision claire de l'avancement de vos projets. Les modes de gestion de roadmap (ROADMAP-SYNC, ROADMAP-REPORT, ROADMAP-PLAN) vous offrent des outils puissants pour synchroniser, analyser et planifier vos tâches, et le gestionnaire intégré vous permet de les utiliser de manière cohérente et efficace.
