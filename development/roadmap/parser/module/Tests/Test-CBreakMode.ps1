# Tests pour le mode C-BREAK

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent $modulePath
$cBreakModePath = Join-Path -Path $projectRoot -ChildPath "c-break-mode.ps1"

# Chemin vers les fonctions à tester
$invokeCycleBreakerPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapCycleBreaker.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $cBreakModePath)) {
    Write-Warning "Le script c-break-mode.ps1 est introuvable à l'emplacement : $cBreakModePath"
}

if (-not (Test-Path -Path $invokeCycleBreakerPath)) {
    Write-Warning "Le fichier Invoke-RoadmapCycleBreaker.ps1 est introuvable à l'emplacement : $invokeCycleBreakerPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeCycleBreakerPath) {
    . $invokeCycleBreakerPath
    Write-Host "Fonction Invoke-RoadmapCycleBreaker importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un module de test avec des dépendances circulaires
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null

# Créer un répertoire de sortie pour les tests
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Test Subtask 1
  - [ ] **1.1.1** Test Subtask 1.1
  - [ ] **1.1.2** Test Subtask 1.2
- [ ] **1.2** Test Subtask 2
  - [ ] **1.2.1** Test Subtask 2.1
  - [ ] **1.2.2** Test Subtask 2.2
"@ | Out-File -FilePath $testFilePath -Encoding UTF8

# Créer des fichiers avec des dépendances circulaires pour les tests
$file1Path = Join-Path -Path $testModulePath -ChildPath "File1.ps1"
$file2Path = Join-Path -Path $testModulePath -ChildPath "File2.ps1"
$file3Path = Join-Path -Path $testModulePath -ChildPath "File3.ps1"

# Fichier 1 dépend de Fichier 3 (cycle)
@"
# Fichier 1
. "$file3Path"

function Test-Function1 {
    Test-Function3
}
"@ | Out-File -FilePath $file1Path -Encoding UTF8

# Fichier 2 dépend de Fichier 1
@"
# Fichier 2
. "$file1Path"

function Test-Function2 {
    Test-Function1
}
"@ | Out-File -FilePath $file2Path -Encoding UTF8

# Fichier 3 dépend de Fichier 1 (cycle)
@"
# Fichier 3
. "$file1Path"

function Test-Function3 {
    Test-Function1
}
"@ | Out-File -FilePath $file3Path -Encoding UTF8

# Tests unitaires avec Pester
Describe "Invoke-RoadmapCycleBreaker" {
    BeforeAll {
        # Préparation avant tous les tests
    }

    AfterAll {
        # Nettoyage après tous les tests
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
        if (Test-Path -Path $testModulePath) {
            Remove-Item -Path $testModulePath -Recurse -Force
        }
        if (Test-Path -Path $testOutputPath) {
            Remove-Item -Path $testOutputPath -Recurse -Force
        }
    }

    It "Devrait exécuter correctement avec des paramètres valides" -Skip {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapCycleBreaker -FilePath $testFilePath -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }

    It "Devrait détecter les cycles de dépendances" -Skip {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapCycleBreaker -FilePath $testFilePath -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
            $result.CycleCount | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }

    It "Devrait générer un rapport de détection" -Skip {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapCycleBreaker -FilePath $testFilePath -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
            $result.ReportPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $result.ReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }
}

# Test d'intégration du script c-break-mode.ps1
Describe "c-break-mode.ps1 Integration" {
    BeforeAll {
        # Préparation avant tous les tests
    }

    AfterAll {
        # Nettoyage après tous les tests
        if (Test-Path -Path $testFilePath) {
            Remove-Item -Path $testFilePath -Force
        }
        if (Test-Path -Path $testModulePath) {
            Remove-Item -Path $testModulePath -Recurse -Force
        }
        if (Test-Path -Path $testOutputPath) {
            Remove-Item -Path $testOutputPath -Recurse -Force
        }
    }

    It "Devrait s'exécuter correctement avec des paramètres valides" -Skip {
        if (Test-Path -Path $cBreakModePath) {
            # Exécuter le script
            $output = & $cBreakModePath -FilePath $testFilePath -OutputPath $testOutputPath -MaxIterations 5
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
        } else {
            Set-ItResult -Skipped -Because "Le script c-break-mode.ps1 n'est pas disponible"
        }
    }

    It "Devrait générer un rapport de détection des cycles" -Skip {
        if (Test-Path -Path $cBreakModePath) {
            # Exécuter le script
            $output = & $cBreakModePath -FilePath $testFilePath -OutputPath $testOutputPath -MaxIterations 5
            
            # Vérifier que les fichiers attendus existent
            $reportPath = Join-Path -Path $testOutputPath -ChildPath "cycle-detection-report.md"
            Test-Path -Path $reportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script c-break-mode.ps1 n'est pas disponible"
        }
    }
}
