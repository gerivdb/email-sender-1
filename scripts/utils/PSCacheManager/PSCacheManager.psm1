<#
.SYNOPSIS
    Module de gestion de cache optimisé pour PowerShell 5.1
.DESCRIPTION
    Ce module fournit des fonctionnalités avancées de mise en cache pour améliorer
    les performances des scripts PowerShell, avec support pour le cache en mémoire
    et sur disque, des politiques d'expiration intelligentes et une gestion optimisée
    des ressources.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 09/04/2023
    Compatibilité: PowerShell 5.1 et supérieur
#>

#region Classes

# Classe pour stocker les éléments de cache avec métadonnées
class CacheItem {
    [object]$Value
    [datetime]$Created
    [datetime]$LastAccess
    [datetime]$Expiration
    [int]$AccessCount
    [string[]]$Tags
    [long]$Size

    CacheItem([object]$value, [int]$ttlSeconds) {
        $this.Value = $value
        $this.Created = Get-Date
        $this.LastAccess = Get-Date
        $this.Expiration = (Get-Date).AddSeconds($ttlSeconds)
        $this.AccessCount = 0
        $this.Tags = @()
        $this.Size = $this.EstimateSize($value)
    }

    [bool] IsExpired() {
        return (Get-Date) -gt $this.Expiration
    }

    [void] UpdateAccess() {
        $this.LastAccess = Get-Date
        $this.AccessCount++
    }

    [void] ExtendExpiration([int]$ttlSeconds) {
        $this.Expiration = (Get-Date).AddSeconds($ttlSeconds)
    }

    [long] EstimateSize([object]$value) {
        if ($null -eq $value) {
            return 0
        }

        try {
            # Estimation approximative de la taille en mémoire
            $json = ConvertTo-Json -InputObject $value -Depth 5 -Compress -ErrorAction SilentlyContinue
            if ($json) {
                return $json.Length * 2  # Approximation pour les objets .NET
            }
            return 100  # Valeur par défaut si la conversion JSON échoue
        }
        catch {
            return 100  # Valeur par défaut en cas d'erreur
        }
    }
}

# Classe principale de gestion de cache
class CacheManager {
    # Stockage principal (mémoire)
    [System.Collections.Concurrent.ConcurrentDictionary[string, CacheItem]]$Items

    # Configuration
    [string]$Name
    [string]$CachePath
    [int]$MaxItems
    [int]$DefaultTTLSeconds
    [bool]$EnableDiskCache
    [bool]$AutoCleanup

    # Statistiques
    [int]$Hits
    [int]$Misses
    [datetime]$LastCleanup

    # Constructeur
    CacheManager([string]$name, [string]$cachePath, [int]$maxItems, [int]$defaultTTL, [bool]$enableDiskCache) {
        $this.Name = $name
        $this.CachePath = $cachePath
        $this.MaxItems = $maxItems
        $this.DefaultTTLSeconds = $defaultTTL
        $this.EnableDiskCache = $enableDiskCache
        $this.AutoCleanup = $true
        $this.Items = [System.Collections.Concurrent.ConcurrentDictionary[string, CacheItem]]::new()
        $this.Hits = 0
        $this.Misses = 0
        $this.LastCleanup = Get-Date

        # Créer le répertoire de cache si nécessaire et s'il est activé
        if ($this.EnableDiskCache -and -not (Test-Path -Path $this.CachePath)) {
            New-Item -Path $this.CachePath -ItemType Directory -Force | Out-Null
        }

        # Charger le cache persistant si activé
        if ($this.EnableDiskCache) {
            $this.LoadPersistentCache()
        }
    }

    # Méthodes principales
    [object] Get([string]$key) {
        # Vérifier si l'élément existe en mémoire
        if ($this.Items.ContainsKey($key)) {
            $item = $this.Items[$key]

            # Vérifier si l'élément est expiré
            if (-not $item.IsExpired()) {
                # Mettre à jour les statistiques d'accès
                $item.UpdateAccess()
                $this.Hits++

                return $item.Value
            }
            else {
                # Élément expiré, le supprimer
                $this.Remove($key)
            }
        }

        # Si l'élément n'est pas en mémoire mais que le cache disque est activé, essayer de le charger
        if ($this.EnableDiskCache) {
            $diskItem = $this.LoadFromDisk($key)
            if ($null -ne $diskItem) {
                # Vérifier si l'élément chargé du disque est expiré
                if (-not $diskItem.IsExpired()) {
                    # Ajouter l'élément au cache mémoire
                    $this.Items[$key] = $diskItem
                    $diskItem.UpdateAccess()
                    $this.Hits++

                    return $diskItem.Value
                }
                else {
                    # Supprimer l'élément expiré du disque
                    $this.RemoveFromDisk($key)
                }
            }
        }

        $this.Misses++
        return $null
    }

    [void] Set([string]$key, [object]$value, [int]$ttlSeconds = 0, [string[]]$tags = @()) {
        # Nettoyer si nécessaire avant d'ajouter
        if ($this.AutoCleanup -and $this.Items.Count -ge $this.MaxItems) {
            $this.CleanCache()
        }

        # Définir le TTL
        if ($ttlSeconds -le 0) {
            $ttlSeconds = $this.DefaultTTLSeconds
        }

        # Créer l'élément de cache
        $item = [CacheItem]::new($value, $ttlSeconds)
        $item.Tags = $tags

        # Stocker l'élément en mémoire
        $this.Items[$key] = $item

        # Persister sur disque si activé et si la taille le justifie
        if ($this.EnableDiskCache -and $item.Size -gt 1KB) {
            $this.SaveToDisk($key, $item)
        }
    }

    [void] Remove([string]$key) {
        $null = $this.Items.TryRemove($key, [ref]$null)

        # Supprimer du stockage persistant si activé
        if ($this.EnableDiskCache) {
            $this.RemoveFromDisk($key)
        }
    }

    [void] RemoveByTag([string]$tag) {
        $keysToRemove = $this.Items.GetEnumerator() |
            Where-Object { $_.Value.Tags -contains $tag } |
            Select-Object -ExpandProperty Key

        foreach ($key in $keysToRemove) {
            $this.Remove($key)
        }
    }

    [void] RemoveByPattern([string]$pattern) {
        $keysToRemove = $this.Items.Keys | Where-Object { $_ -match $pattern }

        foreach ($key in $keysToRemove) {
            $this.Remove($key)
        }
    }

    # Méthodes de gestion du cache
    [void] CleanCache() {
        # Stratégie LRU - supprimer les 20% les moins récemment utilisés
        $itemsToRemove = $this.Items.GetEnumerator() |
            Sort-Object { $_.Value.LastAccess } |
            Select-Object -First ([math]::Ceiling($this.Items.Count * 0.2))

        foreach ($item in $itemsToRemove) {
            $this.Remove($item.Key)
        }

        $this.LastCleanup = Get-Date
    }

    [void] ClearExpired() {
        $expiredKeys = $this.Items.GetEnumerator() |
            Where-Object { $_.Value.IsExpired() } |
            Select-Object -ExpandProperty Key

        foreach ($key in $expiredKeys) {
            $this.Remove($key)
        }
    }

    [void] Clear() {
        $this.Items.Clear()

        # Nettoyer le stockage persistant si activé
        if ($this.EnableDiskCache) {
            Get-ChildItem -Path $this.CachePath -Filter "*.cache" -File | Remove-Item -Force
        }

        # Réinitialiser les statistiques
        $this.Hits = 0
        $this.Misses = 0
    }

    # Méthodes de persistance
    [void] SaveToDisk([string]$key, [CacheItem]$item) {
        if (-not $this.EnableDiskCache) {
            return
        }

        $persistPath = Join-Path -Path $this.CachePath -ChildPath "$key.cache"

        try {
            # Sérialiser
            $json = ConvertTo-Json -InputObject $item -Depth 10 -Compress

            # Écrire sur le disque
            [System.IO.File]::WriteAllText($persistPath, $json, [System.Text.Encoding]::UTF8)
        }
        catch {
            Write-Warning "Impossible de sauvegarder l'élément de cache '$key' sur le disque: $_"
        }
    }

    [CacheItem] LoadFromDisk([string]$key) {
        if (-not $this.EnableDiskCache) {
            return $null
        }

        $persistPath = Join-Path -Path $this.CachePath -ChildPath "$key.cache"

        if (-not (Test-Path -Path $persistPath)) {
            return $null
        }

        try {
            # Lire du disque
            $json = [System.IO.File]::ReadAllText($persistPath, [System.Text.Encoding]::UTF8)

            # Désérialiser
            $item = ConvertFrom-Json -InputObject $json

            # Convertir en objet CacheItem
            $cacheItem = [CacheItem]::new($item.Value, 0)
            $cacheItem.Created = [datetime]$item.Created
            $cacheItem.LastAccess = [datetime]$item.LastAccess
            $cacheItem.Expiration = [datetime]$item.Expiration
            $cacheItem.AccessCount = [int]$item.AccessCount
            $cacheItem.Tags = $item.Tags
            $cacheItem.Size = [long]$item.Size

            return $cacheItem
        }
        catch {
            Write-Warning "Impossible de charger l'élément de cache '$key' depuis le disque: $_"
            # Supprimer le fichier corrompu
            Remove-Item -Path $persistPath -Force -ErrorAction SilentlyContinue
            return $null
        }
    }

    [void] RemoveFromDisk([string]$key) {
        if (-not $this.EnableDiskCache) {
            return
        }

        $persistPath = Join-Path -Path $this.CachePath -ChildPath "$key.cache"

        if (Test-Path -Path $persistPath) {
            Remove-Item -Path $persistPath -Force -ErrorAction SilentlyContinue
        }
    }

    [void] LoadPersistentCache() {
        if (-not $this.EnableDiskCache) {
            return
        }

        $cacheFiles = Get-ChildItem -Path $this.CachePath -Filter "*.cache" -File

        foreach ($file in $cacheFiles) {
            try {
                $key = $file.BaseName
                $item = $this.LoadFromDisk($key)

                if ($null -ne $item -and -not $item.IsExpired()) {
                    $this.Items[$key] = $item
                }
                else {
                    # Supprimer le fichier s'il est expiré
                    Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                }
            }
            catch {
                # Ignorer les fichiers corrompus
                Write-Warning "Impossible de charger le cache $($file.Name): $_"
            }
        }
    }

    # Méthodes de statistiques
    [hashtable] GetStatistics() {
        $totalSize = ($this.Items.Values | Measure-Object -Property Size -Sum).Sum
        $expiredCount = ($this.Items.Values | Where-Object { $_.IsExpired() } | Measure-Object).Count

        return @{
            Name = $this.Name
            ItemCount = $this.Items.Count
            ExpiredCount = $expiredCount
            TotalSize = $totalSize
            Hits = $this.Hits
            Misses = $this.Misses
            HitRatio = if (($this.Hits + $this.Misses) -gt 0) { $this.Hits / ($this.Hits + $this.Misses) } else { 0 }
            LastCleanup = $this.LastCleanup
            DiskCacheEnabled = $this.EnableDiskCache
            CachePath = $this.CachePath
        }
    }
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Crée un nouveau gestionnaire de cache.
.DESCRIPTION
    Cette fonction crée un nouveau gestionnaire de cache avec les paramètres spécifiés.
.PARAMETER Name
    Nom du cache. Utilisé pour identifier le cache et comme nom de dossier par défaut.
.PARAMETER CachePath
    Chemin vers le répertoire de cache sur disque. Par défaut, utilise un sous-répertoire dans %TEMP%.
.PARAMETER MaxItems
    Nombre maximum d'éléments à conserver en mémoire. Par défaut, 1000.
.PARAMETER DefaultTTLSeconds
    Durée de vie par défaut des éléments en secondes. Par défaut, 3600 (1 heure).
.PARAMETER EnableDiskCache
    Active ou désactive le cache sur disque. Par défaut, $true.
.EXAMPLE
    $cache = New-PSCache -Name "ScriptAnalysis" -MaxItems 500
.OUTPUTS
    CacheManager
#>
function New-PSCache {
    [CmdletBinding()]
    [OutputType([CacheManager])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name = "DefaultCache",

        [Parameter(Mandatory = $false)]
        [string]$CachePath = (Join-Path -Path $env:TEMP -ChildPath "PSCacheManager\$Name"),

        [Parameter(Mandatory = $false)]
        [int]$MaxItems = 1000,

        [Parameter(Mandatory = $false)]
        [int]$DefaultTTLSeconds = 3600,

        [Parameter(Mandatory = $false)]
        [bool]$EnableDiskCache = $true
    )

    return [CacheManager]::new($Name, $CachePath, $MaxItems, $DefaultTTLSeconds, $EnableDiskCache)
}

<#
.SYNOPSIS
    Récupère un élément du cache.
.DESCRIPTION
    Cette fonction récupère un élément du cache en utilisant la clé spécifiée.
    Si l'élément n'existe pas et qu'un scriptblock est fourni, il sera exécuté
    pour générer la valeur, qui sera ensuite mise en cache.
.PARAMETER Cache
    Le gestionnaire de cache à utiliser.
.PARAMETER Key
    La clé de l'élément à récupérer.
.PARAMETER GenerateValue
    Un scriptblock à exécuter pour générer la valeur si elle n'existe pas dans le cache.
.PARAMETER TTLSeconds
    Durée de vie de l'élément en secondes, si généré. Par défaut, utilise la valeur du cache.
.PARAMETER Tags
    Tags à associer à l'élément, si généré.
.EXAMPLE
    $result = Get-PSCacheItem -Cache $cache -Key "MyKey" -GenerateValue { Get-Something }
.OUTPUTS
    Object
#>
function Get-PSCacheItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [CacheManager]$Cache,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [scriptblock]$GenerateValue,

        [Parameter(Mandatory = $false)]
        [int]$TTLSeconds = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @()
    )

    $value = $Cache.Get($Key)

    if ($null -eq $value -and $null -ne $GenerateValue) {
        # Valeur non trouvée, la générer
        $value = & $GenerateValue

        if ($null -ne $value) {
            # Mettre en cache la nouvelle valeur
            $Cache.Set($Key, $value, $TTLSeconds, $Tags)
        }
    }

    return $value
}

<#
.SYNOPSIS
    Ajoute ou met à jour un élément dans le cache.
.DESCRIPTION
    Cette fonction ajoute ou met à jour un élément dans le cache avec la clé et la valeur spécifiées.
.PARAMETER Cache
    Le gestionnaire de cache à utiliser.
.PARAMETER Key
    La clé de l'élément à ajouter ou mettre à jour.
.PARAMETER Value
    La valeur à mettre en cache.
.PARAMETER TTLSeconds
    Durée de vie de l'élément en secondes. Par défaut, utilise la valeur du cache.
.PARAMETER Tags
    Tags à associer à l'élément.
.EXAMPLE
    Set-PSCacheItem -Cache $cache -Key "MyKey" -Value $result -TTLSeconds 1800
.OUTPUTS
    None
#>
function Set-PSCacheItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [CacheManager]$Cache,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [int]$TTLSeconds = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @()
    )

    $Cache.Set($Key, $Value, $TTLSeconds, $Tags)
}

<#
.SYNOPSIS
    Supprime un ou plusieurs éléments du cache.
.DESCRIPTION
    Cette fonction supprime un ou plusieurs éléments du cache en fonction de la clé,
    du tag ou du pattern spécifié.
.PARAMETER Cache
    Le gestionnaire de cache à utiliser.
.PARAMETER Key
    La clé de l'élément à supprimer.
.PARAMETER Tag
    Le tag des éléments à supprimer.
.PARAMETER Pattern
    Le pattern regex pour les clés des éléments à supprimer.
.EXAMPLE
    Remove-PSCacheItem -Cache $cache -Key "MyKey"
.EXAMPLE
    Remove-PSCacheItem -Cache $cache -Tag "ConfigData"
.EXAMPLE
    Remove-PSCacheItem -Cache $cache -Pattern "^Temp_.*"
.OUTPUTS
    None
#>
function Remove-PSCacheItem {
    [CmdletBinding(DefaultParameterSetName = "ByKey")]
    param (
        [Parameter(Mandatory = $true)]
        [CacheManager]$Cache,

        [Parameter(Mandatory = $true, ParameterSetName = "ByKey")]
        [string]$Key,

        [Parameter(Mandatory = $true, ParameterSetName = "ByTag")]
        [string]$Tag,

        [Parameter(Mandatory = $true, ParameterSetName = "ByPattern")]
        [string]$Pattern
    )

    switch ($PSCmdlet.ParameterSetName) {
        "ByKey" {
            $Cache.Remove($Key)
        }
        "ByTag" {
            $Cache.RemoveByTag($Tag)
        }
        "ByPattern" {
            $Cache.RemoveByPattern($Pattern)
        }
    }
}

<#
.SYNOPSIS
    Obtient les statistiques du cache.
.DESCRIPTION
    Cette fonction retourne les statistiques du cache spécifié.
.PARAMETER Cache
    Le gestionnaire de cache à utiliser.
.EXAMPLE
    Get-PSCacheStatistics -Cache $cache
.OUTPUTS
    Hashtable
#>
function Get-PSCacheStatistics {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [CacheManager]$Cache
    )

    return $Cache.GetStatistics()
}

<#
.SYNOPSIS
    Nettoie le cache.
.DESCRIPTION
    Cette fonction nettoie le cache en supprimant les éléments expirés ou tous les éléments.
.PARAMETER Cache
    Le gestionnaire de cache à utiliser.
.PARAMETER ExpiredOnly
    Si spécifié, supprime uniquement les éléments expirés. Sinon, supprime tous les éléments.
.EXAMPLE
    Clear-PSCache -Cache $cache -ExpiredOnly
.OUTPUTS
    None
#>
function Clear-PSCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [CacheManager]$Cache,

        [Parameter(Mandatory = $false)]
        [switch]$ExpiredOnly
    )

    if ($ExpiredOnly) {
        $Cache.ClearExpired()
    }
    else {
        $Cache.Clear()
    }
}

#endregion

#region Exportation des fonctions

# Exporter les fonctions publiques
Export-ModuleMember -Function New-PSCache, Get-PSCacheItem, Set-PSCacheItem, Remove-PSCacheItem, Get-PSCacheStatistics, Clear-PSCache

#endregion
