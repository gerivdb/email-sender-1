<#
.SYNOPSIS
    Tests simples pour les modes de roadmap.

.DESCRIPTION
    Ce script contient des tests simples pour vérifier le bon fonctionnement des modes de roadmap.
    Ces tests vérifient que les modes de roadmap existent et qu'ils peuvent être exécutés avec le paramètre -WhatIf.
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
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "simple-test-roadmap.md"
@"
# Roadmap de test simple

## Tâche 1: Test des modes de roadmap

### Description
Cette tâche vise à tester les modes de roadmap.

### Sous-tâches
- [ ] **1.1** Tester le mode ROADMAP-SYNC
- [ ] **1.2** Tester le mode ROADMAP-REPORT
- [ ] **1.3** Tester le mode ROADMAP-PLAN
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Définir les tests
Describe "Tests simples pour les modes de roadmap" {
    Context "Vérification de l'existence des modes de roadmap" {
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
    
    Context "Vérification de l'exécution des modes de roadmap" {
        It "Le mode ROADMAP-SYNC devrait pouvoir être exécuté sans erreur" {
            { & $roadmapSyncPath -SourcePath $testRoadmapPath -TargetFormat "JSON" -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode ROADMAP-REPORT devrait pouvoir être exécuté sans erreur" {
            { & $roadmapReportPath -RoadmapPath $testRoadmapPath -ReportFormat "HTML" -WhatIf } | Should -Not -Throw
        }
        
        It "Le mode ROADMAP-PLAN devrait pouvoir être exécuté sans erreur" {
            { & $roadmapPlanPath -RoadmapPath $testRoadmapPath -WhatIf } | Should -Not -Throw
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed
