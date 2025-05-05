<#
.SYNOPSIS
    Tests unitaires standards pour les workflows.

.DESCRIPTION
    Ce script contient des tests unitaires standards pour vÃ©rifier le bon fonctionnement des workflows.
    Ces tests utilisent des mocks pour simuler les dÃ©pendances et vÃ©rifier que les workflows fonctionnent correctement.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# DÃ©finir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))
$workflowQuotidienPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\workflow-quotidien.ps1"
$workflowHebdomadairePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\workflow-hebdomadaire.ps1"
$workflowMensuelPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\workflow-mensuel.ps1"
$installScheduledTasksPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\install-scheduled-tasks.ps1"

# CrÃ©er un rÃ©pertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "unit-test-roadmap.md"
@"
# Roadmap de test unitaire

## TÃ¢che 1: Test des workflows

### Description
Cette tÃ¢che vise Ã  tester les workflows.

### Sous-tÃ¢ches
- [ ] **1.1** Tester le workflow quotidien
- [ ] **1.2** Tester le workflow hebdomadaire
- [ ] **1.3** Tester le workflow mensuel
- [ ] **1.4** Tester l'installation des tÃ¢ches planifiÃ©es
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# DÃ©finir les tests
Describe "Tests unitaires standards pour les workflows" {
    BeforeAll {
        # CrÃ©er un mock pour le gestionnaire intÃ©grÃ©
        function global:Invoke-IntegratedManager {
            param (
                [string]$Mode,
                [string]$RoadmapPath,
                [string]$TaskIdentifier,
                [string]$OutputPath,
                [string]$ReportFormat,
                [string]$TargetFormat,
                [int]$DaysToForecast,
                [switch]$Force,
                [string]$ConfigPath,
                [switch]$WhatIf
            )
            
            return @{
                Success = $true
                Mode = $Mode
                RoadmapPath = $RoadmapPath
                TaskIdentifier = $TaskIdentifier
                OutputPath = $OutputPath
                ReportFormat = $ReportFormat
                TargetFormat = $TargetFormat
                DaysToForecast = $DaysToForecast
                Force = $Force
                ConfigPath = $ConfigPath
                WhatIf = $WhatIf
            }
        }
        
        # CrÃ©er un mock pour Write-Log
        function global:Write-Log {
            param (
                [string]$Message,
                [string]$Level = "INFO"
            )
            
            # Simuler la journalisation
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logMessage = "[$timestamp] [$Level] $Message"
            
            return $logMessage
        }
        
        # CrÃ©er un mock pour Test-Path
        Mock Test-Path {
            if ($Path -eq $testRoadmapPath) {
                return $true
            } elseif ($Path -match "workflow-quotidien.ps1") {
                return $true
            } elseif ($Path -match "workflow-hebdomadaire.ps1") {
                return $true
            } elseif ($Path -match "workflow-mensuel.ps1") {
                return $true
            } elseif ($Path -match "install-scheduled-tasks.ps1") {
                return $true
            } elseif ($Path -match "integrated-manager.ps1") {
                return $true
            } elseif ($Path -match "temp") {
                return $true
            } else {
                return $false
            }
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour New-Item
        Mock New-Item {
            # Ne rien faire, juste simuler la crÃ©ation
            return [PSCustomObject]@{
                FullName = $Path
                Exists = $true
            }
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour Join-Path
        Mock Join-Path {
            return "$Path\$ChildPath"
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour Get-Date
        Mock Get-Date {
            return [DateTime]::Parse("2023-06-01")
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour Out-File
        Mock Out-File {
            # Ne rien faire, juste simuler l'Ã©criture
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour Get-ScheduledTask
        Mock Get-ScheduledTask {
            return @(
                [PSCustomObject]@{
                    TaskName = "RoadmapManager-Quotidien"
                    State = "Ready"
                },
                [PSCustomObject]@{
                    TaskName = "RoadmapManager-Hebdomadaire"
                    State = "Ready"
                },
                [PSCustomObject]@{
                    TaskName = "RoadmapManager-Mensuel"
                    State = "Ready"
                }
            )
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour Register-ScheduledTask
        Mock Register-ScheduledTask {
            return [PSCustomObject]@{
                TaskName = $TaskName
                State = "Ready"
            }
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour Unregister-ScheduledTask
        Mock Unregister-ScheduledTask {
            # Ne rien faire, juste simuler la suppression
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour New-ScheduledTaskAction
        Mock New-ScheduledTaskAction {
            return [PSCustomObject]@{
                Execute = $Execute
                Argument = $Argument
                WorkingDirectory = $WorkingDirectory
            }
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour New-ScheduledTaskTrigger
        Mock New-ScheduledTaskTrigger {
            return [PSCustomObject]@{
                DaysOfWeek = $DaysOfWeek
                At = $At
                DaysOfMonth = $DaysOfMonth
            }
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour New-ScheduledTaskSettingsSet
        Mock New-ScheduledTaskSettingsSet {
            return [PSCustomObject]@{
                StartWhenAvailable = $StartWhenAvailable
                DontStopOnIdleEnd = $DontStopOnIdleEnd
                AllowStartIfOnBatteries = $AllowStartIfOnBatteries
                DontStopIfGoingOnBatteries = $DontStopIfGoingOnBatteries
                MultipleInstances = $MultipleInstances
            }
        } -ModuleName "Test-UnitWorkflows"
        
        # CrÃ©er un mock pour New-ScheduledTaskPrincipal
        Mock New-ScheduledTaskPrincipal {
            return [PSCustomObject]@{
                UserId = $UserId
                LogonType = $LogonType
                RunLevel = $RunLevel
            }
        } -ModuleName "Test-UnitWorkflows"
    }
    
    AfterAll {
        # Supprimer les mocks
        Remove-Item -Path function:global:Invoke-IntegratedManager -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Write-Log -ErrorAction SilentlyContinue
    }
    
    Context "Workflow quotidien" {
        It "Le workflow quotidien devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            $result = & $workflowQuotidienPath -RoadmapPath $testRoadmapPath -LogPath $testDir
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le workflow quotidien devrait pouvoir Ãªtre exÃ©cutÃ© avec un chemin de roadmap personnalisÃ©" {
            $result = & $workflowQuotidienPath -RoadmapPath "$testDir\custom-roadmap.md" -LogPath $testDir
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le workflow quotidien devrait pouvoir Ãªtre exÃ©cutÃ© avec un rÃ©pertoire de journalisation personnalisÃ©" {
            $result = & $workflowQuotidienPath -RoadmapPath $testRoadmapPath -LogPath "$testDir\logs"
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
    }
    
    Context "Workflow hebdomadaire" {
        It "Le workflow hebdomadaire devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            $result = & $workflowHebdomadairePath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le workflow hebdomadaire devrait pouvoir Ãªtre exÃ©cutÃ© avec plusieurs chemins de roadmap" {
            $roadmapPaths = @($testRoadmapPath, "$testDir\custom-roadmap.md")
            $result = & $workflowHebdomadairePath -RoadmapPaths $roadmapPaths -OutputPath $testDir -LogPath $testDir
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le workflow hebdomadaire devrait pouvoir Ãªtre exÃ©cutÃ© avec un rÃ©pertoire de sortie personnalisÃ©" {
            $result = & $workflowHebdomadairePath -RoadmapPaths @($testRoadmapPath) -OutputPath "$testDir\output" -LogPath $testDir
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
    }
    
    Context "Workflow mensuel" {
        It "Le workflow mensuel devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            $result = & $workflowMensuelPath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le workflow mensuel devrait pouvoir Ãªtre exÃ©cutÃ© avec plusieurs chemins de roadmap" {
            $roadmapPaths = @($testRoadmapPath, "$testDir\custom-roadmap.md")
            $result = & $workflowMensuelPath -RoadmapPaths $roadmapPaths -OutputPath $testDir -LogPath $testDir
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le workflow mensuel devrait pouvoir Ãªtre exÃ©cutÃ© avec un rÃ©pertoire de sortie personnalisÃ©" {
            $result = & $workflowMensuelPath -RoadmapPaths @($testRoadmapPath) -OutputPath "$testDir\output" -LogPath $testDir
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
    }
    
    Context "Installation des tÃ¢ches planifiÃ©es" {
        It "Le script d'installation des tÃ¢ches planifiÃ©es devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            $result = & $installScheduledTasksPath -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Le script d'installation des tÃ¢ches planifiÃ©es devrait pouvoir Ãªtre exÃ©cutÃ© avec un prÃ©fixe personnalisÃ©" {
            $result = & $installScheduledTasksPath -TaskPrefix "CustomPrefix" -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Le script d'installation des tÃ¢ches planifiÃ©es devrait pouvoir Ãªtre exÃ©cutÃ© avec le paramÃ¨tre Force" {
            $result = & $installScheduledTasksPath -Force -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
