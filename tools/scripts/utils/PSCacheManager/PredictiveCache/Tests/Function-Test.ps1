<#
.SYNOPSIS
    Test unitaire simple pour les fonctions du cache prÃ©dictif.
.DESCRIPTION
    Ce script teste les fonctions exportÃ©es par le module MockTypes.psm1.
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

Write-Host "Test des fonctions du cache prÃ©dictif" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Test 1: CrÃ©ation d'un cache prÃ©dictif
Write-Host "`nTest 1: CrÃ©ation d'un cache prÃ©dictif" -ForegroundColor Green
$cache = New-PredictiveCache -Name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
Write-Host "  Cache crÃ©Ã©: $($cache.Name)" -ForegroundColor White
Write-Host "  Base de donnÃ©es: $($cache.UsageDatabasePath)" -ForegroundColor White
$test1Success = ($cache -ne $null) -and ($cache.Name -eq "TestCache")
Write-Host "  RÃ©sultat: $(if ($test1Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })

# Test 2: Configuration du cache prÃ©dictif
Write-Host "`nTest 2: Configuration du cache prÃ©dictif" -ForegroundColor Green
$result = Set-PredictiveCacheOptions -Cache $cache -PreloadEnabled $true -AdaptiveTTL $true
Write-Host "  Configuration rÃ©ussie: $result" -ForegroundColor White
$test2Success = ($result -eq $true) -and ($cache.PreloadEnabled -eq $true) -and ($cache.AdaptiveTTLEnabled -eq $true)
Write-Host "  RÃ©sultat: $(if ($test2Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })

# Test 3: Optimisation du cache prÃ©dictif
Write-Host "`nTest 3: Optimisation du cache prÃ©dictif" -ForegroundColor Green
$result = Optimize-PredictiveCache -Cache $cache
Write-Host "  Optimisation rÃ©ussie: $result" -ForegroundColor White
$test3Success = $result -eq $true
Write-Host "  RÃ©sultat: $(if ($test3Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test3Success) { "Green" } else { "Red" })

# Test 4: Statistiques du cache prÃ©dictif
Write-Host "`nTest 4: Statistiques du cache prÃ©dictif" -ForegroundColor Green
$stats = Get-PredictiveCacheStatistics -Cache $cache
Write-Host "  Statistiques rÃ©cupÃ©rÃ©es: $($stats -ne $null)" -ForegroundColor White
$test4Success = $stats -ne $null
Write-Host "  RÃ©sultat: $(if ($test4Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test4Success) { "Green" } else { "Red" })

# Test 5: CrÃ©ation d'un collecteur d'utilisation
Write-Host "`nTest 5: CrÃ©ation d'un collecteur d'utilisation" -ForegroundColor Green
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
Write-Host "  Collecteur crÃ©Ã©: $($collector -ne $null)" -ForegroundColor White
$test5Success = $collector -ne $null
Write-Host "  RÃ©sultat: $(if ($test5Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test5Success) { "Green" } else { "Red" })

# Test 6: CrÃ©ation d'un moteur de prÃ©diction
Write-Host "`nTest 6: CrÃ©ation d'un moteur de prÃ©diction" -ForegroundColor Green
$engine = New-PredictionEngine -UsageCollector $collector -CacheName "TestCache"
Write-Host "  Moteur crÃ©Ã©: $($engine -ne $null)" -ForegroundColor White
$test6Success = $engine -ne $null
Write-Host "  RÃ©sultat: $(if ($test6Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test6Success) { "Green" } else { "Red" })

# RÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
$totalTests = 6
$passedTests = @($test1Success, $test2Success, $test3Success, $test4Success, $test5Success, $test6Success).Where({ $_ -eq $true }).Count
Write-Host "Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor White
Write-Host "Tests rÃ©ussis: $passedTests" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s: $($totalTests - $passedTests)" -ForegroundColor Red

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
