<#
.SYNOPSIS
    Script pour mettre à jour les références aux modes dans les fichiers de documentation.

.DESCRIPTION
    Ce script met à jour les références aux modes dans les fichiers de documentation pour utiliser le mode MANAGER.
    Il remplace les références directes aux scripts de mode par des références au mode MANAGER.

.PARAMETER Force
    Indique si les modifications doivent être appliquées sans confirmation.
    Par défaut : $false (mode simulation).

.PARAMETER BackupFiles
    Indique si des copies de sauvegarde des fichiers originaux doivent être créées.
    Par défaut : $true.

.EXAMPLE
    .\update-mode-references.ps1 -Force

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de création: 2023-08-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$BackupFiles = $true
)

# Chemin de base du projet
$basePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $basePath)) {
    $basePath = $PSScriptRoot
    while ((Split-Path -Path $basePath -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $basePath) -ne "") {
        $basePath = Split-Path -Path $basePath
    }
}

# Afficher les informations de démarrage
Write-Host "Mise à jour des références aux modes" -ForegroundColor Cyan
Write-Host "Mode : " -NoNewline
if ($Force) {
    Write-Host "Mise à jour" -ForegroundColor Yellow
} else {
    Write-Host "Simulation (utilisez -Force pour appliquer les modifications)" -ForegroundColor Gray
}
Write-Host "Sauvegarde des fichiers originaux : " -NoNewline
if ($BackupFiles) {
    Write-Host "Activée" -ForegroundColor Green
} else {
    Write-Host "Désactivée" -ForegroundColor Yellow
}

# Fonction pour créer une sauvegarde d'un fichier
function Backup-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-Warning "Le fichier à sauvegarder n'existe pas : $FilePath"
        return
    }

    $backupPath = "$FilePath.bak"
    $i = 1
    while (Test-Path -Path $backupPath) {
        $backupPath = "$FilePath.bak$i"
        $i++
    }

    if ($PSCmdlet.ShouldProcess($FilePath, "Créer une sauvegarde")) {
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Host "Sauvegarde créée : $backupPath" -ForegroundColor Green
    }
}

# Fonction pour mettre à jour les références dans un fichier
function Update-ModeReferences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup = $true
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-Warning "Le fichier n'existe pas : $FilePath"
        return
    }

    # Créer une sauvegarde si la sauvegarde est activée
    if ($CreateBackup) {
        Backup-File -FilePath $FilePath
    }

    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw

        # Définir les modèles de remplacement
        $replacements = @(
            @{
                OldPattern = '\.\\gran-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode GRAN'
            },
            @{
                OldPattern = '\.\\dev-r-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode DEV-R'
            },
            @{
                OldPattern = '\.\\check-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode CHECK'
            },
            @{
                OldPattern = '\.\\debug-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode DEBUG'
            },
            @{
                OldPattern = '\.\\test-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode TEST'
            },
            @{
                OldPattern = '\.\\archi-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode ARCHI'
            },
            @{
                OldPattern = '\.\\opti-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode OPTI'
            },
            @{
                OldPattern = '\.\\review-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode REVIEW'
            },
            @{
                OldPattern = '\.\\predic-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode PREDIC'
            },
            @{
                OldPattern = '\.\\c-break-mode\.ps1'
                NewPattern = '.\development\scripts\manager\mode-manager.ps1 -Mode C-BREAK'
            }
        )

        # Appliquer les remplacements
        $modified = $false
        $newContent = $content

        foreach ($replacement in $replacements) {
            if ($newContent -match $replacement.OldPattern) {
                $newContent = $newContent -replace $replacement.OldPattern, $replacement.NewPattern
                $modified = $true
            }
        }

        # Enregistrer les modifications si le contenu a été modifié
        if ($modified) {
            if ($PSCmdlet.ShouldProcess($FilePath, "Mettre à jour les références aux modes")) {
                Set-Content -Path $FilePath -Value $newContent -NoNewline
                Write-Host "Références mises à jour : $FilePath" -ForegroundColor Green
            }
        } else {
            Write-Host "Aucune référence à mettre à jour : $FilePath" -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Erreur lors de la mise à jour des références : $_"
    }
}

# Rechercher les fichiers de documentation
$docFiles = Get-ChildItem -Path $basePath -Include "*.md" -Recurse -File |
    Where-Object { $_.FullName -like "*\methodologies\*" -or $_.FullName -like "*\guides\*" }

# Mettre à jour les références dans les fichiers de documentation
foreach ($docFile in $docFiles) {
    Update-ModeReferences -FilePath $docFile.FullName -CreateBackup:$BackupFiles
}

# Afficher un message de fin
Write-Host "`nMise à jour des références aux modes terminée." -ForegroundColor Cyan
if (-not $Force) {
    Write-Host "Exécutez ce script avec le paramètre -Force pour appliquer les modifications." -ForegroundColor Yellow
}
