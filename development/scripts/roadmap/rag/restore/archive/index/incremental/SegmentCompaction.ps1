# SegmentCompaction.ps1
# Script implémentant la compaction des segments pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$deferredCleanupPath = Join-Path -Path $scriptPath -ChildPath "DeferredCleanup.ps1"

if (Test-Path -Path $deferredCleanupPath) {
    . $deferredCleanupPath
} else {
    Write-Error "Le fichier DeferredCleanup.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une politique de compaction
class CompactionPolicy {
    # Seuil de documents supprimés pour déclencher une compaction (pourcentage)
    [double]$DeletedDocumentsThreshold
    
    # Seuil de taille de segment pour déclencher une compaction (nombre de documents)
    [int]$SegmentSizeThreshold
    
    # Seuil de fragmentation pour déclencher une compaction (pourcentage)
    [double]$FragmentationThreshold
    
    # Constructeur par défaut
    CompactionPolicy() {
        $this.DeletedDocumentsThreshold = 0.2  # 20%
        $this.SegmentSizeThreshold = 1000      # 1000 documents
        $this.FragmentationThreshold = 0.3     # 30%
    }
    
    # Constructeur avec seuils
    CompactionPolicy([double]$deletedDocumentsThreshold, [int]$segmentSizeThreshold, [double]$fragmentationThreshold) {
        $this.DeletedDocumentsThreshold = $deletedDocumentsThreshold
        $this.SegmentSizeThreshold = $segmentSizeThreshold
        $this.FragmentationThreshold = $fragmentationThreshold
    }
    
    # Méthode pour vérifier si un segment doit être compacté
    [bool] ShouldCompactSegment([IndexSegment]$segment, [DeletionRegistry]$deletionRegistry) {
        # Calculer le nombre de documents supprimés
        $deletedDocuments = 0
        
        foreach ($documentId in $segment.Documents.Keys) {
            if ($deletionRegistry.IsDocumentMarkedAsDeleted($documentId)) {
                $deletedDocuments++
            }
        }
        
        # Calculer le pourcentage de documents supprimés
        $deletedPercentage = if ($segment.Documents.Count -gt 0) {
            $deletedDocuments / $segment.Documents.Count
        } else {
            0
        }
        
        # Vérifier si le segment dépasse le seuil de documents supprimés
        if ($deletedPercentage -ge $this.DeletedDocumentsThreshold) {
            return $true
        }
        
        # Vérifier si le segment dépasse le seuil de taille
        if ($segment.Documents.Count -ge $this.SegmentSizeThreshold) {
            return $true
        }
        
        # Calculer la fragmentation
        $fragmentation = $this.CalculateFragmentation($segment)
        
        # Vérifier si le segment dépasse le seuil de fragmentation
        if ($fragmentation -ge $this.FragmentationThreshold) {
            return $true
        }
        
        return $false
    }
    
    # Méthode pour calculer la fragmentation d'un segment
    [double] CalculateFragmentation([IndexSegment]$segment) {
        # Calculer le nombre de termes
        $termCount = $segment.InvertedIndex.Count
        
        # Calculer le nombre de documents
        $documentCount = $segment.Documents.Count
        
        # Calculer le nombre moyen de termes par document
        $avgTermsPerDocument = if ($documentCount -gt 0) {
            $termCount / $documentCount
        } else {
            0
        }
        
        # Calculer la fragmentation
        $fragmentation = 1 - (1 / $avgTermsPerDocument)
        
        return $fragmentation
    }
}

# Classe pour représenter un planificateur de compaction
class CompactionScheduler {
    # Intervalle de compaction (en secondes)
    [int]$CompactionInterval
    
    # Dernière compaction
    [DateTime]$LastCompaction
    
    # Constructeur par défaut
    CompactionScheduler() {
        $this.CompactionInterval = 86400  # 24 heures
        $this.LastCompaction = [DateTime]::MinValue
    }
    
    # Constructeur avec intervalle
    CompactionScheduler([int]$compactionInterval) {
        $this.CompactionInterval = $compactionInterval
        $this.LastCompaction = [DateTime]::MinValue
    }
    
    # Méthode pour vérifier si une compaction est nécessaire
    [bool] ShouldCompact() {
        $now = Get-Date
        $elapsed = ($now - $this.LastCompaction).TotalSeconds
        
        return $elapsed -ge $this.CompactionInterval -or $this.LastCompaction -eq [DateTime]::MinValue
    }
    
    # Méthode pour mettre à jour la date de la dernière compaction
    [void] UpdateLastCompaction() {
        $this.LastCompaction = Get-Date
    }
}

# Classe pour représenter un gestionnaire de compaction de segments
class SegmentCompactionManager {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Registre des suppressions
    [DeletionRegistry]$DeletionRegistry
    
    # Politique de compaction
    [CompactionPolicy]$Policy
    
    # Planificateur de compaction
    [CompactionScheduler]$Scheduler
    
    # Chemin du fichier de journal de compaction
    [string]$CompactionLogPath
    
    # Constructeur par défaut
    SegmentCompactionManager() {
        $this.SegmentManager = $null
        $this.DeletionRegistry = $null
        $this.Policy = [CompactionPolicy]::new()
        $this.Scheduler = [CompactionScheduler]::new()
        $this.CompactionLogPath = Join-Path -Path $env:TEMP -ChildPath "compaction_log.json"
    }
    
    # Constructeur avec gestionnaires
    SegmentCompactionManager([IndexSegmentManager]$segmentManager, [DeletionRegistry]$deletionRegistry) {
        $this.SegmentManager = $segmentManager
        $this.DeletionRegistry = $deletionRegistry
        $this.Policy = [CompactionPolicy]::new()
        $this.Scheduler = [CompactionScheduler]::new()
        $this.CompactionLogPath = Join-Path -Path $env:TEMP -ChildPath "compaction_log.json"
    }
    
    # Constructeur complet
    SegmentCompactionManager([IndexSegmentManager]$segmentManager, [DeletionRegistry]$deletionRegistry, [CompactionPolicy]$policy, [CompactionScheduler]$scheduler, [string]$compactionLogPath) {
        $this.SegmentManager = $segmentManager
        $this.DeletionRegistry = $deletionRegistry
        $this.Policy = $policy
        $this.Scheduler = $scheduler
        $this.CompactionLogPath = $compactionLogPath
    }
    
    # Méthode pour exécuter la compaction
    [hashtable] RunCompaction() {
        $result = @{
            compacted_segments = 0
            removed_documents = 0
            errors = [System.Collections.Generic.List[string]]::new()
            timestamp = Get-Date
        }
        
        # Vérifier si une compaction est nécessaire
        if (-not $this.Scheduler.ShouldCompact()) {
            return $result
        }
        
        # Récupérer les segments
        $segments = $this.SegmentManager.ActiveSegments.Values
        
        # Identifier les segments à compacter
        $segmentsToCompact = [System.Collections.Generic.List[IndexSegment]]::new()
        
        foreach ($segment in $segments) {
            if ($this.Policy.ShouldCompactSegment($segment, $this.DeletionRegistry)) {
                $segmentsToCompact.Add($segment)
            }
        }
        
        # Compacter les segments
        foreach ($segment in $segmentsToCompact) {
            try {
                # Créer un nouveau segment
                $newSegment = [IndexSegment]::new("$($segment.Id)_compacted")
                
                # Copier les documents non supprimés
                foreach ($documentId in $segment.Documents.Keys) {
                    if (-not $this.DeletionRegistry.IsDocumentMarkedAsDeleted($documentId)) {
                        $document = $segment.Documents[$documentId]
                        $newSegment.AddDocument($document)
                    } else {
                        $result.removed_documents++
                    }
                }
                
                # Remplacer l'ancien segment par le nouveau
                $this.SegmentManager.ActiveSegments.Remove($segment.Id)
                $this.SegmentManager.ActiveSegments[$newSegment.Id] = $newSegment
                
                # Sauvegarder le nouveau segment
                $this.SegmentManager.FileManager.SaveSegment($newSegment)
                
                # Supprimer l'ancien segment
                $this.SegmentManager.FileManager.DeleteSegment($segment.Id)
                
                $result.compacted_segments++
            } catch {
                $result.errors.Add("Erreur lors de la compaction du segment $($segment.Id): $_")
            }
        }
        
        # Mettre à jour la date de la dernière compaction
        $this.Scheduler.UpdateLastCompaction()
        
        # Enregistrer le résultat de la compaction
        $this.LogCompactionResult($result)
        
        return $result
    }
    
    # Méthode pour enregistrer le résultat de la compaction
    [void] LogCompactionResult([hashtable]$result) {
        try {
            # Charger les résultats précédents
            $logs = @()
            
            if (Test-Path -Path $this.CompactionLogPath) {
                $logs = Get-Content -Path $this.CompactionLogPath -Raw | ConvertFrom-Json
            }
            
            # Ajouter le nouveau résultat
            $logs += $result
            
            # Limiter le nombre de résultats
            if ($logs.Count -gt 100) {
                $logs = $logs | Select-Object -Last 100
            }
            
            # Sauvegarder les résultats
            $logs | ConvertTo-Json -Depth 10 | Out-File -FilePath $this.CompactionLogPath -Encoding UTF8
        } catch {
            Write-Error "Erreur lors de l'enregistrement du résultat de la compaction: $_"
        }
    }
    
    # Méthode pour démarrer la compaction périodique
    [void] StartPeriodicCompaction() {
        # Créer un timer
        $timer = New-Object System.Timers.Timer
        $timer.Interval = 3600 * 1000  # 1 heure
        $timer.AutoReset = $true
        
        # Configurer l'événement
        $action = {
            param($manager)
            
            if ($manager.Scheduler.ShouldCompact()) {
                $manager.RunCompaction()
            }
        }
        
        $timer.Elapsed.Add({
            & $action $this
        }.GetNewClosure())
        
        # Démarrer le timer
        $timer.Start()
    }
    
    # Méthode pour compacter un segment spécifique
    [bool] CompactSegment([string]$segmentId) {
        # Vérifier si le segment existe
        if (-not $this.SegmentManager.ActiveSegments.ContainsKey($segmentId)) {
            Write-Error "Le segment $segmentId n'existe pas."
            return $false
        }
        
        # Récupérer le segment
        $segment = $this.SegmentManager.ActiveSegments[$segmentId]
        
        try {
            # Créer un nouveau segment
            $newSegment = [IndexSegment]::new("$($segment.Id)_compacted")
            
            # Copier les documents non supprimés
            foreach ($documentId in $segment.Documents.Keys) {
                if (-not $this.DeletionRegistry.IsDocumentMarkedAsDeleted($documentId)) {
                    $document = $segment.Documents[$documentId]
                    $newSegment.AddDocument($document)
                }
            }
            
            # Remplacer l'ancien segment par le nouveau
            $this.SegmentManager.ActiveSegments.Remove($segment.Id)
            $this.SegmentManager.ActiveSegments[$newSegment.Id] = $newSegment
            
            # Sauvegarder le nouveau segment
            $this.SegmentManager.FileManager.SaveSegment($newSegment)
            
            # Supprimer l'ancien segment
            $this.SegmentManager.FileManager.DeleteSegment($segment.Id)
            
            return $true
        } catch {
            Write-Error "Erreur lors de la compaction du segment $segmentId: $_"
            return $false
        }
    }
    
    # Méthode pour obtenir les statistiques de compaction
    [hashtable] GetCompactionStats() {
        $stats = @{
            last_compaction = $this.Scheduler.LastCompaction
            next_compaction = $this.Scheduler.LastCompaction.AddSeconds($this.Scheduler.CompactionInterval)
            deleted_documents_threshold = $this.Policy.DeletedDocumentsThreshold
            segment_size_threshold = $this.Policy.SegmentSizeThreshold
            fragmentation_threshold = $this.Policy.FragmentationThreshold
            compaction_interval_seconds = $this.Scheduler.CompactionInterval
            compaction_log_path = $this.CompactionLogPath
        }
        
        # Ajouter les statistiques des segments
        $segments = $this.SegmentManager.ActiveSegments.Values
        $stats.total_segments = $segments.Count
        
        # Calculer les segments à compacter
        $segmentsToCompact = 0
        
        foreach ($segment in $segments) {
            if ($this.Policy.ShouldCompactSegment($segment, $this.DeletionRegistry)) {
                $segmentsToCompact++
            }
        }
        
        $stats.segments_to_compact = $segmentsToCompact
        
        return $stats
    }
}

# Fonction pour créer une politique de compaction
function New-CompactionPolicy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [double]$DeletedDocumentsThreshold = 0.2,
        
        [Parameter(Mandatory = $false)]
        [int]$SegmentSizeThreshold = 1000,
        
        [Parameter(Mandatory = $false)]
        [double]$FragmentationThreshold = 0.3
    )
    
    return [CompactionPolicy]::new($DeletedDocumentsThreshold, $SegmentSizeThreshold, $FragmentationThreshold)
}

# Fonction pour créer un planificateur de compaction
function New-CompactionScheduler {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$CompactionInterval = 86400  # 24 heures
    )
    
    return [CompactionScheduler]::new($CompactionInterval)
}

# Fonction pour créer un gestionnaire de compaction de segments
function New-SegmentCompactionManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $true)]
        [DeletionRegistry]$DeletionRegistry,
        
        [Parameter(Mandatory = $false)]
        [CompactionPolicy]$Policy = (New-CompactionPolicy),
        
        [Parameter(Mandatory = $false)]
        [CompactionScheduler]$Scheduler = (New-CompactionScheduler),
        
        [Parameter(Mandatory = $false)]
        [string]$CompactionLogPath = (Join-Path -Path $env:TEMP -ChildPath "compaction_log.json")
    )
    
    return [SegmentCompactionManager]::new($SegmentManager, $DeletionRegistry, $Policy, $Scheduler, $CompactionLogPath)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-CompactionPolicy, New-CompactionScheduler, New-SegmentCompactionManager
