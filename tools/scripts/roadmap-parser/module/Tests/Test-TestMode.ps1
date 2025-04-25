<#
.SYNOPSIS
    Tests pour le script test-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script test-mode.ps1
    qui implémente le mode TEST pour maximiser la couverture et la fiabilité du code.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne seront pas exécutés avec le framework Pester."
}

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$testModePath = Join-Path -Path $projectRoot -ChildPath "test-mode.ps1"

# Chemin vers les fonctions à tester
$invokeTestPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapTest.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $testModePath)) {
    Write-Warning "Le script test-mode.ps1 est introuvable à l'emplacement : $testModePath"
}

if (-not (Test-Path -Path $invokeTestPath)) {
    Write-Warning "Le fichier Invoke-RoadmapTest.ps1 est introuvable à l'emplacement : $invokeTestPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeTestPath) {
    . $invokeTestPath
    Write-Host "Fonction Invoke-RoadmapTest importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Fonctionnalités de base
  - [ ] **1.1.1** Implémenter la fonction de calcul
  - [ ] **1.1.2** Développer la fonction de validation
- [ ] **1.2** Fonctionnalités avancées
  - [ ] **1.2.1** Implémenter la fonction d'analyse
  - [ ] **1.2.2** Développer la fonction de reporting

## Section 2

- [ ] **2.1** Tests d'intégration
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
$testTestsPath = Join-Path -Path $env:TEMP -ChildPath "TestTests_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# Créer la structure du module de test
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Public") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Private") -ItemType Directory -Force | Out-Null
New-Item -Path $testTestsPath -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# Créer des fichiers de code pour les tests
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

# Créer des fichiers de test
@"
<#
.SYNOPSIS
    Tests pour la fonction Invoke-Calculation.
#>

# Importer la fonction à tester
. "`$PSScriptRoot\..\Functions\Public\Invoke-Calculation.ps1"

Describe "Invoke-Calculation" {
    It "Devrait additionner correctement deux nombres positifs" {
        Invoke-Calculation -A 2 -B 3 | Should -Be 5
    }
    
    It "Devrait additionner correctement un nombre positif et un nombre négatif" {
        Invoke-Calculation -A 2 -B -3 | Should -Be -1
    }
    
    It "Devrait additionner correctement deux nombres négatifs" {
        Invoke-Calculation -A -2 -B -3 | Should -Be -5
    }
}
"@ | Set-Content -Path (Join-Path -Path $testTestsPath -ChildPath "Test-Calculation.ps1") -Encoding UTF8

Write-Host "Module de test créé : $testModulePath" -ForegroundColor Green
Write-Host "Tests créés : $testTestsPath" -ForegroundColor Green
Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapTest" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
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

    It "Devrait exécuter les tests et générer un rapport de couverture" {
        # Appeler la fonction et vérifier l'exécution des tests
        if (Get-Command -Name Invoke-RoadmapTest -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapTest -ModulePath $testModulePath -TestsPath $testTestsPath -CoverageThreshold 90 -OutputPath $testOutputPath -GenerateReport $true
            
            # Vérifier que le rapport est généré
            $coverageReportPath = Join-Path -Path $testOutputPath -ChildPath "coverage_report.html"
            Test-Path -Path $coverageReportPath | Should -Be $true
            
            # Vérifier les résultats des tests
            $result.TotalTests | Should -BeGreaterThan 0
            $result.PassedTests | Should -BeGreaterThan 0
            $result.Coverage | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapTest n'est pas disponible"
        }
    }

    It "Devrait identifier les fonctions non testées" {
        # Appeler la fonction et vérifier l'identification des fonctions non testées
        if (Get-Command -Name Invoke-RoadmapTest -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapTest -ModulePath $testModulePath -TestsPath $testTestsPath -CoverageThreshold 90 -OutputPath $testOutputPath -GenerateReport $true
            
            # Vérifier que les fonctions non testées sont identifiées
            $result.UncoveredFunctions | Should -Contain "Test-InputValidation"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapTest n'est pas disponible"
        }
    }
}

# Test d'intégration du script test-mode.ps1
Describe "test-mode.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path $testModePath) {
            # Exécuter le script
            $output = & $testModePath -ModulePath $testModulePath -TestsPath $testTestsPath -CoverageThreshold 90 -OutputPath $testOutputPath -GenerateReport $true
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que les fichiers attendus existent
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
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testModulePath) {
    Remove-Item -Path $testModulePath -Recurse -Force
    Write-Host "Module de test supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testTestsPath) {
    Remove-Item -Path $testTestsPath -Recurse -Force
    Write-Host "Tests supprimés." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "Répertoire de sortie supprimé." -ForegroundColor Gray
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}
