# Test simple pour la fonction Get-TasksFromSelection

# Définir la fonction
function Get-TasksFromSelection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Selection,

        [Parameter(Mandatory = $false)]
        [switch]$IdentifyChildren,

        [Parameter(Mandatory = $false)]
        [switch]$SortByHierarchy
    )

    # Initialiser la liste des taches
    $tasks = New-Object System.Collections.ArrayList

    # Diviser la selection en lignes
    $lines = $Selection -split "`r?`n"

    # Analyser chaque ligne pour extraire les taches
    foreach ($line in $lines) {
        # Verifier si la ligne contient une tache
        if ($line -match '^\s*[-*+]\s*\[([ xX])\]\s*(.+)$') {
            $isCompleted = $matches[1] -ne ' '
            $taskContent = $matches[2]

            # Determiner l'indentation
            $indentation = 0
            if ($line -match '^(\s+)') {
                $indentation = $matches[1].Length
            }

            # Extraire l'identifiant de la tache si present
            $taskId = ""
            if ($taskContent -match '^(\d+(\.\d+)*)\s+(.+)$') {
                $taskId = $matches[1]
                $taskContent = $matches[3]
            }

            # Creer l'objet tache
            $task = [PSCustomObject]@{
                Id          = $taskId
                Content     = $taskContent
                IsCompleted = $isCompleted
                Indentation = $indentation
                Line        = $line
                Children    = @()
                Parent      = $null
                Level       = if ($taskId -match '\.') { ($taskId -split '\.').Count } else { 1 }
            }

            # Ajouter la tache a la liste
            [void]$tasks.Add($task)
        }
    }

    # Identifier les taches enfants si demande
    if ($IdentifyChildren) {
        for ($i = 0; $i -lt $tasks.Count; $i++) {
            $currentTask = $tasks[$i]

            # Parcourir les taches suivantes pour trouver les enfants
            for ($j = $i + 1; $j -lt $tasks.Count; $j++) {
                $nextTask = $tasks[$j]

                # Verifier si la tache suivante est un enfant de la tache courante
                if ($nextTask.Id -match "^$([regex]::Escape($currentTask.Id))\.\d+$" -or
                    $nextTask.Indentation -gt $currentTask.Indentation) {
                    $nextTask.Parent = $currentTask
                    $currentTask.Children += $nextTask
                }
                # Si on trouve une tache de meme niveau ou de niveau superieur, arreter la recherche
                elseif ($nextTask.Indentation -le $currentTask.Indentation) {
                    break
                }
            }
        }
    }

    # Trier les taches par ordre hierarchique si demande
    if ($SortByHierarchy) {
        # Fonction recursive pour aplatir la hierarchie
        function Get-FlattenedTasks {
            param (
                [Parameter(Mandatory = $true)]
                [array]$TaskList,

                [Parameter(Mandatory = $false)]
                [array]$Result = @()
            )

            foreach ($task in $TaskList) {
                if ($null -eq $task.Parent) {
                    $Result += $task
                    if ($task.Children.Count -gt 0) {
                        foreach ($child in $task.Children) {
                            $Result += $child
                        }
                    }
                }
            }

            return $Result
        }

        # Obtenir les taches racines (sans parent)
        $rootTasks = $tasks | Where-Object { $null -eq $_.Parent }

        # Aplatir la hierarchie
        $tasks = Get-FlattenedTasks -TaskList $rootTasks
    }

    return $tasks
}

# Tester la fonction avec une tâche simple
$selection = "- [ ] 1.1 Task simple"
$tasks = Get-TasksFromSelection -Selection $selection

# Afficher les résultats
Write-Host "Test 1: Tâche simple"
$tasks | Format-Table -Property Id, Content, IsCompleted

# Tester la fonction avec une tâche complétée
$selection = "- [x] 1.1 Task completed"
$tasks = Get-TasksFromSelection -Selection $selection

# Afficher les résultats
Write-Host "Test 2: Tâche complétée"
$tasks | Format-Table -Property Id, Content, IsCompleted

# Tester la fonction avec plusieurs tâches
$selection = @"
- [ ] 1.1 First task
- [ ] 1.2 Second task
- [ ] 1.3 Third task
"@
$tasks = Get-TasksFromSelection -Selection $selection

# Afficher les résultats
Write-Host "Test 3: Plusieurs tâches"
$tasks | Format-Table -Property Id, Content, IsCompleted

# Tester la fonction avec des tâches enfants
$selection = @"
- [ ] 1.1 Parent task
  - [ ] 1.1.1 Child task
"@
$tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren

# Afficher les résultats
Write-Host "Test 4: Tâches avec enfants"
$tasks | Format-Table -Property Id, Content, IsCompleted, Indentation
Write-Host "Enfants de la tâche 1.1:"
$tasks[0].Children | Format-Table -Property Id, Content, IsCompleted

# Tester la fonction avec tri hiérarchique
$selection = @"
- [ ] 1.1 Parent task 1
  - [ ] 1.1.1 Child task 1
- [ ] 1.2 Parent task 2
  - [ ] 1.2.1 Child task 2
"@
$tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren -SortByHierarchy

# Afficher les résultats
Write-Host "Test 5: Tri hiérarchique"
$tasks | Format-Table -Property Id, Content, IsCompleted

# Vérifier le problème avec le tri hiérarchique
Write-Host "Vérification du tri hiérarchique:"
Write-Host "Nombre de tâches: $($tasks.Count)"
Write-Host "Tâches racines:"
$rootTasks = $tasks | Where-Object { $null -eq $_.Parent }
$rootTasks | Format-Table -Property Id, Content, IsCompleted

Write-Host "Enfants de la tâche 1.1:"
$task11 = $tasks | Where-Object { $_.Id -eq "1.1" }
if ($task11) {
    $task11.Children | Format-Table -Property Id, Content, IsCompleted
} else {
    Write-Host "Tâche 1.1 non trouvée"
}

Write-Host "Enfants de la tâche 1.2:"
$task12 = $tasks | Where-Object { $_.Id -eq "1.2" }
if ($task12) {
    $task12.Children | Format-Table -Property Id, Content, IsCompleted
} else {
    Write-Host "Tâche 1.2 non trouvée"
}
