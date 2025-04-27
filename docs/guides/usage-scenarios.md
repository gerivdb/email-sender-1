# Scénarios d'utilisation courants du module RoadmapParser

Ce guide présente les scénarios d'utilisation les plus courants du module RoadmapParser, avec des exemples de code et des explications détaillées.

## Table des matières

1. [Analyse de feuilles de route](#analyse-de-feuilles-de-route)
2. [Suivi de progression](#suivi-de-progression)
3. [Détection de dépendances cycliques](#détection-de-dépendances-cycliques)
4. [Génération de rapports](#génération-de-rapports)
5. [Granularisation de tâches](#granularisation-de-tâches)
6. [Débogage de feuilles de route](#débogage-de-feuilles-de-route)
7. [Mesure de performance](#mesure-de-performance)
8. [Intégration avec d'autres outils](#intégration-avec-dautres-outils)

## Analyse de feuilles de route

L'analyse de feuilles de route est l'une des fonctionnalités principales du module RoadmapParser. Elle permet de convertir un fichier Markdown contenant une feuille de route en une structure d'objets PowerShell que vous pouvez manipuler programmatiquement.

### Exemple : Analyser une feuille de route simple

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Analyser la feuille de route
$roadmap = ConvertFrom-MarkdownToObject -Path $roadmapPath

# Afficher la structure de la feuille de route
$roadmap | Format-List

# Afficher les tâches de premier niveau
$roadmap.Tasks | ForEach-Object {
    Write-Host "$($_.ID): $($_.Title) - $($_.Status)"
}

# Afficher toutes les tâches, y compris les sous-tâches
$roadmap.Tasks | ForEach-Object {
    Write-Host "$($_.ID): $($_.Title) - $($_.Status)"
    
    if ($_.SubTasks) {
        $_.SubTasks | ForEach-Object {
            Write-Host "  $($_.ID): $($_.Title) - $($_.Status)"
            
            if ($_.SubTasks) {
                $_.SubTasks | ForEach-Object {
                    Write-Host "    $($_.ID): $($_.Title) - $($_.Status)"
                }
            }
        }
    }
}
```

### Exemple : Filtrer les tâches par statut

```powershell
# Obtenir toutes les tâches complétées
$completedTasks = $roadmap.Tasks | Where-Object { $_.Status -eq "Completed" }
$completedTasks += $roadmap.Tasks | ForEach-Object {
    if ($_.SubTasks) {
        $_.SubTasks | Where-Object { $_.Status -eq "Completed" }
    }
}

# Afficher les tâches complétées
$completedTasks | ForEach-Object {
    Write-Host "$($_.ID): $($_.Title)"
}

# Obtenir toutes les tâches en cours
$inProgressTasks = $roadmap.Tasks | Where-Object { $_.Status -eq "InProgress" }
$inProgressTasks += $roadmap.Tasks | ForEach-Object {
    if ($_.SubTasks) {
        $_.SubTasks | Where-Object { $_.Status -eq "InProgress" }
    }
}

# Afficher les tâches en cours
$inProgressTasks | ForEach-Object {
    Write-Host "$($_.ID): $($_.Title)"
}
```

## Suivi de progression

Le module RoadmapParser permet de suivre la progression d'une feuille de route en mettant à jour le statut des tâches et en générant des rapports de progression.

### Exemple : Mettre à jour le statut d'une tâche

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Analyser la feuille de route
$roadmap = ConvertFrom-MarkdownToObject -Path $roadmapPath

# Mettre à jour le statut d'une tâche
$taskId = "1.2.3"
$newStatus = "Completed"
$updatedRoadmap = Update-RoadmapTaskStatus -Roadmap $roadmap -TaskId $taskId -Status $newStatus

# Enregistrer la feuille de route mise à jour
$updatedRoadmap | ConvertTo-MarkdownFromObject -Path $roadmapPath

# Afficher la progression globale
$totalTasks = ($roadmap.Tasks | Measure-Object).Count
$completedTasks = ($roadmap.Tasks | Where-Object { $_.Status -eq "Completed" } | Measure-Object).Count
$progressPercentage = ($completedTasks / $totalTasks) * 100

Write-Host "Progression: $progressPercentage% ($completedTasks/$totalTasks tâches complétées)"
```

### Exemple : Générer un rapport de progression

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Analyser la feuille de route
$roadmap = ConvertFrom-MarkdownToObject -Path $roadmapPath

# Générer un rapport de progression
$reportPath = "C:\Projets\MonProjet\progress-report.html"
$report = Generate-RoadmapReport -Roadmap $roadmap -OutputPath $reportPath -Format HTML -Title "Rapport de progression du projet"

# Ouvrir le rapport dans le navigateur par défaut
Invoke-Item $reportPath
```

## Détection de dépendances cycliques

Le module RoadmapParser peut détecter les dépendances cycliques dans une feuille de route, ce qui peut aider à identifier les problèmes potentiels dans la planification du projet.

### Exemple : Détecter les dépendances cycliques

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Analyser la feuille de route
$roadmap = ConvertFrom-MarkdownToObject -Path $roadmapPath

# Extraire les dépendances
$dependencies = Get-RoadmapDependencies -Roadmap $roadmap

# Détecter les cycles
$cycles = Find-DependencyCycle -Dependencies $dependencies

# Afficher les cycles détectés
if ($cycles.Count -gt 0) {
    Write-Host "Dépendances cycliques détectées:"
    foreach ($cycle in $cycles) {
        Write-Host "Cycle: $($cycle -join ' -> ') -> $($cycle[0])"
    }
} else {
    Write-Host "Aucune dépendance cyclique détectée."
}

# Générer un graphe de dépendances
$graphPath = "C:\Projets\MonProjet\dependencies.png"
Build-DependencyGraph -Dependencies $dependencies -OutputPath $graphPath -Format PNG

# Ouvrir le graphe dans le visualiseur par défaut
Invoke-Item $graphPath
```

## Génération de rapports

Le module RoadmapParser permet de générer différents types de rapports à partir d'une feuille de route.

### Exemple : Générer un rapport HTML

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Analyser la feuille de route
$roadmap = ConvertFrom-MarkdownToObject -Path $roadmapPath

# Générer un rapport HTML
$reportPath = "C:\Projets\MonProjet\roadmap-report.html"
Generate-RoadmapReport -Roadmap $roadmap -OutputPath $reportPath -Format HTML -Title "Rapport de feuille de route"

# Ouvrir le rapport dans le navigateur par défaut
Invoke-Item $reportPath
```

### Exemple : Générer un rapport CSV

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Analyser la feuille de route
$roadmap = ConvertFrom-MarkdownToObject -Path $roadmapPath

# Générer un rapport CSV
$reportPath = "C:\Projets\MonProjet\roadmap-report.csv"
Generate-RoadmapReport -Roadmap $roadmap -OutputPath $reportPath -Format CSV

# Ouvrir le rapport dans Excel
Invoke-Item $reportPath
```

## Granularisation de tâches

Le module RoadmapParser permet de granulariser les tâches d'une feuille de route, c'est-à-dire de décomposer une tâche en sous-tâches plus petites et plus faciles à gérer.

### Exemple : Granulariser une tâche

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Analyser la feuille de route
$roadmap = ConvertFrom-MarkdownToObject -Path $roadmapPath

# Définir la tâche à granulariser
$taskId = "1.2.3"

# Définir les sous-tâches
$subTasks = @(
    @{
        Title = "Sous-tâche 1"
        Status = "NotStarted"
    },
    @{
        Title = "Sous-tâche 2"
        Status = "NotStarted"
    },
    @{
        Title = "Sous-tâche 3"
        Status = "NotStarted"
    }
)

# Granulariser la tâche
$updatedRoadmap = Invoke-RoadmapGranularization -Roadmap $roadmap -TaskId $taskId -SubTasks $subTasks

# Enregistrer la feuille de route mise à jour
$updatedRoadmap | ConvertTo-MarkdownFromObject -Path $roadmapPath
```

## Débogage de feuilles de route

Le module RoadmapParser fournit des outils pour déboguer les feuilles de route et identifier les problèmes potentiels.

### Exemple : Déboguer une feuille de route

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Déboguer la feuille de route
$debugResult = Invoke-RoadmapDebug -Path $roadmapPath -Verbose

# Afficher les erreurs détectées
if ($debugResult.Errors.Count -gt 0) {
    Write-Host "Erreurs détectées:"
    foreach ($error in $debugResult.Errors) {
        Write-Host "- $($error.Message) (Ligne $($error.LineNumber))"
    }
} else {
    Write-Host "Aucune erreur détectée."
}

# Afficher les avertissements
if ($debugResult.Warnings.Count -gt 0) {
    Write-Host "Avertissements:"
    foreach ($warning in $debugResult.Warnings) {
        Write-Host "- $($warning.Message) (Ligne $($warning.LineNumber))"
    }
} else {
    Write-Host "Aucun avertissement détecté."
}

# Générer un rapport de débogage
$reportPath = "C:\Projets\MonProjet\debug-report.html"
$debugResult | Export-RoadmapDebugReport -OutputPath $reportPath -Format HTML

# Ouvrir le rapport dans le navigateur par défaut
Invoke-Item $reportPath
```

## Mesure de performance

Le module RoadmapParser permet de mesurer les performances des opérations sur les feuilles de route, ce qui peut aider à identifier les goulots d'étranglement et à optimiser les performances.

### Exemple : Mesurer les performances d'analyse

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Mesurer les performances d'analyse
$result = Measure-RoadmapPerformance -ScriptBlock {
    ConvertFrom-MarkdownToObject -Path $roadmapPath
} -Iterations 10

# Afficher les résultats
$result | Format-Table -Property Operation, AverageTime, MinTime, MaxTime, TotalTime

# Générer un rapport de performance
$reportPath = "C:\Projets\MonProjet\performance-report.html"
$result | Export-PerformanceReport -OutputPath $reportPath -Format HTML

# Ouvrir le rapport dans le navigateur par défaut
Invoke-Item $reportPath
```

## Intégration avec d'autres outils

Le module RoadmapParser peut être intégré à d'autres outils et systèmes pour créer des flux de travail automatisés.

### Exemple : Intégration avec Git

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Analyser la feuille de route
$roadmap = ConvertFrom-MarkdownToObject -Path $roadmapPath

# Mettre à jour le statut d'une tâche
$taskId = "1.2.3"
$newStatus = "Completed"
$updatedRoadmap = Update-RoadmapTaskStatus -Roadmap $roadmap -TaskId $taskId -Status $newStatus

# Enregistrer la feuille de route mise à jour
$updatedRoadmap | ConvertTo-MarkdownFromObject -Path $roadmapPath

# Valider les modifications dans Git
Set-Location -Path "C:\Projets\MonProjet"
git add $roadmapPath
git commit -m "Mise à jour du statut de la tâche $taskId à $newStatus"
git push
```

### Exemple : Intégration avec Azure DevOps

```powershell
# Importer le module
Import-Module RoadmapParser

# Chemin vers la feuille de route
$roadmapPath = "C:\Projets\MonProjet\roadmap.md"

# Analyser la feuille de route
$roadmap = ConvertFrom-MarkdownToObject -Path $roadmapPath

# Obtenir les tâches non démarrées
$notStartedTasks = $roadmap.Tasks | Where-Object { $_.Status -eq "NotStarted" }
$notStartedTasks += $roadmap.Tasks | ForEach-Object {
    if ($_.SubTasks) {
        $_.SubTasks | Where-Object { $_.Status -eq "NotStarted" }
    }
}

# Créer des éléments de travail dans Azure DevOps
foreach ($task in $notStartedTasks) {
    $workItem = @{
        Title = $task.Title
        Description = "ID de tâche dans la feuille de route: $($task.ID)"
        WorkItemType = "Task"
        State = "New"
        Tags = "RoadmapParser"
    }
    
    # Créer l'élément de travail (exemple simplifié)
    # Dans un scénario réel, vous utiliseriez l'API Azure DevOps
    Write-Host "Création de l'élément de travail: $($workItem.Title)"
}
```

Ces exemples illustrent les scénarios d'utilisation les plus courants du module RoadmapParser. Pour plus d'informations sur les fonctions spécifiques, consultez la [documentation de l'API](../api/index.md).
