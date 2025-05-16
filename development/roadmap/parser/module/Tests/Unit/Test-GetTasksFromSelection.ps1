<#
.SYNOPSIS
    Tests unitaires pour la fonction Get-TasksFromSelection.
.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Get-TasksFromSelection.
.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-16
#>

# Importer la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "..\..\Functions\Public\Get-TasksFromSelection.ps1"
. $modulePath

# Définir les tests
Describe "Get-TasksFromSelection" {
    Context "Extraction de tâches simples" {
        It "Extrait correctement une tâche simple" {
            $selection = "- [ ] 1.1 Tâche simple"
            $tasks = Get-TasksFromSelection -Selection $selection
            
            $tasks.Count | Should -Be 1
            $tasks[0].Id | Should -Be "1.1"
            $tasks[0].Content | Should -Be "Tâche simple"
            $tasks[0].IsCompleted | Should -Be $false
        }
        
        It "Extrait correctement une tâche complétée" {
            $selection = "- [x] 1.2 Tâche complétée"
            $tasks = Get-TasksFromSelection -Selection $selection
            
            $tasks.Count | Should -Be 1
            $tasks[0].Id | Should -Be "1.2"
            $tasks[0].Content | Should -Be "Tâche complétée"
            $tasks[0].IsCompleted | Should -Be $true
        }
        
        It "Extrait correctement plusieurs tâches" {
            $selection = @"
- [ ] 1.1 Première tâche
- [ ] 1.2 Deuxième tâche
- [ ] 1.3 Troisième tâche
"@
            $tasks = Get-TasksFromSelection -Selection $selection
            
            $tasks.Count | Should -Be 3
            $tasks[0].Id | Should -Be "1.1"
            $tasks[1].Id | Should -Be "1.2"
            $tasks[2].Id | Should -Be "1.3"
        }
    }
    
    Context "Identification des tâches enfants" {
        It "Identifie correctement les tâches enfants par indentation" {
            $selection = @"
- [ ] 1.1 Tâche parent
  - [ ] 1.1.1 Tâche enfant
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren
            
            $tasks.Count | Should -Be 2
            $tasks[0].Children.Count | Should -Be 1
            $tasks[0].Children[0].Id | Should -Be "1.1.1"
            $tasks[1].Parent | Should -Be $tasks[0]
        }
        
        It "Identifie correctement les tâches enfants par identifiant" {
            $selection = @"
- [ ] 1 Tâche parent
- [ ] 1.1 Tâche enfant
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren
            
            $tasks.Count | Should -Be 2
            $tasks[0].Children.Count | Should -Be 1
            $tasks[0].Children[0].Id | Should -Be "1.1"
            $tasks[1].Parent | Should -Be $tasks[0]
        }
        
        It "Identifie correctement une hiérarchie complexe" {
            $selection = @"
- [ ] 1 Tâche racine
  - [ ] 1.1 Tâche enfant niveau 1
    - [ ] 1.1.1 Tâche enfant niveau 2
  - [ ] 1.2 Autre tâche enfant niveau 1
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren
            
            $tasks.Count | Should -Be 4
            $tasks[0].Children.Count | Should -Be 2
            $tasks[0].Children[0].Id | Should -Be "1.1"
            $tasks[0].Children[1].Id | Should -Be "1.2"
            $tasks[0].Children[0].Children.Count | Should -Be 1
            $tasks[0].Children[0].Children[0].Id | Should -Be "1.1.1"
        }
    }
    
    Context "Tri par hiérarchie" {
        It "Trie correctement les tâches par hiérarchie" {
            $selection = @"
- [ ] 2 Deuxième tâche racine
- [ ] 1 Première tâche racine
  - [ ] 1.2 Deuxième tâche enfant
  - [ ] 1.1 Première tâche enfant
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren -SortByHierarchy
            
            $tasks.Count | Should -Be 4
            $tasks[0].Id | Should -Be "1"
            $tasks[1].Id | Should -Be "1.1"
            $tasks[2].Id | Should -Be "1.2"
            $tasks[3].Id | Should -Be "2"
        }
    }
    
    Context "Gestion des cas particuliers" {
        It "Gère correctement une sélection vide" {
            $selection = ""
            $tasks = Get-TasksFromSelection -Selection $selection
            
            $tasks.Count | Should -Be 0
        }
        
        It "Gère correctement une sélection sans tâches" {
            $selection = "Ceci n'est pas une tâche"
            $tasks = Get-TasksFromSelection -Selection $selection
            
            $tasks.Count | Should -Be 0
        }
        
        It "Gère correctement les tâches sans identifiant" {
            $selection = "- [ ] Tâche sans identifiant"
            $tasks = Get-TasksFromSelection -Selection $selection
            
            $tasks.Count | Should -Be 1
            $tasks[0].Id | Should -Be ""
            $tasks[0].Content | Should -Be "Tâche sans identifiant"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -PassThru
