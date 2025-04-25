<#
.SYNOPSIS
    Tests pour le script opti-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script opti-mode.ps1
    qui implémente le mode OPTI pour réduire la complexité, la taille ou le temps d'exécution du code.

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
$optiModePath = Join-Path -Path $projectRoot -ChildPath "opti-mode.ps1"

# Chemin vers les fonctions à tester
$invokeOptiPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapOptimization.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $optiModePath)) {
    Write-Warning "Le script opti-mode.ps1 est introuvable à l'emplacement : $optiModePath"
}

if (-not (Test-Path -Path $invokeOptiPath)) {
    Write-Warning "Le fichier Invoke-RoadmapOptimization.ps1 est introuvable à l'emplacement : $invokeOptiPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeOptiPath) {
    . $invokeOptiPath
    Write-Host "Fonction Invoke-RoadmapOptimization importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Optimisation des performances
  - [ ] **1.1.1** Réduire le temps d'exécution
  - [ ] **1.1.2** Optimiser l'utilisation de la mémoire
- [ ] **1.2** Optimisation du code
  - [ ] **1.2.1** Réduire la complexité cyclomatique
  - [ ] **1.2.2** Améliorer la lisibilité

## Section 2

- [ ] **2.1** Tests de performance
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# Créer la structure du module de test
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Public") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testModulePath -ChildPath "Functions\Private") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# Créer des fichiers de code avec des problèmes de performance pour les tests
@"
function Process-LargeData {
    param (
        [Parameter(Mandatory = `$true)]
        [string[]]`$Data
    )
    
    # Problème de performance : Utilisation inefficace de la concaténation de chaînes
    `$result = ""
    foreach (`$item in `$Data) {
        `$result += `$item + "`n"
    }
    
    # Problème de performance : Boucle imbriquée inefficace
    for (`$i = 0; `$i -lt `$Data.Length; `$i++) {
        for (`$j = 0; `$j -lt `$Data.Length; `$j++) {
            if (`$i -ne `$j -and `$Data[`$i] -eq `$Data[`$j]) {
                Write-Host "Doublon trouvé : `$(`$Data[`$i])"
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
    
    # Problème de performance : Calculs redondants
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
    
    # Problème de mémoire : Création inutile de grands tableaux
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

Write-Host "Module de test créé : $testModulePath" -ForegroundColor Green
Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapOptimization" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
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
        # Appeler la fonction et vérifier l'identification des points chauds
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapOptimization -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "Runtime"
            
            # Vérifier que les points chauds sont identifiés
            $result.Hotspots | Should -Not -BeNullOrEmpty
            $result.Hotspots | Should -Contain "Process-LargeData"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }

    It "Devrait générer des recommandations d'optimisation" {
        # Appeler la fonction et vérifier la génération de recommandations
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapOptimization -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "All"
            
            # Vérifier que des recommandations sont générées
            $result.Recommendations | Should -Not -BeNullOrEmpty
            $result.Recommendations.Count | Should -BeGreaterThan 0
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }

    It "Devrait générer un rapport de profilage" {
        # Appeler la fonction et vérifier la génération du rapport
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapOptimization -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "All" -GenerateReport $true
            
            # Vérifier que le rapport est généré
            $profilingReportPath = Join-Path -Path $testOutputPath -ChildPath "profiling_report.html"
            Test-Path -Path $profilingReportPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }

    It "Devrait générer des versions optimisées du code" {
        # Appeler la fonction et vérifier la génération de code optimisé
        if (Get-Command -Name Invoke-RoadmapOptimization -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapOptimization -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "All" -ApplyChanges $true
            
            # Vérifier que des versions optimisées sont générées
            $optimizedCodePath = Join-Path -Path $testOutputPath -ChildPath "optimized_code"
            Test-Path -Path $optimizedCodePath | Should -Be $true
            
            # Vérifier que les fichiers optimisés existent
            $optimizedProcessLargeDataPath = Join-Path -Path $optimizedCodePath -ChildPath "Process-LargeData.ps1"
            Test-Path -Path $optimizedProcessLargeDataPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapOptimization n'est pas disponible"
        }
    }
}

# Test d'intégration du script opti-mode.ps1
Describe "opti-mode.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path $optiModePath) {
            # Exécuter le script
            $output = & $optiModePath -ModulePath $testModulePath -ProfileOutput $testOutputPath -OptimizationTarget "All" -GenerateReport $true
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que les fichiers attendus existent
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
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testModulePath) {
    Remove-Item -Path $testModulePath -Recurse -Force
    Write-Host "Module de test supprimé." -ForegroundColor Gray
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
