# Test-RoadmapModel2-Direct.ps1
# Script pour tester le modèle objet de la roadmap sans utiliser les scriptblocks

# Importer le module RoadmapModel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapModel2.psm1"
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
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-test-direct2.json"
Export-RoadmapTreeToJson -RoadmapTree $roadmap -FilePath $jsonPath
Write-Host "Arbre exporté en JSON: $jsonPath" -ForegroundColor Green

# Exporter l'arbre en markdown
Write-Host "`nExportation de l'arbre en markdown..." -ForegroundColor Cyan
$markdownPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-test-direct2.md"

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

# Tester la conversion d'un fichier markdown en arbre de roadmap
Write-Host "`nTest de conversion d'un fichier markdown en arbre de roadmap..." -ForegroundColor Cyan
$roadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
if (Test-Path -Path $roadmapFilePath) {
    Write-Host "Conversion du fichier markdown: $roadmapFilePath" -ForegroundColor Green
    
    # Lire le contenu du fichier markdown
    $content = Get-Content -Path $roadmapFilePath -Encoding UTF8 -Raw
    $lines = $content -split "`n"
    
    # Extraire le titre et la description
    $title = "Roadmap"
    $description = ""
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^#\s+(.+)$') {
            $title = $matches[1]
            
            # Extraire la description (lignes non vides après le titre jusqu'à la première section)
            $descLines = @()
            $j = $i + 1
            while ($j -lt $lines.Count -and -not ($lines[$j] -match '^#{2,}\s+')) {
                if (-not [string]::IsNullOrWhiteSpace($lines[$j])) {
                    $descLines += $lines[$j]
                }
                $j++
            }
            
            if ($descLines.Count -gt 0) {
                $description = $descLines -join "`n"
            }
            
            break
        }
    }
    
    # Créer l'arbre de roadmap
    $convertedRoadmap = New-RoadmapTree -Title $title -Description $description
    $convertedRoadmap.FilePath = $roadmapFilePath
    
    # Parser les tâches
    $currentParent = $convertedRoadmap.Root
    $currentLevel = 0
    $idCounter = 1
    $taskMap = @{}
    
    foreach ($line in $lines) {
        if ($line -match '^(\s*)[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$') {
            $indent = $matches[1].Length
            $statusMark = $matches[2]
            $id = $matches[3]
            $title = $matches[4]
            
            # Déterminer le statut
            $status = switch ($statusMark) {
                'x' { [TaskStatus]::Complete }
                'X' { [TaskStatus]::Complete }
                '~' { [TaskStatus]::InProgress }
                '!' { [TaskStatus]::Blocked }
                default { [TaskStatus]::Incomplete }
            }
            
            # Si l'ID n'est pas spécifié, en générer un
            if ([string]::IsNullOrEmpty($id)) {
                $id = "$idCounter"
                $idCounter++
            }
            
            # Créer la tâche
            $task = New-RoadmapTask -Id $id -Title $title -Status $status
            $task.OriginalMarkdown = $line
            
            # Déterminer le parent en fonction de l'indentation
            if ($indent -gt $currentLevel) {
                # Niveau d'indentation supérieur, le parent est la dernière tâche ajoutée
                $currentParent = $taskMap[$currentLevel]
                $currentLevel = $indent
            } elseif ($indent -lt $currentLevel) {
                # Niveau d'indentation inférieur, remonter dans l'arborescence
                while ($indent -lt $currentLevel -and $currentParent.Parent -ne $convertedRoadmap.Root) {
                    $currentParent = $currentParent.Parent
                    $currentLevel -= 2  # Supposer 2 espaces par niveau
                }
            }
            
            # Ajouter la tâche à l'arbre
            $task.Parent = $currentParent
            $currentParent.Children.Add($task)
            $convertedRoadmap.AllTasks.Add($task)
            $convertedRoadmap.TasksById[$task.Id] = $task
            $task.Level = if ($currentParent -eq $convertedRoadmap.Root) { 0 } else { $currentParent.Level + 1 }
            
            $taskMap[$indent] = $task
        }
    }
    
    # Afficher les tâches converties
    Write-Host "`nTâches converties:" -ForegroundColor Green
    $convertedTasks = New-Object System.Collections.ArrayList
    foreach ($child in $convertedRoadmap.Root.Children) {
        $convertedTasks.Add($child)
        TraverseTasksRecursively -Task $child -Result $convertedTasks
    }
    
    Write-Host "Nombre de tâches dans l'arbre converti: $($convertedTasks.Count)" -ForegroundColor Green
    
    # Exporter l'arbre converti en markdown
    $convertedMarkdownPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-converted-direct.md"
    
    # Générer le markdown manuellement
    $convertedMarkdown = "# $($convertedRoadmap.Title)`n`n"
    if (-not [string]::IsNullOrEmpty($convertedRoadmap.Description)) {
        $convertedMarkdown += "$($convertedRoadmap.Description)`n`n"
    }
    
    foreach ($task in $convertedRoadmap.Root.Children) {
        $convertedMarkdown += TaskToMarkdown -Task $task
    }
    
    $convertedMarkdown | Out-File -FilePath $convertedMarkdownPath -Encoding UTF8
    Write-Host "Arbre converti exporté en markdown: $convertedMarkdownPath" -ForegroundColor Green
} else {
    Write-Host "Le fichier markdown n'existe pas: $roadmapFilePath" -ForegroundColor Red
}

Write-Host "`nTest terminé." -ForegroundColor Cyan
