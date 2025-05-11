# ParallelExecution.ps1
# Script implémentant l'exécution parallèle des requêtes
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$optimizationPath = Join-Path -Path $scriptPath -ChildPath "SearchOptimization.ps1"

if (Test-Path -Path $optimizationPath) {
    . $optimizationPath
} else {
    Write-Error "Le fichier SearchOptimization.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un pool de threads
class ThreadPool {
    # Nombre maximal de threads
    [int]$MaxThreads
    
    # Liste des tâches en cours d'exécution
    [System.Collections.Generic.List[System.Threading.Tasks.Task]]$RunningTasks
    
    # Constructeur par défaut
    ThreadPool() {
        $this.MaxThreads = [Environment]::ProcessorCount
        $this.RunningTasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
    }
    
    # Constructeur avec nombre maximal de threads
    ThreadPool([int]$maxThreads) {
        $this.MaxThreads = $maxThreads
        $this.RunningTasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
    }
    
    # Méthode pour exécuter une tâche
    [System.Threading.Tasks.Task] RunTask([scriptblock]$scriptBlock) {
        # Créer une tâche
        $task = [System.Threading.Tasks.Task]::Run($scriptBlock)
        
        # Ajouter la tâche à la liste
        $this.RunningTasks.Add($task)
        
        # Nettoyer les tâches terminées
        $this.CleanupTasks()
        
        return $task
    }
    
    # Méthode pour exécuter une tâche avec un résultat
    [System.Threading.Tasks.Task[T]] RunTask[T]([scriptblock]$scriptBlock) {
        # Créer une tâche
        $task = [System.Threading.Tasks.Task[T]]::Run($scriptBlock)
        
        # Ajouter la tâche à la liste
        $this.RunningTasks.Add($task)
        
        # Nettoyer les tâches terminées
        $this.CleanupTasks()
        
        return $task
    }
    
    # Méthode pour attendre toutes les tâches
    [void] WaitAll() {
        [System.Threading.Tasks.Task]::WaitAll($this.RunningTasks.ToArray())
        $this.CleanupTasks()
    }
    
    # Méthode pour attendre une tâche
    [void] WaitTask([System.Threading.Tasks.Task]$task) {
        $task.Wait()
        $this.CleanupTasks()
    }
    
    # Méthode pour nettoyer les tâches terminées
    [void] CleanupTasks() {
        $tasksToRemove = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
        
        foreach ($task in $this.RunningTasks) {
            if ($task.IsCompleted -or $task.IsCanceled -or $task.IsFaulted) {
                $tasksToRemove.Add($task)
            }
        }
        
        foreach ($task in $tasksToRemove) {
            $this.RunningTasks.Remove($task)
        }
    }
    
    # Méthode pour obtenir le nombre de tâches en cours d'exécution
    [int] GetRunningTaskCount() {
        $this.CleanupTasks()
        return $this.RunningTasks.Count
    }
    
    # Méthode pour attendre qu'un slot soit disponible
    [void] WaitForAvailableSlot() {
        while ($this.GetRunningTaskCount() -ge $this.MaxThreads) {
            Start-Sleep -Milliseconds 10
        }
    }
}

# Classe pour représenter un moteur de recherche parallèle
class ParallelSearchEngine {
    # Moteur de recherche optimisé
    [OptimizedSearchEngine]$SearchEngine
    
    # Pool de threads
    [ThreadPool]$ThreadPool
    
    # Constructeur par défaut
    ParallelSearchEngine() {
        $this.SearchEngine = $null
        $this.ThreadPool = [ThreadPool]::new()
    }
    
    # Constructeur avec moteur de recherche
    ParallelSearchEngine([OptimizedSearchEngine]$searchEngine) {
        $this.SearchEngine = $searchEngine
        $this.ThreadPool = [ThreadPool]::new()
    }
    
    # Constructeur complet
    ParallelSearchEngine([OptimizedSearchEngine]$searchEngine, [int]$maxThreads) {
        $this.SearchEngine = $searchEngine
        $this.ThreadPool = [ThreadPool]::new($maxThreads)
    }
    
    # Méthode pour rechercher des documents en parallèle
    [hashtable] Search([string]$queryText, [int]$limit = 100, [int]$offset = 0) {
        # Analyser la requête
        $query = $this.SearchEngine.QueryParser.Parse($queryText)
        
        # Exécuter la requête en parallèle
        return $this.ExecuteQueryParallel($query, $limit, $offset)
    }
    
    # Méthode pour exécuter une requête en parallèle
    [hashtable] ExecuteQueryParallel([SearchQuery]$query, [int]$limit = 100, [int]$offset = 0) {
        # Résultat de la recherche
        $result = @{
            total = 0
            documents = @()
            scores = @{}
            query = $query.ToString()
            execution_time_ms = 0
            parallel_tasks = 0
        }
        
        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Dictionnaire synchronisé pour les scores des documents
        $documentScores = [System.Collections.Concurrent.ConcurrentDictionary[string, double]]::new()
        
        # Liste des tâches
        $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
        
        # Exécuter les termes de la requête en parallèle
        foreach ($term in $query.Terms) {
            $this.ThreadPool.WaitForAvailableSlot()
            
            $task = $this.ThreadPool.RunTask({
                param($term, $searchEngine, $documentScores, $queryType)
                
                $termResults = $searchEngine.ExecuteTerm($term)
                
                # Fusionner les résultats
                foreach ($docId in $termResults.Keys) {
                    $score = $termResults[$docId]
                    
                    switch ($queryType) {
                        "AND" {
                            $documentScores.AddOrUpdate($docId, $score, { param($key, $oldValue) $oldValue + $score })
                        }
                        "OR" {
                            $documentScores.AddOrUpdate($docId, $score, { param($key, $oldValue) $oldValue + $score })
                        }
                        "NOT" {
                            $documentScores.TryRemove($docId, [ref]$null)
                        }
                    }
                }
            }.GetNewClosure())
            
            $tasks.Add($task)
        }
        
        # Exécuter les sous-requêtes en parallèle
        foreach ($subQuery in $query.SubQueries) {
            $this.ThreadPool.WaitForAvailableSlot()
            
            $task = $this.ThreadPool.RunTask({
                param($subQuery, $searchEngine, $documentScores, $queryType, $limit, $offset)
                
                $subQueryResults = $searchEngine.ExecuteQuery($subQuery, $limit, $offset)
                
                # Fusionner les résultats
                foreach ($docId in $subQueryResults.scores.Keys) {
                    $score = $subQueryResults.scores[$docId]
                    
                    switch ($queryType) {
                        "AND" {
                            $documentScores.AddOrUpdate($docId, $score, { param($key, $oldValue) $oldValue + $score })
                        }
                        "OR" {
                            $documentScores.AddOrUpdate($docId, $score, { param($key, $oldValue) $oldValue + $score })
                        }
                        "NOT" {
                            $documentScores.TryRemove($docId, [ref]$null)
                        }
                    }
                }
            }.GetNewClosure())
            
            $tasks.Add($task)
        }
        
        # Attendre que toutes les tâches soient terminées
        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
        
        # Trier les documents par score
        $sortedDocuments = $documentScores.GetEnumerator() | Sort-Object -Property Value -Descending
        
        # Appliquer la pagination
        $pagedDocuments = $sortedDocuments | Select-Object -Skip $offset -First $limit
        
        # Construire le résultat
        $result.total = $documentScores.Count
        $result.documents = $pagedDocuments | ForEach-Object { $_.Key }
        $result.parallel_tasks = $tasks.Count
        
        foreach ($doc in $pagedDocuments) {
            $result.scores[$doc.Key] = $doc.Value
        }
        
        # Arrêter le chronomètre
        $stopwatch.Stop()
        $result.execution_time_ms = $stopwatch.ElapsedMilliseconds
        
        return $result
    }
    
    # Méthode pour exécuter plusieurs requêtes en parallèle
    [hashtable[]] ExecuteQueriesParallel([string[]]$queries, [int]$limit = 100, [int]$offset = 0) {
        # Liste des tâches
        $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task[hashtable]]]::new()
        
        # Exécuter chaque requête dans une tâche séparée
        foreach ($queryText in $queries) {
            $this.ThreadPool.WaitForAvailableSlot()
            
            $task = $this.ThreadPool.RunTask[hashtable]({
                param($queryText, $searchEngine, $limit, $offset)
                
                return $searchEngine.Search($queryText, $limit, $offset)
            }.GetNewClosure())
            
            $tasks.Add($task)
        }
        
        # Attendre que toutes les tâches soient terminées
        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
        
        # Récupérer les résultats
        $results = [System.Collections.Generic.List[hashtable]]::new()
        
        foreach ($task in $tasks) {
            $results.Add($task.Result)
        }
        
        return $results.ToArray()
    }
}

# Classe pour représenter un gestionnaire de tâches parallèles
class ParallelTaskManager {
    # Pool de threads
    [ThreadPool]$ThreadPool
    
    # Constructeur par défaut
    ParallelTaskManager() {
        $this.ThreadPool = [ThreadPool]::new()
    }
    
    # Constructeur avec nombre maximal de threads
    ParallelTaskManager([int]$maxThreads) {
        $this.ThreadPool = [ThreadPool]::new($maxThreads)
    }
    
    # Méthode pour exécuter une tâche en parallèle
    [System.Threading.Tasks.Task] RunTask([scriptblock]$scriptBlock) {
        return $this.ThreadPool.RunTask($scriptBlock)
    }
    
    # Méthode pour exécuter une tâche avec un résultat en parallèle
    [System.Threading.Tasks.Task[T]] RunTask[T]([scriptblock]$scriptBlock) {
        return $this.ThreadPool.RunTask[T]($scriptBlock)
    }
    
    # Méthode pour exécuter plusieurs tâches en parallèle
    [void] RunTasks([scriptblock[]]$scriptBlocks) {
        $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
        
        foreach ($scriptBlock in $scriptBlocks) {
            $this.ThreadPool.WaitForAvailableSlot()
            $task = $this.ThreadPool.RunTask($scriptBlock)
            $tasks.Add($task)
        }
        
        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
    }
    
    # Méthode pour exécuter une action sur chaque élément d'une collection en parallèle
    [void] ForEach([object[]]$collection, [scriptblock]$action) {
        $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
        
        foreach ($item in $collection) {
            $this.ThreadPool.WaitForAvailableSlot()
            
            $task = $this.ThreadPool.RunTask({
                param($item, $action)
                
                & $action $item
            }.GetNewClosure())
            
            $tasks.Add($task)
        }
        
        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
    }
    
    # Méthode pour exécuter une fonction sur chaque élément d'une collection en parallèle et récupérer les résultats
    [object[]] Map([object[]]$collection, [scriptblock]$function) {
        $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task[object]]]::new()
        
        foreach ($item in $collection) {
            $this.ThreadPool.WaitForAvailableSlot()
            
            $task = $this.ThreadPool.RunTask[object]({
                param($item, $function)
                
                return & $function $item
            }.GetNewClosure())
            
            $tasks.Add($task)
        }
        
        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
        
        $results = [System.Collections.Generic.List[object]]::new()
        
        foreach ($task in $tasks) {
            $results.Add($task.Result)
        }
        
        return $results.ToArray()
    }
    
    # Méthode pour attendre toutes les tâches
    [void] WaitAll() {
        $this.ThreadPool.WaitAll()
    }
    
    # Méthode pour obtenir le nombre de tâches en cours d'exécution
    [int] GetRunningTaskCount() {
        return $this.ThreadPool.GetRunningTaskCount()
    }
}

# Fonction pour créer un moteur de recherche parallèle
function New-ParallelSearchEngine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [OptimizedSearchEngine]$SearchEngine,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = [Environment]::ProcessorCount
    )
    
    return [ParallelSearchEngine]::new($SearchEngine, $MaxThreads)
}

# Fonction pour créer un gestionnaire de tâches parallèles
function New-ParallelTaskManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = [Environment]::ProcessorCount
    )
    
    return [ParallelTaskManager]::new($MaxThreads)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-ParallelSearchEngine, New-ParallelTaskManager
