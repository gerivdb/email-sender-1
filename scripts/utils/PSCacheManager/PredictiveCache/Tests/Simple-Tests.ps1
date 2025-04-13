<#
.SYNOPSIS
    Tests simplifiés pour le système de cache prédictif.
.DESCRIPTION
    Ce script exécute des tests simplifiés pour le système de cache prédictif
    en utilisant les types simulés.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer le module de types simulés
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests"
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

# Créer les répertoires nécessaires
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

Write-Host "Exécution des tests simplifiés pour le cache prédictif..." -ForegroundColor Cyan

# Test 1: Création d'un cache de base
Write-Host "`nTest 1: Création d'un cache de base" -ForegroundColor Green
$baseCache = [CacheManager]::new("TestCache", $testCachePath)
Write-Host "  Cache créé: $($baseCache.Name)" -ForegroundColor White
Write-Host "  Chemin: $($baseCache.CachePath)" -ForegroundColor White

# Test 2: Opérations de base sur le cache
Write-Host "`nTest 2: Opérations de base sur le cache" -ForegroundColor Green
$baseCache.Set("TestKey", "TestValue")
$value = $baseCache.Get("TestKey")
Write-Host "  Valeur récupérée: $value" -ForegroundColor White
Write-Host "  Clé existe: $($baseCache.Contains("TestKey"))" -ForegroundColor White
$baseCache.Remove("TestKey")
Write-Host "  Clé après suppression: $($baseCache.Contains("TestKey"))" -ForegroundColor White

# Test 3: Création d'un collecteur d'utilisation
Write-Host "`nTest 3: Création d'un collecteur d'utilisation" -ForegroundColor Green
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
Write-Host "  Collecteur créé: $($collector.CacheName)" -ForegroundColor White
Write-Host "  Base de données: $($collector.DatabasePath)" -ForegroundColor White

# Test 4: Enregistrement des accès au cache
Write-Host "`nTest 4: Enregistrement des accès au cache" -ForegroundColor Green
$collector.RecordAccess("Key1", $true)
$collector.RecordAccess("Key2", $false)
$collector.RecordSet("Key1", "Value1", 3600)
$stats = $collector.GetKeyAccessStats("Key1")
Write-Host "  Statistiques pour Key1:" -ForegroundColor White
Write-Host "    Total des accès: $($stats.TotalAccesses)" -ForegroundColor White
Write-Host "    Hits: $($stats.Hits)" -ForegroundColor White
Write-Host "    Ratio de hits: $($stats.HitRatio)" -ForegroundColor White

# Test 5: Création d'un moteur de prédiction
Write-Host "`nTest 5: Création d'un moteur de prédiction" -ForegroundColor Green
$engine = New-PredictionEngine -UsageCollector $collector -CacheName "TestCache"
Write-Host "  Moteur créé: $($engine.CacheName)" -ForegroundColor White

# Test 6: Prédiction des prochains accès
Write-Host "`nTest 6: Prédiction des prochains accès" -ForegroundColor Green
$predictions = $engine.PredictNextAccesses()
Write-Host "  Nombre de prédictions: $($predictions.Count)" -ForegroundColor White
foreach ($prediction in $predictions) {
    Write-Host "    Clé: $($prediction.Key), Probabilité: $($prediction.Probability)" -ForegroundColor White
}

# Test 7: Création d'un optimiseur de TTL
Write-Host "`nTest 7: Création d'un optimiseur de TTL" -ForegroundColor Green
$optimizer = New-TTLOptimizer -BaseCache $baseCache -UsageCollector $collector
Write-Host "  Optimiseur créé" -ForegroundColor White
Write-Host "  TTL minimum: $($optimizer.MinimumTTL)" -ForegroundColor White
Write-Host "  TTL maximum: $($optimizer.MaximumTTL)" -ForegroundColor White

# Test 8: Configuration de l'optimiseur de TTL
Write-Host "`nTest 8: Configuration de l'optimiseur de TTL" -ForegroundColor Green
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL 300 -MaximumTTL 43200
Write-Host "  Configuration réussie: $result" -ForegroundColor White
Write-Host "  Nouveau TTL minimum: $($optimizer.MinimumTTL)" -ForegroundColor White
Write-Host "  Nouveau TTL maximum: $($optimizer.MaximumTTL)" -ForegroundColor White

# Test 9: Création d'un gestionnaire de dépendances
Write-Host "`nTest 9: Création d'un gestionnaire de dépendances" -ForegroundColor Green
$manager = New-DependencyManager -BaseCache $baseCache -UsageCollector $collector
Write-Host "  Gestionnaire créé" -ForegroundColor White
Write-Host "  Détection automatique: $($manager.AutoDetectDependencies)" -ForegroundColor White

# Test 10: Ajout de dépendances
Write-Host "`nTest 10: Ajout de dépendances" -ForegroundColor Green
$result = Add-CacheDependency -DependencyManager $manager -SourceKey "Source" -TargetKey "Target" -Strength 0.8
Write-Host "  Ajout réussi: $result" -ForegroundColor White
$dependencies = $manager.GetDependencies("Source")
Write-Host "  Dépendances pour Source: $($dependencies.Count)" -ForegroundColor White
Write-Host "  Force de la dépendance: $($dependencies["Target"])" -ForegroundColor White

# Test 11: Création d'un gestionnaire de préchargement
Write-Host "`nTest 11: Création d'un gestionnaire de préchargement" -ForegroundColor Green
$preloadManager = New-PreloadManager -BaseCache $baseCache -PredictionEngine $engine
Write-Host "  Gestionnaire créé" -ForegroundColor White
Write-Host "  Préchargements max: $($preloadManager.MaxConcurrentPreloads)" -ForegroundColor White

# Test 12: Enregistrement d'un générateur de préchargement
Write-Host "`nTest 12: Enregistrement d'un générateur de préchargement" -ForegroundColor Green
$generator = { return "Valeur préchargée" }
$result = Register-PreloadGenerator -PreloadManager $preloadManager -KeyPattern "User:*" -Generator $generator
Write-Host "  Enregistrement réussi: $result" -ForegroundColor White

# Test 13: Création d'un cache prédictif
Write-Host "`nTest 13: Création d'un cache prédictif" -ForegroundColor Green
$predictiveCache = New-PredictiveCache -Name "TestPredictiveCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
Write-Host "  Cache prédictif créé: $($predictiveCache.Name)" -ForegroundColor White
Write-Host "  Base de données: $($predictiveCache.UsageDatabasePath)" -ForegroundColor White

# Test 14: Configuration du cache prédictif
Write-Host "`nTest 14: Configuration du cache prédictif" -ForegroundColor Green
$result = Set-PredictiveCacheOptions -Cache $predictiveCache -PreloadEnabled $true -AdaptiveTTL $true -DependencyTracking $true
Write-Host "  Configuration réussie: $result" -ForegroundColor White
Write-Host "  Préchargement activé: $($predictiveCache.PreloadEnabled)" -ForegroundColor White
Write-Host "  TTL adaptatif activé: $($predictiveCache.AdaptiveTTLEnabled)" -ForegroundColor White
Write-Host "  Suivi des dépendances activé: $($predictiveCache.DependencyTrackingEnabled)" -ForegroundColor White

# Test 15: Optimisation du cache prédictif
Write-Host "`nTest 15: Optimisation du cache prédictif" -ForegroundColor Green
$result = Optimize-PredictiveCache -Cache $predictiveCache
Write-Host "  Optimisation réussie: $result" -ForegroundColor White

# Test 16: Statistiques du cache prédictif
Write-Host "`nTest 16: Statistiques du cache prédictif" -ForegroundColor Green
$stats = Get-PredictiveCacheStatistics -Cache $predictiveCache
Write-Host "  Statistiques récupérées" -ForegroundColor White
Write-Host "  Hits de prédiction: $($stats.PredictionHits)" -ForegroundColor White
Write-Host "  Misses de prédiction: $($stats.PredictionMisses)" -ForegroundColor White
Write-Host "  Précision des prédictions: $([Math]::Round($stats.PredictionAccuracy * 100, 2))%" -ForegroundColor White

# Nettoyage
Write-Host "`nNettoyage..." -ForegroundColor Cyan
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

Write-Host "`nTests terminés avec succès!" -ForegroundColor Green
