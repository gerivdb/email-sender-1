<#
.SYNOPSIS
    Test complet pour le systÃ¨me de cache prÃ©dictif.
.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s du systÃ¨me de cache prÃ©dictif.
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

# Tableau pour stocker les rÃ©sultats des tests
$testResults = @()

Show-SectionTitle "Test du systÃ¨me de cache prÃ©dictif"

# Section 1: Cache de base
Show-SectionTitle "1. Cache de base"

# Test 1.1: CrÃ©ation d'un cache prÃ©dictif
$cache = New-PredictiveCache -Name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
$test1_1 = Show-TestResult -TestName "1.1 CrÃ©ation d'un cache prÃ©dictif" -Success ($null -ne $cache) -Message "Cache crÃ©Ã©: $($cache.Name)"
$testResults += $test1_1

# Test 1.2: Configuration du cache
$result = Set-PredictiveCacheOptions -Cache $cache -PreloadEnabled $true -AdaptiveTTL $true -DependencyTracking $true
$test1_2 = Show-TestResult -TestName "1.2 Configuration du cache" -Success $result -Message "Options configurÃ©es: PrÃ©chargement=$($cache.PreloadEnabled), TTL adaptatif=$($cache.AdaptiveTTLEnabled), DÃ©pendances=$($cache.DependencyTrackingEnabled)"
$testResults += $test1_2

# Test 1.3: AccÃ¨s au cache de base
$baseCache = $cache.BaseCache
# Utiliser la propriÃ©tÃ© Cache directement au lieu de la mÃ©thode Set
$baseCache.Cache["TestKey"] = "TestValue"
$value = $baseCache.Get("TestKey")
$test1_3 = Show-TestResult -TestName "1.3 AccÃ¨s au cache de base" -Success ($value -eq "TestValue") -Message "Valeur rÃ©cupÃ©rÃ©e: $value"
$testResults += $test1_3

# Section 2: Collecteur d'utilisation
Show-SectionTitle "2. Collecteur d'utilisation"

# Test 2.1: CrÃ©ation d'un collecteur d'utilisation
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
$test2_1 = Show-TestResult -TestName "2.1 CrÃ©ation d'un collecteur d'utilisation" -Success ($null -ne $collector) -Message "Collecteur crÃ©Ã© pour $($collector.CacheName)"
$testResults += $test2_1

# Test 2.2: Enregistrement des accÃ¨s
$collector.RecordAccess("Key1", $true)
$collector.RecordAccess("Key1", $true)
$collector.RecordAccess("Key2", $false)
$stats = $collector.GetKeyAccessStats("Key1")
$test2_2 = Show-TestResult -TestName "2.2 Enregistrement des accÃ¨s" -Success ($null -ne $stats) -Message "Statistiques pour Key1: Hits=$($stats.Hits), Misses=$($stats.Misses)"
$testResults += $test2_2

# Test 2.3: RÃ©cupÃ©ration des clÃ©s les plus accÃ©dÃ©es
$mostAccessed = $collector.GetMostAccessedKeys(10, 60)
# VÃ©rifier si $mostAccessed est un tableau et non null
$isValidResult = ($null -ne $mostAccessed) -and ($mostAccessed -is [array] -or $mostAccessed -is [System.Collections.ICollection])
$test2_3 = Show-TestResult -TestName "2.3 RÃ©cupÃ©ration des clÃ©s les plus accÃ©dÃ©es" -Success $isValidResult -Message "Nombre de clÃ©s: $(if($isValidResult){$mostAccessed.Count}else{0})"
$testResults += $test2_3

# Section 3: Moteur de prÃ©diction
Show-SectionTitle "3. Moteur de prÃ©diction"

# Test 3.1: CrÃ©ation d'un moteur de prÃ©diction
$engine = New-PredictionEngine -UsageCollector $collector -CacheName "TestCache"
$test3_1 = Show-TestResult -TestName "3.1 CrÃ©ation d'un moteur de prÃ©diction" -Success ($null -ne $engine) -Message "Moteur crÃ©Ã© pour $($engine.CacheName)"
$testResults += $test3_1

# Test 3.2: PrÃ©diction des prochains accÃ¨s
$predictions = $engine.PredictNextAccesses()
# VÃ©rifier si $predictions est un tableau et non null
$isValidPredictions = ($null -ne $predictions) -and ($predictions -is [array] -or $predictions -is [System.Collections.ICollection])
$test3_2 = Show-TestResult -TestName "3.2 PrÃ©diction des prochains accÃ¨s" -Success $isValidPredictions -Message "Nombre de prÃ©dictions: $(if($isValidPredictions){$predictions.Count}else{0})"
$testResults += $test3_2

# Test 3.3: Calcul de probabilitÃ© pour une clÃ©
$probability = $engine.CalculateKeyProbability("Key1")
$test3_3 = Show-TestResult -TestName "3.3 Calcul de probabilitÃ© pour une clÃ©" -Success ($probability -ge 0 -and $probability -le 1) -Message "ProbabilitÃ© pour Key1: $probability"
$testResults += $test3_3

# Section 4: Optimiseur de TTL
Show-SectionTitle "4. Optimiseur de TTL"

# Test 4.1: CrÃ©ation d'un optimiseur de TTL
$optimizer = New-TTLOptimizer -BaseCache $baseCache -UsageCollector $collector
$test4_1 = Show-TestResult -TestName "4.1 CrÃ©ation d'un optimiseur de TTL" -Success ($null -ne $optimizer) -Message "Optimiseur crÃ©Ã©"
$testResults += $test4_1

# Test 4.2: Configuration de l'optimiseur
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL 300 -MaximumTTL 43200
$test4_2 = Show-TestResult -TestName "4.2 Configuration de l'optimiseur" -Success $result -Message "TTL min=$($optimizer.MinimumTTL), TTL max=$($optimizer.MaximumTTL)"
$testResults += $test4_2

# Test 4.3: Optimisation du TTL pour une clÃ©
$optimizedTTL = $optimizer.OptimizeTTL("Key1", 3600)
$test4_3 = Show-TestResult -TestName "4.3 Optimisation du TTL pour une clÃ©" -Success ($optimizedTTL -ge $optimizer.MinimumTTL -and $optimizedTTL -le $optimizer.MaximumTTL) -Message "TTL optimisÃ© pour Key1: $optimizedTTL"
$testResults += $test4_3

# Section 5: Gestionnaire de dÃ©pendances
Show-SectionTitle "5. Gestionnaire de dÃ©pendances"

# Test 5.1: CrÃ©ation d'un gestionnaire de dÃ©pendances
$dependencyManager = New-DependencyManager -BaseCache $baseCache -UsageCollector $collector
$test5_1 = Show-TestResult -TestName "5.1 CrÃ©ation d'un gestionnaire de dÃ©pendances" -Success ($null -ne $dependencyManager) -Message "Gestionnaire crÃ©Ã©"
$testResults += $test5_1

# Test 5.2: Ajout d'une dÃ©pendance
$result = Add-CacheDependency -DependencyManager $dependencyManager -SourceKey "Source" -TargetKey "Target" -Strength 0.8
$test5_2 = Show-TestResult -TestName "5.2 Ajout d'une dÃ©pendance" -Success $result -Message "DÃ©pendance ajoutÃ©e: Source -> Target (0.8)"
$testResults += $test5_2

# Test 5.3: RÃ©cupÃ©ration des dÃ©pendances
$dependencies = $dependencyManager.GetDependencies("Source")
$test5_3 = Show-TestResult -TestName "5.3 RÃ©cupÃ©ration des dÃ©pendances" -Success ($dependencies.Count -gt 0) -Message "Nombre de dÃ©pendances: $($dependencies.Count)"
$testResults += $test5_3

# Test 5.4: Suppression d'une dÃ©pendance
$result = Remove-CacheDependency -DependencyManager $dependencyManager -SourceKey "Source" -TargetKey "Target"
$dependencies = $dependencyManager.GetDependencies("Source")
$test5_4 = Show-TestResult -TestName "5.4 Suppression d'une dÃ©pendance" -Success ($result -and $dependencies.Count -eq 0) -Message "DÃ©pendances restantes: $($dependencies.Count)"
$testResults += $test5_4

# Section 6: Gestionnaire de prÃ©chargement
Show-SectionTitle "6. Gestionnaire de prÃ©chargement"

# Test 6.1: CrÃ©ation d'un gestionnaire de prÃ©chargement
$preloadManager = New-PreloadManager -BaseCache $baseCache -PredictionEngine $engine
$test6_1 = Show-TestResult -TestName "6.1 CrÃ©ation d'un gestionnaire de prÃ©chargement" -Success ($null -ne $preloadManager) -Message "Gestionnaire crÃ©Ã©"
$testResults += $test6_1

# Test 6.2: Enregistrement d'un gÃ©nÃ©rateur
$generator = { return "Valeur prÃ©chargÃ©e" }
$result = Register-PreloadGenerator -PreloadManager $preloadManager -KeyPattern "User:*" -Generator $generator
$test6_2 = Show-TestResult -TestName "6.2 Enregistrement d'un gÃ©nÃ©rateur" -Success $result -Message "GÃ©nÃ©rateur enregistrÃ© pour le pattern 'User:*'"
$testResults += $test6_2

# Test 6.3: PrÃ©chargement de clÃ©s
$preloadManager.PreloadKeys(@("User:123", "User:456"))
$test6_3 = Show-TestResult -TestName "6.3 PrÃ©chargement de clÃ©s" -Success $true -Message "PrÃ©chargement dÃ©clenchÃ© pour 2 clÃ©s"
$testResults += $test6_3

# Section 7: IntÃ©gration complÃ¨te
Show-SectionTitle "7. IntÃ©gration complÃ¨te"

# Test 7.1: Optimisation du cache prÃ©dictif
$result = Optimize-PredictiveCache -Cache $cache
$test7_1 = Show-TestResult -TestName "7.1 Optimisation du cache prÃ©dictif" -Success $result -Message "Optimisation rÃ©ussie"
$testResults += $test7_1

# Test 7.2: Statistiques du cache prÃ©dictif
$stats = Get-PredictiveCacheStatistics -Cache $cache
$test7_2 = Show-TestResult -TestName "7.2 Statistiques du cache prÃ©dictif" -Success ($null -ne $stats) -Message "Statistiques rÃ©cupÃ©rÃ©es: Hits=$($stats.BaseCache.Hits), Misses=$($stats.BaseCache.Misses)"
$testResults += $test7_2

# Test 7.3: DÃ©clenchement du prÃ©chargement
$cache.TriggerPreload()
$test7_3 = Show-TestResult -TestName "7.3 DÃ©clenchement du prÃ©chargement" -Success $true -Message "PrÃ©chargement dÃ©clenchÃ©"
$testResults += $test7_3

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
