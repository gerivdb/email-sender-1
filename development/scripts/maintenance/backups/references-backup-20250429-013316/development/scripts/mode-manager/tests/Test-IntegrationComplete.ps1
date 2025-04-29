<#
.SYNOPSIS
    Test d'intégration complète entre le mode manager et le roadmap manager.

.DESCRIPTION
    Ce script teste l'intégration complète entre le mode manager et le roadmap manager
    en vérifiant que tous les composants fonctionnent correctement ensemble.
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
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"
$configPath = Join-Path -Path $projectRoot -ChildPath "development\config\unified-config.json"

# Créer un répertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "integration-test-roadmap.md"
@"
# Roadmap d'intégration

## Tâche 1: Intégration Mode Manager et Roadmap Manager

### Description
Cette tâche vise à intégrer le Mode Manager et le Roadmap Manager pour offrir une interface unifiée.

### Sous-tâches
- [ ] **1.1** Créer le gestionnaire intégré
- [ ] **1.2** Adapter les modes existants
- [ ] **1.3** Créer de nouveaux modes d'intégration
- [ ] **1.4** Tester l'intégration complète
- [ ] **1.5** Documenter l'intégration
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Créer un fichier de configuration de test
$testConfigPath = Join-Path -Path $testDir -ChildPath "integration-test-config.json"
@{
    General = @{
        RoadmapPath = $testRoadmapPath
        ActiveDocumentPath = $testRoadmapPath
        ReportPath = $testDir
        LogPath = $testDir
        DefaultLanguage = "fr-FR"
        DefaultEncoding = "UTF8-BOM"
        ProjectRoot = $projectRoot
    }
    Modes = @{
        Check = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\check.ps1"
            DefaultRoadmapFile = $testRoadmapPath
            DefaultActiveDocumentPath = $testRoadmapPath
            AutoUpdateRoadmap = $true
            GenerateReport = $true
            ReportPath = $testDir
            AutoUpdateCheckboxes = $true
            RequireFullTestCoverage = $true
            SimulationModeDefault = $true
        }
        Gran = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\gran-mode.ps1"
            DefaultRoadmapFile = $testRoadmapPath
            MaxTaskSize = 5
            MaxComplexity = 7
            AutoIndent = $true
            GenerateSubtasks = $true
            UpdateInPlace = $true
            IndentationStyle = "Spaces2"
            CheckboxStyle = "GitHub"
        }
        RoadmapSync = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-sync-mode.ps1"
            DefaultSourceFormat = "Markdown"
            DefaultTargetFormat = "JSON"
            DefaultSourcePath = $testRoadmapPath
            DefaultTargetPath = Join-Path -Path $testDir -ChildPath "integration-test-roadmap.json"
        }
        RoadmapReport = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-report-mode.ps1"
            DefaultReportFormat = "HTML"
            DefaultOutputPath = $testDir
            IncludeCharts = $true
            IncludeTrends = $true
            IncludePredictions = $true
            DaysToAnalyze = 30
        }
        RoadmapPlan = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-plan-mode.ps1"
            DefaultOutputPath = $testDir
            DaysToForecast = 30
        }
    }
    Roadmaps = @{
        Test = @{
            Path = $testRoadmapPath
            Description = "Roadmap de test d'intégration"
            Format = "Markdown"
            AutoUpdate = $true
            GitIntegration = $false
            ReportPath = $testDir
        }
    }
    Workflows = @{
        IntegrationTest = @{
            Description = "Workflow de test d'intégration"
            Modes = @("CHECK", "GRAN", "ROADMAP-SYNC", "ROADMAP-REPORT", "ROADMAP-PLAN")
            AutoContinue = $true
            StopOnError = $true
        }
    }
    Integration = @{
        EnabledByDefault = $true
        DefaultWorkflow = "IntegrationTest"
        DefaultRoadmap = "Test"
        AutoSaveResults = $true
        ResultsPath = $testDir
        LogLevel = "Info"
        NotifyOnCompletion = $true
        MaxConcurrentTasks = 4
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $testConfigPath -Encoding UTF8

# Créer des mocks pour les tests
function Mock-RoadmapParser {
    # Créer un module mock pour RoadmapParser
    $mockModulePath = Join-Path -Path $testDir -ChildPath "MockRoadmapParser.psm1"
    @"
function Invoke-RoadmapCheck {
    param (
        [string]`$FilePath,
        [string]`$TaskIdentifier,
        [bool]`$UpdateRoadmap = `$true,
        [bool]`$GenerateReport = `$true
    )
    
    # Simuler la vérification de la roadmap
    return @{
        Success = `$true
        FilePath = `$FilePath
        TaskIdentifier = `$TaskIdentifier
        UpdatedTasks = @("1.1", "1.2")
        ReportPath = Join-Path -Path "$testDir" -ChildPath "check-report.html"
    }
}

function Invoke-RoadmapGranularization {
    param (
        [string]`$FilePath,
        [string]`$TaskIdentifier,
        [string]`$SubTasksInput,
        [string]`$IndentationStyle = "Auto",
        [string]`$CheckboxStyle = "Auto"
    )
    
    # Simuler la granularisation de la roadmap
    return @{
        Success = `$true
        FilePath = `$FilePath
        TaskIdentifier = `$TaskIdentifier
        SubTasksAdded = 3
    }
}

function ConvertFrom-MarkdownToJson {
    param (
        [string]`$MarkdownPath,
        [string]`$JsonPath
    )
    
    # Simuler la conversion de Markdown vers JSON
    `$json = @{
        Title = "Roadmap d'intégration"
        Tasks = @(
            @{
                Title = "Tâche 1: Intégration Mode Manager et Roadmap Manager"
                SubTasks = @(
                    @{ Title = "Créer le gestionnaire intégré"; IsCompleted = `$false },
                    @{ Title = "Adapter les modes existants"; IsCompleted = `$false },
                    @{ Title = "Créer de nouveaux modes d'intégration"; IsCompleted = `$false },
                    @{ Title = "Tester l'intégration complète"; IsCompleted = `$false },
                    @{ Title = "Documenter l'intégration"; IsCompleted = `$false }
                )
            }
        )
    } | ConvertTo-Json -Depth 5
    
    Set-Content -Path `$JsonPath -Value `$json -Encoding UTF8
    
    return `$json
}

function Get-RoadmapAnalysis {
    param (
        [string]`$RoadmapPath
    )
    
    # Simuler l'analyse de la roadmap
    return @{
        RoadmapPath = `$RoadmapPath
        TotalTasks = 5
        CompletedTasks = 0
        CompletionPercentage = 0
        AnalysisDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    }
}

function New-HtmlReport {
    param (
        [hashtable]`$Analysis,
        [string]`$OutputPath,
        [bool]`$IncludeCharts,
        [bool]`$IncludeTrends,
        [bool]`$IncludePredictions
    )
    
    # Simuler la génération d'un rapport HTML
    `$reportPath = Join-Path -Path `$OutputPath -ChildPath "roadmap-report.html"
    
    `$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Roadmap</title>
</head>
<body>
    <h1>Rapport de Roadmap</h1>
    <p>Tâches totales: `$(`$Analysis.TotalTasks)</p>
    <p>Tâches complétées: `$(`$Analysis.CompletedTasks)</p>
    <p>Pourcentage de complétion: `$(`$Analysis.CompletionPercentage)%</p>
</body>
</html>
"@
    
    Set-Content -Path `$reportPath -Value `$html -Encoding UTF8
    
    return `$reportPath
}

function New-ActionPlan {
    param (
        [array]`$Tasks,
        [int]`$DaysToForecast
    )
    
    # Simuler la génération d'un plan d'action
    return @{
        StartDate = (Get-Date).ToString("yyyy-MM-dd")
        EndDate = (Get-Date).AddDays(`$DaysToForecast).ToString("yyyy-MM-dd")
        DaysToForecast = `$DaysToForecast
        Tasks = @(
            @{
                TaskGroup = "Tâche 1"
                SubTaskId = "1.1"
                SubTaskTitle = "Créer le gestionnaire intégré"
                StartDate = (Get-Date).ToString("yyyy-MM-dd")
                EndDate = (Get-Date).AddDays(3).ToString("yyyy-MM-dd")
                EstimatedDays = 3
            }
        )
    }
}

function New-PlanReport {
    param (
        [hashtable]`$Plan,
        [string]`$OutputPath
    )
    
    # Simuler la génération d'un rapport de plan d'action
    `$markdown = @"
# Plan d'action pour la roadmap

## Période de planification
- Date de début: `$(`$Plan.StartDate)
- Date de fin: `$(`$Plan.EndDate)
- Nombre de jours: `$(`$Plan.DaysToForecast)

## Tâches planifiées
| Groupe | ID | Tâche | Date de début | Date de fin | Jours estimés |
| ------ | -- | ----- | ------------- | ----------- | ------------- |
"@
    
    foreach (`$task in `$Plan.Tasks) {
        `$markdown += "| `$(`$task.TaskGroup) | `$(`$task.SubTaskId) | `$(`$task.SubTaskTitle) | `$(`$task.StartDate) | `$(`$task.EndDate) | `$(`$task.EstimatedDays) |`n"
    }
    
    Set-Content -Path `$OutputPath -Value `$markdown -Encoding UTF8
    
    return `$OutputPath
}

Export-ModuleMember -Function Invoke-RoadmapCheck, Invoke-RoadmapGranularization, ConvertFrom-MarkdownToJson, Get-RoadmapAnalysis, New-HtmlReport, New-ActionPlan, New-PlanReport
"@ | Set-Content -Path $mockModulePath -Encoding UTF8

    return $mockModulePath
}

# Créer les mocks
$mockRoadmapParserPath = Mock-RoadmapParser

# Définir les tests
Describe "Intégration complète Mode Manager et Roadmap Manager" {
    BeforeAll {
        # Créer un mock pour Import-Module
        Mock Import-Module {
            # Ne rien faire, juste simuler l'importation
        } -ModuleName "Test-IntegrationComplete"
        
        # Créer un mock pour le module RoadmapParser
        Mock Import-Module {
            Import-Module $mockRoadmapParserPath -Force
        } -ParameterFilter { $Name -match "RoadmapParser" }
    }
    
    Context "Gestionnaire intégré" {
        It "Devrait exister" {
            Test-Path -Path $integratedManagerPath | Should -Be $true
        }
        
        It "Devrait pouvoir être exécuté sans erreur" {
            { & $integratedManagerPath -ListModes -ConfigPath $testConfigPath } | Should -Not -Throw
        }
    }
    
    Context "Modes adaptés" {
        It "Le mode CHECK adapté devrait exister" {
            $checkPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\check.ps1"
            Test-Path -Path $checkPath | Should -Be $true
        }
        
        It "Le mode GRAN adapté devrait exister" {
            $granPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\gran-mode.ps1"
            Test-Path -Path $granPath | Should -Be $true
        }
    }
    
    Context "Nouveaux modes d'intégration" {
        It "Le mode ROADMAP-SYNC devrait exister" {
            $syncPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-sync-mode.ps1"
            Test-Path -Path $syncPath | Should -Be $true
        }
        
        It "Le mode ROADMAP-REPORT devrait exister" {
            $reportPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-report-mode.ps1"
            Test-Path -Path $reportPath | Should -Be $true
        }
        
        It "Le mode ROADMAP-PLAN devrait exister" {
            $planPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-plan-mode.ps1"
            Test-Path -Path $planPath | Should -Be $true
        }
    }
    
    Context "Exécution des modes via le gestionnaire intégré" {
        It "Devrait pouvoir exécuter le mode CHECK" {
            { & $integratedManagerPath -Mode "CHECK" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Devrait pouvoir exécuter le mode GRAN" {
            { & $integratedManagerPath -Mode "GRAN" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Devrait pouvoir exécuter le mode ROADMAP-SYNC" {
            { & $integratedManagerPath -Mode "ROADMAP-SYNC" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Devrait pouvoir exécuter le mode ROADMAP-REPORT" {
            { & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Devrait pouvoir exécuter le mode ROADMAP-PLAN" {
            { & $integratedManagerPath -Mode "ROADMAP-PLAN" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath } | Should -Not -Throw
        }
    }
    
    Context "Exécution du workflow de test d'intégration" {
        It "Devrait pouvoir exécuter le workflow IntegrationTest" {
            { & $integratedManagerPath -Workflow "IntegrationTest" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath } | Should -Not -Throw
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
