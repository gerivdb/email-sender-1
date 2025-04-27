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
        
        # CrÃ©er le rÃ©pertoire de cache si nÃ©cessaire
        if (-not (Test-Path -Path $this.DiskCachePath)) {
            New-Item -Path $this.DiskCachePath -ItemType Directory -Force | Out-Null
        }
    }
    
    [object] GetItem([string]$key) {
        # Normaliser la clÃ©
        $normalizedKey = $this.NormalizeKey($key)
        
        # VÃ©rifier le cache en mÃ©moire
        if ($this.MemoryCache.ContainsKey($normalizedKey)) {
            $cacheItem = $this.MemoryCache[$normalizedKey]
            
            # VÃ©rifier si l'Ã©lÃ©ment est expirÃ©
            if ($cacheItem.Expiration -gt (Get-Date)) {
                return $cacheItem.Value
            }
            else {
                # Supprimer l'Ã©lÃ©ment expirÃ©
                $this.MemoryCache.Remove($normalizedKey)
            }
        }
        
        # VÃ©rifier le cache sur disque
        $diskCacheFile = Join-Path -Path $this.DiskCachePath -ChildPath "$normalizedKey.xml"
        if (Test-Path -Path $diskCacheFile) {
            try {
                $cacheItem = Import-Clixml -Path $diskCacheFile
                
                # VÃ©rifier si l'Ã©lÃ©ment est expirÃ©
                if ($cacheItem.Expiration -gt (Get-Date)) {
                    # Ajouter l'Ã©lÃ©ment au cache en mÃ©moire
                    $this.MemoryCache[$normalizedKey] = $cacheItem
                    
                    # Nettoyer le cache en mÃ©moire si nÃ©cessaire
                    $this.CleanMemoryCache()
                    
                    return $cacheItem.Value
                }
                else {
                    # Supprimer l'Ã©lÃ©ment expirÃ©
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
        # Normaliser la clÃ©
        $normalizedKey = $this.NormalizeKey($key)
        
        # CrÃ©er l'Ã©lÃ©ment de cache
        $cacheItem = @{
            Key = $normalizedKey
            Value = $value
            Created = Get-Date
            Expiration = (Get-Date) + $duration
        }
        
        # Ajouter l'Ã©lÃ©ment au cache en mÃ©moire
        $this.MemoryCache[$normalizedKey] = $cacheItem
        
        # Nettoyer le cache en mÃ©moire si nÃ©cessaire
        $this.CleanMemoryCache()
        
        # Enregistrer l'Ã©lÃ©ment sur disque
        try {
            $diskCacheFile = Join-Path -Path $this.DiskCachePath -ChildPath "$normalizedKey.xml"
            $cacheItem | Export-Clixml -Path $diskCacheFile -Force
        }
        catch {
            Write-Warning "Erreur lors de l'Ã©criture du cache sur disque: $_"
        }
    }
    
    [void] RemoveItem([string]$key) {
        # Normaliser la clÃ©
        $normalizedKey = $this.NormalizeKey($key)
        
        # Supprimer l'Ã©lÃ©ment du cache en mÃ©moire
        if ($this.MemoryCache.ContainsKey($normalizedKey)) {
            $this.MemoryCache.Remove($normalizedKey)
        }
        
        # Supprimer l'Ã©lÃ©ment du cache sur disque
        $diskCacheFile = Join-Path -Path $this.DiskCachePath -ChildPath "$normalizedKey.xml"
        if (Test-Path -Path $diskCacheFile) {
            Remove-Item -Path $diskCacheFile -Force
        }
    }
    
    [void] Clear() {
        # Vider le cache en mÃ©moire
        $this.MemoryCache = @{}
        
        # Vider le cache sur disque
        Get-ChildItem -Path $this.DiskCachePath -Filter "*.xml" | Remove-Item -Force
    }
    
    [string] NormalizeKey([string]$key) {
        # Remplacer les caractÃ¨res non valides pour les noms de fichiers
        $normalizedKey = $key -replace "[\\/:*?`"<>|]", "_"
        
        # Limiter la longueur de la clÃ©
        if ($normalizedKey.Length -gt 100) {
            $normalizedKey = $normalizedKey.Substring(0, 50) + "_" + (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($key)))).Hash.Substring(0, 48)
        }
        
        return $normalizedKey
    }
    
    [void] CleanMemoryCache() {
        # Nettoyer le cache en mÃ©moire si nÃ©cessaire
        if ($this.MemoryCache.Count -gt $this.MaxMemoryItems) {
            # Trier les Ã©lÃ©ments par date d'expiration
            $sortedItems = $this.MemoryCache.GetEnumerator() | Sort-Object { $_.Value.Expiration }
            
            # Supprimer les Ã©lÃ©ments les plus anciens
            $itemsToRemove = $sortedItems | Select-Object -First ($this.MemoryCache.Count - $this.MaxMemoryItems)
            foreach ($item in $itemsToRemove) {
                $this.MemoryCache.Remove($item.Key)
            }
        }
    }
}

# Fonction pour crÃ©er un nouveau cache
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
