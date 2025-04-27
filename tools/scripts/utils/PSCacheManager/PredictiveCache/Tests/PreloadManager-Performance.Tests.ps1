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

# Importer le module de types simulÃ©s
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Test"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# DÃ©finir les chemins de test
$testCachePath = Join-Path -Path $testDir -ChildPath "Cache"
$testDatabasePath = Join-Path -Path $testDir -ChildPath "Usage.db"

# Nettoyer les tests prÃ©cÃ©dents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# CrÃ©er le rÃ©pertoire du cache
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

# Fonction pour afficher un titre de section
function Show-SectionTitle {
    param([string]$Title)

    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

# Fonction pour afficher un rÃ©sultat de test
function Show-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = ""
    )

    Write-Host "  $TestName : " -NoNewline
    if ($Success) {
        Write-Host "SuccÃ¨s" -ForegroundColor Green
    } else {
        Write-Host "Ã‰chec" -ForegroundColor Red
    }

    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }

    return $Success
}

# Fonction pour mesurer le temps d'exÃ©cution
function Measure-ExecutionTime {
    param(
        [scriptblock]$ScriptBlock
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Tableau pour stocker les rÃ©sultats des tests
$testResults = @()

Show-SectionTitle "Tests de performance pour PreloadManager"

# CrÃ©er les objets de base pour les tests
$baseCache = [CacheManager]::new("TestCache", $testCachePath)
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
$engine = New-PredictionEngine -UsageCollector $collector -CacheName "TestCache"
$preloadManager = New-PreloadManager -BaseCache $baseCache -PredictionEngine $engine

# Test 1: Performance de l'enregistrement des gÃ©nÃ©rateurs
Show-SectionTitle "1. Performance de l'enregistrement des gÃ©nÃ©rateurs"

# Test 1.1: Enregistrer un gÃ©nÃ©rateur simple
$generator = { return "Simple Value" }
$time = Measure-ExecutionTime {
    Register-PreloadGenerator -PreloadManager $preloadManager -KeyPattern "Simple:*" -Generator $generator
}
$test1_1 = Show-TestResult -TestName "1.1 Enregistrer un gÃ©nÃ©rateur simple" -Success ($time -lt 100) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test1_1

# Test 1.2: Enregistrer un gÃ©nÃ©rateur complexe
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
$test1_2 = Show-TestResult -TestName "1.2 Enregistrer un gÃ©nÃ©rateur complexe" -Success ($time -lt 100) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test1_2

# Test 1.3: Enregistrer plusieurs gÃ©nÃ©rateurs
$time = Measure-ExecutionTime {
    for ($i = 0; $i -lt 10; $i++) {
        $pattern = "Pattern$i`:*"
        $gen = { param($i) return "Value for pattern $i" }.GetNewClosure()
        Register-PreloadGenerator -PreloadManager $preloadManager -KeyPattern $pattern -Generator $gen
    }
}
$test1_3 = Show-TestResult -TestName "1.3 Enregistrer plusieurs gÃ©nÃ©rateurs" -Success ($time -lt 500) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test1_3

# Test 2: Performance de la recherche de gÃ©nÃ©rateurs
Show-SectionTitle "2. Performance de la recherche de gÃ©nÃ©rateurs"

# Test 2.1: Rechercher un gÃ©nÃ©rateur existant
$time = Measure-ExecutionTime {
    $script:foundGenerator = $preloadManager.FindGenerator("Simple:123")
}
$test2_1 = Show-TestResult -TestName "2.1 Rechercher un gÃ©nÃ©rateur existant" -Success ($time -lt 50 -and $null -ne $script:foundGenerator) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test2_1

# Test 2.2: Rechercher un gÃ©nÃ©rateur inexistant
$time = Measure-ExecutionTime {
    $script:notFoundGenerator = $preloadManager.FindGenerator("NonExistent:123")
}
$test2_2 = Show-TestResult -TestName "2.2 Rechercher un gÃ©nÃ©rateur inexistant" -Success ($time -lt 50) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test2_2

# Test 2.3: Rechercher parmi de nombreux gÃ©nÃ©rateurs
$time = Measure-ExecutionTime {
    for ($i = 0; $i -lt 10; $i++) {
        $key = "Pattern$i`:123"
        $script:multipleGenerators = $preloadManager.FindGenerator($key)
    }
}
$test2_3 = Show-TestResult -TestName "2.3 Rechercher parmi de nombreux gÃ©nÃ©rateurs" -Success ($time -lt 500) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test2_3

# Test 3: Performance du prÃ©chargement
Show-SectionTitle "3. Performance du prÃ©chargement"

# Test 3.1: PrÃ©charger une seule clÃ©
$time = Measure-ExecutionTime {
    $preloadManager.PreloadKeys(@("Simple:123"))
}
$test3_1 = Show-TestResult -TestName "3.1 PrÃ©charger une seule clÃ©" -Success ($time -lt 100) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test3_1

# Test 3.2: PrÃ©charger plusieurs clÃ©s
$keys = @()
for ($i = 0; $i -lt 10; $i++) {
    $keys += "Simple:$i"
}
$time = Measure-ExecutionTime {
    $preloadManager.PreloadKeys($keys)
}
$test3_2 = Show-TestResult -TestName "3.2 PrÃ©charger plusieurs clÃ©s" -Success ($time -lt 500) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test3_2

# Test 3.3: PrÃ©charger des clÃ©s avec diffÃ©rents patterns
$mixedKeys = @("Simple:123", "Complex:456", "Pattern0:789", "Pattern5:012")
$time = Measure-ExecutionTime {
    $preloadManager.PreloadKeys($mixedKeys)
}
$test3_3 = Show-TestResult -TestName "3.3 PrÃ©charger des clÃ©s avec diffÃ©rents patterns" -Success ($time -lt 500) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test3_3

# Test 4: VÃ©rification de la charge systÃ¨me
Show-SectionTitle "4. VÃ©rification de la charge systÃ¨me"

# Test 4.1: VÃ©rifier la charge systÃ¨me
$time = Measure-ExecutionTime {
    $script:isUnderLoad = $preloadManager.IsSystemUnderHeavyLoad()
}
$test4_1 = Show-TestResult -TestName "4.1 VÃ©rifier la charge systÃ¨me" -Success ($time -lt 100) -Message "Temps d'exÃ©cution: $time ms, SystÃ¨me sous charge: $script:isUnderLoad"
$testResults += $test4_1

# Test 5: Optimisation de la stratÃ©gie de prÃ©chargement
Show-SectionTitle "5. Optimisation de la stratÃ©gie de prÃ©chargement"

# Test 5.1: Optimiser la stratÃ©gie
$time = Measure-ExecutionTime {
    $preloadManager.OptimizePreloadStrategy()
}
$test5_1 = Show-TestResult -TestName "5.1 Optimiser la stratÃ©gie" -Success ($time -lt 500) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test5_1

# Test 5.2: Obtenir les statistiques
$time = Measure-ExecutionTime {
    $script:preloadStats = $preloadManager.GetPreloadStatistics()
}
$test5_2 = Show-TestResult -TestName "5.2 Obtenir les statistiques" -Success ($time -lt 100 -and $null -ne $script:preloadStats) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test5_2

# Test 6: Simulation de charge
Show-SectionTitle "6. Simulation de charge"

# Test 6.1: Simulation de charge lÃ©gÃ¨re
$time = Measure-ExecutionTime {
    for ($i = 0; $i -lt 10; $i++) {
        $preloadManager.PreloadKeys(@("Simple:$i"))
        $preloadManager.IsPreloadCandidate("Simple:$i")
    }
}
$test6_1 = Show-TestResult -TestName "6.1 Simulation de charge lÃ©gÃ¨re" -Success ($time -lt 1000) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test6_1

# Test 6.2: Simulation de charge moyenne
$time = Measure-ExecutionTime {
    for ($i = 0; $i -lt 50; $i++) {
        $pattern = "Pattern$($i % 10)`:$i"
        $preloadManager.PreloadKeys(@($pattern))
        $preloadManager.IsPreloadCandidate($pattern)
    }
}
$test6_2 = Show-TestResult -TestName "6.2 Simulation de charge moyenne" -Success ($time -lt 5000) -Message "Temps d'exÃ©cution: $time ms"
$testResults += $test6_2

# RÃ©sumÃ© des tests
Show-SectionTitle "RÃ©sumÃ© des tests"

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor White
Write-Host "Tests rÃ©ussis: $passedTests" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s: $failedTests" -ForegroundColor Red
Write-Host "Taux de rÃ©ussite: $([Math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan

# Nettoyage
Write-Host "`nNettoyage..." -ForegroundColor Cyan
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# RÃ©sultat final
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
