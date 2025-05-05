<#
.SYNOPSIS
    Nettoie les fichiers originaux aprÃƒÂ¨s l'organisation du dÃƒÂ©pÃƒÂ´t.

.DESCRIPTION
    Ce script supprime les fichiers originaux qui ont ÃƒÂ©tÃƒÂ© dÃƒÂ©placÃƒÂ©s lors de l'organisation du dÃƒÂ©pÃƒÂ´t.
    Il ne supprime que les fichiers qui ont ÃƒÂ©tÃƒÂ© correctement copiÃƒÂ©s vers leurs nouveaux emplacements.

.PARAMETER DryRun
    Si spÃƒÂ©cifiÃƒÂ©, le script affiche les actions qui seraient effectuÃƒÂ©es sans les exÃƒÂ©cuter.

.PARAMETER Force
    Si spÃƒÂ©cifiÃƒÂ©, le script supprime les fichiers sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuÃƒÂ©es.

.EXAMPLE
    .\cleanup-repository.ps1 -DryRun

.EXAMPLE
    .\cleanup-repository.ps1 -Force -LogFile "cleanup.log"

.NOTES
    Auteur: Maintenance Team
    Version: 1.0
    Date de crÃƒÂ©ation: 2023-08-15
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

# DÃƒÂ©finir le rÃƒÂ©pertoire racine du dÃƒÂ©pÃƒÂ´t
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# VÃƒÂ©rifier que le rÃƒÂ©pertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le rÃƒÂ©pertoire racine n'existe pas : $repoRoot"
}

Write-Host "Nettoyage du dÃƒÂ©pÃƒÂ´t : $repoRoot" -ForegroundColor Cyan

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
    "=== Nettoyage dÃƒÂ©marrÃƒÂ© le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "RÃƒÂ©pertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# DÃƒÂ©finir les fichiers ÃƒÂ  supprimer
$filesToRemove = @(
    # Scripts de mode
    "development/scripts/archi-mode.ps1",
    "development/scripts/check-mode.ps1",
    "development/scripts/debug-mode.ps1",
    "development/scripts/dev-r-mode.ps1",
    "development/scripts/gran-mode.ps1",
    "development/scripts/test-mode.ps1",
    "development/scripts/Test-GranModeComplete.ps1",
    
    # Scripts de maintenance
    "development/scripts/cleanup-*.ps1",
    "development/scripts/organize-*.ps1",
    "development/scripts/migrate-*.ps1",
    
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
                    Write-Log "Fichier supprimÃƒÂ© : $FilePath"
                }
            }
        } else {
            Write-Log "Suppression ignorÃƒÂ©e : $FilePath"
        }
    } else {
        Write-Log "Le fichier n'existe pas : $FilePath"
    }
}

# Parcourir les fichiers ÃƒÂ  supprimer
foreach ($pattern in $filesToRemove) {
    $files = Get-ChildItem -Path (Join-Path -Path $repoRoot -ChildPath $pattern) -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        # VÃƒÂ©rifier que le fichier a bien ÃƒÂ©tÃƒÂ© copiÃƒÂ© vers son nouvel emplacement
        $fileName = $file.Name
        $baseName = $file.BaseName
        
        # Extraire le nom du mode ÃƒÂ  partir du nom du fichier
        if ($fileName -match "^([a-zA-Z0-9-]+)-mode\.ps1$") {
            $modeName = $matches[1]
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "development/roadmap/scripts-parser/modes/$modeName/$fileName"
        } elseif ($fileName -match "^Test-GranModeComplete\.ps1$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "development/roadmap/scripts-parser/modes/gran/$fileName"
        } elseif ($fileName -match "^cleanup-(.+)\.ps1$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "development/scripts/maintenance/cleanup/$fileName"
        } elseif ($fileName -match "^organize-(.+)\.ps1$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "development/scripts/maintenance/organize/$fileName"
        } elseif ($fileName -match "^migrate-(.+)\.ps1$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "development/scripts/maintenance/migrate/$fileName"
        } elseif ($fileName -match "^mode_(.+)\.md$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "docs/guides/methodologies/$fileName"
        } elseif ($fileName -match "^programmation_(.+)\.md$") {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath "docs/guides/methodologies/$fileName"
        } else {
            # Pour les autres fichiers, on ne vÃƒÂ©rifie pas
            $destinationPath = $null
        }
        
        if ($destinationPath -and (Test-Path -Path $destinationPath)) {
            Remove-FileIfExists -FilePath $file.FullName
        } elseif ($destinationPath) {
            Write-Log "Le fichier n'a pas ÃƒÂ©tÃƒÂ© copiÃƒÂ© vers son nouvel emplacement : $destinationPath"
            Write-Log "Suppression ignorÃƒÂ©e : $($file.FullName)"
        } else {
            Remove-FileIfExists -FilePath $file.FullName
        }
    }
}

# RÃƒÂ©sumÃƒÂ© du nettoyage
Write-Host "Nettoyage terminÃƒÂ©." -ForegroundColor Cyan

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Nettoyage terminÃƒÂ© le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log de nettoyage enregistrÃƒÂ© dans : $LogFile" -ForegroundColor Cyan
}

