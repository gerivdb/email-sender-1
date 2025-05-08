<#
.SYNOPSIS
    Module de mise en cache des résultats de sélection de la largeur de bande pour l'estimation de densité par noyau (KDE).

.DESCRIPTION
    Ce module fournit des fonctions pour initialiser, gérer et utiliser un cache de résultats de sélection de la largeur de bande.
    Il permet d'accélérer les calculs en évitant de recalculer les mêmes résultats pour des données similaires.

.NOTES
    Ce module est utilisé par les fonctions Get-OptimalBandwidthMethod et Get-KernelDensityEstimation.
#>

# Variable globale pour stocker le cache
$script:BandwidthSelectionCache = $null

<#
.SYNOPSIS
    Initialise le cache de sélection de la largeur de bande.

.DESCRIPTION
    Cette fonction initialise le cache de sélection de la largeur de bande.
    Si le cache existe déjà, il est réinitialisé.

.PARAMETER MaxCacheSize
    La taille maximale du cache (nombre d'entrées).
    Par défaut, le cache peut contenir 100 entrées.

.PARAMETER ExpirationMinutes
    Le délai d'expiration des entrées du cache en minutes.
    Par défaut, les entrées expirent après 60 minutes.

.EXAMPLE
    Initialize-BandwidthSelectionCache -MaxCacheSize 200 -ExpirationMinutes 120
    Initialise le cache avec une capacité de 200 entrées et un délai d'expiration de 2 heures.

.OUTPUTS
    Aucun
#>
function Initialize-BandwidthSelectionCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MaxCacheSize = 100,

        [Parameter(Mandatory = $false)]
        [int]$ExpirationMinutes = 60
    )

    # Créer le cache s'il n'existe pas
    if ($null -eq $script:BandwidthSelectionCache) {
        $script:BandwidthSelectionCache = @{
            Entries = @{}
            MaxSize = $MaxCacheSize
            ExpirationMinutes = $ExpirationMinutes
            Stats = @{
                Hits = 0
                Misses = 0
                Additions = 0
                Evictions = 0
                Expirations = 0
            }
            LastCleanup = Get-Date
        }
    }
    else {
        # Réinitialiser le cache existant
        $script:BandwidthSelectionCache.Entries = @{}
        $script:BandwidthSelectionCache.MaxSize = $MaxCacheSize
        $script:BandwidthSelectionCache.ExpirationMinutes = $ExpirationMinutes
        $script:BandwidthSelectionCache.Stats = @{
            Hits = 0
            Misses = 0
            Additions = 0
            Evictions = 0
            Expirations = 0
        }
        $script:BandwidthSelectionCache.LastCleanup = Get-Date
    }

    Write-Verbose "Cache de sélection de la largeur de bande initialisé (taille max: $MaxCacheSize, expiration: $ExpirationMinutes min)"
}

<#
.SYNOPSIS
    Génère une clé de cache pour les données et les paramètres spécifiés.

.DESCRIPTION
    Cette fonction génère une clé de cache unique pour les données et les paramètres spécifiés.
    La clé est basée sur un hachage des données et des paramètres.

.PARAMETER Data
    Les données pour lesquelles générer une clé de cache.

.PARAMETER Parameters
    Les paramètres supplémentaires à inclure dans la clé de cache.

.EXAMPLE
    $key = Get-CacheKey -Data $data -Parameters @{KernelType = "Gaussian"; Objective = "Balanced"}
    Génère une clé de cache pour les données spécifiées et les paramètres supplémentaires.

.OUTPUTS
    String
#>
function Get-CacheKey {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Calculer des statistiques de base sur les données pour créer une empreinte
    $count = $Data.Count
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    $mean = ($Data | Measure-Object -Average).Average
    $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
    
    # Calculer des statistiques supplémentaires pour améliorer l'unicité de la clé
    $sortedData = $Data | Sort-Object
    $median = if ($count % 2 -eq 0) { ($sortedData[$count / 2 - 1] + $sortedData[$count / 2]) / 2 } else { $sortedData[($count - 1) / 2] }
    $q1 = $sortedData[[Math]::Floor($count * 0.25)]
    $q3 = $sortedData[[Math]::Floor($count * 0.75)]
    
    # Créer une chaîne représentant les données
    $dataString = "C:$count|Min:$min|Max:$max|Mean:$mean|StdDev:$stdDev|Med:$median|Q1:$q1|Q3:$q3"
    
    # Ajouter les paramètres à la chaîne
    $paramString = $Parameters.GetEnumerator() | Sort-Object -Property Key | ForEach-Object { "$($_.Key):$($_.Value)" } | Join-String -Separator "|"
    
    # Combiner les chaînes et calculer un hachage
    $combinedString = "$dataString|$paramString"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($combinedString)
    $hashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $hashAlgorithm.ComputeHash($bytes)
    $hash = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
    
    return $hash
}

<#
.SYNOPSIS
    Ajoute un résultat au cache de sélection de la largeur de bande.

.DESCRIPTION
    Cette fonction ajoute un résultat au cache de sélection de la largeur de bande.
    Si le cache est plein, l'entrée la plus ancienne est supprimée.

.PARAMETER Key
    La clé de cache pour le résultat.

.PARAMETER Result
    Le résultat à ajouter au cache.

.EXAMPLE
    Add-CacheEntry -Key $key -Result $result
    Ajoute le résultat spécifié au cache avec la clé spécifiée.

.OUTPUTS
    Aucun
#>
function Add-CacheEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [object]$Result
    )

    # Initialiser le cache s'il n'existe pas
    if ($null -eq $script:BandwidthSelectionCache) {
        Initialize-BandwidthSelectionCache
    }

    # Vérifier si le cache est plein
    if ($script:BandwidthSelectionCache.Entries.Count -ge $script:BandwidthSelectionCache.MaxSize) {
        # Supprimer l'entrée la plus ancienne
        $oldestKey = $script:BandwidthSelectionCache.Entries.Keys | 
            Sort-Object { $script:BandwidthSelectionCache.Entries[$_].Timestamp } | 
            Select-Object -First 1
        
        $script:BandwidthSelectionCache.Entries.Remove($oldestKey)
        $script:BandwidthSelectionCache.Stats.Evictions++
        
        Write-Verbose "Cache plein, suppression de l'entrée la plus ancienne"
    }

    # Ajouter la nouvelle entrée
    $script:BandwidthSelectionCache.Entries[$Key] = @{
        Result = $Result
        Timestamp = Get-Date
    }
    
    $script:BandwidthSelectionCache.Stats.Additions++
    
    Write-Verbose "Entrée ajoutée au cache (clé: $Key)"
}

<#
.SYNOPSIS
    Récupère un résultat du cache de sélection de la largeur de bande.

.DESCRIPTION
    Cette fonction récupère un résultat du cache de sélection de la largeur de bande.
    Si la clé n'existe pas dans le cache ou si l'entrée a expiré, la fonction retourne $null.

.PARAMETER Key
    La clé de cache pour le résultat à récupérer.

.EXAMPLE
    $result = Get-CacheEntry -Key $key
    Récupère le résultat associé à la clé spécifiée.

.OUTPUTS
    Object ou $null
#>
function Get-CacheEntry {
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    # Initialiser le cache s'il n'existe pas
    if ($null -eq $script:BandwidthSelectionCache) {
        Initialize-BandwidthSelectionCache
        $script:BandwidthSelectionCache.Stats.Misses++
        return $null
    }

    # Vérifier si la clé existe dans le cache
    if (-not $script:BandwidthSelectionCache.Entries.ContainsKey($Key)) {
        $script:BandwidthSelectionCache.Stats.Misses++
        Write-Verbose "Cache miss (clé: $Key)"
        return $null
    }

    # Vérifier si l'entrée a expiré
    $entry = $script:BandwidthSelectionCache.Entries[$Key]
    $expirationTime = $entry.Timestamp.AddMinutes($script:BandwidthSelectionCache.ExpirationMinutes)
    
    if ((Get-Date) -gt $expirationTime) {
        # Supprimer l'entrée expirée
        $script:BandwidthSelectionCache.Entries.Remove($Key)
        $script:BandwidthSelectionCache.Stats.Expirations++
        $script:BandwidthSelectionCache.Stats.Misses++
        
        Write-Verbose "Entrée expirée (clé: $Key)"
        return $null
    }

    # Mettre à jour le timestamp pour prolonger la durée de vie de l'entrée
    $entry.Timestamp = Get-Date
    
    $script:BandwidthSelectionCache.Stats.Hits++
    Write-Verbose "Cache hit (clé: $Key)"
    
    return $entry.Result
}

<#
.SYNOPSIS
    Nettoie le cache de sélection de la largeur de bande.

.DESCRIPTION
    Cette fonction supprime les entrées expirées du cache de sélection de la largeur de bande.

.EXAMPLE
    Clear-ExpiredCacheEntries
    Supprime toutes les entrées expirées du cache.

.OUTPUTS
    Aucun
#>
function Clear-ExpiredCacheEntries {
    [CmdletBinding()]
    param ()

    # Initialiser le cache s'il n'existe pas
    if ($null -eq $script:BandwidthSelectionCache) {
        Initialize-BandwidthSelectionCache
        return
    }

    # Calculer le temps d'expiration
    $now = Get-Date
    $expirationMinutes = $script:BandwidthSelectionCache.ExpirationMinutes
    
    # Identifier les clés expirées
    $expiredKeys = $script:BandwidthSelectionCache.Entries.Keys | 
        Where-Object { 
            $entry = $script:BandwidthSelectionCache.Entries[$_]
            $expirationTime = $entry.Timestamp.AddMinutes($expirationMinutes)
            $now -gt $expirationTime
        }
    
    # Supprimer les entrées expirées
    foreach ($key in $expiredKeys) {
        $script:BandwidthSelectionCache.Entries.Remove($key)
        $script:BandwidthSelectionCache.Stats.Expirations++
    }
    
    # Mettre à jour le timestamp du dernier nettoyage
    $script:BandwidthSelectionCache.LastCleanup = $now
    
    Write-Verbose "Nettoyage du cache terminé (entrées supprimées: $($expiredKeys.Count))"
}

<#
.SYNOPSIS
    Obtient les statistiques du cache de sélection de la largeur de bande.

.DESCRIPTION
    Cette fonction retourne les statistiques du cache de sélection de la largeur de bande,
    notamment le nombre d'entrées, le taux de succès, etc.

.EXAMPLE
    $stats = Get-CacheStatistics
    Récupère les statistiques du cache.

.OUTPUTS
    PSCustomObject
#>
function Get-CacheStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    # Initialiser le cache s'il n'existe pas
    if ($null -eq $script:BandwidthSelectionCache) {
        Initialize-BandwidthSelectionCache
    }

    # Calculer le taux de succès
    $totalRequests = $script:BandwidthSelectionCache.Stats.Hits + $script:BandwidthSelectionCache.Stats.Misses
    $hitRate = if ($totalRequests -gt 0) { $script:BandwidthSelectionCache.Stats.Hits / $totalRequests } else { 0 }
    
    # Créer l'objet de statistiques
    $stats = [PSCustomObject]@{
        EntryCount = $script:BandwidthSelectionCache.Entries.Count
        MaxSize = $script:BandwidthSelectionCache.MaxSize
        ExpirationMinutes = $script:BandwidthSelectionCache.ExpirationMinutes
        Hits = $script:BandwidthSelectionCache.Stats.Hits
        Misses = $script:BandwidthSelectionCache.Stats.Misses
        HitRate = $hitRate
        Additions = $script:BandwidthSelectionCache.Stats.Additions
        Evictions = $script:BandwidthSelectionCache.Stats.Evictions
        Expirations = $script:BandwidthSelectionCache.Stats.Expirations
        LastCleanup = $script:BandwidthSelectionCache.LastCleanup
    }
    
    return $stats
}
