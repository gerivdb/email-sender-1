<#
.SYNOPSIS
    Organise la structure du dÃ©pÃ´t selon une structure standardisÃ©e.

.DESCRIPTION
    Ce script organise le dÃ©pÃ´t selon une structure standardisÃ©e.
    Il crÃ©e les dossiers nÃ©cessaires et dÃ©place les fichiers vers leurs emplacements appropriÃ©s.

.PARAMETER DryRun
    Si spÃ©cifiÃ©, le script affiche les actions qui seraient effectuÃ©es sans les exÃ©cuter.

.PARAMETER Force
    Si spÃ©cifiÃ©, le script Ã©crase les fichiers existants sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuÃ©es.

.EXAMPLE
    .\organize-repository.ps1 -DryRun

.EXAMPLE
    .\organize-repository.ps1 -Force -LogFile "organize.log"

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

Write-Host "Organisation du dÃ©pÃ´t : $repoRoot" -ForegroundColor Cyan

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
    "=== Organisation dÃ©marrÃ©e le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "RÃ©pertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# DÃ©finir la structure de dossiers Ã  crÃ©er
$folders = @(
    "scripts",
    "scripts/roadmap",
    "scripts/roadmap-parser",
    "scripts/roadmap-parser/modes",
    "scripts/roadmap-parser/modes/debug",
    "scripts/roadmap-parser/modes/test",
    "scripts/roadmap-parser/modes/archi",
    "scripts/roadmap-parser/modes/check",
    "scripts/roadmap-parser/modes/gran",
    "scripts/roadmap-parser/modes/dev-r",
    "scripts/roadmap-parser/modes/review",
    "scripts/roadmap-parser/modes/opti",
    "scripts/roadmap-parser/core",
    "scripts/roadmap-parser/core/parser",
    "scripts/roadmap-parser/core/model",
    "scripts/roadmap-parser/core/converter",
    "scripts/roadmap-parser/core/structure",
    "scripts/roadmap-parser/utils",
    "scripts/roadmap-parser/utils/encoding",
    "scripts/roadmap-parser/utils/export",
    "scripts/roadmap-parser/utils/import",
    "scripts/roadmap-parser/utils/helpers",
    "scripts/roadmap-parser/analysis",
    "scripts/roadmap-parser/analysis/dependencies",
    "scripts/roadmap-parser/analysis/performance",
    "scripts/roadmap-parser/analysis/validation",
    "scripts/roadmap-parser/analysis/reporting",
    "scripts/roadmap-parser/tests",
    "scripts/roadmap-parser/tests/unit",
    "scripts/roadmap-parser/tests/integration",
    "scripts/roadmap-parser/tests/performance",
    "scripts/roadmap-parser/tests/validation",
    "scripts/roadmap-parser/docs",
    "scripts/roadmap-parser/docs/examples",
    "scripts/roadmap-parser/docs/guides",
    "scripts/roadmap-parser/docs/api",
    "scripts/maintenance",
    "scripts/maintenance/organize",
    "scripts/maintenance/cleanup",
    "scripts/maintenance/migrate",
    "scripts/maintenance/docs",
    "scripts/maintenance/backups",
    "scripts/maintenance/logs",
    "docs",
    "docs/guides",
    "docs/guides/best-practices",
    "docs/guides/core",
    "docs/guides/git",
    "docs/guides/installation",
    "docs/guides/mcp",
    "docs/guides/methodologies",
    "docs/guides/n8n",
    "docs/guides/powershell",
    "docs/guides/python",
    "docs/guides/tools",
    "docs/guides/troubleshooting",
    "Roadmap",
    "Roadmap/mes-plans",
    "templates",
    "templates/reports",
    "_templates",
    "_templates/roadmap",
    "_templates/roadmap-parser",
    "_templates/maintenance"
)

# CrÃ©er les dossiers
foreach ($folder in $folders) {
    $folderPath = Join-Path -Path $repoRoot -ChildPath $folder
    
    if (-not (Test-Path -Path $folderPath)) {
        if ($DryRun) {
            Write-Log "[DRYRUN] CrÃ©ation du dossier : $folderPath"
        } else {
            if ($PSCmdlet.ShouldProcess($folderPath, "CrÃ©er le dossier")) {
                New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                Write-Log "Dossier crÃ©Ã© : $folderPath"
            }
        }
    } else {
        Write-Log "Le dossier existe dÃ©jÃ  : $folderPath"
    }
}

# DÃ©finir les mappages de fichiers vers les nouveaux emplacements
$fileMappings = @{
    # Scripts de mode
    "scripts/*-mode.ps1" = "scripts/roadmap-parser/modes/{0}/{0}-mode.ps1"
    "scripts/Test-GranModeComplete.ps1" = "scripts/roadmap-parser/modes/gran/Test-GranModeComplete.ps1"
    
    # Scripts de maintenance
    "scripts/cleanup-*.ps1" = "scripts/maintenance/cleanup/{0}"
    "scripts/organize-*.ps1" = "scripts/maintenance/organize/{0}"
    "scripts/migrate-*.ps1" = "scripts/maintenance/migrate/{0}"
    
    # Documentation
    "docs/guides/mode_*.md" = "docs/guides/methodologies/mode_{0}.md"
    "docs/guides/programmation_*.md" = "docs/guides/methodologies/programmation_{0}.md"
    
    # Templates
    "templates/*.ejs.t" = "_templates/roadmap/{0}"
    "templates/roadmap-parser/*.ejs.t" = "_templates/roadmap-parser/{0}"
    "templates/maintenance/*.ejs.t" = "_templates/maintenance/{0}"
}

# Fonction pour dÃ©placer un fichier
function Move-FileToNewLocation {
    param (
        [string]$SourceFile,
        [string]$DestinationPath
    )
    
    if (-not (Test-Path -Path $SourceFile)) {
        Write-Log "Le fichier source n'existe pas : $SourceFile"
        return
    }
    
    $destinationDir = Split-Path -Path $DestinationPath -Parent
    if (-not (Test-Path -Path $destinationDir)) {
        if ($DryRun) {
            Write-Log "[DRYRUN] CrÃ©ation du rÃ©pertoire : $destinationDir"
        } else {
            if ($PSCmdlet.ShouldProcess($destinationDir, "CrÃ©er le rÃ©pertoire")) {
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                Write-Log "RÃ©pertoire crÃ©Ã© : $destinationDir"
            }
        }
    }
    
    if (Test-Path -Path $DestinationPath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe dÃ©jÃ  : $DestinationPath. Voulez-vous le remplacer ?", "Confirmation")
        }
    } else {
        $shouldContinue = $true
    }
    
    if ($shouldContinue) {
        if ($DryRun) {
            Write-Log "[DRYRUN] DÃ©placement du fichier : $SourceFile -> $DestinationPath"
        } else {
            if ($PSCmdlet.ShouldProcess($SourceFile, "DÃ©placer vers $DestinationPath")) {
                Copy-Item -Path $SourceFile -Destination $DestinationPath -Force
                Write-Log "Fichier dÃ©placÃ© : $SourceFile -> $DestinationPath"
            }
        }
    } else {
        Write-Log "DÃ©placement ignorÃ© : $SourceFile"
    }
}

# Parcourir les mappages de fichiers
foreach ($pattern in $fileMappings.Keys) {
    $files = Get-ChildItem -Path (Join-Path -Path $repoRoot -ChildPath $pattern) -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $fileName = $file.Name
        $baseName = $file.BaseName
        
        # Extraire le nom du mode Ã  partir du nom du fichier
        if ($fileName -match "^([a-zA-Z0-9-]+)-mode\.ps1$") {
            $modeName = $matches[1]
            $destinationPath = Join-Path -Path $repoRoot -ChildPath ($fileMappings[$pattern] -f $modeName)
        } else {
            $destinationPath = Join-Path -Path $repoRoot -ChildPath ($fileMappings[$pattern] -f $fileName)
        }
        
        Move-FileToNewLocation -SourceFile $file.FullName -DestinationPath $destinationPath
    }
}

# RÃ©sumÃ© de l'organisation
Write-Host "Organisation terminÃ©e." -ForegroundColor Cyan

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Organisation terminÃ©e le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log d'organisation enregistrÃ© dans : $LogFile" -ForegroundColor Cyan
}
