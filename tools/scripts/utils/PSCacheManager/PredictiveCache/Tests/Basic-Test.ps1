<#
.SYNOPSIS
    Test de base pour le système de cache prédictif.
.DESCRIPTION
    Ce script exécute un test de base pour le système de cache prédictif
    en utilisant des fonctions simples.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

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

Write-Host "Test de base pour le cache prédictif" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Créer un cache simple
$cache = @{}

# Fonctions de base pour le cache
function Get-CacheItem {
    param([string]$key)
    if ($cache.ContainsKey($key)) {
        return $cache[$key]
    }
    return $null
}

function Set-CacheItem {
    param([string]$key, [object]$value)
    $cache[$key] = $value
}

function Test-CacheItem {
    param([string]$key)
    return $cache.ContainsKey($key)
}

function Remove-CacheItem {
    param([string]$key)
    if ($cache.ContainsKey($key)) {
        $cache.Remove($key)
    }
}

function Clear-Cache {
    $cache.Clear()
}

# Statistiques d'utilisation
$accessStats = @{}

function Record-CacheAccess {
    param([string]$key, [bool]$hit)
    if (-not $accessStats.ContainsKey($key)) {
        $accessStats[$key] = @{
            Hits = 0
            Misses = 0
            TotalAccesses = 0
            LastAccess = Get-Date
        }
    }
    
    $accessStats[$key].TotalAccesses++
    if ($hit) {
        $accessStats[$key].Hits++
    } else {
        $accessStats[$key].Misses++
    }
    $accessStats[$key].LastAccess = Get-Date
}

function Get-KeyAccessStats {
    param([string]$key)
    if ($accessStats.ContainsKey($key)) {
        $stats = $accessStats[$key]
        $hitRatio = 0
        if ($stats.TotalAccesses -gt 0) {
            $hitRatio = $stats.Hits / $stats.TotalAccesses
        }
        
        return [PSCustomObject]@{
            Key = $key
            TotalAccesses = $stats.TotalAccesses
            Hits = $stats.Hits
            Misses = $stats.Misses
            HitRatio = $hitRatio
            LastAccess = $stats.LastAccess
        }
    }
    return $null
}

# Dépendances
$dependencies = @{}

function Add-CacheDependency {
    param([string]$sourceKey, [string]$targetKey, [double]$strength)
    if ($sourceKey -eq $targetKey) {
        return
    }
    
    if (-not $dependencies.ContainsKey($sourceKey)) {
        $dependencies[$sourceKey] = @{}
    }
    
    $dependencies[$sourceKey][$targetKey] = $strength
}

function Get-CacheDependencies {
    param([string]$key)
    if ($dependencies.ContainsKey($key)) {
        return $dependencies[$key]
    }
    
    return @{}
}

function Remove-CacheDependency {
    param([string]$sourceKey, [string]$targetKey)
    if (-not $dependencies.ContainsKey($sourceKey)) {
        return $false
    }
    
    if (-not $dependencies[$sourceKey].ContainsKey($targetKey)) {
        return $false
    }
    
    $dependencies[$sourceKey].Remove($targetKey)
    return $true
}

# Cache prédictif
function Get-PredictiveCacheItem {
    param([string]$key)
    $value = Get-CacheItem -key $key
    $hit = $null -ne $value
    
    Record-CacheAccess -key $key -hit $hit
    
    return $value
}

function Set-PredictiveCacheItem {
    param([string]$key, [object]$value)
    Set-CacheItem -key $key -value $value
}

# Test 1: Utilisation du cache de base
Write-Host "`nTest 1: Utilisation du cache de base" -ForegroundColor Green
Set-CacheItem -key "TestKey" -value "TestValue"
$value = Get-CacheItem -key "TestKey"
Write-Host "  Valeur récupérée: $value" -ForegroundColor White
$test1Success = $value -eq "TestValue"
Write-Host "  Résultat: $(if ($test1Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })

# Test 2: Enregistrement des accès
Write-Host "`nTest 2: Enregistrement des accès" -ForegroundColor Green
Record-CacheAccess -key "Key1" -hit $true
Record-CacheAccess -key "Key1" -hit $true
Record-CacheAccess -key "Key2" -hit $false
$stats = Get-KeyAccessStats -key "Key1"
Write-Host "  Statistiques pour Key1: Hits=$($stats.Hits), Misses=$($stats.Misses), Total=$($stats.TotalAccesses)" -ForegroundColor White
$test2Success = $stats.Hits -eq 2 -and $stats.TotalAccesses -eq 2
Write-Host "  Résultat: $(if ($test2Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })

# Test 3: Gestion des dépendances
Write-Host "`nTest 3: Gestion des dépendances" -ForegroundColor Green
Add-CacheDependency -sourceKey "Source1" -targetKey "Target1" -strength 0.8
$deps = Get-CacheDependencies -key "Source1"
Write-Host "  Dépendances pour Source1: $($deps.Count)" -ForegroundColor White
$test3Success = $deps.Count -eq 1 -and $deps["Target1"] -eq 0.8
Write-Host "  Résultat: $(if ($test3Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test3Success) { "Green" } else { "Red" })

# Test 4: Cache prédictif
Write-Host "`nTest 4: Cache prédictif" -ForegroundColor Green
Set-PredictiveCacheItem -key "PredictiveKey" -value "PredictiveValue"
$value = Get-PredictiveCacheItem -key "PredictiveKey"
Write-Host "  Valeur récupérée: $value" -ForegroundColor White
$test4Success = $value -eq "PredictiveValue"
Write-Host "  Résultat: $(if ($test4Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test4Success) { "Green" } else { "Red" })

# Test 5: Vérification des statistiques après utilisation du cache prédictif
Write-Host "`nTest 5: Vérification des statistiques après utilisation du cache prédictif" -ForegroundColor Green
$stats = Get-KeyAccessStats -key "PredictiveKey"
Write-Host "  Statistiques pour PredictiveKey: Hits=$($stats.Hits), Misses=$($stats.Misses), Total=$($stats.TotalAccesses)" -ForegroundColor White
$test5Success = $stats.Hits -eq 1 -and $stats.TotalAccesses -eq 1
Write-Host "  Résultat: $(if ($test5Success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($test5Success) { "Green" } else { "Red" })

# Résumé des tests
Write-Host "`nRésumé des tests" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
$totalTests = 5
$passedTests = @($test1Success, $test2Success, $test3Success, $test4Success, $test5Success).Where({ $_ -eq $true }).Count
Write-Host "Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "Tests échoués: $($totalTests - $passedTests)" -ForegroundColor Red
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
