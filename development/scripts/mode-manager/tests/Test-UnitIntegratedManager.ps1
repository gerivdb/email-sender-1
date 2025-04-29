<#
.SYNOPSIS
    Tests unitaires standards pour le gestionnaire intÃ©grÃ©.

.DESCRIPTION
    Ce script contient des tests unitaires standards pour vÃ©rifier le bon fonctionnement du gestionnaire intÃ©grÃ©.
    Ces tests utilisent des mocks pour simuler les dÃ©pendances et vÃ©rifier que le gestionnaire intÃ©grÃ© fonctionne correctement.
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
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1"

# CrÃ©er un rÃ©pertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "unit-test-roadmap.md"
@"
# Roadmap de test unitaire

## TÃ¢che 1: Test du gestionnaire intÃ©grÃ©

### Description
Cette tÃ¢che vise Ã  tester le gestionnaire intÃ©grÃ©.

### Sous-tÃ¢ches
- [ ] **1.1** Tester l'exÃ©cution des modes
- [ ] **1.2** Tester l'exÃ©cution des workflows
- [ ] **1.3** Tester la configuration
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# CrÃ©er un fichier de configuration de test
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
        Check = @{
            Enabled = $true
            ScriptPath = "development\scripts\maintenance\modes\check.ps1"
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
            ScriptPath = "development\scripts\maintenance\modes\gran-mode.ps1"
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
    Workflows = @{
        UnitTest = @{
            Description = "Workflow de test unitaire"
            Modes = @("CHECK", "GRAN", "ROADMAP-SYNC", "ROADMAP-REPORT", "ROADMAP-PLAN")
            AutoContinue = $true
            StopOnError = $true
        }
    }
} | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8

# DÃ©finir les tests
Describe "Tests unitaires standards pour le gestionnaire intÃ©grÃ©" {
    BeforeAll {
        # CrÃ©er des mocks pour les modes
        function global:Invoke-CheckMode {
            param (
                [string]$FilePath,
                [string]$TaskIdentifier,
                [bool]$UpdateRoadmap,
                [bool]$GenerateReport,
                [string]$ReportPath,
                [bool]$Force,
                [string]$ConfigPath,
                [switch]$WhatIf
            )
            
            return @{
                Success = $true
                FilePath = $FilePath
                TaskIdentifier = $TaskIdentifier
                UpdateRoadmap = $UpdateRoadmap
                GenerateReport = $GenerateReport
                ReportPath = $ReportPath
                Force = $Force
                ConfigPath = $ConfigPath
                WhatIf = $WhatIf
            }
        }
        
        function global:Invoke-GranMode {
            param (
                [string]$FilePath,
                [string]$TaskIdentifier,
                [string]$SubTasksFile,
                [string]$IndentationStyle,
                [string]$CheckboxStyle,
                [string]$ConfigPath,
                [switch]$WhatIf
            )
            
            return @{
                Success = $true
                FilePath = $FilePath
                TaskIdentifier = $TaskIdentifier
                SubTasksFile = $SubTasksFile
                IndentationStyle = $IndentationStyle
                CheckboxStyle = $CheckboxStyle
                ConfigPath = $ConfigPath
                WhatIf = $WhatIf
            }
        }
        
        function global:Invoke-RoadmapSyncMode {
            param (
                [object]$SourcePath,
                [object]$TargetPath,
                [string]$SourceFormat,
                [string]$TargetFormat,
                [bool]$Force,
                [bool]$MultiSync,
                [string]$ConfigPath,
                [switch]$WhatIf
            )
            
            return @{
                Success = $true
                SourcePath = $SourcePath
                TargetPath = $TargetPath
                SourceFormat = $SourceFormat
                TargetFormat = $TargetFormat
                Force = $Force
                MultiSync = $MultiSync
                ConfigPath = $ConfigPath
                WhatIf = $WhatIf
            }
        }
        
        function global:Invoke-RoadmapReportMode {
            param (
                [string]$RoadmapPath,
                [string]$OutputPath,
                [string]$ReportFormat,
                [bool]$IncludeCharts,
                [bool]$IncludeTrends,
                [bool]$IncludePredictions,
                [int]$DaysToAnalyze,
                [string]$ConfigPath,
                [switch]$WhatIf
            )
            
            return @{
                Success = $true
                RoadmapPath = $RoadmapPath
                OutputPath = $OutputPath
                ReportFormat = $ReportFormat
                IncludeCharts = $IncludeCharts
                IncludeTrends = $IncludeTrends
                IncludePredictions = $IncludePredictions
                DaysToAnalyze = $DaysToAnalyze
                ConfigPath = $ConfigPath
                WhatIf = $WhatIf
            }
        }
        
        function global:Invoke-RoadmapPlanMode {
            param (
                [string]$RoadmapPath,
                [string]$OutputPath,
                [int]$DaysToForecast,
                [string]$ConfigPath,
                [switch]$WhatIf
            )
            
            return @{
                Success = $true
                RoadmapPath = $RoadmapPath
                OutputPath = $OutputPath
                DaysToForecast = $DaysToForecast
                ConfigPath = $ConfigPath
                WhatIf = $WhatIf
            }
        }
        
        # CrÃ©er un mock pour Get-Content
        Mock Get-Content {
            if ($Path -eq $testConfigPath) {
                return Get-Content -Path $testConfigPath -Raw
            } else {
                return $null
            }
        } -ModuleName "Test-UnitIntegratedManager"
        
        # CrÃ©er un mock pour Test-Path
        Mock Test-Path {
            if ($Path -eq $testConfigPath) {
                return $true
            } elseif ($Path -eq $testRoadmapPath) {
                return $true
            } else {
                return $false
            }
        } -ModuleName "Test-UnitIntegratedManager"
        
        # CrÃ©er un mock pour ConvertFrom-Json
        Mock ConvertFrom-Json {
            return Get-Content -Path $testConfigPath -Raw | ConvertFrom-Json
        } -ModuleName "Test-UnitIntegratedManager"
        
        # CrÃ©er un mock pour Invoke-Expression
        Mock Invoke-Expression {
            if ($Command -match "check.ps1") {
                return Invoke-CheckMode
            } elseif ($Command -match "gran-mode.ps1") {
                return Invoke-GranMode
            } elseif ($Command -match "roadmap-sync-mode.ps1") {
                return Invoke-RoadmapSyncMode
            } elseif ($Command -match "roadmap-report-mode.ps1") {
                return Invoke-RoadmapReportMode
            } elseif ($Command -match "roadmap-plan-mode.ps1") {
                return Invoke-RoadmapPlanMode
            } else {
                return $null
            }
        } -ModuleName "Test-UnitIntegratedManager"
    }
    
    AfterAll {
        # Supprimer les mocks
        Remove-Item -Path function:global:Invoke-CheckMode -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Invoke-GranMode -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Invoke-RoadmapSyncMode -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Invoke-RoadmapReportMode -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Invoke-RoadmapPlanMode -ErrorAction SilentlyContinue
    }
    
    Context "ExÃ©cution des modes" {
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode CHECK" {
            $result = & $integratedManagerPath -Mode "CHECK" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode GRAN" {
            $result = & $integratedManagerPath -Mode "GRAN" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.1" -ConfigPath $testConfigPath -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode ROADMAP-SYNC" {
            $result = & $integratedManagerPath -Mode "ROADMAP-SYNC" -SourcePath $testRoadmapPath -TargetFormat "JSON" -ConfigPath $testConfigPath -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode ROADMAP-REPORT" {
            $result = & $integratedManagerPath -Mode "ROADMAP-REPORT" -RoadmapPath $testRoadmapPath -ReportFormat "HTML" -ConfigPath $testConfigPath -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le mode ROADMAP-PLAN" {
            $result = & $integratedManagerPath -Mode "ROADMAP-PLAN" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "ExÃ©cution des workflows" {
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir exÃ©cuter le workflow UnitTest" {
            $result = & $integratedManagerPath -Workflow "UnitTest" -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Configuration" {
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir charger la configuration" {
            $result = & $integratedManagerPath -ListModes -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir afficher la liste des modes" {
            $result = & $integratedManagerPath -ListModes -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Le gestionnaire intÃ©grÃ© devrait pouvoir afficher la liste des workflows" {
            $result = & $integratedManagerPath -ListWorkflows -ConfigPath $testConfigPath
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed

