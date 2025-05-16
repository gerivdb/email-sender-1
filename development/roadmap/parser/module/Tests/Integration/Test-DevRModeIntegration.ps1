<#
.SYNOPSIS
    Tests d'intégration pour le mode DEV-R amélioré.
.DESCRIPTION
    Ce script contient des tests d'intégration pour le mode DEV-R amélioré.
.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-16
#>

# Créer un fichier de roadmap temporaire pour les tests
$tempRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test-roadmap.md"
$roadmapContent = @"
# Test Roadmap

## Section 1

- [ ] 1.1 Première tâche
  - [ ] 1.1.1 Sous-tâche 1
  - [ ] 1.1.2 Sous-tâche 2
- [ ] 1.2 Deuxième tâche
  - [ ] 1.2.1 Sous-tâche 1
  - [ ] 1.2.2 Sous-tâche 2

## Section 2

- [ ] 2.1 Troisième tâche
- [ ] 2.2 Quatrième tâche
"@
Set-Content -Path $tempRoadmapPath -Value $roadmapContent

# Créer un répertoire de projet temporaire pour les tests
$tempProjectPath = Join-Path -Path $TestDrive -ChildPath "project"
New-Item -Path $tempProjectPath -ItemType Directory -Force | Out-Null

# Créer un répertoire de tests temporaire pour les tests
$tempTestsPath = Join-Path -Path $TestDrive -ChildPath "tests"
New-Item -Path $tempTestsPath -ItemType Directory -Force | Out-Null

# Créer un répertoire de sortie temporaire pour les tests
$tempOutputPath = Join-Path -Path $TestDrive -ChildPath "output"
New-Item -Path $tempOutputPath -ItemType Directory -Force | Out-Null

# Importer les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$getTasksFromSelectionPath = Join-Path -Path $scriptPath -ChildPath "..\..\Functions\Public\Get-TasksFromSelection.ps1"
$invokeTasksProcessingPath = Join-Path -Path $scriptPath -ChildPath "..\..\Functions\Public\Invoke-TasksProcessing.ps1"
. $getTasksFromSelectionPath
. $invokeTasksProcessingPath

# Définir les tests
Describe "Mode DEV-R amélioré - Tests d'intégration" {
    Context "Traitement d'une sélection" {
        It "Traite correctement une sélection simple" {
            $selection = "- [ ] 1.1 Première tâche"
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
        
        It "Traite correctement une sélection avec des tâches enfants" {
            $selection = @"
- [ ] 1.1 Première tâche
  - [ ] 1.1.1 Sous-tâche 1
  - [ ] 1.1.2 Sous-tâche 2
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren
            
            $processedTasks = @()
            $processFunction = {
                param($task)
                $processedTasks += $task
            }
            
            $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction
            
            $processedTasks.Count | Should -Be 3
            $processedTasks[0].Id | Should -Be "1.1"
            $processedTasks[1].Id | Should -Be "1.1.1"
            $processedTasks[2].Id | Should -Be "1.1.2"
        }
        
        It "Traite correctement une sélection avec des tâches enfants en commençant par les enfants" {
            $selection = @"
- [ ] 1.1 Première tâche
  - [ ] 1.1.1 Sous-tâche 1
  - [ ] 1.1.2 Sous-tâche 2
"@
            $tasks = Get-TasksFromSelection -Selection $selection -IdentifyChildren
            
            $processedTasks = @()
            $processFunction = {
                param($task)
                $processedTasks += $task
            }
            
            $result = Invoke-TasksProcessing -Tasks $tasks -ProcessFunction $processFunction -ChildrenFirst
            
            $processedTasks.Count | Should -Be 3
            $processedTasks[0].Id | Should -Be "1.1.1"
            $processedTasks[1].Id | Should -Be "1.1.2"
            $processedTasks[2].Id | Should -Be "1.1"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -PassThru
