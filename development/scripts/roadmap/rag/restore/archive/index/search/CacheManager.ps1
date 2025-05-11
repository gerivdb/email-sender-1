# CacheManager.ps1
# Module de gestion du cache pour les recherches d'archives
# Version: 1.0
# Date: 2025-05-15

# Fonction pour initialiser le cache
function Initialize-ArchiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$CachePath = "$env:TEMP\archive_cache",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxCacheSize = 100, # en Mo
        
        [Parameter(Mandatory = $false)]
        [int]$CacheExpirationHours = 24
    )
    
    # Creer le repertoire de cache s'il n'existe pas
    if (-not (Test-Path -Path $CachePath -PathType Container)) {
        try {
            New-Item -Path $CachePath -ItemType Directory -Force | Out-Null
            Write-Verbose "Repertoire de cache cree: $CachePath"
        }
        catch {
            Write-Error "Erreur lors de la creation du repertoire de cache: $($_.Exception.Message)"
            return $false
        }
    }
    
    # Creer le fichier de configuration du cache
    $cacheConfig = @{
        CachePath = $CachePath
        MaxCacheSize = $MaxCacheSize
        CacheExpirationHours = $CacheExpirationHours
        LastCleanup = [DateTime]::Now.ToString("o")
        CreatedAt = [DateTime]::Now.ToString("o")
    }
    
    try {
        $cacheConfig | ConvertTo-Json | Set-Content -Path "$CachePath\config.json" -Force
        Write-Verbose "Configuration du cache creee: $CachePath\config.json"
    }
    catch {
        Write-Error "Erreur lors de la creation de la configuration du cache: $($_.Exception.Message)"
        return $false
    }
    
    # Nettoyer le cache
    Clear-ArchiveCache -CachePath $CachePath -RemoveExpiredOnly
    
    return $true
}

# Fonction pour nettoyer le cache
function Clear-ArchiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$CachePath = "$env:TEMP\archive_cache",
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveAll,
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveExpiredOnly
    )
    
    # Verifier si le repertoire de cache existe
    if (-not (Test-Path -Path $CachePath -PathType Container)) {
        Write-Warning "Le repertoire de cache n'existe pas: $CachePath"
        return $false
    }
    
    # Charger la configuration du cache
    $cacheConfig = $null
    
    if (Test-Path -Path "$CachePath\config.json") {
        try {
            $cacheConfig = Get-Content -Path "$CachePath\config.json" -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Erreur lors du chargement de la configuration du cache: $($_.Exception.Message)"
            # Continuer avec les valeurs par defaut
        }
    }
    
    # Utiliser les valeurs par defaut si la configuration n'est pas disponible
    if ($null -eq $cacheConfig) {
        $cacheConfig = @{
            MaxCacheSize = 100 # en Mo
            CacheExpirationHours = 24
        }
    }
    
    # Si RemoveAll est specifie, supprimer tous les fichiers de cache
    if ($RemoveAll) {
        try {
            Get-ChildItem -Path $CachePath -File -Exclude "config.json" | Remove-Item -Force
            Write-Verbose "Tous les fichiers de cache ont ete supprimes"
            
            # Mettre a jour la date de dernier nettoyage
            $cacheConfig.LastCleanup = [DateTime]::Now.ToString("o")
            $cacheConfig | ConvertTo-Json | Set-Content -Path "$CachePath\config.json" -Force
            
            return $true
        }
        catch {
            Write-Error "Erreur lors de la suppression des fichiers de cache: $($_.Exception.Message)"
            return $false
        }
    }
    
    # Si RemoveExpiredOnly est specifie, supprimer uniquement les fichiers expires
    if ($RemoveExpiredOnly) {
        try {
            $expirationDate = [DateTime]::Now.AddHours(-$cacheConfig.CacheExpirationHours)
            $expiredFiles = Get-ChildItem -Path $CachePath -File -Exclude "config.json" | 
                Where-Object { $_.LastWriteTime -lt $expirationDate }
            
            foreach ($file in $expiredFiles) {
                Remove-Item -Path $file.FullName -Force
                Write-Verbose "Fichier de cache expire supprime: $($file.Name)"
            }
            
            Write-Verbose "$($expiredFiles.Count) fichiers de cache expires ont ete supprimes"
            
            # Mettre a jour la date de dernier nettoyage
            $cacheConfig.LastCleanup = [DateTime]::Now.ToString("o")
            $cacheConfig | ConvertTo-Json | Set-Content -Path "$CachePath\config.json" -Force
            
            # Verifier la taille du cache
            $cacheSize = (Get-ChildItem -Path $CachePath -File -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
            
            if ($cacheSize -gt $cacheConfig.MaxCacheSize) {
                # Supprimer les fichiers les plus anciens jusqu'a ce que la taille du cache soit inferieure a la limite
                $files = Get-ChildItem -Path $CachePath -File -Exclude "config.json" | Sort-Object LastWriteTime
                
                foreach ($file in $files) {
                    Remove-Item -Path $file.FullName -Force
                    Write-Verbose "Fichier de cache supprime pour reduire la taille du cache: $($file.Name)"
                    
                    $cacheSize = (Get-ChildItem -Path $CachePath -File -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
                    
                    if ($cacheSize -le $cacheConfig.MaxCacheSize) {
                        break
                    }
                }
                
                Write-Verbose "Taille du cache reduite a $([Math]::Round($cacheSize, 2)) Mo"
            }
            
            return $true
        }
        catch {
            Write-Error "Erreur lors de la suppression des fichiers de cache expires: $($_.Exception.Message)"
            return $false
        }
    }
    
    return $true
}

# Fonction pour sauvegarder des donnees dans le cache
function Save-ArchiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Data,
        
        [Parameter(Mandatory = $false)]
        [string]$CachePath = "$env:TEMP\archive_cache",
        
        [Parameter(Mandatory = $false)]
        [int]$ExpirationHours = 0
    )
    
    # Verifier si le repertoire de cache existe
    if (-not (Test-Path -Path $CachePath -PathType Container)) {
        # Initialiser le cache
        if (-not (Initialize-ArchiveCache -CachePath $CachePath)) {
            Write-Error "Impossible d'initialiser le cache"
            return $false
        }
    }
    
    # Generer un nom de fichier a partir de la cle
    $keyHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key))
    $keyHashString = [System.BitConverter]::ToString($keyHash).Replace("-", "").ToLower()
    $cacheFile = "$CachePath\$keyHashString.json"
    
    # Preparer les donnees a sauvegarder
    $cacheData = @{
        Key = $Key
        Data = $Data
        CreatedAt = [DateTime]::Now.ToString("o")
        ExpirationHours = $ExpirationHours
    }
    
    # Sauvegarder les donnees dans le cache
    try {
        $cacheData | ConvertTo-Json -Depth 10 | Set-Content -Path $cacheFile -Force
        Write-Verbose "Donnees sauvegardees dans le cache: $Key"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la sauvegarde des donnees dans le cache: $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour recuperer des donnees du cache
function Get-ArchiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [string]$CachePath = "$env:TEMP\archive_cache",
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreExpiration
    )
    
    # Verifier si le repertoire de cache existe
    if (-not (Test-Path -Path $CachePath -PathType Container)) {
        Write-Verbose "Le repertoire de cache n'existe pas: $CachePath"
        return $null
    }
    
    # Generer un nom de fichier a partir de la cle
    $keyHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key))
    $keyHashString = [System.BitConverter]::ToString($keyHash).Replace("-", "").ToLower()
    $cacheFile = "$CachePath\$keyHashString.json"
    
    # Verifier si le fichier de cache existe
    if (-not (Test-Path -Path $cacheFile -PathType Leaf)) {
        Write-Verbose "Le fichier de cache n'existe pas: $cacheFile"
        return $null
    }
    
    # Charger les donnees du cache
    try {
        $cacheData = Get-Content -Path $cacheFile -Raw | ConvertFrom-Json
        
        # Verifier si les donnees sont expirees
        if (-not $IgnoreExpiration -and $cacheData.ExpirationHours -gt 0) {
            $createdAt = [DateTime]::Parse($cacheData.CreatedAt)
            $expirationDate = $createdAt.AddHours($cacheData.ExpirationHours)
            
            if ([DateTime]::Now -gt $expirationDate) {
                Write-Verbose "Les donnees du cache sont expirees: $Key"
                Remove-Item -Path $cacheFile -Force
                return $null
            }
        }
        
        Write-Verbose "Donnees recuperees du cache: $Key"
        return $cacheData.Data
    }
    catch {
        Write-Error "Erreur lors de la recuperation des donnees du cache: $($_.Exception.Message)"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ArchiveCache, Clear-ArchiveCache, Save-ArchiveCache, Get-ArchiveCache
