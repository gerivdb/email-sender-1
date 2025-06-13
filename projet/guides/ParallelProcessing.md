# Guide d'utilisation : Traitement parallèle

## Introduction

Ce guide explique comment utiliser les fonctionnalités de traitement parallèle pour améliorer les performances de vos scripts PowerShell en exécutant des tâches simultanément.

## Pourquoi utiliser le traitement parallèle ?

Le traitement parallèle offre plusieurs avantages :

- **Performances améliorées** : Exécution plus rapide des tâches.
- **Utilisation optimale des ressources** : Exploitation de tous les cœurs du processeur.
- **Réduction des temps d'attente** : Traitement simultané des opérations d'E/S.
- **Évolutivité** : Adaptation automatique au nombre de processeurs disponibles.

## Installation

Aucune installation spéciale n'est requise. Les scripts de traitement parallèle sont inclus dans le projet.

## Utilisation de base

### Importer le script

Pour utiliser les fonctionnalités de traitement parallèle, importez d'abord le script :

```powershell
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "scripts\performance\Optimize-ParallelExecution.ps1"
. $scriptPath
```plaintext
### Traitement séquentiel (référence)

Pour établir une référence de performance, vous pouvez utiliser le traitement séquentiel :

```powershell
$data = 1..10
$scriptBlock = {
    param($item)
    Start-Sleep -Milliseconds 100  # Simuler une tâche longue

    return $item * 2
}

$result = Invoke-SequentialProcessing -Data $data -ScriptBlock $scriptBlock
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalMilliseconds) ms"
```plaintext
### Traitement parallèle avec Runspace Pool

Pour exécuter des tâches en parallèle à l'aide d'un pool de runspaces :

```powershell
$data = 1..10
$scriptBlock = {
    param($item)
    Start-Sleep -Milliseconds 100  # Simuler une tâche longue

    return $item * 2
}

$result = Invoke-RunspacePoolProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalMilliseconds) ms"
```plaintext
### Traitement parallèle par lots

Pour exécuter des tâches en parallèle par lots (utile pour les tâches avec surcharge de démarrage) :

```powershell
$data = 1..100
$scriptBlock = {
    param($item)
    Start-Sleep -Milliseconds 10  # Simuler une tâche avec surcharge de démarrage

    return $item * 2
}

$result = Invoke-BatchParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -ChunkSize 10
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalMilliseconds) ms"
```plaintext
### Traitement parallèle avec ForEach-Object -Parallel (PowerShell 7+ uniquement)

Si vous utilisez PowerShell 7 ou une version ultérieure, vous pouvez utiliser ForEach-Object -Parallel :

```powershell
$data = 1..10
$scriptBlock = {
    param($item)
    Start-Sleep -Milliseconds 100  # Simuler une tâche longue

    return $item * 2
}

$result = Invoke-ForEachParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalMilliseconds) ms"
```plaintext
### Optimisation automatique

Pour déterminer et utiliser automatiquement la méthode de parallélisation la plus efficace :

```powershell
$data = 1..100
$scriptBlock = {
    param($item)
    Start-Sleep -Milliseconds 10
    return $item * 2
}

# Mesurer les performances des différentes méthodes

$measurements = Optimize-ParallelExecution -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -ChunkSize 10 -Measure

Write-Host "Méthode la plus rapide: $($measurements.FastestMethod)"
Write-Host "Temps d'exécution: $($measurements.FastestTime) ms"

# Exécuter avec la méthode optimale

$result = Optimize-ParallelExecution -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -ChunkSize 10
```plaintext
## Options avancées

### Spécifier le nombre de threads

Pour contrôler le nombre de threads utilisés :

```powershell
$result = Invoke-RunspacePoolProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 8
```plaintext
Par défaut, le nombre de threads est égal au nombre de processeurs logiques disponibles.

### Spécifier la taille des lots

Pour le traitement par lots, vous pouvez spécifier la taille des lots :

```powershell
$result = Invoke-BatchParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -ChunkSize 20
```plaintext
Si vous ne spécifiez pas la taille des lots, elle sera calculée automatiquement en fonction du nombre d'éléments et du nombre de threads.

### Partager des variables entre les threads

Pour partager des variables entre les threads, utilisez un objet thread-safe :

```powershell
$syncHash = [hashtable]::Synchronized(@{
    TotalProcessed = 0
    Errors = @()
})

$data = 1..100
$scriptBlock = {
    param($item, $syncHash)
    
    try {
        # Simuler une tâche

        Start-Sleep -Milliseconds 10
        $result = $item * 2
        
        # Mettre à jour l'état partagé

        $syncHash.TotalProcessed++
        
        return $result
    }
    catch {
        # Enregistrer l'erreur

        $syncHash.Errors += "Erreur sur l'élément $item : $_"
        return $null
    }
}

# Créer un runspace pool

$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
$runspacePool.Open()

# Créer les runspaces

$runspaces = @()
foreach ($item in $data) {
    $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($item).AddArgument($syncHash)
    $powershell.RunspacePool = $runspacePool
    
    $runspaces += [PSCustomObject]@{
        PowerShell = $powershell
        Handle = $powershell.BeginInvoke()
    }
}

# Récupérer les résultats

$results = @()
foreach ($runspace in $runspaces) {
    $results += $runspace.PowerShell.EndInvoke($runspace.Handle)
    $runspace.PowerShell.Dispose()
}

# Fermer le runspace pool

$runspacePool.Close()
$runspacePool.Dispose()

# Afficher les résultats

Write-Host "Éléments traités: $($syncHash.TotalProcessed)"
Write-Host "Erreurs: $($syncHash.Errors.Count)"
```plaintext
## Exemples pratiques

### Exemple 1 : Traitement parallèle de fichiers

Supposons que vous avez un grand nombre de fichiers à traiter :

```powershell
# Obtenir tous les fichiers à traiter

$files = Get-ChildItem -Path ".\data" -Filter "*.txt" -Recurse

# Définir le script de traitement

$scriptBlock = {
    param($file)
    
    # Lire le contenu du fichier

    $content = Get-Content -Path $file.FullName -Raw
    
    # Traiter le contenu (exemple : compter les mots)

    $wordCount = ($content -split '\W+' | Where-Object { $_ -ne '' }).Count
    
    return [PSCustomObject]@{
        File = $file.Name
        Path = $file.FullName
        WordCount = $wordCount
        Size = $file.Length
    }
}

# Traiter les fichiers en parallèle

$result = Optimize-ParallelExecution -Data $files -ScriptBlock $scriptBlock -MaxThreads 8

# Afficher les résultats

$result.Results | Sort-Object -Property WordCount -Descending | Format-Table -AutoSize
```plaintext
### Exemple 2 : Requêtes API parallèles

Si vous devez effectuer de nombreuses requêtes API :

```powershell
# Liste des IDs à récupérer

$userIds = 1..100

# Définir le script de requête API

$scriptBlock = {
    param($userId)
    
    try {
        # Simuler une requête API

        $uri = "https://jsonplaceholder.typicode.com/users/$userId"
        $response = Invoke-RestMethod -Uri $uri -Method Get
        
        return [PSCustomObject]@{
            UserId = $userId
            Name = $response.name
            Email = $response.email
            Success = $true
        }
    }
    catch {
        return [PSCustomObject]@{
            UserId = $userId
            Error = $_.Exception.Message
            Success = $false
        }
    }
}

# Exécuter les requêtes en parallèle

$result = Invoke-RunspacePoolProcessing -Data $userIds -ScriptBlock $scriptBlock -MaxThreads 10

# Afficher les résultats

$successCount = ($result.Results | Where-Object { $_.Success }).Count
$failureCount = ($result.Results | Where-Object { -not $_.Success }).Count

Write-Host "Requêtes réussies: $successCount"
Write-Host "Requêtes échouées: $failureCount"
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalSeconds) secondes"
```plaintext
### Exemple 3 : Traitement parallèle avec limitation de débit

Si vous devez limiter le nombre de requêtes par seconde :

```powershell
function Invoke-ThrottledParallelProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Data,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = [Environment]::ProcessorCount,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxItemsPerSecond = 0
    )
    
    $results = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $itemsProcessed = 0
    
    # Créer un runspace pool

    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $Host)
    $runspacePool.Open()
    
    # Créer les runspaces

    $runspaces = @()
    
    foreach ($item in $Data) {
        # Limiter le débit si nécessaire

        if ($MaxItemsPerSecond -gt 0 -and $itemsProcessed -gt 0) {
            $expectedTime = $itemsProcessed / $MaxItemsPerSecond
            $actualTime = $stopwatch.Elapsed.TotalSeconds
            
            if ($actualTime -lt $expectedTime) {
                $sleepTime = ($expectedTime - $actualTime) * 1000
                Start-Sleep -Milliseconds $sleepTime
            }
        }
        
        $powershell = [powershell]::Create().AddScript($ScriptBlock).AddArgument($item)
        $powershell.RunspacePool = $runspacePool
        
        $runspaces += [PSCustomObject]@{
            PowerShell = $powershell
            Handle = $powershell.BeginInvoke()
            Item = $item
            StartTime = Get-Date
        }
        
        $itemsProcessed++
    }
    
    # Récupérer les résultats

    foreach ($runspace in $runspaces) {
        $results += [PSCustomObject]@{
            Item = $runspace.Item
            Result = $runspace.PowerShell.EndInvoke($runspace.Handle)
            ExecutionTime = (Get-Date) - $runspace.StartTime
        }
        
        $runspace.PowerShell.Dispose()
    }
    
    # Fermer le runspace pool

    $runspacePool.Close()
    $runspacePool.Dispose()
    
    $stopwatch.Stop()
    
    return [PSCustomObject]@{
        Results = $results
        ExecutionTime = $stopwatch.Elapsed
        ItemsProcessed = $itemsProcessed
        ItemsPerSecond = $itemsProcessed / $stopwatch.Elapsed.TotalSeconds
        MaxThreads = $MaxThreads
        MaxItemsPerSecond = $MaxItemsPerSecond
    }
}

# Exemple d'utilisation

$data = 1..100
$scriptBlock = {
    param($item)
    # Simuler une API avec limite de débit

    Start-Sleep -Milliseconds 50
    return $item * 2
}

$result = Invoke-ThrottledParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -MaxItemsPerSecond 20
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalSeconds) secondes"
Write-Host "Éléments par seconde: $($result.ItemsPerSecond)"
```plaintext
## Bonnes pratiques

### Pour un traitement parallèle efficace

1. **Choisissez la bonne méthode** en fonction de la nature de vos tâches :
   - **Tâches courtes** (< 10 ms) : Traitement par lots.
   - **Tâches moyennes** (10-100 ms) : Runspace Pool ou ForEach-Object -Parallel.
   - **Tâches longues** (> 100 ms) : Toutes les méthodes parallèles sont efficaces.

2. **Optimisez le nombre de threads** :
   - Trop peu de threads : Sous-utilisation des ressources.
   - Trop de threads : Surcharge due au changement de contexte.
   - Règle générale : Nombre de processeurs logiques + 1-2 pour les tâches d'E/S.

3. **Gérez correctement les erreurs** :
   - Capturez les exceptions dans chaque thread.
   - Utilisez un objet thread-safe pour collecter les erreurs.

4. **Évitez les problèmes de concurrence** :
   - Utilisez des objets thread-safe pour les données partagées.
   - Évitez de modifier des variables globales.
   - Utilisez des verrous (locks) si nécessaire.

5. **Surveillez les performances** :
   - Mesurez les temps d'exécution pour différentes configurations.
   - Ajustez les paramètres en fonction des résultats.

## Dépannage

### Problème : Performances inférieures aux attentes

**Solution** : 
- Vérifiez que vos tâches sont suffisamment longues pour justifier le traitement parallèle.
- Réduisez le nombre de threads si vous observez une surcharge.
- Utilisez le traitement par lots pour les tâches avec surcharge de démarrage.

### Problème : Erreurs de concurrence

**Solution** : 
- Utilisez des objets thread-safe pour les données partagées.
- Évitez de modifier des variables globales.
- Utilisez des verrous (locks) pour les ressources partagées.

### Problème : Consommation excessive de mémoire

**Solution** : 
- Traitez les données par lots plus petits.
- Libérez les ressources après utilisation.
- Utilisez `Dispose()` pour les objets qui implémentent `IDisposable`.

## Intégration avec d'autres outils

### Intégration avec la segmentation d'entrées

Vous pouvez combiner le traitement parallèle avec la segmentation d'entrées pour traiter efficacement de grandes quantités de données :

```powershell
Import-Module .\modules\InputSegmentation.psm1
. .\scripts\performance\Optimize-ParallelExecution.ps1

$largeInput = Get-Content -Path ".\data\large_file.txt" -Raw
$segments = Split-Input -Input $largeInput -ChunkSizeKB 5

$results = Optimize-ParallelExecution -Data $segments -ScriptBlock {
    param($segment)
    # Traiter le segment

    return "Processed: $($segment.Length) bytes"
} -MaxThreads 4
```plaintext
### Intégration avec le cache prédictif

Vous pouvez combiner le traitement parallèle avec le cache prédictif pour optimiser les performances :

```powershell
Import-Module .\modules\PredictiveCache.psm1
. .\scripts\performance\Optimize-ParallelExecution.ps1

Initialize-PredictiveCache -Enabled $true -CachePath ".\cache" -ModelPath ".\models" -MaxCacheSize 100MB -DefaultTTL 3600

$data = 1..100
$scriptBlock = {
    param($item)
    
    $cacheKey = "item:$item"
    $cachedValue = Get-PredictiveCache -Key $cacheKey
    
    if ($cachedValue -ne $null) {
        return $cachedValue
    }
    
    # Simuler une tâche longue

    Start-Sleep -Milliseconds 100
    $result = $item * 2
    
    # Mettre en cache le résultat

    Set-PredictiveCache -Key $cacheKey -Value $result -TTL 3600
    
    return $result
}

$result = Optimize-ParallelExecution -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
```plaintext
## Conclusion

Le traitement parallèle est un outil puissant pour améliorer les performances de vos scripts PowerShell. En choisissant la méthode appropriée et en suivant les bonnes pratiques, vous pouvez réduire considérablement les temps d'exécution et optimiser l'utilisation des ressources.

Pour plus d'informations techniques, consultez la [documentation technique du traitement parallèle](../technical/ParallelProcessing.md).
