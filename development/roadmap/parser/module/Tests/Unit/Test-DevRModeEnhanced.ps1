<#
.SYNOPSIS
    Tests unitaires pour le script dev-r-mode-enhanced.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script dev-r-mode-enhanced.ps1.
.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-16
#>

# Définir les tests
Describe "dev-r-mode-enhanced.ps1" {
    BeforeAll {
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
        
        # Chemin vers le script à tester
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $devRModeEnhancedPath = Join-Path -Path $scriptPath -ChildPath "..\..\..\modes\dev-r\dev-r-mode-enhanced.ps1"
        
        # Créer un mock pour Invoke-RoadmapDevelopment
        function Invoke-RoadmapDevelopment {
            param(
                [Parameter(Mandatory = $true)]
                [string]$FilePath,
                
                [Parameter(Mandatory = $false)]
                [string]$TaskIdentifier,
                
                [Parameter(Mandatory = $false)]
                [string]$ProjectPath,
                
                [Parameter(Mandatory = $false)]
                [string]$TestsPath,
                
                [Parameter(Mandatory = $false)]
                [string]$OutputPath,
                
                [Parameter(Mandatory = $false)]
                [bool]$AutoCommit = $false,
                
                [Parameter(Mandatory = $false)]
                [bool]$UpdateRoadmap = $true,
                
                [Parameter(Mandatory = $false)]
                [bool]$GenerateTests = $true
            )
            
            return @{
                TaskIdentifier = $TaskIdentifier
                Success = $true
                NextSteps = @("Étape suivante 1", "Étape suivante 2")
                FailedTasks = @()
            }
        }
        
        # Créer un mock pour Get-TasksFromSelection
        function Get-TasksFromSelection {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Selection,
                
                [Parameter(Mandatory = $false)]
                [switch]$IdentifyChildren,
                
                [Parameter(Mandatory = $false)]
                [switch]$SortByHierarchy
            )
            
            $tasks = @(
                [PSCustomObject]@{
                    Id = "1.1"
                    Content = "Première tâche"
                    IsCompleted = $false
                    Indentation = 0
                    Line = "- [ ] 1.1 Première tâche"
                    Children = @()
                    Parent = $null
                    Level = 2
                },
                [PSCustomObject]@{
                    Id = "1.1.1"
                    Content = "Sous-tâche 1"
                    IsCompleted = $false
                    Indentation = 2
                    Line = "  - [ ] 1.1.1 Sous-tâche 1"
                    Children = @()
                    Parent = $null
                    Level = 3
                }
            )
            
            if ($IdentifyChildren) {
                $tasks[0].Children = @($tasks[1])
                $tasks[1].Parent = $tasks[0]
            }
            
            return $tasks
        }
        
        # Créer un mock pour Invoke-TasksProcessing
        function Invoke-TasksProcessing {
            param(
                [Parameter(Mandatory = $true)]
                [array]$Tasks,
                
                [Parameter(Mandatory = $true)]
                [scriptblock]$ProcessFunction,
                
                [Parameter(Mandatory = $false)]
                [switch]$ChildrenFirst,
                
                [Parameter(Mandatory = $false)]
                [switch]$StepByStep
            )
            
            $result = @()
            
            if ($ChildrenFirst) {
                foreach ($task in $Tasks) {
                    if ($task.Children.Count -gt 0) {
                        foreach ($child in $task.Children) {
                            $taskResult = & $ProcessFunction $child
                            $result += $child
                        }
                    }
                    $taskResult = & $ProcessFunction $task
                    $result += $task
                }
            } else {
                foreach ($task in $Tasks) {
                    $taskResult = & $ProcessFunction $task
                    $result += $task
                    if ($task.Children.Count -gt 0) {
                        foreach ($child in $task.Children) {
                            $taskResult = & $ProcessFunction $child
                            $result += $child
                        }
                    }
                }
            }
            
            return $result
        }
        
        # Créer un mock pour Write-LogInfo
        function Write-LogInfo {
            param(
                [Parameter(Mandatory = $true, Position = 0)]
                [string]$Message
            )
            
            # Ne rien faire
        }
        
        # Créer un mock pour Write-LogDebug
        function Write-LogDebug {
            param(
                [Parameter(Mandatory = $true, Position = 0)]
                [string]$Message
            )
            
            # Ne rien faire
        }
        
        # Créer un mock pour Write-LogWarning
        function Write-LogWarning {
            param(
                [Parameter(Mandatory = $true, Position = 0)]
                [string]$Message
            )
            
            # Ne rien faire
        }
        
        # Créer un mock pour Write-LogError
        function Write-LogError {
            param(
                [Parameter(Mandatory = $true, Position = 0)]
                [string]$Message
            )
            
            # Ne rien faire
        }
        
        # Créer un mock pour Set-LoggingLevel
        function Set-LoggingLevel {
            param(
                [Parameter(Mandatory = $true)]
                [ValidateSet("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")]
                [string]$Level
            )
            
            # Ne rien faire
        }
        
        # Créer un mock pour Get-DefaultConfiguration
        function Get-DefaultConfiguration {
            return @{
                General = @{
                    LogLevel = "INFO"
                }
                Modes = @{
                    "DEV-R" = @{
                        GenerateTests = $true
                        UpdateRoadmap = $true
                    }
                }
            }
        }
        
        # Créer un mock pour Assert-ValidFile
        function Assert-ValidFile {
            param(
                [Parameter(Mandatory = $true)]
                [string]$FilePath,
                
                [Parameter(Mandatory = $false)]
                [string]$FileType,
                
                [Parameter(Mandatory = $false)]
                [string]$ParameterName = "FilePath",
                
                [Parameter(Mandatory = $false)]
                [string]$ErrorMessage
            )
            
            # Ne rien faire
        }
        
        # Créer un mock pour Assert-ValidDirectory
        function Assert-ValidDirectory {
            param(
                [Parameter(Mandatory = $true)]
                [string]$DirectoryPath,
                
                [Parameter(Mandatory = $false)]
                [string]$ParameterName = "DirectoryPath",
                
                [Parameter(Mandatory = $false)]
                [string]$ErrorMessage
            )
            
            # Ne rien faire
        }
        
        # Créer un mock pour Assert-ValidTaskIdentifier
        function Assert-ValidTaskIdentifier {
            param(
                [Parameter(Mandatory = $true)]
                [string]$TaskIdentifier,
                
                [Parameter(Mandatory = $false)]
                [string]$ParameterName = "TaskIdentifier",
                
                [Parameter(Mandatory = $false)]
                [string]$ErrorMessage
            )
            
            # Ne rien faire
        }
        
        # Créer un mock pour Invoke-WithErrorHandling
        function Invoke-WithErrorHandling {
            param(
                [Parameter(Mandatory = $true)]
                [scriptblock]$Action,
                
                [Parameter(Mandatory = $false)]
                [string]$ErrorMessage = "Une erreur s'est produite lors de l'exécution de l'action.",
                
                [Parameter(Mandatory = $false)]
                [string]$LogFile,
                
                [Parameter(Mandatory = $false)]
                [int]$ExitCode = 1,
                
                [Parameter(Mandatory = $false)]
                [bool]$ExitOnError = $false
            )
            
            return & $Action
        }
        
        # Exporter les fonctions mock
        Export-ModuleMember -Function Invoke-RoadmapDevelopment, Get-TasksFromSelection, Invoke-TasksProcessing, Write-LogInfo, Write-LogDebug, Write-LogWarning, Write-LogError, Set-LoggingLevel, Get-DefaultConfiguration, Assert-ValidFile, Assert-ValidDirectory, Assert-ValidTaskIdentifier, Invoke-WithErrorHandling
    }
    
    Context "Traitement standard" {
        It "Traite correctement une tâche spécifique" {
            # Appeler le script avec les paramètres de test
            $result = & $devRModeEnhancedPath -FilePath $tempRoadmapPath -TaskIdentifier "1.1" -ProjectPath $tempProjectPath -TestsPath $tempTestsPath -OutputPath $tempOutputPath -LogLevel "INFO"
            
            $result | Should -Not -BeNullOrEmpty
            $result.TaskIdentifier | Should -Be "1.1"
            $result.Success | Should -Be $true
        }
    }
    
    Context "Traitement de la sélection" {
        It "Traite correctement une sélection" {
            # Appeler le script avec les paramètres de test
            $selection = "- [ ] 1.1 Première tâche`n  - [ ] 1.1.1 Sous-tâche 1"
            $result = & $devRModeEnhancedPath -FilePath $tempRoadmapPath -ProcessSelection -Selection $selection -ProjectPath $tempProjectPath -TestsPath $tempTestsPath -OutputPath $tempOutputPath -LogLevel "INFO"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Traite correctement une sélection avec ChildrenFirst" {
            # Appeler le script avec les paramètres de test
            $selection = "- [ ] 1.1 Première tâche`n  - [ ] 1.1.1 Sous-tâche 1"
            $result = & $devRModeEnhancedPath -FilePath $tempRoadmapPath -ProcessSelection -Selection $selection -ChildrenFirst -ProjectPath $tempProjectPath -TestsPath $tempTestsPath -OutputPath $tempOutputPath -LogLevel "INFO"
            
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -PassThru
