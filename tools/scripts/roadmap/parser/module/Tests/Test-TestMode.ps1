<#
.SYNOPSIS
    Tests pour le script test-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script test-mode.ps1
    qui implÃ©mente le mode TEST pour maximiser la couverture et la fiabilitÃ© du code.

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
$testModePath = Join-Path -Path $projectRoot -ChildPath "test-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokeTestPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapTest.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $testModePath)) {
    Write-Warning "Le script test-mode.ps1 est introuvable Ã  l'emplacement : $testModePath"
}

if (-not (Test-Path -Path $invokeTestPath)) {
    Write-Warning "Le fichier Invoke-RoadmapTest.ps1 est introuvable Ã  l'emplacement : $invokeTestPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeTestPath) {
    . $invokeTestPath
    Write-Host "Fonction Invoke-RoadmapTest importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** FonctionnalitÃ©s de base
  - [ ] **1.1.1** ImplÃ©menter la fonction de calcul
  - [ ] **1.1.2** DÃ©velopper la fonction de validation
- [ ] **1.2** FonctionnalitÃ©s avancÃ©es
  - [ ] **1.2.1** ImplÃ©menter la fonction d'analyse
  - [ ] **1.2.2** DÃ©velopper la fonction de reporting

## Section 2

- [ ] **2.1** Tests d'intÃ©gration
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
$testTestsPath = Join-Path -Path $env:TEMP -ChildPath "TestTests_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# CrÃ©er la structure du module de test
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Public") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Private") -ItemType Directory -Force | Out-Null
New-Item -Path $testTestsPath -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de code pour les tests
@"
function Invoke-Calculation {
    param (
        [Parameter(Mandatory = `$true)]
        [int]`$A,
        
        [Parameter(Mandatory = `$true)]
        [int]`$B
    )
    
    return `$A + `$B
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Public\Invoke-Calculation.ps1") -Encoding UTF8

@"
function Test-InputValidation {
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$Input
    )
    
    return `$null -ne `$Input
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Private\Test-InputValidation.ps1") -Encoding UTF8

# CrÃ©er des fichiers de test
@"
<#
.SYNOPSIS
    Tests pour la fonction Invoke-Calculation.
#>

# Importer la fonction Ã  tester
. "`$PSScriptRoot\..\Functions\Public\Invoke-Calculation.ps1"

Describe "Invoke-Calculation" {
    It "Devrait additionner correctement deux nombres positifs" {
        Invoke-Calculation -A 2 -B 3 | Should -Be 5
    }
    
    It "Devrait additionner correctement un nombre positif et un nombre nÃ©gatif" {
        Invoke-Calculation -A 2 -B -3 | Should -Be -1
    }
    
    It "Devrait additionner correctement deux nombres nÃ©gatifs" {
        Invoke-Calculation -A -2 -B -3 | Should -Be -5
    }
}
"@ | Set-Content -Path (Join-Path -Path $testTestsPath -ChildPath "Test-Calculation.ps1") -Encoding UTF8

Write-Host "Module de test crÃ©Ã© : $testModulePath" -ForegroundColor Green
Write-Host "Tests crÃ©Ã©s : $testTestsPath" -ForegroundColor Green
Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapTest" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapTest -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapTest -ModulePath $testModulePath -TestsPath $testTestsPath -CoverageThreshold 90 -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapTest n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le module n'existe pas" {
        # Appeler la fonction avec un module inexistant
        if (Get-Command -Name Invoke-RoadmapTest -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapTest -ModulePath "ModuleInexistant" -TestsPath $testTestsPath -CoverageThreshold 90 -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapTest n'est pas disponible"
        }
    }

    It "Devrait lever une exception si les tests n'existent pas" {
        # Appeler la fonction avec des tests inexistants
        if (Get-Command -Name Invoke-RoadmapTest -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapTest -ModulePath $testModulePath -TestsPath "TestsInexistants" -CoverageThreshold 90 -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapTest n'est pas disponible"
        }
    }

    It "Devrait exÃ©cuter les tests et gÃ©nÃ©rer un rapport de couverture" {
        # Appeler la fonction et vÃ©rifier l'exÃ©cution des tests
        if (Get-Command -Name Invoke-RoadmapTest -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapTest -ModulePath $testModulePath -TestsPath $testTestsPath -CoverageThreshold 90 -OutputPath $testOutputPath -GenerateReport $true
            
            # VÃ©rifier que le rapport est gÃ©nÃ©rÃ©
            $coverageReportPath = Join-Path -Path $testOutputPath -ChildPath "coverage_report.html"
            Test-Path -Path $coverageReportPath | Should -Be $true
            
            # VÃ©rifier les rÃ©sultats des tests
            $result.TotalTests | Should -BeGreaterThan 0
            $result.PassedTests | Should -BeGreaterThan 0
            $result.Coverage | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapTest n'est pas disponible"
        }
    }

    It "Devrait identifier les fonctions non testÃ©es" {
        # Appeler la fonction et vÃ©rifier l'identification des fonctions non testÃ©es
        if (Get-Command -Name Invoke-RoadmapTest -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapTest -ModulePath $testModulePath -TestsPath $testTestsPath -CoverageThreshold 90 -OutputPath $testOutputPath -GenerateReport $true
            
            # VÃ©rifier que les fonctions non testÃ©es sont identifiÃ©es
            $result.UncoveredFunctions | Should -Contain "Test-InputValidation"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapTest n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script test-mode.ps1
Describe "test-mode.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path $testModePath) {
            # ExÃ©cuter le script
            $output = & $testModePath -ModulePath $testModulePath -TestsPath $testTestsPath -CoverageThreshold 90 -OutputPath $testOutputPath -GenerateReport $true
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que les fichiers attendus existent
            $coverageReportPath = Join-Path -Path $testOutputPath -ChildPath "coverage_report.html"
            Test-Path -Path $coverageReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script test-mode.ps1 n'est pas disponible"
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

if (Test-Path -Path $testTestsPath) {
    Remove-Item -Path $testTestsPath -Recurse -Force
    Write-Host "Tests supprimÃ©s." -ForegroundColor Gray
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
