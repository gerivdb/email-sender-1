# Optimisation du traitement parallèle

## Vue d'ensemble

Le module d'optimisation du traitement parallèle fournit des fonctionnalités pour exécuter des tâches en parallèle, améliorant ainsi les performances des scripts PowerShell. Ce module propose plusieurs méthodes de parallélisation et peut déterminer automatiquement la méthode la plus efficace pour un cas d'utilisation spécifique.

## Installation

Le script est disponible dans le dossier `scripts/performance` du projet. Pour l'importer :

```powershell
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "scripts\performance\Optimize-ParallelExecution.ps1"
. $scriptPath
```

## Fonctions principales

### Invoke-SequentialProcessing

Exécute un traitement séquentiel sur un ensemble de données.

#### Syntaxe

```powershell
Invoke-SequentialProcessing -Data <Array> -ScriptBlock <ScriptBlock>
```

#### Paramètres

- **Data** : Tableau des éléments à traiter.
- **ScriptBlock** : Script à exécuter pour chaque élément.

#### Valeur de retour

Un objet avec les propriétés suivantes :
- **Results** : Résultats du traitement.
- **ExecutionTime** : Temps d'exécution total.
- **ItemsProcessed** : Nombre d'éléments traités.

#### Exemple

```powershell
$data = 1..10
$scriptBlock = {
    param($item)
    return $item * 2
}

$result = Invoke-SequentialProcessing -Data $data -ScriptBlock $scriptBlock
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalMilliseconds) ms"
```

### Invoke-RunspacePoolProcessing

Exécute un traitement parallèle en utilisant un pool de runspaces.

#### Syntaxe

```powershell
Invoke-RunspacePoolProcessing -Data <Array> -ScriptBlock <ScriptBlock> [-MaxThreads <Int32>]
```

#### Paramètres

- **Data** : Tableau des éléments à traiter.
- **ScriptBlock** : Script à exécuter pour chaque élément.
- **MaxThreads** : Nombre maximum de threads à utiliser (par défaut : nombre de processeurs).

#### Valeur de retour

Un objet avec les propriétés suivantes :
- **Results** : Résultats du traitement.
- **ExecutionTime** : Temps d'exécution total.
- **ItemsProcessed** : Nombre d'éléments traités.
- **MaxThreads** : Nombre maximum de threads utilisés.

#### Exemple

```powershell
$data = 1..10
$scriptBlock = {
    param($item)
    Start-Sleep -Milliseconds 100  # Simuler une tâche longue
    return $item * 2
}

$result = Invoke-RunspacePoolProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalMilliseconds) ms"
```

### Invoke-BatchParallelProcessing

Exécute un traitement parallèle par lots.

#### Syntaxe

```powershell
Invoke-BatchParallelProcessing -Data <Array> -ScriptBlock <ScriptBlock> [-MaxThreads <Int32>] [-ChunkSize <Int32>]
```

#### Paramètres

- **Data** : Tableau des éléments à traiter.
- **ScriptBlock** : Script à exécuter pour chaque élément.
- **MaxThreads** : Nombre maximum de threads à utiliser (par défaut : nombre de processeurs).
- **ChunkSize** : Nombre d'éléments par lot (par défaut : calculé automatiquement).

#### Valeur de retour

Un objet avec les propriétés suivantes :
- **Results** : Résultats du traitement.
- **ExecutionTime** : Temps d'exécution total.
- **ItemsProcessed** : Nombre d'éléments traités.
- **MaxThreads** : Nombre maximum de threads utilisés.
- **ChunkSize** : Taille des lots utilisée.
- **BatchCount** : Nombre de lots traités.

#### Exemple

```powershell
$data = 1..100
$scriptBlock = {
    param($item)
    Start-Sleep -Milliseconds 10  # Simuler une tâche avec surcharge de démarrage
    return $item * 2
}

$result = Invoke-BatchParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4 -ChunkSize 10
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalMilliseconds) ms"
```

### Invoke-ForEachParallelProcessing

Exécute un traitement parallèle en utilisant ForEach-Object -Parallel (PowerShell 7+ uniquement).

#### Syntaxe

```powershell
Invoke-ForEachParallelProcessing -Data <Array> -ScriptBlock <ScriptBlock> [-MaxThreads <Int32>]
```

#### Paramètres

- **Data** : Tableau des éléments à traiter.
- **ScriptBlock** : Script à exécuter pour chaque élément.
- **MaxThreads** : Nombre maximum de threads à utiliser (par défaut : nombre de processeurs).

#### Valeur de retour

Un objet avec les propriétés suivantes :
- **Results** : Résultats du traitement.
- **ExecutionTime** : Temps d'exécution total.
- **ItemsProcessed** : Nombre d'éléments traités.
- **MaxThreads** : Nombre maximum de threads utilisés.

#### Exemple

```powershell
# Nécessite PowerShell 7+
$data = 1..10
$scriptBlock = {
    param($item)
    Start-Sleep -Milliseconds 100  # Simuler une tâche longue
    return $item * 2
}

$result = Invoke-ForEachParallelProcessing -Data $data -ScriptBlock $scriptBlock -MaxThreads 4
Write-Host "Temps d'exécution: $($result.ExecutionTime.TotalMilliseconds) ms"
```

### Optimize-ParallelExecution

Détermine et utilise automatiquement la méthode de parallélisation la plus efficace.

#### Syntaxe

```powershell
Optimize-ParallelExecution -Data <Array> -ScriptBlock <ScriptBlock> [-MaxThreads <Int32>] [-ChunkSize <Int32>] [-Measure]
```

#### Paramètres

- **Data** : Tableau des éléments à traiter.
- **ScriptBlock** : Script à exécuter pour chaque élément.
- **MaxThreads** : Nombre maximum de threads à utiliser (par défaut : nombre de processeurs).
- **ChunkSize** : Taille des lots pour le traitement par lots (par défaut : calculé automatiquement).
- **Measure** : Compare les différentes méthodes et retourne les résultats de mesure.

#### Valeur de retour

Si **Measure** est spécifié, un objet avec les propriétés suivantes :
- **Sequential** : Résultats du traitement séquentiel.
- **RunspacePool** : Résultats du traitement avec Runspace Pool.
- **BatchParallel** : Résultats du traitement par lots.
- **ForEachParallel** : Résultats du traitement avec ForEach-Object -Parallel (PowerShell 7+ uniquement).
- **FastestMethod** : Nom de la méthode la plus rapide.
- **FastestTime** : Temps d'exécution de la méthode la plus rapide.
- **Recommendations** : Recommandations pour l'optimisation.

Sinon, les résultats du traitement avec la méthode optimale.

#### Exemple

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
```

## Choix de la méthode de parallélisation

Le choix de la méthode de parallélisation dépend de plusieurs facteurs :

1. **Taille des données** : Pour les petits ensembles de données, le traitement séquentiel peut être plus rapide en raison de la surcharge de création des threads.

2. **Durée des tâches** :
   - **Tâches courtes** (< 10 ms) : Le traitement par lots est généralement plus efficace.
   - **Tâches moyennes** (10-100 ms) : Runspace Pool ou ForEach-Object -Parallel.
   - **Tâches longues** (> 100 ms) : Toutes les méthodes parallèles sont efficaces.

3. **Surcharge de démarrage** : Si chaque tâche a une surcharge de démarrage importante, le traitement par lots est recommandé.

4. **Version de PowerShell** :
   - **PowerShell 5.1** : Utiliser Runspace Pool ou traitement par lots.
   - **PowerShell 7+** : ForEach-Object -Parallel est également disponible.

## Performance

Les performances dépendent de la nature des tâches et de l'environnement d'exécution :

- **Traitement séquentiel** : Baseline pour la comparaison.
- **Runspace Pool** : 2-8x plus rapide pour les tâches longues.
- **Traitement par lots** : 1.5-5x plus rapide pour les tâches avec surcharge de démarrage.
- **ForEach-Object -Parallel** : 2-6x plus rapide pour les tâches moyennes à longues (PowerShell 7+ uniquement).

## Compatibilité

- **Invoke-SequentialProcessing**, **Invoke-RunspacePoolProcessing**, **Invoke-BatchParallelProcessing** : PowerShell 5.1 et versions ultérieures.
- **Invoke-ForEachParallelProcessing** : PowerShell 7 et versions ultérieures uniquement.
- **Optimize-ParallelExecution** : Compatible avec toutes les versions, mais n'utilisera ForEach-Object -Parallel que sur PowerShell 7+.

## Limitations connues

- Les tâches qui modifient l'état global peuvent causer des problèmes de concurrence.
- Les objets partagés entre les threads doivent être thread-safe.
- La communication entre les threads est limitée.

## Exemples avancés

### Traitement parallèle avec état partagé

```powershell
# Créer un objet thread-safe pour partager l'état
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
```

### Traitement parallèle avec limitation de débit

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
```
