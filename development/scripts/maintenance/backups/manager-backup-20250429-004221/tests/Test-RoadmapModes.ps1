<#
.SYNOPSIS
    Tests pour les nouveaux modes de gestion de roadmap.

.DESCRIPTION
    Ce script contient des tests pour vÃ©rifier que les nouveaux modes de gestion de roadmap
    (ROADMAP-SYNC, ROADMAP-REPORT, ROADMAP-PLAN) fonctionnent correctement.
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
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"
$configPath = Join-Path -Path $projectRoot -ChildPath "development\config\unified-config.json"
$roadmapSyncPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-sync-mode.ps1"
$roadmapReportPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-report-mode.ps1"
$roadmapPlanPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-plan-mode.ps1"

# CrÃ©er un rÃ©pertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
@"
# Test Roadmap

## TÃ¢che 1.2.3

### Description
Cette tÃ¢che est utilisÃ©e pour les tests des modes de gestion de roadmap.

### Sous-tÃ¢ches
- [ ] **1.2.3.1** Sous-tÃ¢che 1
- [ ] **1.2.3.2** Sous-tÃ¢che 2
- [ ] **1.2.3.3** Sous-tÃ¢che 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# CrÃ©er un fichier de configuration de test
$testConfigPath = Join-Path -Path $testDir -ChildPath "test-config.json"
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
        RoadmapSync = @{
            Enabled = $true
            ScriptPath = $roadmapSyncPath
            DefaultSourceFormat = "Markdown"
            DefaultTargetFormat = "JSON"
        }
        RoadmapReport = @{
            Enabled = $true
            ScriptPath = $roadmapReportPath
            DefaultReportFormat = "HTML"
            IncludeCharts = $true
            IncludeTrends = $true
            IncludePredictions = $true
            DaysToAnalyze = 30
        }
        RoadmapPlan = @{
            Enabled = $true
            ScriptPath = $roadmapPlanPath
            DaysToForecast = 30
        }
    }
    Roadmaps = @{
        Test = @{
            Path = $testRoadmapPath
            Description = "Roadmap de test"
            Format = "Markdown"
            AutoUpdate = $true
            GitIntegration = $false
            ReportPath = $testDir
        }
    }
    Workflows = @{
        RoadmapManagement = @{
            Description = "Workflow de gestion de roadmap"
            Modes = @("ROADMAP-SYNC", "ROADMAP-REPORT", "ROADMAP-PLAN")
            AutoContinue = $true
            StopOnError = $true
        }
    }
    Integration = @{
        EnabledByDefault = $true
        DefaultWorkflow = "RoadmapManagement"
        DefaultRoadmap = "Test"
        AutoSaveResults = $true
        ResultsPath = $testDir
        LogLevel = "Info"
        NotifyOnCompletion = $true
        MaxConcurrentTasks = 4
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $testConfigPath -Encoding UTF8

# CrÃ©er des scripts mock pour les tests
$mockRoadmapParserModulePath = Join-Path -Path $testDir -ChildPath "RoadmapParser.psm1"
@"
function Get-RoadmapTasks {
    param (
        [string]`$RoadmapPath
    )
    
    # Simuler l'analyse de la roadmap
    return @(
        @{
            Title = "TÃ¢che 1.2.3"
            Id = "1.2.3"
            Description = "Cette tÃ¢che est utilisÃ©e pour les tests des modes de gestion de roadmap."
            SubTasks = @(
                @{
                    Title = "Sous-tÃ¢che 1"
                    Id = "1.2.3.1"
                    IsCompleted = `$false
                },
                @{
                    Title = "Sous-tÃ¢che 2"
                    Id = "1.2.3.2"
                    IsCompleted = `$false
                },
                @{
                    Title = "Sous-tÃ¢che 3"
                    Id = "1.2.3.3"
                    IsCompleted = `$false
                }
            )
        }
    )
}

function ConvertFrom-MarkdownToJson {
    param (
        [string]`$MarkdownPath,
        [string]`$JsonPath
    )
    
    # Simuler la conversion de Markdown vers JSON
    `$json = @{
        Title = "Roadmap"
        Description = "Roadmap gÃ©nÃ©rÃ©e Ã  partir du fichier Markdown"
        LastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Tasks = @(
            @{
                Title = "TÃ¢che 1.2.3"
                Id = "1.2.3"
                Description = "Cette tÃ¢che est utilisÃ©e pour les tests des modes de gestion de roadmap."
                Status = "NotStarted"
                SubTasks = @(
                    @{
                        Title = "Sous-tÃ¢che 1"
                        Id = "1.2.3.1"
                        Status = "NotStarted"
                    },
                    @{
                        Title = "Sous-tÃ¢che 2"
                        Id = "1.2.3.2"
                        Status = "NotStarted"
                    },
                    @{
                        Title = "Sous-tÃ¢che 3"
                        Id = "1.2.3.3"
                        Status = "NotStarted"
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10
    
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
        TotalTasks = 3
        CompletedTasks = 0
        CompletionPercentage = 0
        TaskGroups = @{
            "TÃ¢che 1.2.3" = @{
                Total = 3
                Completed = 0
                Percentage = 0
            }
        }
        Tasks = @(
            @{
                Title = "TÃ¢che 1.2.3"
                Id = "1.2.3"
                Description = "Cette tÃ¢che est utilisÃ©e pour les tests des modes de gestion de roadmap."
                SubTasks = @(
                    @{
                        Title = "Sous-tÃ¢che 1"
                        Id = "1.2.3.1"
                        Status = "NotStarted"
                    },
                    @{
                        Title = "Sous-tÃ¢che 2"
                        Id = "1.2.3.2"
                        Status = "NotStarted"
                    },
                    @{
                        Title = "Sous-tÃ¢che 3"
                        Id = "1.2.3.3"
                        Status = "NotStarted"
                    }
                )
            }
        )
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
    <meta charset="UTF-8">
    <title>Rapport de Roadmap</title>
</head>
<body>
    <h1>Rapport de Roadmap</h1>
    <p>Fichier de roadmap : `$(`$Analysis.RoadmapPath)</p>
    <p>Date d'analyse : `$(`$Analysis.AnalysisDate)</p>
    <p>TÃ¢ches totales : `$(`$Analysis.TotalTasks)</p>
    <p>TÃ¢ches complÃ©tÃ©es : `$(`$Analysis.CompletedTasks)</p>
    <p>Pourcentage de complÃ©tion : `$(`$Analysis.CompletionPercentage)%</p>
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
    `$today = Get-Date
    `$endDate = `$today.AddDays(`$DaysToForecast)
    
    return @{
        StartDate = `$today.ToString("yyyy-MM-dd")
        EndDate = `$endDate.ToString("yyyy-MM-dd")
        DaysToForecast = `$DaysToForecast
        Tasks = @(
            @{
                TaskGroup = "TÃ¢che 1.2.3"
                SubTaskId = "1.2.3.1"
                SubTaskTitle = "Sous-tÃ¢che 1"
                StartDate = `$today.ToString("yyyy-MM-dd")
                EndDate = `$today.AddDays(3).ToString("yyyy-MM-dd")
                EstimatedDays = 3
            },
            @{
                TaskGroup = "TÃ¢che 1.2.3"
                SubTaskId = "1.2.3.2"
                SubTaskTitle = "Sous-tÃ¢che 2"
                StartDate = `$today.AddDays(3).ToString("yyyy-MM-dd")
                EndDate = `$today.AddDays(6).ToString("yyyy-MM-dd")
                EstimatedDays = 3
            },
            @{
                TaskGroup = "TÃ¢che 1.2.3"
                SubTaskId = "1.2.3.3"
                SubTaskTitle = "Sous-tÃ¢che 3"
                StartDate = `$today.AddDays(6).ToString("yyyy-MM-dd")
                EndDate = `$today.AddDays(9).ToString("yyyy-MM-dd")
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
    `$reportPath = `$OutputPath
    
    `$markdown = @"
# Plan d'action pour la roadmap

## PÃ©riode de planification

- **Date de dÃ©but :** `$(`$Plan.StartDate)
- **Date de fin :** `$(`$Plan.EndDate)
- **Nombre de jours :** `$(`$Plan.DaysToForecast)

## TÃ¢ches planifiÃ©es

| Groupe | ID | TÃ¢che | Date de dÃ©but | Date de fin | Jours estimÃ©s |
| ------ | -- | ----- | ------------- | ----------- | ------------- |
"@
    
    foreach (`$task in `$Plan.Tasks) {
        `$markdown += "| `$(`$task.TaskGroup) | `$(`$task.SubTaskId) | `$(`$task.SubTaskTitle) | `$(`$task.StartDate) | `$(`$task.EndDate) | `$(`$task.EstimatedDays) |`n"
    }
    
    Set-Content -Path `$reportPath -Value `$markdown -Encoding UTF8
    
    return `$reportPath
}

Export-ModuleMember -Function Get-RoadmapTasks, ConvertFrom-MarkdownToJson, Get-RoadmapAnalysis, New-HtmlReport, New-ActionPlan, New-PlanReport
"@ | Set-Content -Path $mockRoadmapParserModulePath -Encoding UTF8

# DÃ©finir les tests
Describe "Modes de gestion de roadmap" {
    BeforeAll {
        # CrÃ©er un mock pour Import-Module
        Mock Import-Module {
            # Ne rien faire, juste simuler l'importation
        } -ModuleName "Test-RoadmapModes"
        
        # CrÃ©er un mock pour le module RoadmapParser
        Mock Import-Module {
            Import-Module $mockRoadmapParserModulePath -Force
        } -ParameterFilter { $Name -eq $modulePath }
    }
    
    Context "Mode ROADMAP-SYNC" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPath = Join-Path -Path $testDir -ChildPath "test-roadmap.json"
            if (Test-Path -Path $outputPath) {
                Remove-Item -Path $outputPath -Force
            }
        }
        
        It "Devrait exister" {
            Test-Path -Path $roadmapSyncPath | Should -Be $true
        }
        
        It "Devrait convertir une roadmap de Markdown vers JSON" {
            # ExÃ©cuter le script directement
            & $roadmapSyncPath -SourcePath $testRoadmapPath -TargetFormat "JSON" -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path (Split-Path -Parent $testRoadmapPath) -ChildPath "test-roadmap.json"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $content = Get-Content -Path $outputPath -Raw
            $content | Should -Match "Roadmap"
            $content | Should -Match "TÃ¢che 1.2.3"
            $content | Should -Match "Sous-tÃ¢che 1"
        }
        
        It "Devrait Ãªtre exÃ©cutable via le gestionnaire intÃ©grÃ©" {
            # ExÃ©cuter le script via le gestionnaire intÃ©grÃ©
            & $integratedManagerPath -Mode "ROADMAP-SYNC" -RoadmapPath $testRoadmapPath -TargetFormat "JSON" -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path (Split-Path -Parent $testRoadmapPath) -ChildPath "test-roadmap.json"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $content = Get-Content -Path $outputPath -Raw
            $content | Should -Match "Roadmap"
            $content | Should -Match "TÃ¢che 1.2.3"
            $content | Should -Match "Sous-tÃ¢che 1"
        }
    }
    
    Context "Mode ROADMAP-REPORT" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-report.html"
            if (Test-Path -Path $outputPath) {
                Remove-Item -Path $outputPath -Force
            }
        }
        
        It "Devrait exister" {
            Test-Path -Path $roadmapReportPath | Should -Be $true
        }
        
        It "Devrait gÃ©nÃ©rer un rapport HTML" {
            # ExÃ©cuter le script directement
            & $roadmapReportPath -RoadmapPath $testRoadmapPath -OutputPath $testDir -ReportFormat "HTML" -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-report.html"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $content = Get-Content -Path $outputPath -Raw
            $content | Should -Match "Rapport de Roadmap"
            $content | Should -Match "TÃ¢ches totales"
            $content | Should -Match "Pourcentage de complÃ©tion"
        }
        
        It "Devrait Ãªtre exÃ©cutable via le gestionnaire intÃ©grÃ©" {
            # ExÃ©cuter le script via le gestionnaire intÃ©grÃ©
            & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $testRoadmapPath -OutputPath $testDir -ReportFormat "HTML" -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-report.html"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $content = Get-Content -Path $outputPath -Raw
            $content | Should -Match "Rapport de Roadmap"
            $content | Should -Match "TÃ¢ches totales"
            $content | Should -Match "Pourcentage de complÃ©tion"
        }
    }
    
    Context "Mode ROADMAP-PLAN" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-plan.md"
            if (Test-Path -Path $outputPath) {
                Remove-Item -Path $outputPath -Force
            }
        }
        
        It "Devrait exister" {
            Test-Path -Path $roadmapPlanPath | Should -Be $true
        }
        
        It "Devrait gÃ©nÃ©rer un plan d'action" {
            # ExÃ©cuter le script directement
            & $roadmapPlanPath -RoadmapPath $testRoadmapPath -OutputPath (Join-Path -Path $testDir -ChildPath "roadmap-plan.md") -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-plan.md"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $content = Get-Content -Path $outputPath -Raw
            $content | Should -Match "Plan d'action pour la roadmap"
            $content | Should -Match "PÃ©riode de planification"
            $content | Should -Match "TÃ¢ches planifiÃ©es"
        }
        
        It "Devrait Ãªtre exÃ©cutable via le gestionnaire intÃ©grÃ©" {
            # ExÃ©cuter le script via le gestionnaire intÃ©grÃ©
            & $integratedManagerPath -Mode "ROADMAP-PLAN" -RoadmapPath $testRoadmapPath -OutputPath (Join-Path -Path $testDir -ChildPath "roadmap-plan.md") -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-plan.md"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $content = Get-Content -Path $outputPath -Raw
            $content | Should -Match "Plan d'action pour la roadmap"
            $content | Should -Match "PÃ©riode de planification"
            $content | Should -Match "TÃ¢ches planifiÃ©es"
        }
    }
    
    Context "Workflow de gestion de roadmap" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPaths = @(
                (Join-Path -Path $testDir -ChildPath "test-roadmap.json"),
                (Join-Path -Path $testDir -ChildPath "roadmap-report.html"),
                (Join-Path -Path $testDir -ChildPath "roadmap-plan.md")
            )
            
            foreach ($path in $outputPaths) {
                if (Test-Path -Path $path) {
                    Remove-Item -Path $path -Force
                }
            }
        }
        
        It "Devrait exÃ©cuter le workflow de gestion de roadmap" {
            # ExÃ©cuter le workflow via le gestionnaire intÃ©grÃ©
            & $integratedManagerPath -Workflow "RoadmapManagement" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath
            
            # VÃ©rifier que les fichiers de sortie ont Ã©tÃ© crÃ©Ã©s
            $jsonPath = Join-Path -Path (Split-Path -Parent $testRoadmapPath) -ChildPath "test-roadmap.json"
            $reportPath = Join-Path -Path $testDir -ChildPath "roadmap-report.html"
            $planPath = Join-Path -Path (Split-Path -Parent $testRoadmapPath) -ChildPath "roadmap-plan.md"
            
            Test-Path -Path $jsonPath | Should -Be $true
            Test-Path -Path $reportPath | Should -Be $true
            Test-Path -Path $planPath | Should -Be $true
            
            # VÃ©rifier le contenu des fichiers de sortie
            $jsonContent = Get-Content -Path $jsonPath -Raw
            $jsonContent | Should -Match "Roadmap"
            $jsonContent | Should -Match "TÃ¢che 1.2.3"
            
            $reportContent = Get-Content -Path $reportPath -Raw
            $reportContent | Should -Match "Rapport de Roadmap"
            $reportContent | Should -Match "TÃ¢ches totales"
            
            $planContent = Get-Content -Path $planPath -Raw
            $planContent | Should -Match "Plan d'action pour la roadmap"
            $planContent | Should -Match "TÃ¢ches planifiÃ©es"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
