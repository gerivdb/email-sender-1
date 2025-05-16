<#
.SYNOPSIS
    Tests unitaires pour la fonction Invoke-TasksProcessing.
.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Invoke-TasksProcessing.
.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-16
#>

# Importer les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$getTasksFromSelectionPath = Join-Path -Path $scriptPath -ChildPath "..\..\Functions\Public\Get-TasksFromSelection.ps1"
$invokeTasksProcessingPath = Join-Path -Path $scriptPath -ChildPath "..\..\Functions\Public\Invoke-TasksProcessing.ps1"
. $getTasksFromSelectionPath
. $invokeTasksProcessingPath

# Définir les tests
Describe "Invoke-TasksProcessing" {
    Context "Traitement de tâches simples" {
        It "Traite correctement une tâche simple" {
            $selection = "- [ ] 1.1 Tâche simple"
            $tasks = Get-TasksFromSelection -Selection $selection
            
            $processedTasks = @()
            $processFunction = {
                param($task)
                $processedTasks += $task
            }
            
            $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction
            
            $processedTasks.Count | Should -Be 1
            $processedTasks[0].Id | Should -Be "1.1"
        }
        
        It "Traite correctement plusieurs tâches" {
            $selection = @"
- [ ] 1.1 Première tâche
- [ ] 1.2 Deuxième tâche
- [ ] 1.3 Troisième tâche
"@
            $tasks = Get-TasksFromSelection -Selection $selection
            
            $processedTasks = @()
            $processFunction = {
                param($task)
                $processedTasks += $task
            }
            
            $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction
            
            $processedTasks.Count | Should -Be 3
            $processedTasks[0].Id | Should -Be "1.1"
            $processedTasks[1].Id | Should -Be "1.2"
            $processedTasks[2].Id | Should -Be "1.3"
        }
    }
    
    Context "Traitement des tâches enfants d'abord" {
        It "Traite les tâches enfants avant les tâches parentes" {
            $selection = @"
- [ ] 1 Tâche parent
  - [ ] 1.1 Tâche enfant
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren
            
            $processedTasks = @()
            $processFunction = {
                param($task)
                $processedTasks += $task
            }
            
            $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction -ChildrenFirst
            
            $processedTasks.Count | Should -Be 2
            $processedTasks[0].Id | Should -Be "1.1"
            $processedTasks[1].Id | Should -Be "1"
        }
        
        It "Traite les tâches parentes avant les tâches enfants par défaut" {
            $selection = @"
- [ ] 1 Tâche parent
  - [ ] 1.1 Tâche enfant
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren
            
            $processedTasks = @()
            $processFunction = {
                param($task)
                $processedTasks += $task
            }
            
            $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction
            
            $processedTasks.Count | Should -Be 2
            $processedTasks[0].Id | Should -Be "1"
            $processedTasks[1].Id | Should -Be "1.1"
        }
        
        It "Traite correctement une hiérarchie complexe avec ChildrenFirst" {
            $selection = @"
- [ ] 1 Tâche racine
  - [ ] 1.1 Tâche enfant niveau 1
    - [ ] 1.1.1 Tâche enfant niveau 2
  - [ ] 1.2 Autre tâche enfant niveau 1
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren
            
            $processedTasks = @()
            $processFunction = {
                param($task)
                $processedTasks += $task
            }
            
            $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction -ChildrenFirst
            
            $processedTasks.Count | Should -Be 4
            $processedTasks[0].Id | Should -Be "1.1.1"
            $processedTasks[1].Id | Should -Be "1.1"
            $processedTasks[2].Id | Should -Be "1.2"
            $processedTasks[3].Id | Should -Be "1"
        }
    }
    
    Context "Gestion des cas particuliers" {
        It "Gère correctement un tableau de tâches vide" {
            $tasks = @()
            
            $processedTasks = @()
            $processFunction = {
                param($task)
                $processedTasks += $task
            }
            
            $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction
            
            $processedTasks.Count | Should -Be 0
        }
        
        It "Retourne les tâches traitées" {
            $selection = "- [ ] 1.1 Tâche simple"
            $tasks = Get-TasksFromSelection -Selection $selection
            
            $processFunction = {
                param($task)
                # Ne rien faire
            }
            
            $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction
            
            $result.Count | Should -Be 1
            $result[0].Id | Should -Be "1.1"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -PassThru
