<#
.SYNOPSIS
    Met à jour tous les scripts qui utilisent l'ancienne fonction Update-ActiveDocumentCheckboxes pour utiliser la nouvelle version améliorée.

.DESCRIPTION
    Ce script recherche tous les fichiers PowerShell qui importent ou utilisent l'ancienne fonction Update-ActiveDocumentCheckboxes
    et les met à jour pour utiliser la nouvelle version améliorée (Update-ActiveDocumentCheckboxes-Enhanced.ps1).
    Il préserve l'encodage UTF-8 avec BOM pour tous les fichiers modifiés.

.PARAMETER RootPath
    Chemin racine où rechercher les fichiers à mettre à jour.
    Par défaut : le répertoire courant.

.PARAMETER BackupFiles
    Indique si des copies de sauvegarde des fichiers originaux doivent être créées.
    Par défaut : $true.

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.
    Par défaut : $false (mode simulation).

.EXAMPLE
    .\update-checkbox-function.ps1 -RootPath "D:\Projets\MonProjet" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$RootPath = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [switch]$BackupFiles = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour créer une copie de sauvegarde d'un fichier
function Backup-File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $backupPath = "$FilePath.bak"
    Copy-Item -Path $FilePath -Destination $backupPath -Force
    Write-Host "  Sauvegarde créée : $backupPath" -ForegroundColor Gray
}

# Fonction pour mettre à jour les chemins d'importation dans un fichier
function Update-ImportPaths {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw

        # Remplacer les chemins d'importation
        $oldPattern1 = 'Update-ActiveDocumentCheckboxes\.ps1'
        $newPattern1 = 'Update-ActiveDocumentCheckboxes-Enhanced.ps1'
        
        $oldPattern2 = 'Update-ActiveDocumentCheckboxes-Fixed\.ps1'
        $newPattern2 = 'Update-ActiveDocumentCheckboxes-Enhanced.ps1'

        $modified = $false

        if ($content -match $oldPattern1 -or $content -match $oldPattern2) {
            # Créer une sauvegarde si demandé
            if ($BackupFiles) {
                Backup-File -FilePath $FilePath
            }

            # Remplacer les chemins
            $newContent = $content -replace $oldPattern1, $newPattern1
            $newContent = $newContent -replace $oldPattern2, $newPattern2

            # Vérifier si le contenu a été modifié
            if ($newContent -ne $content) {
                $modified = $true

                # Enregistrer les modifications si nécessaire
                if ($Force -or $PSCmdlet.ShouldProcess($FilePath, "Mettre à jour les chemins d'importation")) {
                    # Utiliser UTF-8 avec BOM pour l'enregistrement
                    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
                    [System.IO.File]::WriteAllText($FilePath, $newContent, $utf8WithBom)
                    
                    Write-Host "  Chemins d'importation mis à jour dans : $FilePath" -ForegroundColor Green
                } else {
                    Write-Host "  Les chemins d'importation seraient mis à jour dans : $FilePath (mode simulation)" -ForegroundColor Yellow
                }
            }
        }

        return $modified
    }
    catch {
        Write-Error "Erreur lors de la mise à jour des chemins d'importation dans $FilePath : $_"
        return $false
    }
}

# Fonction pour mettre à jour les appels de fonction dans un fichier
function Update-FunctionCalls {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Vérifier si le fichier a déjà été modifié par Update-ImportPaths
        $alreadyModified = $script:modifiedFiles -contains $FilePath
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw

        # Rechercher les appels à l'ancienne fonction sans mise à jour des chemins d'importation
        if (-not $alreadyModified -and $content -match 'Update-ActiveDocumentCheckboxes\s+(?!-Enhanced)') {
            # Créer une sauvegarde si demandé et si ce n'est pas déjà fait
            if ($BackupFiles -and -not $alreadyModified) {
                Backup-File -FilePath $FilePath
            }

            # Enregistrer les modifications si nécessaire
            if ($Force -or $PSCmdlet.ShouldProcess($FilePath, "Mettre à jour les appels de fonction")) {
                # Utiliser UTF-8 avec BOM pour l'enregistrement
                $utf8WithBom = New-Object System.Text.UTF8Encoding $true
                [System.IO.File]::WriteAllText($FilePath, $content, $utf8WithBom)
                
                Write-Host "  Encodage UTF-8 avec BOM appliqué à : $FilePath" -ForegroundColor Green
            } else {
                Write-Host "  L'encodage UTF-8 avec BOM serait appliqué à : $FilePath (mode simulation)" -ForegroundColor Yellow
            }

            return $true
        }

        return $false
    }
    catch {
        Write-Error "Erreur lors de la mise à jour des appels de fonction dans $FilePath : $_"
        return $false
    }
}

# Afficher les informations de démarrage
Write-Host "Recherche des fichiers à mettre à jour dans : $RootPath" -ForegroundColor Cyan
Write-Host "Mode : " -NoNewline
if ($Force) {
    Write-Host "Application des modifications" -ForegroundColor Yellow
} else {
    Write-Host "Simulation (utilisez -Force pour appliquer les modifications)" -ForegroundColor Gray
}
Write-Host "Sauvegarde des fichiers originaux : " -NoNewline
if ($BackupFiles) {
    Write-Host "Activée" -ForegroundColor Green
} else {
    Write-Host "Désactivée" -ForegroundColor Yellow
}

# Rechercher tous les fichiers PowerShell
$psFiles = Get-ChildItem -Path $RootPath -Include "*.ps1" -Recurse

Write-Host "`nAnalyse de $($psFiles.Count) fichiers PowerShell..." -ForegroundColor Cyan

# Liste pour suivre les fichiers modifiés
$script:modifiedFiles = @()

# Mettre à jour les chemins d'importation
foreach ($file in $psFiles) {
    $modified = Update-ImportPaths -FilePath $file.FullName
    if ($modified) {
        $script:modifiedFiles += $file.FullName
    }
}

# Mettre à jour les appels de fonction
foreach ($file in $psFiles) {
    $modified = Update-FunctionCalls -FilePath $file.FullName
    if ($modified -and $script:modifiedFiles -notcontains $file.FullName) {
        $script:modifiedFiles += $file.FullName
    }
}

# Afficher un résumé
Write-Host "`nRésumé des modifications :" -ForegroundColor Cyan
Write-Host "  Fichiers analysés : $($psFiles.Count)" -ForegroundColor Cyan
Write-Host "  Fichiers modifiés : $($script:modifiedFiles.Count)" -ForegroundColor Cyan

if ($script:modifiedFiles.Count -gt 0) {
    Write-Host "`nListe des fichiers modifiés :" -ForegroundColor Cyan
    foreach ($file in $script:modifiedFiles) {
        Write-Host "  - $file" -ForegroundColor Green
    }
}

# Afficher un message de fin
if ($Force) {
    Write-Host "`nMise à jour terminée." -ForegroundColor Green
} else {
    Write-Host "`nSimulation terminée. Utilisez -Force pour appliquer les modifications." -ForegroundColor Yellow
}
