<#
.SYNOPSIS
    Module contenant des classes simulées pour les tests du cache prédictif.
.DESCRIPTION
    Ce module définit des classes simulées pour les tests du système de cache prédictif.
    Il inclut des implémentations de CacheManager, UsageCollector, DependencyManager, etc.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 13/04/2025
#>

# Classe CacheManager simulée
class CacheManager {
    [string]$Name
    [string]$CachePath
    [hashtable]$Cache
    [int]$MaxItems
    [int]$DefaultTTL
    [bool]$EnableCompression
    [datetime]$LastCleanup

    CacheManager([string]$name, [string]$cachePath) {
        $this.Name = $name
        $this.CachePath = $cachePath
        $this.Cache = @{}
        $this.MaxItems = 1000
        $this.DefaultTTL = 3600
        $this.EnableCompression = $false
        $this.LastCleanup = Get-Date
    }

    [object] Get([string]$key) {
        if ($this.Cache.ContainsKey($key)) {
            $item = $this.Cache[$key]
            if ($item.Expiry -gt (Get-Date)) {
                return $item.Value
            }
            else {
                $this.Cache.Remove($key)
            }
        }
        return $null
    }

    [void] Set([string]$key, [object]$value, [int]$ttl = 0) {
        if ($ttl -eq 0) {
            $ttl = $this.DefaultTTL
        }

        $this.Cache[$key] = @{
            Value = $value
            Expiry = (Get-Date).AddSeconds($ttl)
        }

        if ($this.Cache.Count -gt $this.MaxItems) {
            $this.Cleanup()
        }
    }

    [bool] Contains([string]$key) {
        if ($this.Cache.ContainsKey($key)) {
            $item = $this.Cache[$key]
            if ($item.Expiry -gt (Get-Date)) {
                return $true
            }
            else {
                $this.Cache.Remove($key)
            }
        }
        return $false
    }

    [void] Remove([string]$key) {
        if ($this.Cache.ContainsKey($key)) {
            $this.Cache.Remove($key)
        }
    }

    [void] Clear() {
        $this.Cache.Clear()
    }

    [void] Cleanup() {
        $now = Get-Date
        $keysToRemove = @()

        foreach ($key in $this.Cache.Keys) {
            if ($this.Cache[$key].Expiry -lt $now) {
                $keysToRemove += $key
            }
        }

        foreach ($key in $keysToRemove) {
            $this.Cache.Remove($key)
        }

        $this.LastCleanup = $now
    }

    [hashtable] GetStatistics() {
        $stats = @{
            TotalItems = $this.Cache.Count
            MaxItems = $this.MaxItems
            DefaultTTL = $this.DefaultTTL
            LastCleanup = $this.LastCleanup
        }
        return $stats
    }
}

# Classe UsageCollector simulée
class UsageCollector {
    [string]$DatabasePath
    [string]$CacheName
    [hashtable]$AccessStats
    [hashtable]$LastAccess
    [datetime]$LastCleanup

    UsageCollector([string]$databasePath, [string]$cacheName) {
        $this.DatabasePath = $databasePath
        $this.CacheName = $cacheName
        $this.AccessStats = @{}
        $this.LastAccess = @{}
        $this.LastCleanup = Get-Date
    }

    [void] RecordAccess([string]$key, [bool]$hit) {
        if (-not $this.AccessStats.ContainsKey($key)) {
            $this.AccessStats[$key] = @{
                Hits = 0
                Misses = 0
                TotalAccesses = 0
                AccessTimes = @()
            }
        }

        $this.AccessStats[$key].TotalAccesses++
        $this.AccessStats[$key].AccessTimes += Get-Date
        
        if ($hit) {
            $this.AccessStats[$key].Hits++
        } else {
            $this.AccessStats[$key].Misses++
        }

        $this.LastAccess[$key] = Get-Date
    }

    [void] RecordSet([string]$key, [object]$value) {
        # Simuler l'enregistrement d'une opération Set
        if (-not $this.AccessStats.ContainsKey($key)) {
            $this.AccessStats[$key] = @{
                Hits = 0
                Misses = 0
                TotalAccesses = 0
                AccessTimes = @()
                Sets = 0
            }
        }

        $this.AccessStats[$key].Sets = ($this.AccessStats[$key].Sets ?? 0) + 1
        $this.LastAccess[$key] = Get-Date
    }

    [void] RecordEviction([string]$key) {
        # Simuler l'enregistrement d'une éviction
        if ($this.AccessStats.ContainsKey($key)) {
            $this.AccessStats[$key].Evicted = $true
            $this.AccessStats[$key].EvictionTime = Get-Date
        }
    }

    [object] GetKeyAccessStats([string]$key) {
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
                LastAccess = $this.LastAccess[$key]
            }
        }
        return $null
    }

    [array] GetMostAccessedKeys([int]$limit = 10, [int]$timeWindowMinutes = 60) {
        $now = Get-Date
        $cutoff = $now.AddMinutes(-$timeWindowMinutes)
        
        $result = @()
        foreach ($key in $this.AccessStats.Keys) {
            $stats = $this.AccessStats[$key]
            $recentAccesses = ($stats.AccessTimes | Where-Object { $_ -gt $cutoff }).Count
            
            if ($recentAccesses -gt 0) {
                $result += [PSCustomObject]@{
                    Key = $key
                    AccessCount = $recentAccesses
                    TotalAccesses = $stats.TotalAccesses
                    Hits = $stats.Hits
                    Misses = $stats.Misses
                    HitRatio = if ($stats.TotalAccesses -gt 0) { $stats.Hits / $stats.TotalAccesses } else { 0 }
                    LastAccess = $this.LastAccess[$key]
                }
            }
        }
        
        return $result | Sort-Object -Property AccessCount -Descending | Select-Object -First $limit
    }

    [array] GetFrequentSequences([int]$limit = 10, [int]$timeWindowMinutes = 60) {
        $now = Get-Date
        $cutoff = $now.AddMinutes(-$timeWindowMinutes)
        
        $sequences = @{}
        
        # Analyser les séquences d'accès
        foreach ($key1 in $this.AccessStats.Keys) {
            foreach ($key2 in $this.AccessStats.Keys) {
                if ($key1 -eq $key2) { continue }
                
                $stats1 = $this.AccessStats[$key1]
                $stats2 = $this.AccessStats[$key2]
                
                $sequenceCount = 0
                $timeDifferences = @()
                
                foreach ($time1 in $stats1.AccessTimes) {
                    if ($time1 -lt $cutoff) { continue }
                    
                    $nextTime = $stats2.AccessTimes | Where-Object { $_ -gt $time1 } | Sort-Object | Select-Object -First 1
                    
                    if ($null -ne $nextTime) {
                        $timeDiff = ($nextTime - $time1).TotalMilliseconds
                        if ($timeDiff -lt 5000) {  # 5 secondes
                            $sequenceCount++
                            $timeDifferences += $timeDiff
                        }
                    }
                }
                
                if ($sequenceCount -gt 0) {
                    $avgTimeDiff = ($timeDifferences | Measure-Object -Average).Average
                    
                    $sequences["$key1->$key2"] = [PSCustomObject]@{
                        FirstKey = $key1
                        SecondKey = $key2
                        SequenceCount = $sequenceCount
                        AvgTimeDifference = $avgTimeDiff
                        LastOccurrence = $stats2.AccessTimes | Where-Object { $_ -gt $cutoff } | Sort-Object -Descending | Select-Object -First 1
                    }
                }
            }
        }
        
        return $sequences.Values | Sort-Object -Property SequenceCount -Descending | Select-Object -First $limit
    }

    [void] Close() {
        # Simuler la fermeture de la connexion à la base de données
    }
}

# Classe DependencyManager simulée
class DependencyManager {
    [CacheManager]$BaseCache
    [UsageCollector]$UsageCollector
    [hashtable]$Dependencies
    [hashtable]$Dependents
    [bool]$AutoDetectDependencies
    [int]$MaxDependenciesPerKey
    [double]$MinDependencyStrength

    DependencyManager([CacheManager]$baseCache, [UsageCollector]$usageCollector) {
        $this.BaseCache = $baseCache
        $this.UsageCollector = $usageCollector
        $this.Dependencies = @{}
        $this.Dependents = @{}
        $this.AutoDetectDependencies = $true
        $this.MaxDependenciesPerKey = 10
        $this.MinDependencyStrength = 0.3
    }

    [void] AddDependency([string]$sourceKey, [string]$targetKey, [double]$strength) {
        if ($sourceKey -eq $targetKey) {
            return
        }
        
        if (-not $this.Dependencies.ContainsKey($sourceKey)) {
            $this.Dependencies[$sourceKey] = @{}
        }
        
        $this.Dependencies[$sourceKey][$targetKey] = $strength
        
        if (-not $this.Dependents.ContainsKey($targetKey)) {
            $this.Dependents[$targetKey] = @{}
        }
        
        $this.Dependents[$targetKey][$sourceKey] = $strength
    }

    [bool] RemoveDependency([string]$sourceKey, [string]$targetKey) {
        if (-not $this.Dependencies.ContainsKey($sourceKey)) {
            return $false
        }
        
        if (-not $this.Dependencies[$sourceKey].ContainsKey($targetKey)) {
            return $false
        }
        
        $this.Dependencies[$sourceKey].Remove($targetKey)
        
        if ($this.Dependents.ContainsKey($targetKey) -and $this.Dependents[$targetKey].ContainsKey($sourceKey)) {
            $this.Dependents[$targetKey].Remove($sourceKey)
        }
        
        return $true
    }

    [hashtable] GetDependencies([string]$key) {
        if ($this.Dependencies.ContainsKey($key)) {
            return $this.Dependencies[$key]
        }
        
        return @{}
    }

    [hashtable] GetDependents([string]$key) {
        if ($this.Dependents.ContainsKey($key)) {
            return $this.Dependents[$key]
        }
        
        return @{}
    }

    [void] DetectDependencies() {
        if (-not $this.AutoDetectDependencies) {
            return
        }
        
        $sequences = $this.UsageCollector.GetFrequentSequences(20, 60)
        
        foreach ($seq in $sequences) {
            $strength = [Math]::Min(1.0, $seq.SequenceCount / 10)
            if ($strength -ge $this.MinDependencyStrength) {
                $this.AddDependency($seq.FirstKey, $seq.SecondKey, $strength)
            }
        }
    }

    [hashtable] GetDependencyStatistics() {
        $totalSources = $this.Dependencies.Count
        $totalTargets = 0
        $totalDependencies = 0
        $strengthSum = 0
        
        foreach ($source in $this.Dependencies.Keys) {
            $totalDependencies += $this.Dependencies[$source].Count
            $totalTargets += ($this.Dependencies[$source].Keys | Select-Object -Unique).Count
            $strengthSum += ($this.Dependencies[$source].Values | Measure-Object -Sum).Sum
        }
        
        $avgStrength = if ($totalDependencies -gt 0) { $strengthSum / $totalDependencies } else { 0 }
        
        return @{
            TotalSources = $totalSources
            TotalTargets = $totalTargets
            TotalDependencies = $totalDependencies
            AverageStrength = $avgStrength
        }
    }
}

# Classe TTLOptimizer simulée
class TTLOptimizer {
    [CacheManager]$BaseCache
    [UsageCollector]$UsageCollector
    [hashtable]$TTLRules
    [int]$MinimumTTL
    [int]$MaximumTTL
    [double]$FrequencyWeight
    [double]$RecencyWeight
    [double]$StabilityWeight
    [datetime]$LastUpdate

    TTLOptimizer([CacheManager]$baseCache, [UsageCollector]$usageCollector) {
        $this.BaseCache = $baseCache
        $this.UsageCollector = $usageCollector
        $this.TTLRules = @{}
        $this.MinimumTTL = 60
        $this.MaximumTTL = 86400
        $this.FrequencyWeight = 0.4
        $this.RecencyWeight = 0.3
        $this.StabilityWeight = 0.3
        $this.LastUpdate = Get-Date
    }

    [int] OptimizeTTL([string]$key, [int]$defaultTTL) {
        $pattern = $this.DetectKeyPattern($key)
        if ($pattern -and $this.TTLRules.ContainsKey($pattern)) {
            return $this.TTLRules[$pattern]
        }
        
        $stats = $this.UsageCollector.GetKeyAccessStats($key)
        if ($null -eq $stats) {
            return $defaultTTL
        }
        
        return $this.CalculateOptimalTTL($stats, $defaultTTL)
    }

    [int] CalculateOptimalTTL([object]$stats, [int]$defaultTTL) {
        $frequencyFactor = $this.CalculateFrequencyFactor($stats.TotalAccesses)
        $recencyFactor = $this.CalculateRecencyFactor($stats.LastAccess)
        $stabilityFactor = $this.CalculateStabilityFactor($stats.HitRatio)
        
        $ttlFactor = ($frequencyFactor * $this.FrequencyWeight) + 
                     ($recencyFactor * $this.RecencyWeight) + 
                     ($stabilityFactor * $this.StabilityWeight)
        
        $optimalTTL = [int]($defaultTTL * $ttlFactor)
        
        # Assurer que le TTL est dans les limites
        $optimalTTL = [Math]::Max($this.MinimumTTL, [Math]::Min($this.MaximumTTL, $optimalTTL))
        
        return $optimalTTL
    }

    [double] CalculateFrequencyFactor([int]$totalAccesses) {
        return [Math]::Min(1.0, $totalAccesses / 100)
    }

    [double] CalculateRecencyFactor([datetime]$lastAccess) {
        $now = Get-Date
        $hoursSinceLastAccess = ($now - $lastAccess).TotalHours
        
        return [Math]::Max(0.1, 1.0 - ($hoursSinceLastAccess / 24))
    }

    [double] CalculateStabilityFactor([double]$hitRatio) {
        return $hitRatio
    }

    [string] DetectKeyPattern([string]$key) {
        if ($key -match '^[a-zA-Z]+\d+$') {
            return 'AlphaNumeric'
        }
        
        if ($key -match '^[a-zA-Z]+:[a-zA-Z0-9]+$') {
            return 'Namespaced'
        }
        
        if ($key -match '^[a-zA-Z]+/[a-zA-Z0-9/]+$') {
            return 'Hierarchical'
        }
        
        return 'Default'
    }

    [hashtable] GetOptimizationStatistics() {
        $ruleCount = $this.TTLRules.Count
        $patternCount = ($this.TTLRules.Keys | Select-Object -Unique).Count
        
        $ttlValues = $this.TTLRules.Values
        $avgTTL = if ($ttlValues.Count -gt 0) { ($ttlValues | Measure-Object -Average).Average } else { 0 }
        
        $minTTL = if ($ttlValues.Count -gt 0) { ($ttlValues | Measure-Object -Minimum).Minimum } else { 0 }
        
        $maxTTL = if ($ttlValues.Count -gt 0) { ($ttlValues | Measure-Object -Maximum).Maximum } else { 0 }
        
        return @{
            RuleCount = $ruleCount
            PatternCount = $patternCount
            AverageTTL = $avgTTL
            MinimumTTL = $minTTL
            MaximumTTL = $maxTTL
            LastUpdate = $this.LastUpdate
        }
    }
}

# Classe PreloadManager simulée
class PreloadManager {
    [CacheManager]$BaseCache
    [UsageCollector]$UsageCollector
    [hashtable]$PreloadGenerators
    [hashtable]$PreloadStatus
    [int]$MaxConcurrentPreloads
    [bool]$ResourceAwarePreloading
    [datetime]$LastPreload

    PreloadManager([CacheManager]$baseCache, [UsageCollector]$usageCollector) {
        $this.BaseCache = $baseCache
        $this.UsageCollector = $usageCollector
        $this.PreloadGenerators = @{}
        $this.PreloadStatus = @{}
        $this.MaxConcurrentPreloads = 5
        $this.ResourceAwarePreloading = $true
        $this.LastPreload = Get-Date
    }

    [void] RegisterPreloadGenerator([string]$keyPattern, [scriptblock]$generator) {
        $this.PreloadGenerators[$keyPattern] = $generator
    }

    [scriptblock] FindPreloadGenerator([string]$key) {
        foreach ($pattern in $this.PreloadGenerators.Keys) {
            if ($key -like $pattern) {
                return $this.PreloadGenerators[$pattern]
            }
        }
        
        return $null
    }

    [bool] PreloadKey([string]$key) {
        $generator = $this.FindPreloadGenerator($key)
        if ($null -eq $generator) {
            return $false
        }
        
        if ($this.BaseCache.Contains($key)) {
            return $true
        }
        
        try {
            $value = & $generator
            $this.BaseCache.Set($key, $value)
            $this.PreloadStatus[$key] = @{
                Success = $true
                Timestamp = Get-Date
            }
            return $true
        }
        catch {
            $this.PreloadStatus[$key] = @{
                Success = $false
                Error = $_.Exception.Message
                Timestamp = Get-Date
            }
            return $false
        }
    }

    [int] PreloadKeys([array]$keys) {
        $successCount = 0
        
        foreach ($key in $keys) {
            if ($this.PreloadKey($key)) {
                $successCount++
            }
        }
        
        return $successCount
    }

    [hashtable] GetPreloadStatistics() {
        $successCount = ($this.PreloadStatus.Values | Where-Object { $_.Success -eq $true }).Count
        $totalCount = $this.PreloadStatus.Count
        $successRate = if ($totalCount -gt 0) { $successCount / $totalCount } else { 0 }
        
        $averageTime = 0
        
        return @{
            TotalPreloads = $totalCount
            SuccessfulPreloads = $successCount
            SuccessRate = $successRate
            AveragePreloadTime = $averageTime
            MaxConcurrentPreloads = $this.MaxConcurrentPreloads
            ResourceAwarePreloading = $this.ResourceAwarePreloading
        }
    }
}

# Classe PredictionEngine simulée
class PredictionEngine {
    [UsageCollector]$UsageCollector
    [DependencyManager]$DependencyManager
    [hashtable]$Predictions
    [int]$MaxPredictions
    [double]$MinConfidence
    [datetime]$LastUpdate

    PredictionEngine([UsageCollector]$usageCollector, [DependencyManager]$dependencyManager) {
        $this.UsageCollector = $usageCollector
        $this.DependencyManager = $dependencyManager
        $this.Predictions = @{}
        $this.MaxPredictions = 100
        $this.MinConfidence = 0.3
        $this.LastUpdate = Get-Date
    }

    [array] PredictNextKeys([string]$currentKey, [int]$limit = 5) {
        $dependencies = $this.DependencyManager.GetDependencies($currentKey)
        
        $predictions = @()
        foreach ($targetKey in $dependencies.Keys) {
            $strength = $dependencies[$targetKey]
            if ($strength -ge $this.MinConfidence) {
                $predictions += [PSCustomObject]@{
                    Key = $targetKey
                    Confidence = $strength
                }
            }
        }
        
        return $predictions | Sort-Object -Property Confidence -Descending | Select-Object -First $limit
    }

    [void] UpdatePredictions() {
        $this.DependencyManager.DetectDependencies()
        $this.LastUpdate = Get-Date
    }

    [hashtable] GetPredictionStatistics() {
        $totalPredictions = $this.Predictions.Count
        $highConfidencePredictions = ($this.Predictions.Values | Where-Object { $_.Confidence -ge 0.7 }).Count
        
        return @{
            TotalPredictions = $totalPredictions
            HighConfidencePredictions = $highConfidencePredictions
            MinConfidence = $this.MinConfidence
            LastUpdate = $this.LastUpdate
        }
    }
}

# Classe PredictiveCache simulée
class PredictiveCache {
    [string]$Name
    [CacheManager]$BaseCache
    [UsageCollector]$UsageCollector
    [DependencyManager]$DependencyManager
    [TTLOptimizer]$TTLOptimizer
    [PreloadManager]$PreloadManager
    [PredictionEngine]$PredictionEngine
    [bool]$AdaptiveTTLEnabled
    [bool]$PreloadEnabled
    [bool]$DependencyTrackingEnabled

    PredictiveCache([string]$name, [string]$cachePath, [string]$databasePath) {
        $this.Name = $name
        $this.BaseCache = [CacheManager]::new($name, $cachePath)
        $this.UsageCollector = [UsageCollector]::new($databasePath, $name)
        $this.DependencyManager = [DependencyManager]::new($this.BaseCache, $this.UsageCollector)
        $this.TTLOptimizer = [TTLOptimizer]::new($this.BaseCache, $this.UsageCollector)
        $this.PreloadManager = [PreloadManager]::new($this.BaseCache, $this.UsageCollector)
        $this.PredictionEngine = [PredictionEngine]::new($this.UsageCollector, $this.DependencyManager)
        $this.AdaptiveTTLEnabled = $true
        $this.PreloadEnabled = $true
        $this.DependencyTrackingEnabled = $true
    }

    [object] Get([string]$key) {
        $value = $this.BaseCache.Get($key)
        $hit = $null -ne $value
        
        $this.UsageCollector.RecordAccess($key, $hit)
        
        if ($hit -and $this.DependencyTrackingEnabled) {
            $this.ProcessDependencies($key)
        }
        
        return $value
    }

    [void] Set([string]$key, [object]$value, [int]$ttl = 0) {
        if ($this.AdaptiveTTLEnabled) {
            $ttl = $this.TTLOptimizer.OptimizeTTL($key, $ttl -eq 0 ? $this.BaseCache.DefaultTTL : $ttl)
        }
        
        $this.BaseCache.Set($key, $value, $ttl)
        $this.UsageCollector.RecordSet($key, $value)
    }

    [void] Remove([string]$key) {
        $this.BaseCache.Remove($key)
        $this.UsageCollector.RecordEviction($key)
    }

    [bool] Contains([string]$key) {
        $contains = $this.BaseCache.Contains($key)
        $this.UsageCollector.RecordAccess($key, $contains)
        return $contains
    }

    [void] ProcessDependencies([string]$key) {
        if (-not $this.DependencyTrackingEnabled) {
            return
        }
        
        $dependencies = $this.DependencyManager.GetDependencies($key)
        
        if ($this.PreloadEnabled) {
            foreach ($targetKey in $dependencies.Keys) {
                $strength = $dependencies[$targetKey]
                if ($strength -gt 0.7 -and -not $this.BaseCache.Contains($targetKey)) {
                    $this.PreloadManager.PreloadKey($targetKey)
                }
            }
        }
    }

    [void] Optimize() {
        if ($this.DependencyTrackingEnabled) {
            $this.DependencyManager.DetectDependencies()
        }
        
        if ($this.PreloadEnabled) {
            $predictions = $this.UsageCollector.GetMostAccessedKeys(10, 30)
            $keysToPreload = $predictions | Where-Object { $_.HitRatio -gt 0.7 } | Select-Object -ExpandProperty Key
            
            $this.PreloadManager.PreloadKeys($keysToPreload)
        }
    }

    [hashtable] GetStatistics() {
        $cacheStats = $this.BaseCache.GetStatistics()
        $usageStats = @{
            TotalKeys = $this.UsageCollector.AccessStats.Count
        }
        $dependencyStats = $this.DependencyManager.GetDependencyStatistics()
        $ttlStats = $this.TTLOptimizer.GetOptimizationStatistics()
        $preloadStats = $this.PreloadManager.GetPreloadStatistics()
        
        return @{
            Name = $this.Name
            CacheStats = $cacheStats
            UsageStats = $usageStats
            DependencyStats = $dependencyStats
            TTLStats = $ttlStats
            PreloadStats = $preloadStats
            AdaptiveTTLEnabled = $this.AdaptiveTTLEnabled
            PreloadEnabled = $this.PreloadEnabled
            DependencyTrackingEnabled = $this.DependencyTrackingEnabled
        }
    }
}

# Fonctions pour créer des instances des classes
function New-MockCacheManager {
    param(
        [string]$Name,
        [string]$CachePath
    )
    
    return [CacheManager]::new($Name, $CachePath)
}

function New-MockUsageCollector {
    param(
        [string]$DatabasePath,
        [string]$CacheName
    )
    
    return [UsageCollector]::new($DatabasePath, $CacheName)
}

function New-MockDependencyManager {
    param(
        [CacheManager]$BaseCache,
        [UsageCollector]$UsageCollector
    )
    
    return [DependencyManager]::new($BaseCache, $UsageCollector)
}

function New-MockTTLOptimizer {
    param(
        [CacheManager]$BaseCache,
        [UsageCollector]$UsageCollector
    )
    
    return [TTLOptimizer]::new($BaseCache, $UsageCollector)
}

function New-MockPreloadManager {
    param(
        [CacheManager]$BaseCache,
        [UsageCollector]$UsageCollector
    )
    
    return [PreloadManager]::new($BaseCache, $UsageCollector)
}

function New-MockPredictionEngine {
    param(
        [UsageCollector]$UsageCollector,
        [DependencyManager]$DependencyManager
    )
    
    return [PredictionEngine]::new($UsageCollector, $DependencyManager)
}

function New-MockPredictiveCache {
    param(
        [string]$Name,
        [string]$CachePath,
        [string]$DatabasePath
    )
    
    return [PredictiveCache]::new($Name, $CachePath, $DatabasePath)
}

# Exporter les classes et fonctions
Export-ModuleMember -Function New-MockCacheManager, New-MockUsageCollector, New-MockDependencyManager, 
                             New-MockTTLOptimizer, New-MockPreloadManager, New-MockPredictionEngine, 
                             New-MockPredictiveCache
