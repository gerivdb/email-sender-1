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

    # Initialiser la liste des tâches
    $tasks = New-Object System.Collections.ArrayList

    # Diviser la sélection en lignes
    $lines = $Selection -split "`r?`n"

    # Analyser chaque ligne pour extraire les tâches
    foreach ($line in $lines) {
        # Vérifier si la ligne contient une tâche
        if ($line -match '^\s*[-*+]\s*\[([ xX])\]\s*(.+)$') {
            $isCompleted = $matches[1] -ne ' '
            $taskContent = $matches[2]

            # Déterminer l'indentation
            $indentation = 0
            if ($line -match '^(\s+)') {
                $indentation = $matches[1].Length
            }

            # Extraire l'identifiant de la tâche si présent
            $taskId = ""
            if ($taskContent -match '^(\d+(\.\d+)*)\s+(.+)$') {
                $taskId = $matches[1]
                $taskContent = $matches[3]
            }

            # Créer l'objet tâche
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

            # Ajouter la tâche à la liste
            [void]$tasks.Add($task)
        }
    }

    # Identifier les tâches enfants si demandé
    if ($IdentifyChildren) {
        for ($i = 0; $i -lt $tasks.Count; $i++) {
            $currentTask = $tasks[$i]

            # Parcourir les tâches suivantes pour trouver les enfants
            for ($j = $i + 1; $j -lt $tasks.Count; $j++) {
                $nextTask = $tasks[$j]

                # Vérifier si la tâche suivante est un enfant de la tâche courante
                if ($nextTask.Id -match "^$([regex]::Escape($currentTask.Id))\.\d+$" -or
                    $nextTask.Indentation -gt $currentTask.Indentation) {
                    $nextTask.Parent = $currentTask
                    $currentTask.Children += $nextTask
                }
                # Si on trouve une tâche de même niveau ou de niveau supérieur, arrêter la recherche
                elseif ($nextTask.Indentation -le $currentTask.Indentation) {
                    break
                }
            }
        }
    }

    # Trier les tâches par ordre hiérarchique si demandé
    if ($SortByHierarchy) {
        # Fonction récursive pour aplatir la hiérarchie
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
                        $Result = Get-FlattenedTasks -TaskList $task.Children -Result $Result
                    }
                }
            }

            return $Result
        }

        # Obtenir les tâches racines (sans parent)
        $rootTasks = $tasks | Where-Object { $null -eq $_.Parent }

        # Aplatir la hiérarchie
        $tasks = Get-FlattenedTasks -TaskList $rootTasks
    }

    return $tasks
}

# Définir l'encodage
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tester la fonction
$selection = "- [ ] 1.1 Task simple"
$tasks = Get-TasksFromSelection -Selection $selection

# Afficher les résultats
$tasks | Format-Table -Property Id, Content, IsCompleted

# Tester avec des caractères ASCII uniquement
$selection = @"
- [ ] 1.1 Task parent
  - [ ] 1.1.1 Task child
- [ ] 1.2 Another task
  - [ ] 1.2.1 Another child
"@
$tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren

# Afficher les résultats
Write-Host "Tâches avec leurs enfants :"
foreach ($task in $tasks) {
    if ($null -eq $task.Parent) {
        Write-Host "- $($task.Id) $($task.Content)"
        foreach ($child in $task.Children) {
            Write-Host "  - $($child.Id) $($child.Content)"
        }
    }
}

# Tester le tri hiérarchique
$tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren -SortByHierarchy

# Afficher les résultats
Write-Host "`nTâches triées par hiérarchie :"
$tasks | Format-Table -Property Id, Content, IsCompleted, Level
