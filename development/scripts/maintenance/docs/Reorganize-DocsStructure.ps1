#Requires -Version 5.1
<#
.SYNOPSIS
    RÃ©organise la structure du dossier docs pour Ã©liminer les redondances et amÃ©liorer l'arborescence
.DESCRIPTION
    Ce script rÃ©organise les fichiers du dossier docs en Ã©liminant les redondances,
    en rÃ©duisant le nombre de sous-dossiers et en crÃ©ant une arborescence plus claire.
.PARAMETER Path
    Chemin du dossier docs Ã  rÃ©organiser
.PARAMETER LogPath
    Chemin oÃ¹ gÃ©nÃ©rer le journal des dÃ©placements
.PARAMETER DryRun
    Indique si le script doit simuler les dÃ©placements sans les effectuer
.PARAMETER Force
    Indique si le script doit forcer la rÃ©organisation mÃªme en cas de conflits
.EXAMPLE
    .\Reorganize-DocsStructure.ps1 -Path "D:\Repos\EMAIL_SENDER_1\docs" -DryRun
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-26
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Join-Path -Path (Get-Location).Path -ChildPath "docs"),

    [Parameter(Mandatory = $false)]
    [string]$LogPath = (Join-Path -Path (Get-Location).Path -ChildPath "logs\docs-reorganization-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"),

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour Ã©crire dans le journal
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Ajouter au fichier journal
    Add-Content -Path $logFilePath -Value $logMessage -Encoding UTF8

    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Gray }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Fonction pour dÃ©placer un fichier vers un dossier de destination
function Move-FileToDestination {
    param (
        [string]$SourcePath,
        [string]$DestinationFolder,
        [switch]$Force
    )

    $fileName = Split-Path -Leaf $SourcePath
    $destinationPath = Join-Path -Path $DestinationFolder -ChildPath $fileName

    # CrÃ©er le dossier de destination s'il n'existe pas
    if (-not (Test-Path -Path $DestinationFolder)) {
        if ($PSCmdlet.ShouldProcess($DestinationFolder, "CrÃ©er le dossier")) {
            New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
        }
    }

    # VÃ©rifier si le fichier existe dÃ©jÃ  Ã  la destination
    if (Test-Path -Path $destinationPath) {
        if (-not $Force) {
            Write-Log -Message "Le fichier existe dÃ©jÃ  Ã  la destination: $destinationPath" -Level "WARNING"
            return $false
        }

        # Comparer les fichiers
        $sourceHash = Get-FileHash -Path $SourcePath -Algorithm SHA256
        $destHash = Get-FileHash -Path $destinationPath -Algorithm SHA256

        if ($sourceHash.Hash -eq $destHash.Hash) {
            Write-Log -Message "Le fichier est identique Ã  la destination, suppression de la source: $SourcePath" -Level "INFO"

            if ($PSCmdlet.ShouldProcess($SourcePath, "Supprimer le fichier source (identique Ã  la destination)")) {
                Remove-Item -Path $SourcePath -Force
            }

            return $true
        }

        # Renommer le fichier de destination avec un suffixe
        $newName = [System.IO.Path]::GetFileNameWithoutExtension($fileName) + "_old" + [System.IO.Path]::GetExtension($fileName)
        $renamedDestination = Join-Path -Path $DestinationFolder -ChildPath $newName

        Write-Log -Message "Conflit dÃ©tectÃ©, renommage du fichier de destination: $destinationPath -> $renamedDestination" -Level "WARNING"

        if ($PSCmdlet.ShouldProcess($destinationPath, "Renommer en $newName")) {
            Rename-Item -Path $destinationPath -NewName $newName -Force
        }
    }

    # DÃ©placer le fichier
    Write-Log -Message "DÃ©placement: $SourcePath -> $destinationPath" -Level "INFO"

    if ($PSCmdlet.ShouldProcess($SourcePath, "DÃ©placer vers $destinationPath")) {
        Move-Item -Path $SourcePath -Destination $destinationPath -Force
    }

    return $true
}

# Fonction pour crÃ©er la structure de dossiers
function New-FolderStructure {
    # DÃ©finition des dossiers principaux
    $mainFolders = @(
        "api",
        "architecture",
        "guides",
        "reference",
        "tutorials",
        "development",
        "assets"
    )

    # DÃ©finition des sous-dossiers
    $subFolders = @{
        "api"          = @(
            "api\rest",
            "api\graphql",
            "api\examples"
        )
        "architecture" = @(
            "architecture\diagrams",
            "architecture\decisions",
            "architecture\patterns"
        )
        "guides"       = @(
            "guides\best-practices",
            "guides\core",
            "guides\git",
            "guides\installation",
            "guides\mcp",
            "guides\methodologies",
            "guides\methodologies\modes",
            "guides\n8n",
            "guides\powershell",
            "guides\python",
            "guides\tools",
            "guides\troubleshooting"
        )
        "reference"    = @(
            "reference\configuration",
            "reference\scripts",
            "reference\modules"
        )
        "tutorials"    = @(
            "tutorials\getting-started",
            "tutorials\advanced"
        )
        "development"  = @(
            "development\roadmap",
            "development\testing",
            "development\workflows"
        )
        "assets"       = @(
            "assets\images",
            "assets\templates"
        )
    }

    # CrÃ©er les dossiers principaux
    foreach ($folder in $mainFolders) {
        $folderPath = Join-Path -Path $Path -ChildPath $folder
        if (-not (Test-Path -Path $folderPath -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($folderPath, "CrÃ©er le dossier")) {
                New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
            }
            Write-Log -Message "Dossier crÃ©Ã©: $folder" -Level "SUCCESS"
        }
    }

    # CrÃ©er les sous-dossiers
    foreach ($mainFolder in $subFolders.Keys) {
        foreach ($subFolder in $subFolders[$mainFolder]) {
            $folderPath = Join-Path -Path $Path -ChildPath $subFolder
            if (-not (Test-Path -Path $folderPath -PathType Container)) {
                if ($PSCmdlet.ShouldProcess($folderPath, "CrÃ©er le sous-dossier")) {
                    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                }
                Write-Log -Message "Sous-dossier crÃ©Ã©: $subFolder" -Level "SUCCESS"
            }
        }
    }
}

# Fonction pour migrer les fichiers de documentation
function Move-DocumentationFiles {
    # RÃ¨gles de migration pour les dossiers redondants
    $migrationRules = @{
        "documentation"           = "guides"
        "documentation\api"       = "api"
        "documentation\technique" = "architecture"
        "documentation\workflow"  = "development\workflows"
        "journal_de_bord"         = "development\roadmap\journal"
        "journal"                 = "development\roadmap\journal"
        "roadmap"                 = "development\roadmap"
        "project-management"      = "development\roadmap"
        "specifications"          = "architecture\decisions"
        "conception"              = "architecture"
        "technical"               = "architecture"
        "user-guides"             = "guides"
        "md"                      = "guides"
        "references"              = "reference"
        "reference"               = "reference"
        "plans"                   = "development\roadmap\plans"
        "error_reports"           = "development\testing\reports"
        "test_reports"            = "development\testing\reports"
        "testing"                 = "development\testing"
        "analytics"               = "development\testing\analytics"
        "analysis"                = "development\testing\analytics"
        "performance"             = "development\testing\performance"
        "visualizations"          = "assets\visualizations"
        "visualization"           = "assets\visualizations"
        "ui"                      = "assets\ui"
        "integrations"            = "guides\integrations"
        "n8n"                     = "guides\n8n"
        "mcp"                     = "guides\mcp"
        "workflows"               = "development\workflows"
        "Examples"                = "tutorials\examples"
        "Augment"                 = "guides\augment"
        "communications"          = "development\communications"
        "archives"                = "development\archives"
    }

    # Traiter chaque dossier source
    foreach ($sourceFolder in $migrationRules.Keys) {
        $sourcePath = Join-Path -Path $Path -ChildPath $sourceFolder
        $destinationFolder = Join-Path -Path $Path -ChildPath $migrationRules[$sourceFolder]

        # VÃ©rifier si le dossier source existe
        if (Test-Path -Path $sourcePath -PathType Container) {
            Write-Log -Message "Traitement du dossier: $sourceFolder -> $($migrationRules[$sourceFolder])" -Level "INFO"

            # CrÃ©er le dossier de destination s'il n'existe pas
            if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
                if ($PSCmdlet.ShouldProcess($destinationFolder, "CrÃ©er le dossier de destination")) {
                    New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
                }
            }

            # Obtenir tous les fichiers du dossier source
            $files = Get-ChildItem -Path $sourcePath -File -Recurse

            foreach ($file in $files) {
                # DÃ©terminer le chemin relatif du fichier par rapport au dossier source
                $relativePath = $file.FullName.Substring($sourcePath.Length + 1)
                $relativeDir = Split-Path -Path $relativePath -Parent

                # Construire le chemin de destination
                $destDir = if ([string]::IsNullOrEmpty($relativeDir)) {
                    $destinationFolder
                } else {
                    Join-Path -Path $destinationFolder -ChildPath $relativeDir
                }

                # DÃ©placer le fichier
                Move-FileToDestination -SourcePath $file.FullName -DestinationFolder $destDir -Force:$Force
            }
        }
    }
}

# Fonction pour nettoyer les dossiers vides
function Clear-EmptyFolders {
    $emptyFolders = @()
    $foldersToExclude = @("_build", ".git", "node_modules")

    # Obtenir tous les dossiers
    $allFolders = Get-ChildItem -Path $Path -Directory -Recurse | Where-Object {
        $foldersToExclude -notcontains $_.Name
    } | Sort-Object -Property FullName -Descending

    foreach ($folder in $allFolders) {
        $items = Get-ChildItem -Path $folder.FullName -Force

        if ($null -eq $items -or $items.Count -eq 0) {
            $emptyFolders += $folder.FullName

            Write-Log -Message "Dossier vide dÃ©tectÃ©: $($folder.FullName)" -Level "INFO"

            if ($PSCmdlet.ShouldProcess($folder.FullName, "Supprimer le dossier vide")) {
                Remove-Item -Path $folder.FullName -Force
            }
        }
    }

    Write-Log -Message "Nettoyage terminÃ©: $($emptyFolders.Count) dossiers vides supprimÃ©s" -Level "SUCCESS"
}

# Fonction pour crÃ©er des fichiers index.md dans chaque dossier
function New-IndexFiles {
    # Obtenir tous les dossiers
    $allFolders = Get-ChildItem -Path $Path -Directory -Recurse | Where-Object {
        $_.Name -ne "_build" -and $_.Name -ne ".git" -and $_.Name -ne "node_modules"
    }

    foreach ($folder in $allFolders) {
        $indexPath = Join-Path -Path $folder.FullName -ChildPath "index.md"

        # VÃ©rifier si le fichier index.md existe dÃ©jÃ 
        if (-not (Test-Path -Path $indexPath)) {
            $folderName = $folder.Name
            $folderTitle = (Get-Culture).TextInfo.ToTitleCase($folderName.Replace("-", " "))

            $content = @"
# $folderTitle

Cette section contient la documentation relative Ã  $folderTitle.

## Contenu

"@

            # Ajouter les liens vers les fichiers du dossier
            $files = Get-ChildItem -Path $folder.FullName -File | Where-Object { $_.Name -ne "index.md" }

            if ($files.Count -gt 0) {
                $content += "`n`n### Fichiers`n"

                foreach ($file in $files) {
                    $fileName = $file.Name
                    $fileTitle = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
                    $fileTitle = $fileTitle.Replace("-", " ").Replace("_", " ")
                    $fileTitle = (Get-Culture).TextInfo.ToTitleCase($fileTitle)

                    $content += "`n- [$fileTitle](./$fileName)"
                }
            }

            # Ajouter les liens vers les sous-dossiers
            $subFolders = Get-ChildItem -Path $folder.FullName -Directory

            if ($subFolders.Count -gt 0) {
                $content += "`n`n### Sous-sections`n"

                foreach ($subFolder in $subFolders) {
                    $subFolderName = $subFolder.Name
                    $subFolderTitle = (Get-Culture).TextInfo.ToTitleCase($subFolderName.Replace("-", " "))

                    $content += "`n- [$subFolderTitle](./$subFolderName/)"
                }
            }

            # Ã‰crire le fichier index.md
            if ($PSCmdlet.ShouldProcess($indexPath, "CrÃ©er le fichier index.md")) {
                Set-Content -Path $indexPath -Value $content -Encoding UTF8
            }

            Write-Log -Message "Fichier index crÃ©Ã©: $indexPath" -Level "SUCCESS"
        }
    }
}

# Fonction principale
function Main {
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "Le chemin spÃ©cifiÃ© n'existe pas: $Path"
        exit 1
    }

    # CrÃ©er le dossier de logs s'il n'existe pas
    $logDir = Split-Path -Path $LogPath -Parent

    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # Chemin complet du fichier journal
    $script:logFilePath = $LogPath

    # Afficher le mode d'exÃ©cution
    if ($DryRun) {
        Write-Log -Message "Mode simulation activÃ©. Aucune modification ne sera effectuÃ©e." -Level "WARNING"
    }

    # CrÃ©er la structure de dossiers
    Write-Log -Message "CrÃ©ation de la structure de dossiers..." -Level "INFO"
    New-FolderStructure

    # Migrer les fichiers
    Write-Log -Message "Migration des fichiers..." -Level "INFO"
    Move-DocumentationFiles

    # Nettoyer les dossiers vides
    Write-Log -Message "Nettoyage des dossiers vides..." -Level "INFO"
    Clear-EmptyFolders

    # CrÃ©er les fichiers index.md
    Write-Log -Message "CrÃ©ation des fichiers index.md..." -Level "INFO"
    New-IndexFiles

    # Afficher le rÃ©sumÃ©
    Write-Log -Message "RÃ©organisation de la documentation terminÃ©e." -Level "SUCCESS"
    Write-Log -Message "Journal des opÃ©rations: $logFilePath" -Level "INFO"
}

# ExÃ©cuter la fonction principale
try {
    Main
} catch {
    Write-Log -Message "Erreur lors de la rÃ©organisation de la documentation: $_" -Level "ERROR"
    exit 1
}


