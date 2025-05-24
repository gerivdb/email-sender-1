<#
.SYNOPSIS
    Script de rotation des logs n8n.

.DESCRIPTION
    Ce script effectue la rotation des logs n8n en archivant les anciens logs
    et en créant de nouveaux fichiers de log vides.

.PARAMETER LogFolder
    Dossier contenant les logs n8n (par défaut: n8n/logs).

.PARAMETER HistoryFolder
    Dossier où stocker les logs archivés (par défaut: n8n/logs/history).

.PARAMETER MaxLogSizeMB
    Taille maximale des fichiers de log en MB avant rotation (par défaut: 10).

.PARAMETER MaxLogAgeDays
    Âge maximal des fichiers de log en jours avant rotation (par défaut: 7).

.PARAMETER MaxHistoryCount
    Nombre maximal d'archives de logs à conserver (par défaut: 30).

.PARAMETER NoInteractive
    Exécute le script en mode non interactif (sans demander de confirmation).

.EXAMPLE
    .\Move-Logs.ps1
    Effectue la rotation des logs avec les paramètres par défaut.

.EXAMPLE
    .\Move-Logs.ps1 -LogFolder "C:\n8n\logs" -MaxLogSizeMB 20 -MaxLogAgeDays 14
    Effectue la rotation des logs dans le dossier spécifié avec une taille maximale de 20 MB et un âge maximal de 14 jours.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  27/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$LogFolder = "n8n/logs",
    
    [Parameter(Mandatory=$false)]
    [string]$HistoryFolder = "n8n/logs/history",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxLogSizeMB = 10,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxLogAgeDays = 7,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxHistoryCount = 30,
    
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
    $maintenanceLogFile = Join-Path -Path $LogFolder -ChildPath "maintenance.log"
    Add-Content -Path $maintenanceLogFile -Value $logMessage
}

# Fonction pour vérifier si un dossier existe et le créer si nécessaire
function Confirm-FolderExists {
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

# Fonction pour archiver un fichier de log
function Compress-LogFile {
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$LogFile,
        
        [Parameter(Mandatory=$true)]
        [string]$HistoryFolder
    )
    
    try {
        # Créer le nom du fichier d'archive
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $archiveFileName = "$($LogFile.BaseName)_$timestamp$($LogFile.Extension).zip"
        $archiveFilePath = Join-Path -Path $HistoryFolder -ChildPath $archiveFileName
        
        # Créer une archive ZIP
        Compress-Archive -Path $LogFile.FullName -DestinationPath $archiveFilePath -Force
        
        # Vider le fichier de log
        Set-Content -Path $LogFile.FullName -Value "" -Force
        
        Write-Log "Fichier de log archivé: $($LogFile.Name) -> $archiveFileName" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors de l'archivage du fichier de log $($LogFile.Name): $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour nettoyer les anciennes archives
function Clear-OldArchives {
    param (
        [Parameter(Mandatory=$true)]
        [string]$HistoryFolder,
        
        [Parameter(Mandatory=$true)]
        [int]$MaxHistoryCount
    )
    
    try {
        # Obtenir toutes les archives
        $archives = Get-ChildItem -Path $HistoryFolder -Filter "*.zip" | Sort-Object -Property LastWriteTime -Descending
        
        # Supprimer les archives excédentaires
        if ($archives.Count -gt $MaxHistoryCount) {
            $archivesToDelete = $archives | Select-Object -Skip $MaxHistoryCount
            
            foreach ($archive in $archivesToDelete) {
                Remove-Item -Path $archive.FullName -Force
                Write-Log "Archive supprimée: $($archive.Name)" -Level "INFO"
            }
            
            Write-Log "$($archivesToDelete.Count) anciennes archives supprimées" -Level "SUCCESS"
        } else {
            Write-Log "Aucune archive à supprimer (total: $($archives.Count), max: $MaxHistoryCount)" -Level "INFO"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors du nettoyage des anciennes archives: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale pour effectuer la rotation des logs
function Move-Logs {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$HistoryFolder,
        
        [Parameter(Mandatory=$true)]
        [int]$MaxLogSizeMB,
        
        [Parameter(Mandatory=$true)]
        [int]$MaxLogAgeDays,
        
        [Parameter(Mandatory=$true)]
        [int]$MaxHistoryCount
    )
    
    # Vérifier si les dossiers existent
    $logFolderExists = Confirm-FolderExists -FolderPath $LogFolder
    $historyFolderExists = Confirm-FolderExists -FolderPath $HistoryFolder
    
    if (-not $logFolderExists -or -not $historyFolderExists) {
        Write-Log "Impossible de continuer sans les dossiers requis" -Level "ERROR"
        return $false
    }
    
    # Obtenir tous les fichiers de log
    $logFiles = Get-ChildItem -Path $LogFolder -Filter "*.log" -File
    
    if ($logFiles.Count -eq 0) {
        Write-Log "Aucun fichier de log trouvé dans $LogFolder" -Level "WARNING"
        return $true
    }
    
    Write-Log "Début de la rotation des logs ($($logFiles.Count) fichiers)" -Level "INFO"
    
    # Convertir la taille maximale en octets
    $maxLogSizeBytes = $MaxLogSizeMB * 1MB
    
    # Calculer la date limite
    $limitDate = (Get-Date).AddDays(-$MaxLogAgeDays)
    
    $rotatedCount = 0
    
    # Traiter chaque fichier de log
    foreach ($logFile in $logFiles) {
        $needsRotation = $false
        $rotationReason = ""
        
        # Vérifier la taille du fichier
        if ($logFile.Length -gt $maxLogSizeBytes) {
            $needsRotation = $true
            $rotationReason = "taille ($([Math]::Round($logFile.Length / 1MB, 2)) MB > $MaxLogSizeMB MB)"
        }
        
        # Vérifier l'âge du fichier
        if ($logFile.LastWriteTime -lt $limitDate) {
            $needsRotation = $true
            $rotationReason = "âge ($([Math]::Round(((Get-Date) - $logFile.LastWriteTime).TotalDays, 2)) jours > $MaxLogAgeDays jours)"
        }
        
        # Effectuer la rotation si nécessaire
        if ($needsRotation) {
            Write-Log "Rotation du fichier $($logFile.Name) en raison de $rotationReason" -Level "INFO"
            
            $success = Compress-LogFile -LogFile $logFile -HistoryFolder $HistoryFolder
            
            if ($success) {
                $rotatedCount++
            }
        } else {
            Write-Log "Le fichier $($logFile.Name) ne nécessite pas de rotation" -Level "INFO"
        }
    }
    
    # Nettoyer les anciennes archives
    Clear-OldArchives -HistoryFolder $HistoryFolder -MaxHistoryCount $MaxHistoryCount
    
    Write-Log "Fin de la rotation des logs ($rotatedCount fichiers rotés)" -Level "SUCCESS"
    
    return $true
}

# Exécuter la fonction principale
if ($MyInvocation.InvocationName -ne ".") {
    # Afficher les paramètres
    Write-Log "Paramètres:" -Level "INFO"
    Write-Log "  LogFolder: $LogFolder" -Level "INFO"
    Write-Log "  HistoryFolder: $HistoryFolder" -Level "INFO"
    Write-Log "  MaxLogSizeMB: $MaxLogSizeMB" -Level "INFO"
    Write-Log "  MaxLogAgeDays: $MaxLogAgeDays" -Level "INFO"
    Write-Log "  MaxHistoryCount: $MaxHistoryCount" -Level "INFO"
    
    # Demander confirmation si mode interactif
    if (-not $NoInteractive) {
        $confirmation = Read-Host "Voulez-vous continuer? (O/N)"
        
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Opération annulée par l'utilisateur" -Level "WARNING"
            exit
        }
    }
    
    # Effectuer la rotation des logs
    $success = Move-Logs -LogFolder $LogFolder -HistoryFolder $HistoryFolder -MaxLogSizeMB $MaxLogSizeMB -MaxLogAgeDays $MaxLogAgeDays -MaxHistoryCount $MaxHistoryCount
    
    if ($success) {
        exit 0
    } else {
        exit 1
    }
}


