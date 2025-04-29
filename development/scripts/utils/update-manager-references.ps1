<#
.SYNOPSIS
    Met Ã  jour les rÃ©fÃ©rences aux gestionnaires dans les fichiers.

.DESCRIPTION
    Ce script met Ã  jour les rÃ©fÃ©rences aux gestionnaires dans les fichiers
    pour pointer vers les nouveaux emplacements.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire parent du rÃ©pertoire du script.

.PARAMETER BackupFolder
    Chemin vers le dossier de sauvegarde. Par dÃ©faut, utilise le dossier "backups" dans le rÃ©pertoire du script.

.PARAMETER WhatIf
    Indique ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.PARAMETER Force
    Force l'exÃ©cution du script sans demander de confirmation.

.EXAMPLE
    .\update-manager-references.ps1
    Met Ã  jour les rÃ©fÃ©rences aux gestionnaires dans les fichiers.

.EXAMPLE
    .\update-manager-references.ps1 -WhatIf
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

# DÃ©finir les chemins des rÃ©pertoires
$managersRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers"
$configRoot = Join-Path -Path $ProjectRoot -ChildPath "projet\config\managers"

# VÃ©rifier que les rÃ©pertoires existent
if (-not (Test-Path -Path $managersRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire racine des gestionnaires est introuvable : $managersRoot"
    exit 1
}

if (-not (Test-Path -Path $configRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire de configuration des gestionnaires est introuvable : $configRoot"
    exit 1
}

# DÃ©finir les chemins Ã  mettre Ã  jour
$pathMappings = @{
    # Integrated Manager
    "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1"                = "development\managers\integrated-manager\scripts\integrated-manager.ps1"
    "development\\managers\\integrated-manager\\scripts\\install-integrated-manager\.ps1"        = "development\managers\integrated-manager\scripts\install-integrated-manager.ps1"

    # Mode Manager
    "development\\managers\\mode-manager\\scripts\\mode-manager\.ps1"         = "development\managers\mode-manager\scripts\mode-manager.ps1"
    "development\\managers\\mode-manager\\scripts\\install-mode-manager\.ps1" = "development\managers\mode-manager\scripts\install-mode-manager.ps1"

    # Roadmap Manager
    "development\\managers\\roadmap-manager\\scripts\\roadmap-manager\.ps1"               = "development\managers\roadmap-manager\scripts\roadmap-manager.ps1"

    # MCP Manager
    "development\\managers\\mcp-manager\\scripts\\mcp-manager\.ps1"                           = "development\managers\mcp-manager\scripts\mcp-manager.ps1"

    # Script Manager
    "development\\managers\\script-manager\\scripts\\script-manager\.ps1"     = "development\managers\script-manager\scripts\script-manager.ps1"

    # N8N Manager
    "development\\managers\\n8n-manager\\scripts\\n8n-manager\.ps1"                        = "development\managers\n8n-manager\scripts\n8n-manager.ps1"
    "projet\\config\\managers\\n8n-manager\\n8n-manager\.config\.json"                    = "projet\config\managers\n8n-manager\n8n-manager.config.json"
}

# CrÃ©er une sauvegarde des fichiers
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path -Path $BackupFolder -ChildPath "references-backup-$timestamp"

if ($PSCmdlet.ShouldProcess("RÃ©fÃ©rences", "CrÃ©er une sauvegarde")) {
    Write-Host "CrÃ©ation d'une sauvegarde des fichiers..." -ForegroundColor Yellow
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
}

# Rechercher les fichiers qui contiennent des rÃ©fÃ©rences aux anciens chemins
Write-Host "Recherche des fichiers contenant des rÃ©fÃ©rences aux anciens chemins..." -ForegroundColor Yellow

$filesToUpdate = @()

# Limiter la recherche aux rÃ©pertoires les plus susceptibles de contenir des rÃ©fÃ©rences
$searchPaths = @(
    Join-Path -Path $ProjectRoot -ChildPath "development\scripts"
    Join-Path -Path $ProjectRoot -ChildPath "development\managers"
    Join-Path -Path $ProjectRoot -ChildPath "projet\config"
    Join-Path -Path $ProjectRoot -ChildPath "projet\roadmaps"
    Join-Path -Path $ProjectRoot -ChildPath "src\mcp"
    Join-Path -Path $ProjectRoot -ChildPath "src\n8n"
)

foreach ($searchPath in $searchPaths) {
    if (Test-Path -Path $searchPath -PathType Container) {
        Write-Host "  Recherche dans $searchPath..." -ForegroundColor Gray

        foreach ($oldPath in $pathMappings.Keys) {
            $oldPathPattern = $oldPath.Replace("\", "\\").Replace(".", "\.")

            # Rechercher les fichiers qui contiennent des rÃ©fÃ©rences Ã  l'ancien chemin
            $files = Get-ChildItem -Path $searchPath -Recurse -File -Include *.ps1, *.psm1, *.psd1, *.json, *.md |
                Where-Object { $_.FullName -notlike "*\node_modules\*" -and $_.FullName -notlike "*\backups\*" } |
                Select-Object -ExpandProperty FullName |
                ForEach-Object {
                    $filePath = $_
                    $fileContent = Get-Content -Path $filePath -Raw

                    if ($fileContent -match $oldPathPattern) {
                        [PSCustomObject]@{
                            FilePath = $filePath
                            OldPath  = $oldPath
                            NewPath  = $pathMappings[$oldPath]
                        }
                    }
                }

            $filesToUpdate += $files
        }
    }
}

# Supprimer les doublons
$filesToUpdate = $filesToUpdate | Sort-Object -Property FilePath -Unique

# Sauvegarder et mettre Ã  jour les fichiers
foreach ($file in $filesToUpdate) {
    $filePath = $file.FilePath
    $fileName = Split-Path -Path $filePath -Leaf
    $relativePath = $filePath.Substring($ProjectRoot.Length + 1)

    # Sauvegarder le fichier
    if ($PSCmdlet.ShouldProcess($filePath, "Sauvegarder")) {
        $backupFilePath = Join-Path -Path $backupPath -ChildPath $relativePath
        $backupFileDir = Split-Path -Path $backupFilePath -Parent

        if (-not (Test-Path -Path $backupFileDir -PathType Container)) {
            New-Item -Path $backupFileDir -ItemType Directory -Force | Out-Null
        }

        Copy-Item -Path $filePath -Destination $backupFilePath -Force
    }

    # Mettre Ã  jour les rÃ©fÃ©rences dans le fichier
    if ($PSCmdlet.ShouldProcess($filePath, "Mettre Ã  jour les rÃ©fÃ©rences")) {
        $fileContent = Get-Content -Path $filePath -Raw
        $originalContent = $fileContent

        foreach ($mapping in $pathMappings.GetEnumerator()) {
            $oldPath = $mapping.Key.Replace("\", "\\").Replace(".", "\.")
            $newPath = $mapping.Value.Replace("\", "\\").Replace(".", "\.")

            $fileContent = $fileContent -replace $oldPath, $newPath
        }

        # Ã‰crire le contenu mis Ã  jour dans le fichier
        if ($fileContent -ne $originalContent) {
            Set-Content -Path $filePath -Value $fileContent -Encoding UTF8
            Write-Host "  Fichier mis Ã  jour : $relativePath" -ForegroundColor Gray
        }
    }
}

# Mettre Ã  jour les rÃ©fÃ©rences dans les fichiers des gestionnaires
Write-Host "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers des gestionnaires..." -ForegroundColor Yellow

$managerFiles = Get-ChildItem -Path $managersRoot -Recurse -File -Include *.ps1, *.psm1, *.psd1, *.json |
    Select-Object -ExpandProperty FullName

foreach ($filePath in $managerFiles) {
    $fileName = Split-Path -Path $filePath -Leaf
    $relativePath = $filePath.Substring($ProjectRoot.Length + 1)

    # Sauvegarder le fichier
    if ($PSCmdlet.ShouldProcess($filePath, "Sauvegarder")) {
        $backupFilePath = Join-Path -Path $backupPath -ChildPath $relativePath
        $backupFileDir = Split-Path -Path $backupFilePath -Parent

        if (-not (Test-Path -Path $backupFileDir -PathType Container)) {
            New-Item -Path $backupFileDir -ItemType Directory -Force | Out-Null
        }

        Copy-Item -Path $filePath -Destination $backupFilePath -Force
    }

    # Mettre Ã  jour les rÃ©fÃ©rences dans le fichier
    if ($PSCmdlet.ShouldProcess($filePath, "Mettre Ã  jour les rÃ©fÃ©rences")) {
        $fileContent = Get-Content -Path $filePath -Raw
        $originalContent = $fileContent

        foreach ($mapping in $pathMappings.GetEnumerator()) {
            $oldPath = $mapping.Key.Replace("\", "\\").Replace(".", "\.")
            $newPath = $mapping.Value.Replace("\", "\\").Replace(".", "\.")

            $fileContent = $fileContent -replace $oldPath, $newPath
        }

        # Ã‰crire le contenu mis Ã  jour dans le fichier
        if ($fileContent -ne $originalContent) {
            Set-Content -Path $filePath -Value $fileContent -Encoding UTF8
            Write-Host "  Fichier mis Ã  jour : $relativePath" -ForegroundColor Gray
        }
    }
}

# Mettre Ã  jour les rÃ©fÃ©rences dans les fichiers de configuration
Write-Host "Mise Ã  jour des rÃ©fÃ©rences dans les fichiers de configuration..." -ForegroundColor Yellow

$configFiles = Get-ChildItem -Path $configRoot -Recurse -File -Include *.json |
    Select-Object -ExpandProperty FullName

foreach ($filePath in $configFiles) {
    $fileName = Split-Path -Path $filePath -Leaf
    $relativePath = $filePath.Substring($ProjectRoot.Length + 1)

    # Sauvegarder le fichier
    if ($PSCmdlet.ShouldProcess($filePath, "Sauvegarder")) {
        $backupFilePath = Join-Path -Path $backupPath -ChildPath $relativePath
        $backupFileDir = Split-Path -Path $backupFilePath -Parent

        if (-not (Test-Path -Path $backupFileDir -PathType Container)) {
            New-Item -Path $backupFileDir -ItemType Directory -Force | Out-Null
        }

        Copy-Item -Path $filePath -Destination $backupFilePath -Force
    }

    # Mettre Ã  jour les rÃ©fÃ©rences dans le fichier
    if ($PSCmdlet.ShouldProcess($filePath, "Mettre Ã  jour les rÃ©fÃ©rences")) {
        $fileContent = Get-Content -Path $filePath -Raw
        $originalContent = $fileContent

        foreach ($mapping in $pathMappings.GetEnumerator()) {
            $oldPath = $mapping.Key.Replace("\", "\\").Replace(".", "\.")
            $newPath = $mapping.Value.Replace("\", "\\").Replace(".", "\.")

            $fileContent = $fileContent -replace $oldPath, $newPath
        }

        # Ã‰crire le contenu mis Ã  jour dans le fichier
        if ($fileContent -ne $originalContent) {
            Set-Content -Path $filePath -Value $fileContent -Encoding UTF8
            Write-Host "  Fichier mis Ã  jour : $relativePath" -ForegroundColor Gray
        }
    }
}

# Afficher un rÃ©sumÃ©
Write-Host ""
Write-Host "RÃ©sumÃ© de la mise Ã  jour des rÃ©fÃ©rences" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Sauvegarde : $backupPath" -ForegroundColor Gray
Write-Host "Nombre de fichiers mis Ã  jour : $($filesToUpdate.Count)" -ForegroundColor Gray
Write-Host ""
Write-Host "Mise Ã  jour terminÃ©e avec succÃ¨s." -ForegroundColor Green

# Retourner un rÃ©sultat
return @{
    BackupPath   = $backupPath
    UpdatedFiles = $filesToUpdate.Count
    Success      = $true
}

