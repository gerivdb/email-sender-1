<#
.SYNOPSIS
    Test unitaire simple pour le CacheManager.
.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s de base du CacheManager.
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

# DÃ©finir le chemin du cache de test
$testCachePath = Join-Path -Path $testDir -ChildPath "Cache"

# Nettoyer les tests prÃ©cÃ©dents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}

# CrÃ©er le rÃ©pertoire du cache
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

Write-Host "Test du CacheManager" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

# Test 1: CrÃ©ation d'un cache
Write-Host "`nTest 1: CrÃ©ation d'un cache" -ForegroundColor Green
$cache = [CacheManager]::new("TestCache", $testCachePath)
Write-Host "  Cache crÃ©Ã©: $($cache.Name)" -ForegroundColor White
Write-Host "  Chemin: $($cache.CachePath)" -ForegroundColor White
$test1Success = ($cache.Name -eq "TestCache") -and ($cache.CachePath -eq $testCachePath)
Write-Host "  RÃ©sultat: $(if ($test1Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })

# Test 2: DÃ©finition d'une valeur dans le cache
Write-Host "`nTest 2: DÃ©finition d'une valeur dans le cache" -ForegroundColor Green
$cache.Set("TestKey", "TestValue")
$test2Success = $cache.Cache.ContainsKey("TestKey")
Write-Host "  ClÃ© ajoutÃ©e: $test2Success" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })

# Test 3: RÃ©cupÃ©ration d'une valeur du cache
Write-Host "`nTest 3: RÃ©cupÃ©ration d'une valeur du cache" -ForegroundColor Green
$value = $cache.Get("TestKey")
Write-Host "  Valeur rÃ©cupÃ©rÃ©e: $value" -ForegroundColor White
$test3Success = $value -eq "TestValue"
Write-Host "  RÃ©sultat: $(if ($test3Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test3Success) { "Green" } else { "Red" })

# Test 4: VÃ©rification de l'existence d'une clÃ©
Write-Host "`nTest 4: VÃ©rification de l'existence d'une clÃ©" -ForegroundColor Green
$exists = $cache.Contains("TestKey")
Write-Host "  ClÃ© existe: $exists" -ForegroundColor White
$test4Success = $exists -eq $true
Write-Host "  RÃ©sultat: $(if ($test4Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test4Success) { "Green" } else { "Red" })

# Test 5: Suppression d'une clÃ©
Write-Host "`nTest 5: Suppression d'une clÃ©" -ForegroundColor Green
$cache.Remove("TestKey")
$exists = $cache.Contains("TestKey")
Write-Host "  ClÃ© existe aprÃ¨s suppression: $exists" -ForegroundColor White
$test5Success = $exists -eq $false
Write-Host "  RÃ©sultat: $(if ($test5Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test5Success) { "Green" } else { "Red" })

# Test 6: Vidage du cache
Write-Host "`nTest 6: Vidage du cache" -ForegroundColor Green
$cache.Set("Key1", "Value1")
$cache.Set("Key2", "Value2")
$cache.Clear()
$count = $cache.Cache.Count
Write-Host "  Nombre d'Ã©lÃ©ments aprÃ¨s vidage: $count" -ForegroundColor White
$test6Success = $count -eq 0
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

# RÃ©sultat final
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
