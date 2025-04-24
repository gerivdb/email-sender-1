# Test-RoadmapModel-Direct.ps1
# Script pour tester le modèle objet de la roadmap sans utiliser les scriptblocks

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

# Ajouter les tâches à l'arbre manuellement
Write-Host "Ajout des tâches à l'arbre..." -ForegroundColor Cyan
$task1.Parent = $roadmap.Root
$roadmap.Root.Children.Add($task1)
$roadmap.AllTasks.Add($task1)
$roadmap.TasksById[$task1.Id] = $task1
$task1.Level = 0

$task1_1.Parent = $task1
$task1.Children.Add($task1_1)
$roadmap.AllTasks.Add($task1_1)
$roadmap.TasksById[$task1_1.Id] = $task1_1
$task1_1.Level = 1

$task1_2.Parent = $task1
$task1.Children.Add($task1_2)
$roadmap.AllTasks.Add($task1_2)
$roadmap.TasksById[$task1_2.Id] = $task1_2
$task1_2.Level = 1

$task1_2_1.Parent = $task1_2
$task1_2.Children.Add($task1_2_1)
$roadmap.AllTasks.Add($task1_2_1)
$roadmap.TasksById[$task1_2_1.Id] = $task1_2_1
$task1_2_1.Level = 2

$task1_2_2.Parent = $task1_2
$task1_2.Children.Add($task1_2_2)
$roadmap.AllTasks.Add($task1_2_2)
$roadmap.TasksById[$task1_2_2.Id] = $task1_2_2
$task1_2_2.Level = 2

$task2.Parent = $roadmap.Root
$roadmap.Root.Children.Add($task2)
$roadmap.AllTasks.Add($task2)
$roadmap.TasksById[$task2.Id] = $task2
$task2.Level = 0

$task2_1.Parent = $task2
$task2.Children.Add($task2_1)
$roadmap.AllTasks.Add($task2_1)
$roadmap.TasksById[$task2_1.Id] = $task2_1
$task2_1.Level = 1

# Ajouter des dépendances manuellement
Write-Host "Ajout des dépendances..." -ForegroundColor Cyan
$task2.Dependencies.Add($task1)
$task1.DependentTasks.Add($task2)

$task2_1.Dependencies.Add($task1_2_2)
$task1_2_2.DependentTasks.Add($task2_1)

# Définir la fonction de parcours récursif
function TraverseTasksRecursively {
    param(
        [PSCustomObject]$Task,
        [System.Collections.ArrayList]$Result
    )

    foreach ($child in $Task.Children) {
        $Result.Add($child)
        TraverseTasksRecursively -Task $child -Result $Result
    }
}

# Afficher la structure de l'arbre
Write-Host "`nStructure de l'arbre:" -ForegroundColor Green
$tasks = New-Object System.Collections.ArrayList
foreach ($child in $roadmap.Root.Children) {
    $tasks.Add($child)
    TraverseTasksRecursively -Task $child -Result $tasks
}

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

# Exporter l'arbre en JSON
Write-Host "`nExportation de l'arbre en JSON..." -ForegroundColor Cyan
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-test-direct.json"
Export-RoadmapTreeToJson -RoadmapTree $roadmap -FilePath $jsonPath
Write-Host "Arbre exporté en JSON: $jsonPath" -ForegroundColor Green

# Exporter l'arbre en markdown
Write-Host "`nExportation de l'arbre en markdown..." -ForegroundColor Cyan
$markdownPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-test-direct.md"

# Générer le markdown manuellement
$markdown = "# $($roadmap.Title)`n`n"
if (-not [string]::IsNullOrEmpty($roadmap.Description)) {
    $markdown += "$($roadmap.Description)`n`n"
}

function TaskToMarkdown {
    param(
        [PSCustomObject]$Task
    )

    $indent = "  " * $Task.Level
    $statusMark = switch ($Task.Status) {
        ([TaskStatus]::Complete) { "[x]" }
        ([TaskStatus]::InProgress) { "[~]" }
        ([TaskStatus]::Blocked) { "[!]" }
        default { "[ ]" }
    }

    $result = "$indent- $statusMark **$($Task.Id)** $($Task.Title)`n"
    if (-not [string]::IsNullOrEmpty($Task.Description)) {
        $result += "$indent  $($Task.Description)`n"
    }

    foreach ($child in $Task.Children) {
        $result += TaskToMarkdown -Task $child
    }

    return $result
}

foreach ($task in $roadmap.Root.Children) {
    $markdown += TaskToMarkdown -Task $task
}

$markdown | Out-File -FilePath $markdownPath -Encoding UTF8
Write-Host "Arbre exporté en markdown: $markdownPath" -ForegroundColor Green

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
