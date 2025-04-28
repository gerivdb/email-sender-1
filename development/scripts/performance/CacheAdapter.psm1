#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'adaptation du cache pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Ce module fournit des fonctions pour gÃ©rer le cache partagÃ© entre PowerShell et Python.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur
#>

# VÃ©rifier si le module PSCacheManager est disponible
$psCacheManagerAvailable = $false
try {
    $psCacheManagerAvailable = Get-Module -ListAvailable -Name PSCacheManager
    if (-not $psCacheManagerAvailable) {
        Write-Verbose "Module PSCacheManager non disponible. Utilisation du cache intÃ©grÃ©."
    }
    else {
        Write-Verbose "Module PSCacheManager disponible. Utilisation du cache PSCacheManager."
        Import-Module PSCacheManager -Force
    }
}
catch {
    Write-Warning "Erreur lors de la vÃ©rification du module PSCacheManager : $_"
}

<#
.SYNOPSIS
    Initialise le cache partagÃ© pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    CrÃ©e et configure un cache partagÃ© entre PowerShell et Python.
.PARAMETER Config
    Configuration du cache partagÃ©.
.PARAMETER CachePath
    Chemin vers le rÃ©pertoire du cache. Par dÃ©faut: sous-rÃ©pertoire 'cache' du rÃ©pertoire courant.
.PARAMETER CacheType
    Type de cache Ã  utiliser. Valeurs possibles: 'Memory', 'Disk', 'Hybrid'. Par dÃ©faut: 'Hybrid'.
.PARAMETER MaxMemorySize
    Taille maximale du cache en mÃ©moire en Mo. Par dÃ©faut: 100.
.PARAMETER MaxDiskSize
    Taille maximale du cache sur disque en Mo. Par dÃ©faut: 1000.
.PARAMETER DefaultTTL
    DurÃ©e de vie par dÃ©faut des Ã©lÃ©ments du cache en secondes. Par dÃ©faut: 3600 (1 heure).
.PARAMETER EvictionPolicy
    Politique d'Ã©viction des Ã©lÃ©ments du cache. Valeurs possibles: 'LRU', 'LFU', 'FIFO'. Par dÃ©faut: 'LRU'.
.EXAMPLE
    $cache = Initialize-SharedCache -CachePath "C:\Temp\Cache" -CacheType "Hybrid"
.OUTPUTS
    Un objet reprÃ©sentant le cache partagÃ©.
#>
function Initialize-SharedCache {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$CachePath = (Join-Path -Path $PWD -ChildPath "cache"),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Memory", "Disk", "Hybrid")]
        [string]$CacheType = "Hybrid",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxMemorySize = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDiskSize = 1000,
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultTTL = 3600,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("LRU", "LFU", "FIFO")]
        [string]$EvictionPolicy = "LRU"
    )
    
    # Fusionner la configuration par dÃ©faut avec la configuration fournie
    $cacheConfig = @{
        CachePath = $CachePath
        CacheType = $CacheType
        MaxMemorySize = $MaxMemorySize
        MaxDiskSize = $MaxDiskSize
        DefaultTTL = $DefaultTTL
        EvictionPolicy = $EvictionPolicy
    }
    
    foreach ($key in $Config.Keys) {
        $cacheConfig[$key] = $Config[$key]
    }
    
    # CrÃ©er le rÃ©pertoire du cache si nÃ©cessaire
    if (-not (Test-Path -Path $cacheConfig.CachePath)) {
        New-Item -Path $cacheConfig.CachePath -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er le fichier de configuration du cache pour Python
    $cacheConfigPath = Join-Path -Path $cacheConfig.CachePath -ChildPath "cache_config.json"
    $cacheConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $cacheConfigPath -Encoding utf8
    
    # Initialiser le cache selon le type
    $cache = $null
    
    if ($psCacheManagerAvailable) {
        # Utiliser PSCacheManager si disponible
        try {
            $cache = New-PSCache -Name "HybridCache" -Path $cacheConfig.CachePath -MaxMemorySize $cacheConfig.MaxMemorySize -MaxDiskSize $cacheConfig.MaxDiskSize -DefaultTTL $cacheConfig.DefaultTTL -EvictionPolicy $cacheConfig.EvictionPolicy
        }
        catch {
            Write-Warning "Erreur lors de l'initialisation du cache PSCacheManager : $_"
            $cache = Initialize-InternalCache -Config $cacheConfig
        }
    }
    else {
        # Utiliser le cache interne
        $cache = Initialize-InternalCache -Config $cacheConfig
    }
    
    return $cache
}

<#
.SYNOPSIS
    Initialise un cache interne pour l'architecture hybride PowerShell-Python.
.DESCRIPTION
    CrÃ©e et configure un cache interne lorsque PSCacheManager n'est pas disponible.
.PARAMETER Config
    Configuration du cache interne.
.EXAMPLE
    $cache = Initialize-InternalCache -Config $cacheConfig
.OUTPUTS
    Un objet reprÃ©sentant le cache interne.
#>
function Initialize-InternalCache {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    # CrÃ©er l'objet cache
    $cache = [PSCustomObject]@{
        Name = "InternalCache"
        CachePath = $Config.CachePath
        CacheType = $Config.CacheType
        MaxMemorySize = $Config.MaxMemorySize
        MaxDiskSize = $Config.MaxDiskSize
        DefaultTTL = $Config.DefaultTTL
        EvictionPolicy = $Config.EvictionPolicy
        MemoryCache = @{}
        DiskCache = @{}
        Statistics = @{
            MemoryHits = 0
            MemoryMisses = 0
            DiskHits = 0
            DiskMisses = 0
            Evictions = 0
        }
    }
    
    # Ajouter les mÃ©thodes au cache
    $cache | Add-Member -MemberType ScriptMethod -Name "Get" -Value {
        param(
            [string]$Key,
            [object]$DefaultValue = $null
        )
        
        # VÃ©rifier d'abord dans le cache mÃ©moire
        if ($this.MemoryCache.ContainsKey($Key)) {
            $item = $this.MemoryCache[$Key]
            
            # VÃ©rifier si l'Ã©lÃ©ment est expirÃ©
            if ($item.ExpiresAt -gt (Get-Date)) {
                $this.Statistics.MemoryHits++
                return $item.Value
            }
            else {
                # Supprimer l'Ã©lÃ©ment expirÃ©
                $this.MemoryCache.Remove($Key)
            }
        }
        
        # Si le cache est de type Hybrid ou Disk, vÃ©rifier dans le cache disque
        if ($this.CacheType -ne "Memory") {
            $diskCachePath = Join-Path -Path $this.CachePath -ChildPath "$Key.cache"
            
            if (Test-Path -Path $diskCachePath) {
                try {
                    $item = Import-Clixml -Path $diskCachePath
                    
                    # VÃ©rifier si l'Ã©lÃ©ment est expirÃ©
                    if ($item.ExpiresAt -gt (Get-Date)) {
                        $this.Statistics.DiskHits++
                        
                        # Promouvoir l'Ã©lÃ©ment dans le cache mÃ©moire si le cache est de type Hybrid
                        if ($this.CacheType -eq "Hybrid") {
                            $this.Set($Key, $item.Value, ($item.ExpiresAt - (Get-Date)).TotalSeconds)
                        }
                        
                        return $item.Value
                    }
                    else {
                        # Supprimer l'Ã©lÃ©ment expirÃ©
                        Remove-Item -Path $diskCachePath -Force
                    }
                }
                catch {
                    Write-Warning "Erreur lors de la lecture du cache disque pour la clÃ© '$Key' : $_"
                }
            }
            
            $this.Statistics.DiskMisses++
        }
        else {
            $this.Statistics.MemoryMisses++
        }
        
        return $DefaultValue
    }
    
    $cache | Add-Member -MemberType ScriptMethod -Name "Set" -Value {
        param(
            [string]$Key,
            [object]$Value,
            [int]$TTL = $this.DefaultTTL
        )
        
        # CrÃ©er l'Ã©lÃ©ment de cache
        $expiresAt = (Get-Date).AddSeconds($TTL)
        $item = @{
            Key = $Key
            Value = $Value
            CreatedAt = Get-Date
            ExpiresAt = $expiresAt
            TTL = $TTL
        }
        
        # Stocker dans le cache mÃ©moire si le cache est de type Memory ou Hybrid
        if ($this.CacheType -ne "Disk") {
            # VÃ©rifier si le cache mÃ©moire est plein
            if ($this.MemoryCache.Count -ge $this.MaxMemorySize) {
                # Appliquer la politique d'Ã©viction
                $this.EvictFromMemory()
            }
            
            $this.MemoryCache[$Key] = $item
        }
        
        # Stocker dans le cache disque si le cache est de type Disk ou Hybrid
        if ($this.CacheType -ne "Memory") {
            try {
                $diskCachePath = Join-Path -Path $this.CachePath -ChildPath "$Key.cache"
                $item | Export-Clixml -Path $diskCachePath -Force
                
                # VÃ©rifier si le cache disque est plein
                $diskCacheSize = (Get-ChildItem -Path $this.CachePath -Filter "*.cache" | Measure-Object -Property Length -Sum).Sum / 1MB
                if ($diskCacheSize -ge $this.MaxDiskSize) {
                    # Appliquer la politique d'Ã©viction
                    $this.EvictFromDisk()
                }
            }
            catch {
                Write-Warning "Erreur lors de l'Ã©criture dans le cache disque pour la clÃ© '$Key' : $_"
            }
        }
        
        return $Value
    }
    
    $cache | Add-Member -MemberType ScriptMethod -Name "Remove" -Value {
        param(
            [string]$Key
        )
        
        # Supprimer du cache mÃ©moire
        if ($this.MemoryCache.ContainsKey($Key)) {
            $this.MemoryCache.Remove($Key)
        }
        
        # Supprimer du cache disque
        $diskCachePath = Join-Path -Path $this.CachePath -ChildPath "$Key.cache"
        if (Test-Path -Path $diskCachePath) {
            Remove-Item -Path $diskCachePath -Force
        }
    }
    
    $cache | Add-Member -MemberType ScriptMethod -Name "Clear" -Value {
        # Vider le cache mÃ©moire
        $this.MemoryCache.Clear()
        
        # Vider le cache disque
        Get-ChildItem -Path $this.CachePath -Filter "*.cache" | Remove-Item -Force
        
        # RÃ©initialiser les statistiques
        $this.Statistics.MemoryHits = 0
        $this.Statistics.MemoryMisses = 0
        $this.Statistics.DiskHits = 0
        $this.Statistics.DiskMisses = 0
        $this.Statistics.Evictions = 0
    }
    
    $cache | Add-Member -MemberType ScriptMethod -Name "EvictFromMemory" -Value {
        # Appliquer la politique d'Ã©viction pour le cache mÃ©moire
        switch ($this.EvictionPolicy) {
            "LRU" {
                # Least Recently Used
                $oldestKey = $this.MemoryCache.Keys | Sort-Object { $this.MemoryCache[$_].LastAccessedAt } | Select-Object -First 1
                if ($oldestKey) {
                    $this.MemoryCache.Remove($oldestKey)
                    $this.Statistics.Evictions++
                }
            }
            "LFU" {
                # Least Frequently Used
                $leastUsedKey = $this.MemoryCache.Keys | Sort-Object { $this.MemoryCache[$_].AccessCount } | Select-Object -First 1
                if ($leastUsedKey) {
                    $this.MemoryCache.Remove($leastUsedKey)
                    $this.Statistics.Evictions++
                }
            }
            "FIFO" {
                # First In First Out
                $oldestKey = $this.MemoryCache.Keys | Sort-Object { $this.MemoryCache[$_].CreatedAt } | Select-Object -First 1
                if ($oldestKey) {
                    $this.MemoryCache.Remove($oldestKey)
                    $this.Statistics.Evictions++
                }
            }
        }
    }
    
    $cache | Add-Member -MemberType ScriptMethod -Name "EvictFromDisk" -Value {
        # Appliquer la politique d'Ã©viction pour le cache disque
        $cacheFiles = Get-ChildItem -Path $this.CachePath -Filter "*.cache"
        
        switch ($this.EvictionPolicy) {
            "LRU" {
                # Least Recently Used
                $oldestFile = $cacheFiles | Sort-Object LastWriteTime | Select-Object -First 1
                if ($oldestFile) {
                    Remove-Item -Path $oldestFile.FullName -Force
                    $this.Statistics.Evictions++
                }
            }
            "LFU" {
                # Least Frequently Used (approximation basÃ©e sur la taille du fichier)
                $smallestFile = $cacheFiles | Sort-Object Length | Select-Object -First 1
                if ($smallestFile) {
                    Remove-Item -Path $smallestFile.FullName -Force
                    $this.Statistics.Evictions++
                }
            }
            "FIFO" {
                # First In First Out
                $oldestFile = $cacheFiles | Sort-Object CreationTime | Select-Object -First 1
                if ($oldestFile) {
                    Remove-Item -Path $oldestFile.FullName -Force
                    $this.Statistics.Evictions++
                }
            }
        }
    }
    
    $cache | Add-Member -MemberType ScriptMethod -Name "GetStatistics" -Value {
        return $this.Statistics
    }
    
    return $cache
}

<#
.SYNOPSIS
    Obtient un Ã©lÃ©ment du cache partagÃ©.
.DESCRIPTION
    RÃ©cupÃ¨re un Ã©lÃ©ment du cache partagÃ© en utilisant sa clÃ©.
.PARAMETER Cache
    Objet cache initialisÃ© par Initialize-SharedCache.
.PARAMETER Key
    ClÃ© de l'Ã©lÃ©ment Ã  rÃ©cupÃ©rer.
.PARAMETER DefaultValue
    Valeur par dÃ©faut Ã  retourner si l'Ã©lÃ©ment n'est pas trouvÃ©. Par dÃ©faut: $null.
.EXAMPLE
    $value = Get-SharedCacheItem -Cache $cache -Key "myKey" -DefaultValue "defaultValue"
.OUTPUTS
    La valeur de l'Ã©lÃ©ment du cache ou la valeur par dÃ©faut si l'Ã©lÃ©ment n'est pas trouvÃ©.
#>
function Get-SharedCacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cache,
        
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [object]$DefaultValue = $null
    )
    
    if ($psCacheManagerAvailable -and $Cache.GetType().Name -eq "PSCache") {
        return Get-PSCacheItem -Cache $Cache -Key $Key -DefaultValue $DefaultValue
    }
    else {
        return $Cache.Get($Key, $DefaultValue)
    }
}

<#
.SYNOPSIS
    DÃ©finit un Ã©lÃ©ment dans le cache partagÃ©.
.DESCRIPTION
    Stocke un Ã©lÃ©ment dans le cache partagÃ© en utilisant sa clÃ©.
.PARAMETER Cache
    Objet cache initialisÃ© par Initialize-SharedCache.
.PARAMETER Key
    ClÃ© de l'Ã©lÃ©ment Ã  stocker.
.PARAMETER Value
    Valeur de l'Ã©lÃ©ment Ã  stocker.
.PARAMETER TTL
    DurÃ©e de vie de l'Ã©lÃ©ment en secondes. Par dÃ©faut: valeur par dÃ©faut du cache.
.EXAMPLE
    Set-SharedCacheItem -Cache $cache -Key "myKey" -Value "myValue" -TTL 3600
.OUTPUTS
    La valeur stockÃ©e dans le cache.
#>
function Set-SharedCacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cache,
        
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter(Mandatory = $false)]
        [int]$TTL = 0
    )
    
    if ($TTL -le 0) {
        $TTL = $Cache.DefaultTTL
    }
    
    if ($psCacheManagerAvailable -and $Cache.GetType().Name -eq "PSCache") {
        return Set-PSCacheItem -Cache $Cache -Key $Key -Value $Value -TTL $TTL
    }
    else {
        return $Cache.Set($Key, $Value, $TTL)
    }
}

<#
.SYNOPSIS
    Supprime un Ã©lÃ©ment du cache partagÃ©.
.DESCRIPTION
    Supprime un Ã©lÃ©ment du cache partagÃ© en utilisant sa clÃ©.
.PARAMETER Cache
    Objet cache initialisÃ© par Initialize-SharedCache.
.PARAMETER Key
    ClÃ© de l'Ã©lÃ©ment Ã  supprimer.
.EXAMPLE
    Remove-SharedCacheItem -Cache $cache -Key "myKey"
#>
function Remove-SharedCacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cache,
        
        [Parameter(Mandatory = $true)]
        [string]$Key
    )
    
    if ($psCacheManagerAvailable -and $Cache.GetType().Name -eq "PSCache") {
        Remove-PSCacheItem -Cache $Cache -Key $Key
    }
    else {
        $Cache.Remove($Key)
    }
}

<#
.SYNOPSIS
    Vide le cache partagÃ©.
.DESCRIPTION
    Supprime tous les Ã©lÃ©ments du cache partagÃ©.
.PARAMETER Cache
    Objet cache initialisÃ© par Initialize-SharedCache.
.EXAMPLE
    Clear-SharedCache -Cache $cache
#>
function Clear-SharedCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cache
    )
    
    if ($psCacheManagerAvailable -and $Cache.GetType().Name -eq "PSCache") {
        Clear-PSCache -Cache $Cache
    }
    else {
        $Cache.Clear()
    }
}

<#
.SYNOPSIS
    Obtient les statistiques du cache partagÃ©.
.DESCRIPTION
    RÃ©cupÃ¨re les statistiques d'utilisation du cache partagÃ©.
.PARAMETER Cache
    Objet cache initialisÃ© par Initialize-SharedCache.
.EXAMPLE
    $stats = Get-SharedCacheStatistics -Cache $cache
.OUTPUTS
    Un objet contenant les statistiques du cache.
#>
function Get-SharedCacheStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cache
    )
    
    if ($psCacheManagerAvailable -and $Cache.GetType().Name -eq "PSCache") {
        return Get-PSCacheStatistics -Cache $Cache
    }
    else {
        return $Cache.GetStatistics()
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-SharedCache, Get-SharedCacheItem, Set-SharedCacheItem, Remove-SharedCacheItem, Clear-SharedCache, Get-SharedCacheStatistics
