<#
.SYNOPSIS
    Nettoie les fichiers originaux aprÃ¨s l'organisation du dÃ©pÃ´t.

.DESCRIPTION
    Ce script supprime les fichiers originaux qui ont Ã©tÃ© dÃ©placÃ©s lors de l'organisation du dÃ©pÃ´t.
    Il ne supprime que les fichiers qui ont Ã©tÃ© correctement copiÃ©s vers leurs nouveaux emplacements.

.PARAMETER DryRun
    Si spÃ©cifiÃ©, le script affiche les actions qui seraient effectuÃ©es sans les exÃ©cuter.

.PARAMETER Force
    Si spÃ©cifiÃ©, le script supprime les fichiers sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuÃ©es.

.EXAMPLE
    .\cleanup-repository.ps1 -DryRun

.EXAMPLE
    .\cleanup-repository.ps1 -Force -LogFile "cleanup.log"

.NOTES
    Auteur: Maintenance Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$LogFile
)

# DÃ©finir le rÃ©pertoire racine du dÃ©pÃ´t
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# VÃ©rifier que le rÃ©pertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le rÃ©pertoire racine n'existe pas : $repoRoot"
}

Write-Host "Nettoyage du dÃ©pÃ´t : $repoRoot" -ForegroundColor Cyan

# Fonction pour journaliser les actions
function Write-Log {
    param (
        [string]$Message
    )
    
    Write-Host $Message
    
    if ($LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
}

# Initialiser le fichier de log
if ($LogFile) {
    if (-not [System.IO.Path]::IsPathRooted($LogFile)) {
        $LogFile = Join-Path -Path $PSScriptRoot -ChildPath $LogFile
    }
    
    $logDir = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Nettoyage dÃ©marrÃ© le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "RÃ©pertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# DÃ©finir les fichiers Ã  supprimer
$filesToRemove = @(
    # Scripts de mode
    "scripts/archi-mode.ps1",
    "scripts/check-mode.ps1",
    "scripts/debug-mode.ps1",
    "scripts/dev-r-mode.ps1",
    "scripts/gran-mode.ps1",
    "scripts/test-mode.ps1",
    "scripts/Test-GranModeComplete.ps1",
    
    # Scripts de maintenance
    "scripts/cleanup-*.ps1",
    "scripts/organize-*.ps1",
    "scripts/migrate-*.ps1",
    
    # Documentation
    "docs/guides/mode_*.md",
    "docs/guides/programmation_*.md",
    
    # Templates
    "templates/*.ejs.t",
    "templates/roadmap-parser/*.ejs.t",
    "templates/maintenance/*.ejs.t"
)

# Fonction pour supprimer un fichier
function Remove-FileIfExists {
    param (
        [string]$FilePath
    )
    
    if (Test-Path -Path $FilePath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Voulez-vous supprimer le fichier : $FilePath ?", "Confirmation")
        }
        
        if ($shouldContinue) {
            if ($DryRun) {
                Write-Log "[DRYRUN] Suppression du fichier : $FilePath"
            } else {
                if ($PSCmdlet.ShouldProcess($FilePath, "Supprimer")) {
                    Remove-Item -Path $FilePath -Force
                    Write-Log "Fichier supprimÃ© : $FilePath"
                }
            }
        } else {
            Write-Log "Suppression ignorÃ©e : $FilePath"
        }
    } else {
        Write-Log "Le fichier n'existe pas : $FilePath"
    }
}

# Parcourir les fichiers Ã  supprimer
foreach ($pattern in $filesToRemove) {
    $files = Get-ChildItem -Path (Join-Path -Path $repoRoot -ChildPath $pattern) -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        # VÃ©rifier que le fichier a bien Ã©tÃ© copiÃ© vers son nouvel emplacement
        $fileName = $file.Name
        $baseName = $file.BaseName
        
        # Extraire le nom du mode Ã  partir du nom du fichier
        if ($fileName -match "^([a-zA-Z0-9-]+)-mode\.ps1$") {
            $modeName = $matches[1]
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "scripts/roadmap-parser/modes/$modeName/$fileName"
        } elseif ($fileName -match "^Test-GranModeComplete\.ps1$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "scripts/roadmap-parser/modes/gran/$fileName"
        } elseif ($fileName -match "^cleanup-(.+)\.ps1$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "scripts/maintenance/cleanup/$fileName"
        } elseif ($fileName -match "^organize-(.+)\.ps1$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "scripts/maintenance/organize/$fileName"
        } elseif ($fileName -match "^migrate-(.+)\.ps1$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "scripts/maintenance/migrate/$fileName"
        } elseif ($fileName -match "^mode_(.+)\.md$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "docs/guides/methodologies/$fileName"
        } elseif ($fileName -match "^programmation_(.+)\.md$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "docs/guides/methodologies/$fileName"
        } else {
            # Pour les autres fichiers, on ne vÃ©rifie pas
            $destinationPath = $null
        }
        
        if ($destinationPath -and (Test-Path -Path $destinationPath)) {
            Remove-FileIfExists -FilePath $file.FullName
        } elseif ($destinationPath) {
            Write-Log "Le fichier n'a pas Ã©tÃ© copiÃ© vers son nouvel emplacement : $destinationPath"
            Write-Log "Suppression ignorÃ©e : $($file.FullName)"
        } else {
            Remove-FileIfExists -FilePath $file.FullName
        }
    }
}

# RÃ©sumÃ© du nettoyage
Write-Host "Nettoyage terminÃ©." -ForegroundColor Cyan

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Nettoyage terminÃ© le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log de nettoyage enregistrÃ© dans : $LogFile" -ForegroundColor Cyan
}
