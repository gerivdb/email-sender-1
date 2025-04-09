#Requires -Version 5.1

<#
.SYNOPSIS
    Optimized cache management module for PowerShell 5.1+
.DESCRIPTION
    Provides advanced caching features including thread-safe in-memory caching,
    optional persistent disk caching, configurable eviction policies (LRU/LFU),
    TTL management, tag-based removal, and hit/miss statistics.
    Uses CliXml for serialization to preserve PowerShell object fidelity.
.NOTES
    Version: 2.0
    Author: Augment Agent (Improved by AI)
    Date: 2023-10-27
    Compatibility: PowerShell 5.1 and higher

    Changes in v2.0:
    - Switched serialization to Export/Import-CliXml for better object fidelity.
    - Added LFU eviction policy option.
    - Added option to extend TTL on cache hits.
    - Made disk cache loading lazy (on miss) instead of loading all at startup.
    - Renamed CleanCache -> EvictItems, ClearExpired for clarity.
    - Removed unreliable size estimation.
    - Added Test-PSCacheItem function.
    - Enhanced error handling and robustness, especially for disk operations.
    - Improved documentation and added more configuration options.
#>

#region Classes (Internal Implementation Detail)

# Class to store cache items with metadata
class CacheItem {
    [object]$Value
    [datetime]$Created
    [datetime]$LastAccess
    [datetime]$Expiration
    [long]$AccessCount # Changed to long for potentially very high counts
    [string[]]$Tags

    CacheItem([object]$itemValue, [int]$ttlSeconds) {
        $this.Value = $itemValue
        $this.Created = Get-Date
        $this.LastAccess = $this.Created
        if ($ttlSeconds -gt 0) {
            $this.Expiration = $this.Created.AddSeconds($ttlSeconds)
        } else {
            $this.Expiration = [datetime]::MaxValue # No expiration if TTL <= 0
        }
        $this.AccessCount = 0
        $this.Tags = @()
    }

    [bool] IsExpired() {
        return (Get-Date) -gt $this.Expiration
    }

    [void] UpdateAccess([bool]$extendTtl, [int]$ttlSeconds) {
        $this.LastAccess = Get-Date
        $this.AccessCount++
        if ($extendTtl -and $ttlSeconds -gt 0) {
            $this.Expiration = $this.LastAccess.AddSeconds($ttlSeconds)
        }
        elseif($extendTtl -and $this.Expiration -ne [datetime]::MaxValue) {
             # Extend with original TTL if no specific TTL provided for extension
             $originalTtlDuration = $this.Expiration - $this.Created
             $this.Expiration = $this.LastAccess + $originalTtlDuration
        }
    }
}

# Main cache management class
class CacheManager {
    #region Properties

    # Configuration
    [string]$Name
    [string]$CachePath # Full path to the disk cache directory
    [int]$MaxMemoryItems # Max items in the memory cache
    [int]$DefaultTTLSeconds
    [bool]$EnableDiskCache
    [string]$EvictionPolicy # 'LRU' or 'LFU'
    [double]$EvictionPercentage # Percentage (0.0 to 1.0) of items to remove during eviction
    [bool]$ExtendTtlOnAccess

    # State
    [System.Collections.Concurrent.ConcurrentDictionary[string, CacheItem]]$MemoryCache
    [System.Object]$DiskLock # Simple lock object for disk operations if needed (though file operations have some atomicity)

    # Statistics
    [long]$Hits # Use long for high counts
    [long]$Misses
    [long]$DiskLoads
    [datetime]$LastEvictionTime

    #endregion

    #region Constructor

    CacheManager([string]$cacheName, [string]$diskCachePath, [int]$maxMemoryCacheItems, [int]$defaultTtl, [bool]$diskCacheEnabled, [string]$policy, [double]$percentage, [bool]$extendOnAccess) {
        # Validation
        if ([string]::IsNullOrWhiteSpace($cacheName)) { throw "Cache name cannot be empty." }
        if ($maxMemoryCacheItems -lt 1) { throw "MaxMemoryItems must be at least 1." }
        if ($defaultTtl -lt 0) { Write-Warning "DefaultTTLSeconds is negative, treating as infinite TTL." }
        if ($policy -notin @('LRU', 'LFU')) { throw "Invalid EvictionPolicy '$policy'. Must be 'LRU' or 'LFU'." }
        if ($percentage -lt 0.01 -or $percentage -gt 1.0) { throw "EvictionPercentage must be between 0.01 (1%) and 1.0 (100%)." }

        $this.Name = $cacheName
        $this.CachePath = $diskCachePath # Assume caller provides a valid, absolute path
        $this.MaxMemoryItems = $maxMemoryCacheItems
        $this.DefaultTTLSeconds = $defaultTtl
        $this.EnableDiskCache = $diskCacheEnabled
        $this.EvictionPolicy = $policy
        $this.EvictionPercentage = $percentage
        $this.ExtendTtlOnAccess = $extendOnAccess

        $this.MemoryCache = [System.Collections.Concurrent.ConcurrentDictionary[string, CacheItem]]::new([System.StringComparer]::OrdinalIgnoreCase) # Case-insensitive keys
        $this.DiskLock = [System.Object]::new()
        $this.Hits = 0
        $this.Misses = 0
        $this.DiskLoads = 0
        $this.LastEvictionTime = [datetime]::MinValue

        # Create the disk cache directory if needed
        if ($this.EnableDiskCache -and -not (Test-Path -Path $this.CachePath -PathType Container)) {
            try {
                New-Item -Path $this.CachePath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Write-Verbose "[$($this.Name)] Created disk cache directory: $($this.CachePath)"
            }
            catch {
                Write-Error "[$($this.Name)] Failed to create disk cache directory '$($this.CachePath)'. Error: $($_.Exception.Message)"
                $this.EnableDiskCache = $false # Disable disk cache if directory creation fails
                Write-Warning "[$($this.Name)] Disk cache has been disabled due to directory creation failure."
            }
        }
    }

    #endregion

    #region Core Methods (Get, Set, Remove)

    [object] Get([string]$key) {
        if ([string]::IsNullOrWhiteSpace($key)) { return $null }

        $item = $null
        $foundInMemory = $this.MemoryCache.TryGetValue($key, [ref]$item)

        if ($foundInMemory) {
            if ($item.IsExpired()) {
                Write-Verbose "[$($this.Name)] Memory item '$key' expired. Removing."
                $this.Remove($key) # Remove expired item from memory and disk
                $this.Misses++
                return $null
            }
            else {
                Write-Verbose "[$($this.Name)] Memory hit for '$key'."
                $item.UpdateAccess($this.ExtendTtlOnAccess, $this.DefaultTTLSeconds)
                $this.Hits++
                # Optionally update disk version with new access time? Maybe too much I/O. Let's skip for now.
                return $item.Value
            }
        }

        # Not in memory, try disk if enabled
        if ($this.EnableDiskCache) {
            Write-Verbose "[$($this.Name)] Memory miss for '$key'. Checking disk cache."
            $diskItem = $this.LoadFromDisk($key)
            if ($null -ne $diskItem) {
                $this.DiskLoads++
                if ($diskItem.IsExpired()) {
                    Write-Verbose "[$($this.Name)] Disk item '$key' expired. Removing."
                    $this.RemoveFromDisk($key) # Only remove from disk, not in memory
                }
                else {
                    Write-Verbose "[$($this.Name)] Disk hit for '$key'. Loading into memory."
                    $diskItem.UpdateAccess($this.ExtendTtlOnAccess, $this.DefaultTTLSeconds) # Update access stats *before* adding to memory
                    # Add to memory cache (potentially triggering eviction)
                    $this.AddToMemoryCache($key, $diskItem)
                    $this.Hits++ # Count disk load as a hit
                    return $diskItem.Value
                }
            }
        }

        # Not found anywhere
        Write-Verbose "[$($this.Name)] Cache miss for '$key'."
        $this.Misses++
        return $null
    }

    [bool] ContainsKey([string]$key) {
         if ([string]::IsNullOrWhiteSpace($key)) { return $false }

         if ($this.MemoryCache.ContainsKey($key)) {
             $item = $this.MemoryCache[$key]
             if(-not $item.IsExpired()) {
                 return $true
             }
         }
         # Optionally check disk, but might be slow. Let's keep it simple: checks *valid* items in memory primarily.
         # For a strict "exists anywhere" check, would need to modify Get or add another method.
         # Let's refine: check memory (valid), then check disk *existence* (without loading fully)
         if ($this.EnableDiskCache) {
             $persistPath = $this.GetDiskPath($key)
             if (Test-Path -Path $persistPath -PathType Leaf) {
                 # We know it exists on disk, but don't know if it's expired without loading.
                 # For simplicity, let's say ContainsKey == true if it exists in memory (valid) or on disk.
                 return $true
             }
         }

         return $false
    }

    [void] Set([string]$key, [object]$value, $ttlSeconds = $null, [string[]]$tags = @()) {
        if ([string]::IsNullOrWhiteSpace($key)) { throw "Cache key cannot be empty." }
        # Allow setting null values in cache
        # if ($null -eq $value) { Write-Warning "[$($this.Name)] Setting null value for key '$key'."; # return }

        $effectiveTtl = if ($null -ne $ttlSeconds) { $ttlSeconds } else { $this.DefaultTTLSeconds }

        $item = [CacheItem]::new($value, $effectiveTtl)
        $item.Tags = $tags

        Write-Verbose "[$($this.Name)] Setting cache item '$key' with TTL $effectiveTtl seconds."
        $this.AddToMemoryCache($key, $item)

        if ($this.EnableDiskCache) {
            $this.SaveToDisk($key, $item)
        }
    }

     # Adds to memory, handles eviction if needed
    [void] AddToMemoryCache([string]$key, [CacheItem]$item) {
        # Check if eviction is needed *before* adding the new item if the cache is already full
        if ($this.MemoryCache.Count -ge $this.MaxMemoryItems -and -not $this.MemoryCache.ContainsKey($key)) {
            Write-Verbose "[$($this.Name)] Memory cache full ($($this.MemoryCache.Count) items). Triggering eviction."
            $this.EvictItems()
        }

        $this.MemoryCache[$key] = $item # Add or update
    }

    [void] Remove([string]$key) {
        if ([string]::IsNullOrWhiteSpace($key)) { return }

        Write-Verbose "[$($this.Name)] Removing item '$key' from memory and disk."
        $removedItem = $null
        $this.MemoryCache.TryRemove($key, [ref]$removedItem) | Out-Null

        if ($this.EnableDiskCache) {
            $this.RemoveFromDisk($key)
        }
    }

    [void] RemoveByTag([string]$tag) {
        if ([string]::IsNullOrWhiteSpace($tag)) { return }

        # Iterate safely on a snapshot of keys
        $keysToRemove = @($this.MemoryCache.Keys) | Where-Object {
            $item = $null
            if ($this.MemoryCache.TryGetValue($_, [ref]$item)) {
                return $item.Tags -contains $tag
            }
            return $false
        }

        Write-Verbose "[$($this.Name)] Removing $($keysToRemove.Count) items with tag '$tag'."
        foreach ($key in $keysToRemove) {
            $this.Remove($key) # Will also remove from disk if enabled
        }
    }

    [void] RemoveByPattern([string]$pattern) {
         if ([string]::IsNullOrWhiteSpace($pattern)) { return }

         # Iterate safely on a snapshot of keys
         $keysToRemove = @($this.MemoryCache.Keys) | Where-Object { $_ -match $pattern }

         Write-Verbose "[$($this.Name)] Removing $($keysToRemove.Count) items matching pattern '$pattern'."
         foreach ($key in $keysToRemove) {
             $this.Remove($key) # Will also remove from disk if enabled
         }
    }

    #endregion

    #region Cache Maintenance

    [void] EvictItems() {
        $countToRemove = [math]::Ceiling($this.MaxMemoryItems * $this.EvictionPercentage)
        if ($countToRemove -le 0) { return } # Should not happen with validation, but safety first

        Write-Verbose "[$($this.Name)] Evicting approximately $countToRemove items based on $($this.EvictionPolicy) policy."

        # Get a snapshot of items for sorting
        # Need to handle potential errors if items are removed while enumerating
        $itemsSnapshot = @{}
        try {
             foreach($kvp in $this.MemoryCache.GetEnumerator()){
                 $itemsSnapshot[$kvp.Key] = $kvp.Value
             }
        } catch {
             Write-Warning "[$($this.Name)] Error enumerating cache during eviction. Retrying snapshot."
             Start-Sleep -Milliseconds 50 # Small delay before retry
             $itemsSnapshot = @{}
             foreach($kvp in $this.MemoryCache.GetEnumerator()){ $itemsSnapshot[$kvp.Key] = $kvp.Value }
        }


        if ($itemsSnapshot.Count -eq 0) { return }

        $sortedItems = switch ($this.EvictionPolicy) {
            'LRU' { $itemsSnapshot.GetEnumerator() | Sort-Object { $_.Value.LastAccess } }
            'LFU' { $itemsSnapshot.GetEnumerator() | Sort-Object { $_.Value.AccessCount } }
            default { $itemsSnapshot.GetEnumerator() | Sort-Object { $_.Value.LastAccess } } # Default to LRU
        }

        $itemsToRemove = $sortedItems | Select-Object -First $countToRemove

        $removedCount = 0
        foreach ($itemToRemove in $itemsToRemove) {
             # Check if the item still exists before trying to remove
             if($this.MemoryCache.ContainsKey($itemToRemove.Key)) {
                 $this.Remove($itemToRemove.Key) # Removes from memory and disk
                 $removedCount++
             }
        }

        Write-Verbose "[$($this.Name)] Evicted $removedCount items."
        $this.LastEvictionTime = Get-Date
    }

    [void] ClearExpired() {
        Write-Verbose "[$($this.Name)] Clearing expired items."
        # Iterate safely on a snapshot of keys
        $keysToCheck = @($this.MemoryCache.Keys)
        $expiredKeys = @()

        foreach($key in $keysToCheck) {
             $item = $null
             if ($this.MemoryCache.TryGetValue($key, [ref]$item)) {
                 if ($item.IsExpired()) {
                    $expiredKeys += $key
                 }
             }
        }

        Write-Verbose "[$($this.Name)] Found $($expiredKeys.Count) expired items to remove."
        foreach ($key in $expiredKeys) {
            $this.Remove($key) # Removes from memory and disk
        }

        # Optionally, could also scan disk cache for expired files not in memory, but could be slow.
    }

    [void] Clear() {
        Write-Verbose "[$($this.Name)] Clearing all items from memory and disk cache."
        $this.MemoryCache.Clear()

        if ($this.EnableDiskCache -and (Test-Path -Path $this.CachePath -PathType Container)) {
            try {
                # Remove files, but keep the directory structure
                Get-ChildItem -Path $this.CachePath -Filter "*.xml" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                Write-Verbose "[$($this.Name)] Cleared disk cache files in $($this.CachePath)."
            }
            catch {
                 Write-Warning "[$($this.Name)] Error while clearing disk cache files in '$($this.CachePath)'. Error: $($_.Exception.Message)"
            }
        }

        # Reset statistics
        $this.Hits = 0
        $this.Misses = 0
        $this.DiskLoads = 0
        Write-Verbose "[$($this.Name)] Cache cleared and statistics reset."
    }

    #endregion

    #region Disk Persistence

    [string] GetDiskPath([string]$key) {
        # Sanitize key to make it safe for file names
        $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() -join ''
        $safeKey = $key -replace "[$invalidChars]", '_' # Replace invalid chars with underscore
        # Consider hashing long keys if file name length limits are a concern
        # $maxLength = 200 # Example limit
        # if ($safeKey.Length -gt $maxLength) {
        #    $hash = Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($key))) -Algorithm SHA256
        #    $safeKey = $hash.Hash
        # }
        return Join-Path -Path $this.CachePath -ChildPath "$safeKey.xml" # Use .xml for CliXml
    }

    [void] SaveToDisk([string]$key, [CacheItem]$item) {
        if (-not $this.EnableDiskCache) { return }

        $persistPath = $this.GetDiskPath($key)
        Write-Verbose "[$($this.Name)] Saving item '$key' to disk: $persistPath"

        try {
            # Serialize using CliXml for better PowerShell object fidelity
            Export-Clixml -Path $persistPath -InputObject $item -Depth 10 -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "[$($this.Name)] Failed to save cache item '$key' to disk '$persistPath'. Error: $($_.Exception.Message)"
        }
    }

    [CacheItem] LoadFromDisk([string]$key) {
        if (-not $this.EnableDiskCache) { return $null }

        $persistPath = $this.GetDiskPath($key)

        if (-not (Test-Path -Path $persistPath -PathType Leaf)) {
             Write-Verbose "[$($this.Name)] Disk item for '$key' not found at '$persistPath'."
             return $null
        }

        Write-Verbose "[$($this.Name)] Attempting to load item '$key' from disk: $persistPath"
        try {
            # Deserialize using CliXml
            $loadedObject = Import-Clixml -Path $persistPath -ErrorAction Stop

            if ($loadedObject -is [CacheItem]) {
                 # Basic validation after load
                 if($null -eq $loadedObject.Created -or $null -eq $loadedObject.Expiration) {
                      throw "Loaded object is missing essential date properties."
                 }
                 return $loadedObject
            } else {
                 Write-Warning "[$($this.Name)] Object loaded from '$persistPath' for key '$key' is not a CacheItem. Type: $($loadedObject.GetType().FullName)"
                 # Corrupted file or wrong type - remove it
                 Remove-Item -Path $persistPath -Force -ErrorAction SilentlyContinue
                 return $null
            }
        }
        catch {
            Write-Warning "[$($this.Name)] Failed to load or deserialize cache item '$key' from disk '$persistPath'. It might be corrupted. Error: $($_.Exception.Message)"
            # Remove potentially corrupted file
            Remove-Item -Path $persistPath -Force -ErrorAction SilentlyContinue
            return $null
        }
    }

    [void] RemoveFromDisk([string]$key) {
        if (-not $this.EnableDiskCache) { return }

        $persistPath = $this.GetDiskPath($key)

        if (Test-Path -Path $persistPath -PathType Leaf) {
            Write-Verbose "[$($this.Name)] Removing disk item for '$key' at '$persistPath'."
            try {
                Remove-Item -Path $persistPath -Force -ErrorAction Stop
            }
            catch {
                 Write-Warning "[$($this.Name)] Failed to remove disk cache file '$persistPath'. Error: $($_.Exception.Message)"
            }
        }
    }

    #endregion

    #region Statistics

    [hashtable] GetStatistics() {
        $memoryCount = $this.MemoryCache.Count
        $expiredCount = 0
        # Avoid iterating if count is 0
        if ($memoryCount -gt 0) {
            try {
                # Need to handle potential errors if collection is modified during enumeration
                $itemsSnapshot = @($this.MemoryCache.Values)
                $expiredCount = ($itemsSnapshot | Where-Object { $_.IsExpired() } | Measure-Object).Count
            } catch {
                 Write-Warning "[$($this.Name)] Error enumerating cache for statistics. Expired count might be inaccurate."
            }
        }

        $totalAccesses = $this.Hits + $this.Misses
        $hitRatio = if ($totalAccesses -gt 0) { [math]::Round($this.Hits / $totalAccesses, 4) } else { 0 }

        return @{
            Name = $this.Name
            MemoryItemCount = $memoryCount
            MaxMemoryItems = $this.MaxMemoryItems
            MemoryExpiredCount = $expiredCount # Expired items currently in memory
            MemoryUtilization = if($this.MaxMemoryItems -gt 0) { [math]::Round($memoryCount / $this.MaxMemoryItems, 2) } else { 0 }
            Hits = $this.Hits
            Misses = $this.Misses
            TotalAccesses = $totalAccesses
            HitRatio = $hitRatio
            DiskCacheEnabled = $this.EnableDiskCache
            DiskCachePath = if($this.EnableDiskCache) { $this.CachePath } else { $null }
            DiskItemsLoaded = $this.DiskLoads # How many times items were successfully loaded from disk
            EvictionPolicy = $this.EvictionPolicy
            EvictionPercentage = $this.EvictionPercentage
            ExtendTtlOnAccess = $this.ExtendTtlOnAccess
            LastEvictionTime = if($this.LastEvictionTime -eq [datetime]::MinValue) { $null } else { $this.LastEvictionTime }
        }
    }

    #endregion
}

#endregion

#region Public Functions

<#
.SYNOPSIS
    Creates a new cache manager instance.
.DESCRIPTION
    Initializes and returns a new CacheManager object with specified configuration.
    Uses ConcurrentDictionary for thread-safe memory operations and optional
    persistent disk cache using CliXml serialization.
.PARAMETER Name
    A unique name for this cache instance. Used in logging and potentially disk path generation.
.PARAMETER CachePath
    The full path to the directory for storing disk cache files.
    Defaults to a subdirectory within $env:TEMP based on the cache Name.
    Must be an absolute path. The directory will be created if it doesn't exist.
.PARAMETER MaxMemoryItems
    The maximum number of items to store in the memory cache. When exceeded,
    eviction policy is triggered. Default is 1000.
.PARAMETER DefaultTTLSeconds
    Default Time-To-Live for cache items in seconds. Use 0 or negative for infinite TTL.
    Default is 3600 (1 hour). Can be overridden per item on Set.
.PARAMETER EnableDiskCache
    Set to $true to enable storing cache items on disk as a fallback/persistent layer.
    Default is $true. Disk cache path is specified by -CachePath.
.PARAMETER EvictionPolicy
    The policy used to evict items from memory when MaxMemoryItems is reached.
    Valid values: 'LRU' (Least Recently Used), 'LFU' (Least Frequently Used).
    Default is 'LRU'.
.PARAMETER EvictionPercentage
    The percentage (between 0.01 and 1.0) of items to remove when eviction occurs.
    Default is 0.2 (20%).
.PARAMETER ExtendTtlOnAccess
    Set to $true to reset an item's TTL expiration timer each time it is accessed via Get.
    Default is $false.
.EXAMPLE
    $scriptCache = New-PSCache -Name "ScriptAnalysis" -MaxMemoryItems 500 -DefaultTTLSeconds 7200
    # Creates a cache named ScriptAnalysis, holds 500 items in memory, default 2hr TTL, disk cache enabled in %TEMP%.
.EXAMPLE
    $apiCache = New-PSCache -Name "ExternalAPI" -MaxMemoryItems 100 -DefaultTTLSeconds 300 -EvictionPolicy LFU -CachePath "C:\Cache\API" -ExtendTtlOnAccess:$true
    # Creates an LFU cache for API results, 100 items, 5min TTL extended on access, custom disk path.
.OUTPUTS
    CacheManager
.NOTES
    Requires PowerShell 5.1 or higher for class support.
    Disk cache path should ideally be on a fast, local drive.
    Ensure the process running PowerShell has write permissions to the CachePath.
#>
function New-PSCache {
    [CmdletBinding()]
    [OutputType([CacheManager])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Name = "DefaultCache_$(Get-Random)", # Add random suffix to avoid collisions with default name

        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path (Split-Path $_ -Parent) -PathType Container })] # Validate parent exists
        [string]$CachePath = (Join-Path -Path $env:TEMP -ChildPath "PSCacheManager\$Name"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$MaxMemoryItems = 1000,

        [Parameter(Mandatory = $false)]
        [int]$DefaultTTLSeconds = 3600, # 1 hour

        [Parameter(Mandatory = $false)]
        [bool]$EnableDiskCache = $true,

        [Parameter(Mandatory = $false)]
        [ValidateSet('LRU', 'LFU')]
        [string]$EvictionPolicy = 'LRU',

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.01, 1.0)]
        [double]$EvictionPercentage = 0.2,

        [Parameter(Mandatory = $false)]
        [bool]$ExtendTtlOnAccess = $false
    )

    try {
        Write-Verbose "[New-PSCache] Initializing cache '$Name'. Path: '$CachePath', MaxItems: $MaxMemoryItems, TTL: $DefaultTTLSeconds, Disk: $EnableDiskCache, Policy: $EvictionPolicy, Evict%: $EvictionPercentage, ExtendTTL: $ExtendTtlOnAccess"
        # Ensure CachePath is absolute before passing to constructor
        if(-not [System.IO.Path]::IsPathRooted($CachePath)) {
             $CachePath = Join-Path -Path $PWD -ChildPath $CachePath # Make relative path absolute
             Write-Verbose "[New-PSCache] Resolved relative CachePath to '$CachePath'"
        }
        $manager = [CacheManager]::new($Name, $CachePath, $MaxMemoryItems, $DefaultTTLSeconds, $EnableDiskCache, $EvictionPolicy, $EvictionPercentage, $ExtendTtlOnAccess)
        return $manager
    }
    catch {
        Write-Error "[New-PSCache] Failed to create cache '$Name'. Error: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Retrieves an item from the specified cache.
.DESCRIPTION
    Gets an item value using its key. Checks memory first, then disk (if enabled).
    If the item is not found or expired, and a -GenerateValue scriptblock is provided,
    that scriptblock is executed. The result is then stored in the cache before being returned.
.PARAMETER Cache
    The CacheManager instance to operate on.
.PARAMETER Key
    The unique key identifying the cache item. Case-insensitive.
.PARAMETER GenerateValue
    A scriptblock used to generate the value if the key is not found in the cache or is expired.
    The scriptblock should output the value to be cached.
.PARAMETER TTLSeconds
    Specifies the Time-To-Live (in seconds) for the item *if* it is generated using -GenerateValue.
    Overrides the cache's default TTL for this specific item. Use 0 or negative for infinite TTL.
.PARAMETER Tags
    An array of string tags to associate with the item *if* it is generated.
.EXAMPLE
    $data = Get-PSCacheItem -Cache $myCache -Key "UserData:123"
.EXAMPLE
    $config = Get-PSCacheItem -Cache $appCache -Key "AppConfig" -GenerateValue {
        Write-Host "Generating expensive config..."
        Import-Json -Path "C:\config\app.json" # Simulate expensive operation
    } -TTLSeconds 86400 -Tags "Configuration", "Critical"
    # Tries to get 'AppConfig', if not found, runs the scriptblock, caches result for 1 day with tags.
.OUTPUTS
    Object The cached value, the newly generated value, or $null if not found and no generator provided.
#>
function Get-PSCacheItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [CacheManager]$Cache,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [scriptblock]$GenerateValue,

        [Parameter(Mandatory = $false)]
        [int]$TTLSeconds = $null, # Use null to signal using cache default unless overridden

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @()
    )

    $value = $Cache.Get($Key)

    if ($null -eq $value -and $null -ne $GenerateValue) {
        Write-Verbose "[$($Cache.Name)] Cache miss/expired for '$Key'. Executing GenerateValue scriptblock."
        try {
            $generatedValue = & $GenerateValue
            # Allow caching null results if generator explicitly returns $null
            # if ($null -ne $generatedValue) {
            Write-Verbose "[$($Cache.Name)] Value generated for '$Key'. Caching now."
            $Cache.Set($Key, $generatedValue, $TTLSeconds, $Tags)
            $value = $generatedValue # Return the newly generated value
            # } else {
            #    Write-Verbose "[$($Cache.Name)] GenerateValue returned null for '$Key'. Not caching."
            # }
        }
        catch {
            Write-Error "[$($Cache.Name)] Error executing GenerateValue scriptblock for key '$Key'. Error: $($_.Exception.Message)"
            # Do not cache on error, return $null or rethrow? Let's return $null.
            $value = $null
        }
    }

    return $value
}

<#
.SYNOPSIS
    Adds or updates an item in the specified cache.
.DESCRIPTION
    Stores a value in the cache associated with a specific key.
    If the key already exists, its value and metadata (TTL, tags) are overwritten.
    Triggers eviction if the memory cache limit is reached. Persists to disk if enabled.
.PARAMETER Cache
    The CacheManager instance to operate on.
.PARAMETER Key
    The unique key for the cache item. Case-insensitive.
.PARAMETER Value
    The object/value to store in the cache. Can be any PowerShell object serializable by CliXml.
.PARAMETER TTLSeconds
    Specifies the Time-To-Live (in seconds) for this item.
    Overrides the cache's default TTL. Use 0 or negative for infinite TTL.
    If not specified ($null), uses the cache's DefaultTTLSeconds.
.PARAMETER Tags
    An array of string tags to associate with the item for later retrieval or removal.
.EXAMPLE
    $userObj = @{ Name = "GlaDOS"; ID = 77 }
    Set-PSCacheItem -Cache $sessionCache -Key "User:77" -Value $userObj -TTLSeconds 600 -Tags "UserSession"
.EXAMPLE
    Set-PSCacheItem -Cache $appCache -Key "LastUpdateTime" -Value (Get-Date) # Uses default TTL
.OUTPUTS
    None
#>
function Set-PSCacheItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [CacheManager]$Cache,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory = $true, AllowNull = $true)] # Explicitly allow caching $null
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [int]$TTLSeconds = $null, # Use null to signal using cache default

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @()
    )

    try {
        $Cache.Set($Key, $Value, $TTLSeconds, $Tags)
    }
    catch {
         Write-Error "[$($Cache.Name)] Failed to set cache item '$Key'. Error: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Removes one or more items from the cache.
.DESCRIPTION
    Removes items from both memory and disk cache (if enabled).
    Can remove by specific key, by items associated with a tag, or by keys matching a regex pattern.
.PARAMETER Cache
    The CacheManager instance to operate on.
.PARAMETER Key
    The specific key of the item to remove.
.PARAMETER Tag
    Removes all items associated with this specific tag.
.PARAMETER Pattern
    Removes all items whose keys match the provided PowerShell regex pattern.
.EXAMPLE
    Remove-PSCacheItem -Cache $myCache -Key "ObsoleteData"
.EXAMPLE
    Remove-PSCacheItem -Cache $myCache -Tag "UserData" # Removes all items tagged 'UserData'
.EXAMPLE
    Remove-PSCacheItem -Cache $myCache -Pattern "^Session:\d+$" # Removes items with keys like Session:123
.OUTPUTS
    None
#>
function Remove-PSCacheItem {
    [CmdletBinding(DefaultParameterSetName = "ByKey", SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [CacheManager]$Cache,

        [Parameter(Mandatory = $true, ParameterSetName = "ByKey")]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory = $true, ParameterSetName = "ByTag")]
        [ValidateNotNullOrEmpty()]
        [string]$Tag,

        [Parameter(Mandatory = $true, ParameterSetName = "ByPattern")]
        [ValidateNotNullOrEmpty()]
        [string]$Pattern
    )

    switch ($PSCmdlet.ParameterSetName) {
        "ByKey" {
            if ($PSCmdlet.ShouldProcess($Key, "Remove cache item")) {
                 $Cache.Remove($Key)
            }
        }
        "ByTag" {
             if ($PSCmdlet.ShouldProcess("items with tag '$Tag'", "Remove cache items")) {
                 $Cache.RemoveByTag($Tag)
            }
        }
        "ByPattern" {
             if ($PSCmdlet.ShouldProcess("items matching pattern '$Pattern'", "Remove cache items")) {
                 $Cache.RemoveByPattern($Pattern)
            }
        }
    }
}

<#
.SYNOPSIS
    Checks if a key exists in the cache (memory or disk).
.DESCRIPTION
    Tests if a non-expired item exists in the memory cache, or if an item
    exists in the disk cache (without checking disk item expiration for performance).
.PARAMETER Cache
    The CacheManager instance to operate on.
.PARAMETER Key
    The key to check for existence. Case-insensitive.
.EXAMPLE
    if (Test-PSCacheItem -Cache $myCache -Key "ConfigLoaded") { ... }
.OUTPUTS
    Boolean $true if the key exists (and is valid in memory, or present on disk), $false otherwise.
#>
function Test-PSCacheItem {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [CacheManager]$Cache,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key
    )

    return $Cache.ContainsKey($Key)
}


<#
.SYNOPSIS
    Retrieves performance and state statistics for the cache.
.DESCRIPTION
    Returns a hashtable containing various statistics like item counts,
    hit/miss ratio, memory usage, configuration settings, etc.
.PARAMETER Cache
    The CacheManager instance to get statistics from.
.EXAMPLE
    Get-PSCacheStatistics -Cache $myCache | Format-List
.OUTPUTS
    Hashtable Detailed cache statistics.
#>
function Get-PSCacheStatistics {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [CacheManager]$Cache
    )

    return $Cache.GetStatistics()
}

<#
.SYNOPSIS
    Clears items from the cache.
.DESCRIPTION
    Removes items from the cache. Can either remove only expired items
    or clear the entire cache (both memory and disk).
.PARAMETER Cache
    The CacheManager instance to operate on.
.PARAMETER ExpiredOnly
    If specified ($true), only removes items whose TTL has passed.
    If omitted or $false, removes ALL items from memory and disk cache.
.EXAMPLE
    Clear-PSCache -Cache $myCache # Clears everything
.EXAMPLE
    Clear-PSCache -Cache $myCache -ExpiredOnly # Removes only expired items
.OUTPUTS
    None
#>
function Clear-PSCache {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [CacheManager]$Cache,

        [Parameter(Mandatory = $false)]
        [switch]$ExpiredOnly
    )

    if ($ExpiredOnly) {
        if ($PSCmdlet.ShouldProcess($Cache.Name, "Clear expired items from cache")) {
            $Cache.ClearExpired()
        }
    }
    else {
         if ($PSCmdlet.ShouldProcess($Cache.Name, "Clear ALL items from cache")) {
            $Cache.Clear()
         }
    }
}

#endregion

#region Exportation

# Export only the public functions
Export-ModuleMember -Function New-PSCache, Get-PSCacheItem, Set-PSCacheItem, Remove-PSCacheItem, Test-PSCacheItem, Get-PSCacheStatistics, Clear-PSCache
# Export the CacheManager class if users need to type-hint variables (optional but can be useful)
# Export-ModuleMember -Class CacheManager

#endregion