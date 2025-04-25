#Requires -Version 5.1
<#
.SYNOPSIS
    Module de cache prédictif pour n8n.
.DESCRIPTION
    Ce module fournit des fonctions pour implémenter un cache prédictif
    qui anticipe les besoins en données des workflows n8n.
#>

# Variables globales
$script:CacheEnabled = $true
$script:CachePath = Join-Path -Path $PSScriptRoot -ChildPath "..\cache\predictive"
$script:ModelPath = Join-Path -Path $PSScriptRoot -ChildPath "..\models\predictive"
$script:LogsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\logs\predictive"
$script:MaxCacheSize = 100MB
$script:DefaultTTL = 3600  # 1 heure
$script:PredictionThreshold = 0.7
$script:UsagePatterns = @{}

# Créer les dossiers nécessaires
foreach ($path in @($script:CachePath, $script:ModelPath, $script:LogsPath)) {
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour initialiser le cache prédictif
function Initialize-PredictiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$CachePath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ModelPath = "",
        
        [Parameter(Mandatory = $false)]
        [long]$MaxCacheSize = 100MB,
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultTTL = 3600,
        
        [Parameter(Mandatory = $false)]
        [double]$PredictionThreshold = 0.7
    )
    
    $script:CacheEnabled = $Enabled
    
    if ($CachePath) {
        $script:CachePath = $CachePath
        if (-not (Test-Path -Path $script:CachePath)) {
            New-Item -Path $script:CachePath -ItemType Directory -Force | Out-Null
        }
    }
    
    if ($ModelPath) {
        $script:ModelPath = $ModelPath
        if (-not (Test-Path -Path $script:ModelPath)) {
            New-Item -Path $script:ModelPath -ItemType Directory -Force | Out-Null
        }
    }
    
    $script:MaxCacheSize = $MaxCacheSize
    $script:DefaultTTL = $DefaultTTL
    $script:PredictionThreshold = $PredictionThreshold
    
    # Charger les modèles existants
    Load-UsagePatterns
    
    Write-Verbose "Cache prédictif initialisé. Activé: $Enabled, Taille max: $($MaxCacheSize / 1MB) MB"
}

# Fonction pour charger les modèles de prédiction
function Load-UsagePatterns {
    [CmdletBinding()]
    param ()
    
    $patternsFile = Join-Path -Path $script:ModelPath -ChildPath "usage_patterns.json"
    
    if (Test-Path -Path $patternsFile) {
        try {
            $script:UsagePatterns = Get-Content -Path $patternsFile -Raw | ConvertFrom-Json -AsHashtable
            Write-Verbose "Modèles de prédiction chargés: $($script:UsagePatterns.Count) motifs"
        }
        catch {
            Write-Warning "Erreur lors du chargement des modèles de prédiction: $_"
            $script:UsagePatterns = @{}
        }
    }
    else {
        $script:UsagePatterns = @{}
    }
}

# Fonction pour sauvegarder les modèles de prédiction
function Save-UsagePatterns {
    [CmdletBinding()]
    param ()
    
    $patternsFile = Join-Path -Path $script:ModelPath -ChildPath "usage_patterns.json"
    
    try {
        $script:UsagePatterns | ConvertTo-Json -Depth 10 | Out-File -FilePath $patternsFile -Encoding utf8
        Write-Verbose "Modèles de prédiction sauvegardés: $($script:UsagePatterns.Count) motifs"
    }
    catch {
        Write-Warning "Erreur lors de la sauvegarde des modèles de prédiction: $_"
    }
}

# Fonction pour enregistrer un accès au cache
function Register-CacheAccess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkflowId = "",
        
        [Parameter(Mandatory = $false)]
        [string]$NodeId = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    if (-not $script:CacheEnabled) {
        return
    }
    
    # Créer un identifiant unique pour le contexte
    $contextId = if ($WorkflowId -and $NodeId) { "$WorkflowId:$NodeId" } else { "global" }
    
    # Initialiser le contexte s'il n'existe pas
    if (-not $script:UsagePatterns.ContainsKey($contextId)) {
        $script:UsagePatterns[$contextId] = @{
            AccessCount = 0
            LastAccess = Get-Date
            Keys = @{}
            Sequences = @{}
        }
    }
    
    # Mettre à jour les statistiques d'accès
    $script:UsagePatterns[$contextId].AccessCount++
    $script:UsagePatterns[$contextId].LastAccess = Get-Date
    
    # Initialiser la clé si elle n'existe pas
    if (-not $script:UsagePatterns[$contextId].Keys.ContainsKey($Key)) {
        $script:UsagePatterns[$contextId].Keys[$Key] = @{
            AccessCount = 0
            LastAccess = Get-Date
            Metadata = @{}
        }
    }
    
    # Mettre à jour les statistiques de la clé
    $script:UsagePatterns[$contextId].Keys[$Key].AccessCount++
    $script:UsagePatterns[$contextId].Keys[$Key].LastAccess = Get-Date
    
    # Fusionner les métadonnées
    foreach ($metaKey in $Metadata.Keys) {
        $script:UsagePatterns[$contextId].Keys[$Key].Metadata[$metaKey] = $Metadata[$metaKey]
    }
    
    # Enregistrer la séquence d'accès
    $lastKey = $script:UsagePatterns[$contextId].LastKey
    
    if ($lastKey -and $lastKey -ne $Key) {
        $sequence = "$lastKey -> $Key"
        
        if (-not $script:UsagePatterns[$contextId].Sequences.ContainsKey($sequence)) {
            $script:UsagePatterns[$contextId].Sequences[$sequence] = @{
                Count = 0
                LastOccurrence = Get-Date
            }
        }
        
        $script:UsagePatterns[$contextId].Sequences[$sequence].Count++
        $script:UsagePatterns[$contextId].Sequences[$sequence].LastOccurrence = Get-Date
    }
    
    $script:UsagePatterns[$contextId].LastKey = $Key
    
    # Sauvegarder périodiquement les modèles
    if ($script:UsagePatterns[$contextId].AccessCount % 100 -eq 0) {
        Save-UsagePatterns
    }
}

# Fonction pour prédire les prochains accès au cache
function Get-PredictedCacheKeys {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkflowId = "",
        
        [Parameter(Mandatory = $false)]
        [string]$NodeId = "",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxPredictions = 5
    )
    
    if (-not $script:CacheEnabled) {
        return @()
    }
    
    # Créer un identifiant unique pour le contexte
    $contextId = if ($WorkflowId -and $NodeId) { "$WorkflowId:$NodeId" } else { "global" }
    
    # Vérifier si le contexte existe
    if (-not $script:UsagePatterns.ContainsKey($contextId)) {
        return @()
    }
    
    # Trouver les séquences qui commencent par la clé actuelle
    $predictions = @()
    
    foreach ($sequence in $script:UsagePatterns[$contextId].Sequences.Keys) {
        if ($sequence -match "^$([regex]::Escape($Key)) -> (.+)$") {
            $targetKey = $matches[1]
            $count = $script:UsagePatterns[$contextId].Sequences[$sequence].Count
            $lastOccurrence = $script:UsagePatterns[$contextId].Sequences[$sequence].LastOccurrence
            
            # Calculer un score de prédiction basé sur la fréquence et la récence
            $frequencyScore = $count / [Math]::Max(1, $script:UsagePatterns[$contextId].AccessCount)
            $recencyScore = 1 / [Math]::Max(1, ((Get-Date) - $lastOccurrence).TotalHours)
            $predictionScore = ($frequencyScore * 0.7) + ($recencyScore * 0.3)
            
            if ($predictionScore -ge $script:PredictionThreshold) {
                $predictions += [PSCustomObject]@{
                    Key = $targetKey
                    Score = $predictionScore
                    Sequence = $sequence
                    Count = $count
                    LastOccurrence = $lastOccurrence
                }
            }
        }
    }
    
    # Trier par score et limiter le nombre de prédictions
    $topPredictions = $predictions | Sort-Object -Property Score -Descending | Select-Object -First $MaxPredictions
    
    return $topPredictions
}

# Fonction pour mettre en cache une valeur
function Set-PredictiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter(Mandatory = $false)]
        [int]$TTL = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkflowId = "",
        
        [Parameter(Mandatory = $false)]
        [string]$NodeId = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    if (-not $script:CacheEnabled) {
        return
    }
    
    # Utiliser le TTL par défaut si non spécifié
    if ($TTL -le 0) {
        $TTL = $script:DefaultTTL
    }
    
    # Créer le chemin du fichier cache
    $keyHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key))
    $keyHashString = [System.BitConverter]::ToString($keyHash).Replace("-", "").ToLower()
    $cachePath = Join-Path -Path $script:CachePath -ChildPath "$keyHashString.cache"
    
    # Créer l'objet cache
    $cacheObject = @{
        Key = $Key
        Value = $Value
        CreatedAt = (Get-Date).ToString("o")
        ExpiresAt = (Get-Date).AddSeconds($TTL).ToString("o")
        WorkflowId = $WorkflowId
        NodeId = $NodeId
        Metadata = $Metadata
    }
    
    # Enregistrer l'objet cache
    try {
        $cacheObject | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $cachePath -Encoding utf8
        
        # Enregistrer l'accès au cache
        Register-CacheAccess -Key $Key -WorkflowId $WorkflowId -NodeId $NodeId -Metadata $Metadata
        
        # Vérifier la taille du cache
        Optimize-CacheSize
        
        return $true
    }
    catch {
        Write-Warning "Erreur lors de la mise en cache de la valeur: $_"
        return $false
    }
}

# Fonction pour récupérer une valeur du cache
function Get-PredictiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkflowId = "",
        
        [Parameter(Mandatory = $false)]
        [string]$NodeId = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoPreload
    )
    
    if (-not $script:CacheEnabled) {
        return $null
    }
    
    # Créer le chemin du fichier cache
    $keyHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key))
    $keyHashString = [System.BitConverter]::ToString($keyHash).Replace("-", "").ToLower()
    $cachePath = Join-Path -Path $script:CachePath -ChildPath "$keyHashString.cache"
    
    # Vérifier si le fichier cache existe
    if (-not (Test-Path -Path $cachePath)) {
        return $null
    }
    
    try {
        # Charger l'objet cache
        $cacheObject = Get-Content -Path $cachePath -Raw | ConvertFrom-Json
        
        # Vérifier si le cache a expiré
        $expiresAt = [datetime]::Parse($cacheObject.ExpiresAt)
        
        if ($expiresAt -lt (Get-Date)) {
            # Le cache a expiré
            Remove-Item -Path $cachePath -Force
            return $null
        }
        
        # Enregistrer l'accès au cache
        Register-CacheAccess -Key $Key -WorkflowId $WorkflowId -NodeId $NodeId
        
        # Précharger les valeurs prédites
        if (-not $NoPreload) {
            $predictions = Get-PredictedCacheKeys -Key $Key -WorkflowId $WorkflowId -NodeId $NodeId
            
            if ($predictions.Count -gt 0) {
                # Précharger en arrière-plan
                Start-ThreadJob -ScriptBlock {
                    param($Module, $Predictions, $WorkflowId, $NodeId)
                    
                    Import-Module $Module
                    
                    foreach ($prediction in $Predictions) {
                        Get-PredictiveCache -Key $prediction.Key -WorkflowId $WorkflowId -NodeId $NodeId -NoPreload
                    }
                } -ArgumentList $PSScriptRoot, $predictions, $WorkflowId, $NodeId | Out-Null
            }
        }
        
        return $cacheObject.Value
    }
    catch {
        Write-Warning "Erreur lors de la récupération de la valeur du cache: $_"
        return $null
    }
}

# Fonction pour invalider une entrée du cache
function Remove-PredictiveCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $false)]
        [switch]$InvalidateRelated
    )
    
    if (-not $script:CacheEnabled) {
        return $false
    }
    
    # Créer le chemin du fichier cache
    $keyHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key))
    $keyHashString = [System.BitConverter]::ToString($keyHash).Replace("-", "").ToLower()
    $cachePath = Join-Path -Path $script:CachePath -ChildPath "$keyHashString.cache"
    
    # Vérifier si le fichier cache existe
    if (-not (Test-Path -Path $cachePath)) {
        return $false
    }
    
    try {
        # Supprimer le fichier cache
        Remove-Item -Path $cachePath -Force
        
        # Invalider les entrées liées si demandé
        if ($InvalidateRelated) {
            $relatedKeys = @()
            
            # Parcourir tous les contextes
            foreach ($contextId in $script:UsagePatterns.Keys) {
                # Trouver les séquences qui commencent par la clé actuelle
                foreach ($sequence in $script:UsagePatterns[$contextId].Sequences.Keys) {
                    if ($sequence -match "^$([regex]::Escape($Key)) -> (.+)$") {
                        $targetKey = $matches[1]
                        $relatedKeys += $targetKey
                    }
                }
            }
            
            # Invalider les clés liées
            foreach ($relatedKey in $relatedKeys) {
                Remove-PredictiveCache -Key $relatedKey
            }
        }
        
        return $true
    }
    catch {
        Write-Warning "Erreur lors de l'invalidation du cache: $_"
        return $false
    }
}

# Fonction pour optimiser la taille du cache
function Optimize-CacheSize {
    [CmdletBinding()]
    param ()
    
    if (-not $script:CacheEnabled) {
        return
    }
    
    # Obtenir la taille actuelle du cache
    $cacheFiles = Get-ChildItem -Path $script:CachePath -Filter "*.cache"
    $currentSize = ($cacheFiles | Measure-Object -Property Length -Sum).Sum
    
    # Vérifier si la taille dépasse la limite
    if ($currentSize -gt $script:MaxCacheSize) {
        Write-Verbose "Taille du cache ($($currentSize / 1MB) MB) dépasse la limite ($($script:MaxCacheSize / 1MB) MB). Optimisation..."
        
        # Trier les fichiers par date de dernière modification
        $oldestFiles = $cacheFiles | Sort-Object -Property LastWriteTime
        
        # Supprimer les fichiers les plus anciens jusqu'à ce que la taille soit acceptable
        $targetSize = $script:MaxCacheSize * 0.8  # Réduire à 80% de la taille maximale
        $currentSize = ($cacheFiles | Measure-Object -Property Length -Sum).Sum
        
        foreach ($file in $oldestFiles) {
            if ($currentSize -le $targetSize) {
                break
            }
            
            try {
                $fileSize = $file.Length
                Remove-Item -Path $file.FullName -Force
                $currentSize -= $fileSize
                
                Write-Verbose "Fichier cache supprimé: $($file.Name) ($($fileSize / 1KB) KB)"
            }
            catch {
                Write-Warning "Erreur lors de la suppression du fichier cache: $_"
            }
        }
    }
}

# Fonction pour intégrer le cache prédictif avec n8n
function Register-N8nCacheHook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$N8nApiUrl = "http://localhost:5678/api/v1",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = ""
    )
    
    if (-not $script:CacheEnabled) {
        return $false
    }
    
    try {
        # Vérifier si n8n est accessible
        $headers = @{
            "Accept" = "application/json"
        }
        
        if ($ApiKey) {
            $headers["X-N8N-API-KEY"] = $ApiKey
        }
        
        $response = Invoke-RestMethod -Uri "$N8nApiUrl/health" -Method Get -Headers $headers
        
        if ($response.status -ne "ok") {
            Write-Warning "n8n n'est pas disponible ou en bonne santé."
            return $false
        }
        
        # Créer un webhook pour intercepter les exécutions de workflow
        $webhookUrl = "http://localhost:8080/api/predictive-cache/hook"
        
        # TODO: Implémenter le webhook pour intercepter les exécutions de workflow
        
        Write-Verbose "Intégration avec n8n configurée."
        return $true
    }
    catch {
        Write-Warning "Erreur lors de l'intégration avec n8n: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-PredictiveCache, Set-PredictiveCache, Get-PredictiveCache, Remove-PredictiveCache, Register-N8nCacheHook
