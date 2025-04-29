<#
.SYNOPSIS
    Met à jour les références aux gestionnaires dans les fichiers.

.DESCRIPTION
    Ce script met à jour les références aux gestionnaires dans les fichiers
    pour pointer vers les nouveaux emplacements.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire parent du répertoire du script.

.PARAMETER BackupFolder
    Chemin vers le dossier de sauvegarde. Par défaut, utilise le dossier "backups" dans le répertoire du script.

.PARAMETER WhatIf
    Indique ce qui se passerait si le script s'exécutait sans effectuer de modifications.

.PARAMETER Force
    Force l'exécution du script sans demander de confirmation.

.EXAMPLE
    .\update-manager-references.ps1
    Met à jour les références aux gestionnaires dans les fichiers.

.EXAMPLE
    .\update-manager-references.ps1 -WhatIf
    Affiche ce qui se passerait si le script s'exécutait sans effectuer de modifications.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2023-06-01
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

# Vérifier que le dossier de projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le dossier de projet est introuvable : $ProjectRoot"
    exit 1
}

# Créer le dossier de sauvegarde s'il n'existe pas
if (-not (Test-Path -Path $BackupFolder -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($BackupFolder, "Créer le dossier de sauvegarde")) {
        New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null
    }
}

# Définir les chemins des répertoires
$managersRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers"
$configRoot = Join-Path -Path $ProjectRoot -ChildPath "projet\config\managers"

# Vérifier que les répertoires existent
if (-not (Test-Path -Path $managersRoot -PathType Container)) {
    Write-Error "Le répertoire racine des gestionnaires est introuvable : $managersRoot"
    exit 1
}

if (-not (Test-Path -Path $configRoot -PathType Container)) {
    Write-Error "Le répertoire de configuration des gestionnaires est introuvable : $configRoot"
    exit 1
}

# Définir les chemins à mettre à jour
$pathMappings = @{
    # Integrated Manager
    "development\scripts\integrated-manager.ps1"                = "development\managers\integrated-manager\scripts\integrated-manager.ps1"
    "development\scripts\install-integrated-manager.ps1"        = "development\managers\integrated-manager\scripts\install-integrated-manager.ps1"

    # Mode Manager
    "development\scripts\mode-manager\mode-manager.ps1"         = "development\managers\mode-manager\scripts\mode-manager.ps1"
    "development\scripts\mode-manager\install-mode-manager.ps1" = "development\managers\mode-manager\scripts\install-mode-manager.ps1"

    # Roadmap Manager
    "projet\roadmaps\scripts\roadmap-manager.ps1"               = "development\managers\roadmap-manager\scripts\roadmap-manager.ps1"

    # MCP Manager
    "src\mcp\scripts\mcp-manager.ps1"                           = "development\managers\mcp-manager\scripts\mcp-manager.ps1"

    # Script Manager
    "development\scripts\script-manager\script-manager.ps1"     = "development\managers\script-manager\scripts\script-manager.ps1"

    # N8N Manager
    "src\n8n\automation\n8n-manager.ps1"                        = "development\managers\n8n-manager\scripts\n8n-manager.ps1"
    "src\n8n\config\n8n-manager-config.json"                    = "projet\config\managers\n8n-manager\n8n-manager.config.json"
}

# Créer une sauvegarde des fichiers
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = Join-Path -Path $BackupFolder -ChildPath "references-backup-$timestamp"

if ($PSCmdlet.ShouldProcess("Références", "Créer une sauvegarde")) {
    Write-Host "Création d'une sauvegarde des fichiers..." -ForegroundColor Yellow
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
}

# Rechercher les fichiers qui contiennent des références aux anciens chemins
Write-Host "Recherche des fichiers contenant des références aux anciens chemins..." -ForegroundColor Yellow

$filesToUpdate = @()

# Limiter la recherche aux répertoires les plus susceptibles de contenir des références
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

            # Rechercher les fichiers qui contiennent des références à l'ancien chemin
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

# Sauvegarder et mettre à jour les fichiers
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

    # Mettre à jour les références dans le fichier
    if ($PSCmdlet.ShouldProcess($filePath, "Mettre à jour les références")) {
        $fileContent = Get-Content -Path $filePath -Raw
        $originalContent = $fileContent

        foreach ($mapping in $pathMappings.GetEnumerator()) {
            $oldPath = $mapping.Key.Replace("\", "\\").Replace(".", "\.")
            $newPath = $mapping.Value.Replace("\", "\\").Replace(".", "\.")

            $fileContent = $fileContent -replace $oldPath, $newPath
        }

        # Écrire le contenu mis à jour dans le fichier
        if ($fileContent -ne $originalContent) {
            Set-Content -Path $filePath -Value $fileContent -Encoding UTF8
            Write-Host "  Fichier mis à jour : $relativePath" -ForegroundColor Gray
        }
    }
}

# Mettre à jour les références dans les fichiers des gestionnaires
Write-Host "Mise à jour des références dans les fichiers des gestionnaires..." -ForegroundColor Yellow

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

    # Mettre à jour les références dans le fichier
    if ($PSCmdlet.ShouldProcess($filePath, "Mettre à jour les références")) {
        $fileContent = Get-Content -Path $filePath -Raw
        $originalContent = $fileContent

        foreach ($mapping in $pathMappings.GetEnumerator()) {
            $oldPath = $mapping.Key.Replace("\", "\\").Replace(".", "\.")
            $newPath = $mapping.Value.Replace("\", "\\").Replace(".", "\.")

            $fileContent = $fileContent -replace $oldPath, $newPath
        }

        # Écrire le contenu mis à jour dans le fichier
        if ($fileContent -ne $originalContent) {
            Set-Content -Path $filePath -Value $fileContent -Encoding UTF8
            Write-Host "  Fichier mis à jour : $relativePath" -ForegroundColor Gray
        }
    }
}

# Mettre à jour les références dans les fichiers de configuration
Write-Host "Mise à jour des références dans les fichiers de configuration..." -ForegroundColor Yellow

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

    # Mettre à jour les références dans le fichier
    if ($PSCmdlet.ShouldProcess($filePath, "Mettre à jour les références")) {
        $fileContent = Get-Content -Path $filePath -Raw
        $originalContent = $fileContent

        foreach ($mapping in $pathMappings.GetEnumerator()) {
            $oldPath = $mapping.Key.Replace("\", "\\").Replace(".", "\.")
            $newPath = $mapping.Value.Replace("\", "\\").Replace(".", "\.")

            $fileContent = $fileContent -replace $oldPath, $newPath
        }

        # Écrire le contenu mis à jour dans le fichier
        if ($fileContent -ne $originalContent) {
            Set-Content -Path $filePath -Value $fileContent -Encoding UTF8
            Write-Host "  Fichier mis à jour : $relativePath" -ForegroundColor Gray
        }
    }
}

# Afficher un résumé
Write-Host ""
Write-Host "Résumé de la mise à jour des références" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Sauvegarde : $backupPath" -ForegroundColor Gray
Write-Host "Nombre de fichiers mis à jour : $($filesToUpdate.Count)" -ForegroundColor Gray
Write-Host ""
Write-Host "Mise à jour terminée avec succès." -ForegroundColor Green

# Retourner un résultat
return @{
    BackupPath   = $backupPath
    UpdatedFiles = $filesToUpdate.Count
    Success      = $true
}
