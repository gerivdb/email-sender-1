<#
.SYNOPSIS
    Tests simples pour les workflows.

.DESCRIPTION
    Ce script contient des tests simples pour vÃ©rifier le bon fonctionnement des workflows.
    Ces tests vÃ©rifient que les workflows existent et qu'ils peuvent Ãªtre exÃ©cutÃ©s avec le paramÃ¨tre -WhatIf.
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
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "simple-test-roadmap.md"
@"
# Roadmap de test simple

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
Describe "Tests simples pour les workflows" {
    Context "VÃ©rification de l'existence des workflows" {
        It "Le workflow quotidien devrait exister" {
            Test-Path -Path $workflowQuotidienPath | Should -Be $true
        }
        
        It "Le workflow hebdomadaire devrait exister" {
            Test-Path -Path $workflowHebdomadairePath | Should -Be $true
        }
        
        It "Le workflow mensuel devrait exister" {
            Test-Path -Path $workflowMensuelPath | Should -Be $true
        }
        
        It "Le script d'installation des tÃ¢ches planifiÃ©es devrait exister" {
            Test-Path -Path $installScheduledTasksPath | Should -Be $true
        }
    }
    
    Context "VÃ©rification de l'exÃ©cution des workflows" {
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
        }
        
        AfterAll {
            # Supprimer le mock
            Remove-Item -Path function:global:Invoke-IntegratedManager -ErrorAction SilentlyContinue
        }
        
        It "Le workflow quotidien devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $workflowQuotidienPath -RoadmapPath $testRoadmapPath -LogPath $testDir -WhatIf } | Should -Not -Throw
        }
        
        It "Le workflow hebdomadaire devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $workflowHebdomadairePath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir -WhatIf } | Should -Not -Throw
        }
        
        It "Le workflow mensuel devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $workflowMensuelPath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir -WhatIf } | Should -Not -Throw
        }
        
        It "Le script d'installation des tÃ¢ches planifiÃ©es devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $installScheduledTasksPath -WhatIf } | Should -Not -Throw
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
