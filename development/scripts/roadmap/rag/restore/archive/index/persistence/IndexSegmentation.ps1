# IndexSegmentation.ps1
# Script implémentant le mécanisme de segmentation d'index
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$fileManagerPath = Join-Path -Path $scriptPath -ChildPath "IndexFileManager.ps1"

if (Test-Path -Path $fileManagerPath) {
    . $fileManagerPath
} else {
    Write-Error "Le fichier IndexFileManager.ps1 est introuvable."
    exit 1
}

# Classe pour gérer la segmentation des index
class IndexSegmentManager {
    # Gestionnaire de fichiers d'index
    [IndexFileManager]$FileManager
    
    # Taille maximale d'un segment (nombre de documents)
    [int]$MaxSegmentSize
    
    # Nombre maximal de segments avant fusion
    [int]$MaxSegmentCount
    
    # Seuil de documents supprimés pour déclencher une compaction
    [double]$CompactionThreshold
    
    # Segments actifs
    [System.Collections.Generic.Dictionary[string, IndexSegment]]$ActiveSegments
    
    # Constructeur par défaut
    IndexSegmentManager() {
        $this.FileManager = [IndexFileManager]::new()
        $this.MaxSegmentSize = 1000
        $this.MaxSegmentCount = 10
        $this.CompactionThreshold = 0.2  # 20% de documents supprimés
        $this.ActiveSegments = [System.Collections.Generic.Dictionary[string, IndexSegment]]::new()
    }
    
    # Constructeur avec gestionnaire de fichiers
    IndexSegmentManager([IndexFileManager]$fileManager) {
        $this.FileManager = $fileManager
        $this.MaxSegmentSize = 1000
        $this.MaxSegmentCount = 10
        $this.CompactionThreshold = 0.2  # 20% de documents supprimés
        $this.ActiveSegments = [System.Collections.Generic.Dictionary[string, IndexSegment]]::new()
    }
    
    # Constructeur complet
    IndexSegmentManager([IndexFileManager]$fileManager, [int]$maxSegmentSize, [int]$maxSegmentCount, [double]$compactionThreshold) {
        $this.FileManager = $fileManager
        $this.MaxSegmentSize = $maxSegmentSize
        $this.MaxSegmentCount = $maxSegmentCount
        $this.CompactionThreshold = $compactionThreshold
        $this.ActiveSegments = [System.Collections.Generic.Dictionary[string, IndexSegment]]::new()
    }
    
    # Méthode pour initialiser le gestionnaire de segments
    [void] Initialize() {
        # Charger les segments existants
        $segmentIds = $this.FileManager.GetSegmentIds()
        
        foreach ($segmentId in $segmentIds) {
            $segment = $this.FileManager.LoadSegment($segmentId)
            
            if ($null -ne $segment) {
                $this.ActiveSegments[$segmentId] = $segment
            }
        }
        
        # Vérifier si une compaction est nécessaire
        $this.CheckAndCompactSegments()
    }
    
    # Méthode pour ajouter un document à l'index
    [bool] AddDocument([IndexDocument]$document) {
        # Vérifier si le document existe déjà dans un segment
        $existingSegment = $null
        
        foreach ($segment in $this.ActiveSegments.Values) {
            if ($segment.Documents.ContainsKey($document.Id)) {
                $existingSegment = $segment
                break
            }
        }
        
        if ($null -ne $existingSegment) {
            # Mettre à jour le document dans le segment existant
            $existingSegment.Documents[$document.Id] = $document
            
            # Réindexer le document
            $existingSegment.RemoveDocument($document.Id)
            $existingSegment.IndexDocument($document)
            
            # Sauvegarder le segment
            return $this.FileManager.SaveSegment($existingSegment)
        } else {
            # Trouver un segment non plein
            $targetSegment = $null
            
            foreach ($segment in $this.ActiveSegments.Values) {
                if ($segment.Documents.Count -lt $this.MaxSegmentSize) {
                    $targetSegment = $segment
                    break
                }
            }
            
            if ($null -eq $targetSegment) {
                # Créer un nouveau segment
                $targetSegment = [IndexSegment]::new("segment_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$([Guid]::NewGuid().ToString('N').Substring(0, 8))")
                $this.ActiveSegments[$targetSegment.Id] = $targetSegment
                
                # Vérifier si le nombre de segments dépasse la limite
                if ($this.ActiveSegments.Count -gt $this.MaxSegmentCount) {
                    # Fusionner les segments
                    $this.MergeSegments()
                }
            }
            
            # Ajouter le document au segment
            $targetSegment.AddDocument($document)
            
            # Sauvegarder le segment
            return $this.FileManager.SaveSegment($targetSegment)
        }
    }
    
    # Méthode pour supprimer un document de l'index
    [bool] RemoveDocument([string]$documentId) {
        # Trouver le segment contenant le document
        $targetSegment = $null
        
        foreach ($segment in $this.ActiveSegments.Values) {
            if ($segment.Documents.ContainsKey($documentId)) {
                $targetSegment = $segment
                break
            }
        }
        
        if ($null -eq $targetSegment) {
            # Le document n'existe pas dans l'index
            return $true
        }
        
        # Supprimer le document du segment
        $targetSegment.RemoveDocument($documentId)
        
        # Sauvegarder le segment
        $result = $this.FileManager.SaveSegment($targetSegment)
        
        # Vérifier si une compaction est nécessaire
        $this.CheckAndCompactSegments()
        
        return $result
    }
    
    # Méthode pour rechercher des documents dans l'index
    [string[]] SearchDocuments([string]$query) {
        # Ensemble des résultats
        $results = [System.Collections.Generic.HashSet[string]]::new()
        
        # Rechercher dans tous les segments
        foreach ($segment in $this.ActiveSegments.Values) {
            $segmentResults = $segment.Search($query)
            
            foreach ($docId in $segmentResults) {
                $results.Add($docId)
            }
        }
        
        return $results.ToArray()
    }
    
    # Méthode pour filtrer des documents dans l'index
    [string[]] FilterDocuments([hashtable]$filters) {
        # Ensemble des résultats
        $results = [System.Collections.Generic.HashSet[string]]::new()
        $isFirstSegment = $true
        
        # Filtrer dans tous les segments
        foreach ($segment in $this.ActiveSegments.Values) {
            $segmentResults = $segment.Filter($filters)
            
            if ($isFirstSegment) {
                # Pour le premier segment, initialiser l'ensemble des résultats
                foreach ($docId in $segmentResults) {
                    $results.Add($docId)
                }
                
                $isFirstSegment = $false
            } else {
                # Pour les segments suivants, faire l'union des résultats
                foreach ($docId in $segmentResults) {
                    $results.Add($docId)
                }
            }
        }
        
        return $results.ToArray()
    }
    
    # Méthode pour obtenir un document par son ID
    [IndexDocument] GetDocument([string]$documentId) {
        # Rechercher le document dans les segments
        foreach ($segment in $this.ActiveSegments.Values) {
            if ($segment.Documents.ContainsKey($documentId)) {
                return $segment.Documents[$documentId]
            }
        }
        
        # Si le document n'est pas trouvé dans les segments, essayer de le charger depuis le stockage
        return $this.FileManager.LoadDocument($documentId)
    }
    
    # Méthode pour vérifier et compacter les segments si nécessaire
    [void] CheckAndCompactSegments() {
        # Vérifier si des segments ont besoin d'être compactés
        $segmentsToCompact = [System.Collections.Generic.List[IndexSegment]]::new()
        
        foreach ($segment in $this.ActiveSegments.Values) {
            # Calculer le ratio de documents supprimés
            $totalTerms = 0
            $totalDocIds = [System.Collections.Generic.HashSet[string]]::new()
            
            foreach ($term in $segment.InvertedIndex.Keys) {
                $docIds = $segment.InvertedIndex[$term]
                $totalTerms += $docIds.Count
                
                foreach ($docId in $docIds) {
                    $totalDocIds.Add($docId)
                }
            }
            
            $documentCount = $segment.Documents.Count
            $indexedDocumentCount = $totalDocIds.Count
            
            if ($documentCount -gt 0 -and $indexedDocumentCount -lt $documentCount * (1 - $this.CompactionThreshold)) {
                $segmentsToCompact.Add($segment)
            }
        }
        
        # Compacter les segments
        foreach ($segment in $segmentsToCompact) {
            $this.CompactSegment($segment)
        }
        
        # Vérifier si le nombre de segments dépasse la limite
        if ($this.ActiveSegments.Count -gt $this.MaxSegmentCount) {
            $this.MergeSegments()
        }
    }
    
    # Méthode pour compacter un segment
    [void] CompactSegment([IndexSegment]$segment) {
        # Créer un nouveau segment
        $newSegment = [IndexSegment]::new("$($segment.Name)_compacted")
        
        # Copier les documents valides
        foreach ($docId in $segment.Documents.Keys) {
            $document = $segment.Documents[$docId]
            $newSegment.AddDocument($document)
        }
        
        # Remplacer l'ancien segment par le nouveau
        $this.ActiveSegments.Remove($segment.Id)
        $this.ActiveSegments[$newSegment.Id] = $newSegment
        
        # Sauvegarder le nouveau segment
        $this.FileManager.SaveSegment($newSegment)
        
        # Supprimer l'ancien segment
        $this.FileManager.DeleteSegment($segment.Id)
    }
    
    # Méthode pour fusionner des segments
    [void] MergeSegments() {
        # Trier les segments par taille (nombre de documents)
        $sortedSegments = $this.ActiveSegments.Values | Sort-Object -Property { $_.Documents.Count }
        
        # Sélectionner les segments les plus petits à fusionner
        $segmentsToMerge = $sortedSegments | Select-Object -First 2
        
        if ($segmentsToMerge.Count -lt 2) {
            # Pas assez de segments à fusionner
            return
        }
        
        # Créer un nouveau segment
        $newSegment = [IndexSegment]::new("merged_$(Get-Date -Format 'yyyyMMdd_HHmmss')")
        
        # Fusionner les documents
        foreach ($segment in $segmentsToMerge) {
            foreach ($docId in $segment.Documents.Keys) {
                $document = $segment.Documents[$docId]
                $newSegment.AddDocument($document)
            }
        }
        
        # Ajouter le nouveau segment
        $this.ActiveSegments[$newSegment.Id] = $newSegment
        
        # Sauvegarder le nouveau segment
        $this.FileManager.SaveSegment($newSegment)
        
        # Supprimer les segments fusionnés
        foreach ($segment in $segmentsToMerge) {
            $this.ActiveSegments.Remove($segment.Id)
            $this.FileManager.DeleteSegment($segment.Id)
        }
    }
    
    # Méthode pour obtenir des statistiques sur les segments
    [hashtable] GetSegmentStats() {
        $stats = @{
            segment_count = $this.ActiveSegments.Count
            total_documents = 0
            total_terms = 0
            segments = @{}
        }
        
        foreach ($segmentId in $this.ActiveSegments.Keys) {
            $segment = $this.ActiveSegments[$segmentId]
            $documentCount = $segment.Documents.Count
            $termCount = $segment.InvertedIndex.Count
            
            $stats.total_documents += $documentCount
            $stats.total_terms += $termCount
            
            $stats.segments[$segmentId] = @{
                name = $segment.Name
                document_count = $documentCount
                term_count = $termCount
                created_at = $segment.Metadata.created_at
                updated_at = $segment.Metadata.updated_at
            }
        }
        
        return $stats
    }
}

# Fonction pour créer un gestionnaire de segments d'index
function New-IndexSegmentManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [IndexFileManager]$FileManager = (New-IndexFileManager),
        
        [Parameter(Mandatory = $false)]
        [int]$MaxSegmentSize = 1000,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxSegmentCount = 10,
        
        [Parameter(Mandatory = $false)]
        [double]$CompactionThreshold = 0.2
    )
    
    $manager = [IndexSegmentManager]::new($FileManager, $MaxSegmentSize, $MaxSegmentCount, $CompactionThreshold)
    $manager.Initialize()
    
    return $manager
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-IndexSegmentManager
