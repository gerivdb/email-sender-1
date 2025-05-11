# ModificationMerger.ps1
# Script implémentant le mécanisme de fusion des modifications pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$documentUpdaterPath = Join-Path -Path $scriptPath -ChildPath "DocumentUpdater.ps1"

if (Test-Path -Path $documentUpdaterPath) {
    . $documentUpdaterPath
} else {
    Write-Error "Le fichier DocumentUpdater.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une modification de document
class DocumentModification {
    # ID du document
    [string]$DocumentId
    
    # Type de modification (Add, Update, Delete)
    [string]$Type
    
    # Horodatage de la modification
    [DateTime]$Timestamp
    
    # Document avant la modification
    [IndexDocument]$BeforeDocument
    
    # Document après la modification
    [IndexDocument]$AfterDocument
    
    # Utilisateur ayant effectué la modification
    [string]$UserId
    
    # Source de la modification
    [string]$Source
    
    # Constructeur par défaut
    DocumentModification() {
        $this.DocumentId = ""
        $this.Type = "Add"
        $this.Timestamp = Get-Date
        $this.BeforeDocument = $null
        $this.AfterDocument = $null
        $this.UserId = "system"
        $this.Source = "system"
    }
    
    # Constructeur avec ID et type
    DocumentModification([string]$documentId, [string]$type) {
        $this.DocumentId = $documentId
        $this.Type = $type
        $this.Timestamp = Get-Date
        $this.BeforeDocument = $null
        $this.AfterDocument = $null
        $this.UserId = "system"
        $this.Source = "system"
    }
    
    # Constructeur complet
    DocumentModification([string]$documentId, [string]$type, [IndexDocument]$beforeDocument, [IndexDocument]$afterDocument, [string]$userId, [string]$source) {
        $this.DocumentId = $documentId
        $this.Type = $type
        $this.Timestamp = Get-Date
        $this.BeforeDocument = $beforeDocument
        $this.AfterDocument = $afterDocument
        $this.UserId = $userId
        $this.Source = $source
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            document_id = $this.DocumentId
            type = $this.Type
            timestamp = $this.Timestamp.ToString("o")
            before_document = if ($null -ne $this.BeforeDocument) { $this.BeforeDocument.ToHashtable() } else { $null }
            after_document = if ($null -ne $this.AfterDocument) { $this.AfterDocument.ToHashtable() } else { $null }
            user_id = $this.UserId
            source = $this.Source
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [DocumentModification] FromHashtable([hashtable]$data) {
        $modification = [DocumentModification]::new()
        
        if ($data.ContainsKey("document_id")) {
            $modification.DocumentId = $data.document_id
        }
        
        if ($data.ContainsKey("type")) {
            $modification.Type = $data.type
        }
        
        if ($data.ContainsKey("timestamp")) {
            $modification.Timestamp = [DateTime]::Parse($data.timestamp)
        }
        
        if ($data.ContainsKey("before_document") -and $null -ne $data.before_document) {
            $modification.BeforeDocument = [IndexDocument]::FromHashtable($data.before_document)
        }
        
        if ($data.ContainsKey("after_document") -and $null -ne $data.after_document) {
            $modification.AfterDocument = [IndexDocument]::FromHashtable($data.after_document)
        }
        
        if ($data.ContainsKey("user_id")) {
            $modification.UserId = $data.user_id
        }
        
        if ($data.ContainsKey("source")) {
            $modification.Source = $data.source
        }
        
        return $modification
    }
}

# Classe pour représenter un journal des modifications de documents
class DocumentModificationLog {
    # Liste des modifications
    [System.Collections.Generic.List[DocumentModification]]$Modifications
    
    # Constructeur par défaut
    DocumentModificationLog() {
        $this.Modifications = [System.Collections.Generic.List[DocumentModification]]::new()
    }
    
    # Méthode pour ajouter une modification
    [void] AddModification([DocumentModification]$modification) {
        $this.Modifications.Add($modification)
    }
    
    # Méthode pour obtenir les modifications pour un document
    [DocumentModification[]] GetModificationsForDocument([string]$documentId) {
        return $this.Modifications | Where-Object { $_.DocumentId -eq $documentId }
    }
    
    # Méthode pour obtenir les modifications par type
    [DocumentModification[]] GetModificationsByType([string]$type) {
        return $this.Modifications | Where-Object { $_.Type -eq $type }
    }
    
    # Méthode pour obtenir les modifications depuis un horodatage
    [DocumentModification[]] GetModificationsSince([DateTime]$timestamp) {
        return $this.Modifications | Where-Object { $_.Timestamp -gt $timestamp }
    }
    
    # Méthode pour obtenir les modifications par utilisateur
    [DocumentModification[]] GetModificationsByUser([string]$userId) {
        return $this.Modifications | Where-Object { $_.UserId -eq $userId }
    }
    
    # Méthode pour obtenir les modifications par source
    [DocumentModification[]] GetModificationsBySource([string]$source) {
        return $this.Modifications | Where-Object { $_.Source -eq $source }
    }
    
    # Méthode pour nettoyer les modifications anciennes
    [int] CleanupOldModifications([int]$maxAgeInDays) {
        $cutoffDate = (Get-Date).AddDays(-$maxAgeInDays)
        $oldModifications = $this.Modifications | Where-Object { $_.Timestamp -lt $cutoffDate }
        
        foreach ($modification in $oldModifications) {
            $this.Modifications.Remove($modification)
        }
        
        return $oldModifications.Count
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        $modifications = $this.Modifications | ForEach-Object { $_.ToHashtable() }
        return ConvertTo-Json -InputObject $modifications -Depth 10
    }
    
    # Méthode pour créer à partir de JSON
    static [DocumentModificationLog] FromJson([string]$json) {
        $log = [DocumentModificationLog]::new()
        $modifications = ConvertFrom-Json -InputObject $json
        
        foreach ($modificationData in $modifications) {
            $hashtable = @{}
            
            foreach ($prop in $modificationData.PSObject.Properties) {
                $hashtable[$prop.Name] = $prop.Value
            }
            
            $modification = [DocumentModification]::FromHashtable($hashtable)
            $log.AddModification($modification)
        }
        
        return $log
    }
}

# Classe pour représenter un gestionnaire de fusion des modifications
class ModificationMerger {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Gestionnaire de mise à jour de documents
    [DocumentUpdater]$DocumentUpdater
    
    # Journal des modifications
    [DocumentModificationLog]$ModificationLog
    
    # Chemin du fichier de journal
    [string]$LogFilePath
    
    # Constructeur par défaut
    ModificationMerger() {
        $this.SegmentManager = $null
        $this.DocumentUpdater = $null
        $this.ModificationLog = [DocumentModificationLog]::new()
        $this.LogFilePath = Join-Path -Path $env:TEMP -ChildPath "document_modifications.json"
    }
    
    # Constructeur avec gestionnaires
    ModificationMerger([IndexSegmentManager]$segmentManager, [DocumentUpdater]$documentUpdater) {
        $this.SegmentManager = $segmentManager
        $this.DocumentUpdater = $documentUpdater
        $this.ModificationLog = [DocumentModificationLog]::new()
        $this.LogFilePath = Join-Path -Path $env:TEMP -ChildPath "document_modifications.json"
        
        # Charger le journal existant s'il existe
        $this.LoadModificationLog()
    }
    
    # Constructeur complet
    ModificationMerger([IndexSegmentManager]$segmentManager, [DocumentUpdater]$documentUpdater, [string]$logFilePath) {
        $this.SegmentManager = $segmentManager
        $this.DocumentUpdater = $documentUpdater
        $this.ModificationLog = [DocumentModificationLog]::new()
        $this.LogFilePath = $logFilePath
        
        # Charger le journal existant s'il existe
        $this.LoadModificationLog()
    }
    
    # Méthode pour charger le journal des modifications
    [bool] LoadModificationLog() {
        if (-not (Test-Path -Path $this.LogFilePath)) {
            return $false
        }
        
        try {
            $json = Get-Content -Path $this.LogFilePath -Raw
            $this.ModificationLog = [DocumentModificationLog]::FromJson($json)
            return $true
        } catch {
            Write-Error "Erreur lors du chargement du journal des modifications: $_"
            return $false
        }
    }
    
    # Méthode pour sauvegarder le journal des modifications
    [bool] SaveModificationLog() {
        try {
            $json = $this.ModificationLog.ToJson()
            $json | Out-File -FilePath $this.LogFilePath -Encoding UTF8
            return $true
        } catch {
            Write-Error "Erreur lors de la sauvegarde du journal des modifications: $_"
            return $false
        }
    }
    
    # Méthode pour enregistrer une modification
    [DocumentModification] RecordModification([string]$type, [IndexDocument]$beforeDocument, [IndexDocument]$afterDocument, [string]$userId = "system", [string]$source = "system") {
        $documentId = if ($null -ne $afterDocument) { $afterDocument.Id } else { $beforeDocument.Id }
        
        $modification = [DocumentModification]::new($documentId, $type, $beforeDocument, $afterDocument, $userId, $source)
        $this.ModificationLog.AddModification($modification)
        
        # Sauvegarder le journal
        $this.SaveModificationLog()
        
        return $modification
    }
    
    # Méthode pour fusionner des modifications
    [IndexDocument] MergeModifications([string]$documentId, [DateTime]$since = [DateTime]::MinValue) {
        # Obtenir les modifications pour le document
        $modifications = $this.ModificationLog.GetModificationsForDocument($documentId)
        
        # Filtrer par date si nécessaire
        if ($since -ne [DateTime]::MinValue) {
            $modifications = $modifications | Where-Object { $_.Timestamp -gt $since }
        }
        
        # Trier les modifications par horodatage
        $modifications = $modifications | Sort-Object -Property Timestamp
        
        # Si aucune modification, retourner null
        if ($modifications.Count -eq 0) {
            return $null
        }
        
        # Vérifier si le document existe
        $document = $this.SegmentManager.GetDocument($documentId)
        
        if ($null -eq $document) {
            # Le document n'existe pas, vérifier s'il y a une modification de type Add
            $addModification = $modifications | Where-Object { $_.Type -eq "Add" } | Select-Object -Last 1
            
            if ($null -ne $addModification -and $null -ne $addModification.AfterDocument) {
                return $addModification.AfterDocument
            }
            
            return $null
        }
        
        # Appliquer les modifications dans l'ordre
        foreach ($modification in $modifications) {
            switch ($modification.Type) {
                "Add" {
                    # Ignorer les ajouts si le document existe déjà
                    continue
                }
                "Update" {
                    if ($null -ne $modification.AfterDocument) {
                        $document = $this.DocumentUpdater.UpdateDocument($modification.AfterDocument)
                    }
                }
                "Delete" {
                    # Si une suppression est trouvée, le document n'existe plus
                    return $null
                }
            }
        }
        
        return $document
    }
    
    # Méthode pour fusionner toutes les modifications depuis un horodatage
    [hashtable] MergeAllModifications([DateTime]$since = [DateTime]::MinValue) {
        $result = @{
            processed = 0
            added = 0
            updated = 0
            deleted = 0
            errors = [System.Collections.Generic.List[string]]::new()
        }
        
        # Obtenir toutes les modifications
        $modifications = $this.ModificationLog.GetModificationsSince($since)
        
        # Regrouper les modifications par document
        $documentIds = $modifications | Select-Object -ExpandProperty DocumentId -Unique
        
        foreach ($documentId in $documentIds) {
            try {
                $result.processed++
                
                # Fusionner les modifications pour ce document
                $document = $this.MergeModifications($documentId, $since)
                
                if ($null -eq $document) {
                    # Le document a été supprimé ou n'existe pas
                    $this.SegmentManager.RemoveDocument($documentId)
                    $result.deleted++
                } else {
                    # Vérifier si le document existe déjà
                    $existingDocument = $this.SegmentManager.GetDocument($documentId)
                    
                    if ($null -eq $existingDocument) {
                        # Ajouter le document
                        $this.SegmentManager.AddDocument($document)
                        $result.added++
                    } else {
                        # Mettre à jour le document
                        $this.DocumentUpdater.UpdateDocument($document)
                        $result.updated++
                    }
                }
            } catch {
                $result.errors.Add("Erreur lors de la fusion des modifications pour le document $documentId: $_")
            }
        }
        
        return $result
    }
    
    # Méthode pour nettoyer les modifications anciennes
    [int] CleanupOldModifications([int]$maxAgeInDays) {
        $count = $this.ModificationLog.CleanupOldModifications($maxAgeInDays)
        
        if ($count -gt 0) {
            $this.SaveModificationLog()
        }
        
        return $count
    }
}

# Fonction pour créer un gestionnaire de fusion des modifications
function New-ModificationMerger {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $true)]
        [DocumentUpdater]$DocumentUpdater,
        
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = (Join-Path -Path $env:TEMP -ChildPath "document_modifications.json")
    )
    
    return [ModificationMerger]::new($SegmentManager, $DocumentUpdater, $LogFilePath)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-ModificationMerger
