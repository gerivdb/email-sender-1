<#
.SYNOPSIS
    Standardise les noms des gestionnaires selon une convention cohÃ©rente.

.DESCRIPTION
    Ce script renomme les fichiers et dossiers des gestionnaires selon une convention cohÃ©rente.
    Format du nom de fichier : <domaine>-manager.ps1
    Format du nom de dossier : <domaine>-manager
    Format du nom de fonction : Verb-<Domaine>Manager<Action>

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire parent du rÃ©pertoire du script.

.PARAMETER BackupFolder
    Chemin vers le dossier de sauvegarde. Par dÃ©faut, utilise le dossier "backups" dans le rÃ©pertoire du script.

.PARAMETER WhatIf
    Indique ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.PARAMETER Force
    Force l'exÃ©cution du script sans demander de confirmation.

.EXAMPLE
    .\standardize-manager-names.ps1
    Standardise les noms des gestionnaires selon une convention cohÃ©rente.

.EXAMPLE
    .\standardize-manager-names.ps1 -WhatIf
    Affiche ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [string]$BackupFolder = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\maintenance\backups",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# VÃ©rifier que le dossier de projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le dossier de projet est introuvable : $ProjectRoot"
    exit 1
}

# CrÃ©er le dossier de sauvegarde s'il n'existe pas
if (-not (Test-Path -Path $BackupFolder -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($BackupFolder, "CrÃ©er le dossier de sauvegarde")) {
        New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null
    }
}

# DÃ©finir les chemins des gestionnaires
$managerPaths = @{
    "roadmap-manager" = @{
        "OldPath" = Join-Path -Path $ProjectRoot -ChildPath "projet\roadmaps\scripts\roadmap-manager.ps1"
        "NewPath" = Join-Path -Path $ProjectRoot -ChildPath "projet\roadmaps\scripts\roadmap-manager.ps1"
        "NewDir" = Join-Path -Path $ProjectRoot -ChildPath "projet\roadmaps\scripts\roadmap-manager"
    }
    "MCPManager" = @{
        "OldPath" = Join-Path -Path $ProjectRoot -ChildPath "src\mcp\scripts\mcp-manager.ps1"
        "NewPath" = Join-Path -Path $ProjectRoot -ChildPath "src\mcp\scripts\mcp-manager.ps1"
        "NewDir" = Join-Path -Path $ProjectRoot -ChildPath "src\mcp\scripts\mcp-manager"
    }
    "ScriptManager" = @{
        "OldPath" = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\script-manager\script-manager.ps1"
        "NewPath" = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\script-manager\script-manager.ps1"
        "NewDir" = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\script-manager"
    }
}

# CrÃ©er une sauvegarde des fichiers
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path -Path $BackupFolder -ChildPath "managers-backup-$timestamp"

if ($PSCmdlet.ShouldProcess("Gestionnaires", "CrÃ©er une sauvegarde")) {
    Write-Host "CrÃ©ation d'une sauvegarde des gestionnaires..." -ForegroundColor Yellow
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    
    foreach ($manager in $managerPaths.Keys) {
        $oldPath = $managerPaths[$manager].OldPath
        if (Test-Path -Path $oldPath -PathType Leaf) {
            $backupFile = Join-Path -Path $backupPath -ChildPath "$manager.ps1"
            Copy-Item -Path $oldPath -Destination $backupFile -Force
        }
    }
    
    Write-Host "Sauvegarde crÃ©Ã©e : $backupPath" -ForegroundColor Green
}

# Renommer les fichiers selon la convention
foreach ($manager in $managerPaths.Keys) {
    $oldPath = $managerPaths[$manager].OldPath
    $newPath = $managerPaths[$manager].NewPath
    $newDir = $managerPaths[$manager].NewDir
    
    if (Test-Path -Path $oldPath -PathType Leaf) {
        # CrÃ©er le dossier si nÃ©cessaire
        if (-not (Test-Path -Path $newDir -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($newDir, "CrÃ©er le dossier")) {
                New-Item -Path $newDir -ItemType Directory -Force | Out-Null
            }
        }
        
        # Renommer le fichier
        if ($PSCmdlet.ShouldProcess($oldPath, "Renommer en $newPath")) {
            Write-Host "Renommage de $oldPath en $newPath..." -ForegroundColor Yellow
            
            # Copier le fichier vers le nouveau chemin
            Copy-Item -Path $oldPath -Destination $newPath -Force
            
            # Ne pas supprimer l'original pour l'instant
            # Remove-Item -Path $oldPath -Force
            
            Write-Host "Fichier renommÃ© : $newPath" -ForegroundColor Green
        }
    } else {
        Write-Host "Le fichier $oldPath n'existe pas." -ForegroundColor Red
    }
}

# Mettre Ã  jour les rÃ©fÃ©rences dans les fichiers
Write-Host "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers..." -ForegroundColor Yellow

# Rechercher tous les fichiers qui contiennent des rÃ©fÃ©rences aux gestionnaires
$files = Get-ChildItem -Path $ProjectRoot -Recurse -File -Include *.ps1,*.psm1,*.psd1,*.md,*.json | 
    Where-Object { 
        $content = Get-Content -Path $_.FullName -Raw
        $content -match 'roadmap-manager' -or $content -match 'mcp-manager' -or $content -match 'script-manager'
    }

$updatedFiles = 0

foreach ($file in $files) {
    # Ignorer les fichiers dans le dossier de sauvegarde
    if ($file.FullName -like "$BackupFolder*") {
        continue
    }
    
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    
    # Remplacer les rÃ©fÃ©rences
    $content = $content -replace 'roadmap-manager', 'roadmap-manager'
    $content = $content -replace 'mcp-manager', 'mcp-manager'
    $content = $content -replace 'script-manager', 'script-manager'
    
    # Mettre Ã  jour le fichier si des modifications ont Ã©tÃ© apportÃ©es
    if ($content -ne $originalContent) {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Mettre Ã  jour les rÃ©fÃ©rences")) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8
            $updatedFiles++
            Write-Host "  Fichier mis Ã  jour : $($file.FullName)" -ForegroundColor Gray
        }
    }
}

Write-Host "Mise Ã  jour terminÃ©e. $updatedFiles fichiers mis Ã  jour." -ForegroundColor Green

# Afficher un rÃ©sumÃ©
Write-Host ""
Write-Host "RÃ©sumÃ© de la standardisation" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Sauvegarde : $backupPath" -ForegroundColor Gray
Write-Host "Fichiers mis Ã  jour : $updatedFiles" -ForegroundColor Gray
Write-Host ""
Write-Host "Standardisation terminÃ©e avec succÃ¨s." -ForegroundColor Green

# Retourner un rÃ©sultat
return @{
    BackupPath = $backupPath
    UpdatedFiles = $updatedFiles
    Success = $true
}

