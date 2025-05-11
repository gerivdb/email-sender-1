# IncrementalAddition.ps1
# Script implémentant l'ajout incrémental de documents pour l'indexation
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modifiedFileDetectionPath = Join-Path -Path $scriptPath -ChildPath "ModifiedFileDetection.ps1"

if (Test-Path -Path $modifiedFileDetectionPath) {
    . $modifiedFileDetectionPath
} else {
    Write-Error "Le fichier ModifiedFileDetection.ps1 est introuvable."
    exit 1
}

# Importer les modules de l'index
$parentPath = Split-Path -Parent $scriptPath
$persistencePath = Join-Path -Path $parentPath -ChildPath "persistence"
$segmentationPath = Join-Path -Path $persistencePath -ChildPath "IndexSegmentation.ps1"

if (Test-Path -Path $segmentationPath) {
    . $segmentationPath
} else {
    Write-Error "Le fichier IndexSegmentation.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une file d'attente d'indexation
class IndexingQueue {
    # Liste des documents à indexer
    [System.Collections.Concurrent.ConcurrentQueue[IndexDocument]]$Queue
    
    # Constructeur par défaut
    IndexingQueue() {
        $this.Queue = [System.Collections.Concurrent.ConcurrentQueue[IndexDocument]]::new()
    }
    
    # Méthode pour ajouter un document à la file d'attente
    [void] Enqueue([IndexDocument]$document) {
        $this.Queue.Enqueue($document)
    }
    
    # Méthode pour récupérer un document de la file d'attente
    [bool] TryDequeue([ref]$document) {
        return $this.Queue.TryDequeue([ref]$document)
    }
    
    # Méthode pour vider la file d'attente
    [void] Clear() {
        while ($this.Queue.Count -gt 0) {
            $document = $null
            $this.Queue.TryDequeue([ref]$document)
        }
    }
    
    # Méthode pour obtenir le nombre de documents dans la file d'attente
    [int] Count() {
        return $this.Queue.Count
    }
}

# Classe pour représenter un processeur d'indexation incrémentale
class IncrementalProcessor {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Gestionnaire de suivi des modifications
    [ChangeTrackingManager]$ChangeTracker
    
    # Gestionnaire de signatures
    [SignatureManager]$SignatureManager
    
    # File d'attente d'indexation
    [IndexingQueue]$Queue
    
    # Taille maximale du lot
    [int]$BatchSize
    
    # Intervalle de traitement (en secondes)
    [int]$ProcessingInterval
    
    # Indicateur de traitement en cours
    [bool]$IsProcessing
    
    # Constructeur par défaut
    IncrementalProcessor() {
        $this.SegmentManager = $null
        $this.ChangeTracker = $null
        $this.SignatureManager = $null
        $this.Queue = [IndexingQueue]::new()
        $this.BatchSize = 100
        $this.ProcessingInterval = 60  # 1 minute
        $this.IsProcessing = $false
    }
    
    # Constructeur avec gestionnaires
    IncrementalProcessor([IndexSegmentManager]$segmentManager, [ChangeTrackingManager]$changeTracker, [SignatureManager]$signatureManager) {
        $this.SegmentManager = $segmentManager
        $this.ChangeTracker = $changeTracker
        $this.SignatureManager = $signatureManager
        $this.Queue = [IndexingQueue]::new()
        $this.BatchSize = 100
        $this.ProcessingInterval = 60  # 1 minute
        $this.IsProcessing = $false
    }
    
    # Constructeur complet
    IncrementalProcessor([IndexSegmentManager]$segmentManager, [ChangeTrackingManager]$changeTracker, [SignatureManager]$signatureManager, [int]$batchSize, [int]$processingInterval) {
        $this.SegmentManager = $segmentManager
        $this.ChangeTracker = $changeTracker
        $this.SignatureManager = $signatureManager
        $this.Queue = [IndexingQueue]::new()
        $this.BatchSize = $batchSize
        $this.ProcessingInterval = $processingInterval
        $this.IsProcessing = $false
    }
    
    # Méthode pour ajouter un document à la file d'attente
    [void] EnqueueDocument([IndexDocument]$document) {
        $this.Queue.Enqueue($document)
    }
    
    # Méthode pour traiter la file d'attente
    [hashtable] ProcessQueue() {
        $result = @{
            processed_documents = 0
            added_documents = 0
            updated_documents = 0
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
            # Déterminer le nombre de documents à traiter
            $count = [Math]::Min($this.Queue.Count(), $this.BatchSize)
            
            # Traiter les documents
            for ($i = 0; $i -lt $count; $i++) {
                $document = $null
                
                if (-not $this.Queue.TryDequeue([ref]$document)) {
                    break
                }
                
                if ($null -eq $document) {
                    continue
                }
                
                $result.processed_documents++
                
                try {
                    # Vérifier si le document a changé
                    $changeResult = $this.SignatureManager.CheckDocumentChanged($document)
                    
                    if ($changeResult.is_new) {
                        # Ajouter le document à l'index
                        $this.SegmentManager.AddDocument($document)
                        $result.added_documents++
                    } elseif ($changeResult.has_changed) {
                        # Mettre à jour le document dans l'index
                        $this.SegmentManager.AddDocument($document)
                        $result.updated_documents++
                    }
                } catch {
                    $result.errors.Add("Erreur lors du traitement du document $($document.Id): $_")
                }
            }
        } finally {
            # Marquer la fin du traitement
            $this.IsProcessing = $false
        }
        
        return $result
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
}

# Classe pour représenter un indexeur incrémental
class IncrementalIndexer {
    # Processeur d'indexation incrémentale
    [IncrementalProcessor]$Processor
    
    # Détecteur de fichiers
    [FileDetector]$FileDetector
    
    # Observateur de fichiers
    [FileWatcher]$FileWatcher
    
    # Extracteur de documents
    [scriptblock]$DocumentExtractor
    
    # Constructeur par défaut
    IncrementalIndexer() {
        $this.Processor = $null
        $this.FileDetector = $null
        $this.FileWatcher = $null
        $this.DocumentExtractor = { param($filePath) return $null }
    }
    
    # Constructeur avec processeur
    IncrementalIndexer([IncrementalProcessor]$processor) {
        $this.Processor = $processor
        $this.FileDetector = $null
        $this.FileWatcher = $null
        $this.DocumentExtractor = { param($filePath) return $null }
    }
    
    # Constructeur complet
    IncrementalIndexer([IncrementalProcessor]$processor, [FileDetector]$fileDetector, [scriptblock]$documentExtractor) {
        $this.Processor = $processor
        $this.FileDetector = $fileDetector
        $this.FileWatcher = $null
        $this.DocumentExtractor = $documentExtractor
    }
    
    # Méthode pour démarrer l'indexation incrémentale
    [void] Start() {
        # Vérifier si le processeur est défini
        if ($null -eq $this.Processor) {
            Write-Error "Le processeur d'indexation incrémentale n'est pas défini."
            return
        }
        
        # Vérifier si le détecteur de fichiers est défini
        if ($null -eq $this.FileDetector) {
            Write-Error "Le détecteur de fichiers n'est pas défini."
            return
        }
        
        # Vérifier si l'extracteur de documents est défini
        if ($null -eq $this.DocumentExtractor) {
            Write-Error "L'extracteur de documents n'est pas défini."
            return
        }
        
        # Effectuer un scan initial
        $scanResult = $this.FileDetector.ScanFiles()
        
        # Traiter les nouveaux fichiers et les fichiers modifiés
        $filesToProcess = $scanResult.new_files + $scanResult.modified_files
        
        foreach ($filePath in $filesToProcess) {
            try {
                # Extraire le document
                $document = & $this.DocumentExtractor $filePath
                
                if ($null -ne $document) {
                    # Ajouter le document à la file d'attente
                    $this.Processor.EnqueueDocument($document)
                }
            } catch {
                Write-Error "Erreur lors de l'extraction du document à partir du fichier $filePath: $_"
            }
        }
        
        # Traiter la file d'attente
        $this.Processor.ProcessQueue()
        
        # Créer et démarrer l'observateur de fichiers
        $this.FileWatcher = [FileWatcher]::new($this.FileDetector)
        $this.FileWatcher.Start()
        
        # Démarrer le traitement périodique
        $this.Processor.StartPeriodicProcessing()
    }
    
    # Méthode pour arrêter l'indexation incrémentale
    [void] Stop() {
        # Arrêter l'observateur de fichiers
        if ($null -ne $this.FileWatcher) {
            $this.FileWatcher.Stop()
            $this.FileWatcher = $null
        }
    }
    
    # Méthode pour indexer un fichier spécifique
    [bool] IndexFile([string]$filePath) {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $filePath -PathType Leaf)) {
            Write-Error "Le fichier $filePath n'existe pas."
            return $false
        }
        
        try {
            # Extraire le document
            $document = & $this.DocumentExtractor $filePath
            
            if ($null -eq $document) {
                Write-Error "Impossible d'extraire un document à partir du fichier $filePath."
                return $false
            }
            
            # Ajouter le document à la file d'attente
            $this.Processor.EnqueueDocument($document)
            
            # Traiter la file d'attente
            $this.Processor.ProcessQueue()
            
            return $true
        } catch {
            Write-Error "Erreur lors de l'indexation du fichier $filePath: $_"
            return $false
        }
    }
    
    # Méthode pour obtenir les statistiques de l'indexeur
    [hashtable] GetStats() {
        return @{
            queue_size = $this.Processor.Queue.Count()
            is_processing = $this.Processor.IsProcessing
            batch_size = $this.Processor.BatchSize
            processing_interval = $this.Processor.ProcessingInterval
        }
    }
}

# Fonction pour créer un processeur d'indexation incrémentale
function New-IncrementalProcessor {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $true)]
        [ChangeTrackingManager]$ChangeTracker,
        
        [Parameter(Mandatory = $true)]
        [SignatureManager]$SignatureManager,
        
        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$ProcessingInterval = 60
    )
    
    return [IncrementalProcessor]::new($SegmentManager, $ChangeTracker, $SignatureManager, $BatchSize, $ProcessingInterval)
}

# Fonction pour créer un indexeur incrémental
function New-IncrementalIndexer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IncrementalProcessor]$Processor,
        
        [Parameter(Mandatory = $true)]
        [FileDetector]$FileDetector,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$DocumentExtractor
    )
    
    return [IncrementalIndexer]::new($Processor, $FileDetector, $DocumentExtractor)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-IncrementalProcessor, New-IncrementalIndexer
