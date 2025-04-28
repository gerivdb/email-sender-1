#Requires -Version 5.1
<#
.SYNOPSIS
    Restaure une version précédente des composants MCP.
.DESCRIPTION
    Ce script restaure une version précédente des composants MCP à partir d'une sauvegarde.
.PARAMETER BackupDate
    Date de la sauvegarde à restaurer au format 'yyyyMMdd'. Si non spécifiée, la dernière sauvegarde sera utilisée.
.PARAMETER Version
    Version à restaurer. Si non spécifiée, la dernière version de la date spécifiée sera utilisée.
.PARAMETER Force
    Force la restauration sans demander de confirmation.
.EXAMPLE
    .\rollback-mcp-update.ps1 -BackupDate 20250501
    Restaure la dernière sauvegarde du 1er mai 2025.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$BackupDate,
    
    [Parameter(Mandatory = $false)]
    [string]$Version,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$versioningRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $versioningRoot).Parent.FullName
$projectRoot = (Get-Item $mcpRoot).Parent.FullName
$backupsDir = Join-Path -Path $versioningRoot -ChildPath "backups"
$versionHistoryPath = Join-Path -Path $versioningRoot -ChildPath "changelog\version-history.json"

# Fonctions d'aide
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "TITLE" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-LatestBackup {
    $backups = Get-ChildItem -Path $backupsDir -Directory | Sort-Object Name -Descending
    
    if ($backups.Count -eq 0) {
        return $null
    }
    
    return $backups[0]
}

function Get-BackupByDate {
    param (
        [string]$Date
    )
    
    $backups = Get-ChildItem -Path $backupsDir -Directory | Where-Object { $_.Name -like "$Date*" } | Sort-Object Name -Descending
    
    if ($backups.Count -eq 0) {
        return $null
    }
    
    return $backups[0]
}

function Get-BackupByVersion {
    param (
        [string]$Version
    )
    
    $backups = Get-ChildItem -Path $backupsDir -Directory | Where-Object { $_.Name -like "*-$Version" } | Sort-Object Name -Descending
    
    if ($backups.Count -eq 0) {
        return $null
    }
    
    return $backups[0]
}

function Get-BackupByDateAndVersion {
    param (
        [string]$Date,
        [string]$Version
    )
    
    $backupName = "$Date-$Version"
    $backup = Get-ChildItem -Path $backupsDir -Directory | Where-Object { $_.Name -eq $backupName }
    
    return $backup
}

function Update-VersionHistory {
    param (
        [string]$Version
    )
    
    if (Test-Path $versionHistoryPath) {
        $versionHistory = Get-Content -Path $versionHistoryPath -Raw | ConvertFrom-Json
        
        $versionInfo = @{
            Version = $Version
            Date = Get-Date -Format "yyyy-MM-dd"
            Components = @("Rollback")
            UpdatedBy = $env:USERNAME
            IsRollback = $true
        }
        
        $versionHistory += $versionInfo
        $versionHistory | ConvertTo-Json -Depth 5 | Set-Content -Path $versionHistoryPath
        
        Write-Log "Historique des versions mis à jour." -Level "SUCCESS"
    }
}

# Corps principal du script
try {
    Write-Log "Restauration d'une version précédente des composants MCP..." -Level "TITLE"
    
    # Déterminer la sauvegarde à restaurer
    $backup = $null
    
    if ($BackupDate -and $Version) {
        $backup = Get-BackupByDateAndVersion -Date $BackupDate -Version $Version
        if (-not $backup) {
            Write-Log "Sauvegarde $BackupDate-$Version non trouvée." -Level "ERROR"
            exit 1
        }
    }
    elseif ($BackupDate) {
        $backup = Get-BackupByDate -Date $BackupDate
        if (-not $backup) {
            Write-Log "Aucune sauvegarde trouvée pour la date $BackupDate." -Level "ERROR"
            exit 1
        }
    }
    elseif ($Version) {
        $backup = Get-BackupByVersion -Version $Version
        if (-not $backup) {
            Write-Log "Aucune sauvegarde trouvée pour la version $Version." -Level "ERROR"
            exit 1
        }
    }
    else {
        $backup = Get-LatestBackup
        if (-not $backup) {
            Write-Log "Aucune sauvegarde trouvée." -Level "ERROR"
            exit 1
        }
    }
    
    Write-Log "Sauvegarde à restaurer: $($backup.Name)" -Level "INFO"
    
    # Extraire la version de la sauvegarde
    $backupVersion = $backup.Name -replace '^\d{8}-', ''
    
    # Demander confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous restaurer la version $backupVersion ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Restauration annulée par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }
    
    # Restaurer les fichiers
    $dirsToRestore = @(
        "config",
        "core",
        "modules",
        "python"
    )
    
    foreach ($dir in $dirsToRestore) {
        $sourcePath = Join-Path -Path $backup.FullName -ChildPath $dir
        $targetPath = Join-Path -Path $mcpRoot -ChildPath $dir
        
        if (Test-Path $sourcePath) {
            if ($PSCmdlet.ShouldProcess($sourcePath, "Restore to $targetPath")) {
                # Supprimer le répertoire cible s'il existe
                if (Test-Path $targetPath) {
                    Remove-Item -Path $targetPath -Recurse -Force
                }
                
                # Créer le répertoire parent si nécessaire
                $targetParent = Split-Path -Parent $targetPath
                if (-not (Test-Path $targetParent)) {
                    New-Item -Path $targetParent -ItemType Directory -Force | Out-Null
                }
                
                # Copier les fichiers
                Copy-Item -Path $sourcePath -Destination $targetPath -Recurse -Force
                Write-Log "Restauration de $dir terminée." -Level "SUCCESS"
            }
        }
        else {
            Write-Log "Répertoire $dir non trouvé dans la sauvegarde, ignoré." -Level "WARNING"
        }
    }
    
    # Mettre à jour l'historique des versions
    if ($PSCmdlet.ShouldProcess($versionHistoryPath, "Update version history")) {
        Update-VersionHistory -Version $backupVersion
    }
    
    Write-Log "Restauration de la version $backupVersion terminée." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de la restauration: $_" -Level "ERROR"
    exit 1
}
