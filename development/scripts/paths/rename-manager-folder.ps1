<#
.SYNOPSIS
    Script de migration pour renommer le dossier manager en mode-manager.

.DESCRIPTION
    Ce script renomme le dossier development/scripts/mode-manager en development/scripts/mode-manager
    et met Ã  jour toutes les rÃ©fÃ©rences dans le code.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire parent du rÃ©pertoire du script.

.PARAMETER BackupFolder
    Chemin vers le dossier de sauvegarde. Par dÃ©faut, utilise le dossier "backups" dans le rÃ©pertoire du script.

.PARAMETER WhatIf
    Indique ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.PARAMETER Force
    Force l'exÃ©cution du script sans demander de confirmation.

.EXAMPLE
    .\rename-manager-folder.ps1
    Renomme le dossier manager en mode-manager et met Ã  jour les rÃ©fÃ©rences.

.EXAMPLE
    .\rename-manager-folder.ps1 -WhatIf
    Affiche ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.NOTES
    Auteur: Mode Manager Team
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

# DÃ©finir les chemins
$managerPath = Join-Path -Path $ProjectRoot -ChildPath "development\\scripts\\mode-manager"
$modeManagerPath = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\mode-manager"

# VÃ©rifier que le dossier manager existe
if (-not (Test-Path -Path $managerPath -PathType Container)) {
    Write-Error "Le dossier manager est introuvable : $managerPath"
    exit 1
}

# VÃ©rifier que le dossier mode-manager n'existe pas
if (Test-Path -Path $modeManagerPath -PathType Container) {
    if ($Force) {
        if ($PSCmdlet.ShouldProcess($modeManagerPath, "Supprimer le dossier existant")) {
            Remove-Item -Path $modeManagerPath -Recurse -Force
        }
    } else {
        Write-Error "Le dossier mode-manager existe dÃ©jÃ  : $modeManagerPath. Utilisez -Force pour le remplacer."
        exit 1
    }
}

# CrÃ©er une sauvegarde du dossier manager
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path -Path $BackupFolder -ChildPath "manager-backup-$timestamp"

if ($PSCmdlet.ShouldProcess($managerPath, "CrÃ©er une sauvegarde")) {
    Write-Host "CrÃ©ation d'une sauvegarde du dossier manager..." -ForegroundColor Yellow
    Copy-Item -Path $managerPath -Destination $backupPath -Recurse -Force
    Write-Host "Sauvegarde crÃ©Ã©e : $backupPath" -ForegroundColor Green
}

# Renommer le dossier manager en mode-manager
if ($PSCmdlet.ShouldProcess($managerPath, "Renommer en mode-manager")) {
    Write-Host "Renommage du dossier manager en mode-manager..." -ForegroundColor Yellow

    # CrÃ©er le dossier mode-manager
    New-Item -Path $modeManagerPath -ItemType Directory -Force | Out-Null

    # Copier le contenu du dossier manager vers mode-manager
    Copy-Item -Path "$managerPath\*" -Destination $modeManagerPath -Recurse -Force

    Write-Host "Dossier renommÃ© : $modeManagerPath" -ForegroundColor Green
}

# Mettre Ã  jour les rÃ©fÃ©rences dans les fichiers
Write-Host "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers..." -ForegroundColor Yellow

# Rechercher tous les fichiers qui contiennent des rÃ©fÃ©rences au dossier manager
$files = Get-ChildItem -Path $ProjectRoot -Recurse -File -Include *.ps1, *.psm1, *.psd1, *.md, *.json |
    Where-Object {
        $content = Get-Content -Path $_.FullName -Raw
        $content -match 'development[/\\]scripts[/\\]manager' -or $content -match 'scripts[/\\]manager'
    }

$updatedFiles = 0

foreach ($file in $files) {
    # Ignorer les fichiers dans le dossier de sauvegarde
    if ($file.FullName -like "$BackupFolder*") {
        continue
    }

    # Ignorer les fichiers dans le dossier manager (ils seront supprimÃ©s)
    if ($file.FullName -like "$managerPath*") {
        continue
    }

    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content

    # Remplacer les rÃ©fÃ©rences
    $content = $content -replace 'development/scripts/mode-manager', 'development/scripts/mode-manager'
    $content = $content -replace 'development\\scripts\\manager', 'development\\scripts\\mode-manager'
    $content = $content -replace 'scripts/mode-manager', 'scripts/mode-manager'
    $content = $content -replace 'scripts\\manager', 'scripts\\mode-manager'

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

# Supprimer le dossier manager original
if ($PSCmdlet.ShouldProcess($managerPath, "Supprimer le dossier original")) {
    Write-Host "Suppression du dossier manager original..." -ForegroundColor Yellow
    Remove-Item -Path $managerPath -Recurse -Force
    Write-Host "Dossier supprimÃ© : $managerPath" -ForegroundColor Green
}

# Afficher un rÃ©sumÃ©
Write-Host ""
Write-Host "RÃ©sumÃ© de la migration" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Dossier original : $managerPath" -ForegroundColor Gray
Write-Host "Nouveau dossier : $modeManagerPath" -ForegroundColor Gray
Write-Host "Sauvegarde : $backupPath" -ForegroundColor Gray
Write-Host "Fichiers mis Ã  jour : $updatedFiles" -ForegroundColor Gray
Write-Host ""
Write-Host "Migration terminÃ©e avec succÃ¨s." -ForegroundColor Green

# Retourner un rÃ©sultat
return @{
    OriginalPath = $managerPath
    NewPath      = $modeManagerPath
    BackupPath   = $backupPath
    UpdatedFiles = $updatedFiles
    Success      = $true
}

