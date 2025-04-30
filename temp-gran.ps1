# Script temporaire pour granulariser une tâche
# Importer la fonction Split-RoadmapTask
. "development\roadmap\parser\module\Functions\Public\Split-RoadmapTask.ps1"

# Définir les sous-tâches
$subTasks = @(
    @{ Title = "Analyser les besoins"; Description = "" },
    @{ Title = "Concevoir l'architecture"; Description = "" },
    @{ Title = "Implémenter le code"; Description = "" },
    @{ Title = "Tester la fonctionnalité"; Description = "" },
    @{ Title = "Documenter l'implémentation"; Description = "" }
)

# Appeler la fonction Split-RoadmapTask
Split-RoadmapTask -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "2.1.2.4.1.2.3.2.1.5" -SubTasks $subTasks -IndentationStyle "Auto" -CheckboxStyle "Auto"
