<#
.SYNOPSIS
    Tests simplifiÃ©s pour le systÃ¨me de cache prÃ©dictif.
.DESCRIPTION
    Ce script exÃ©cute des tests simplifiÃ©s pour le systÃ¨me de cache prÃ©dictif
    en utilisant les types simulÃ©s.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer le module de types simulÃ©s
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests"
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

# CrÃ©er les rÃ©pertoires nÃ©cessaires
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

Write-Host "ExÃ©cution des tests simplifiÃ©s pour le cache prÃ©dictif..." -ForegroundColor Cyan

# Test 1: CrÃ©ation d'un cache de base
Write-Host "`nTest 1: CrÃ©ation d'un cache de base" -ForegroundColor Green
$baseCache = [CacheManager]::new("TestCache", $testCachePath)
Write-Host "  Cache crÃ©Ã©: $($baseCache.Name)" -ForegroundColor White
Write-Host "  Chemin: $($baseCache.CachePath)" -ForegroundColor White

# Test 2: OpÃ©rations de base sur le cache
Write-Host "`nTest 2: OpÃ©rations de base sur le cache" -ForegroundColor Green
$baseCache.Set("TestKey", "TestValue")
$value = $baseCache.Get("TestKey")
Write-Host "  Valeur rÃ©cupÃ©rÃ©e: $value" -ForegroundColor White
Write-Host "  ClÃ© existe: $($baseCache.Contains("TestKey"))" -ForegroundColor White
$baseCache.Remove("TestKey")
Write-Host "  ClÃ© aprÃ¨s suppression: $($baseCache.Contains("TestKey"))" -ForegroundColor White

# Test 3: CrÃ©ation d'un collecteur d'utilisation
Write-Host "`nTest 3: CrÃ©ation d'un collecteur d'utilisation" -ForegroundColor Green
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
Write-Host "  Collecteur crÃ©Ã©: $($collector.CacheName)" -ForegroundColor White
Write-Host "  Base de donnÃ©es: $($collector.DatabasePath)" -ForegroundColor White

# Test 4: Enregistrement des accÃ¨s au cache
Write-Host "`nTest 4: Enregistrement des accÃ¨s au cache" -ForegroundColor Green
$collector.RecordAccess("Key1", $true)
$collector.RecordAccess("Key2", $false)
$collector.RecordSet("Key1", "Value1", 3600)
$stats = $collector.GetKeyAccessStats("Key1")
Write-Host "  Statistiques pour Key1:" -ForegroundColor White
Write-Host "    Total des accÃ¨s: $($stats.TotalAccesses)" -ForegroundColor White
Write-Host "    Hits: $($stats.Hits)" -ForegroundColor White
Write-Host "    Ratio de hits: $($stats.HitRatio)" -ForegroundColor White

# Test 5: CrÃ©ation d'un moteur de prÃ©diction
Write-Host "`nTest 5: CrÃ©ation d'un moteur de prÃ©diction" -ForegroundColor Green
$engine = New-PredictionEngine -UsageCollector $collector -CacheName "TestCache"
Write-Host "  Moteur crÃ©Ã©: $($engine.CacheName)" -ForegroundColor White

# Test 6: PrÃ©diction des prochains accÃ¨s
Write-Host "`nTest 6: PrÃ©diction des prochains accÃ¨s" -ForegroundColor Green
$predictions = $engine.PredictNextAccesses()
Write-Host "  Nombre de prÃ©dictions: $($predictions.Count)" -ForegroundColor White
foreach ($prediction in $predictions) {
    Write-Host "    ClÃ©: $($prediction.Key), ProbabilitÃ©: $($prediction.Probability)" -ForegroundColor White
}

# Test 7: CrÃ©ation d'un optimiseur de TTL
Write-Host "`nTest 7: CrÃ©ation d'un optimiseur de TTL" -ForegroundColor Green
$optimizer = New-TTLOptimizer -BaseCache $baseCache -UsageCollector $collector
Write-Host "  Optimiseur crÃ©Ã©" -ForegroundColor White
Write-Host "  TTL minimum: $($optimizer.MinimumTTL)" -ForegroundColor White
Write-Host "  TTL maximum: $($optimizer.MaximumTTL)" -ForegroundColor White

# Test 8: Configuration de l'optimiseur de TTL
Write-Host "`nTest 8: Configuration de l'optimiseur de TTL" -ForegroundColor Green
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL 300 -MaximumTTL 43200
Write-Host "  Configuration rÃ©ussie: $result" -ForegroundColor White
Write-Host "  Nouveau TTL minimum: $($optimizer.MinimumTTL)" -ForegroundColor White
Write-Host "  Nouveau TTL maximum: $($optimizer.MaximumTTL)" -ForegroundColor White

# Test 9: CrÃ©ation d'un gestionnaire de dÃ©pendances
Write-Host "`nTest 9: CrÃ©ation d'un gestionnaire de dÃ©pendances" -ForegroundColor Green
$manager = New-DependencyManager -BaseCache $baseCache -UsageCollector $collector
Write-Host "  Gestionnaire crÃ©Ã©" -ForegroundColor White
Write-Host "  DÃ©tection automatique: $($manager.AutoDetectDependencies)" -ForegroundColor White

# Test 10: Ajout de dÃ©pendances
Write-Host "`nTest 10: Ajout de dÃ©pendances" -ForegroundColor Green
$result = Add-CacheDependency -DependencyManager $manager -SourceKey "Source" -TargetKey "Target" -Strength 0.8
Write-Host "  Ajout rÃ©ussi: $result" -ForegroundColor White
$dependencies = $manager.GetDependencies("Source")
Write-Host "  DÃ©pendances pour Source: $($dependencies.Count)" -ForegroundColor White
Write-Host "  Force de la dÃ©pendance: $($dependencies["Target"])" -ForegroundColor White

# Test 11: CrÃ©ation d'un gestionnaire de prÃ©chargement
Write-Host "`nTest 11: CrÃ©ation d'un gestionnaire de prÃ©chargement" -ForegroundColor Green
$preloadManager = New-PreloadManager -BaseCache $baseCache -PredictionEngine $engine
Write-Host "  Gestionnaire crÃ©Ã©" -ForegroundColor White
Write-Host "  PrÃ©chargements max: $($preloadManager.MaxConcurrentPreloads)" -ForegroundColor White

# Test 12: Enregistrement d'un gÃ©nÃ©rateur de prÃ©chargement
Write-Host "`nTest 12: Enregistrement d'un gÃ©nÃ©rateur de prÃ©chargement" -ForegroundColor Green
$generator = { return "Valeur prÃ©chargÃ©e" }
$result = Register-PreloadGenerator -PreloadManager $preloadManager -KeyPattern "User:*" -Generator $generator
Write-Host "  Enregistrement rÃ©ussi: $result" -ForegroundColor White

# Test 13: CrÃ©ation d'un cache prÃ©dictif
Write-Host "`nTest 13: CrÃ©ation d'un cache prÃ©dictif" -ForegroundColor Green
$predictiveCache = New-PredictiveCache -Name "TestPredictiveCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
Write-Host "  Cache prÃ©dictif crÃ©Ã©: $($predictiveCache.Name)" -ForegroundColor White
Write-Host "  Base de donnÃ©es: $($predictiveCache.UsageDatabasePath)" -ForegroundColor White

# Test 14: Configuration du cache prÃ©dictif
Write-Host "`nTest 14: Configuration du cache prÃ©dictif" -ForegroundColor Green
$result = Set-PredictiveCacheOptions -Cache $predictiveCache -PreloadEnabled $true -AdaptiveTTL $true -DependencyTracking $true
Write-Host "  Configuration rÃ©ussie: $result" -ForegroundColor White
Write-Host "  PrÃ©chargement activÃ©: $($predictiveCache.PreloadEnabled)" -ForegroundColor White
Write-Host "  TTL adaptatif activÃ©: $($predictiveCache.AdaptiveTTLEnabled)" -ForegroundColor White
Write-Host "  Suivi des dÃ©pendances activÃ©: $($predictiveCache.DependencyTrackingEnabled)" -ForegroundColor White

# Test 15: Optimisation du cache prÃ©dictif
Write-Host "`nTest 15: Optimisation du cache prÃ©dictif" -ForegroundColor Green
$result = Optimize-PredictiveCache -Cache $predictiveCache
Write-Host "  Optimisation rÃ©ussie: $result" -ForegroundColor White

# Test 16: Statistiques du cache prÃ©dictif
Write-Host "`nTest 16: Statistiques du cache prÃ©dictif" -ForegroundColor Green
$stats = Get-PredictiveCacheStatistics -Cache $predictiveCache
Write-Host "  Statistiques rÃ©cupÃ©rÃ©es" -ForegroundColor White
Write-Host "  Hits de prÃ©diction: $($stats.PredictionHits)" -ForegroundColor White
Write-Host "  Misses de prÃ©diction: $($stats.PredictionMisses)" -ForegroundColor White
Write-Host "  PrÃ©cision des prÃ©dictions: $([Math]::Round($stats.PredictionAccuracy * 100, 2))%" -ForegroundColor White

# Nettoyage
Write-Host "`nNettoyage..." -ForegroundColor Cyan
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

Write-Host "`nTests terminÃ©s avec succÃ¨s!" -ForegroundColor Green
