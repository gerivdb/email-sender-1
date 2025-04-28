<#
.SYNOPSIS
    Tests pour le script opti-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script opti-mode.ps1
    qui implÃ©mente le mode OPTI pour rÃ©duire la complexitÃ©, la taille ou le temps d'exÃ©cution du code.

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
$optiModePath = Join-Path -Path $projectRoot -ChildPath "opti-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokeOptiPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapOptimization.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $optiModePath)) {
    Write-Warning "Le script opti-mode.ps1 est introuvable Ã  l'emplacement : $optiModePath"
}

if (-not (Test-Path -Path $invokeOptiPath)) {
    Write-Warning "Le fichier Invoke-RoadmapOptimization.ps1 est introuvable Ã  l'emplacement : $invokeOptiPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeOptiPath) {
    . $invokeOptiPath
    Write-Host "Fonction Invoke-RoadmapOptimization importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Optimisation des performances
  - [ ] **1.1.1** RÃ©duire le temps d'exÃ©cution
  - [ ] **1.1.2** Optimiser l'utilisation de la mÃ©moire
- [ ] **1.2** Optimisation du code
  - [ ] **1.2.1** RÃ©duire la complexitÃ© cyclomatique
  - [ ] **1.2.2** AmÃ©liorer la lisibilitÃ©

## Section 2

- [ ] **2.1** Tests de performance
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# CrÃ©er la structure du module de test
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Public") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Private") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de code avec des problÃ¨mes de performance pour les tests
@"
function Process-LargeData {
    param (
        [Parameter(Mandatory = `$true)]
        [string[]]`$Data
    )
    
    # ProblÃ¨me de performance : Utilisation inefficace de la concatÃ©nation de chaÃ®nes
    `$result = ""
    foreach (`$item in `$Data) {
        `$result += `$item + "`n"
    }
    
    # ProblÃ¨me de performance : Boucle imbriquÃ©e inefficace
    for (`$i = 0; `$i -lt `$Data.Length; `$i++) {
        for (`$j = 0; `$j -lt `$Data.Length; `$j++) {
            if (`$i -ne `$j -and `$Data[`$i] -eq `$Data[`$j]) {
                Write-Host "Doublon trouvÃ© : `$(`$Data[`$i])"
            }
        }
    }
    
    return `$result
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Public\Process-LargeData.ps1") -Encoding UTF8

@"
function Calculate-Statistics {
    param (
        [Parameter(Mandatory = `$true)]
        [int[]]`$Numbers
    )
    
    # ProblÃ¨me de performance : Calculs redondants
    `$sum = 0
    foreach (`$num in `$Numbers) {
        `$sum += `$num
    }
    
    `$mean = `$sum / `$Numbers.Length
    
    `$sumSquaredDiff = 0
    foreach (`$num in `$Numbers) {
        `$sumSquaredDiff += [Math]::Pow(`$num - `$mean, 2)
    }
    
    `$variance = `$sumSquaredDiff / `$Numbers.Length
    `$stdDev = [Math]::Sqrt(`$variance)
    
    # ProblÃ¨me de mÃ©moire : CrÃ©ation inutile de grands tableaux
    `$allNumbers = @()
    foreach (`$num in `$Numbers) {
        `$allNumbers += `$num
    }
    
    return @{
        Sum = `$sum
        Mean = `$mean
        Variance = `$variance
        StdDev = `$stdDev
    }
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Private\Calculate-Statistics.ps1") -Encoding UTF8

Write-Host "Module de test crÃ©Ã© : $testModulePath" -ForegroundColor Green
Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapOptimization" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapOptimization -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "Runtime"
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le module n'existe pas" {
        # Appeler la fonction avec un module inexistant
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapOptimization -ModulePath "ModuleInexistant" -ProfileOutput $testOutputPath -OptimizationTarget "Runtime" } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }

    It "Devrait identifier les points chauds de performance" {
        # Appeler la fonction et vÃ©rifier l'identification des points chauds
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapOptimization -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "Runtime"
            
            # VÃ©rifier que les points chauds sont identifiÃ©s
            $result.Hotspots | Should -Not -BeNullOrEmpty
            $result.Hotspots | Should -Contain "Process-LargeData"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer des recommandations d'optimisation" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration de recommandations
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapOptimization -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "All"
            
            # VÃ©rifier que des recommandations sont gÃ©nÃ©rÃ©es
            $result.Recommendations | Should -Not -BeNullOrEmpty
            $result.Recommendations.Count | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer un rapport de profilage" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration du rapport
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapOptimization -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "All" -GenerateReport $true
            
            # VÃ©rifier que le rapport est gÃ©nÃ©rÃ©
            $profilingReportPath = Join-Path -Path $testOutputPath -ChildPath "profiling_report.html"
            Test-Path -Path $profilingReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }

    It "Devrait gÃ©nÃ©rer des versions optimisÃ©es du code" {
        # Appeler la fonction et vÃ©rifier la gÃ©nÃ©ration de code optimisÃ©
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapOptimization -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "All" -ApplyChanges $true
            
            # VÃ©rifier que des versions optimisÃ©es sont gÃ©nÃ©rÃ©es
            $optimizedCodePath = Join-Path -Path $testOutputPath -ChildPath "optimized_code"
            Test-Path -Path $optimizedCodePath | Should -Be $true
            
            # VÃ©rifier que les fichiers optimisÃ©s existent
            $optimizedProcessLargeDataPath = Join-Path -Path $optimizedCodePath -ChildPath "Process-LargeData.ps1"
            Test-Path -Path $optimizedProcessLargeDataPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script opti-mode.ps1
Describe "opti-mode.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path $optiModePath) {
            # ExÃ©cuter le script
            $output = & $optiModePath -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "All" -GenerateReport $true
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # VÃ©rifier que les fichiers attendus existent
            $profilingReportPath = Join-Path -Path $testOutputPath -ChildPath "profiling_report.html"
            Test-Path -Path $profilingReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script opti-mode.ps1 n'est pas disponible"
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
