# ChangeTracking.ps1
# Script implémentant le système de suivi des modifications pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$performancePath = Join-Path -Path $parentPath -ChildPath "performance\PerformanceMetrics.ps1"

if (Test-Path -Path $performancePath) {
    . $performancePath
} else {
    Write-Error "Le fichier PerformanceMetrics.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un journal des modifications
class ChangeLog {
    # ID du journal
    [string]$Id
    
    # Horodatage de création
    [DateTime]$CreatedAt
    
    # Liste des modifications
    [System.Collections.Generic.List[ChangeEntry]]$Entries
    
    # Constructeur par défaut
    ChangeLog() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.CreatedAt = Get-Date
        $this.Entries = [System.Collections.Generic.List[ChangeEntry]]::new()
    }
    
    # Méthode pour ajouter une entrée
    [void] AddEntry([ChangeEntry]$entry) {
        $this.Entries.Add($entry)
    }
    
    # Méthode pour obtenir les entrées depuis un horodatage
    [ChangeEntry[]] GetEntriesSince([DateTime]$timestamp) {
        return $this.Entries | Where-Object { $_.Timestamp -gt $timestamp }
    }
    
    # Méthode pour obtenir les entrées pour un document
    [ChangeEntry[]] GetEntriesForDocument([string]$documentId) {
        return $this.Entries | Where-Object { $_.DocumentId -eq $documentId }
    }
    
    # Méthode pour obtenir les entrées par type
    [ChangeEntry[]] GetEntriesByType([string]$type) {
        return $this.Entries | Where-Object { $_.Type -eq $type }
    }
    
    # Méthode pour nettoyer les entrées anciennes
    [int] CleanupOldEntries([int]$maxAgeInDays) {
        $cutoffDate = (Get-Date).AddDays(-$maxAgeInDays)
        $oldEntries = $this.Entries | Where-Object { $_.Timestamp -lt $cutoffDate }
        
        foreach ($entry in $oldEntries) {
            $this.Entries.Remove($entry)
        }
        
        return $oldEntries.Count
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        $obj = @{
            id = $this.Id
            created_at = $this.CreatedAt.ToString("o")
            entries = $this.Entries | ForEach-Object { $_.ToHashtable() }
        }
        
        return ConvertTo-Json -InputObject $obj -Depth 10
    }
    
    # Méthode pour créer à partir de JSON
    static [ChangeLog] FromJson([string]$json) {
        $obj = ConvertFrom-Json -InputObject $json
        
        $log = [ChangeLog]::new()
        $log.Id = $obj.id
        $log.CreatedAt = [DateTime]::Parse($obj.created_at)
        
        foreach ($entryObj in $obj.entries) {
            $entry = [ChangeEntry]::new()
            $entry.Id = $entryObj.id
            $entry.Type = $entryObj.type
            $entry.DocumentId = $entryObj.document_id
            $entry.Timestamp = [DateTime]::Parse($entryObj.timestamp)
            $entry.UserId = $entryObj.user_id
            $entry.Source = $entryObj.source
            
            if ($entryObj.PSObject.Properties.Name.Contains("metadata")) {
                $entry.Metadata = @{}
                
                foreach ($prop in $entryObj.metadata.PSObject.Properties) {
                    $entry.Metadata[$prop.Name] = $prop.Value
                }
            }
            
            $log.Entries.Add($entry)
        }
        
        return $log
    }
}

# Classe pour représenter une entrée de modification
class ChangeEntry {
    # ID de l'entrée
    [string]$Id
    
    # Type de modification (Add, Update, Delete)
    [string]$Type
    
    # ID du document concerné
    [string]$DocumentId
    
    # Horodatage de la modification
    [DateTime]$Timestamp
    
    # ID de l'utilisateur ayant effectué la modification
    [string]$UserId
    
    # Source de la modification (API, UI, Sync, etc.)
    [string]$Source
    
    # Métadonnées supplémentaires
    [hashtable]$Metadata
    
    # Constructeur par défaut
    ChangeEntry() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Type = "Add"
        $this.DocumentId = ""
        $this.Timestamp = Get-Date
        $this.UserId = "system"
        $this.Source = "system"
        $this.Metadata = @{}
    }
    
    # Constructeur avec type et document
    ChangeEntry([string]$type, [string]$documentId) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Type = $type
        $this.DocumentId = $documentId
        $this.Timestamp = Get-Date
        $this.UserId = "system"
        $this.Source = "system"
        $this.Metadata = @{}
    }
    
    # Constructeur complet
    ChangeEntry([string]$type, [string]$documentId, [string]$userId, [string]$source) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Type = $type
        $this.DocumentId = $documentId
        $this.Timestamp = Get-Date
        $this.UserId = $userId
        $this.Source = $source
        $this.Metadata = @{}
    }
    
    # Méthode pour ajouter une métadonnée
    [void] AddMetadata([string]$key, [object]$value) {
        $this.Metadata[$key] = $value
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            id = $this.Id
            type = $this.Type
            document_id = $this.DocumentId
            timestamp = $this.Timestamp.ToString("o")
            user_id = $this.UserId
            source = $this.Source
            metadata = $this.Metadata
        }
    }
}

# Classe pour représenter un gestionnaire de suivi des modifications
class ChangeTrackingManager {
    # Journal des modifications
    [ChangeLog]$ChangeLog
    
    # Chemin du fichier de journal
    [string]$LogFilePath
    
    # Intervalle de sauvegarde (en secondes)
    [int]$SaveInterval
    
    # Dernier horodatage de sauvegarde
    [DateTime]$LastSave
    
    # Métriques de performance
    [PerformanceMetricsManager]$Metrics
    
    # Constructeur par défaut
    ChangeTrackingManager() {
        $this.ChangeLog = [ChangeLog]::new()
        $this.LogFilePath = Join-Path -Path $env:TEMP -ChildPath "change_log.json"
        $this.SaveInterval = 60  # 1 minute
        $this.LastSave = Get-Date
        $this.Metrics = [PerformanceMetricsManager]::new()
    }
    
    # Constructeur avec chemin de fichier
    ChangeTrackingManager([string]$logFilePath) {
        $this.ChangeLog = [ChangeLog]::new()
        $this.LogFilePath = $logFilePath
        $this.SaveInterval = 60  # 1 minute
        $this.LastSave = Get-Date
        $this.Metrics = [PerformanceMetricsManager]::new()
        
        # Charger le journal existant s'il existe
        $this.LoadChangeLog()
    }
    
    # Constructeur complet
    ChangeTrackingManager([string]$logFilePath, [int]$saveInterval) {
        $this.ChangeLog = [ChangeLog]::new()
        $this.LogFilePath = $logFilePath
        $this.SaveInterval = $saveInterval
        $this.LastSave = Get-Date
        $this.Metrics = [PerformanceMetricsManager]::new()
        
        # Charger le journal existant s'il existe
        $this.LoadChangeLog()
    }
    
    # Méthode pour charger le journal des modifications
    [bool] LoadChangeLog() {
        if (-not (Test-Path -Path $this.LogFilePath)) {
            return $false
        }
        
        try {
            $json = Get-Content -Path $this.LogFilePath -Raw
            $this.ChangeLog = [ChangeLog]::FromJson($json)
            return $true
        } catch {
            Write-Error "Erreur lors du chargement du journal des modifications: $_"
            return $false
        }
    }
    
    # Méthode pour sauvegarder le journal des modifications
    [bool] SaveChangeLog() {
        try {
            $json = $this.ChangeLog.ToJson()
            $json | Out-File -FilePath $this.LogFilePath -Encoding UTF8
            $this.LastSave = Get-Date
            return $true
        } catch {
            Write-Error "Erreur lors de la sauvegarde du journal des modifications: $_"
            return $false
        }
    }
    
    # Méthode pour vérifier si une sauvegarde est nécessaire
    [bool] CheckSaveNeeded() {
        $now = Get-Date
        $elapsed = ($now - $this.LastSave).TotalSeconds
        
        return $elapsed -ge $this.SaveInterval
    }
    
    # Méthode pour enregistrer une modification
    [ChangeEntry] TrackChange([string]$type, [string]$documentId, [string]$userId = "system", [string]$source = "system") {
        $timer = $this.Metrics.GetTimer("change_tracking.track_change")
        $timer.Start()
        
        $entry = [ChangeEntry]::new($type, $documentId, $userId, $source)
        $this.ChangeLog.AddEntry($entry)
        
        # Incrémenter le compteur approprié
        $counterName = "change_tracking.changes.$type"
        $this.Metrics.IncrementCounter($counterName)
        
        # Sauvegarder le journal si nécessaire
        if ($this.CheckSaveNeeded()) {
            $this.SaveChangeLog()
        }
        
        $timer.Stop()
        
        return $entry
    }
    
    # Méthode pour enregistrer un ajout de document
    [ChangeEntry] TrackAdd([string]$documentId, [string]$userId = "system", [string]$source = "system") {
        return $this.TrackChange("Add", $documentId, $userId, $source)
    }
    
    # Méthode pour enregistrer une mise à jour de document
    [ChangeEntry] TrackUpdate([string]$documentId, [string]$userId = "system", [string]$source = "system") {
        return $this.TrackChange("Update", $documentId, $userId, $source)
    }
    
    # Méthode pour enregistrer une suppression de document
    [ChangeEntry] TrackDelete([string]$documentId, [string]$userId = "system", [string]$source = "system") {
        return $this.TrackChange("Delete", $documentId, $userId, $source)
    }
    
    # Méthode pour obtenir les modifications depuis un horodatage
    [ChangeEntry[]] GetChangesSince([DateTime]$timestamp) {
        return $this.ChangeLog.GetEntriesSince($timestamp)
    }
    
    # Méthode pour obtenir les modifications pour un document
    [ChangeEntry[]] GetChangesForDocument([string]$documentId) {
        return $this.ChangeLog.GetEntriesForDocument($documentId)
    }
    
    # Méthode pour obtenir les modifications par type
    [ChangeEntry[]] GetChangesByType([string]$type) {
        return $this.ChangeLog.GetEntriesByType($type)
    }
    
    # Méthode pour nettoyer les modifications anciennes
    [int] CleanupOldChanges([int]$maxAgeInDays) {
        $timer = $this.Metrics.GetTimer("change_tracking.cleanup")
        $timer.Start()
        
        $count = $this.ChangeLog.CleanupOldEntries($maxAgeInDays)
        
        if ($count -gt 0) {
            $this.SaveChangeLog()
        }
        
        $timer.Stop()
        
        return $count
    }
    
    # Méthode pour obtenir les statistiques du suivi des modifications
    [hashtable] GetStats() {
        $stats = @{
            total_entries = $this.ChangeLog.Entries.Count
            add_entries = ($this.ChangeLog.GetEntriesByType("Add")).Count
            update_entries = ($this.ChangeLog.GetEntriesByType("Update")).Count
            delete_entries = ($this.ChangeLog.GetEntriesByType("Delete")).Count
            oldest_entry = if ($this.ChangeLog.Entries.Count -gt 0) { ($this.ChangeLog.Entries | Sort-Object -Property Timestamp | Select-Object -First 1).Timestamp } else { $null }
            newest_entry = if ($this.ChangeLog.Entries.Count -gt 0) { ($this.ChangeLog.Entries | Sort-Object -Property Timestamp -Descending | Select-Object -First 1).Timestamp } else { $null }
            metrics = $this.Metrics.GetAllMetrics()
        }
        
        return $stats
    }
}

# Fonction pour créer un gestionnaire de suivi des modifications
function New-ChangeTrackingManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = (Join-Path -Path $env:TEMP -ChildPath "change_log.json"),
        
        [Parameter(Mandatory = $false)]
        [int]$SaveInterval = 60
    )
    
    return [ChangeTrackingManager]::new($LogFilePath, $SaveInterval)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-ChangeTrackingManager
