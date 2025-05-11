# DeferredCleanup.ps1
# Script implémentant le nettoyage différé des documents supprimés pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$deletionMarkerPath = Join-Path -Path $scriptPath -ChildPath "DeletionMarker.ps1"

if (Test-Path -Path $deletionMarkerPath) {
    . $deletionMarkerPath
} else {
    Write-Error "Le fichier DeletionMarker.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une politique de nettoyage
class CleanupPolicy {
    # Délai de rétention pour les documents supprimés temporairement (en jours)
    [int]$TemporaryRetentionDays
    
    # Délai de rétention pour les documents supprimés définitivement (en jours)
    [int]$PermanentRetentionDays
    
    # Taille maximale du lot de nettoyage
    [int]$BatchSize
    
    # Constructeur par défaut
    CleanupPolicy() {
        $this.TemporaryRetentionDays = 30  # 30 jours
        $this.PermanentRetentionDays = 7   # 7 jours
        $this.BatchSize = 100
    }
    
    # Constructeur avec délais de rétention
    CleanupPolicy([int]$temporaryRetentionDays, [int]$permanentRetentionDays) {
        $this.TemporaryRetentionDays = $temporaryRetentionDays
        $this.PermanentRetentionDays = $permanentRetentionDays
        $this.BatchSize = 100
    }
    
    # Constructeur complet
    CleanupPolicy([int]$temporaryRetentionDays, [int]$permanentRetentionDays, [int]$batchSize) {
        $this.TemporaryRetentionDays = $temporaryRetentionDays
        $this.PermanentRetentionDays = $permanentRetentionDays
        $this.BatchSize = $batchSize
    }
    
    # Méthode pour vérifier si un document temporairement supprimé doit être nettoyé
    [bool] ShouldCleanupTemporary([DateTime]$deletedAt) {
        $cutoffDate = (Get-Date).AddDays(-$this.TemporaryRetentionDays)
        return $deletedAt -lt $cutoffDate
    }
    
    # Méthode pour vérifier si un document définitivement supprimé doit être nettoyé
    [bool] ShouldCleanupPermanent([DateTime]$deletedAt) {
        $cutoffDate = (Get-Date).AddDays(-$this.PermanentRetentionDays)
        return $deletedAt -lt $cutoffDate
    }
}

# Classe pour représenter un planificateur de nettoyage
class CleanupScheduler {
    # Intervalle de nettoyage (en secondes)
    [int]$CleanupInterval
    
    # Dernier nettoyage
    [DateTime]$LastCleanup
    
    # Constructeur par défaut
    CleanupScheduler() {
        $this.CleanupInterval = 86400  # 24 heures
        $this.LastCleanup = [DateTime]::MinValue
    }
    
    # Constructeur avec intervalle
    CleanupScheduler([int]$cleanupInterval) {
        $this.CleanupInterval = $cleanupInterval
        $this.LastCleanup = [DateTime]::MinValue
    }
    
    # Méthode pour vérifier si un nettoyage est nécessaire
    [bool] ShouldCleanup() {
        $now = Get-Date
        $elapsed = ($now - $this.LastCleanup).TotalSeconds
        
        return $elapsed -ge $this.CleanupInterval -or $this.LastCleanup -eq [DateTime]::MinValue
    }
    
    # Méthode pour mettre à jour la date du dernier nettoyage
    [void] UpdateLastCleanup() {
        $this.LastCleanup = Get-Date
    }
}

# Classe pour représenter un gestionnaire de nettoyage différé
class DeferredCleanupManager {
    # Gestionnaire de suppressions
    [DeletionManager]$DeletionManager
    
    # Politique de nettoyage
    [CleanupPolicy]$Policy
    
    # Planificateur de nettoyage
    [CleanupScheduler]$Scheduler
    
    # Chemin du fichier de journal de nettoyage
    [string]$CleanupLogPath
    
    # Constructeur par défaut
    DeferredCleanupManager() {
        $this.DeletionManager = $null
        $this.Policy = [CleanupPolicy]::new()
        $this.Scheduler = [CleanupScheduler]::new()
        $this.CleanupLogPath = Join-Path -Path $env:TEMP -ChildPath "cleanup_log.json"
    }
    
    # Constructeur avec gestionnaire de suppressions
    DeferredCleanupManager([DeletionManager]$deletionManager) {
        $this.DeletionManager = $deletionManager
        $this.Policy = [CleanupPolicy]::new()
        $this.Scheduler = [CleanupScheduler]::new()
        $this.CleanupLogPath = Join-Path -Path $env:TEMP -ChildPath "cleanup_log.json"
    }
    
    # Constructeur complet
    DeferredCleanupManager([DeletionManager]$deletionManager, [CleanupPolicy]$policy, [CleanupScheduler]$scheduler, [string]$cleanupLogPath) {
        $this.DeletionManager = $deletionManager
        $this.Policy = $policy
        $this.Scheduler = $scheduler
        $this.CleanupLogPath = $cleanupLogPath
    }
    
    # Méthode pour exécuter le nettoyage
    [hashtable] RunCleanup() {
        $result = @{
            cleaned_temporary = 0
            cleaned_permanent = 0
            converted_to_permanent = 0
            errors = [System.Collections.Generic.List[string]]::new()
            timestamp = Get-Date
        }
        
        # Vérifier si un nettoyage est nécessaire
        if (-not $this.Scheduler.ShouldCleanup()) {
            return $result
        }
        
        # Récupérer les documents supprimés
        $deletedDocuments = $this.DeletionManager.GetDeletedDocuments()
        
        # Traiter les documents temporairement supprimés
        $temporaryMarkers = $this.DeletionManager.Registry.GetTemporaryMarkers()
        
        foreach ($marker in $temporaryMarkers) {
            try {
                # Vérifier si le document doit être converti en suppression permanente
                if ($this.Policy.ShouldCleanupTemporary($marker.DeletedAt)) {
                    # Convertir en suppression permanente
                    $this.DeletionManager.PermanentlyDeleteDocument($marker.DocumentId, "system", "Conversion automatique après expiration du délai de rétention temporaire")
                    $result.converted_to_permanent++
                }
            } catch {
                $result.errors.Add("Erreur lors du traitement du document temporairement supprimé $($marker.DocumentId): $_")
            }
        }
        
        # Traiter les documents définitivement supprimés
        $permanentMarkers = $this.DeletionManager.Registry.GetPermanentMarkers()
        
        foreach ($marker in $permanentMarkers) {
            try {
                # Vérifier si le document doit être nettoyé
                if ($this.Policy.ShouldCleanupPermanent($marker.DeletedAt)) {
                    # Supprimer le document de l'index
                    $this.DeletionManager.SegmentManager.RemoveDocument($marker.DocumentId)
                    
                    # Supprimer le marqueur de suppression
                    $this.DeletionManager.Registry.RemoveMarker($marker.DocumentId)
                    
                    $result.cleaned_permanent++
                }
            } catch {
                $result.errors.Add("Erreur lors du nettoyage du document définitivement supprimé $($marker.DocumentId): $_")
            }
        }
        
        # Mettre à jour la date du dernier nettoyage
        $this.Scheduler.UpdateLastCleanup()
        
        # Enregistrer le résultat du nettoyage
        $this.LogCleanupResult($result)
        
        return $result
    }
    
    # Méthode pour enregistrer le résultat du nettoyage
    [void] LogCleanupResult([hashtable]$result) {
        try {
            # Charger les résultats précédents
            $logs = @()
            
            if (Test-Path -Path $this.CleanupLogPath) {
                $logs = Get-Content -Path $this.CleanupLogPath -Raw | ConvertFrom-Json
            }
            
            # Ajouter le nouveau résultat
            $logs += $result
            
            # Limiter le nombre de résultats
            if ($logs.Count -gt 100) {
                $logs = $logs | Select-Object -Last 100
            }
            
            # Sauvegarder les résultats
            $logs | ConvertTo-Json -Depth 10 | Out-File -FilePath $this.CleanupLogPath -Encoding UTF8
        } catch {
            Write-Error "Erreur lors de l'enregistrement du résultat du nettoyage: $_"
        }
    }
    
    # Méthode pour démarrer le nettoyage périodique
    [void] StartPeriodicCleanup() {
        # Créer un timer
        $timer = New-Object System.Timers.Timer
        $timer.Interval = 3600 * 1000  # 1 heure
        $timer.AutoReset = $true
        
        # Configurer l'événement
        $action = {
            param($manager)
            
            if ($manager.Scheduler.ShouldCleanup()) {
                $manager.RunCleanup()
            }
        }
        
        $timer.Elapsed.Add({
            & $action $this
        }.GetNewClosure())
        
        # Démarrer le timer
        $timer.Start()
    }
    
    # Méthode pour obtenir les statistiques de nettoyage
    [hashtable] GetCleanupStats() {
        $stats = @{
            last_cleanup = $this.Scheduler.LastCleanup
            next_cleanup = $this.Scheduler.LastCleanup.AddSeconds($this.Scheduler.CleanupInterval)
            temporary_retention_days = $this.Policy.TemporaryRetentionDays
            permanent_retention_days = $this.Policy.PermanentRetentionDays
            batch_size = $this.Policy.BatchSize
            cleanup_interval_seconds = $this.Scheduler.CleanupInterval
            cleanup_log_path = $this.CleanupLogPath
        }
        
        # Ajouter les statistiques des documents supprimés
        $deletedDocuments = $this.DeletionManager.GetDeletedDocuments()
        $stats.total_deleted = $deletedDocuments.total
        $stats.permanent_deleted = $deletedDocuments.permanent
        $stats.temporary_deleted = $deletedDocuments.temporary
        
        # Calculer les documents à nettoyer
        $temporaryToCleanup = 0
        $permanentToCleanup = 0
        
        foreach ($marker in $this.DeletionManager.Registry.GetTemporaryMarkers()) {
            if ($this.Policy.ShouldCleanupTemporary($marker.DeletedAt)) {
                $temporaryToCleanup++
            }
        }
        
        foreach ($marker in $this.DeletionManager.Registry.GetPermanentMarkers()) {
            if ($this.Policy.ShouldCleanupPermanent($marker.DeletedAt)) {
                $permanentToCleanup++
            }
        }
        
        $stats.temporary_to_cleanup = $temporaryToCleanup
        $stats.permanent_to_cleanup = $permanentToCleanup
        
        return $stats
    }
}

# Fonction pour créer une politique de nettoyage
function New-CleanupPolicy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$TemporaryRetentionDays = 30,
        
        [Parameter(Mandatory = $false)]
        [int]$PermanentRetentionDays = 7,
        
        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 100
    )
    
    return [CleanupPolicy]::new($TemporaryRetentionDays, $PermanentRetentionDays, $BatchSize)
}

# Fonction pour créer un planificateur de nettoyage
function New-CleanupScheduler {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$CleanupInterval = 86400  # 24 heures
    )
    
    return [CleanupScheduler]::new($CleanupInterval)
}

# Fonction pour créer un gestionnaire de nettoyage différé
function New-DeferredCleanupManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DeletionManager]$DeletionManager,
        
        [Parameter(Mandatory = $false)]
        [CleanupPolicy]$Policy = (New-CleanupPolicy),
        
        [Parameter(Mandatory = $false)]
        [CleanupScheduler]$Scheduler = (New-CleanupScheduler),
        
        [Parameter(Mandatory = $false)]
        [string]$CleanupLogPath = (Join-Path -Path $env:TEMP -ChildPath "cleanup_log.json")
    )
    
    return [DeferredCleanupManager]::new($DeletionManager, $Policy, $Scheduler, $CleanupLogPath)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-CleanupPolicy, New-CleanupScheduler, New-DeferredCleanupManager
