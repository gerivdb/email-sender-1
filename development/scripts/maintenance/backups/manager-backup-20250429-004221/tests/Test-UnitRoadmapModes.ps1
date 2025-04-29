<#
.SYNOPSIS
    Tests unitaires standards pour les modes de roadmap.

.DESCRIPTION
    Ce script contient des tests unitaires standards pour vérifier le bon fonctionnement des modes de roadmap.
    Ces tests utilisent des mocks pour simuler les dépendances et vérifier que les modes de roadmap fonctionnent correctement.
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
$roadmapSyncPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-sync-mode.ps1"
$roadmapReportPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-report-mode.ps1"
$roadmapPlanPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-plan-mode.ps1"

# Créer un répertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "unit-test-roadmap.md"
@"
# Roadmap de test unitaire

## Tâche 1: Test des modes de roadmap

### Description
Cette tâche vise à tester les modes de roadmap.

### Sous-tâches
- [ ] **1.1** Tester le mode ROADMAP-SYNC
- [ ] **1.2** Tester le mode ROADMAP-REPORT
- [ ] **1.3** Tester le mode ROADMAP-PLAN
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Créer un fichier de configuration de test
$testConfigPath = Join-Path -Path $testDir -ChildPath "unit-test-config.json"
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
            ScriptPath = "development\scripts\maintenance\modes\roadmap-sync-mode.ps1"
            DefaultSourceFormat = "Markdown"
            DefaultTargetFormat = "JSON"
            DefaultSourcePath = $testRoadmapPath
            DefaultTargetPath = Join-Path -Path $testDir -ChildPath "unit-test-roadmap.json"
        }
        RoadmapReport = @{
            Enabled = $true
            ScriptPath = "development\scripts\maintenance\modes\roadmap-report-mode.ps1"
            DefaultReportFormat = "HTML"
            DefaultOutputPath = $testDir
            IncludeCharts = $true
            IncludeTrends = $true
            IncludePredictions = $true
            DaysToAnalyze = 30
        }
        RoadmapPlan = @{
            Enabled = $true
            ScriptPath = "development\scripts\maintenance\modes\roadmap-plan-mode.ps1"
            DefaultOutputPath = $testDir
            DaysToForecast = 30
        }
    }
} | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8

# Créer un module mock pour RoadmapParser
$mockRoadmapParserPath = Join-Path -Path $testDir -ChildPath "MockRoadmapParser.psm1"
@"
function ConvertFrom-MarkdownToJson {
    param (
        [string]`$MarkdownPath,
        [string]`$JsonPath
    )
    
    # Simuler la conversion de Markdown vers JSON
    `$json = @{
        Title = "Roadmap de test unitaire"
        Tasks = @(
            @{
                Title = "Tâche 1: Test des modes de roadmap"
                SubTasks = @(
                    @{ Title = "Tester le mode ROADMAP-SYNC"; IsCompleted = `$false },
                    @{ Title = "Tester le mode ROADMAP-REPORT"; IsCompleted = `$false },
                    @{ Title = "Tester le mode ROADMAP-PLAN"; IsCompleted = `$false }
                )
            }
        )
    } | ConvertTo-Json -Depth 5
    
    Set-Content -Path `$JsonPath -Value `$json -Encoding UTF8
    
    return `$json
}

function ConvertFrom-MarkdownToHtml {
    param (
        [string]`$MarkdownPath,
        [string]`$HtmlPath
    )
    
    # Simuler la conversion de Markdown vers HTML
    `$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Roadmap de test unitaire</title>
</head>
<body>
    <h1>Roadmap de test unitaire</h1>
    <h2>Tâche 1: Test des modes de roadmap</h2>
    <h3>Description</h3>
    <p>Cette tâche vise à tester les modes de roadmap.</p>
    <h3>Sous-tâches</h3>
    <ul>
        <li>[ ] <strong>1.1</strong> Tester le mode ROADMAP-SYNC</li>
        <li>[ ] <strong>1.2</strong> Tester le mode ROADMAP-REPORT</li>
        <li>[ ] <strong>1.3</strong> Tester le mode ROADMAP-PLAN</li>
    </ul>
</body>
</html>
"@
    
    Set-Content -Path `$HtmlPath -Value `$html -Encoding UTF8
    
    return `$html
}

function ConvertFrom-MarkdownToCsv {
    param (
        [string]`$MarkdownPath,
        [string]`$CsvPath
    )
    
    # Simuler la conversion de Markdown vers CSV
    `$csv = @"
"TaskGroup","TaskId","TaskTitle","IsCompleted"
"Tâche 1: Test des modes de roadmap","1.1","Tester le mode ROADMAP-SYNC","False"
"Tâche 1: Test des modes de roadmap","1.2","Tester le mode ROADMAP-REPORT","False"
"Tâche 1: Test des modes de roadmap","1.3","Tester le mode ROADMAP-PLAN","False"
"@
    
    Set-Content -Path `$CsvPath -Value `$csv -Encoding UTF8
    
    return `$csv
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

function New-JsonReport {
    param (
        [hashtable]`$Analysis,
        [string]`$OutputPath
    )
    
    # Simuler la génération d'un rapport JSON
    `$reportPath = Join-Path -Path `$OutputPath -ChildPath "roadmap-report.json"
    
    `$json = `$Analysis | ConvertTo-Json -Depth 5
    
    Set-Content -Path `$reportPath -Value `$json -Encoding UTF8
    
    return `$reportPath
}

function New-CsvReport {
    param (
        [hashtable]`$Analysis,
        [string]`$OutputPath
    )
    
    # Simuler la génération d'un rapport CSV
    `$reportPath = Join-Path -Path `$OutputPath -ChildPath "roadmap-report.csv"
    
    `$csv = @"
"Property","Value"
"RoadmapPath","`$(`$Analysis.RoadmapPath)"
"TotalTasks","`$(`$Analysis.TotalTasks)"
"CompletedTasks","`$(`$Analysis.CompletedTasks)"
"CompletionPercentage","`$(`$Analysis.CompletionPercentage)"
"AnalysisDate","`$(`$Analysis.AnalysisDate)"
"@
    
    Set-Content -Path `$reportPath -Value `$csv -Encoding UTF8
    
    return `$reportPath
}

function New-MarkdownReport {
    param (
        [hashtable]`$Analysis,
        [string]`$OutputPath
    )
    
    # Simuler la génération d'un rapport Markdown
    `$reportPath = Join-Path -Path `$OutputPath -ChildPath "roadmap-report.md"
    
    `$markdown = @"
# Rapport de Roadmap

## Résumé

- **Roadmap** : `$(`$Analysis.RoadmapPath)
- **Tâches totales** : `$(`$Analysis.TotalTasks)
- **Tâches complétées** : `$(`$Analysis.CompletedTasks)
- **Pourcentage de complétion** : `$(`$Analysis.CompletionPercentage)%
- **Date d'analyse** : `$(`$Analysis.AnalysisDate)
"@
    
    Set-Content -Path `$reportPath -Value `$markdown -Encoding UTF8
    
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
                TaskGroup = "Tâche 1: Test des modes de roadmap"
                SubTaskId = "1.1"
                SubTaskTitle = "Tester le mode ROADMAP-SYNC"
                StartDate = (Get-Date).ToString("yyyy-MM-dd")
                EndDate = (Get-Date).AddDays(3).ToString("yyyy-MM-dd")
                EstimatedDays = 3
            },
            @{
                TaskGroup = "Tâche 1: Test des modes de roadmap"
                SubTaskId = "1.2"
                SubTaskTitle = "Tester le mode ROADMAP-REPORT"
                StartDate = (Get-Date).AddDays(3).ToString("yyyy-MM-dd")
                EndDate = (Get-Date).AddDays(6).ToString("yyyy-MM-dd")
                EstimatedDays = 3
            },
            @{
                TaskGroup = "Tâche 1: Test des modes de roadmap"
                SubTaskId = "1.3"
                SubTaskTitle = "Tester le mode ROADMAP-PLAN"
                StartDate = (Get-Date).AddDays(6).ToString("yyyy-MM-dd")
                EndDate = (Get-Date).AddDays(9).ToString("yyyy-MM-dd")
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

Export-ModuleMember -Function ConvertFrom-MarkdownToJson, ConvertFrom-MarkdownToHtml, ConvertFrom-MarkdownToCsv, Get-RoadmapAnalysis, New-HtmlReport, New-JsonReport, New-CsvReport, New-MarkdownReport, New-ActionPlan, New-PlanReport
"@ | Set-Content -Path $mockRoadmapParserPath -Encoding UTF8

# Définir les tests
Describe "Tests unitaires standards pour les modes de roadmap" {
    BeforeAll {
        # Créer un mock pour Import-Module
        Mock Import-Module {
            # Ne rien faire, juste simuler l'importation
        } -ModuleName "Test-UnitRoadmapModes"
        
        # Créer un mock pour le module RoadmapParser
        Mock Import-Module {
            Import-Module $mockRoadmapParserPath -Force
        } -ParameterFilter { $Name -match "RoadmapParser" }
        
        # Créer un mock pour Get-Content
        Mock Get-Content {
            if ($Path -eq $testConfigPath) {
                return Get-Content -Path $testConfigPath -Raw
            } elseif ($Path -eq $testRoadmapPath) {
                return Get-Content -Path $testRoadmapPath -Raw
            } else {
                return $null
            }
        } -ModuleName "Test-UnitRoadmapModes"
        
        # Créer un mock pour Test-Path
        Mock Test-Path {
            if ($Path -eq $testConfigPath) {
                return $true
            } elseif ($Path -eq $testRoadmapPath) {
                return $true
            } elseif ($Path -match "roadmap-sync-mode.ps1") {
                return $true
            } elseif ($Path -match "roadmap-report-mode.ps1") {
                return $true
            } elseif ($Path -match "roadmap-plan-mode.ps1") {
                return $true
            } else {
                return $false
            }
        } -ModuleName "Test-UnitRoadmapModes"
        
        # Créer un mock pour ConvertFrom-Json
        Mock ConvertFrom-Json {
            return Get-Content -Path $testConfigPath -Raw | ConvertFrom-Json
        } -ModuleName "Test-UnitRoadmapModes"
        
        # Créer un mock pour Set-Content
        Mock Set-Content {
            # Ne rien faire, juste simuler l'écriture
        } -ModuleName "Test-UnitRoadmapModes"
        
        # Créer un mock pour Join-Path
        Mock Join-Path {
            if ($ChildPath -match "roadmap-report.html") {
                return Join-Path -Path $testDir -ChildPath "roadmap-report.html"
            } elseif ($ChildPath -match "roadmap-report.json") {
                return Join-Path -Path $testDir -ChildPath "roadmap-report.json"
            } elseif ($ChildPath -match "roadmap-report.csv") {
                return Join-Path -Path $testDir -ChildPath "roadmap-report.csv"
            } elseif ($ChildPath -match "roadmap-report.md") {
                return Join-Path -Path $testDir -ChildPath "roadmap-report.md"
            } elseif ($ChildPath -match "roadmap-plan.md") {
                return Join-Path -Path $testDir -ChildPath "roadmap-plan.md"
            } else {
                return Join-Path -Path $Path -ChildPath $ChildPath
            }
        } -ModuleName "Test-UnitRoadmapModes"
    }
    
    Context "Mode ROADMAP-SYNC" {
        It "Le mode ROADMAP-SYNC devrait pouvoir convertir de Markdown vers JSON" {
            $result = & $roadmapSyncPath -SourcePath $testRoadmapPath -TargetFormat "JSON" -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le mode ROADMAP-SYNC devrait pouvoir convertir de Markdown vers HTML" {
            $result = & $roadmapSyncPath -SourcePath $testRoadmapPath -TargetFormat "HTML" -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le mode ROADMAP-SYNC devrait pouvoir convertir de Markdown vers CSV" {
            $result = & $roadmapSyncPath -SourcePath $testRoadmapPath -TargetFormat "CSV" -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le mode ROADMAP-SYNC devrait pouvoir convertir plusieurs roadmaps en une seule opération" {
            $sourcePaths = @($testRoadmapPath, $testRoadmapPath)
            $result = & $roadmapSyncPath -SourcePath $sourcePaths -MultiSync -TargetFormat "JSON" -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
    }
    
    Context "Mode ROADMAP-REPORT" {
        It "Le mode ROADMAP-REPORT devrait pouvoir générer un rapport HTML" {
            $result = & $roadmapReportPath -RoadmapPath $testRoadmapPath -ReportFormat "HTML" -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le mode ROADMAP-REPORT devrait pouvoir générer un rapport JSON" {
            $result = & $roadmapReportPath -RoadmapPath $testRoadmapPath -ReportFormat "JSON" -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le mode ROADMAP-REPORT devrait pouvoir générer un rapport CSV" {
            $result = & $roadmapReportPath -RoadmapPath $testRoadmapPath -ReportFormat "CSV" -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le mode ROADMAP-REPORT devrait pouvoir générer un rapport Markdown" {
            $result = & $roadmapReportPath -RoadmapPath $testRoadmapPath -ReportFormat "Markdown" -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le mode ROADMAP-REPORT devrait pouvoir générer des rapports dans tous les formats" {
            $result = & $roadmapReportPath -RoadmapPath $testRoadmapPath -ReportFormat "All" -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
    }
    
    Context "Mode ROADMAP-PLAN" {
        It "Le mode ROADMAP-PLAN devrait pouvoir générer un plan d'action" {
            $result = & $roadmapPlanPath -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le mode ROADMAP-PLAN devrait pouvoir générer un plan d'action avec une période de prévision personnalisée" {
            $result = & $roadmapPlanPath -RoadmapPath $testRoadmapPath -DaysToForecast 60 -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
        
        It "Le mode ROADMAP-PLAN devrait pouvoir générer un plan d'action dans un fichier spécifique" {
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-plan.md"
            $result = & $roadmapPlanPath -RoadmapPath $testRoadmapPath -OutputPath $outputPath -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
