# Test-RoadmapModel-Direct.ps1
# Script pour tester le modÃ¨le objet de la roadmap sans utiliser les scriptblocks

# Importer le module RoadmapModel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapModel.psm1"
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

# Ajouter les tÃ¢ches Ã  l'arbre manuellement
Write-Host "Ajout des tÃ¢ches Ã  l'arbre..." -ForegroundColor Cyan
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

# Ajouter des dÃ©pendances manuellement
Write-Host "Ajout des dÃ©pendances..." -ForegroundColor Cyan
$task2.Dependencies.Add($task1)
$task1.DependentTasks.Add($task2)

$task2_1.Dependencies.Add($task1_2_2)
$task1_2_2.DependentTasks.Add($task2_1)

# DÃ©finir la fonction de parcours rÃ©cursif
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
Write-Host "Arbre exportÃ© en JSON: $jsonPath" -ForegroundColor Green

# Exporter l'arbre en markdown
Write-Host "`nExportation de l'arbre en markdown..." -ForegroundColor Cyan
$markdownPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-test-direct.md"

# GÃ©nÃ©rer le markdown manuellement
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
Write-Host "Arbre exportÃ© en markdown: $markdownPath" -ForegroundColor Green

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

Write-Host "`nTest terminÃ©." -ForegroundColor Cyan
