#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion de cache pour amÃ©liorer les performances.
.DESCRIPTION
    Ce module fournit des fonctions pour mettre en cache les rÃ©sultats des opÃ©rations
    coÃ»teuses afin d'amÃ©liorer les performances lors des appels rÃ©pÃ©tÃ©s.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Initialiser le cache
$script:Cache = @{}
$script:CacheStats = @{
    Hits = 0
    Misses = 0
    Evictions = 0
}
$script:CacheConfig = @{
    Enabled = $true
    MaxItems = 1000
    DefaultTTL = 3600  # Secondes (1 heure)
    EvictionPolicy = "LRU"  # LRU, LFU, FIFO
}

# Fonction pour initialiser le gestionnaire de cache
function Initialize-CacheManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxItems = 1000,
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultTTL = 3600,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("LRU", "LFU", "FIFO")]
        [string]$EvictionPolicy = "LRU"
    )
    
    $script:CacheConfig.Enabled = $Enabled
    $script:CacheConfig.MaxItems = $MaxItems
    $script:CacheConfig.DefaultTTL = $DefaultTTL
    $script:CacheConfig.EvictionPolicy = $EvictionPolicy
    
    # RÃ©initialiser le cache et les statistiques
    $script:Cache = @{}
    $script:CacheStats = @{
        Hits = 0
        Misses = 0
        Evictions = 0
    }
    
    Write-Verbose "Gestionnaire de cache initialisÃ© avec les paramÃ¨tres suivants :"
    Write-Verbose "  ActivÃ© : $Enabled"
    Write-Verbose "  Nombre maximum d'Ã©lÃ©ments : $MaxItems"
    Write-Verbose "  TTL par dÃ©faut : $DefaultTTL secondes"
    Write-Verbose "  Politique d'Ã©viction : $EvictionPolicy"
    
    return $true
}

# Fonction pour obtenir un Ã©lÃ©ment du cache
function Get-CacheItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key
    )
    
    if (-not $script:CacheConfig.Enabled) {
        Write-Verbose "Le cache est dÃ©sactivÃ©."
        return $null
    }
    
    if (-not $script:Cache.ContainsKey($Key)) {
        Write-Verbose "Ã‰lÃ©ment non trouvÃ© dans le cache : $Key"
        $script:CacheStats.Misses++
        return $null
    }
    
    $cacheItem = $script:Cache[$Key]
    
    # VÃ©rifier si l'Ã©lÃ©ment a expirÃ©
    if ($cacheItem.ExpiresAt -lt (Get-Date)) {
        Write-Verbose "Ã‰lÃ©ment expirÃ© dans le cache : $Key"
        $script:Cache.Remove($Key)
        $script:CacheStats.Misses++
        return $null
    }
    
    # Mettre Ã  jour les statistiques d'accÃ¨s
    $cacheItem.LastAccessed = Get-Date
    $cacheItem.AccessCount++
    
    Write-Verbose "Ã‰lÃ©ment trouvÃ© dans le cache : $Key"
    $script:CacheStats.Hits++
    
    return $cacheItem.Value
}

# Fonction pour ajouter un Ã©lÃ©ment au cache
function Set-CacheItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter(Mandatory = $false)]
        [int]$TTL = -1
    )
    
    if (-not $script:CacheConfig.Enabled) {
        Write-Verbose "Le cache est dÃ©sactivÃ©."
        return
    }
    
    # Utiliser le TTL par dÃ©faut si non spÃ©cifiÃ©
    if ($TTL -lt 0) {
        $TTL = $script:CacheConfig.DefaultTTL
    }
    
    # CrÃ©er l'Ã©lÃ©ment de cache
    $cacheItem = @{
        Key = $Key
        Value = $Value
        CreatedAt = Get-Date
        LastAccessed = Get-Date
        ExpiresAt = (Get-Date).AddSeconds($TTL)
        AccessCount = 0
    }
    
    # VÃ©rifier si le cache est plein
    if ($script:Cache.Count -ge $script:CacheConfig.MaxItems -and -not $script:Cache.ContainsKey($Key)) {
        # Ã‰viction selon la politique configurÃ©e
        $evictedKey = $null
        
        switch ($script:CacheConfig.EvictionPolicy) {
            "LRU" {
                # Least Recently Used
                $evictedKey = $script:Cache.Keys | 
                    Sort-Object { $script:Cache[$_].LastAccessed } | 
                    Select-Object -First 1
            }
            "LFU" {
                # Least Frequently Used
                $evictedKey = $script:Cache.Keys | 
                    Sort-Object { $script:Cache[$_].AccessCount } | 
                    Select-Object -First 1
            }
            "FIFO" {
                # First In First Out
                $evictedKey = $script:Cache.Keys | 
                    Sort-Object { $script:Cache[$_].CreatedAt } | 
                    Select-Object -First 1
            }
        }
        
        if ($evictedKey) {
            Write-Verbose "Ã‰viction de l'Ã©lÃ©ment du cache : $evictedKey"
            $script:Cache.Remove($evictedKey)
            $script:CacheStats.Evictions++
        }
    }
    
    # Ajouter ou mettre Ã  jour l'Ã©lÃ©ment dans le cache
    $script:Cache[$Key] = $cacheItem
    
    Write-Verbose "Ã‰lÃ©ment ajoutÃ© au cache : $Key (expire dans $TTL secondes)"
}

# Fonction pour supprimer un Ã©lÃ©ment du cache
function Remove-CacheItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key
    )
    
    if (-not $script:CacheConfig.Enabled) {
        Write-Verbose "Le cache est dÃ©sactivÃ©."
        return
    }
    
    if ($script:Cache.ContainsKey($Key)) {
        Write-Verbose "Suppression de l'Ã©lÃ©ment du cache : $Key"
        $script:Cache.Remove($Key)
        return $true
    }
    
    Write-Verbose "Ã‰lÃ©ment non trouvÃ© dans le cache : $Key"
    return $false
}

# Fonction pour vider le cache
function Clear-Cache {
    [CmdletBinding()]
    param ()
    
    Write-Verbose "Vidage du cache"
    $script:Cache = @{}
    
    return $true
}

# Fonction pour obtenir les statistiques du cache
function Get-CacheStatistics {
    [CmdletBinding()]
    param ()
    
    $totalRequests = $script:CacheStats.Hits + $script:CacheStats.Misses
    $hitRate = if ($totalRequests -gt 0) { $script:CacheStats.Hits / $totalRequests } else { 0 }
    
    $stats = [PSCustomObject]@{
        Enabled = $script:CacheConfig.Enabled
        ItemCount = $script:Cache.Count
        MaxItems = $script:CacheConfig.MaxItems
        UsagePercentage = if ($script:CacheConfig.MaxItems -gt 0) { $script:Cache.Count / $script:CacheConfig.MaxItems * 100 } else { 0 }
        Hits = $script:CacheStats.Hits
        Misses = $script:CacheStats.Misses
        TotalRequests = $totalRequests
        HitRate = $hitRate
        Evictions = $script:CacheStats.Evictions
        EvictionPolicy = $script:CacheConfig.EvictionPolicy
    }
    
    return $stats
}

# Fonction pour exÃ©cuter une fonction avec mise en cache
function Invoke-CachedFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true)]
        [string]$CacheKey,
        
        [Parameter(Mandatory = $false)]
        [int]$TTL = -1,
        
        [Parameter(Mandatory = $false)]
        [object[]]$Arguments = @()
    )
    
    if (-not $script:CacheConfig.Enabled) {
        Write-Verbose "Le cache est dÃ©sactivÃ©. ExÃ©cution directe de la fonction."
        return & $ScriptBlock @Arguments
    }
    
    # VÃ©rifier si le rÃ©sultat est dans le cache
    $cachedResult = Get-CacheItem -Key $CacheKey
    
    if ($null -ne $cachedResult) {
        Write-Verbose "RÃ©sultat trouvÃ© dans le cache pour la clÃ© : $CacheKey"
        return $cachedResult
    }
    
    # ExÃ©cuter la fonction
    Write-Verbose "ExÃ©cution de la fonction et mise en cache du rÃ©sultat pour la clÃ© : $CacheKey"
    $result = & $ScriptBlock @Arguments
    
    # Mettre en cache le rÃ©sultat
    Set-CacheItem -Key $CacheKey -Value $result -TTL $TTL
    
    return $result
}

# Exporter les fonctions
# Export-ModuleMember est commentÃ© pour permettre le chargement direct du script

