<#
.SYNOPSIS
    Test complet de l'intÃ©gration entre le mode manager et le roadmap manager.

.DESCRIPTION
    Ce script teste l'intÃ©gration complÃ¨te entre le mode manager et le roadmap manager,
    y compris les modes adaptÃ©s, les nouveaux modes d'intÃ©gration et les workflows automatisÃ©s.
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

# CrÃ©er un rÃ©pertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "complete-integration-test-roadmap.md"
@"
# Roadmap de test d'intÃ©gration complÃ¨te

## TÃ¢che 1: IntÃ©gration Mode Manager et Roadmap Manager

### Description
Cette tÃ¢che vise Ã  tester l'intÃ©gration complÃ¨te entre le Mode Manager et le Roadmap Manager.

### Sous-tÃ¢ches
- [ ] **1.1** Tester le gestionnaire intÃ©grÃ©
- [ ] **1.2** Tester les modes adaptÃ©s
- [ ] **1.3** Tester les nouveaux modes d'intÃ©gration
- [ ] **1.4** Tester les workflows automatisÃ©s
- [ ] **1.5** VÃ©rifier la documentation
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# CrÃ©er un fichier de configuration de test
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
            Description = "Roadmap de test d'intÃ©gration complÃ¨te"
            Format = "Markdown"
            AutoUpdate = $true
            GitIntegration = $false
            ReportPath = $testDir
        }
    }
    Workflows = @{
        CompleteIntegrationTest = @{
            Description = "Workflow de test d'intÃ©gration complÃ¨te"
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

# CrÃ©er des mocks pour les tests
function New-RoadmapParser {
    # CrÃ©er un module mock pour RoadmapParser
    $mockModulePath = Join-Path -Path $testDir -ChildPath "MockRoadmapParser.psm1"
    @"
function Invoke-RoadmapCheck {
    param (
        [string]`$FilePath,
        [string]`$TaskIdentifier,
        [bool]`$UpdateRoadmap = `$true,
        [bool]`$GenerateReport = `$true
    )
    
    # Simuler la vÃ©rification de la roadmap
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
        Title = "Roadmap de test d'intÃ©gration complÃ¨te"
        Tasks = @(
            @{
                Title = "TÃ¢che 1: IntÃ©gration Mode Manager et Roadmap Manager"
                SubTasks = @(
                    @{ Title = "Tester le gestionnaire intÃ©grÃ©"; IsCompleted = `$false },
                    @{ Title = "Tester les modes adaptÃ©s"; IsCompleted = `$false },
                    @{ Title = "Tester les nouveaux modes d'intÃ©gration"; IsCompleted = `$false },
                    @{ Title = "Tester les workflows automatisÃ©s"; IsCompleted = `$false },
                    @{ Title = "VÃ©rifier la documentation"; IsCompleted = `$false }
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
    
    # Simuler la gÃ©nÃ©ration d'un rapport HTML
    `$reportPath = Join-Path -Path `$OutputPath -ChildPath "roadmap-report.html"
    
    `$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de Roadmap</title>
</head>
<body>
    <h1>Rapport de Roadmap</h1>
    <p>TÃ¢ches totales: `$(`$Analysis.TotalTasks)</p>
    <p>TÃ¢ches complÃ©tÃ©es: `$(`$Analysis.CompletedTasks)</p>
    <p>Pourcentage de complÃ©tion: `$(`$Analysis.CompletionPercentage)%</p>
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
    
    # Simuler la gÃ©nÃ©ration d'un plan d'action
    return @{
        StartDate = (Get-Date).ToString("yyyy-MM-dd")
        EndDate = (Get-Date).AddDays(`$DaysToForecast).ToString("yyyy-MM-dd")
        DaysToForecast = `$DaysToForecast
        Tasks = @(
            @{
                TaskGroup = "TÃ¢che 1"
                SubTaskId = "1.1"
                SubTaskTitle = "Tester le gestionnaire intÃ©grÃ©"
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
    
    # Simuler la gÃ©nÃ©ration d'un rapport de plan d'action
    `$markdown = @"
# Plan d'action pour la roadmap

## PÃ©riode de planification
- Date de dÃ©but: `$(`$Plan.StartDate)
- Date de fin: `$(`$Plan.EndDate)
- Nombre de jours: `$(`$Plan.DaysToForecast)

## TÃ¢ches planifiÃ©es
| Groupe | ID | TÃ¢che | Date de dÃ©but | Date de fin | Jours estimÃ©s |
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

# CrÃ©er les mocks
$mockRoadmapParserPath = New-RoadmapParser

# DÃ©finir les chemins des composants
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

# DÃ©finir les tests
Describe "IntÃ©gration complÃ¨te Mode Manager et Roadmap Manager" {
    BeforeAll {
        # CrÃ©er un mock pour Import-Module
        Mock Import-Module {
            # Ne rien faire, juste simuler l'importation
        } -ModuleName "Test-CompleteIntegration"
        
        # CrÃ©er un mock pour le module RoadmapParser
        Mock Import-Module {
            Import-Module $mockRoadmapParserPath -Force
        } -ParameterFilter { $Name -match "RoadmapParser" }
    }
    
    Context "VÃ©rification des composants" {
        It "Le gestionnaire intÃ©grÃ© devrait exister" {
            Test-Path -Path $integratedManagerPath | Should -Be $true
        }
        
        It "Le mode CHECK adaptÃ© devrait exister" {
            Test-Path -Path $checkModePath | Should -Be $true
        }
        
        It "Le mode GRAN adaptÃ© devrait exister" {
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
        
        It "Le script d'installation des tÃ¢ches planifiÃ©es devrait exister" {
            Test-Path -Path $installScheduledTasksPath | Should -Be $true
        }
    }
    
    Context "ExÃ©cution des modes adaptÃ©s" {
        It "Le mode CHECK adaptÃ© devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $checkModePath -FilePath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode GRAN adaptÃ© devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $granModePath -FilePath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "ExÃ©cution des nouveaux modes d'intÃ©gration" {
        It "Le mode ROADMAP-SYNC devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $roadmapSyncModePath -SourcePath $testRoadmapPath -TargetFormat "JSON" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode ROADMAP-REPORT devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $roadmapReportModePath -RoadmapPath $testRoadmapPath -OutputPath $testDir -ReportFormat "HTML" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode ROADMAP-PLAN devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $roadmapPlanModePath -RoadmapPath $testRoadmapPath -OutputPath (Join-Path -Path $testDir -ChildPath "roadmap-plan.md") -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "ExÃ©cution des workflows automatisÃ©s" {
        It "Le workflow quotidien devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            # CrÃ©er un mock pour le gestionnaire intÃ©grÃ©
            Mock Invoke-Expression { return @{ Success = $true } } -ModuleName "Test-CompleteIntegration"
            
            { & $workflowQuotidienPath -RoadmapPath $testRoadmapPath -LogPath $testDir -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Le workflow hebdomadaire devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            # CrÃ©er un mock pour le gestionnaire intÃ©grÃ©
            Mock Invoke-Expression { return @{ Success = $true } } -ModuleName "Test-CompleteIntegration"
            
            { & $workflowHebdomadairePath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Le workflow mensuel devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            # CrÃ©er un mock pour le gestionnaire intÃ©grÃ©
            Mock Invoke-Expression { return @{ Success = $true } } -ModuleName "Test-CompleteIntegration"
            
            { & $workflowMensuelPath -RoadmapPaths @($testRoadmapPath) -OutputPath $testDir -LogPath $testDir -ConfigPath $testConfigPath } | Should -Not -Throw
        }
    }
    
    Context "ExÃ©cution du gestionnaire intÃ©grÃ©" {
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $integratedManagerPath -ListModes -ConfigPath $testConfigPath } | Should -Not -Throw
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode CHECK" {
            { & $integratedManagerPath -Mode "CHECK" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode GRAN" {
            { & $integratedManagerPath -Mode "GRAN" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode ROADMAP-SYNC" {
            { & $integratedManagerPath -Mode "ROADMAP-SYNC" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode ROADMAP-REPORT" {
            { & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode ROADMAP-PLAN" {
            { & $integratedManagerPath -Mode "ROADMAP-PLAN" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le workflow CompleteIntegrationTest" {
            { & $integratedManagerPath -Workflow "CompleteIntegrationTest" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "VÃ©rification de la documentation" {
        It "La documentation du gestionnaire intÃ©grÃ© devrait exister" {
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
        
        It "La documentation des workflows automatisÃ©s devrait exister" {
            $docPath = Join-Path -Path $projectRoot -ChildPath "development\docs\guides\automation\roadmap-workflows.md"
            Test-Path -Path $docPath | Should -Be $true
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed

