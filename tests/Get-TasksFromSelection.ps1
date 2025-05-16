<#
.SYNOPSIS
    Extrait les tâches à partir d'une sélection de texte.
.DESCRIPTION
    Cette fonction analyse une sélection de texte pour en extraire les tâches,
    en identifiant les tâches enfants et en les triant par ordre hiérarchique.
.PARAMETER Selection
    La sélection de texte à analyser.
.PARAMETER IdentifyChildren
    Si spécifié, identifie les tâches enfants dans la sélection.
.PARAMETER SortByHierarchy
    Si spécifié, trie les tâches par ordre hiérarchique.
.EXAMPLE
    $tasks = Get-TasksFromSelection -Selection "- [ ] 1.1 Tâche parent`n  - [ ] 1.1.1 Tâche enfant"
    Extrait les tâches de la sélection.
.EXAMPLE
    $tasks = Get-TasksFromSelection -Selection "- [ ] 1.1 Tâche parent`n  - [ ] 1.1.1 Tâche enfant" -IdentifyChildren -SortByHierarchy
    Extrait les tâches de la sélection, identifie les tâches enfants et les trie par ordre hiérarchique.
.OUTPUTS
    System.Collections.ArrayList
#>
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
                Id = $taskId
                Content = $taskContent
                IsCompleted = $isCompleted
                Indentation = $indentation
                Line = $line
                Children = @()
                Parent = $null
                Level = if ($taskId -match '\.') { ($taskId -split '\.').Count } else { 1 }
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
                if ($task.Parent -eq $null) {
                    $Result += $task
                    if ($task.Children.Count -gt 0) {
                        $Result = Get-FlattenedTasks -TaskList $task.Children -Result $Result
                    }
                }
            }
            
            return $Result
        }
        
        # Obtenir les tâches racines (sans parent)
        $rootTasks = $tasks | Where-Object { $_.Parent -eq $null }
        
        # Aplatir la hiérarchie
        $tasks = Get-FlattenedTasks -TaskList $rootTasks
    }
    
    return $tasks
}
