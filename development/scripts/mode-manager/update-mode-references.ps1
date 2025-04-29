<#
.SYNOPSIS
    Script pour mettre Ã  jour les rÃ©fÃ©rences aux modes dans les fichiers de documentation.

.DESCRIPTION
    Ce script met Ã  jour les rÃ©fÃ©rences aux modes dans les fichiers de documentation pour utiliser le mode MANAGER.
    Il remplace les rÃ©fÃ©rences directes aux scripts de mode par des rÃ©fÃ©rences au mode MANAGER.

.PARAMETER Force
    Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation.
    Par dÃ©faut : $false (mode simulation).

.PARAMETER BackupFiles
    Indique si des copies de sauvegarde des fichiers originaux doivent Ãªtre crÃ©Ã©es.
    Par dÃ©faut : $true.

.EXAMPLE
    .\update-mode-references.ps1 -Force

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
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

# Afficher les informations de dÃ©marrage
Write-Host "Mise Ã  jour des rÃ©fÃ©rences aux modes" -ForegroundColor Cyan
Write-Host "Mode : " -NoNewline
if ($Force) {
    Write-Host "Mise Ã  jour" -ForegroundColor Yellow
} else {
    Write-Host "Simulation (utilisez -Force pour appliquer les modifications)" -ForegroundColor Gray
}
Write-Host "Sauvegarde des fichiers originaux : " -NoNewline
if ($BackupFiles) {
    Write-Host "ActivÃ©e" -ForegroundColor Green
} else {
    Write-Host "DÃ©sactivÃ©e" -ForegroundColor Yellow
}

# Fonction pour crÃ©er une sauvegarde d'un fichier
function Backup-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        Write-Warning "Le fichier Ã  sauvegarder n'existe pas : $FilePath"
        return
    }

    $backupPath = "$FilePath.bak"
    $i = 1
    while (Test-Path -Path $backupPath) {
        $backupPath = "$FilePath.bak$i"
        $i++
    }

    if ($PSCmdlet.ShouldProcess($FilePath, "CrÃ©er une sauvegarde")) {
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Host "Sauvegarde crÃ©Ã©e : $backupPath" -ForegroundColor Green
    }
}

# Fonction pour mettre Ã  jour les rÃ©fÃ©rences dans un fichier
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

    # CrÃ©er une sauvegarde si la sauvegarde est activÃ©e
    if ($CreateBackup) {
        Backup-File -FilePath $FilePath
    }

    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw

        # DÃ©finir les modÃ¨les de remplacement
        $replacements = @(
            @{
                OldPattern = '\.\\gran-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode GRAN'
            },
            @{
                OldPattern = '\.\\dev-r-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode DEV-R'
            },
            @{
                OldPattern = '\.\\check-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode CHECK'
            },
            @{
                OldPattern = '\.\\debug-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode DEBUG'
            },
            @{
                OldPattern = '\.\\test-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode TEST'
            },
            @{
                OldPattern = '\.\\archi-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode ARCHI'
            },
            @{
                OldPattern = '\.\\opti-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode OPTI'
            },
            @{
                OldPattern = '\.\\review-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode REVIEW'
            },
            @{
                OldPattern = '\.\\predic-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode PREDIC'
            },
            @{
                OldPattern = '\.\\c-break-mode\.ps1'
                NewPattern = '.\development\\scripts\\mode-manager\mode-manager.ps1 -Mode C-BREAK'
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

        # Enregistrer les modifications si le contenu a Ã©tÃ© modifiÃ©
        if ($modified) {
            if ($PSCmdlet.ShouldProcess($FilePath, "Mettre Ã  jour les rÃ©fÃ©rences aux modes")) {
                Set-Content -Path $FilePath -Value $newContent -NoNewline
                Write-Host "RÃ©fÃ©rences mises Ã  jour : $FilePath" -ForegroundColor Green
            }
        } else {
            Write-Host "Aucune rÃ©fÃ©rence Ã  mettre Ã  jour : $FilePath" -ForegroundColor Yellow
        }
    } catch {
        Write-Error "Erreur lors de la mise Ã  jour des rÃ©fÃ©rences : $_"
    }
}

# Rechercher les fichiers de documentation
$docFiles = Get-ChildItem -Path $basePath -Include "*.md" -Recurse -File |
    Where-Object { $_.FullName -like "*\methodologies\*" -or $_.FullName -like "*\guides\*" }

# Mettre Ã  jour les rÃ©fÃ©rences dans les fichiers de documentation
foreach ($docFile in $docFiles) {
    Update-ModeReferences -FilePath $docFile.FullName -CreateBackup:$BackupFiles
}

# Afficher un message de fin
Write-Host "`nMise Ã  jour des rÃ©fÃ©rences aux modes terminÃ©e." -ForegroundColor Cyan
if (-not $Force) {
    Write-Host "ExÃ©cutez ce script avec le paramÃ¨tre -Force pour appliquer les modifications." -ForegroundColor Yellow
}

