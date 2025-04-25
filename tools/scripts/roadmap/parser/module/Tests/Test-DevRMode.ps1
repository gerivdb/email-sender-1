<#
.SYNOPSIS
    Tests pour le script dev-r-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script dev-r-mode.ps1
    qui implémente le mode DEV-R (Roadmap Delivery) pour implémenter méthodiquement les tâches
    confirmées dans la roadmap.

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
$devRModePath = Join-Path -Path $projectRoot -ChildPath "dev-r-mode.ps1"

# Chemin vers les fonctions à tester
$invokeDevRPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapDelivery.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $devRModePath)) {
    Write-Warning "Le script dev-r-mode.ps1 est introuvable à l'emplacement : $devRModePath"
}

if (-not (Test-Path -Path $invokeDevRPath)) {
    Write-Warning "Le fichier Invoke-RoadmapDelivery.ps1 est introuvable à l'emplacement : $invokeDevRPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeDevRPath) {
    . $invokeDevRPath
    Write-Host "Fonction Invoke-RoadmapDelivery importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Implémentation des fonctionnalités de base
  - [ ] **1.1.1** Développer la fonction d'inspection de variables
  - [ ] **1.1.2** Implémenter la fonction de validation d'entrées
- [ ] **1.2** Implémentation des fonctionnalités avancées
  - [ ] **1.2.1** Développer la fonction d'analyse de données
  - [ ] **1.2.2** Implémenter la fonction de génération de rapports

## Section 2

- [ ] **2.1** Tests d'intégration
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"
$testTestsPath = Join-Path -Path $env:TEMP -ChildPath "TestTests_$(Get-Random)"

# Créer la structure des répertoires de test
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
New-Item -Path $testTestsPath -ItemType Directory -Force | Out-Null

Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green
Write-Host "Répertoire de tests créé : $testTestsPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapDelivery" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
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

    It "Devrait lever une exception si l'identifiant de tâche est invalide" {
        # Appeler la fonction avec un identifiant de tâche invalide
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapDelivery -RoadmapPath $testFilePath -TaskIdentifier "9.9.9" -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }

    It "Devrait implémenter la fonction spécifiée" {
        # Appeler la fonction et vérifier l'implémentation
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDelivery -RoadmapPath $testFilePath -TaskIdentifier "1.1.1" -OutputPath $testOutputPath
            
            # Vérifier que le fichier d'implémentation est créé
            $implementationPath = Join-Path -Path $testOutputPath -ChildPath "Inspect-Variable.ps1"
            Test-Path -Path $implementationPath | Should -Be $true
            
            # Vérifier que le contenu du fichier contient une fonction
            $implementationContent = Get-Content -Path $implementationPath -Raw
            $implementationContent | Should -Match "function Inspect-Variable"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }

    It "Devrait générer des tests pour la fonction implémentée" {
        # Appeler la fonction et vérifier la génération de tests
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDelivery -RoadmapPath $testFilePath -TaskIdentifier "1.1.1" -OutputPath $testOutputPath -GenerateTests $true -TestsPath $testTestsPath
            
            # Vérifier que le fichier de test est créé
            $testPath = Join-Path -Path $testTestsPath -ChildPath "Test-InspectVariable.ps1"
            Test-Path -Path $testPath | Should -Be $true
            
            # Vérifier que le contenu du fichier contient des tests
            $testContent = Get-Content -Path $testPath -Raw
            $testContent | Should -Match "Describe"
            $testContent | Should -Match "It"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }

    It "Devrait mettre à jour la roadmap" {
        # Appeler la fonction et vérifier la mise à jour de la roadmap
        if (Get-Command -Name Invoke-RoadmapDelivery -ErrorAction SilentlyContinue) {
            # Créer une copie de la roadmap pour le test
            $testRoadmapCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmapCopy_$(Get-Random).md"
            Copy-Item -Path $testFilePath -Destination $testRoadmapCopyPath
            
            $result = Invoke-RoadmapDelivery -RoadmapPath $testRoadmapCopyPath -TaskIdentifier "1.1.1" -OutputPath $testOutputPath -UpdateRoadmap $true
            
            # Vérifier que la roadmap est mise à jour
            $roadmapContent = Get-Content -Path $testRoadmapCopyPath -Raw
            $roadmapContent | Should -Match "\[x\] \*\*1\.1\.1\*\* Développer la fonction d'inspection de variables"
            
            # Supprimer la copie de la roadmap
            Remove-Item -Path $testRoadmapCopyPath -Force
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDelivery n'est pas disponible"
        }
    }
}

# Test d'intégration du script dev-r-mode.ps1
Describe "dev-r-mode.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path $devRModePath) {
            # Exécuter le script
            $output = & $devRModePath -RoadmapPath $testFilePath -TaskIdentifier "1.1.1" -OutputPath $testOutputPath -GenerateTests $true -TestsPath $testTestsPath
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que les fichiers attendus existent
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
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "Répertoire de sortie supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testTestsPath) {
    Remove-Item -Path $testTestsPath -Recurse -Force
    Write-Host "Répertoire de tests supprimé." -ForegroundColor Gray
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}
