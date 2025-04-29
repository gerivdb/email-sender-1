<#
.SYNOPSIS
    Tests simples pour les workflows.

.DESCRIPTION
    Ce script contient des tests simples pour vérifier le bon fonctionnement des workflows.
    Ces tests vérifient que les workflows existent et qu'ils peuvent être exécutés avec le paramètre -WhatIf.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Définir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))
$workflowQuotidienPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\workflow-quotidien.ps1"
$workflowHebdomadairePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\workflow-hebdomadaire.ps1"
$workflowMensuelPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\workflow-mensuel.ps1"
$installScheduledTasksPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\install-scheduled-tasks.ps1"

# Créer un répertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "simple-test-roadmap.md"
@"
# Roadmap de test simple

## Tâche 1: Test des workflows

### Description
Cette tâche vise à tester les workflows.

### Sous-tâches
- [ ] **1.1** Tester le workflow quotidien
- [ ] **1.2** Tester le workflow hebdomadaire
- [ ] **1.3** Tester le workflow mensuel
- [ ] **1.4** Tester l'installation des tâches planifiées
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Définir les tests
Describe "Tests simples pour les workflows" {
    Context "Vérification de l'existence des workflows" {
        It "Le workflow quotidien devrait exister" {
            Test-Path -Path $workflowQuotidienPath | Should -Be $true
        }
        
        It "Le workflow hebdomadaire devrait exister" {
            Test-Path -Path $workflowHebdomadairePath | Should -Be $true
        }
        
        It "Le workflow mensuel devrait exister" {
            Test-Path -Path $workflowMensuelPath | Should -Be $true
        }
        
        It "Le script d'installation des tâches planifiées devrait exister" {
            Test-Path -Path $installScheduledTasksPath | Should -Be $true
        }
    }
    
    Context "Vérification de l'exécution des workflows" {
        BeforeAll {
            # Créer un mock pour le gestionnaire intégré
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
        
        It "Le workflow quotidien devrait pouvoir être exécuté sans erreur" {
            { & $workflowQuotidienPath -RoadmapPath $testRoadmapPath -LogPath $testDir -WhatIf } | Should -Not -Throw
        }
        
        It "Le workflow hebdomadaire devrait pouvoir être exécuté sans erreur" {
            { & $workflowHebdomadairePath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir -WhatIf } | Should -Not -Throw
        }
        
        It "Le workflow mensuel devrait pouvoir être exécuté sans erreur" {
            { & $workflowMensuelPath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir -WhatIf } | Should -Not -Throw
        }
        
        It "Le script d'installation des tâches planifiées devrait pouvoir être exécuté sans erreur" {
            { & $installScheduledTasksPath -WhatIf } | Should -Not -Throw
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
