<#
.SYNOPSIS
    Module pour la mise en cache des résultats de sélection du noyau optimal pour l'estimation de densité par noyau.

.DESCRIPTION
    Ce module implémente les fonctions nécessaires pour la mise en cache des résultats de sélection
    du noyau optimal pour l'estimation de densité par noyau. Il permet de stocker les résultats
    de sélection pour éviter de recalculer les mêmes résultats plusieurs fois.

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-17
#>

# Importer le module de configuration
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\KernelSelectionConfig.ps1"

# Cache pour les résultats de sélection du noyau optimal
$script:KernelSelectionCache = @{
    # Cache pour la sélection basée sur les caractéristiques des données
    Characteristics = @{}
    
    # Cache pour la sélection basée sur la validation croisée
    CrossValidation = @{}
    
    # Statistiques du cache
    Stats = @{
        Hits        = 0
        Misses      = 0
        Evictions   = 0
        LastCleanup = [DateTime]::Now
    }
}

<#
.SYNOPSIS
    Génère une clé de cache pour les données.

.DESCRIPTION
    Cette fonction génère une clé de cache pour les données en calculant un hachage SHA256.
    La clé est utilisée pour identifier de manière unique un ensemble de données.

.PARAMETER Data
    Les données pour lesquelles générer une clé de cache.

.PARAMETER AdditionalParams
    Paramètres supplémentaires à inclure dans la clé de cache.

.EXAMPLE
    Get-CacheKey -Data $data
    Génère une clé de cache pour les données spécifiées.

.EXAMPLE
    Get-CacheKey -Data $data -AdditionalParams @{ KernelType = "Gaussian"; Bandwidth = 1.0 }
    Génère une clé de cache pour les données spécifiées avec des paramètres supplémentaires.

.OUTPUTS
    System.String
#>
function Get-CacheKey {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalParams = @{}
    )
    
    # Convertir les données en chaîne de caractères
    $dataString = $Data -join ","
    
    # Convertir les paramètres supplémentaires en chaîne de caractères
    $paramsString = ""
    foreach ($key in $AdditionalParams.Keys | Sort-Object) {
        $paramsString += "$key=$($AdditionalParams[$key]);"
    }
    
    # Combiner les données et les paramètres
    $combinedString = $dataString + "|" + $paramsString
    
    # Calculer le hachage SHA256
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($combinedString))
    $hashString = [BitConverter]::ToString($hashBytes) -replace "-", ""
    
    return $hashString
}

<#
.SYNOPSIS
    Obtient un résultat de sélection du noyau optimal depuis le cache.

.DESCRIPTION
    Cette fonction obtient un résultat de sélection du noyau optimal depuis le cache.
    Si le résultat n'est pas dans le cache, elle retourne $null.

.PARAMETER Data
    Les données pour lesquelles obtenir le résultat de sélection.

.PARAMETER SelectionMethod
    La méthode de sélection utilisée (par défaut "Characteristics").
    - "Characteristics": Sélection basée sur les caractéristiques des données
    - "CrossValidation": Sélection basée sur la validation croisée

.PARAMETER AdditionalParams
    Paramètres supplémentaires à inclure dans la clé de cache.

.EXAMPLE
    Get-KernelSelectionCacheResult -Data $data
    Obtient le résultat de sélection pour les données spécifiées en utilisant la méthode de sélection par défaut.

.EXAMPLE
    Get-KernelSelectionCacheResult -Data $data -SelectionMethod "CrossValidation" -AdditionalParams @{ ValidationMethod = "KFold"; K = 5 }
    Obtient le résultat de sélection pour les données spécifiées en utilisant la méthode de sélection par validation croisée.

.OUTPUTS
    System.String
#>
function Get-KernelSelectionCacheResult {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Characteristics", "CrossValidation")]
        [string]$SelectionMethod = "Characteristics",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalParams = @{}
    )
    
    # Vérifier si la mise en cache est activée
    $config = Get-KernelSelectionConfig
    if (-not $config.Cache.Enabled) {
        return $null
    }
    
    # Générer la clé de cache
    $cacheKey = Get-CacheKey -Data $Data -AdditionalParams $AdditionalParams
    
    # Vérifier si le résultat est dans le cache
    if ($script:KernelSelectionCache[$SelectionMethod].ContainsKey($cacheKey)) {
        $cacheEntry = $script:KernelSelectionCache[$SelectionMethod][$cacheKey]
        
        # Vérifier si l'entrée de cache a expiré
        if ([DateTime]::Now -lt $cacheEntry.ExpirationTime) {
            # Incrémenter le compteur de hits
            $script:KernelSelectionCache.Stats.Hits++
            
            return $cacheEntry.Result
        } else {
            # Supprimer l'entrée de cache expirée
            $script:KernelSelectionCache[$SelectionMethod].Remove($cacheKey)
            
            # Incrémenter le compteur d'évictions
            $script:KernelSelectionCache.Stats.Evictions++
        }
    }
    
    # Incrémenter le compteur de misses
    $script:KernelSelectionCache.Stats.Misses++
    
    return $null
}

<#
.SYNOPSIS
    Ajoute un résultat de sélection du noyau optimal au cache.

.DESCRIPTION
    Cette fonction ajoute un résultat de sélection du noyau optimal au cache.
    Elle gère également la taille du cache en supprimant les entrées les plus anciennes
    si le cache dépasse la taille maximale.

.PARAMETER Data
    Les données pour lesquelles ajouter le résultat de sélection.

.PARAMETER Result
    Le résultat de sélection à ajouter au cache.

.PARAMETER SelectionMethod
    La méthode de sélection utilisée (par défaut "Characteristics").
    - "Characteristics": Sélection basée sur les caractéristiques des données
    - "CrossValidation": Sélection basée sur la validation croisée

.PARAMETER AdditionalParams
    Paramètres supplémentaires à inclure dans la clé de cache.

.EXAMPLE
    Add-KernelSelectionCacheResult -Data $data -Result "Gaussian"
    Ajoute le résultat de sélection "Gaussian" pour les données spécifiées en utilisant la méthode de sélection par défaut.

.EXAMPLE
    Add-KernelSelectionCacheResult -Data $data -Result "Epanechnikov" -SelectionMethod "CrossValidation" -AdditionalParams @{ ValidationMethod = "KFold"; K = 5 }
    Ajoute le résultat de sélection "Epanechnikov" pour les données spécifiées en utilisant la méthode de sélection par validation croisée.

.OUTPUTS
    None
#>
function Add-KernelSelectionCacheResult {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,
        
        [Parameter(Mandatory = $true)]
        [string]$Result,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Characteristics", "CrossValidation")]
        [string]$SelectionMethod = "Characteristics",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalParams = @{}
    )
    
    # Vérifier si la mise en cache est activée
    $config = Get-KernelSelectionConfig
    if (-not $config.Cache.Enabled) {
        return
    }
    
    # Générer la clé de cache
    $cacheKey = Get-CacheKey -Data $Data -AdditionalParams $AdditionalParams
    
    # Calculer le temps d'expiration
    $expirationTime = [DateTime]::Now.AddSeconds($config.Cache.ExpirationTime)
    
    # Ajouter le résultat au cache
    $script:KernelSelectionCache[$SelectionMethod][$cacheKey] = @{
        Result         = $Result
        ExpirationTime = $expirationTime
        CreationTime   = [DateTime]::Now
    }
    
    # Nettoyer le cache si nécessaire
    if ($script:KernelSelectionCache[$SelectionMethod].Count -gt $config.Cache.MaxCacheSize) {
        # Supprimer les entrées les plus anciennes
        $entriesToRemove = $script:KernelSelectionCache[$SelectionMethod].GetEnumerator() |
            Sort-Object -Property { $_.Value.CreationTime } |
            Select-Object -First ($script:KernelSelectionCache[$SelectionMethod].Count - $config.Cache.MaxCacheSize)
        
        foreach ($entry in $entriesToRemove) {
            $script:KernelSelectionCache[$SelectionMethod].Remove($entry.Key)
            
            # Incrémenter le compteur d'évictions
            $script:KernelSelectionCache.Stats.Evictions++
        }
    }
}

<#
.SYNOPSIS
    Nettoie le cache des résultats de sélection du noyau optimal.

.DESCRIPTION
    Cette fonction nettoie le cache des résultats de sélection du noyau optimal
    en supprimant les entrées expirées.

.EXAMPLE
    Clear-KernelSelectionCache
    Nettoie le cache des résultats de sélection du noyau optimal.

.OUTPUTS
    None
#>
function Clear-KernelSelectionCache {
    [CmdletBinding()]
    param ()
    
    # Vérifier si la mise en cache est activée
    $config = Get-KernelSelectionConfig
    if (-not $config.Cache.Enabled) {
        return
    }
    
    # Nettoyer le cache pour chaque méthode de sélection
    foreach ($selectionMethod in @("Characteristics", "CrossValidation")) {
        # Trouver les entrées expirées
        $expiredEntries = $script:KernelSelectionCache[$selectionMethod].GetEnumerator() |
            Where-Object { [DateTime]::Now -gt $_.Value.ExpirationTime }
        
        # Supprimer les entrées expirées
        foreach ($entry in $expiredEntries) {
            $script:KernelSelectionCache[$selectionMethod].Remove($entry.Key)
            
            # Incrémenter le compteur d'évictions
            $script:KernelSelectionCache.Stats.Evictions++
        }
    }
    
    # Mettre à jour la date du dernier nettoyage
    $script:KernelSelectionCache.Stats.LastCleanup = [DateTime]::Now
}

<#
.SYNOPSIS
    Obtient les statistiques du cache des résultats de sélection du noyau optimal.

.DESCRIPTION
    Cette fonction obtient les statistiques du cache des résultats de sélection du noyau optimal,
    telles que le nombre de hits, de misses, d'évictions, etc.

.EXAMPLE
    Get-KernelSelectionCacheStats
    Obtient les statistiques du cache des résultats de sélection du noyau optimal.

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-KernelSelectionCacheStats {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param ()
    
    # Calculer les statistiques supplémentaires
    $characteristicsCount = $script:KernelSelectionCache.Characteristics.Count
    $crossValidationCount = $script:KernelSelectionCache.CrossValidation.Count
    $totalCount = $characteristicsCount + $crossValidationCount
    
    $hitRate = 0
    $totalRequests = $script:KernelSelectionCache.Stats.Hits + $script:KernelSelectionCache.Stats.Misses
    if ($totalRequests -gt 0) {
        $hitRate = $script:KernelSelectionCache.Stats.Hits / $totalRequests
    }
    
    # Retourner les statistiques
    return @{
        Hits                = $script:KernelSelectionCache.Stats.Hits
        Misses              = $script:KernelSelectionCache.Stats.Misses
        Evictions           = $script:KernelSelectionCache.Stats.Evictions
        LastCleanup         = $script:KernelSelectionCache.Stats.LastCleanup
        CharacteristicsCount = $characteristicsCount
        CrossValidationCount = $crossValidationCount
        TotalCount          = $totalCount
        HitRate             = $hitRate
    }
}
