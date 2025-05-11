# DeletionMarker.ps1
# Script implémentant le marquage des documents supprimés pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$updateOptimizationPath = Join-Path -Path $scriptPath -ChildPath "UpdateOptimization.ps1"

if (Test-Path -Path $updateOptimizationPath) {
    . $updateOptimizationPath
} else {
    Write-Error "Le fichier UpdateOptimization.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un marqueur de suppression
class DeletionMarker {
    # ID du document supprimé
    [string]$DocumentId
    
    # Horodatage de suppression
    [DateTime]$DeletedAt
    
    # Utilisateur ayant effectué la suppression
    [string]$DeletedBy
    
    # Raison de la suppression
    [string]$Reason
    
    # Indicateur de suppression définitive
    [bool]$IsPermanent
    
    # Constructeur par défaut
    DeletionMarker() {
        $this.DocumentId = ""
        $this.DeletedAt = Get-Date
        $this.DeletedBy = "system"
        $this.Reason = ""
        $this.IsPermanent = $false
    }
    
    # Constructeur avec ID de document
    DeletionMarker([string]$documentId) {
        $this.DocumentId = $documentId
        $this.DeletedAt = Get-Date
        $this.DeletedBy = "system"
        $this.Reason = ""
        $this.IsPermanent = $false
    }
    
    # Constructeur complet
    DeletionMarker([string]$documentId, [string]$deletedBy, [string]$reason, [bool]$isPermanent) {
        $this.DocumentId = $documentId
        $this.DeletedAt = Get-Date
        $this.DeletedBy = $deletedBy
        $this.Reason = $reason
        $this.IsPermanent = $isPermanent
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            document_id = $this.DocumentId
            deleted_at = $this.DeletedAt.ToString("o")
            deleted_by = $this.DeletedBy
            reason = $this.Reason
            is_permanent = $this.IsPermanent
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [DeletionMarker] FromHashtable([hashtable]$data) {
        $marker = [DeletionMarker]::new()
        
        if ($data.ContainsKey("document_id")) {
            $marker.DocumentId = $data.document_id
        }
        
        if ($data.ContainsKey("deleted_at")) {
            $marker.DeletedAt = [DateTime]::Parse($data.deleted_at)
        }
        
        if ($data.ContainsKey("deleted_by")) {
            $marker.DeletedBy = $data.deleted_by
        }
        
        if ($data.ContainsKey("reason")) {
            $marker.Reason = $data.reason
        }
        
        if ($data.ContainsKey("is_permanent")) {
            $marker.IsPermanent = $data.is_permanent
        }
        
        return $marker
    }
}

# Classe pour représenter un registre des suppressions
class DeletionRegistry {
    # Dictionnaire des marqueurs de suppression
    [System.Collections.Generic.Dictionary[string, DeletionMarker]]$Markers
    
    # Chemin du fichier de registre
    [string]$RegistryFilePath
    
    # Constructeur par défaut
    DeletionRegistry() {
        $this.Markers = [System.Collections.Generic.Dictionary[string, DeletionMarker]]::new()
        $this.RegistryFilePath = Join-Path -Path $env:TEMP -ChildPath "deletion_registry.json"
    }
    
    # Constructeur avec chemin de fichier
    DeletionRegistry([string]$registryFilePath) {
        $this.Markers = [System.Collections.Generic.Dictionary[string, DeletionMarker]]::new()
        $this.RegistryFilePath = $registryFilePath
        
        # Charger le registre existant s'il existe
        $this.LoadRegistry()
    }
    
    # Méthode pour charger le registre
    [bool] LoadRegistry() {
        if (-not (Test-Path -Path $this.RegistryFilePath)) {
            return $false
        }
        
        try {
            $json = Get-Content -Path $this.RegistryFilePath -Raw
            $data = ConvertFrom-Json -InputObject $json -AsHashtable
            
            foreach ($documentId in $data.Keys) {
                $markerData = $data[$documentId]
                $marker = [DeletionMarker]::FromHashtable($markerData)
                $this.Markers[$documentId] = $marker
            }
            
            return $true
        } catch {
            Write-Error "Erreur lors du chargement du registre des suppressions: $_"
            return $false
        }
    }
    
    # Méthode pour sauvegarder le registre
    [bool] SaveRegistry() {
        try {
            $data = @{}
            
            foreach ($documentId in $this.Markers.Keys) {
                $marker = $this.Markers[$documentId]
                $data[$documentId] = $marker.ToHashtable()
            }
            
            $json = ConvertTo-Json -InputObject $data -Depth 10
            $json | Out-File -FilePath $this.RegistryFilePath -Encoding UTF8
            
            return $true
        } catch {
            Write-Error "Erreur lors de la sauvegarde du registre des suppressions: $_"
            return $false
        }
    }
    
    # Méthode pour ajouter un marqueur de suppression
    [DeletionMarker] AddMarker([string]$documentId, [string]$deletedBy = "system", [string]$reason = "", [bool]$isPermanent = $false) {
        $marker = [DeletionMarker]::new($documentId, $deletedBy, $reason, $isPermanent)
        $this.Markers[$documentId] = $marker
        
        # Sauvegarder le registre
        $this.SaveRegistry()
        
        return $marker
    }
    
    # Méthode pour vérifier si un document est marqué comme supprimé
    [bool] IsDocumentMarkedAsDeleted([string]$documentId) {
        return $this.Markers.ContainsKey($documentId)
    }
    
    # Méthode pour obtenir un marqueur de suppression
    [DeletionMarker] GetMarker([string]$documentId) {
        if ($this.Markers.ContainsKey($documentId)) {
            return $this.Markers[$documentId]
        }
        
        return $null
    }
    
    # Méthode pour supprimer un marqueur de suppression
    [bool] RemoveMarker([string]$documentId) {
        if ($this.Markers.ContainsKey($documentId)) {
            $this.Markers.Remove($documentId)
            
            # Sauvegarder le registre
            $this.SaveRegistry()
            
            return $true
        }
        
        return $false
    }
    
    # Méthode pour obtenir tous les marqueurs de suppression
    [DeletionMarker[]] GetAllMarkers() {
        return $this.Markers.Values
    }
    
    # Méthode pour obtenir les marqueurs de suppression par utilisateur
    [DeletionMarker[]] GetMarkersByUser([string]$deletedBy) {
        return $this.Markers.Values | Where-Object { $_.DeletedBy -eq $deletedBy }
    }
    
    # Méthode pour obtenir les marqueurs de suppression par date
    [DeletionMarker[]] GetMarkersByDate([DateTime]$startDate, [DateTime]$endDate) {
        return $this.Markers.Values | Where-Object { $_.DeletedAt -ge $startDate -and $_.DeletedAt -le $endDate }
    }
    
    # Méthode pour obtenir les marqueurs de suppression permanente
    [DeletionMarker[]] GetPermanentMarkers() {
        return $this.Markers.Values | Where-Object { $_.IsPermanent }
    }
    
    # Méthode pour obtenir les marqueurs de suppression temporaire
    [DeletionMarker[]] GetTemporaryMarkers() {
        return $this.Markers.Values | Where-Object { -not $_.IsPermanent }
    }
    
    # Méthode pour marquer un document comme supprimé définitivement
    [bool] MarkAsPermanent([string]$documentId) {
        if ($this.Markers.ContainsKey($documentId)) {
            $this.Markers[$documentId].IsPermanent = $true
            
            # Sauvegarder le registre
            $this.SaveRegistry()
            
            return $true
        }
        
        return $false
    }
}

# Classe pour représenter un gestionnaire de suppressions
class DeletionManager {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Registre des suppressions
    [DeletionRegistry]$Registry
    
    # Gestionnaire de suivi des modifications
    [ChangeTrackingManager]$ChangeTracker
    
    # Constructeur par défaut
    DeletionManager() {
        $this.SegmentManager = $null
        $this.Registry = [DeletionRegistry]::new()
        $this.ChangeTracker = $null
    }
    
    # Constructeur avec gestionnaire de segments
    DeletionManager([IndexSegmentManager]$segmentManager) {
        $this.SegmentManager = $segmentManager
        $this.Registry = [DeletionRegistry]::new()
        $this.ChangeTracker = $null
    }
    
    # Constructeur complet
    DeletionManager([IndexSegmentManager]$segmentManager, [DeletionRegistry]$registry, [ChangeTrackingManager]$changeTracker) {
        $this.SegmentManager = $segmentManager
        $this.Registry = $registry
        $this.ChangeTracker = $changeTracker
    }
    
    # Méthode pour marquer un document comme supprimé
    [DeletionMarker] MarkDocumentAsDeleted([string]$documentId, [string]$deletedBy = "system", [string]$reason = "", [bool]$isPermanent = $false) {
        # Vérifier si le document existe
        $document = $this.SegmentManager.GetDocument($documentId)
        
        if ($null -eq $document) {
            Write-Warning "Le document $documentId n'existe pas."
        }
        
        # Ajouter un marqueur de suppression
        $marker = $this.Registry.AddMarker($documentId, $deletedBy, $reason, $isPermanent)
        
        # Enregistrer la suppression si un gestionnaire de suivi est disponible
        if ($null -ne $this.ChangeTracker) {
            $entry = $this.ChangeTracker.TrackDelete($documentId, $deletedBy)
            
            # Ajouter des métadonnées
            $entry.AddMetadata("reason", $reason)
            $entry.AddMetadata("is_permanent", $isPermanent)
        }
        
        # Si la suppression est permanente, supprimer le document de l'index
        if ($isPermanent) {
            $this.SegmentManager.RemoveDocument($documentId)
        }
        
        return $marker
    }
    
    # Méthode pour restaurer un document supprimé
    [bool] RestoreDeletedDocument([string]$documentId, [string]$restoredBy = "system") {
        # Vérifier si le document est marqué comme supprimé
        if (-not $this.Registry.IsDocumentMarkedAsDeleted($documentId)) {
            Write-Warning "Le document $documentId n'est pas marqué comme supprimé."
            return $false
        }
        
        # Récupérer le marqueur de suppression
        $marker = $this.Registry.GetMarker($documentId)
        
        # Vérifier si la suppression est permanente
        if ($marker.IsPermanent) {
            Write-Warning "Le document $documentId a été supprimé définitivement et ne peut pas être restauré."
            return $false
        }
        
        # Supprimer le marqueur de suppression
        $this.Registry.RemoveMarker($documentId)
        
        # Enregistrer la restauration si un gestionnaire de suivi est disponible
        if ($null -ne $this.ChangeTracker) {
            $entry = $this.ChangeTracker.TrackAdd($documentId, $restoredBy)
            
            # Ajouter des métadonnées
            $entry.AddMetadata("restored_from_deletion", $true)
            $entry.AddMetadata("deleted_at", $marker.DeletedAt.ToString("o"))
            $entry.AddMetadata("deleted_by", $marker.DeletedBy)
        }
        
        return $true
    }
    
    # Méthode pour supprimer définitivement un document
    [bool] PermanentlyDeleteDocument([string]$documentId, [string]$deletedBy = "system", [string]$reason = "") {
        # Vérifier si le document est déjà marqué comme supprimé
        if ($this.Registry.IsDocumentMarkedAsDeleted($documentId)) {
            # Marquer le document comme supprimé définitivement
            $this.Registry.MarkAsPermanent($documentId)
        } else {
            # Marquer le document comme supprimé définitivement
            $this.MarkDocumentAsDeleted($documentId, $deletedBy, $reason, $true)
        }
        
        # Supprimer le document de l'index
        $this.SegmentManager.RemoveDocument($documentId)
        
        return $true
    }
    
    # Méthode pour obtenir les documents supprimés
    [hashtable] GetDeletedDocuments() {
        $result = @{
            total = 0
            permanent = 0
            temporary = 0
            documents = @{}
        }
        
        # Récupérer tous les marqueurs de suppression
        $markers = $this.Registry.GetAllMarkers()
        
        $result.total = $markers.Count
        $result.permanent = ($markers | Where-Object { $_.IsPermanent }).Count
        $result.temporary = ($markers | Where-Object { -not $_.IsPermanent }).Count
        
        foreach ($marker in $markers) {
            $result.documents[$marker.DocumentId] = @{
                deleted_at = $marker.DeletedAt
                deleted_by = $marker.DeletedBy
                reason = $marker.Reason
                is_permanent = $marker.IsPermanent
            }
        }
        
        return $result
    }
    
    # Méthode pour nettoyer les documents supprimés définitivement
    [int] CleanupPermanentlyDeletedDocuments() {
        # Récupérer les marqueurs de suppression permanente
        $markers = $this.Registry.GetPermanentMarkers()
        
        $count = 0
        
        foreach ($marker in $markers) {
            # Supprimer le document de l'index
            $this.SegmentManager.RemoveDocument($marker.DocumentId)
            
            # Supprimer le marqueur de suppression
            $this.Registry.RemoveMarker($marker.DocumentId)
            
            $count++
        }
        
        return $count
    }
}

# Fonction pour créer un registre des suppressions
function New-DeletionRegistry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RegistryFilePath = (Join-Path -Path $env:TEMP -ChildPath "deletion_registry.json")
    )
    
    return [DeletionRegistry]::new($RegistryFilePath)
}

# Fonction pour créer un gestionnaire de suppressions
function New-DeletionManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $false)]
        [DeletionRegistry]$Registry = (New-DeletionRegistry),
        
        [Parameter(Mandatory = $false)]
        [ChangeTrackingManager]$ChangeTracker = $null
    )
    
    return [DeletionManager]::new($SegmentManager, $Registry, $ChangeTracker)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-DeletionRegistry, New-DeletionManager
