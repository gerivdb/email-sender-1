<#
.SYNOPSIS
    Tests pour le script dev-r-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script dev-r-mode.ps1
    qui implÃ©mente le mode DEV-R (Roadmap Delivery) pour implÃ©menter mÃ©thodiquement les tÃ¢ches
    confirmÃ©es dans la roadmap.

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
$devRModePath = Join-Path -Path $projectRoot -ChildPath "dev-r-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokeDevRPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapDelivery.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $devRModePath)) {
    Write-Warning "Le script dev-r-mode.ps1 est introuvable Ã  l'emplacement : $devRModePath"
}

if (-not (Test-Path -Path $invokeDevRPath)) {
    Write-Warning "Le fichier Invoke-RoadmapDelivery.ps1 est introuvable Ã  l'emplacement : $invokeDevRPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeDevRPath) {
    . $invokeDevRPath
    Write-Host "Fonction Invoke-RoadmapDelivery importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** ImplÃ©mentation des fonctionnalitÃ©s de base
  - [ ] **1.1.1** DÃ©velopper la fonction d'inspection de variables
  - [ ] **1.1.2** ImplÃ©menter la fonction de validation d'entrÃ©es
- [ ] **1.2** ImplÃ©mentation des fonctionnalitÃ©s avancÃ©es
  - [ ] **1.2.1** DÃ©velopper la fonction d'analyse de donnÃ©es
  - [ ] **1.2.2** ImplÃ©menter la fonction de gÃ©nÃ©ration de rapports

## Section 2

- [ ] **2.1** Tests d'intÃ©gration
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"
$testTestsPath = Join-Path -Path $env:TEMP -ChildPath "TestTests_$(Get-Random)"

# CrÃ©er la structure des rÃ©pertoires de test
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
New-Item -Path $testTestsPath -ItemType Directory -Force | Out-Null

Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green
Write-Host "RÃ©pertoire de tests crÃ©Ã© : $testTestsPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapDelivery" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDelivery -RoadmapPath $testFilePath -TaskIdentifier "1.1.1" -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le fichier de roadmap n'existe pas" {
        # Appeler la fonction avec un fichier inexistant
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapDelivery -RoadmapPath "FichierInexistant.md" -TaskIdentifier "1.1.1" -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }

    It "Devrait lever une exception si l'identifiant de tÃ¢che est invalide" {
        # Appeler la fonction avec un identifiant de tÃ¢che invalide
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapDelivery -RoadmapPath $testFilePath -TaskIdentifier "9.9.9" -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }

    It "Devrait implÃ©menter la fonction spÃ©cifiÃ©e" {
        # Appeler la fonction et vÃ©rifier l'implÃ©mentation
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDelivery -RoadmapPath $testFilePath -TaskIdentifier "1.1.1" -OutputPath $testOutputPath
            
            # VÃ©rifier que le fichier d'implÃ©mentation est crÃ©Ã©
            $implementationPath = Join-Path -Path $testOutputPath -ChildPath "Inspect-Variable.ps1"
            Test-Path -Path $implementationPath | Should -Be $true
            
            # VÃ©rifier que le contenu du fichier contient une fonction
            $implementationContent = Get-Content -Path $implementationPath -Raw
            $implementationContent | Should -Match "function Inspect-Variable"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer des tests pour la fonction implÃ©mentÃ©e" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration de tests
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDelivery -RoadmapPath $testFilePath -TaskIdentifier "1.1.1" -OutputPath $testOutputPath -GenerateTests $true -TestsPath $testTestsPath
            
            # VÃ©rifier que le fichier de test est crÃ©Ã©
            $testPath = Join-Path -Path $testTestsPath -ChildPath "Test-InspectVariable.ps1"
            Test-Path -Path $testPath | Should -Be $true
            
            # VÃ©rifier que le contenu du fichier contient des tests
            $testContent = Get-Content -Path $testPath -Raw
            $testContent | Should -Match "Describe"
            $testContent | Should -Match "It"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }

    It "Devrait mettre Ã  jour la roadmap" {
        # Appeler la fonction et vÃ©rifier la mise Ã  jour de la roadmap
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            # CrÃ©er une copie de la roadmap pour le test
            $testRoadmapCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmapCopy_$(Get-Random).md"
            Copy-Item -Path $testFilePath -Destination $testRoadmapCopyPath
            
            $result = Invoke-RoadmapDelivery -RoadmapPath $testRoadmapCopyPath -TaskIdentifier "1.1.1" -OutputPath $testOutputPath -UpdateRoadmap $true
            
            # VÃ©rifier que la roadmap est mise Ã  jour
            $roadmapContent = Get-Content -Path $testRoadmapCopyPath -Raw
            $roadmapContent | Should -Match "\[x\] \*\*1\.1\.1\*\* DÃ©velopper la fonction d'inspection de variables"
            
            # Supprimer la copie de la roadmap
            Remove-Item -Path $testRoadmapCopyPath -Force
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script dev-r-mode.ps1
Describe "dev-r-mode.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path $devRModePath) {
            # ExÃ©cuter le script
            $output = & $devRModePath -RoadmapPath $testFilePath -TaskIdentifier "1.1.1" -OutputPath $testOutputPath -GenerateTests $true -TestsPath $testTestsPath
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que les fichiers attendus existent
            $implementationPath = Join-Path -Path $testOutputPath -ChildPath "Inspect-Variable.ps1"
            Test-Path -Path $implementationPath | Should -Be $true
            
            $testPath = Join-Path -Path $testTestsPath -ChildPath "Test-InspectVariable.ps1"
            Test-Path -Path $testPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script dev-r-mode.ps1 n'est pas disponible"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "RÃ©pertoire de sortie supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testTestsPath) {
    Remove-Item -Path $testTestsPath -Recurse -Force
    Write-Host "RÃ©pertoire de tests supprimÃ©." -ForegroundColor Gray
}

# ExÃ©cuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminÃ©s. Utilisez Invoke-Pester pour exÃ©cuter les tests avec le framework Pester." -ForegroundColor Yellow
}
