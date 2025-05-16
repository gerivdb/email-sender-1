<#
.SYNOPSIS
    Tests pour la fonction Get-TasksFromSelection.
.DESCRIPTION
    Ce fichier contient des tests unitaires pour la fonction Get-TasksFromSelection.
.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-16
#>

# Définir la fonction directement dans le fichier de test
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

Describe "Get-TasksFromSelection" {
    Context "Extraction de taches simples" {
        It "Devrait extraire une tache simple" {
            $selection = "- [ ] 1.1 Task simple"
            $tasks = Get-TasksFromSelection -Selection $selection

            $tasks.Count | Should -Be 1
            $tasks[0].Id | Should -Be "1.1"
            $tasks[0].Content | Should -Be "Task simple"
            $tasks[0].IsCompleted | Should -Be $false
        }

        It "Devrait extraire une tache completee" {
            $selection = "- [x] 1.1 Task completed"
            $tasks = Get-TasksFromSelection -Selection $selection

            $tasks.Count | Should -Be 1
            $tasks[0].Id | Should -Be "1.1"
            $tasks[0].Content | Should -Be "Task completed"
            $tasks[0].IsCompleted | Should -Be $true
        }

        It "Devrait extraire plusieurs taches" {
            $selection = @"
- [ ] 1.1 First task
- [ ] 1.2 Second task
- [ ] 1.3 Third task
"@
            $tasks = Get-TasksFromSelection -Selection $selection

            $tasks.Count | Should -Be 3
            $tasks[0].Id | Should -Be "1.1"
            $tasks[1].Id | Should -Be "1.2"
            $tasks[2].Id | Should -Be "1.3"
        }
    }

    Context "Identification des taches enfants" {
        It "Devrait identifier les taches enfants par indentation" {
            $selection = @"
- [ ] 1.1 Parent task
  - [ ] 1.1.1 Child task
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren

            $tasks.Count | Should -Be 2
            $tasks[0].Children.Count | Should -Be 1
            $tasks[0].Children[0].Id | Should -Be "1.1.1"
            $tasks[1].Parent | Should -Not -BeNullOrEmpty
        }

        It "Devrait identifier les taches enfants par identifiant" {
            $selection = @"
- [ ] 1.1 Parent task
- [ ] 1.1.1 Child task
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren

            $tasks.Count | Should -Be 2
            $tasks[0].Children.Count | Should -Be 1
            $tasks[0].Children[0].Id | Should -Be "1.1.1"
            $tasks[1].Parent | Should -Not -BeNullOrEmpty
        }

        It "Devrait identifier plusieurs niveaux de taches enfants" {
            $selection = @"
- [ ] 1 Grandparent task
  - [ ] 1.1 Parent task
    - [ ] 1.1.1 Child task
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren

            $tasks.Count | Should -Be 3
            $tasks[0].Children.Count | Should -Be 1
            $tasks[0].Children[0].Children.Count | Should -Be 1
            $tasks[0].Children[0].Children[0].Id | Should -Be "1.1.1"
        }
    }

    Context "Tri par hierarchie" {
        It "Devrait trier les taches par hierarchie" {
            $selection = @"
- [ ] 1.1 Parent task 1
  - [ ] 1.1.1 Child task 1
- [ ] 1.2 Parent task 2
  - [ ] 1.2.1 Child task 2
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren -SortByHierarchy

            $tasks.Count | Should -Be 4
            $tasks[0].Id | Should -Be "1.1"
            $tasks[1].Id | Should -Be "1.1.1"
            $tasks[2].Id | Should -Be "1.2"
            $tasks[3].Id | Should -Be "1.2.1"
        }
    }

    Context "Gestion des cas particuliers" {
        It "Devrait gerer les taches sans identifiant" {
            $selection = "- [ ] Task without ID"
            $tasks = Get-TasksFromSelection -Selection $selection

            $tasks.Count | Should -Be 1
            $tasks[0].Id | Should -Be ""
            $tasks[0].Content | Should -Be "Task without ID"
        }

        It "Devrait gerer les taches avec des caracteres speciaux" {
            $selection = "- [ ] 1.1 Task with special characters: @ # $ %"
            $tasks = Get-TasksFromSelection -Selection $selection

            $tasks.Count | Should -Be 1
            $tasks[0].Id | Should -Be "1.1"
            $tasks[0].Content | Should -Be "Task with special characters: @ # $ %"
        }

        It "Devrait gerer les taches avec des symboles differents" {
            $selection = @"
* [ ] 1.1 Task with asterisk
+ [ ] 1.2 Task with plus
"@
            $tasks = Get-TasksFromSelection -Selection $selection

            $tasks.Count | Should -Be 2
            $tasks[0].Id | Should -Be "1.1"
            $tasks[1].Id | Should -Be "1.2"
        }
    }
}
