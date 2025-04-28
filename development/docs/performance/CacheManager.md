# Module de gestion de cache (CacheManager)

Ce document décrit le module de gestion de cache (`CacheManager.ps1`) qui permet d'améliorer les performances en mettant en cache les résultats des opérations coûteuses.

## Table des matières

1. [Introduction](#introduction)
2. [Fonctions disponibles](#fonctions-disponibles)
3. [Politiques d'éviction](#politiques-déviction)
4. [Exemples d'utilisation](#exemples-dutilisation)
5. [Statistiques de cache](#statistiques-de-cache)
6. [Bonnes pratiques](#bonnes-pratiques)
7. [Intégration avec d'autres modules](#intégration-avec-dautres-modules)

## Introduction

Le module de gestion de cache permet de stocker temporairement les résultats des opérations coûteuses pour éviter de les recalculer lors des appels ultérieurs. Cela peut considérablement améliorer les performances des applications qui effectuent des opérations répétitives.

Le module offre plusieurs fonctionnalités :
- Mise en cache des résultats avec une durée de vie (TTL)
- Différentes politiques d'éviction pour gérer la taille du cache
- Statistiques de cache pour mesurer l'efficacité de la mise en cache
- Fonction pour exécuter une fonction avec mise en cache

## Fonctions disponibles

### Initialize-CacheManager

```powershell
Initialize-CacheManager [-Enabled <bool>] [-MaxItems <int>] [-DefaultTTL <int>] [-EvictionPolicy <string>]
```

Cette fonction initialise le gestionnaire de cache avec les paramètres spécifiés.

#### Paramètres

- **Enabled** : Indique si le cache est activé (par défaut : $true).
- **MaxItems** : Nombre maximum d'éléments dans le cache (par défaut : 1000).
- **DefaultTTL** : Durée de vie par défaut des éléments en secondes (par défaut : 3600).
- **EvictionPolicy** : Politique d'éviction à utiliser (LRU, LFU, FIFO) (par défaut : LRU).

#### Exemple

```powershell
Initialize-CacheManager -Enabled $true -MaxItems 500 -DefaultTTL 1800 -EvictionPolicy "LFU"
```

### Get-CacheItem

```powershell
Get-CacheItem -Key <string>
```

Cette fonction récupère un élément du cache à partir de sa clé.

#### Paramètres

- **Key** : Clé de l'élément à récupérer.

#### Exemple

```powershell
$cachedResult = Get-CacheItem -Key "MyOperation_param1_param2"
```

### Set-CacheItem

```powershell
Set-CacheItem -Key <string> -Value <object> [-TTL <int>]
```

Cette fonction ajoute ou met à jour un élément dans le cache.

#### Paramètres

- **Key** : Clé de l'élément à ajouter ou mettre à jour.
- **Value** : Valeur à stocker dans le cache.
- **TTL** : Durée de vie de l'élément en secondes (par défaut : valeur de DefaultTTL).

#### Exemple

```powershell
Set-CacheItem -Key "MyOperation_param1_param2" -Value $result -TTL 7200
```

### Remove-CacheItem

```powershell
Remove-CacheItem -Key <string>
```

Cette fonction supprime un élément du cache.

#### Paramètres

- **Key** : Clé de l'élément à supprimer.

#### Exemple

```powershell
Remove-CacheItem -Key "MyOperation_param1_param2"
```

### Clear-Cache

```powershell
Clear-Cache
```

Cette fonction vide complètement le cache.

#### Exemple

```powershell
Clear-Cache
```

### Get-CacheStatistics

```powershell
Get-CacheStatistics
```

Cette fonction retourne des statistiques sur l'utilisation du cache.

#### Exemple

```powershell
$stats = Get-CacheStatistics
$stats | Format-List
```

### Invoke-CachedFunction

```powershell
Invoke-CachedFunction -ScriptBlock <scriptblock> -CacheKey <string> [-TTL <int>] [-Arguments <object[]>]
```

Cette fonction exécute une fonction avec mise en cache des résultats.

#### Paramètres

- **ScriptBlock** : Script block à exécuter.
- **CacheKey** : Clé à utiliser pour le cache.
- **TTL** : Durée de vie du résultat en secondes (par défaut : valeur de DefaultTTL).
- **Arguments** : Arguments à passer au script block.

#### Exemple

```powershell
$result = Invoke-CachedFunction -ScriptBlock { param($a, $b) $a + $b } -CacheKey "Addition_2_3" -Arguments @(2, 3)
```

## Politiques d'éviction

Le module prend en charge trois politiques d'éviction pour gérer la taille du cache :

### LRU (Least Recently Used)

La politique LRU supprime les éléments les moins récemment utilisés lorsque le cache est plein. C'est la politique par défaut et elle est généralement la plus efficace pour la plupart des cas d'utilisation.

### LFU (Least Frequently Used)

La politique LFU supprime les éléments les moins fréquemment utilisés lorsque le cache est plein. Cette politique est utile lorsque certains éléments sont accédés très fréquemment et doivent rester dans le cache.

### FIFO (First In First Out)

La politique FIFO supprime les éléments les plus anciens lorsque le cache est plein. Cette politique est simple mais peut être moins efficace que LRU ou LFU.

## Exemples d'utilisation

### Mise en cache simple

```powershell
# Initialiser le gestionnaire de cache
Initialize-CacheManager -Enabled $true -MaxItems 100 -DefaultTTL 3600 -EvictionPolicy "LRU"

# Fonction coûteuse à mettre en cache
function Get-ExpensiveData {
    param($id)
    
    Write-Host "Calcul coûteux pour l'ID $id..."
    Start-Sleep -Seconds 2  # Simuler une opération coûteuse
    return "Données pour l'ID $id"
}

# Fonction avec mise en cache
function Get-CachedData {
    param($id)
    
    $cacheKey = "ExpensiveData_$id"
    
    # Vérifier si le résultat est dans le cache
    $cachedResult = Get-CacheItem -Key $cacheKey
    
    if ($null -ne $cachedResult) {
        Write-Host "Résultat trouvé dans le cache pour l'ID $id"
        return $cachedResult
    }
    
    # Exécuter la fonction coûteuse
    $result = Get-ExpensiveData -id $id
    
    # Mettre en cache le résultat
    Set-CacheItem -Key $cacheKey -Value $result -TTL 3600
    
    return $result
}

# Utilisation
$result1 = Get-CachedData -id 123  # Calcul coûteux
$result2 = Get-CachedData -id 123  # Récupéré du cache
```

### Utilisation de Invoke-CachedFunction

```powershell
# Initialiser le gestionnaire de cache
Initialize-CacheManager -Enabled $true -MaxItems 100 -DefaultTTL 3600 -EvictionPolicy "LRU"

# Fonction coûteuse
$expensiveFunction = {
    param($id)
    
    Write-Host "Calcul coûteux pour l'ID $id..."
    Start-Sleep -Seconds 2  # Simuler une opération coûteuse
    return "Données pour l'ID $id"
}

# Premier appel (sans cache)
$result1 = Invoke-CachedFunction -ScriptBlock $expensiveFunction -CacheKey "ExpensiveFunction_123" -Arguments @(123)

# Deuxième appel (avec cache)
$result2 = Invoke-CachedFunction -ScriptBlock $expensiveFunction -CacheKey "ExpensiveFunction_123" -Arguments @(123)

# Afficher les statistiques du cache
Get-CacheStatistics | Format-List
```

### Mise en cache avec expiration

```powershell
# Initialiser le gestionnaire de cache
Initialize-CacheManager -Enabled $true -MaxItems 100 -DefaultTTL 5 -EvictionPolicy "LRU"

# Fonction coûteuse
$expensiveFunction = {
    param($id)
    
    Write-Host "Calcul coûteux pour l'ID $id..."
    Start-Sleep -Seconds 1  # Simuler une opération coûteuse
    return "Données pour l'ID $id ($(Get-Date))"
}

# Premier appel
$result1 = Invoke-CachedFunction -ScriptBlock $expensiveFunction -CacheKey "ExpensiveFunction_123" -Arguments @(123)
Write-Host "Résultat 1: $result1"

# Deuxième appel (avec cache)
$result2 = Invoke-CachedFunction -ScriptBlock $expensiveFunction -CacheKey "ExpensiveFunction_123" -Arguments @(123)
Write-Host "Résultat 2: $result2"

# Attendre l'expiration du cache
Write-Host "Attente de l'expiration du cache (5 secondes)..."
Start-Sleep -Seconds 6

# Troisième appel (après expiration)
$result3 = Invoke-CachedFunction -ScriptBlock $expensiveFunction -CacheKey "ExpensiveFunction_123" -Arguments @(123)
Write-Host "Résultat 3: $result3"
```

## Statistiques de cache

Le module fournit des statistiques détaillées sur l'utilisation du cache via la fonction `Get-CacheStatistics`. Ces statistiques incluent :

- **Enabled** : Indique si le cache est activé.
- **ItemCount** : Nombre d'éléments actuellement dans le cache.
- **MaxItems** : Nombre maximum d'éléments autorisés dans le cache.
- **UsagePercentage** : Pourcentage d'utilisation du cache.
- **Hits** : Nombre de fois où un élément a été trouvé dans le cache.
- **Misses** : Nombre de fois où un élément n'a pas été trouvé dans le cache.
- **TotalRequests** : Nombre total de requêtes au cache.
- **HitRate** : Taux de succès du cache (Hits / TotalRequests).
- **Evictions** : Nombre d'éléments évincés du cache.
- **EvictionPolicy** : Politique d'éviction utilisée.

Ces statistiques sont utiles pour mesurer l'efficacité du cache et ajuster les paramètres si nécessaire.

## Bonnes pratiques

Pour tirer le meilleur parti du module de gestion de cache, suivez ces bonnes pratiques :

1. **Choisissez une taille de cache appropriée** : Une taille trop petite entraînera trop d'évictions, tandis qu'une taille trop grande consommera trop de mémoire.

2. **Ajustez la durée de vie (TTL)** : Choisissez une durée de vie adaptée à la fréquence de changement des données. Des données qui changent rarement peuvent avoir un TTL plus long.

3. **Utilisez des clés de cache significatives** : Les clés de cache doivent être uniques et refléter les paramètres qui influencent le résultat.

4. **Surveillez les statistiques de cache** : Utilisez `Get-CacheStatistics` pour surveiller l'efficacité du cache et ajuster les paramètres si nécessaire.

5. **Choisissez la bonne politique d'éviction** : LRU est généralement un bon choix par défaut, mais LFU peut être meilleur si certains éléments sont accédés très fréquemment.

6. **Évitez de mettre en cache des objets trop volumineux** : Le cache est conçu pour stocker des résultats de taille raisonnable. Des objets trop volumineux peuvent consommer trop de mémoire.

7. **Utilisez Invoke-CachedFunction pour simplifier la mise en cache** : Cette fonction gère automatiquement la vérification du cache et la mise en cache du résultat.

## Intégration avec d'autres modules

Le module de gestion de cache peut être intégré avec d'autres modules pour améliorer leurs performances. Voici quelques exemples d'intégration :

### Intégration avec UnifiedFileProcessor

```powershell
# Importer les modules
. ".\modules\CacheManager.ps1"
. ".\modules\UnifiedFileProcessor.ps1"

# Initialiser les modules
Initialize-CacheManager -Enabled $true -MaxItems 100 -DefaultTTL 3600 -EvictionPolicy "LRU"
Initialize-UnifiedFileProcessor -EnableCache

# Utiliser la fonction de traitement avec mise en cache
$result = Invoke-CachedFileProcessing -InputFile "input.json" -OutputFile "output.yaml" -InputFormat "JSON" -OutputFormat "YAML"
```

### Intégration avec des fonctions personnalisées

```powershell
# Importer le module
. ".\modules\CacheManager.ps1"

# Initialiser le gestionnaire de cache
Initialize-CacheManager -Enabled $true -MaxItems 100 -DefaultTTL 3600 -EvictionPolicy "LRU"

# Fonction personnalisée avec mise en cache
function Get-CachedData {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [int]$CacheTTL = 3600
    )
    
    # Générer une clé de cache
    $cacheKey = "Data_${Source}_${Query}"
    
    # Définir le script block pour récupérer les données
    $scriptBlock = {
        param($Source, $Query)
        
        # Simuler une requête coûteuse
        Write-Host "Récupération des données depuis $Source avec la requête $Query..."
        Start-Sleep -Seconds 2
        
        # Retourner les données
        return @{
            Source = $Source
            Query = $Query
            Timestamp = Get-Date
            Data = "Données pour $Query"
        }
    }
    
    # Exécuter avec mise en cache
    $result = Invoke-CachedFunction -ScriptBlock $scriptBlock -CacheKey $cacheKey -TTL $CacheTTL -Arguments @($Source, $Query)
    
    return $result
}

# Utilisation
$data1 = Get-CachedData -Source "Database" -Query "SELECT * FROM users"  # Requête coûteuse
$data2 = Get-CachedData -Source "Database" -Query "SELECT * FROM users"  # Récupéré du cache
```
