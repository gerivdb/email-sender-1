<#
.SYNOPSIS
    Tests simples pour les modes de roadmap.

.DESCRIPTION
    Ce script contient des tests simples pour vÃ©rifier le bon fonctionnement des modes de roadmap.
    Ces tests vÃ©rifient que les modes de roadmap existent et qu'ils peuvent Ãªtre exÃ©cutÃ©s avec le paramÃ¨tre -WhatIf.
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
$roadmapSyncPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-sync-mode.ps1"
$roadmapReportPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-report-mode.ps1"
$roadmapPlanPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\roadmap-plan-mode.ps1"

# CrÃ©er un rÃ©pertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "simple-test-roadmap.md"
@"
# Roadmap de test simple

## TÃ¢che 1: Test des modes de roadmap

### Description
Cette tÃ¢che vise Ã  tester les modes de roadmap.

### Sous-tÃ¢ches
- [ ] **1.1** Tester le mode ROADMAP-SYNC
- [ ] **1.2** Tester le mode ROADMAP-REPORT
- [ ] **1.3** Tester le mode ROADMAP-PLAN
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# DÃ©finir les tests
Describe "Tests simples pour les modes de roadmap" {
    Context "VÃ©rification de l'existence des modes de roadmap" {
        It "Le mode ROADMAP-SYNC devrait exister" {
            Test-Path -Path $roadmapSyncPath | Should -Be $true
        }
        
        It "Le mode ROADMAP-REPORT devrait exister" {
            Test-Path -Path $roadmapReportPath | Should -Be $true
        }
        
        It "Le mode ROADMAP-PLAN devrait exister" {
            Test-Path -Path $roadmapPlanPath | Should -Be $true
        }
    }
    
    Context "VÃ©rification de l'exÃ©cution des modes de roadmap" {
        It "Le mode ROADMAP-SYNC devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $roadmapSyncPath -SourcePath $testRoadmapPath -TargetFormat "JSON" -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode ROADMAP-REPORT devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $roadmapReportPath -RoadmapPath $testRoadmapPath -ReportFormat "HTML" -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode ROADMAP-PLAN devrait pouvoir Ãªtre exÃ©cutÃ© sans erreur" {
            { & $roadmapPlanPath -RoadmapPath $testRoadmapPath -WhatIf } | Should -Not -Throw
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
