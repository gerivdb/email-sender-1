<#
.SYNOPSIS
    Tests pour le script mode-name.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script mode-name.ps1
    qui implémente le mode MODE_NAME.

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
$modeScriptPath = Join-Path -Path $projectRoot -ChildPath "mode-name.ps1"

# Chemin vers les fonctions à tester
$invokeModeFunctionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-ModeNameFunction.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $modeScriptPath)) {
    Write-Warning "Le script mode-name.ps1 est introuvable à l'emplacement : $modeScriptPath"
}

if (-not (Test-Path -Path $invokeModeFunctionPath)) {
    Write-Warning "Le fichier Invoke-ModeNameFunction.ps1 est introuvable à l'emplacement : $invokeModeFunctionPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeModeFunctionPath) {
    . $invokeModeFunctionPath
    Write-Host "Fonction Invoke-ModeNameFunction importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Tâche 1
  - [ ] **1.1.1** Sous-tâche 1
  - [ ] **1.1.2** Sous-tâche 2
- [ ] **1.2** Tâche 2
  - [ ] **1.2.1** Sous-tâche 1
  - [ ] **1.2.2** Sous-tâche 2

## Section 2

- [ ] **2.1** Autre tâche
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-ModeNameFunction" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            $result = Invoke-ModeNameFunction -FilePath $testFilePath -TaskIdentifier "1.1" -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le fichier n'existe pas" {
        # Appeler la fonction avec un fichier inexistant
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            { Invoke-ModeNameFunction -FilePath "FichierInexistant.md" -TaskIdentifier "1.1" -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }

    It "Devrait lever une exception si l'identifiant de tâche est invalide" {
        # Appeler la fonction avec un identifiant de tâche invalide
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            { Invoke-ModeNameFunction -FilePath $testFilePath -TaskIdentifier "9.9" -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }

    It "Devrait créer les fichiers de sortie attendus" {
        # Appeler la fonction et vérifier les fichiers de sortie
        if (Get-Command -Name Invoke-ModeNameFunction -ErrorAction SilentlyContinue) {
            $result = Invoke-ModeNameFunction -FilePath $testFilePath -TaskIdentifier "1.1" -OutputPath $testOutputPath
            
            # Vérifier que les fichiers attendus existent
            $expectedFile = Join-Path -Path $testOutputPath -ChildPath "expected_output_file.txt"
            Test-Path -Path $expectedFile | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-ModeNameFunction n'est pas disponible"
        }
    }
}

# Test d'intégration du script mode-name.ps1
Describe "mode-name.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path $modeScriptPath) {
            # Exécuter le script
            $output = & $modeScriptPath -FilePath $testFilePath -TaskIdentifier "1.1" -OutputPath $testOutputPath
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que les fichiers attendus existent
            $expectedFile = Join-Path -Path $testOutputPath -ChildPath "expected_output_file.txt"
            Test-Path -Path $expectedFile | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script mode-name.ps1 n'est pas disponible"
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

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}
