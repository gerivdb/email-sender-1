# Tests pour le mode C-BREAK

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent $modulePath
$cBreakModePath = Join-Path -Path $projectRoot -ChildPath "c-break-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokeCycleBreakerPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapCycleBreaker.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $cBreakModePath)) {
    Write-Warning "Le script c-break-mode.ps1 est introuvable Ã  l'emplacement : $cBreakModePath"
}

if (-not (Test-Path -Path $invokeCycleBreakerPath)) {
    Write-Warning "Le fichier Invoke-RoadmapCycleBreaker.ps1 est introuvable Ã  l'emplacement : $invokeCycleBreakerPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeCycleBreakerPath) {
    . $invokeCycleBreakerPath
    Write-Host "Fonction Invoke-RoadmapCycleBreaker importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un module de test avec des dÃ©pendances circulaires
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null

# CrÃ©er un rÃ©pertoire de sortie pour les tests
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er un fichier de test avec une structure de roadmap simple
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

# CrÃ©er des fichiers avec des dÃ©pendances circulaires pour les tests
$file1Path = Join-Path -Path $testModulePath -ChildPath "File1.ps1"
$file2Path = Join-Path -Path $testModulePath -ChildPath "File2.ps1"
$file3Path = Join-Path -Path $testModulePath -ChildPath "File3.ps1"

# Fichier 1 dÃ©pend de Fichier 3 (cycle)
@"
# Fichier 1
. "$file3Path"

function Test-Function1 {
    Test-Function3
}
"@ | Out-File -FilePath $file1Path -Encoding UTF8

# Fichier 2 dÃ©pend de Fichier 1
@"
# Fichier 2
. "$file1Path"

function Test-Function2 {
    Test-Function1
}
"@ | Out-File -FilePath $file2Path -Encoding UTF8

# Fichier 3 dÃ©pend de Fichier 1 (cycle)
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
        # PrÃ©paration avant tous les tests
    }

    AfterAll {
        # Nettoyage aprÃ¨s tous les tests
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

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" -Skip {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapCycleBreaker -FilePath $testFilePath -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }

    It "Devrait dÃ©tecter les cycles de dÃ©pendances" -Skip {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapCycleBreaker -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapCycleBreaker -FilePath $testFilePath -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
            $result.CycleCount | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapCycleBreaker n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer un rapport de dÃ©tection" -Skip {
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

# Test d'intÃ©gration du script c-break-mode.ps1
Describe "c-break-mode.ps1 Integration" {
    BeforeAll {
        # PrÃ©paration avant tous les tests
    }

    AfterAll {
        # Nettoyage aprÃ¨s tous les tests
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

    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" -Skip {
        if (Test-Path -Path $cBreakModePath) {
            # ExÃ©cuter le script
            $output = & $cBreakModePath -FilePath $testFilePath -OutputPath $testOutputPath -MaxIterations 5
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
        } else {
            Set-ItResult -Skipped -Because "Le script c-break-mode.ps1 n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer un rapport de dÃ©tection des cycles" -Skip {
        if (Test-Path -Path $cBreakModePath) {
            # ExÃ©cuter le script
            $output = & $cBreakModePath -FilePath $testFilePath -OutputPath $testOutputPath -MaxIterations 5
            
            # VÃ©rifier que les fichiers attendus existent
            $reportPath = Join-Path -Path $testOutputPath -ChildPath "cycle-detection-report.md"
            Test-Path -Path $reportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script c-break-mode.ps1 n'est pas disponible"
        }
    }
}
