# Test-RoadmapModel2.ps1
# Script pour tester le modÃ¨le objet de la roadmap

# Importer le module RoadmapModel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapModel2.psm1"
Import-Module $modulePath -Force

# CrÃ©er un nouvel arbre de roadmap
Write-Host "CrÃ©ation d'un nouvel arbre de roadmap..." -ForegroundColor Cyan
$roadmap = New-RoadmapTree -Title "Roadmap de Test" -Description "Ceci est une roadmap de test pour valider le modÃ¨le objet."

# CrÃ©er quelques tÃ¢ches
Write-Host "CrÃ©ation des tÃ¢ches..." -ForegroundColor Cyan
$task1 = New-RoadmapTask -Id "1" -Title "TÃ¢che 1" -Description "Description de la tÃ¢che 1"
$task1_1 = New-RoadmapTask -Id "1.1" -Title "TÃ¢che 1.1" -Description "Description de la tÃ¢che 1.1"
$task1_2 = New-RoadmapTask -Id "1.2" -Title "TÃ¢che 1.2" -Description "Description de la tÃ¢che 1.2"
$task1_2_1 = New-RoadmapTask -Id "1.2.1" -Title "TÃ¢che 1.2.1" -Description "Description de la tÃ¢che 1.2.1"
$task1_2_2 = New-RoadmapTask -Id "1.2.2" -Title "TÃ¢che 1.2.2" -Description "Description de la tÃ¢che 1.2.2" -Status ([TaskStatus]::Complete)
$task2 = New-RoadmapTask -Id "2" -Title "TÃ¢che 2" -Description "Description de la tÃ¢che 2"
$task2_1 = New-RoadmapTask -Id "2.1" -Title "TÃ¢che 2.1" -Description "Description de la tÃ¢che 2.1" -Status ([TaskStatus]::InProgress)

# Ajouter les tÃ¢ches Ã  l'arbre
Write-Host "Ajout des tÃ¢ches Ã  l'arbre..." -ForegroundColor Cyan
$roadmap.AddTask.Invoke($task1)
$roadmap.AddTask.Invoke($task1_1, $task1)
$roadmap.AddTask.Invoke($task1_2, $task1)
$roadmap.AddTask.Invoke($task1_2_1, $task1_2)
$roadmap.AddTask.Invoke($task1_2_2, $task1_2)
$roadmap.AddTask.Invoke($task2)
$roadmap.AddTask.Invoke($task2_1, $task2)

# Ajouter des dÃ©pendances
Write-Host "Ajout des dÃ©pendances..." -ForegroundColor Cyan
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
Write-Host "Arbre exportÃ© en JSON: $jsonPath" -ForegroundColor Green

# Exporter l'arbre en markdown
Write-Host "`nExportation de l'arbre en markdown..." -ForegroundColor Cyan
$markdownPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-test.md"
Export-RoadmapTreeToMarkdown -RoadmapTree $roadmap -FilePath $markdownPath
Write-Host "Arbre exportÃ© en markdown: $markdownPath" -ForegroundColor Green

# Importer l'arbre Ã  partir du JSON
Write-Host "`nImportation de l'arbre Ã  partir du JSON..." -ForegroundColor Cyan
$importedRoadmap = Import-RoadmapTreeFromJson -FilePath $jsonPath
Write-Host "Arbre importÃ© avec succÃ¨s." -ForegroundColor Green

# VÃ©rifier que l'arbre importÃ© est identique Ã  l'original
Write-Host "`nVÃ©rification de l'arbre importÃ©:" -ForegroundColor Cyan
$importedTasks = $importedRoadmap.TraverseDepthFirst.Invoke()
Write-Host "Nombre de tÃ¢ches dans l'arbre original: $($tasks.Count)" -ForegroundColor Green
Write-Host "Nombre de tÃ¢ches dans l'arbre importÃ©: $($importedTasks.Count)" -ForegroundColor Green

# Rechercher des tÃ¢ches
Write-Host "`nRecherche de tÃ¢ches contenant '1.2':" -ForegroundColor Cyan
$searchResults = $roadmap.SearchTasks.Invoke("1.2")
foreach ($task in $searchResults) {
    Write-Host "  - $($task.Id) $($task.Title)" -ForegroundColor Green
}

# Filtrer les tÃ¢ches terminÃ©es
Write-Host "`nFiltrage des tÃ¢ches terminÃ©es:" -ForegroundColor Cyan
$completedTasks = $roadmap.FilterTasks.Invoke({ param($t) $t.Status -eq [TaskStatus]::Complete })
foreach ($task in $completedTasks) {
    Write-Host "  - $($task.Id) $($task.Title)" -ForegroundColor Green
}

# Filtrer les tÃ¢ches en cours
Write-Host "`nFiltrage des tÃ¢ches en cours:" -ForegroundColor Cyan
$inProgressTasks = $roadmap.FilterTasks.Invoke({ param($t) $t.Status -eq [TaskStatus]::InProgress })
foreach ($task in $inProgressTasks) {
    Write-Host "  - $($task.Id) $($task.Title)" -ForegroundColor Green
}

# Afficher les dÃ©pendances
Write-Host "`nDÃ©pendances:" -ForegroundColor Cyan
foreach ($task in $tasks) {
    if ($task.Dependencies.Count -gt 0) {
        Write-Host "  $($task.Id) $($task.Title) dÃ©pend de:" -ForegroundColor Green
        foreach ($dependency in $task.Dependencies) {
            Write-Host "    - $($dependency.Id) $($dependency.Title)" -ForegroundColor Yellow
        }
    }
}

# Tester la conversion d'un fichier markdown en arbre de roadmap
Write-Host "`nTest de conversion d'un fichier markdown en arbre de roadmap..." -ForegroundColor Cyan
$roadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
if (Test-Path -Path $roadmapFilePath) {
    Write-Host "Conversion du fichier markdown: $roadmapFilePath" -ForegroundColor Green
    $convertedRoadmap = ConvertFrom-MarkdownToRoadmapTree -FilePath $roadmapFilePath
    $convertedTasks = $convertedRoadmap.TraverseDepthFirst.Invoke()
    Write-Host "Nombre de tÃ¢ches dans l'arbre converti: $($convertedTasks.Count)" -ForegroundColor Green

    # Exporter l'arbre converti en markdown
    $convertedMarkdownPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-converted.md"
    Export-RoadmapTreeToMarkdown -RoadmapTree $convertedRoadmap -FilePath $convertedMarkdownPath
    Write-Host "Arbre converti exportÃ© en markdown: $convertedMarkdownPath" -ForegroundColor Green
} else {
    Write-Host "Le fichier markdown n'existe pas: $roadmapFilePath" -ForegroundColor Red
}

Write-Host "`nTest terminÃ©." -ForegroundColor Cyan
