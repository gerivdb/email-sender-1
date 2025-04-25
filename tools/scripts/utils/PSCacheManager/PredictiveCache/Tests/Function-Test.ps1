<#
.SYNOPSIS
    Test unitaire simple pour les fonctions du cache prédictif.
.DESCRIPTION
    Ce script teste les fonctions exportées par le module MockTypes.psm1.
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

Write-Host "Test des fonctions du cache prédictif" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Test 1: Création d'un cache prédictif
Write-Host "`nTest 1: Création d'un cache prédictif" -ForegroundColor Green
$cache = New-PredictiveCache -Name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
Write-Host "  Cache créé: $($cache.Name)" -ForegroundColor White
Write-Host "  Base de données: $($cache.UsageDatabasePath)" -ForegroundColor White
$test1Success = ($cache -ne $null) -and ($cache.Name -eq "TestCache")
Write-Host "  Résultat: $(if ($test1Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })

# Test 2: Configuration du cache prédictif
Write-Host "`nTest 2: Configuration du cache prédictif" -ForegroundColor Green
$result = Set-PredictiveCacheOptions -Cache $cache -PreloadEnabled $true -AdaptiveTTL $true
Write-Host "  Configuration réussie: $result" -ForegroundColor White
$test2Success = ($result -eq $true) -and ($cache.PreloadEnabled -eq $true) -and ($cache.AdaptiveTTLEnabled -eq $true)
Write-Host "  Résultat: $(if ($test2Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })

# Test 3: Optimisation du cache prédictif
Write-Host "`nTest 3: Optimisation du cache prédictif" -ForegroundColor Green
$result = Optimize-PredictiveCache -Cache $cache
Write-Host "  Optimisation réussie: $result" -ForegroundColor White
$test3Success = $result -eq $true
Write-Host "  Résultat: $(if ($test3Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test3Success) { "Green" } else { "Red" })

# Test 4: Statistiques du cache prédictif
Write-Host "`nTest 4: Statistiques du cache prédictif" -ForegroundColor Green
$stats = Get-PredictiveCacheStatistics -Cache $cache
Write-Host "  Statistiques récupérées: $($stats -ne $null)" -ForegroundColor White
$test4Success = $stats -ne $null
Write-Host "  Résultat: $(if ($test4Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test4Success) { "Green" } else { "Red" })

# Test 5: Création d'un collecteur d'utilisation
Write-Host "`nTest 5: Création d'un collecteur d'utilisation" -ForegroundColor Green
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
Write-Host "  Collecteur créé: $($collector -ne $null)" -ForegroundColor White
$test5Success = $collector -ne $null
Write-Host "  Résultat: $(if ($test5Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test5Success) { "Green" } else { "Red" })

# Test 6: Création d'un moteur de prédiction
Write-Host "`nTest 6: Création d'un moteur de prédiction" -ForegroundColor Green
$engine = New-PredictionEngine -UsageCollector $collector -CacheName "TestCache"
Write-Host "  Moteur créé: $($engine -ne $null)" -ForegroundColor White
$test6Success = $engine -ne $null
Write-Host "  Résultat: $(if ($test6Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test6Success) { "Green" } else { "Red" })

# Résumé des tests
Write-Host "`nRésumé des tests" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
$totalTests = 6
$passedTests = @($test1Success, $test2Success, $test3Success, $test4Success, $test5Success, $test6Success).Where({ $_ -eq $true }).Count
Write-Host "Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "Tests échoués: $($totalTests - $passedTests)" -ForegroundColor Red

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
