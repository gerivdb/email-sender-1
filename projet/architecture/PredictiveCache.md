# Module de cache prédictif

## Vue d'ensemble

Le module `PredictiveCache` fournit un système de cache intelligent qui prédit les prochains accès en fonction des modèles d'utilisation passés. Ce module est particulièrement utile pour optimiser les performances des workflows n8n et d'autres systèmes nécessitant un accès rapide aux données fréquemment utilisées.

## Installation

Le module est disponible dans le dossier `modules` du projet. Pour l'importer :

```powershell
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\PredictiveCache.psm1"
Import-Module $modulePath -Force
```plaintext
## Initialisation

Avant d'utiliser le module, il est nécessaire de l'initialiser avec les paramètres souhaités :

```powershell
Initialize-PredictiveCache -Enabled $true -CachePath ".\cache" -ModelPath ".\models" -MaxCacheSize 100MB -DefaultTTL 3600
```plaintext
## Fonctions principales

### Set-PredictiveCache

Met en cache une valeur avec une clé spécifiée.

#### Syntaxe

```powershell
Set-PredictiveCache -Key <String> -Value <Object> [-TTL <Int32>]
```plaintext
#### Paramètres

- **Key** : Clé unique pour identifier la valeur en cache.
- **Value** : Valeur à mettre en cache.
- **TTL** : Durée de vie en secondes (par défaut : valeur spécifiée lors de l'initialisation).

#### Valeur de retour

La valeur mise en cache.

#### Exemple

```powershell
$value = @{
    name = "Test Object"
    properties = @{
        prop1 = "Value 1"
        prop2 = 123
    }
}

Set-PredictiveCache -Key "test-key" -Value $value -TTL 1800
```plaintext
### Get-PredictiveCache

Récupère une valeur du cache.

#### Syntaxe

```powershell
Get-PredictiveCache -Key <String>
```plaintext
#### Paramètres

- **Key** : Clé de la valeur à récupérer.

#### Valeur de retour

La valeur en cache, ou `$null` si la clé n'existe pas ou a expiré.

#### Exemple

```powershell
$value = Get-PredictiveCache -Key "test-key"
if ($value -ne $null) {
    Write-Host "Valeur trouvée dans le cache: $($value | ConvertTo-Json -Compress)"
}
```plaintext
### Remove-PredictiveCache

Supprime une valeur du cache.

#### Syntaxe

```powershell
Remove-PredictiveCache -Key <String> [-InvalidateRelated]
```plaintext
#### Paramètres

- **Key** : Clé de la valeur à supprimer.
- **InvalidateRelated** : Invalide également les entrées liées à cette clé.

#### Valeur de retour

`$true` si la valeur a été supprimée, `$false` sinon.

#### Exemple

```powershell
$removed = Remove-PredictiveCache -Key "test-key" -InvalidateRelated
if ($removed) {
    Write-Host "Valeur supprimée du cache."
}
```plaintext
### Register-CacheAccess

Enregistre un accès au cache pour l'apprentissage des modèles de prédiction.

#### Syntaxe

```powershell
Register-CacheAccess -Key <String> -WorkflowId <String> -NodeId <String>
```plaintext
#### Paramètres

- **Key** : Clé de la valeur accédée.
- **WorkflowId** : Identifiant du workflow.
- **NodeId** : Identifiant du nœud dans le workflow.

#### Exemple

```powershell
Register-CacheAccess -Key "test-key" -WorkflowId "workflow1" -NodeId "node1"
```plaintext
### Get-PredictedCacheKeys

Prédit les prochaines clés qui seront accédées en fonction des modèles d'utilisation passés.

#### Syntaxe

```powershell
Get-PredictedCacheKeys -Key <String> -WorkflowId <String> -NodeId <String> [-MaxPredictions <Int32>]
```plaintext
#### Paramètres

- **Key** : Clé actuelle.
- **WorkflowId** : Identifiant du workflow.
- **NodeId** : Identifiant du nœud dans le workflow.
- **MaxPredictions** : Nombre maximum de prédictions à retourner (par défaut : 5).

#### Valeur de retour

Un tableau d'objets avec les propriétés suivantes :
- **Key** : Clé prédite.
- **Probability** : Probabilité de l'accès (entre 0 et 1).

#### Exemple

```powershell
$predictions = Get-PredictedCacheKeys -Key "test-key" -WorkflowId "workflow1" -NodeId "node1"
foreach ($prediction in $predictions) {
    Write-Host "Clé prédite: $($prediction.Key) (probabilité: $($prediction.Probability))"
    
    # Précharger la valeur prédite

    $predictedValue = Get-PredictiveCache -Key $prediction.Key
}
```plaintext
### Optimize-CacheSize

Optimise la taille du cache en supprimant les entrées les moins utilisées lorsque la taille maximale est dépassée.

#### Syntaxe

```powershell
Optimize-CacheSize
```plaintext
#### Exemple

```powershell
Optimize-CacheSize
```plaintext
### Register-N8nCacheHook

Enregistre les hooks nécessaires pour intégrer le cache prédictif avec n8n.

#### Syntaxe

```powershell
Register-N8nCacheHook -N8nApiUrl <String> [-ApiKey <String>]
```plaintext
#### Paramètres

- **N8nApiUrl** : URL de l'API n8n.
- **ApiKey** : Clé API pour l'authentification avec n8n.

#### Valeur de retour

`$true` si les hooks ont été enregistrés avec succès, `$false` sinon.

#### Exemple

```powershell
$hooksRegistered = Register-N8nCacheHook -N8nApiUrl "http://localhost:5678/api/v1" -ApiKey "your_api_key"
if ($hooksRegistered) {
    Write-Host "Hooks n8n enregistrés avec succès."
}
```plaintext
## Intégration avec n8n

Le module `PredictiveCache` s'intègre avec n8n via le script `Initialize-N8nPredictiveCache.ps1` qui configure le cache prédictif pour n8n et enregistre les hooks nécessaires.

### Exemple d'utilisation avec n8n

```powershell
# Initialiser le cache prédictif pour n8n

& ".\scripts\n8n\cache\Initialize-N8nPredictiveCache.ps1" -N8nApiUrl "http://localhost:5678/api/v1" -ApiKey "your_api_key" -MaxCacheSizeMB 200

# Dans les workflows n8n, utiliser l'objet global $predictiveCache

# Exemple de code JavaScript dans un nœud Function de n8n:

/*
const key = 'example-key';
const value = { data: 'example-value' };

// Mettre en cache la valeur
$predictiveCache.set(key, value);

// Récupérer la valeur du cache
const cachedValue = $predictiveCache.get(key);

// Obtenir des prédictions
const predictions = $predictiveCache.predict(key);
*/
```plaintext
## Algorithmes de prédiction

Le module utilise plusieurs algorithmes pour prédire les prochains accès au cache :

1. **Analyse de séquence** : Détecte les modèles dans les séquences d'accès au cache.
2. **Analyse contextuelle** : Prend en compte le contexte (workflow et nœud) pour affiner les prédictions.
3. **Pondération temporelle** : Donne plus de poids aux accès récents.

## Performance

Les performances du module dépendent de la taille du cache et du nombre d'accès enregistrés :

- **Mise en cache** : Opération rapide (< 10 ms).
- **Récupération** : Opération très rapide (< 5 ms).
- **Prédiction** : Opération plus intensive (10-50 ms).

## Compatibilité

- PowerShell 5.1 et versions ultérieures.
- Compatible avec PowerShell 7.
- Compatible avec n8n via l'API JavaScript.

## Limitations connues

- Les objets très volumineux (> 10 MB) peuvent entraîner des problèmes de performance.
- Les prédictions sont moins précises pour les nouveaux workflows avec peu d'historique d'utilisation.

## Exemples avancés

### Utilisation avec préchargement automatique

```powershell
function Get-DataWithCache {
    param (
        [string]$Key,
        [string]$WorkflowId,
        [string]$NodeId,
        [scriptblock]$DataFetcher
    )
    
    # Essayer de récupérer du cache

    $cachedValue = Get-PredictiveCache -Key $Key
    
    if ($cachedValue -ne $null) {
        # Enregistrer l'accès au cache

        Register-CacheAccess -Key $Key -WorkflowId $WorkflowId -NodeId $NodeId
        
        # Obtenir les prédictions

        $predictions = Get-PredictedCacheKeys -Key $Key -WorkflowId $WorkflowId -NodeId $NodeId
        
        # Précharger les valeurs prédites en arrière-plan

        Start-Job -ScriptBlock {
            param($predictions, $modulePath)
            
            Import-Module $modulePath -Force
            
            foreach ($prediction in $predictions) {
                $predictedValue = Get-PredictiveCache -Key $prediction.Key
                if ($predictedValue -eq $null) {
                    # La valeur n'est pas en cache, la récupérer

                    # (Ceci est un exemple, dans un cas réel, vous auriez besoin de plus d'informations)

                }
            }
        } -ArgumentList $predictions, $modulePath
        
        return $cachedValue
    }
    
    # La valeur n'est pas en cache, la récupérer

    $value = & $DataFetcher
    
    # Mettre en cache la valeur

    Set-PredictiveCache -Key $Key -Value $value
    
    # Enregistrer l'accès au cache

    Register-CacheAccess -Key $Key -WorkflowId $WorkflowId -NodeId $NodeId
    
    return $value
}

# Exemple d'utilisation

$data = Get-DataWithCache -Key "user-123" -WorkflowId "user-workflow" -NodeId "fetch-user" -DataFetcher {
    # Simuler une requête API

    Start-Sleep -Seconds 2
    return @{
        id = 123
        name = "John Doe"
        email = "john.doe@example.com"
    }
}
```plaintext
### Analyse des performances du cache

```powershell
function Analyze-CachePerformance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )
    
    # Obtenir les statistiques du cache

    $cacheStats = Get-PredictiveCacheStats
    
    # Calculer le taux de succès du cache

    $hitRate = if ($cacheStats.TotalRequests -gt 0) {
        $cacheStats.CacheHits / $cacheStats.TotalRequests
    } else {
        0
    }
    
    # Calculer l'efficacité des prédictions

    $predictionAccuracy = if ($cacheStats.TotalPredictions -gt 0) {
        $cacheStats.SuccessfulPredictions / $cacheStats.TotalPredictions
    } else {
        0
    }
    
    # Créer le rapport d'analyse

    $report = [PSCustomObject]@{
        GeneratedAt = (Get-Date).ToString("o")
        CacheSize = $cacheStats.CacheSize
        MaxCacheSize = $cacheStats.MaxCacheSize
        CacheUtilization = $cacheStats.CacheSize / $cacheStats.MaxCacheSize
        TotalRequests = $cacheStats.TotalRequests
        CacheHits = $cacheStats.CacheHits
        CacheMisses = $cacheStats.CacheMisses
        HitRate = $hitRate
        TotalPredictions = $cacheStats.TotalPredictions
        SuccessfulPredictions = $cacheStats.SuccessfulPredictions
        PredictionAccuracy = $predictionAccuracy
        TopCachedKeys = $cacheStats.TopCachedKeys
        TopPredictedKeys = $cacheStats.TopPredictedKeys
    }
    
    # Enregistrer le rapport si demandé

    if ($OutputPath) {
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
    }
    
    return $report
}

# Exemple d'utilisation

$report = Analyze-CachePerformance -OutputPath ".\reports\cache_performance.json"
Write-Host "Taux de succès du cache: $([Math]::Round($report.HitRate * 100, 2))%"
Write-Host "Précision des prédictions: $([Math]::Round($report.PredictionAccuracy * 100, 2))%"
```plaintext