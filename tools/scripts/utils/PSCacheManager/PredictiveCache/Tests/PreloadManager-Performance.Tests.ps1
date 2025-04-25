#Requires -Version 5.1
<#
.SYNOPSIS
    Tests de performance pour le module PreloadManager.
.DESCRIPTION
    Ce script contient des tests de performance et de charge
    pour le module PreloadManager.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer le module de types simulés
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Test"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Définir les chemins de test
$testCachePath = Join-Path -Path $testDir -ChildPath "Cache"
$testDatabasePath = Join-Path -Path $testDir -ChildPath "Usage.db"

# Nettoyer les tests précédents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# Créer le répertoire du cache
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

# Fonction pour afficher un titre de section
function Show-SectionTitle {
    param([string]$Title)

    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

# Fonction pour afficher un résultat de test
function Show-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = ""
    )

    Write-Host "  $TestName : " -NoNewline
    if ($Success) {
        Write-Host "Succès" -ForegroundColor Green
    } else {
        Write-Host "Échec" -ForegroundColor Red
    }

    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }

    return $Success
}

# Fonction pour mesurer le temps d'exécution
function Measure-ExecutionTime {
    param(
        [scriptblock]$ScriptBlock
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Tableau pour stocker les résultats des tests
$testResults = @()

Show-SectionTitle "Tests de performance pour PreloadManager"

# Créer les objets de base pour les tests
$baseCache = [CacheManager]::new("TestCache", $testCachePath)
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
$engine = New-PredictionEngine -UsageCollector $collector -CacheName "TestCache"
$preloadManager = New-PreloadManager -BaseCache $baseCache -PredictionEngine $engine

# Test 1: Performance de l'enregistrement des générateurs
Show-SectionTitle "1. Performance de l'enregistrement des générateurs"

# Test 1.1: Enregistrer un générateur simple
$generator = { return "Simple Value" }
$time = Measure-ExecutionTime {
    Register-PreloadGenerator -PreloadManager $preloadManager -KeyPattern "Simple:*" -Generator $generator
}
$test1_1 = Show-TestResult -TestName "1.1 Enregistrer un générateur simple" -Success ($time -lt 100) -Message "Temps d'exécution: $time ms"
$testResults += $test1_1

# Test 1.2: Enregistrer un générateur complexe
$complexGenerator = {
    $result = @{}
    for ($i = 0; $i -lt 100; $i++) {
        $result["Item$i"] = "Value$i"
    }
    return $result
}
$time = Measure-ExecutionTime {
    Register-PreloadGenerator -PreloadManager $preloadManager -KeyPattern "Complex:*" -Generator $complexGenerator
}
$test1_2 = Show-TestResult -TestName "1.2 Enregistrer un générateur complexe" -Success ($time -lt 100) -Message "Temps d'exécution: $time ms"
$testResults += $test1_2

# Test 1.3: Enregistrer plusieurs générateurs
$time = Measure-ExecutionTime {
    for ($i = 0; $i -lt 10; $i++) {
        $pattern = "Pattern$i`:*"
        $gen = { param($i) return "Value for pattern $i" }.GetNewClosure()
        Register-PreloadGenerator -PreloadManager $preloadManager -KeyPattern $pattern -Generator $gen
    }
}
$test1_3 = Show-TestResult -TestName "1.3 Enregistrer plusieurs générateurs" -Success ($time -lt 500) -Message "Temps d'exécution: $time ms"
$testResults += $test1_3

# Test 2: Performance de la recherche de générateurs
Show-SectionTitle "2. Performance de la recherche de générateurs"

# Test 2.1: Rechercher un générateur existant
$time = Measure-ExecutionTime {
    $script:foundGenerator = $preloadManager.FindGenerator("Simple:123")
}
$test2_1 = Show-TestResult -TestName "2.1 Rechercher un générateur existant" -Success ($time -lt 50 -and $null -ne $script:foundGenerator) -Message "Temps d'exécution: $time ms"
$testResults += $test2_1

# Test 2.2: Rechercher un générateur inexistant
$time = Measure-ExecutionTime {
    $script:notFoundGenerator = $preloadManager.FindGenerator("NonExistent:123")
}
$test2_2 = Show-TestResult -TestName "2.2 Rechercher un générateur inexistant" -Success ($time -lt 50) -Message "Temps d'exécution: $time ms"
$testResults += $test2_2

# Test 2.3: Rechercher parmi de nombreux générateurs
$time = Measure-ExecutionTime {
    for ($i = 0; $i -lt 10; $i++) {
        $key = "Pattern$i`:123"
        $script:multipleGenerators = $preloadManager.FindGenerator($key)
    }
}
$test2_3 = Show-TestResult -TestName "2.3 Rechercher parmi de nombreux générateurs" -Success ($time -lt 500) -Message "Temps d'exécution: $time ms"
$testResults += $test2_3

# Test 3: Performance du préchargement
Show-SectionTitle "3. Performance du préchargement"

# Test 3.1: Précharger une seule clé
$time = Measure-ExecutionTime {
    $preloadManager.PreloadKeys(@("Simple:123"))
}
$test3_1 = Show-TestResult -TestName "3.1 Précharger une seule clé" -Success ($time -lt 100) -Message "Temps d'exécution: $time ms"
$testResults += $test3_1

# Test 3.2: Précharger plusieurs clés
$keys = @()
for ($i = 0; $i -lt 10; $i++) {
    $keys += "Simple:$i"
}
$time = Measure-ExecutionTime {
    $preloadManager.PreloadKeys($keys)
}
$test3_2 = Show-TestResult -TestName "3.2 Précharger plusieurs clés" -Success ($time -lt 500) -Message "Temps d'exécution: $time ms"
$testResults += $test3_2

# Test 3.3: Précharger des clés avec différents patterns
$mixedKeys = @("Simple:123", "Complex:456", "Pattern0:789", "Pattern5:012")
$time = Measure-ExecutionTime {
    $preloadManager.PreloadKeys($mixedKeys)
}
$test3_3 = Show-TestResult -TestName "3.3 Précharger des clés avec différents patterns" -Success ($time -lt 500) -Message "Temps d'exécution: $time ms"
$testResults += $test3_3

# Test 4: Vérification de la charge système
Show-SectionTitle "4. Vérification de la charge système"

# Test 4.1: Vérifier la charge système
$time = Measure-ExecutionTime {
    $script:isUnderLoad = $preloadManager.IsSystemUnderHeavyLoad()
}
$test4_1 = Show-TestResult -TestName "4.1 Vérifier la charge système" -Success ($time -lt 100) -Message "Temps d'exécution: $time ms, Système sous charge: $script:isUnderLoad"
$testResults += $test4_1

# Test 5: Optimisation de la stratégie de préchargement
Show-SectionTitle "5. Optimisation de la stratégie de préchargement"

# Test 5.1: Optimiser la stratégie
$time = Measure-ExecutionTime {
    $preloadManager.OptimizePreloadStrategy()
}
$test5_1 = Show-TestResult -TestName "5.1 Optimiser la stratégie" -Success ($time -lt 500) -Message "Temps d'exécution: $time ms"
$testResults += $test5_1

# Test 5.2: Obtenir les statistiques
$time = Measure-ExecutionTime {
    $script:preloadStats = $preloadManager.GetPreloadStatistics()
}
$test5_2 = Show-TestResult -TestName "5.2 Obtenir les statistiques" -Success ($time -lt 100 -and $null -ne $script:preloadStats) -Message "Temps d'exécution: $time ms"
$testResults += $test5_2

# Test 6: Simulation de charge
Show-SectionTitle "6. Simulation de charge"

# Test 6.1: Simulation de charge légère
$time = Measure-ExecutionTime {
    for ($i = 0; $i -lt 10; $i++) {
        $preloadManager.PreloadKeys(@("Simple:$i"))
        $preloadManager.IsPreloadCandidate("Simple:$i")
    }
}
$test6_1 = Show-TestResult -TestName "6.1 Simulation de charge légère" -Success ($time -lt 1000) -Message "Temps d'exécution: $time ms"
$testResults += $test6_1

# Test 6.2: Simulation de charge moyenne
$time = Measure-ExecutionTime {
    for ($i = 0; $i -lt 50; $i++) {
        $pattern = "Pattern$($i % 10)`:$i"
        $preloadManager.PreloadKeys(@($pattern))
        $preloadManager.IsPreloadCandidate($pattern)
    }
}
$test6_2 = Show-TestResult -TestName "6.2 Simulation de charge moyenne" -Success ($time -lt 5000) -Message "Temps d'exécution: $time ms"
$testResults += $test6_2

# Résumé des tests
Show-SectionTitle "Résumé des tests"

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "Tests échoués: $failedTests" -ForegroundColor Red
Write-Host "Taux de réussite: $([Math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan

# Nettoyage
Write-Host "`nNettoyage..." -ForegroundColor Cyan
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# Résultat final
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
