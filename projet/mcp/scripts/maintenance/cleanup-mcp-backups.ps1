#Requires -Version 5.1
<#
.SYNOPSIS
    Nettoie les anciennes sauvegardes MCP.
.DESCRIPTION
    Ce script supprime les anciennes sauvegardes MCP en fonction de leur âge
    ou du nombre maximum de sauvegardes à conserver.
.PARAMETER BackupDir
    Répertoire de sauvegarde. Par défaut, "projet/mcp/versioning/backups".
.PARAMETER MaxAge
    Âge maximum des sauvegardes en jours. Par défaut, 30 jours.
.PARAMETER MaxCount
    Nombre maximum de sauvegardes à conserver. Par défaut, 10.
.PARAMETER Force
    Force le nettoyage sans demander de confirmation.
.EXAMPLE
    .\cleanup-mcp-backups.ps1 -MaxAge 15 -MaxCount 5
    Supprime les sauvegardes de plus de 15 jours et ne conserve que les 5 plus récentes.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$BackupDir = "projet/mcp/versioning/backups",
    
    [Parameter(Mandatory = $false)]
    [int]$MaxAge = 30,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxCount = 10,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $scriptsRoot).Parent.FullName
$projectRoot = (Get-Item $mcpRoot).Parent.FullName
$backupDir = Join-Path -Path $projectRoot -ChildPath $BackupDir

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

# Corps principal du script
try {
    Write-Log "Nettoyage des anciennes sauvegardes MCP..." -Level "TITLE"
    
    # Vérifier si le répertoire de sauvegarde existe
    if (-not (Test-Path $backupDir)) {
        Write-Log "Répertoire de sauvegarde non trouvé: $backupDir" -Level "WARNING"
        exit 0
    }
    
    # Récupérer toutes les sauvegardes
    $backups = @()
    
    # Récupérer les répertoires de sauvegarde
    $backupDirs = Get-ChildItem -Path $backupDir -Directory | Where-Object {
        $_.Name -match "^\d{8}-\d{6}$"
    }
    
    foreach ($dir in $backupDirs) {
        $backups += @{
            Path = $dir.FullName
            Name = $dir.Name
            Type = "Directory"
            CreationTime = $dir.CreationTime
            Age = (Get-Date) - $dir.CreationTime
        }
    }
    
    # Récupérer les fichiers ZIP
    $zipFiles = Get-ChildItem -Path $backupDir -File -Filter "*.zip" | Where-Object {
        $_.Name -match "^\d{8}-\d{6}\.zip$"
    }
    
    foreach ($file in $zipFiles) {
        $backups += @{
            Path = $file.FullName
            Name = $file.Name
            Type = "ZIP"
            CreationTime = $file.CreationTime
            Age = (Get-Date) - $file.CreationTime
        }
    }
    
    # Trier les sauvegardes par date de création (la plus récente en premier)
    $backups = $backups | Sort-Object -Property CreationTime -Descending
    
    # Afficher les informations
    Write-Log "Informations sur les sauvegardes:" -Level "INFO"
    Write-Log "- Nombre total de sauvegardes: $($backups.Count)" -Level "INFO"
    Write-Log "- Âge maximum autorisé: $MaxAge jours" -Level "INFO"
    Write-Log "- Nombre maximum de sauvegardes à conserver: $MaxCount" -Level "INFO"
    
    # Identifier les sauvegardes à supprimer
    $backupsToDelete = @()
    
    # Supprimer les sauvegardes trop anciennes
    foreach ($backup in $backups) {
        if ($backup.Age.TotalDays -gt $MaxAge) {
            $backupsToDelete += $backup
        }
    }
    
    # Supprimer les sauvegardes en excès
    if ($backups.Count - $backupsToDelete.Count -gt $MaxCount) {
        $excessCount = ($backups.Count - $backupsToDelete.Count) - $MaxCount
        $backupsToDelete += $backups | Where-Object { $_ -notin $backupsToDelete } | Select-Object -Last $excessCount
    }
    
    # Afficher les sauvegardes à supprimer
    if ($backupsToDelete.Count -eq 0) {
        Write-Log "Aucune sauvegarde à supprimer." -Level "SUCCESS"
        exit 0
    }
    
    Write-Log "Sauvegardes à supprimer ($($backupsToDelete.Count)):" -Level "INFO"
    foreach ($backup in $backupsToDelete) {
        Write-Log "- $($backup.Name) ($($backup.Type), âge: $([math]::Round($backup.Age.TotalDays, 1)) jours)" -Level "INFO"
    }
    
    # Demander confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous supprimer ces $($backupsToDelete.Count) sauvegardes ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Nettoyage annulé par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }
    
    # Supprimer les sauvegardes
    $deletedCount = 0
    
    foreach ($backup in $backupsToDelete) {
        if ($PSCmdlet.ShouldProcess($backup.Path, "Delete")) {
            try {
                if ($backup.Type -eq "Directory") {
                    Remove-Item -Path $backup.Path -Recurse -Force
                }
                else {
                    Remove-Item -Path $backup.Path -Force
                }
                
                $deletedCount++
                Write-Log "Sauvegarde supprimée: $($backup.Name)" -Level "SUCCESS"
            }
            catch {
                Write-Log "Erreur lors de la suppression de la sauvegarde $($backup.Name): $_" -Level "ERROR"
            }
        }
    }
    
    Write-Log "Nettoyage terminé. $deletedCount sauvegardes supprimées." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors du nettoyage des anciennes sauvegardes MCP: $_" -Level "ERROR"
    exit 1
}
