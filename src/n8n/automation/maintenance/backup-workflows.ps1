<#
.SYNOPSIS
    Script de sauvegarde des workflows n8n.

.DESCRIPTION
    Ce script effectue la sauvegarde des workflows n8n en créant une archive ZIP
    contenant tous les fichiers de workflow.

.PARAMETER WorkflowFolder
    Dossier contenant les workflows n8n (par défaut: n8n/data/.n8n/workflows).

.PARAMETER BackupFolder
    Dossier où stocker les sauvegardes (par défaut: n8n/backups).

.PARAMETER MaxBackupCount
    Nombre maximal de sauvegardes à conserver (par défaut: 30).

.PARAMETER IncludeTimestamp
    Indique s'il faut inclure un horodatage dans le nom du fichier de sauvegarde (par défaut: $true).

.PARAMETER NoInteractive
    Exécute le script en mode non interactif (sans demander de confirmation).

.EXAMPLE
    .\backup-workflows.ps1
    Effectue la sauvegarde des workflows avec les paramètres par défaut.

.EXAMPLE
    .\backup-workflows.ps1 -WorkflowFolder "C:\n8n\workflows" -BackupFolder "C:\backups" -MaxBackupCount 10
    Effectue la sauvegarde des workflows dans le dossier spécifié avec un nombre maximal de 10 sauvegardes.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  27/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$WorkflowFolder = "n8n/data/.n8n/workflows",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupFolder = "n8n/backups",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxBackupCount = 30,
    
    [Parameter(Mandatory=$false)]
    [bool]$IncludeTimestamp = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$NoInteractive
)

# Fonction pour écrire dans le log
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec la couleur appropriée
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    # Écrire dans le fichier de log de maintenance
    $logFolder = Split-Path -Path $BackupFolder -Parent
    $logFolder = Join-Path -Path $logFolder -ChildPath "logs"
    $maintenanceLogFile = Join-Path -Path $logFolder -ChildPath "maintenance.log"
    
    # Créer le dossier de log s'il n'existe pas
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $maintenanceLogFile -Value $logMessage
}

# Fonction pour vérifier si un dossier existe et le créer si nécessaire
function Ensure-FolderExists {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath
    )
    
    if (-not (Test-Path -Path $FolderPath)) {
        try {
            New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
            Write-Log "Dossier créé: $FolderPath" -Level "SUCCESS"
            return $true
        } catch {
            Write-Log "Erreur lors de la création du dossier $FolderPath : $_" -Level "ERROR"
            return $false
        }
    }
    
    return $true
}

# Fonction pour nettoyer les anciennes sauvegardes
function Clean-OldBackups {
    param (
        [Parameter(Mandatory=$true)]
        [string]$BackupFolder,
        
        [Parameter(Mandatory=$true)]
        [int]$MaxBackupCount
    )
    
    try {
        # Obtenir toutes les sauvegardes
        $backups = Get-ChildItem -Path $BackupFolder -Filter "workflows*.zip" | Sort-Object -Property LastWriteTime -Descending
        
        # Supprimer les sauvegardes excédentaires
        if ($backups.Count -gt $MaxBackupCount) {
            $backupsToDelete = $backups | Select-Object -Skip $MaxBackupCount
            
            foreach ($backup in $backupsToDelete) {
                Remove-Item -Path $backup.FullName -Force
                Write-Log "Sauvegarde supprimée: $($backup.Name)" -Level "INFO"
            }
            
            Write-Log "$($backupsToDelete.Count) anciennes sauvegardes supprimées" -Level "SUCCESS"
        } else {
            Write-Log "Aucune sauvegarde à supprimer (total: $($backups.Count), max: $MaxBackupCount)" -Level "INFO"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors du nettoyage des anciennes sauvegardes: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale pour effectuer la sauvegarde des workflows
function Backup-Workflows {
    param (
        [Parameter(Mandatory=$true)]
        [string]$WorkflowFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$BackupFolder,
        
        [Parameter(Mandatory=$true)]
        [int]$MaxBackupCount,
        
        [Parameter(Mandatory=$true)]
        [bool]$IncludeTimestamp
    )
    
    # Vérifier si les dossiers existent
    $workflowFolderExists = Test-Path -Path $WorkflowFolder
    $backupFolderExists = Ensure-FolderExists -FolderPath $BackupFolder
    
    if (-not $workflowFolderExists) {
        Write-Log "Dossier de workflows non trouvé: $WorkflowFolder" -Level "ERROR"
        return $false
    }
    
    if (-not $backupFolderExists) {
        Write-Log "Impossible de continuer sans le dossier de sauvegarde" -Level "ERROR"
        return $false
    }
    
    # Obtenir tous les fichiers de workflow
    $workflowFiles = Get-ChildItem -Path $WorkflowFolder -Filter "*.json" -File
    
    if ($workflowFiles.Count -eq 0) {
        Write-Log "Aucun fichier de workflow trouvé dans $WorkflowFolder" -Level "WARNING"
        return $true
    }
    
    Write-Log "Début de la sauvegarde des workflows ($($workflowFiles.Count) fichiers)" -Level "INFO"
    
    try {
        # Créer le nom du fichier de sauvegarde
        $backupFileName = if ($IncludeTimestamp) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            "workflows_$timestamp.zip"
        } else {
            "workflows.zip"
        }
        
        $backupFilePath = Join-Path -Path $BackupFolder -ChildPath $backupFileName
        
        # Créer une archive ZIP
        Compress-Archive -Path "$WorkflowFolder\*" -DestinationPath $backupFilePath -Force
        
        Write-Log "Sauvegarde créée: $backupFileName ($($workflowFiles.Count) fichiers)" -Level "SUCCESS"
        
        # Nettoyer les anciennes sauvegardes
        Clean-OldBackups -BackupFolder $BackupFolder -MaxBackupCount $MaxBackupCount
        
        return $true
    } catch {
        Write-Log "Erreur lors de la sauvegarde des workflows: $_" -Level "ERROR"
        return $false
    }
}

# Exécuter la fonction principale
if ($MyInvocation.InvocationName -ne ".") {
    # Afficher les paramètres
    Write-Log "Paramètres:" -Level "INFO"
    Write-Log "  WorkflowFolder: $WorkflowFolder" -Level "INFO"
    Write-Log "  BackupFolder: $BackupFolder" -Level "INFO"
    Write-Log "  MaxBackupCount: $MaxBackupCount" -Level "INFO"
    Write-Log "  IncludeTimestamp: $IncludeTimestamp" -Level "INFO"
    
    # Demander confirmation si mode interactif
    if (-not $NoInteractive) {
        $confirmation = Read-Host "Voulez-vous continuer? (O/N)"
        
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Opération annulée par l'utilisateur" -Level "WARNING"
            exit
        }
    }
    
    # Effectuer la sauvegarde des workflows
    $success = Backup-Workflows -WorkflowFolder $WorkflowFolder -BackupFolder $BackupFolder -MaxBackupCount $MaxBackupCount -IncludeTimestamp $IncludeTimestamp
    
    if ($success) {
        exit 0
    } else {
        exit 1
    }
}
