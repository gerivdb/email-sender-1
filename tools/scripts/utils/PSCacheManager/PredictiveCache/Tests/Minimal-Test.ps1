<#
.SYNOPSIS
    Test minimal pour le systÃ¨me de cache prÃ©dictif.
.DESCRIPTION
    Ce script exÃ©cute un test minimal pour le systÃ¨me de cache prÃ©dictif
    en utilisant des objets PSCustomObject au lieu des classes.
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

Write-Host "Test minimal pour le cache prÃ©dictif" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# CrÃ©er un cache de base
$baseCache = [PSCustomObject]@{
    Name = "TestCache"
    CachePath = $testCachePath
    Cache = @{}
    Get = {
        param([string]$key)
        if ($this.Cache.ContainsKey($key)) {
            return $this.Cache[$key]
        }
        return $null
    }
    Set = {
        param([string]$key, [object]$value)
        $this.Cache[$key] = $value
    }
    Contains = {
        param([string]$key)
        return $this.Cache.ContainsKey($key)
    }
    Remove = {
        param([string]$key)
        if ($this.Cache.ContainsKey($key)) {
            $this.Cache.Remove($key)
        }
    }
    Clear = {
        $this.Cache.Clear()
    }
}

# CrÃ©er un collecteur d'utilisation
$usageCollector = [PSCustomObject]@{
    DatabasePath = $testDatabasePath
    CacheName = "TestCache"
    AccessStats = @{}
    RecordAccess = {
        param([string]$key, [bool]$hit)
        if (-not $this.AccessStats.ContainsKey($key)) {
            $this.AccessStats[$key] = @{
                Hits = 0
                Misses = 0
                TotalAccesses = 0
                LastAccess = Get-Date
            }
        }
        
        $this.AccessStats[$key].TotalAccesses++
        if ($hit) {
            $this.AccessStats[$key].Hits++
        } else {
            $this.AccessStats[$key].Misses++
        }
        $this.AccessStats[$key].LastAccess = Get-Date
    }
    GetKeyAccessStats = {
        param([string]$key)
        if ($this.AccessStats.ContainsKey($key)) {
            $stats = $this.AccessStats[$key]
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
}

# Test 1: Utilisation du cache de base
Write-Host "`nTest 1: Utilisation du cache de base" -ForegroundColor Green
$baseCache.Set.Invoke("TestKey", "TestValue")
$value = $baseCache.Get.Invoke("TestKey")
Write-Host "  Valeur rÃ©cupÃ©rÃ©e: $value" -ForegroundColor White
$test1Success = $value -eq "TestValue"
Write-Host "  RÃ©sultat: $(if ($test1Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })

# Test 2: Enregistrement des accÃ¨s
Write-Host "`nTest 2: Enregistrement des accÃ¨s" -ForegroundColor Green
$usageCollector.RecordAccess.Invoke("Key1", $true)
$usageCollector.RecordAccess.Invoke("Key1", $true)
$usageCollector.RecordAccess.Invoke("Key2", $false)
$stats = $usageCollector.GetKeyAccessStats.Invoke("Key1")
Write-Host "  Statistiques pour Key1: Hits=$($stats.Hits), Misses=$($stats.Misses), Total=$($stats.TotalAccesses)" -ForegroundColor White
$test2Success = $stats.Hits -eq 2 -and $stats.TotalAccesses -eq 2
Write-Host "  RÃ©sultat: $(if ($test2Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })

# Test 3: CrÃ©ation d'un gestionnaire de dÃ©pendances
Write-Host "`nTest 3: CrÃ©ation d'un gestionnaire de dÃ©pendances" -ForegroundColor Green
$dependencyManager = [PSCustomObject]@{
    BaseCache = $baseCache
    UsageCollector = $usageCollector
    Dependencies = @{}
    AddDependency = {
        param([string]$sourceKey, [string]$targetKey, [double]$strength)
        if ($sourceKey -eq $targetKey) {
            return
        }
        
        if (-not $this.Dependencies.ContainsKey($sourceKey)) {
            $this.Dependencies[$sourceKey] = @{}
        }
        
        $this.Dependencies[$sourceKey][$targetKey] = $strength
    }
    GetDependencies = {
        param([string]$key)
        if ($this.Dependencies.ContainsKey($key)) {
            return $this.Dependencies[$key]
        }
        
        return @{}
    }
}

$dependencyManager.AddDependency.Invoke("Source1", "Target1", 0.8)
$dependencies = $dependencyManager.GetDependencies.Invoke("Source1")
Write-Host "  DÃ©pendances pour Source1: $($dependencies.Count)" -ForegroundColor White
$test3Success = $dependencies.Count -eq 1 -and $dependencies["Target1"] -eq 0.8
Write-Host "  RÃ©sultat: $(if ($test3Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test3Success) { "Green" } else { "Red" })

# Test 4: CrÃ©ation d'un cache prÃ©dictif
Write-Host "`nTest 4: CrÃ©ation d'un cache prÃ©dictif" -ForegroundColor Green
$predictiveCache = [PSCustomObject]@{
    Name = "TestPredictiveCache"
    CachePath = $testCachePath
    UsageDatabasePath = $testDatabasePath
    BaseCache = $baseCache
    UsageCollector = $usageCollector
    DependencyManager = $dependencyManager
    PreloadEnabled = $false
    AdaptiveTTLEnabled = $false
    DependencyTrackingEnabled = $false
    Get = {
        param([string]$key)
        $value = $this.BaseCache.Get.Invoke($key)
        $hit = $null -ne $value
        
        $this.UsageCollector.RecordAccess.Invoke($key, $hit)
        
        return $value
    }
    Set = {
        param([string]$key, [object]$value)
        $this.BaseCache.Set.Invoke($key, $value)
    }
}

$predictiveCache.Set.Invoke("PredictiveKey", "PredictiveValue")
$value = $predictiveCache.Get.Invoke("PredictiveKey")
Write-Host "  Valeur rÃ©cupÃ©rÃ©e: $value" -ForegroundColor White
$test4Success = $value -eq "PredictiveValue"
Write-Host "  RÃ©sultat: $(if ($test4Success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($test4Success) { "Green" } else { "Red" })

# RÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests" -ForegroundColor Cyan
Write-Host "==============" -ForegroundColor Cyan
$totalTests = 4
$passedTests = @($test1Success, $test2Success, $test3Success, $test4Success).Where({ $_ -eq $true }).Count
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
