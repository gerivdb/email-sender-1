<#
.SYNOPSIS
    Tests pour le script debug-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script debug-mode.ps1
    qui implÃ©mente le mode DEBUG pour isoler, comprendre et corriger les anomalies dans le code.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installÃ©. Les tests ne seront pas exÃ©cutÃ©s avec le framework Pester."
}

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$debugModePath = Join-Path -Path $projectRoot -ChildPath "debug-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokeDebugPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapDebug.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $debugModePath)) {
    Write-Warning "Le script debug-mode.ps1 est introuvable Ã  l'emplacement : $debugModePath"
}

if (-not (Test-Path -Path $invokeDebugPath)) {
    Write-Warning "Le fichier Invoke-RoadmapDebug.ps1 est introuvable Ã  l'emplacement : $invokeDebugPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeDebugPath) {
    . $invokeDebugPath
    Write-Host "Fonction Invoke-RoadmapDebug importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Correction de bugs
  - [ ] **1.1.1** Corriger le bug de rÃ©fÃ©rence nulle
  - [ ] **1.1.2** RÃ©soudre le problÃ¨me de performance
- [ ] **1.2** AmÃ©liorations
  - [ ] **1.2.1** Optimiser l'algorithme
  - [ ] **1.2.2** AmÃ©liorer l'interface utilisateur

## Section 2

- [ ] **2.1** Tests de rÃ©gression
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"
$testErrorLogPath = Join-Path -Path $env:TEMP -ChildPath "TestErrorLog_$(Get-Random).log"

# CrÃ©er la structure du module de test
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er un fichier de code avec un bug pour les tests
@"
function Invoke-Data {
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$Data
    )
    
    # Bug: AccÃ¨s Ã  une propriÃ©tÃ© sans vÃ©rifier si l'objet est null
    `$result = `$Data.Value.ToString()
    
    return `$result
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "BuggyFunction.ps1") -Encoding UTF8

# CrÃ©er un fichier de log d'erreur
@"
[ERROR] 2023-08-15T10:15:30 - NullReferenceException in Invoke-Data: Object reference not set to an instance of an object.
   at Invoke-Data, D:\Path\To\BuggyFunction.ps1: line 8
   at CallSite.Target(Closure , CallSite , Object )
Stack trace:
   at Invoke-Data(`$Data = null)
   at Invoke-ProcessData(`$InputData = null)
   at Main()
"@ | Set-Content -Path $testErrorLogPath -Encoding UTF8

Write-Host "Module de test crÃ©Ã© : $testModulePath" -ForegroundColor Green
Write-Host "Fichier de log d'erreur crÃ©Ã© : $testErrorLogPath" -ForegroundColor Green
Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapDebug" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDebug -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le fichier de log n'existe pas" {
        # Appeler la fonction avec un fichier inexistant
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapDebug -ErrorLog "FichierInexistant.log" -ModulePath $testModulePath -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }

    It "Devrait identifier correctement l'origine de l'erreur" {
        # Appeler la fonction et vÃ©rifier l'identification de l'erreur
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDebug -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath
            
            # VÃ©rifier que l'origine de l'erreur est correctement identifiÃ©e
            $result.ErrorOrigin | Should -Be "Invoke-Data"
            $result.ErrorType | Should -Be "NullReferenceException"
            $result.ErrorLine | Should -Be 8
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer un rapport de dÃ©bogage" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration du rapport
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDebug -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath -GeneratePatch $true
            
            # VÃ©rifier que le rapport est gÃ©nÃ©rÃ©
            $debugReportPath = Join-Path -Path $testOutputPath -ChildPath "debug_report.md"
            Test-Path -Path $debugReportPath | Should -Be $true
            
            # VÃ©rifier que le contenu du rapport contient les informations attendues
            $reportContent = Get-Content -Path $debugReportPath -Raw
            $reportContent | Should -Match "NullReferenceException"
            $reportContent | Should -Match "Invoke-Data"
            $reportContent | Should -Match "BuggyFunction.ps1"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer un patch correctif" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration du patch
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDebug -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath -GeneratePatch $true
            
            # VÃ©rifier que le patch est gÃ©nÃ©rÃ©
            $patchPath = Join-Path -Path $testOutputPath -ChildPath "fix_patch.ps1"
            Test-Path -Path $patchPath | Should -Be $true
            
            # VÃ©rifier que le contenu du patch contient la correction attendue
            $patchContent = Get-Content -Path $patchPath -Raw
            $patchContent | Should -Match "if \(`\$null -ne `\$Data\.Value\)"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script debug-mode.ps1
Describe "debug-mode.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path $debugModePath) {
            # ExÃ©cuter le script
            $output = & $debugModePath -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath -GeneratePatch $true
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que les fichiers attendus existent
            $debugReportPath = Join-Path -Path $testOutputPath -ChildPath "debug_report.md"
            Test-Path -Path $debugReportPath | Should -Be $true
            
            $patchPath = Join-Path -Path $testOutputPath -ChildPath "fix_patch.ps1"
            Test-Path -Path $patchPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script debug-mode.ps1 n'est pas disponible"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testModulePath) {
    Remove-Item -Path $testModulePath -Recurse -Force
    Write-Host "Module de test supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testErrorLogPath) {
    Remove-Item -Path $testErrorLogPath -Force
    Write-Host "Fichier de log d'erreur supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "RÃ©pertoire de sortie supprimÃ©." -ForegroundColor Gray
}

# ExÃ©cuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminÃ©s. Utilisez Invoke-Pester pour exÃ©cuter les tests avec le framework Pester." -ForegroundColor Yellow
}

