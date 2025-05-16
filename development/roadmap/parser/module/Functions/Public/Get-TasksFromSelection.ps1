<#
.SYNOPSIS
    Extrait les taches a partir d'une selection de texte.
.DESCRIPTION
    Cette fonction analyse une selection de texte pour en extraire les taches,
    en identifiant les taches enfants et en les triant par ordre hierarchique.
.PARAMETER Selection
    La selection de texte a analyser.
.PARAMETER IdentifyChildren
    Si specifie, identifie les taches enfants dans la selection.
.PARAMETER SortByHierarchy
    Si specifie, trie les taches par ordre hierarchique.
.EXAMPLE
    $tasks = Get-TasksFromSelection -Selection "- [ ] 1.1 Task parent`n  - [ ] 1.1.1 Task child"
    Extrait les taches de la selection.
.EXAMPLE
    $tasks = Get-TasksFromSelection -Selection "- [ ] 1.1 Task parent`n  - [ ] 1.1.1 Task child" -IdentifyChildren -SortByHierarchy
    Extrait les taches de la selection, identifie les taches enfants et les trie par ordre hierarchique.
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
                        $Result = Get-FlattenedTasks -TaskList $task.Children -Result $Result
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

# Exporter la fonction
# Vérifier si nous sommes dans un module
if ($MyInvocation.ScriptName -ne '' -and $MyInvocation.MyCommand.ModuleName) {
    # Nous sommes dans un module
    Export-ModuleMember -Function Get-TasksFromSelection
}
