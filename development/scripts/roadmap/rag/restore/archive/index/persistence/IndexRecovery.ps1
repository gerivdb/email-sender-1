# IndexRecovery.ps1
# Script implémentant la récupération après crash pour les index
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$transactionsPath = Join-Path -Path $scriptPath -ChildPath "IndexTransactions.ps1"

if (Test-Path -Path $transactionsPath) {
    . $transactionsPath
} else {
    Write-Error "Le fichier IndexTransactions.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un point de contrôle
class IndexCheckpoint {
    # ID du point de contrôle
    [string]$Id
    
    # Horodatage de création
    [DateTime]$CreatedAt
    
    # Liste des IDs de segments
    [string[]]$SegmentIds
    
    # Liste des IDs de documents
    [string[]]$DocumentIds
    
    # Métadonnées de l'index
    [hashtable]$IndexMetadata
    
    # Constructeur par défaut
    IndexCheckpoint() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.CreatedAt = Get-Date
        $this.SegmentIds = @()
        $this.DocumentIds = @()
        $this.IndexMetadata = @{}
    }
    
    # Constructeur avec données
    IndexCheckpoint([string[]]$segmentIds, [string[]]$documentIds, [hashtable]$indexMetadata) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.CreatedAt = Get-Date
        $this.SegmentIds = $segmentIds
        $this.DocumentIds = $documentIds
        $this.IndexMetadata = $indexMetadata
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        $obj = @{
            id = $this.Id
            created_at = $this.CreatedAt.ToString("o")
            segment_ids = $this.SegmentIds
            document_ids = $this.DocumentIds
            index_metadata = $this.IndexMetadata
        }
        
        return ConvertTo-Json -InputObject $obj -Depth 10 -Compress
    }
    
    # Méthode pour créer à partir de JSON
    static [IndexCheckpoint] FromJson([string]$json) {
        $obj = ConvertFrom-Json -InputObject $json
        
        $checkpoint = [IndexCheckpoint]::new()
        $checkpoint.Id = $obj.id
        $checkpoint.CreatedAt = [DateTime]::Parse($obj.created_at)
        $checkpoint.SegmentIds = $obj.segment_ids
        $checkpoint.DocumentIds = $obj.document_ids
        
        $checkpoint.IndexMetadata = @{}
        foreach ($prop in $obj.index_metadata.PSObject.Properties) {
            $checkpoint.IndexMetadata[$prop.Name] = $prop.Value
        }
        
        return $checkpoint
    }
}

# Classe pour gérer la récupération des index
class IndexRecoveryManager {
    # Gestionnaire de transactions
    [IndexTransactionManager]$TransactionManager
    
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Gestionnaire de fichiers
    [IndexFileManager]$FileManager
    
    # Répertoire des points de contrôle
    [string]$CheckpointDirectory
    
    # Nombre maximal de points de contrôle à conserver
    [int]$MaxCheckpoints
    
    # Intervalle entre les points de contrôle (en minutes)
    [int]$CheckpointInterval
    
    # Dernier point de contrôle
    [DateTime]$LastCheckpoint
    
    # Constructeur par défaut
    IndexRecoveryManager() {
        $this.TransactionManager = $null
        $this.SegmentManager = $null
        $this.FileManager = $null
        $this.CheckpointDirectory = Join-Path -Path $env:TEMP -ChildPath "IndexCheckpoints"
        $this.MaxCheckpoints = 5
        $this.CheckpointInterval = 60  # 1 heure
        $this.LastCheckpoint = [DateTime]::MinValue
        
        # Créer le répertoire des points de contrôle s'il n'existe pas
        if (-not (Test-Path -Path $this.CheckpointDirectory)) {
            New-Item -Path $this.CheckpointDirectory -ItemType Directory -Force | Out-Null
        }
    }
    
    # Constructeur avec gestionnaires
    IndexRecoveryManager([IndexTransactionManager]$transactionManager, [IndexSegmentManager]$segmentManager, [IndexFileManager]$fileManager) {
        $this.TransactionManager = $transactionManager
        $this.SegmentManager = $segmentManager
        $this.FileManager = $fileManager
        $this.CheckpointDirectory = Join-Path -Path $this.FileManager.RootDirectory -ChildPath "checkpoints"
        $this.MaxCheckpoints = 5
        $this.CheckpointInterval = 60  # 1 heure
        $this.LastCheckpoint = [DateTime]::MinValue
        
        # Créer le répertoire des points de contrôle s'il n'existe pas
        if (-not (Test-Path -Path $this.CheckpointDirectory)) {
            New-Item -Path $this.CheckpointDirectory -ItemType Directory -Force | Out-Null
        }
    }
    
    # Méthode pour créer un point de contrôle
    [IndexCheckpoint] CreateCheckpoint() {
        # Vérifier si un point de contrôle est nécessaire
        $now = Get-Date
        
        if (($now - $this.LastCheckpoint).TotalMinutes -lt $this.CheckpointInterval) {
            # Pas besoin de créer un nouveau point de contrôle
            return $null
        }
        
        # Obtenir les IDs de segments
        $segmentIds = $this.FileManager.GetSegmentIds()
        
        # Obtenir les IDs de documents
        $documentIds = $this.FileManager.GetDocumentIds()
        
        # Obtenir les métadonnées de l'index
        $indexMetadata = $this.FileManager.LoadIndexMetadata()
        
        # Créer le point de contrôle
        $checkpoint = [IndexCheckpoint]::new($segmentIds, $documentIds, $indexMetadata)
        
        # Sauvegarder le point de contrôle
        $checkpointPath = Join-Path -Path $this.CheckpointDirectory -ChildPath "$($checkpoint.Id).json"
        $checkpoint.ToJson() | Out-File -FilePath $checkpointPath -Encoding UTF8
        
        # Mettre à jour la date du dernier point de contrôle
        $this.LastCheckpoint = $now
        
        # Nettoyer les anciens points de contrôle
        $this.CleanupCheckpoints()
        
        return $checkpoint
    }
    
    # Méthode pour nettoyer les anciens points de contrôle
    [void] CleanupCheckpoints() {
        # Obtenir tous les fichiers de points de contrôle
        $checkpointFiles = Get-ChildItem -Path $this.CheckpointDirectory -Filter "*.json" | Sort-Object -Property LastWriteTime -Descending
        
        # Supprimer les fichiers excédentaires
        if ($checkpointFiles.Count -gt $this.MaxCheckpoints) {
            $filesToDelete = $checkpointFiles | Select-Object -Skip $this.MaxCheckpoints
            
            foreach ($file in $filesToDelete) {
                Remove-Item -Path $file.FullName -Force
            }
        }
    }
    
    # Méthode pour récupérer l'index à partir d'un point de contrôle
    [bool] RecoverFromCheckpoint([string]$checkpointId = "") {
        # Déterminer le point de contrôle à utiliser
        $checkpointPath = ""
        
        if ([string]::IsNullOrEmpty($checkpointId)) {
            # Utiliser le point de contrôle le plus récent
            $checkpointFiles = Get-ChildItem -Path $this.CheckpointDirectory -Filter "*.json" | Sort-Object -Property LastWriteTime -Descending
            
            if ($checkpointFiles.Count -eq 0) {
                Write-Error "Aucun point de contrôle trouvé."
                return $false
            }
            
            $checkpointPath = $checkpointFiles[0].FullName
        } else {
            # Utiliser le point de contrôle spécifié
            $checkpointPath = Join-Path -Path $this.CheckpointDirectory -ChildPath "$checkpointId.json"
            
            if (-not (Test-Path -Path $checkpointPath)) {
                Write-Error "Point de contrôle non trouvé: $checkpointId"
                return $false
            }
        }
        
        try {
            # Charger le point de contrôle
            $checkpointJson = Get-Content -Path $checkpointPath -Raw
            $checkpoint = [IndexCheckpoint]::FromJson($checkpointJson)
            
            # Vérifier les segments
            $currentSegmentIds = $this.FileManager.GetSegmentIds()
            $missingSegmentIds = $checkpoint.SegmentIds | Where-Object { $_ -notin $currentSegmentIds }
            
            if ($missingSegmentIds.Count -gt 0) {
                Write-Warning "Segments manquants: $($missingSegmentIds -join ', ')"
            }
            
            # Vérifier les documents
            $currentDocumentIds = $this.FileManager.GetDocumentIds()
            $missingDocumentIds = $checkpoint.DocumentIds | Where-Object { $_ -notin $currentDocumentIds }
            
            if ($missingDocumentIds.Count -gt 0) {
                Write-Warning "Documents manquants: $($missingDocumentIds.Count) documents"
            }
            
            # Restaurer les métadonnées de l'index
            $this.FileManager.SaveIndexMetadata($checkpoint.IndexMetadata)
            
            # Réinitialiser le gestionnaire de segments
            $this.SegmentManager.Initialize()
            
            return $true
        } catch {
            Write-Error "Erreur lors de la récupération à partir du point de contrôle: $_"
            return $false
        }
    }
    
    # Méthode pour vérifier l'intégrité de l'index
    [hashtable] CheckIndexIntegrity() {
        $result = @{
            is_valid = $true
            errors = @()
            warnings = @()
            segments = @{
                total = 0
                valid = 0
                invalid = 0
                details = @{}
            }
            documents = @{
                total = 0
                valid = 0
                invalid = 0
                orphaned = 0
            }
        }
        
        # Vérifier les segments
        $segmentIds = $this.FileManager.GetSegmentIds()
        $result.segments.total = $segmentIds.Count
        
        foreach ($segmentId in $segmentIds) {
            try {
                $segment = $this.FileManager.LoadSegment($segmentId)
                
                if ($null -eq $segment) {
                    $result.segments.invalid++
                    $result.errors += "Segment invalide: $segmentId"
                    $result.is_valid = $false
                    $result.segments.details[$segmentId] = "Erreur de chargement"
                } else {
                    $result.segments.valid++
                    $result.segments.details[$segmentId] = "OK"
                    
                    # Vérifier les documents du segment
                    $result.documents.total += $segment.Documents.Count
                    
                    foreach ($docId in $segment.Documents.Keys) {
                        $doc = $segment.Documents[$docId]
                        
                        if ($null -eq $doc) {
                            $result.documents.invalid++
                            $result.errors += "Document invalide dans le segment $segmentId: $docId"
                            $result.is_valid = $false
                        } else {
                            $result.documents.valid++
                        }
                    }
                }
            } catch {
                $result.segments.invalid++
                $result.errors += "Erreur lors du chargement du segment $segmentId: $_"
                $result.is_valid = $false
                $result.segments.details[$segmentId] = "Exception: $($_.Exception.Message)"
            }
        }
        
        # Vérifier les documents orphelins
        $documentIds = $this.FileManager.GetDocumentIds()
        $segmentDocumentIds = [System.Collections.Generic.HashSet[string]]::new()
        
        foreach ($segmentId in $segmentIds) {
            try {
                $segment = $this.FileManager.LoadSegment($segmentId)
                
                if ($null -ne $segment) {
                    foreach ($docId in $segment.Documents.Keys) {
                        $segmentDocumentIds.Add($docId)
                    }
                }
            } catch {
                # Ignorer les erreurs, déjà traitées ci-dessus
            }
        }
        
        foreach ($docId in $documentIds) {
            if (-not $segmentDocumentIds.Contains($docId)) {
                $result.documents.orphaned++
                $result.warnings += "Document orphelin: $docId"
            }
        }
        
        return $result
    }
    
    # Méthode pour réparer l'index
    [hashtable] RepairIndex() {
        $result = @{
            success = $true
            repaired_segments = 0
            repaired_documents = 0
            deleted_segments = 0
            deleted_documents = 0
            errors = @()
        }
        
        # Vérifier l'intégrité de l'index
        $integrity = $this.CheckIndexIntegrity()
        
        if ($integrity.is_valid) {
            # L'index est valide, rien à réparer
            return $result
        }
        
        # Réparer les segments invalides
        foreach ($segmentId in $integrity.segments.details.Keys) {
            $status = $integrity.segments.details[$segmentId]
            
            if ($status -ne "OK") {
                try {
                    # Supprimer le segment invalide
                    $this.FileManager.DeleteSegment($segmentId)
                    $result.deleted_segments++
                } catch {
                    $result.errors += "Erreur lors de la suppression du segment $segmentId: $_"
                    $result.success = $false
                }
            }
        }
        
        # Supprimer les documents orphelins
        $documentIds = $this.FileManager.GetDocumentIds()
        $segmentDocumentIds = [System.Collections.Generic.HashSet[string]]::new()
        
        foreach ($segmentId in $this.FileManager.GetSegmentIds()) {
            try {
                $segment = $this.FileManager.LoadSegment($segmentId)
                
                if ($null -ne $segment) {
                    foreach ($docId in $segment.Documents.Keys) {
                        $segmentDocumentIds.Add($docId)
                    }
                }
            } catch {
                # Ignorer les erreurs
            }
        }
        
        foreach ($docId in $documentIds) {
            if (-not $segmentDocumentIds.Contains($docId)) {
                try {
                    # Supprimer le document orphelin
                    $this.FileManager.DeleteDocument($docId)
                    $result.deleted_documents++
                } catch {
                    $result.errors += "Erreur lors de la suppression du document orphelin $docId: $_"
                    $result.success = $false
                }
            }
        }
        
        # Créer un nouveau point de contrôle
        $this.CreateCheckpoint()
        
        return $result
    }
}

# Fonction pour créer un gestionnaire de récupération d'index
function New-IndexRecoveryManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexTransactionManager]$TransactionManager,
        
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $true)]
        [IndexFileManager]$FileManager,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxCheckpoints = 5,
        
        [Parameter(Mandatory = $false)]
        [int]$CheckpointInterval = 60
    )
    
    $manager = [IndexRecoveryManager]::new($TransactionManager, $SegmentManager, $FileManager)
    $manager.MaxCheckpoints = $MaxCheckpoints
    $manager.CheckpointInterval = $CheckpointInterval
    
    return $manager
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-IndexRecoveryManager
