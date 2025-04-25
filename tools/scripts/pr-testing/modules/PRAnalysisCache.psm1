#
# Module PRAnalysisCache
# Cache pour l'analyse des fichiers
#

# Classe PRAnalysisCache
class PRAnalysisCache {
    [int]$MaxMemoryItems
    [hashtable]$MemoryCache
    [string]$DiskCachePath
    
    PRAnalysisCache([int]$maxMemoryItems) {
        $this.MaxMemoryItems = $maxMemoryItems
        $this.MemoryCache = @{}
        $this.DiskCachePath = Join-Path -Path $env:TEMP -ChildPath "PRAnalysisCache"
        
        # Créer le répertoire de cache si nécessaire
        if (-not (Test-Path -Path $this.DiskCachePath)) {
            New-Item -Path $this.DiskCachePath -ItemType Directory -Force | Out-Null
        }
    }
    
    [object] GetItem([string]$key) {
        # Normaliser la clé
        $normalizedKey = $this.NormalizeKey($key)
        
        # Vérifier le cache en mémoire
        if ($this.MemoryCache.ContainsKey($normalizedKey)) {
            $cacheItem = $this.MemoryCache[$normalizedKey]
            
            # Vérifier si l'élément est expiré
            if ($cacheItem.Expiration -gt (Get-Date)) {
                return $cacheItem.Value
            }
            else {
                # Supprimer l'élément expiré
                $this.MemoryCache.Remove($normalizedKey)
            }
        }
        
        # Vérifier le cache sur disque
        $diskCacheFile = Join-Path -Path $this.DiskCachePath -ChildPath "$normalizedKey.xml"
        if (Test-Path -Path $diskCacheFile) {
            try {
                $cacheItem = Import-Clixml -Path $diskCacheFile
                
                # Vérifier si l'élément est expiré
                if ($cacheItem.Expiration -gt (Get-Date)) {
                    # Ajouter l'élément au cache en mémoire
                    $this.MemoryCache[$normalizedKey] = $cacheItem
                    
                    # Nettoyer le cache en mémoire si nécessaire
                    $this.CleanMemoryCache()
                    
                    return $cacheItem.Value
                }
                else {
                    # Supprimer l'élément expiré
                    Remove-Item -Path $diskCacheFile -Force
                }
            }
            catch {
                Write-Warning "Erreur lors de la lecture du cache sur disque: $_"
            }
        }
        
        return $null
    }
    
    [void] SetItem([string]$key, [object]$value, [timespan]$duration = (New-TimeSpan -Hours 1)) {
        # Normaliser la clé
        $normalizedKey = $this.NormalizeKey($key)
        
        # Créer l'élément de cache
        $cacheItem = @{
            Key = $normalizedKey
            Value = $value
            Created = Get-Date
            Expiration = (Get-Date) + $duration
        }
        
        # Ajouter l'élément au cache en mémoire
        $this.MemoryCache[$normalizedKey] = $cacheItem
        
        # Nettoyer le cache en mémoire si nécessaire
        $this.CleanMemoryCache()
        
        # Enregistrer l'élément sur disque
        try {
            $diskCacheFile = Join-Path -Path $this.DiskCachePath -ChildPath "$normalizedKey.xml"
            $cacheItem | Export-Clixml -Path $diskCacheFile -Force
        }
        catch {
            Write-Warning "Erreur lors de l'écriture du cache sur disque: $_"
        }
    }
    
    [void] RemoveItem([string]$key) {
        # Normaliser la clé
        $normalizedKey = $this.NormalizeKey($key)
        
        # Supprimer l'élément du cache en mémoire
        if ($this.MemoryCache.ContainsKey($normalizedKey)) {
            $this.MemoryCache.Remove($normalizedKey)
        }
        
        # Supprimer l'élément du cache sur disque
        $diskCacheFile = Join-Path -Path $this.DiskCachePath -ChildPath "$normalizedKey.xml"
        if (Test-Path -Path $diskCacheFile) {
            Remove-Item -Path $diskCacheFile -Force
        }
    }
    
    [void] Clear() {
        # Vider le cache en mémoire
        $this.MemoryCache = @{}
        
        # Vider le cache sur disque
        Get-ChildItem -Path $this.DiskCachePath -Filter "*.xml" | Remove-Item -Force
    }
    
    [string] NormalizeKey([string]$key) {
        # Remplacer les caractères non valides pour les noms de fichiers
        $normalizedKey = $key -replace "[\\/:*?`"<>|]", "_"
        
        # Limiter la longueur de la clé
        if ($normalizedKey.Length -gt 100) {
            $normalizedKey = $normalizedKey.Substring(0, 50) + "_" + (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($key)))).Hash.Substring(0, 48)
        }
        
        return $normalizedKey
    }
    
    [void] CleanMemoryCache() {
        # Nettoyer le cache en mémoire si nécessaire
        if ($this.MemoryCache.Count -gt $this.MaxMemoryItems) {
            # Trier les éléments par date d'expiration
            $sortedItems = $this.MemoryCache.GetEnumerator() | Sort-Object { $_.Value.Expiration }
            
            # Supprimer les éléments les plus anciens
            $itemsToRemove = $sortedItems | Select-Object -First ($this.MemoryCache.Count - $this.MaxMemoryItems)
            foreach ($item in $itemsToRemove) {
                $this.MemoryCache.Remove($item.Key)
            }
        }
    }
}

# Fonction pour créer un nouveau cache
function New-PRAnalysisCache {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MaxMemoryItems = 1000
    )
    
    return [PRAnalysisCache]::new($MaxMemoryItems)
}

# Exporter les fonctions
Export-ModuleMember -Function New-PRAnalysisCache
