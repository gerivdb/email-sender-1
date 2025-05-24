#Requires -Version 5.1
<#
.SYNOPSIS
    Sauvegarde la configuration MCP.
.DESCRIPTION
    Ce script sauvegarde la configuration MCP et les fichiers importants
    dans un répertoire de sauvegarde ou un fichier ZIP.
.PARAMETER BackupDir
    Répertoire de sauvegarde. Par défaut, "projet/mcp/versioning/backups".
.PARAMETER CreateZip
    Crée un fichier ZIP au lieu d'un répertoire.
.PARAMETER IncludeData
    Inclut les données en plus de la configuration.
.PARAMETER Force
    Force la sauvegarde sans demander de confirmation.
.EXAMPLE
    .\backup-mcp-config.ps1 -CreateZip -IncludeData
    Sauvegarde la configuration et les données dans un fichier ZIP.
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
    [switch]$CreateZip,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeData,
    
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
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path -Path $backupDir -ChildPath $timestamp

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

function Backup-Directory {
    param (
        [string]$SourceDir,
        [string]$TargetDir,
        [string]$RelativePath = ""
    )
    
    # Créer le répertoire cible
    $targetPath = Join-Path -Path $TargetDir -ChildPath $RelativePath
    if (-not (Test-Path $targetPath)) {
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    }
    
    # Copier les fichiers
    $files = Get-ChildItem -Path $SourceDir -File
    foreach ($file in $files) {
        $targetFile = Join-Path -Path $targetPath -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $targetFile -Force
    }
    
    # Copier les sous-répertoires
    $dirs = Get-ChildItem -Path $SourceDir -Directory
    foreach ($dir in $dirs) {
        $newRelativePath = if ($RelativePath) { Join-Path -Path $RelativePath -ChildPath $dir.Name } else { $dir.Name }
        Backup-Directory -SourceDir $dir.FullName -TargetDir $TargetDir -RelativePath $newRelativePath
    }
}

function New-ZipFile {
    param (
        [string]$SourceDir,
        [string]$ZipFile
    )
    
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDir, $ZipFile)
        return $true
    }
    catch {
        Write-Log "Erreur lors de la création du fichier ZIP: $_" -Level "ERROR"
        return $false
    }
}

# Corps principal du script
try {
    Write-Log "Sauvegarde de la configuration MCP..." -Level "TITLE"
    
    # Créer le répertoire de sauvegarde
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    }
    
    # Créer le répertoire de sauvegarde temporaire
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    
    # Demander confirmation
    if (-not $Force) {
        $message = "Voulez-vous sauvegarder la configuration MCP"
        
        if ($IncludeData) {
            $message += " et les données"
        }
        
        if ($CreateZip) {
            $message += " dans un fichier ZIP"
        }
        else {
            $message += " dans un répertoire"
        }
        
        $message += " ? (O/N)"
        
        $confirmation = Read-Host $message
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Sauvegarde annulée par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }
    
    # Sauvegarder les répertoires
    $dirsToBackup = @(
        "config",
        "modules",
        "scripts"
    )
    
    if ($IncludeData) {
        $dirsToBackup += @(
            "data",
            "monitoring\logs",
            "monitoring\reports"
        )
    }
    
    foreach ($dir in $dirsToBackup) {
        $sourcePath = Join-Path -Path $mcpRoot -ChildPath $dir
        
        if (Test-Path $sourcePath) {
            if ($PSCmdlet.ShouldProcess($sourcePath, "Backup")) {
                Write-Log "Sauvegarde du répertoire $dir..." -Level "INFO"
                Backup-Directory -SourceDir $sourcePath -TargetDir $backupPath -RelativePath $dir
                Write-Log "Répertoire $dir sauvegardé." -Level "SUCCESS"
            }
        }
        else {
            Write-Log "Répertoire $dir non trouvé, ignoré." -Level "WARNING"
        }
    }
    
    # Créer un fichier ZIP si demandé
    if ($CreateZip) {
        $zipFile = "$backupPath.zip"
        
        if ($PSCmdlet.ShouldProcess($backupPath, "Create ZIP file")) {
            Write-Log "Création du fichier ZIP..." -Level "INFO"
            $zipResult = New-ZipFile -SourceDir $backupPath -ZipFile $zipFile
            
            if ($zipResult) {
                Write-Log "Fichier ZIP créé: $zipFile" -Level "SUCCESS"
                
                # Supprimer le répertoire temporaire
                Remove-Item -Path $backupPath -Recurse -Force
                
                Write-Log "Sauvegarde terminée." -Level "SUCCESS"
            }
            else {
                Write-Log "Échec de la création du fichier ZIP." -Level "ERROR"
                Write-Log "La sauvegarde est disponible dans le répertoire: $backupPath" -Level "INFO"
            }
        }
    }
    else {
        Write-Log "Sauvegarde terminée. Répertoire de sauvegarde: $backupPath" -Level "SUCCESS"
    }
} catch {
    Write-Log "Erreur lors de la sauvegarde de la configuration MCP: $_" -Level "ERROR"
    exit 1
}

