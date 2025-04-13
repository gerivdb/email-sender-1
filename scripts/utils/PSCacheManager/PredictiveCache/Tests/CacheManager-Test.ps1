<#
.SYNOPSIS
    Test unitaire simple pour le CacheManager.
.DESCRIPTION
    Ce script teste les fonctionnalités de base du CacheManager.
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

# Définir le chemin du cache de test
$testCachePath = Join-Path -Path $testDir -ChildPath "Cache"

# Nettoyer les tests précédents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}

# Créer le répertoire du cache
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

Write-Host "Test du CacheManager" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

# Test 1: Création d'un cache
Write-Host "`nTest 1: Création d'un cache" -ForegroundColor Green
$cache = [CacheManager]::new("TestCache", $testCachePath)
Write-Host "  Cache créé: $($cache.Name)" -ForegroundColor White
Write-Host "  Chemin: $($cache.CachePath)" -ForegroundColor White
$test1Success = ($cache.Name -eq "TestCache") -and ($cache.CachePath -eq $testCachePath)
Write-Host "  Résultat: $(if ($test1Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })

# Test 2: Définition d'une valeur dans le cache
Write-Host "`nTest 2: Définition d'une valeur dans le cache" -ForegroundColor Green
$cache.Set("TestKey", "TestValue")
$test2Success = $cache.Cache.ContainsKey("TestKey")
Write-Host "  Clé ajoutée: $test2Success" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })

# Test 3: Récupération d'une valeur du cache
Write-Host "`nTest 3: Récupération d'une valeur du cache" -ForegroundColor Green
$value = $cache.Get("TestKey")
Write-Host "  Valeur récupérée: $value" -ForegroundColor White
$test3Success = $value -eq "TestValue"
Write-Host "  Résultat: $(if ($test3Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test3Success) { "Green" } else { "Red" })

# Test 4: Vérification de l'existence d'une clé
Write-Host "`nTest 4: Vérification de l'existence d'une clé" -ForegroundColor Green
$exists = $cache.Contains("TestKey")
Write-Host "  Clé existe: $exists" -ForegroundColor White
$test4Success = $exists -eq $true
Write-Host "  Résultat: $(if ($test4Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test4Success) { "Green" } else { "Red" })

# Test 5: Suppression d'une clé
Write-Host "`nTest 5: Suppression d'une clé" -ForegroundColor Green
$cache.Remove("TestKey")
$exists = $cache.Contains("TestKey")
Write-Host "  Clé existe après suppression: $exists" -ForegroundColor White
$test5Success = $exists -eq $false
Write-Host "  Résultat: $(if ($test5Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test5Success) { "Green" } else { "Red" })

# Test 6: Vidage du cache
Write-Host "`nTest 6: Vidage du cache" -ForegroundColor Green
$cache.Set("Key1", "Value1")
$cache.Set("Key2", "Value2")
$cache.Clear()
$count = $cache.Cache.Count
Write-Host "  Nombre d'éléments après vidage: $count" -ForegroundColor White
$test6Success = $count -eq 0
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

# Résultat final
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
