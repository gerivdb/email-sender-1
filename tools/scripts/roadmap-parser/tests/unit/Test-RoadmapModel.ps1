# Test-RoadmapModel.ps1
# Script pour tester le modèle objet de la roadmap

# Importer le module RoadmapModel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapModel.psm1"
Import-Module $modulePath -Force

# Créer un nouvel arbre de roadmap
Write-Host "Création d'un nouvel arbre de roadmap..." -ForegroundColor Cyan
$roadmap = New-RoadmapTree -Title "Roadmap de Test" -Description "Ceci est une roadmap de test pour valider le modèle objet."

# Créer quelques tâches
Write-Host "Création des tâches..." -ForegroundColor Cyan
$task1 = New-RoadmapTask -Id "1" -Title "Tâche 1" -Description "Description de la tâche 1"
$task1_1 = New-RoadmapTask -Id "1.1" -Title "Tâche 1.1" -Description "Description de la tâche 1.1"
$task1_2 = New-RoadmapTask -Id "1.2" -Title "Tâche 1.2" -Description "Description de la tâche 1.2"
$task1_2_1 = New-RoadmapTask -Id "1.2.1" -Title "Tâche 1.2.1" -Description "Description de la tâche 1.2.1"
$task1_2_2 = New-RoadmapTask -Id "1.2.2" -Title "Tâche 1.2.2" -Description "Description de la tâche 1.2.2" -Status ([TaskStatus]::Complete)
$task2 = New-RoadmapTask -Id "2" -Title "Tâche 2" -Description "Description de la tâche 2"
$task2_1 = New-RoadmapTask -Id "2.1" -Title "Tâche 2.1" -Description "Description de la tâche 2.1" -Status ([TaskStatus]::InProgress)

# Ajouter les tâches à l'arbre
Write-Host "Ajout des tâches à l'arbre..." -ForegroundColor Cyan
$roadmap.AddTask.Invoke($task1)
$roadmap.AddTask.Invoke($task1_1, $task1)
$roadmap.AddTask.Invoke($task1_2, $task1)
$roadmap.AddTask.Invoke($task1_2_1, $task1_2)
$roadmap.AddTask.Invoke($task1_2_2, $task1_2)
$roadmap.AddTask.Invoke($task2)
$roadmap.AddTask.Invoke($task2_1, $task2)

# Ajouter des dépendances
Write-Host "Ajout des dépendances..." -ForegroundColor Cyan
$task2.AddDependency.Invoke($task1)
$task2_1.AddDependency.Invoke($task1_2_2)

# Afficher la structure de l'arbre
Write-Host "`nStructure de l'arbre:" -ForegroundColor Green
$tasks = $roadmap.TraverseDepthFirst.Invoke()
foreach ($task in $tasks) {
    $indent = "  " * $task.Level
    $statusMark = switch ($task.Status) {
        ([TaskStatus]::Complete) { "[x]" }
        ([TaskStatus]::InProgress) { "[~]" }
        ([TaskStatus]::Blocked) { "[!]" }
        default { "[ ]" }
    }
    Write-Host "$indent- $statusMark $($task.Id) $($task.Title)"
}

# Valider la structure de l'arbre
Write-Host "`nValidation de la structure de l'arbre..." -ForegroundColor Cyan
$isValid = $roadmap.ValidateStructure.Invoke()
Write-Host "Structure valide: $isValid" -ForegroundColor $(if ($isValid) { "Green" } else { "Red" })

# Exporter l'arbre en JSON
Write-Host "`nExportation de l'arbre en JSON..." -ForegroundColor Cyan
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-test.json"
Export-RoadmapTreeToJson -RoadmapTree $roadmap -FilePath $jsonPath
Write-Host "Arbre exporté en JSON: $jsonPath" -ForegroundColor Green

# Exporter l'arbre en markdown
Write-Host "`nExportation de l'arbre en markdown..." -ForegroundColor Cyan
$markdownPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-test.md"
Export-RoadmapTreeToMarkdown -RoadmapTree $roadmap -FilePath $markdownPath
Write-Host "Arbre exporté en markdown: $markdownPath" -ForegroundColor Green

# Importer l'arbre à partir du JSON
Write-Host "`nImportation de l'arbre à partir du JSON..." -ForegroundColor Cyan
$importedRoadmap = Import-RoadmapTreeFromJson -FilePath $jsonPath
Write-Host "Arbre importé avec succès." -ForegroundColor Green

# Vérifier que l'arbre importé est identique à l'original
Write-Host "`nVérification de l'arbre importé:" -ForegroundColor Cyan
$importedTasks = $importedRoadmap.TraverseDepthFirst.Invoke()
Write-Host "Nombre de tâches dans l'arbre original: $($tasks.Count)" -ForegroundColor Green
Write-Host "Nombre de tâches dans l'arbre importé: $($importedTasks.Count)" -ForegroundColor Green

# Rechercher des tâches
Write-Host "`nRecherche de tâches contenant '1.2':" -ForegroundColor Cyan
$searchResults = $roadmap.SearchTasks.Invoke("1.2")
foreach ($task in $searchResults) {
    Write-Host "  - $($task.Id) $($task.Title)" -ForegroundColor Green
}

# Filtrer les tâches terminées
Write-Host "`nFiltrage des tâches terminées:" -ForegroundColor Cyan
$completedTasks = $roadmap.FilterTasks.Invoke({ param($t) $t.Status -eq [TaskStatus]::Complete })
foreach ($task in $completedTasks) {
    Write-Host "  - $($task.Id) $($task.Title)" -ForegroundColor Green
}

# Filtrer les tâches en cours
Write-Host "`nFiltrage des tâches en cours:" -ForegroundColor Cyan
$inProgressTasks = $roadmap.FilterTasks.Invoke({ param($t) $t.Status -eq [TaskStatus]::InProgress })
foreach ($task in $inProgressTasks) {
    Write-Host "  - $($task.Id) $($task.Title)" -ForegroundColor Green
}

# Afficher les dépendances
Write-Host "`nDépendances:" -ForegroundColor Cyan
foreach ($task in $tasks) {
    if ($task.Dependencies.Count -gt 0) {
        Write-Host "  $($task.Id) $($task.Title) dépend de:" -ForegroundColor Green
        foreach ($dependency in $task.Dependencies) {
            Write-Host "    - $($dependency.Id) $($dependency.Title)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nTest terminé." -ForegroundColor Cyan
