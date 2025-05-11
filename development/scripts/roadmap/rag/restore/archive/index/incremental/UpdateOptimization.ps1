# UpdateOptimization.ps1
# Script implémentant l'optimisation des performances de mise à jour pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modificationMergerPath = Join-Path -Path $scriptPath -ChildPath "ModificationMerger.ps1"

if (Test-Path -Path $modificationMergerPath) {
    . $modificationMergerPath
} else {
    Write-Error "Le fichier ModificationMerger.ps1 est introuvable."
    exit 1
}

# Importer les modules de performance
$parentPath = Split-Path -Parent $scriptPath
$performancePath = Join-Path -Path $parentPath -ChildPath "performance"
$parallelExecutionPath = Join-Path -Path $performancePath -ChildPath "ParallelExecution.ps1"

if (Test-Path -Path $parallelExecutionPath) {
    . $parallelExecutionPath
} else {
    Write-Error "Le fichier ParallelExecution.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une file d'attente de mise à jour optimisée
class OptimizedUpdateQueue {
    # File d'attente des documents à ajouter
    [System.Collections.Concurrent.ConcurrentQueue[IndexDocument]]$AddQueue
    
    # File d'attente des documents à mettre à jour
    [System.Collections.Concurrent.ConcurrentQueue[IndexDocument]]$UpdateQueue
    
    # File d'attente des documents à supprimer
    [System.Collections.Concurrent.ConcurrentQueue[string]]$DeleteQueue
    
    # Ensemble des IDs de documents en cours de traitement
    [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]$ProcessingIds
    
    # Constructeur par défaut
    OptimizedUpdateQueue() {
        $this.AddQueue = [System.Collections.Concurrent.ConcurrentQueue[IndexDocument]]::new()
        $this.UpdateQueue = [System.Collections.Concurrent.ConcurrentQueue[IndexDocument]]::new()
        $this.DeleteQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
        $this.ProcessingIds = [System.Collections.Concurrent.ConcurrentDictionary[string, bool]]::new()
    }
    
    # Méthode pour ajouter un document à la file d'attente d'ajout
    [bool] EnqueueAdd([IndexDocument]$document) {
        # Vérifier si le document est déjà en cours de traitement
        if ($this.ProcessingIds.ContainsKey($document.Id)) {
            return $false
        }
        
        # Marquer le document comme en cours de traitement
        $this.ProcessingIds[$document.Id] = $true
        
        # Ajouter le document à la file d'attente
        $this.AddQueue.Enqueue($document)
        
        return $true
    }
    
    # Méthode pour ajouter un document à la file d'attente de mise à jour
    [bool] EnqueueUpdate([IndexDocument]$document) {
        # Vérifier si le document est déjà en cours de traitement
        if ($this.ProcessingIds.ContainsKey($document.Id)) {
            return $false
        }
        
        # Marquer le document comme en cours de traitement
        $this.ProcessingIds[$document.Id] = $true
        
        # Ajouter le document à la file d'attente
        $this.UpdateQueue.Enqueue($document)
        
        return $true
    }
    
    # Méthode pour ajouter un document à la file d'attente de suppression
    [bool] EnqueueDelete([string]$documentId) {
        # Vérifier si le document est déjà en cours de traitement
        if ($this.ProcessingIds.ContainsKey($documentId)) {
            return $false
        }
        
        # Marquer le document comme en cours de traitement
        $this.ProcessingIds[$documentId] = $true
        
        # Ajouter le document à la file d'attente
        $this.DeleteQueue.Enqueue($documentId)
        
        return $true
    }
    
    # Méthode pour récupérer un document de la file d'attente d'ajout
    [bool] TryDequeueAdd([ref]$document) {
        $result = $this.AddQueue.TryDequeue([ref]$document)
        
        if ($result -and $null -ne $document.Value) {
            # Supprimer le document de l'ensemble des IDs en cours de traitement
            $this.ProcessingIds.TryRemove($document.Value.Id, [ref]$null)
        }
        
        return $result
    }
    
    # Méthode pour récupérer un document de la file d'attente de mise à jour
    [bool] TryDequeueUpdate([ref]$document) {
        $result = $this.UpdateQueue.TryDequeue([ref]$document)
        
        if ($result -and $null -ne $document.Value) {
            # Supprimer le document de l'ensemble des IDs en cours de traitement
            $this.ProcessingIds.TryRemove($document.Value.Id, [ref]$null)
        }
        
        return $result
    }
    
    # Méthode pour récupérer un document de la file d'attente de suppression
    [bool] TryDequeueDelete([ref]$documentId) {
        $result = $this.DeleteQueue.TryDequeue([ref]$documentId)
        
        if ($result -and $null -ne $documentId.Value) {
            # Supprimer le document de l'ensemble des IDs en cours de traitement
            $this.ProcessingIds.TryRemove($documentId.Value, [ref]$null)
        }
        
        return $result
    }
    
    # Méthode pour obtenir le nombre total de documents dans les files d'attente
    [int] Count() {
        return $this.AddQueue.Count + $this.UpdateQueue.Count + $this.DeleteQueue.Count
    }
    
    # Méthode pour vider les files d'attente
    [void] Clear() {
        # Vider les files d'attente
        while ($this.AddQueue.Count -gt 0) {
            $document = $null
            $this.AddQueue.TryDequeue([ref]$document)
        }
        
        while ($this.UpdateQueue.Count -gt 0) {
            $document = $null
            $this.UpdateQueue.TryDequeue([ref]$document)
        }
        
        while ($this.DeleteQueue.Count -gt 0) {
            $documentId = $null
            $this.DeleteQueue.TryDequeue([ref]$documentId)
        }
        
        # Vider l'ensemble des IDs en cours de traitement
        $this.ProcessingIds.Clear()
    }
}

# Classe pour représenter un processeur de mise à jour optimisé
class OptimizedUpdateProcessor {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Gestionnaire de mise à jour de documents
    [DocumentUpdater]$DocumentUpdater
    
    # Gestionnaire de fusion des modifications
    [ModificationMerger]$ModificationMerger
    
    # File d'attente de mise à jour optimisée
    [OptimizedUpdateQueue]$Queue
    
    # Gestionnaire de tâches parallèles
    [ParallelTaskManager]$TaskManager
    
    # Taille maximale du lot
    [int]$BatchSize
    
    # Intervalle de traitement (en secondes)
    [int]$ProcessingInterval
    
    # Indicateur de traitement en cours
    [bool]$IsProcessing
    
    # Constructeur par défaut
    OptimizedUpdateProcessor() {
        $this.SegmentManager = $null
        $this.DocumentUpdater = $null
        $this.ModificationMerger = $null
        $this.Queue = [OptimizedUpdateQueue]::new()
        $this.TaskManager = [ParallelTaskManager]::new()
        $this.BatchSize = 100
        $this.ProcessingInterval = 60  # 1 minute
        $this.IsProcessing = $false
    }
    
    # Constructeur avec gestionnaires
    OptimizedUpdateProcessor([IndexSegmentManager]$segmentManager, [DocumentUpdater]$documentUpdater, [ModificationMerger]$modificationMerger) {
        $this.SegmentManager = $segmentManager
        $this.DocumentUpdater = $documentUpdater
        $this.ModificationMerger = $modificationMerger
        $this.Queue = [OptimizedUpdateQueue]::new()
        $this.TaskManager = [ParallelTaskManager]::new()
        $this.BatchSize = 100
        $this.ProcessingInterval = 60  # 1 minute
        $this.IsProcessing = $false
    }
    
    # Constructeur complet
    OptimizedUpdateProcessor([IndexSegmentManager]$segmentManager, [DocumentUpdater]$documentUpdater, [ModificationMerger]$modificationMerger, [int]$batchSize, [int]$processingInterval, [int]$maxThreads) {
        $this.SegmentManager = $segmentManager
        $this.DocumentUpdater = $documentUpdater
        $this.ModificationMerger = $modificationMerger
        $this.Queue = [OptimizedUpdateQueue]::new()
        $this.TaskManager = [ParallelTaskManager]::new($maxThreads)
        $this.BatchSize = $batchSize
        $this.ProcessingInterval = $processingInterval
        $this.IsProcessing = $false
    }
    
    # Méthode pour ajouter un document
    [bool] AddDocument([IndexDocument]$document) {
        # Vérifier si le document existe déjà
        $existingDocument = $this.SegmentManager.GetDocument($document.Id)
        
        if ($null -eq $existingDocument) {
            # Ajouter le document à la file d'attente d'ajout
            return $this.Queue.EnqueueAdd($document)
        } else {
            # Ajouter le document à la file d'attente de mise à jour
            return $this.Queue.EnqueueUpdate($document)
        }
    }
    
    # Méthode pour mettre à jour un document
    [bool] UpdateDocument([IndexDocument]$document) {
        # Ajouter le document à la file d'attente de mise à jour
        return $this.Queue.EnqueueUpdate($document)
    }
    
    # Méthode pour supprimer un document
    [bool] DeleteDocument([string]$documentId) {
        # Ajouter le document à la file d'attente de suppression
        return $this.Queue.EnqueueDelete($documentId)
    }
    
    # Méthode pour traiter la file d'attente
    [hashtable] ProcessQueue() {
        $result = @{
            processed = 0
            added = 0
            updated = 0
            deleted = 0
            errors = [System.Collections.Generic.List[string]]::new()
        }
        
        # Vérifier si un traitement est déjà en cours
        if ($this.IsProcessing) {
            $result.errors.Add("Un traitement est déjà en cours.")
            return $result
        }
        
        # Marquer le début du traitement
        $this.IsProcessing = $true
        
        try {
            # Traiter les documents à ajouter
            $this.ProcessAddQueue($result)
            
            # Traiter les documents à mettre à jour
            $this.ProcessUpdateQueue($result)
            
            # Traiter les documents à supprimer
            $this.ProcessDeleteQueue($result)
        } finally {
            # Marquer la fin du traitement
            $this.IsProcessing = $false
        }
        
        return $result
    }
    
    # Méthode pour traiter la file d'attente d'ajout
    [void] ProcessAddQueue([hashtable]$result) {
        # Déterminer le nombre de documents à traiter
        $count = [Math]::Min($this.Queue.AddQueue.Count, $this.BatchSize)
        
        # Créer une liste pour stocker les documents à traiter
        $documents = [System.Collections.Generic.List[IndexDocument]]::new()
        
        # Récupérer les documents de la file d'attente
        for ($i = 0; $i -lt $count; $i++) {
            $document = $null
            
            if (-not $this.Queue.TryDequeueAdd([ref]$document)) {
                break
            }
            
            if ($null -eq $document) {
                continue
            }
            
            $documents.Add($document)
        }
        
        # Traiter les documents en parallèle
        $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
        
        foreach ($document in $documents) {
            $task = $this.TaskManager.RunTask({
                param($document, $segmentManager, $modificationMerger)
                
                try {
                    # Ajouter le document à l'index
                    $segmentManager.AddDocument($document)
                    
                    # Enregistrer la modification
                    $modificationMerger.RecordModification("Add", $null, $document)
                    
                    return @{
                        success = $true
                        document_id = $document.Id
                    }
                } catch {
                    return @{
                        success = $false
                        document_id = $document.Id
                        error = $_.ToString()
                    }
                }
            }.GetNewClosure())
            
            $tasks.Add($task)
        }
        
        # Attendre que toutes les tâches soient terminées
        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
        
        # Traiter les résultats
        foreach ($task in $tasks) {
            $taskResult = $task.Result
            
            if ($taskResult.success) {
                $result.added++
            } else {
                $result.errors.Add("Erreur lors de l'ajout du document $($taskResult.document_id): $($taskResult.error)")
            }
            
            $result.processed++
        }
    }
    
    # Méthode pour traiter la file d'attente de mise à jour
    [void] ProcessUpdateQueue([hashtable]$result) {
        # Déterminer le nombre de documents à traiter
        $count = [Math]::Min($this.Queue.UpdateQueue.Count, $this.BatchSize)
        
        # Créer une liste pour stocker les documents à traiter
        $documents = [System.Collections.Generic.List[IndexDocument]]::new()
        
        # Récupérer les documents de la file d'attente
        for ($i = 0; $i -lt $count; $i++) {
            $document = $null
            
            if (-not $this.Queue.TryDequeueUpdate([ref]$document)) {
                break
            }
            
            if ($null -eq $document) {
                continue
            }
            
            $documents.Add($document)
        }
        
        # Traiter les documents en parallèle
        $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
        
        foreach ($document in $documents) {
            $task = $this.TaskManager.RunTask({
                param($document, $documentUpdater, $modificationMerger)
                
                try {
                    # Récupérer le document existant
                    $existingDocument = $documentUpdater.SegmentManager.GetDocument($document.Id)
                    
                    # Mettre à jour le document
                    $updatedDocument = $documentUpdater.UpdateDocument($document)
                    
                    # Enregistrer la modification
                    $modificationMerger.RecordModification("Update", $existingDocument, $updatedDocument)
                    
                    return @{
                        success = $true
                        document_id = $document.Id
                    }
                } catch {
                    return @{
                        success = $false
                        document_id = $document.Id
                        error = $_.ToString()
                    }
                }
            }.GetNewClosure())
            
            $tasks.Add($task)
        }
        
        # Attendre que toutes les tâches soient terminées
        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
        
        # Traiter les résultats
        foreach ($task in $tasks) {
            $taskResult = $task.Result
            
            if ($taskResult.success) {
                $result.updated++
            } else {
                $result.errors.Add("Erreur lors de la mise à jour du document $($taskResult.document_id): $($taskResult.error)")
            }
            
            $result.processed++
        }
    }
    
    # Méthode pour traiter la file d'attente de suppression
    [void] ProcessDeleteQueue([hashtable]$result) {
        # Déterminer le nombre de documents à traiter
        $count = [Math]::Min($this.Queue.DeleteQueue.Count, $this.BatchSize)
        
        # Créer une liste pour stocker les IDs de documents à traiter
        $documentIds = [System.Collections.Generic.List[string]]::new()
        
        # Récupérer les IDs de documents de la file d'attente
        for ($i = 0; $i -lt $count; $i++) {
            $documentId = $null
            
            if (-not $this.Queue.TryDequeueDelete([ref]$documentId)) {
                break
            }
            
            if ([string]::IsNullOrEmpty($documentId)) {
                continue
            }
            
            $documentIds.Add($documentId)
        }
        
        # Traiter les documents en parallèle
        $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
        
        foreach ($documentId in $documentIds) {
            $task = $this.TaskManager.RunTask({
                param($documentId, $segmentManager, $modificationMerger)
                
                try {
                    # Récupérer le document existant
                    $existingDocument = $segmentManager.GetDocument($documentId)
                    
                    # Supprimer le document de l'index
                    $segmentManager.RemoveDocument($documentId)
                    
                    # Enregistrer la modification
                    $modificationMerger.RecordModification("Delete", $existingDocument, $null)
                    
                    return @{
                        success = $true
                        document_id = $documentId
                    }
                } catch {
                    return @{
                        success = $false
                        document_id = $documentId
                        error = $_.ToString()
                    }
                }
            }.GetNewClosure())
            
            $tasks.Add($task)
        }
        
        # Attendre que toutes les tâches soient terminées
        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
        
        # Traiter les résultats
        foreach ($task in $tasks) {
            $taskResult = $task.Result
            
            if ($taskResult.success) {
                $result.deleted++
            } else {
                $result.errors.Add("Erreur lors de la suppression du document $($taskResult.document_id): $($taskResult.error)")
            }
            
            $result.processed++
        }
    }
    
    # Méthode pour démarrer le traitement périodique
    [void] StartPeriodicProcessing() {
        # Créer un timer
        $timer = New-Object System.Timers.Timer
        $timer.Interval = $this.ProcessingInterval * 1000  # Convertir en millisecondes
        $timer.AutoReset = $true
        
        # Configurer l'événement
        $action = {
            param($processor)
            
            if ($processor.Queue.Count() -gt 0) {
                $processor.ProcessQueue()
            }
        }
        
        $timer.Elapsed.Add({
            & $action $this
        }.GetNewClosure())
        
        # Démarrer le timer
        $timer.Start()
    }
    
    # Méthode pour obtenir les statistiques du processeur
    [hashtable] GetStats() {
        return @{
            add_queue_size = $this.Queue.AddQueue.Count
            update_queue_size = $this.Queue.UpdateQueue.Count
            delete_queue_size = $this.Queue.DeleteQueue.Count
            total_queue_size = $this.Queue.Count()
            is_processing = $this.IsProcessing
            batch_size = $this.BatchSize
            processing_interval = $this.ProcessingInterval
            max_threads = $this.TaskManager.ThreadPool.MaxThreads
            running_tasks = $this.TaskManager.GetRunningTaskCount()
        }
    }
}

# Fonction pour créer un processeur de mise à jour optimisé
function New-OptimizedUpdateProcessor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $true)]
        [DocumentUpdater]$DocumentUpdater,
        
        [Parameter(Mandatory = $true)]
        [ModificationMerger]$ModificationMerger,
        
        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$ProcessingInterval = 60,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = [Environment]::ProcessorCount
    )
    
    return [OptimizedUpdateProcessor]::new($SegmentManager, $DocumentUpdater, $ModificationMerger, $BatchSize, $ProcessingInterval, $MaxThreads)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-OptimizedUpdateProcessor
