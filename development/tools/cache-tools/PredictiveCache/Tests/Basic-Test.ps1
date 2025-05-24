<#
.SYNOPSIS
    Test de base pour le systÃ¨me de cache prÃ©dictif.
.DESCRIPTION
    Ce script exÃ©cute un test de base pour le systÃ¨me de cache prÃ©dictif
    en utilisant des fonctions simples.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

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

Write-Host "Test de base pour le cache prÃ©dictif" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# CrÃ©er un cache simple
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

function Write-CacheAccess {
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

# DÃ©pendances
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

# Cache prÃ©dictif
function Get-PredictiveCacheItem {
    param([string]$key)
    $value = Get-CacheItem -key $key
    $hit = $null -ne $value
    
    Write-CacheAccess -key $key -hit $hit
    
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
Write-Host "  Valeur rÃ©cupÃ©rÃ©e: $value" -ForegroundColor White
$test1Success = $value -eq "TestValue"
Write-Host "  RÃ©sultat: $(if ($test1Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })

# Test 2: Enregistrement des accÃ¨s
Write-Host "`nTest 2: Enregistrement des accÃ¨s" -ForegroundColor Green
Write-CacheAccess -key "Key1" -hit $true
Write-CacheAccess -key "Key1" -hit $true
Write-CacheAccess -key "Key2" -hit $false
$stats = Get-KeyAccessStats -key "Key1"
Write-Host "  Statistiques pour Key1: Hits=$($stats.Hits), Misses=$($stats.Misses), Total=$($stats.TotalAccesses)" -ForegroundColor White
$test2Success = $stats.Hits -eq 2 -and $stats.TotalAccesses -eq 2
Write-Host "  RÃ©sultat: $(if ($test2Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })

# Test 3: Gestion des dÃ©pendances
Write-Host "`nTest 3: Gestion des dÃ©pendances" -ForegroundColor Green
Add-CacheDependency -sourceKey "Source1" -targetKey "Target1" -strength 0.8
$deps = Get-CacheDependencies -key "Source1"
Write-Host "  DÃ©pendances pour Source1: $($deps.Count)" -ForegroundColor White
$test3Success = $deps.Count -eq 1 -and $deps["Target1"] -eq 0.8
Write-Host "  RÃ©sultat: $(if ($test3Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test3Success) { "Green" } else { "Red" })

# Test 4: Cache prÃ©dictif
Write-Host "`nTest 4: Cache prÃ©dictif" -ForegroundColor Green
Set-PredictiveCacheItem -key "PredictiveKey" -value "PredictiveValue"
$value = Get-PredictiveCacheItem -key "PredictiveKey"
Write-Host "  Valeur rÃ©cupÃ©rÃ©e: $value" -ForegroundColor White
$test4Success = $value -eq "PredictiveValue"
Write-Host "  RÃ©sultat: $(if ($test4Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test4Success) { "Green" } else { "Red" })

# Test 5: VÃ©rification des statistiques aprÃ¨s utilisation du cache prÃ©dictif
Write-Host "`nTest 5: VÃ©rification des statistiques aprÃ¨s utilisation du cache prÃ©dictif" -ForegroundColor Green
$stats = Get-KeyAccessStats -key "PredictiveKey"
Write-Host "  Statistiques pour PredictiveKey: Hits=$($stats.Hits), Misses=$($stats.Misses), Total=$($stats.TotalAccesses)" -ForegroundColor White
$test5Success = $stats.Hits -eq 1 -and $stats.TotalAccesses -eq 1
Write-Host "  RÃ©sultat: $(if ($test5Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test5Success) { "Green" } else { "Red" })

# RÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
$totalTests = 5
$passedTests = @($test1Success, $test2Success, $test3Success, $test4Success, $test5Success).Where({ $_ -eq $true }).Count
Write-Host "Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor White
Write-Host "Tests rÃ©ussis: $passedTests" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s: $($totalTests - $passedTests)" -ForegroundColor Red
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

