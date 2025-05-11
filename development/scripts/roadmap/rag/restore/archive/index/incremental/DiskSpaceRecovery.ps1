# DiskSpaceRecovery.ps1
# Script implémentant la récupération d'espace disque pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$segmentCompactionPath = Join-Path -Path $scriptPath -ChildPath "SegmentCompaction.ps1"

if (Test-Path -Path $segmentCompactionPath) {
    . $segmentCompactionPath
} else {
    Write-Error "Le fichier SegmentCompaction.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une politique de récupération d'espace disque
class DiskSpacePolicy {
    # Seuil d'espace disque minimal (en octets)
    [long]$MinimumDiskSpace
    
    # Seuil d'espace disque critique (en octets)
    [long]$CriticalDiskSpace
    
    # Pourcentage d'espace disque à récupérer
    [double]$RecoveryPercentage
    
    # Constructeur par défaut
    DiskSpacePolicy() {
        $this.MinimumDiskSpace = 1GB      # 1 Go
        $this.CriticalDiskSpace = 500MB   # 500 Mo
        $this.RecoveryPercentage = 0.2    # 20%
    }
    
    # Constructeur avec seuils
    DiskSpacePolicy([long]$minimumDiskSpace, [long]$criticalDiskSpace, [double]$recoveryPercentage) {
        $this.MinimumDiskSpace = $minimumDiskSpace
        $this.CriticalDiskSpace = $criticalDiskSpace
        $this.RecoveryPercentage = $recoveryPercentage
    }
    
    # Méthode pour vérifier si une récupération d'espace disque est nécessaire
    [bool] ShouldRecoverDiskSpace([string]$drivePath) {
        # Obtenir les informations sur le disque
        $drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($drivePath).TrimEnd(':\')) -PSProvider FileSystem
        
        # Vérifier si l'espace disque est inférieur au seuil minimal
        return $drive.Free -lt $this.MinimumDiskSpace
    }
    
    # Méthode pour vérifier si l'espace disque est critique
    [bool] IsDiskSpaceCritical([string]$drivePath) {
        # Obtenir les informations sur le disque
        $drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($drivePath).TrimEnd(':\')) -PSProvider FileSystem
        
        # Vérifier si l'espace disque est inférieur au seuil critique
        return $drive.Free -lt $this.CriticalDiskSpace
    }
    
    # Méthode pour calculer l'espace disque à récupérer
    [long] CalculateSpaceToRecover([string]$drivePath) {
        # Obtenir les informations sur le disque
        $drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($drivePath).TrimEnd(':\')) -PSProvider FileSystem
        
        # Calculer l'espace à récupérer
        $spaceToRecover = [long]($drive.Used * $this.RecoveryPercentage)
        
        # Limiter l'espace à récupérer à la différence entre l'espace libre et le seuil minimal
        $maxSpaceToRecover = $this.MinimumDiskSpace - $drive.Free
        
        if ($maxSpaceToRecover -gt 0) {
            $spaceToRecover = [Math]::Min($spaceToRecover, $maxSpaceToRecover)
        }
        
        return $spaceToRecover
    }
}

# Classe pour représenter un planificateur de récupération d'espace disque
class DiskSpaceScheduler {
    # Intervalle de vérification (en secondes)
    [int]$CheckInterval
    
    # Dernière vérification
    [DateTime]$LastCheck
    
    # Constructeur par défaut
    DiskSpaceScheduler() {
        $this.CheckInterval = 3600  # 1 heure
        $this.LastCheck = [DateTime]::MinValue
    }
    
    # Constructeur avec intervalle
    DiskSpaceScheduler([int]$checkInterval) {
        $this.CheckInterval = $checkInterval
        $this.LastCheck = [DateTime]::MinValue
    }
    
    # Méthode pour vérifier si une vérification est nécessaire
    [bool] ShouldCheck() {
        $now = Get-Date
        $elapsed = ($now - $this.LastCheck).TotalSeconds
        
        return $elapsed -ge $this.CheckInterval -or $this.LastCheck -eq [DateTime]::MinValue
    }
    
    # Méthode pour mettre à jour la date de la dernière vérification
    [void] UpdateLastCheck() {
        $this.LastCheck = Get-Date
    }
}

# Classe pour représenter un gestionnaire de récupération d'espace disque
class DiskSpaceRecoveryManager {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Gestionnaire de compaction de segments
    [SegmentCompactionManager]$CompactionManager
    
    # Politique de récupération d'espace disque
    [DiskSpacePolicy]$Policy
    
    # Planificateur de récupération d'espace disque
    [DiskSpaceScheduler]$Scheduler
    
    # Chemin du fichier de journal de récupération d'espace disque
    [string]$RecoveryLogPath
    
    # Constructeur par défaut
    DiskSpaceRecoveryManager() {
        $this.SegmentManager = $null
        $this.CompactionManager = $null
        $this.Policy = [DiskSpacePolicy]::new()
        $this.Scheduler = [DiskSpaceScheduler]::new()
        $this.RecoveryLogPath = Join-Path -Path $env:TEMP -ChildPath "disk_space_recovery_log.json"
    }
    
    # Constructeur avec gestionnaires
    DiskSpaceRecoveryManager([IndexSegmentManager]$segmentManager, [SegmentCompactionManager]$compactionManager) {
        $this.SegmentManager = $segmentManager
        $this.CompactionManager = $compactionManager
        $this.Policy = [DiskSpacePolicy]::new()
        $this.Scheduler = [DiskSpaceScheduler]::new()
        $this.RecoveryLogPath = Join-Path -Path $env:TEMP -ChildPath "disk_space_recovery_log.json"
    }
    
    # Constructeur complet
    DiskSpaceRecoveryManager([IndexSegmentManager]$segmentManager, [SegmentCompactionManager]$compactionManager, [DiskSpacePolicy]$policy, [DiskSpaceScheduler]$scheduler, [string]$recoveryLogPath) {
        $this.SegmentManager = $segmentManager
        $this.CompactionManager = $compactionManager
        $this.Policy = $policy
        $this.Scheduler = $scheduler
        $this.RecoveryLogPath = $recoveryLogPath
    }
    
    # Méthode pour vérifier l'espace disque
    [hashtable] CheckDiskSpace() {
        $result = @{
            drive_path = $this.SegmentManager.FileManager.RootDirectory
            free_space = 0
            total_space = 0
            used_space = 0
            is_critical = $false
            needs_recovery = $false
            space_to_recover = 0
            timestamp = Get-Date
        }
        
        # Obtenir les informations sur le disque
        $drivePath = [System.IO.Path]::GetPathRoot($this.SegmentManager.FileManager.RootDirectory)
        $drive = Get-PSDrive -Name ($drivePath.TrimEnd(':\')) -PSProvider FileSystem
        
        $result.free_space = $drive.Free
        $result.total_space = $drive.Used + $drive.Free
        $result.used_space = $drive.Used
        
        # Vérifier si l'espace disque est critique
        $result.is_critical = $this.Policy.IsDiskSpaceCritical($drivePath)
        
        # Vérifier si une récupération d'espace disque est nécessaire
        $result.needs_recovery = $this.Policy.ShouldRecoverDiskSpace($drivePath)
        
        # Calculer l'espace disque à récupérer
        if ($result.needs_recovery) {
            $result.space_to_recover = $this.Policy.CalculateSpaceToRecover($drivePath)
        }
        
        return $result
    }
    
    # Méthode pour exécuter la récupération d'espace disque
    [hashtable] RunRecovery() {
        $result = @{
            recovered_space = 0
            compacted_segments = 0
            deleted_files = 0
            errors = [System.Collections.Generic.List[string]]::new()
            timestamp = Get-Date
        }
        
        # Vérifier si une vérification est nécessaire
        if (-not $this.Scheduler.ShouldCheck()) {
            return $result
        }
        
        # Vérifier l'espace disque
        $diskSpaceCheck = $this.CheckDiskSpace()
        
        # Mettre à jour la date de la dernière vérification
        $this.Scheduler.UpdateLastCheck()
        
        # Vérifier si une récupération d'espace disque est nécessaire
        if (-not $diskSpaceCheck.needs_recovery) {
            return $result
        }
        
        # Récupérer l'espace disque
        $spaceToRecover = $diskSpaceCheck.space_to_recover
        $recoveredSpace = 0
        
        # Compacter les segments
        if ($null -ne $this.CompactionManager) {
            $compactionResult = $this.CompactionManager.RunCompaction()
            $result.compacted_segments = $compactionResult.compacted_segments
            
            # Ajouter les erreurs
            foreach ($error in $compactionResult.errors) {
                $result.errors.Add($error)
            }
        }
        
        # Supprimer les fichiers temporaires
        $tempFiles = $this.FindTemporaryFiles()
        
        foreach ($file in $tempFiles) {
            try {
                $fileSize = (Get-Item -Path $file).Length
                Remove-Item -Path $file -Force
                $recoveredSpace += $fileSize
                $result.deleted_files++
                
                # Vérifier si suffisamment d'espace a été récupéré
                if ($recoveredSpace -ge $spaceToRecover) {
                    break
                }
            } catch {
                $result.errors.Add("Erreur lors de la suppression du fichier $file: $_")
            }
        }
        
        $result.recovered_space = $recoveredSpace
        
        # Enregistrer le résultat de la récupération d'espace disque
        $this.LogRecoveryResult($result)
        
        return $result
    }
    
    # Méthode pour trouver les fichiers temporaires
    [string[]] FindTemporaryFiles() {
        $tempFiles = [System.Collections.Generic.List[string]]::new()
        
        # Trouver les fichiers de journalisation anciens
        $logFiles = Get-ChildItem -Path $this.SegmentManager.FileManager.RootDirectory -Filter "*.log" -Recurse |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
            Sort-Object -Property LastWriteTime
        
        foreach ($file in $logFiles) {
            $tempFiles.Add($file.FullName)
        }
        
        # Trouver les fichiers temporaires
        $tempFilePatterns = @("*.tmp", "*.temp", "*.bak")
        
        foreach ($pattern in $tempFilePatterns) {
            $files = Get-ChildItem -Path $this.SegmentManager.FileManager.RootDirectory -Filter $pattern -Recurse |
                Sort-Object -Property LastWriteTime
            
            foreach ($file in $files) {
                $tempFiles.Add($file.FullName)
            }
        }
        
        return $tempFiles.ToArray()
    }
    
    # Méthode pour enregistrer le résultat de la récupération d'espace disque
    [void] LogRecoveryResult([hashtable]$result) {
        try {
            # Charger les résultats précédents
            $logs = @()
            
            if (Test-Path -Path $this.RecoveryLogPath) {
                $logs = Get-Content -Path $this.RecoveryLogPath -Raw | ConvertFrom-Json
            }
            
            # Ajouter le nouveau résultat
            $logs += $result
            
            # Limiter le nombre de résultats
            if ($logs.Count -gt 100) {
                $logs = $logs | Select-Object -Last 100
            }
            
            # Sauvegarder les résultats
            $logs | ConvertTo-Json -Depth 10 | Out-File -FilePath $this.RecoveryLogPath -Encoding UTF8
        } catch {
            Write-Error "Erreur lors de l'enregistrement du résultat de la récupération d'espace disque: $_"
        }
    }
    
    # Méthode pour démarrer la vérification périodique de l'espace disque
    [void] StartPeriodicCheck() {
        # Créer un timer
        $timer = New-Object System.Timers.Timer
        $timer.Interval = 3600 * 1000  # 1 heure
        $timer.AutoReset = $true
        
        # Configurer l'événement
        $action = {
            param($manager)
            
            if ($manager.Scheduler.ShouldCheck()) {
                $diskSpaceCheck = $manager.CheckDiskSpace()
                
                if ($diskSpaceCheck.needs_recovery) {
                    $manager.RunRecovery()
                }
                
                $manager.Scheduler.UpdateLastCheck()
            }
        }
        
        $timer.Elapsed.Add({
            & $action $this
        }.GetNewClosure())
        
        # Démarrer le timer
        $timer.Start()
    }
    
    # Méthode pour obtenir les statistiques de récupération d'espace disque
    [hashtable] GetRecoveryStats() {
        $stats = @{
            last_check = $this.Scheduler.LastCheck
            next_check = $this.Scheduler.LastCheck.AddSeconds($this.Scheduler.CheckInterval)
            minimum_disk_space = $this.Policy.MinimumDiskSpace
            critical_disk_space = $this.Policy.CriticalDiskSpace
            recovery_percentage = $this.Policy.RecoveryPercentage
            check_interval_seconds = $this.Scheduler.CheckInterval
            recovery_log_path = $this.RecoveryLogPath
        }
        
        # Ajouter les statistiques du disque
        $diskSpaceCheck = $this.CheckDiskSpace()
        $stats.free_space = $diskSpaceCheck.free_space
        $stats.total_space = $diskSpaceCheck.total_space
        $stats.used_space = $diskSpaceCheck.used_space
        $stats.is_critical = $diskSpaceCheck.is_critical
        $stats.needs_recovery = $diskSpaceCheck.needs_recovery
        $stats.space_to_recover = $diskSpaceCheck.space_to_recover
        
        return $stats
    }
}

# Fonction pour créer une politique de récupération d'espace disque
function New-DiskSpacePolicy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [long]$MinimumDiskSpace = 1GB,
        
        [Parameter(Mandatory = $false)]
        [long]$CriticalDiskSpace = 500MB,
        
        [Parameter(Mandatory = $false)]
        [double]$RecoveryPercentage = 0.2
    )
    
    return [DiskSpacePolicy]::new($MinimumDiskSpace, $CriticalDiskSpace, $RecoveryPercentage)
}

# Fonction pour créer un planificateur de récupération d'espace disque
function New-DiskSpaceScheduler {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$CheckInterval = 3600  # 1 heure
    )
    
    return [DiskSpaceScheduler]::new($CheckInterval)
}

# Fonction pour créer un gestionnaire de récupération d'espace disque
function New-DiskSpaceRecoveryManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $false)]
        [SegmentCompactionManager]$CompactionManager = $null,
        
        [Parameter(Mandatory = $false)]
        [DiskSpacePolicy]$Policy = (New-DiskSpacePolicy),
        
        [Parameter(Mandatory = $false)]
        [DiskSpaceScheduler]$Scheduler = (New-DiskSpaceScheduler),
        
        [Parameter(Mandatory = $false)]
        [string]$RecoveryLogPath = (Join-Path -Path $env:TEMP -ChildPath "disk_space_recovery_log.json")
    )
    
    return [DiskSpaceRecoveryManager]::new($SegmentManager, $CompactionManager, $Policy, $Scheduler, $RecoveryLogPath)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-DiskSpacePolicy, New-DiskSpaceScheduler, New-DiskSpaceRecoveryManager
