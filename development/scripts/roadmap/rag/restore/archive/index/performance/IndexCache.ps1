# IndexCache.ps1
# Script implémentant la mise en cache des résultats de recherche
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$persistencePath = Join-Path -Path $parentPath -ChildPath "persistence"
$recoveryPath = Join-Path -Path $persistencePath -ChildPath "IndexRecovery.ps1"

if (Test-Path -Path $recoveryPath) {
    . $recoveryPath
} else {
    Write-Error "Le fichier IndexRecovery.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une entrée de cache
class CacheEntry {
    # Clé de l'entrée
    [string]$Key
    
    # Valeur de l'entrée
    [object]$Value
    
    # Horodatage de création
    [DateTime]$CreatedAt
    
    # Horodatage de dernier accès
    [DateTime]$LastAccessedAt
    
    # Nombre d'accès
    [int]$AccessCount
    
    # Durée de vie (en secondes)
    [int]$TimeToLive
    
    # Constructeur par défaut
    CacheEntry() {
        $this.Key = ""
        $this.Value = $null
        $this.CreatedAt = Get-Date
        $this.LastAccessedAt = Get-Date
        $this.AccessCount = 0
        $this.TimeToLive = 300  # 5 minutes
    }
    
    # Constructeur avec clé et valeur
    CacheEntry([string]$key, [object]$value) {
        $this.Key = $key
        $this.Value = $value
        $this.CreatedAt = Get-Date
        $this.LastAccessedAt = Get-Date
        $this.AccessCount = 0
        $this.TimeToLive = 300  # 5 minutes
    }
    
    # Constructeur complet
    CacheEntry([string]$key, [object]$value, [int]$timeToLive) {
        $this.Key = $key
        $this.Value = $value
        $this.CreatedAt = Get-Date
        $this.LastAccessedAt = Get-Date
        $this.AccessCount = 0
        $this.TimeToLive = $timeToLive
    }
    
    # Méthode pour vérifier si l'entrée est expirée
    [bool] IsExpired() {
        $now = Get-Date
        $age = ($now - $this.CreatedAt).TotalSeconds
        
        return $age -gt $this.TimeToLive
    }
    
    # Méthode pour accéder à l'entrée
    [object] Access() {
        $this.LastAccessedAt = Get-Date
        $this.AccessCount++
        
        return $this.Value
    }
    
    # Méthode pour obtenir l'âge de l'entrée (en secondes)
    [double] GetAge() {
        $now = Get-Date
        return ($now - $this.CreatedAt).TotalSeconds
    }
    
    # Méthode pour obtenir le temps restant avant expiration (en secondes)
    [double] GetTimeRemaining() {
        $age = $this.GetAge()
        return [Math]::Max(0, $this.TimeToLive - $age)
    }
}

# Classe pour représenter un cache LRU (Least Recently Used)
class LRUCache {
    # Dictionnaire des entrées
    [System.Collections.Generic.Dictionary[string, CacheEntry]]$Entries
    
    # Liste des clés ordonnées par dernier accès
    [System.Collections.Generic.LinkedList[string]]$AccessOrder
    
    # Capacité maximale du cache
    [int]$Capacity
    
    # Durée de vie par défaut des entrées (en secondes)
    [int]$DefaultTimeToLive
    
    # Statistiques du cache
    [hashtable]$Stats
    
    # Constructeur par défaut
    LRUCache() {
        $this.Entries = [System.Collections.Generic.Dictionary[string, CacheEntry]]::new()
        $this.AccessOrder = [System.Collections.Generic.LinkedList[string]]::new()
        $this.Capacity = 100
        $this.DefaultTimeToLive = 300  # 5 minutes
        $this.Stats = @{
            hits = 0
            misses = 0
            evictions = 0
            expirations = 0
            last_cleanup = [DateTime]::MinValue
        }
    }
    
    # Constructeur avec capacité
    LRUCache([int]$capacity) {
        $this.Entries = [System.Collections.Generic.Dictionary[string, CacheEntry]]::new()
        $this.AccessOrder = [System.Collections.Generic.LinkedList[string]]::new()
        $this.Capacity = $capacity
        $this.DefaultTimeToLive = 300  # 5 minutes
        $this.Stats = @{
            hits = 0
            misses = 0
            evictions = 0
            expirations = 0
            last_cleanup = [DateTime]::MinValue
        }
    }
    
    # Constructeur complet
    LRUCache([int]$capacity, [int]$defaultTimeToLive) {
        $this.Entries = [System.Collections.Generic.Dictionary[string, CacheEntry]]::new()
        $this.AccessOrder = [System.Collections.Generic.LinkedList[string]]::new()
        $this.Capacity = $capacity
        $this.DefaultTimeToLive = $defaultTimeToLive
        $this.Stats = @{
            hits = 0
            misses = 0
            evictions = 0
            expirations = 0
            last_cleanup = [DateTime]::MinValue
        }
    }
    
    # Méthode pour ajouter une entrée au cache
    [void] Set([string]$key, [object]$value) {
        $this.Set($key, $value, $this.DefaultTimeToLive)
    }
    
    # Méthode pour ajouter une entrée au cache avec une durée de vie spécifique
    [void] Set([string]$key, [object]$value, [int]$timeToLive) {
        # Vérifier si la clé existe déjà
        if ($this.Entries.ContainsKey($key)) {
            # Supprimer l'entrée existante
            $this.Remove($key)
        }
        
        # Vérifier si le cache est plein
        if ($this.Entries.Count -ge $this.Capacity) {
            # Supprimer l'entrée la moins récemment utilisée
            $this.RemoveLRU()
        }
        
        # Créer une nouvelle entrée
        $entry = [CacheEntry]::new($key, $value, $timeToLive)
        
        # Ajouter l'entrée au dictionnaire
        $this.Entries[$key] = $entry
        
        # Ajouter la clé à la liste d'accès
        $this.AccessOrder.AddLast($key)
    }
    
    # Méthode pour obtenir une entrée du cache
    [object] Get([string]$key) {
        # Vérifier si la clé existe
        if (-not $this.Entries.ContainsKey($key)) {
            $this.Stats.misses++
            return $null
        }
        
        # Obtenir l'entrée
        $entry = $this.Entries[$key]
        
        # Vérifier si l'entrée est expirée
        if ($entry.IsExpired()) {
            # Supprimer l'entrée expirée
            $this.Remove($key)
            $this.Stats.expirations++
            $this.Stats.misses++
            return $null
        }
        
        # Mettre à jour l'ordre d'accès
        $this.AccessOrder.Remove($key)
        $this.AccessOrder.AddLast($key)
        
        # Accéder à l'entrée
        $this.Stats.hits++
        return $entry.Access()
    }
    
    # Méthode pour vérifier si une clé existe dans le cache
    [bool] ContainsKey([string]$key) {
        # Vérifier si la clé existe
        if (-not $this.Entries.ContainsKey($key)) {
            return $false
        }
        
        # Obtenir l'entrée
        $entry = $this.Entries[$key]
        
        # Vérifier si l'entrée est expirée
        if ($entry.IsExpired()) {
            # Supprimer l'entrée expirée
            $this.Remove($key)
            $this.Stats.expirations++
            return $false
        }
        
        return $true
    }
    
    # Méthode pour supprimer une entrée du cache
    [bool] Remove([string]$key) {
        # Vérifier si la clé existe
        if (-not $this.Entries.ContainsKey($key)) {
            return $false
        }
        
        # Supprimer l'entrée du dictionnaire
        $this.Entries.Remove($key)
        
        # Supprimer la clé de la liste d'accès
        $this.AccessOrder.Remove($key)
        
        return $true
    }
    
    # Méthode pour supprimer l'entrée la moins récemment utilisée
    [void] RemoveLRU() {
        # Vérifier si le cache est vide
        if ($this.AccessOrder.Count -eq 0) {
            return
        }
        
        # Obtenir la clé la moins récemment utilisée
        $lruKey = $this.AccessOrder.First.Value
        
        # Supprimer l'entrée
        $this.Entries.Remove($lruKey)
        $this.AccessOrder.RemoveFirst()
        $this.Stats.evictions++
    }
    
    # Méthode pour vider le cache
    [void] Clear() {
        $this.Entries.Clear()
        $this.AccessOrder.Clear()
    }
    
    # Méthode pour nettoyer les entrées expirées
    [int] Cleanup() {
        $expiredKeys = [System.Collections.Generic.List[string]]::new()
        
        # Identifier les entrées expirées
        foreach ($key in $this.Entries.Keys) {
            $entry = $this.Entries[$key]
            
            if ($entry.IsExpired()) {
                $expiredKeys.Add($key)
            }
        }
        
        # Supprimer les entrées expirées
        foreach ($key in $expiredKeys) {
            $this.Remove($key)
            $this.Stats.expirations++
        }
        
        # Mettre à jour la date du dernier nettoyage
        $this.Stats.last_cleanup = Get-Date
        
        return $expiredKeys.Count
    }
    
    # Méthode pour obtenir les statistiques du cache
    [hashtable] GetStats() {
        $stats = $this.Stats.Clone()
        $stats.size = $this.Entries.Count
        $stats.capacity = $this.Capacity
        $stats.usage = if ($this.Capacity -gt 0) { [Math]::Round(($this.Entries.Count / $this.Capacity) * 100, 2) } else { 0 }
        $stats.hit_ratio = if (($stats.hits + $stats.misses) -gt 0) { [Math]::Round(($stats.hits / ($stats.hits + $stats.misses)) * 100, 2) } else { 0 }
        
        return $stats
    }
}

# Classe pour gérer le cache des résultats de recherche
class IndexSearchCache {
    # Cache pour les requêtes de recherche
    [LRUCache]$SearchCache
    
    # Cache pour les requêtes de filtrage
    [LRUCache]$FilterCache
    
    # Cache pour les documents
    [LRUCache]$DocumentCache
    
    # Intervalle de nettoyage (en secondes)
    [int]$CleanupInterval
    
    # Dernier nettoyage
    [DateTime]$LastCleanup
    
    # Constructeur par défaut
    IndexSearchCache() {
        $this.SearchCache = [LRUCache]::new(100, 300)  # 100 entrées, 5 minutes
        $this.FilterCache = [LRUCache]::new(100, 300)  # 100 entrées, 5 minutes
        $this.DocumentCache = [LRUCache]::new(1000, 600)  # 1000 entrées, 10 minutes
        $this.CleanupInterval = 60  # 1 minute
        $this.LastCleanup = Get-Date
    }
    
    # Constructeur avec capacités
    IndexSearchCache([int]$searchCacheCapacity, [int]$filterCacheCapacity, [int]$documentCacheCapacity) {
        $this.SearchCache = [LRUCache]::new($searchCacheCapacity, 300)  # 5 minutes
        $this.FilterCache = [LRUCache]::new($filterCacheCapacity, 300)  # 5 minutes
        $this.DocumentCache = [LRUCache]::new($documentCacheCapacity, 600)  # 10 minutes
        $this.CleanupInterval = 60  # 1 minute
        $this.LastCleanup = Get-Date
    }
    
    # Constructeur complet
    IndexSearchCache([int]$searchCacheCapacity, [int]$filterCacheCapacity, [int]$documentCacheCapacity, [int]$cleanupInterval) {
        $this.SearchCache = [LRUCache]::new($searchCacheCapacity, 300)  # 5 minutes
        $this.FilterCache = [LRUCache]::new($filterCacheCapacity, 300)  # 5 minutes
        $this.DocumentCache = [LRUCache]::new($documentCacheCapacity, 600)  # 10 minutes
        $this.CleanupInterval = $cleanupInterval
        $this.LastCleanup = Get-Date
    }
    
    # Méthode pour mettre en cache un résultat de recherche
    [void] CacheSearchResult([string]$query, [string[]]$documentIds) {
        # Vérifier si un nettoyage est nécessaire
        $this.CheckCleanup()
        
        # Normaliser la requête
        $normalizedQuery = $query.Trim().ToLower()
        
        # Mettre en cache le résultat
        $this.SearchCache.Set($normalizedQuery, $documentIds)
    }
    
    # Méthode pour obtenir un résultat de recherche du cache
    [string[]] GetCachedSearchResult([string]$query) {
        # Vérifier si un nettoyage est nécessaire
        $this.CheckCleanup()
        
        # Normaliser la requête
        $normalizedQuery = $query.Trim().ToLower()
        
        # Obtenir le résultat du cache
        return $this.SearchCache.Get($normalizedQuery)
    }
    
    # Méthode pour mettre en cache un résultat de filtrage
    [void] CacheFilterResult([string]$filterKey, [string[]]$documentIds) {
        # Vérifier si un nettoyage est nécessaire
        $this.CheckCleanup()
        
        # Mettre en cache le résultat
        $this.FilterCache.Set($filterKey, $documentIds)
    }
    
    # Méthode pour obtenir un résultat de filtrage du cache
    [string[]] GetCachedFilterResult([string]$filterKey) {
        # Vérifier si un nettoyage est nécessaire
        $this.CheckCleanup()
        
        # Obtenir le résultat du cache
        return $this.FilterCache.Get($filterKey)
    }
    
    # Méthode pour mettre en cache un document
    [void] CacheDocument([string]$documentId, [IndexDocument]$document) {
        # Vérifier si un nettoyage est nécessaire
        $this.CheckCleanup()
        
        # Mettre en cache le document
        $this.DocumentCache.Set($documentId, $document)
    }
    
    # Méthode pour obtenir un document du cache
    [IndexDocument] GetCachedDocument([string]$documentId) {
        # Vérifier si un nettoyage est nécessaire
        $this.CheckCleanup()
        
        # Obtenir le document du cache
        return $this.DocumentCache.Get($documentId)
    }
    
    # Méthode pour invalider le cache de recherche
    [void] InvalidateSearchCache() {
        $this.SearchCache.Clear()
    }
    
    # Méthode pour invalider le cache de filtrage
    [void] InvalidateFilterCache() {
        $this.FilterCache.Clear()
    }
    
    # Méthode pour invalider le cache de documents
    [void] InvalidateDocumentCache() {
        $this.DocumentCache.Clear()
    }
    
    # Méthode pour invalider tout le cache
    [void] InvalidateAllCaches() {
        $this.InvalidateSearchCache()
        $this.InvalidateFilterCache()
        $this.InvalidateDocumentCache()
    }
    
    # Méthode pour invalider un document spécifique
    [void] InvalidateDocument([string]$documentId) {
        # Supprimer le document du cache
        $this.DocumentCache.Remove($documentId)
        
        # Invalider les caches de recherche et de filtrage
        # car ils peuvent contenir des références à ce document
        $this.InvalidateSearchCache()
        $this.InvalidateFilterCache()
    }
    
    # Méthode pour vérifier si un nettoyage est nécessaire
    [void] CheckCleanup() {
        $now = Get-Date
        $elapsed = ($now - $this.LastCleanup).TotalSeconds
        
        if ($elapsed -ge $this.CleanupInterval) {
            $this.Cleanup()
        }
    }
    
    # Méthode pour nettoyer les caches
    [hashtable] Cleanup() {
        $result = @{
            search_cache = $this.SearchCache.Cleanup()
            filter_cache = $this.FilterCache.Cleanup()
            document_cache = $this.DocumentCache.Cleanup()
        }
        
        $this.LastCleanup = Get-Date
        
        return $result
    }
    
    # Méthode pour obtenir les statistiques des caches
    [hashtable] GetStats() {
        return @{
            search_cache = $this.SearchCache.GetStats()
            filter_cache = $this.FilterCache.GetStats()
            document_cache = $this.DocumentCache.GetStats()
            last_cleanup = $this.LastCleanup
            cleanup_interval = $this.CleanupInterval
        }
    }
}

# Fonction pour créer un cache de recherche d'index
function New-IndexSearchCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SearchCacheCapacity = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$FilterCacheCapacity = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$DocumentCacheCapacity = 1000,
        
        [Parameter(Mandatory = $false)]
        [int]$CleanupInterval = 60
    )
    
    return [IndexSearchCache]::new($SearchCacheCapacity, $FilterCacheCapacity, $DocumentCacheCapacity, $CleanupInterval)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-IndexSearchCache
