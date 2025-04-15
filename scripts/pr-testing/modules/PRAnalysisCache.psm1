#Requires -Version 5.1
<#
.SYNOPSIS
    Module de cache pour l'analyse des pull requests.
.DESCRIPTION
    Fournit des fonctionnalités de cache multi-niveaux pour améliorer
    les performances du système d'analyse des pull requests.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Importer le module PSCacheManager s'il est disponible
$PSCacheManagerAvailable = $false
try {
    Import-Module PSCacheManager -ErrorAction Stop
    $PSCacheManagerAvailable = $true
    Write-Verbose "Module PSCacheManager chargé avec succès."
} catch {
    Write-Warning "Module PSCacheManager non disponible. Utilisation d'un cache mémoire simple."
}

# Cache mémoire simple à utiliser si PSCacheManager n'est pas disponible
$script:SimpleMemoryCache = @{}
$script:SimpleCacheStats = @{
    Hits = 0
    Misses = 0
    Sets = 0
    Removes = 0
}

# Classe pour gérer le cache d'analyse des pull requests
class PRAnalysisCache {
    # Propriétés
    [string]$Name
    [object]$CacheManager
    [bool]$UsePSCacheManager
    [string]$CachePath
    [int]$DefaultTTLSeconds
    [hashtable]$Stats

    # Constructeur
    PRAnalysisCache([string]$name, [string]$cachePath, [int]$defaultTTL) {
        $this.Name = $name
        $this.CachePath = $cachePath
        $this.DefaultTTLSeconds = $defaultTTL
        $this.Stats = @{
            Hits = 0
            Misses = 0
            Sets = 0
            Removes = 0
        }

        # Initialiser le cache
        $this.Initialize()
    }

    # Initialiser le cache
    [void] Initialize() {
        if ($global:PSCacheManagerAvailable) {
            try {
                $this.CacheManager = New-PSCache -Name $this.Name -CachePath $this.CachePath -DefaultTTLSeconds $this.DefaultTTLSeconds
                $this.UsePSCacheManager = $true
                Write-Verbose "Cache '$($this.Name)' initialisé avec PSCacheManager."
            } catch {
                Write-Warning "Erreur lors de l'initialisation du cache avec PSCacheManager: $_"
                $this.UsePSCacheManager = $false
            }
        } else {
            $this.UsePSCacheManager = $false
            Write-Verbose "Cache '$($this.Name)' initialisé avec un cache mémoire simple."
        }
    }

    # Obtenir un élément du cache
    [object] Get([string]$key) {
        if ($this.UsePSCacheManager) {
            $value = Get-PSCacheItem -Cache $this.CacheManager -Key $key
            if ($null -ne $value) {
                $this.Stats.Hits++
            } else {
                $this.Stats.Misses++
            }
            return $value
        } else {
            if ($script:SimpleMemoryCache.ContainsKey($key)) {
                $cacheItem = $script:SimpleMemoryCache[$key]
                # Vérifier si l'élément est expiré
                if ($cacheItem.ExpiresAt -gt (Get-Date)) {
                    $this.Stats.Hits++
                    $script:SimpleCacheStats.Hits++
                    return $cacheItem.Value
                }
                # Supprimer l'élément expiré
                $script:SimpleMemoryCache.Remove($key)
            }
            $this.Stats.Misses++
            $script:SimpleCacheStats.Misses++
            return $null
        }
    }

    # Définir un élément dans le cache
    [void] Set([string]$key, [object]$value, [int]$ttlSeconds = 0) {
        if ($this.UsePSCacheManager) {
            $effectiveTTL = if ($ttlSeconds -gt 0) { $ttlSeconds } else { $this.DefaultTTLSeconds }
            Set-PSCacheItem -Cache $this.CacheManager -Key $key -Value $value -TTLSeconds $effectiveTTL
            $this.Stats.Sets++
        } else {
            $effectiveTTL = if ($ttlSeconds -gt 0) { $ttlSeconds } else { $this.DefaultTTLSeconds }
            $expiresAt = (Get-Date).AddSeconds($effectiveTTL)
            $script:SimpleMemoryCache[$key] = @{
                Value = $value
                ExpiresAt = $expiresAt
            }
            $this.Stats.Sets++
            $script:SimpleCacheStats.Sets++
        }
    }

    # Supprimer un élément du cache
    [void] Remove([string]$key) {
        if ($this.UsePSCacheManager) {
            Remove-PSCacheItem -Cache $this.CacheManager -Key $key
            $this.Stats.Removes++
        } else {
            if ($script:SimpleMemoryCache.ContainsKey($key)) {
                $script:SimpleMemoryCache.Remove($key)
                $this.Stats.Removes++
                $script:SimpleCacheStats.Removes++
            }
        }
    }

    # Vider le cache
    [void] Clear() {
        if ($this.UsePSCacheManager) {
            Clear-PSCache -Cache $this.CacheManager
        } else {
            $script:SimpleMemoryCache.Clear()
        }
        Write-Verbose "Cache '$($this.Name)' vidé."
    }

    # Obtenir les statistiques du cache
    [hashtable] GetStats() {
        if ($this.UsePSCacheManager) {
            $cacheStats = Get-PSCacheStatistics -Cache $this.CacheManager
            return @{
                Name = $this.Name
                Hits = $cacheStats.Hits
                Misses = $cacheStats.Misses
                ItemCount = $cacheStats.MemoryItemCount
                DiskItemCount = $cacheStats.DiskItemCount
                HitRatio = if (($cacheStats.Hits + $cacheStats.Misses) -gt 0) {
                    [Math]::Round(($cacheStats.Hits / ($cacheStats.Hits + $cacheStats.Misses)) * 100, 2)
                } else { 0 }
            }
        } else {
            return @{
                Name = $this.Name
                Hits = $this.Stats.Hits
                Misses = $this.Stats.Misses
                ItemCount = $script:SimpleMemoryCache.Count
                DiskItemCount = 0
                HitRatio = if (($this.Stats.Hits + $this.Stats.Misses) -gt 0) {
                    [Math]::Round(($this.Stats.Hits / ($this.Stats.Hits + $this.Stats.Misses)) * 100, 2)
                } else { 0 }
            }
        }
    }
}

# Fonction pour créer un nouveau cache d'analyse des pull requests
function New-PRAnalysisCache {
    [CmdletBinding()]
    [OutputType([PRAnalysisCache])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name = "PRAnalysisCache",

        [Parameter(Mandatory = $false)]
        [string]$CachePath = (Join-Path -Path $env:TEMP -ChildPath "PRAnalysisCache"),

        [Parameter(Mandatory = $false)]
        [int]$DefaultTTLSeconds = 3600 # 1 heure par défaut
    )

    try {
        $cache = [PRAnalysisCache]::new($Name, $CachePath, $DefaultTTLSeconds)
        return $cache
    } catch {
        Write-Error "Erreur lors de la création du cache d'analyse des pull requests: $_"
        return $null
    }
}

# Fonction pour obtenir un élément du cache avec génération automatique
function Get-PRCacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PRAnalysisCache]$Cache,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [scriptblock]$GenerateValue = $null,

        [Parameter(Mandatory = $false)]
        [int]$TTLSeconds = 0
    )

    try {
        # Essayer d'obtenir l'élément du cache
        $value = $Cache.Get($Key)

        # Si l'élément n'est pas dans le cache et qu'un générateur est fourni
        if ($null -eq $value -and $null -ne $GenerateValue) {
            Write-Verbose "Génération de la valeur pour la clé '$Key'..."
            $value = & $GenerateValue
            
            # Stocker la valeur générée dans le cache
            if ($null -ne $value) {
                $Cache.Set($Key, $value, $TTLSeconds)
            }
        }

        return $value
    } catch {
        Write-Error "Erreur lors de la récupération de l'élément du cache: $_"
        return $null
    }
}

# Fonction pour invalider sélectivement des éléments du cache
function Update-PRCacheSelectively {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PRAnalysisCache]$Cache,

        [Parameter(Mandatory = $true, ParameterSetName = "ByPattern")]
        [string]$Pattern,

        [Parameter(Mandatory = $true, ParameterSetName = "ByKeys")]
        [string[]]$Keys,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveMatching
    )

    try {
        if ($PSCmdlet.ParameterSetName -eq "ByPattern") {
            # Obtenir toutes les clés correspondant au modèle
            $matchingKeys = @()
            if ($Cache.UsePSCacheManager) {
                $allKeys = Get-PSCacheKeys -Cache $Cache.CacheManager
                $matchingKeys = $allKeys | Where-Object { $_ -like $Pattern }
            } else {
                $matchingKeys = $script:SimpleMemoryCache.Keys | Where-Object { $_ -like $Pattern }
            }

            # Supprimer ou mettre à jour les éléments correspondants
            foreach ($key in $matchingKeys) {
                if ($RemoveMatching) {
                    $Cache.Remove($key)
                    Write-Verbose "Clé supprimée: $key"
                } else {
                    # Ici, on pourrait implémenter une logique de mise à jour spécifique
                    # Pour l'instant, on se contente de supprimer l'élément
                    $Cache.Remove($key)
                    Write-Verbose "Clé invalidée: $key"
                }
            }

            return $matchingKeys.Count
        } else {
            # Supprimer ou mettre à jour les clés spécifiées
            $processedCount = 0
            foreach ($key in $Keys) {
                if ($RemoveMatching) {
                    $Cache.Remove($key)
                    Write-Verbose "Clé supprimée: $key"
                } else {
                    # Ici, on pourrait implémenter une logique de mise à jour spécifique
                    # Pour l'instant, on se contente de supprimer l'élément
                    $Cache.Remove($key)
                    Write-Verbose "Clé invalidée: $key"
                }
                $processedCount++
            }

            return $processedCount
        }
    } catch {
        Write-Error "Erreur lors de la mise à jour sélective du cache: $_"
        return 0
    }
}

# Fonction pour obtenir les statistiques du cache
function Get-PRCacheStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PRAnalysisCache]$Cache
    )

    try {
        return $Cache.GetStats()
    } catch {
        Write-Error "Erreur lors de la récupération des statistiques du cache: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-PRAnalysisCache, Get-PRCacheItem, Update-PRCacheSelectively, Get-PRCacheStatistics
