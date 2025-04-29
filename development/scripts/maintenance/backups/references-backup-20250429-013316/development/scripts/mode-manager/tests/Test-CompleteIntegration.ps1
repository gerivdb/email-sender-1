<#
.SYNOPSIS
    Test complet de l'intégration entre le mode manager et le roadmap manager.

.DESCRIPTION
    Ce script teste l'intégration complète entre le mode manager et le roadmap manager,
    y compris les modes adaptés, les nouveaux modes d'intégration et les workflows automatisés.
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

# Créer un répertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "complete-integration-test-roadmap.md"
@"
# Roadmap de test d'intégration complète

## Tâche 1: Intégration Mode Manager et Roadmap Manager

### Description
Cette tâche vise à tester l'intégration complète entre le Mode Manager et le Roadmap Manager.

### Sous-tâches
- [ ] **1.1** Tester le gestionnaire intégré
- [ ] **1.2** Tester les modes adaptés
- [ ] **1.3** Tester les nouveaux modes d'intégration
- [ ] **1.4** Tester les workflows automatisés
- [ ] **1.5** Vérifier la documentation
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Créer un fichier de configuration de test
$testConfigPath = Join-Path -Path $testDir -ChildPath "complete-integration-test-config.json"
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
            DefaultTargetPath = Join-Path -Path $testDir -ChildPath "complete-integration-test-roadmap.json"
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
            Description = "Roadmap de test d'intégration complète"
            Format = "Markdown"
            AutoUpdate = $true
            GitIntegration = $false
            ReportPath = $testDir
        }
    }
    Workflows = @{
        CompleteIntegrationTest = @{
            Description = "Workflow de test d'intégration complète"
            Modes = @("CHECK", "GRAN", "ROADMAP-SYNC", "ROADMAP-REPORT", "ROADMAP-PLAN")
            AutoContinue = $true
            StopOnError = $true
        }
    }
    Integration = @{
        EnabledByDefault = $true
        DefaultWorkflow = "CompleteIntegrationTest"
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
        Title = "Roadmap de test d'intégration complète"
        Tasks = @(
            @{
                Title = "Tâche 1: Intégration Mode Manager et Roadmap Manager"
                SubTasks = @(
                    @{ Title = "Tester le gestionnaire intégré"; IsCompleted = `$false },
                    @{ Title = "Tester les modes adaptés"; IsCompleted = `$false },
                    @{ Title = "Tester les nouveaux modes d'intégration"; IsCompleted = `$false },
                    @{ Title = "Tester les workflows automatisés"; IsCompleted = `$false },
                    @{ Title = "Vérifier la documentation"; IsCompleted = `$false }
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
                SubTaskTitle = "Tester le gestionnaire intégré"
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

function Write-Log {
    param (
        [string]`$Message,
        [string]`$Level = "INFO"
    )
    
    # Simuler la journalisation
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMessage = "[\`$timestamp] [\`$Level] \`$Message"
    
    return `$logMessage
}

Export-ModuleMember -Function Invoke-RoadmapCheck, Invoke-RoadmapGranularization, ConvertFrom-MarkdownToJson, Get-RoadmapAnalysis, New-HtmlReport, New-ActionPlan, New-PlanReport, Write-Log
"@ | Set-Content -Path $mockModulePath -Encoding UTF8

    return $mockModulePath
}

# Créer les mocks
$mockRoadmapParserPath = Mock-RoadmapParser

# Définir les chemins des composants
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"
$checkModePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\check.ps1"
$granModePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\gran-mode.ps1"
$roadmapSyncModePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-sync-mode.ps1"
$roadmapReportModePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-report-mode.ps1"
$roadmapPlanModePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-plan-mode.ps1"
$workflowQuotidienPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\workflow-quotidien.ps1"
$workflowHebdomadairePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\workflow-hebdomadaire.ps1"
$workflowMensuelPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\workflow-mensuel.ps1"
$installScheduledTasksPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\workflows\install-scheduled-tasks.ps1"

# Définir les tests
Describe "Intégration complète Mode Manager et Roadmap Manager" {
    BeforeAll {
        # Créer un mock pour Import-Module
        Mock Import-Module {
            # Ne rien faire, juste simuler l'importation
        } -ModuleName "Test-CompleteIntegration"
        
        # Créer un mock pour le module RoadmapParser
        Mock Import-Module {
            Import-Module $mockRoadmapParserPath -Force
        } -ParameterFilter { $Name -match "RoadmapParser" }
    }
    
    Context "Vérification des composants" {
        It "Le gestionnaire intégré devrait exister" {
            Test-Path -Path $integratedManagerPath | Should -Be $true
        }
        
        It "Le mode CHECK adapté devrait exister" {
            Test-Path -Path $checkModePath | Should -Be $true
        }
        
        It "Le mode GRAN adapté devrait exister" {
            Test-Path -Path $granModePath | Should -Be $true
        }
        
        It "Le mode ROADMAP-SYNC devrait exister" {
            Test-Path -Path $roadmapSyncModePath | Should -Be $true
        }
        
        It "Le mode ROADMAP-REPORT devrait exister" {
            Test-Path -Path $roadmapReportModePath | Should -Be $true
        }
        
        It "Le mode ROADMAP-PLAN devrait exister" {
            Test-Path -Path $roadmapPlanModePath | Should -Be $true
        }
        
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
    
    Context "Exécution des modes adaptés" {
        It "Le mode CHECK adapté devrait pouvoir être exécuté sans erreur" {
            { & $checkModePath -FilePath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode GRAN adapté devrait pouvoir être exécuté sans erreur" {
            { & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Exécution des nouveaux modes d'intégration" {
        It "Le mode ROADMAP-SYNC devrait pouvoir être exécuté sans erreur" {
            { & $roadmapSyncModePath -SourcePath $testRoadmapPath -TargetFormat "JSON" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode ROADMAP-REPORT devrait pouvoir être exécuté sans erreur" {
            { & $roadmapReportModePath -RoadmapPath $testRoadmapPath -OutputPath $testDir -ReportFormat "HTML" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode ROADMAP-PLAN devrait pouvoir être exécuté sans erreur" {
            { & $roadmapPlanModePath -RoadmapPath $testRoadmapPath -OutputPath (Join-Path -Path $testDir -ChildPath "roadmap-plan.md") -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Exécution des workflows automatisés" {
        It "Le workflow quotidien devrait pouvoir être exécuté sans erreur" {
            # Créer un mock pour le gestionnaire intégré
            Mock Invoke-Expression { return @{ Success = $true } } -ModuleName "Test-CompleteIntegration"
            
            { & $workflowQuotidienPath -RoadmapPath $testRoadmapPath -LogPath $testDir -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Le workflow hebdomadaire devrait pouvoir être exécuté sans erreur" {
            # Créer un mock pour le gestionnaire intégré
            Mock Invoke-Expression { return @{ Success = $true } } -ModuleName "Test-CompleteIntegration"
            
            { & $workflowHebdomadairePath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Le workflow mensuel devrait pouvoir être exécuté sans erreur" {
            # Créer un mock pour le gestionnaire intégré
            Mock Invoke-Expression { return @{ Success = $true } } -ModuleName "Test-CompleteIntegration"
            
            { & $workflowMensuelPath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir -ConfigPath $testConfigPath } | Should -Not -Throw
        }
    }
    
    Context "Exécution du gestionnaire intégré" {
        It "Le gestionnaire intégré devrait pouvoir être exécuté sans erreur" {
            { & $integratedManagerPath -ListModes -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Le gestionnaire intégré devrait pouvoir exécuter le mode CHECK" {
            { & $integratedManagerPath -Mode "CHECK" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intégré devrait pouvoir exécuter le mode GRAN" {
            { & $integratedManagerPath -Mode "GRAN" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intégré devrait pouvoir exécuter le mode ROADMAP-SYNC" {
            { & $integratedManagerPath -Mode "ROADMAP-SYNC" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intégré devrait pouvoir exécuter le mode ROADMAP-REPORT" {
            { & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intégré devrait pouvoir exécuter le mode ROADMAP-PLAN" {
            { & $integratedManagerPath -Mode "ROADMAP-PLAN" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intégré devrait pouvoir exécuter le workflow CompleteIntegrationTest" {
            { & $integratedManagerPath -Workflow "CompleteIntegrationTest" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Vérification de la documentation" {
        It "La documentation du gestionnaire intégré devrait exister" {
            $docPath = Join-Path -Path $projectRoot -ChildPath "development\docs\guides\methodologies\integrated_manager.md"
            Test-Path -Path $docPath | Should -Be $true
        }
        
        It "La documentation des exemples d'utilisation des modes de roadmap devrait exister" {
            $docPath = Join-Path -Path $projectRoot -ChildPath "development\docs\guides\examples\roadmap-modes-examples.md"
            Test-Path -Path $docPath | Should -Be $true
        }
        
        It "La documentation des bonnes pratiques pour la gestion des roadmaps devrait exister" {
            $docPath = Join-Path -Path $projectRoot -ChildPath "development\docs\guides\best-practices\roadmap-management.md"
            Test-Path -Path $docPath | Should -Be $true
        }
        
        It "La documentation des workflows automatisés devrait exister" {
            $docPath = Join-Path -Path $projectRoot -ChildPath "development\docs\guides\automation\roadmap-workflows.md"
            Test-Path -Path $docPath | Should -Be $true
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
