# Guide d'utilisation : Cache prédictif

## Introduction

Ce guide explique comment utiliser le cache prédictif pour optimiser les performances de vos workflows n8n et autres scripts en mettant en cache les données fréquemment utilisées et en prédisant les prochains accès.

## Pourquoi utiliser le cache prédictif ?

Le cache prédictif offre plusieurs avantages :

- **Performances améliorées** : Accès rapide aux données fréquemment utilisées.
- **Réduction de la charge** : Moins de requêtes aux sources de données externes.
- **Préchargement intelligent** : Anticipe les besoins en données pour réduire les temps d'attente.
- **Optimisation contextuelle** : Adapte le cache en fonction du contexte d'exécution.

## Installation

Aucune installation spéciale n'est requise. Les scripts de cache prédictif sont inclus dans le projet.

## Configuration pour n8n

Pour configurer le cache prédictif pour n8n :

1. Ouvrez PowerShell.
2. Exécutez le script d'initialisation :

```powershell
.\scripts\n8n\cache\Initialize-N8nPredictiveCache.ps1 -N8nApiUrl "http://localhost:5678/api/v1" -ApiKey "your_api_key" -MaxCacheSizeMB 200
```

3. Cette commande initialisera le cache prédictif avec une taille maximale de 200 MB et enregistrera les hooks nécessaires pour l'intégration avec n8n.

## Utilisation de base

### Mettre en cache une valeur

Pour mettre une valeur en cache :

```powershell
Import-Module .\modules\PredictiveCache.psm1
Initialize-PredictiveCache -Enabled $true -CachePath ".\cache" -ModelPath ".\models" -MaxCacheSize 100MB -DefaultTTL 3600

$value = @{
    name = "Test Object"
    properties = @{
        prop1 = "Value 1"
        prop2 = 123
    }
}

Set-PredictiveCache -Key "test-key" -Value $value -TTL 1800
```

### Récupérer une valeur du cache

Pour récupérer une valeur du cache :

```powershell
$value = Get-PredictiveCache -Key "test-key"
if ($value -ne $null) {
    Write-Host "Valeur trouvée dans le cache: $($value | ConvertTo-Json -Compress)"
}
else {
    Write-Host "Valeur non trouvée dans le cache."
}
```

### Supprimer une valeur du cache

Pour supprimer une valeur du cache :

```powershell
$removed = Remove-PredictiveCache -Key "test-key"
if ($removed) {
    Write-Host "Valeur supprimée du cache."
}
else {
    Write-Host "Valeur non trouvée dans le cache."
}
```

### Enregistrer un accès au cache

Pour enregistrer un accès au cache (pour l'apprentissage des modèles de prédiction) :

```powershell
Register-CacheAccess -Key "test-key" -WorkflowId "workflow1" -NodeId "node1"
```

### Obtenir des prédictions

Pour obtenir des prédictions sur les prochains accès au cache :

```powershell
$predictions = Get-PredictedCacheKeys -Key "test-key" -WorkflowId "workflow1" -NodeId "node1"
foreach ($prediction in $predictions) {
    Write-Host "Clé prédite: $($prediction.Key) (probabilité: $($prediction.Probability))"
    
    # Précharger la valeur prédite
    $predictedValue = Get-PredictiveCache -Key $prediction.Key
}
```

## Utilisation avec n8n

### Dans les workflows n8n

Une fois le cache prédictif configuré pour n8n, vous pouvez l'utiliser dans vos workflows via l'objet global `$predictiveCache` :

```javascript
// Dans un nœud Function de n8n
const key = 'example-key';
const value = { data: 'example-value' };

// Mettre en cache la valeur
$predictiveCache.set(key, value);

// Récupérer la valeur du cache
const cachedValue = $predictiveCache.get(key);

// Obtenir des prédictions
const predictions = $predictiveCache.predict(key);

// Afficher les résultats
return {
  json: {
    key,
    value,
    cachedValue,
    predictions
  }
};
```

### Exemple de workflow n8n

Un workflow d'exemple est créé automatiquement lors de l'initialisation du cache prédictif. Vous pouvez l'utiliser comme référence pour intégrer le cache prédictif dans vos propres workflows.

## Options avancées

### Spécifier une durée de vie (TTL)

Pour spécifier une durée de vie personnalisée pour une entrée de cache :

```powershell
Set-PredictiveCache -Key "test-key" -Value $value -TTL 3600  # 1 heure
```

### Invalider les entrées liées

Pour supprimer une entrée du cache et toutes les entrées liées :

```powershell
Remove-PredictiveCache -Key "test-key" -InvalidateRelated
```

### Optimiser la taille du cache

Pour optimiser manuellement la taille du cache :

```powershell
Optimize-CacheSize
```

Cette fonction est également appelée automatiquement lorsque la taille du cache dépasse la taille maximale configurée.

## Exemples pratiques

### Exemple 1 : Mise en cache des résultats d'API

Supposons que vous avez une fonction qui récupère des données d'une API externe :

```powershell
function Get-ApiData {
    param (
        [string]$Endpoint,
        [hashtable]$Parameters
    )
    
    # Créer une clé de cache basée sur l'endpoint et les paramètres
    $paramString = ($Parameters.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "&"
    $cacheKey = "api:$Endpoint:$paramString"
    
    # Essayer de récupérer du cache
    $cachedData = Get-PredictiveCache -Key $cacheKey
    
    if ($cachedData -ne $null) {
        Write-Host "Données récupérées du cache."
        return $cachedData
    }
    
    # Récupérer les données de l'API
    $uri = "https://api.example.com/$Endpoint"
    if ($Parameters) {
        $uri += "?" + $paramString
    }
    
    $response = Invoke-RestMethod -Uri $uri -Method Get
    
    # Mettre en cache les données (TTL de 30 minutes)
    Set-PredictiveCache -Key $cacheKey -Value $response -TTL 1800
    
    # Enregistrer l'accès au cache
    Register-CacheAccess -Key $cacheKey -WorkflowId "api-workflow" -NodeId "get-data"
    
    return $response
}

# Utilisation
$data = Get-ApiData -Endpoint "users" -Parameters @{ limit = 10; offset = 0 }
```

### Exemple 2 : Préchargement intelligent

Pour précharger intelligemment les données susceptibles d'être demandées prochainement :

```powershell
function Get-UserData {
    param (
        [int]$UserId
    )
    
    $cacheKey = "user:$UserId"
    
    # Essayer de récupérer du cache
    $userData = Get-PredictiveCache -Key $cacheKey
    
    if ($userData -ne $null) {
        Write-Host "Données utilisateur récupérées du cache."
        
        # Enregistrer l'accès au cache
        Register-CacheAccess -Key $cacheKey -WorkflowId "user-workflow" -NodeId "get-user"
        
        # Obtenir des prédictions et précharger
        $predictions = Get-PredictedCacheKeys -Key $cacheKey -WorkflowId "user-workflow" -NodeId "get-user"
        
        # Précharger en arrière-plan
        Start-Job -ScriptBlock {
            param($predictions, $modulePath)
            
            Import-Module $modulePath -Force
            
            foreach ($prediction in $predictions) {
                $predictedKey = $prediction.Key
                $predictedUserId = $predictedKey -replace "user:", ""
                
                # Vérifier si déjà en cache
                $predictedData = Get-PredictiveCache -Key $predictedKey
                
                if ($predictedData -eq $null) {
                    # Récupérer les données
                    $uri = "https://api.example.com/users/$predictedUserId"
                    $response = Invoke-RestMethod -Uri $uri -Method Get
                    
                    # Mettre en cache
                    Set-PredictiveCache -Key $predictedKey -Value $response -TTL 1800
                }
            }
        } -ArgumentList $predictions, (Join-Path -Path $PSScriptRoot -ChildPath "modules\PredictiveCache.psm1")
        
        return $userData
    }
    
    # Récupérer les données de l'API
    $uri = "https://api.example.com/users/$UserId"
    $response = Invoke-RestMethod -Uri $uri -Method Get
    
    # Mettre en cache les données
    Set-PredictiveCache -Key $cacheKey -Value $response -TTL 1800
    
    # Enregistrer l'accès au cache
    Register-CacheAccess -Key $cacheKey -WorkflowId "user-workflow" -NodeId "get-user"
    
    return $response
}

# Utilisation
$user = Get-UserData -UserId 123
```

### Exemple 3 : Utilisation dans un workflow n8n

Voici un exemple de code JavaScript à utiliser dans un nœud Function de n8n :

```javascript
// Récupérer des données utilisateur avec mise en cache
const userId = items[0].json.userId;
const cacheKey = `user:${userId}`;

// Essayer de récupérer du cache
let userData = $predictiveCache.get(cacheKey);

if (userData) {
  // Données trouvées dans le cache
  items[0].json.userDataSource = 'cache';
  items[0].json.userData = userData;
  
  // Obtenir des prédictions
  const predictions = $predictiveCache.predict(cacheKey);
  
  // Précharger les prédictions
  for (const prediction of predictions) {
    const predictedKey = prediction.key;
    if (!$predictiveCache.get(predictedKey)) {
      // La valeur n'est pas en cache, la précharger en arrière-plan
      // (Dans un cas réel, vous utiliseriez un nœud HTTP Request séparé)
    }
  }
} else {
  // Données non trouvées dans le cache, les récupérer
  const apiUrl = `https://api.example.com/users/${userId}`;
  
  // Dans un cas réel, vous utiliseriez un nœud HTTP Request
  // Simulons une réponse pour cet exemple
  userData = {
    id: userId,
    name: `User ${userId}`,
    email: `user${userId}@example.com`
  };
  
  // Mettre en cache les données (TTL de 30 minutes)
  $predictiveCache.set(cacheKey, userData, 1800);
  
  items[0].json.userDataSource = 'api';
  items[0].json.userData = userData;
}

return items;
```

## Bonnes pratiques

### Pour une utilisation efficace du cache

1. **Utilisez des clés descriptives** : Les clés de cache doivent être uniques et descriptives.
2. **Définissez des TTL appropriés** : Adaptez la durée de vie en fonction de la fraîcheur requise des données.
3. **Enregistrez les accès au cache** : Utilisez `Register-CacheAccess` pour améliorer les prédictions.
4. **Préchargez en arrière-plan** : Utilisez des jobs ou des threads séparés pour le préchargement.
5. **Surveillez la taille du cache** : Évitez de mettre en cache des objets trop volumineux.

### Pour l'intégration avec n8n

1. **Utilisez l'objet global** : Accédez au cache via l'objet `$predictiveCache`.
2. **Structurez vos workflows** : Organisez vos workflows pour maximiser les avantages du cache.
3. **Combinez avec d'autres fonctionnalités** : Utilisez le cache avec d'autres optimisations comme le traitement parallèle.

## Dépannage

### Problème : Valeurs non trouvées dans le cache

**Solution** : Vérifiez que la clé est correcte et que la valeur n'a pas expiré (TTL).

### Problème : Prédictions incorrectes

**Solution** : Assurez-vous d'enregistrer correctement les accès au cache avec `Register-CacheAccess`.

### Problème : Performances lentes

**Solution** : Réduisez la taille des objets mis en cache ou augmentez la taille maximale du cache.

## Intégration avec d'autres outils

### Intégration avec le monitoring

Vous pouvez surveiller les performances du cache prédictif :

```powershell
function Get-CachePerformanceMetrics {
    $cacheStats = Get-PredictiveCacheStats
    
    $hitRate = if ($cacheStats.TotalRequests -gt 0) {
        $cacheStats.CacheHits / $cacheStats.TotalRequests
    } else {
        0
    }
    
    $metrics = [PSCustomObject]@{
        Timestamp = Get-Date
        CacheSize = $cacheStats.CacheSize
        MaxCacheSize = $cacheStats.MaxCacheSize
        CacheUtilization = $cacheStats.CacheSize / $cacheStats.MaxCacheSize
        TotalRequests = $cacheStats.TotalRequests
        CacheHits = $cacheStats.CacheHits
        CacheMisses = $cacheStats.CacheMisses
        HitRate = $hitRate
    }
    
    return $metrics
}

# Enregistrer les métriques
$metrics = Get-CachePerformanceMetrics
$metrics | Export-Csv -Path ".\logs\cache_metrics_$(Get-Date -Format 'yyyyMMdd').csv" -Append -NoTypeInformation
```

### Intégration avec le système de feedback

Si vous trouvez des problèmes avec le cache prédictif, vous pouvez soumettre un feedback :

```powershell
Import-Module .\modules\FeedbackCollection.psm1
Submit-Feedback -Component "PredictiveCache" -FeedbackType "Performance Issue" -Description "Description du problème"
```

## Conclusion

Le cache prédictif est un outil puissant pour optimiser les performances de vos workflows et scripts. En mettant en cache les données fréquemment utilisées et en prédisant les prochains accès, vous pouvez réduire considérablement les temps de réponse et la charge sur les systèmes externes.

Pour plus d'informations techniques, consultez la [documentation technique du module PredictiveCache](../technical/PredictiveCache.md).
