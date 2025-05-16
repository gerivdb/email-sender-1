﻿# Get-RoadmapFiles.ps1
# Script pour parcourir les dossiers de roadmap et inventorier les fichiers
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$Directories = @(
        "projet/roadmaps",
        "development/roadmap"
    ),

    [Parameter(Mandatory = $false)]
    [string[]]$FileExtensions = @(".md"),

    [Parameter(Mandatory = $false)]
    [switch]$IncludeContent,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeMetadata,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Object")]
    [string]$OutputFormat = "Object"
)

# Importer le module de journalisation s'il existe
if (Test-Path -Path "$PSScriptRoot\..\utils\Write-Log.ps1") {
    . "$PSScriptRoot\..\utils\Write-Log.ps1"
} else {
    function Write-Log {
        param (
            [string]$Message,
            [ValidateSet("Info", "Warning", "Error", "Success")]
            [string]$Level = "Info"
        )

        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
        }

        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour extraire les métadonnées d'un fichier markdown
function Get-MarkdownMetadata {
    param (
        [string]$FilePath
    )

    $metadata = @{
        Title              = ""
        CreationDate       = $null
        ModificationDate   = $null
        TaskCount          = 0
        CompletedTaskCount = 0
        CompletionRate     = 0
        Sections           = @()
    }

    try {
        # Obtenir les dates de création et modification
        $fileInfo = Get-Item -Path $FilePath
        $metadata.CreationDate = $fileInfo.CreationTime
        $metadata.ModificationDate = $fileInfo.LastWriteTime

        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw

        # Extraire le titre (première ligne commençant par #)
        if ($content -match "^#\s+(.+)$") {
            $metadata.Title = $Matches[1].Trim()
        }

        # Compter les tâches (lignes avec cases à cocher)
        $taskMatches = [regex]::Matches($content, "\s*[-*+]\s*\[([ xX])\]")
        $metadata.TaskCount = $taskMatches.Count

        # Compter les tâches terminées (cases cochées)
        $completedMatches = [regex]::Matches($content, "\s*[-*+]\s*\[[xX]\]")
        $metadata.CompletedTaskCount = $completedMatches.Count

        # Calculer le taux de complétion
        if ($metadata.TaskCount -gt 0) {
            $metadata.CompletionRate = [math]::Round(($metadata.CompletedTaskCount / $metadata.TaskCount) * 100, 2)
        }

        # Extraire les sections (lignes commençant par ##)
        $sectionMatches = [regex]::Matches($content, "^##\s+(.+)$")
        foreach ($match in $sectionMatches) {
            $metadata.Sections += $match.Groups[1].Value.Trim()
        }
    } catch {
        Write-Log "Erreur lors de l'extraction des métadonnées de $FilePath : $_" -Level Error
    }

    return $metadata
}

# Fonction principale pour parcourir les dossiers et inventorier les fichiers
function Get-RoadmapFiles {
    [CmdletBinding()]
    param (
        [string[]]$Directories,
        [string[]]$FileExtensions,
        [switch]$IncludeContent,
        [switch]$IncludeMetadata
    )

    $results = @()

    foreach ($directory in $Directories) {
        Write-Log "Parcours du dossier $directory..." -Level Info

        if (-not (Test-Path -Path $directory)) {
            Write-Log "Le dossier $directory n'existe pas." -Level Warning
            continue
        }

        # Récupérer tous les fichiers avec les extensions spécifiées
        $files = Get-ChildItem -Path $directory -Recurse -File | Where-Object {
            $FileExtensions -contains $_.Extension
        }

        Write-Log "Trouvé $($files.Count) fichiers dans $directory" -Level Info

        foreach ($file in $files) {
            $fileInfo = [PSCustomObject]@{
                Path          = $file.FullName
                RelativePath  = $file.FullName.Replace((Get-Location).Path + "\", "")
                Name          = $file.Name
                Extension     = $file.Extension
                Directory     = $file.DirectoryName
                Size          = $file.Length
                CreationTime  = $file.CreationTime
                LastWriteTime = $file.LastWriteTime
                Content       = if ($IncludeContent) { Get-Content -Path $file.FullName -Raw } else { $null }
                Metadata      = if ($IncludeMetadata) { Get-MarkdownMetadata -FilePath $file.FullName } else { $null }
            }

            $results += $fileInfo
        }
    }

    return $results
}

# Fonction pour exporter les résultats
function Export-Results {
    param (
        [array]$Results,
        [string]$OutputPath,
        [string]$Format
    )

    switch ($Format) {
        "JSON" {
            $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Log "Résultats exportés au format JSON dans $OutputPath" -Level Success
        }
        "CSV" {
            # Aplatir les objets pour le CSV
            $flatResults = $Results | ForEach-Object {
                $obj = [PSCustomObject]@{
                    Path          = $_.Path
                    RelativePath  = $_.RelativePath
                    Name          = $_.Name
                    Extension     = $_.Extension
                    Directory     = $_.Directory
                    Size          = $_.Size
                    CreationTime  = $_.CreationTime
                    LastWriteTime = $_.LastWriteTime
                }

                if ($_.Metadata) {
                    $obj | Add-Member -NotePropertyName Title -NotePropertyValue $_.Metadata.Title
                    $obj | Add-Member -NotePropertyName TaskCount -NotePropertyValue $_.Metadata.TaskCount
                    $obj | Add-Member -NotePropertyName CompletedTaskCount -NotePropertyValue $_.Metadata.CompletedTaskCount
                    $obj | Add-Member -NotePropertyName CompletionRate -NotePropertyValue $_.Metadata.CompletionRate
                    $obj | Add-Member -NotePropertyName Sections -NotePropertyValue ($_.Metadata.Sections -join "; ")
                }

                return $obj
            }

            $flatResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            Write-Log "Résultats exportés au format CSV dans $OutputPath" -Level Success
        }
    }
}

# Exécution principale
try {
    Write-Log "Démarrage de l'inventaire des fichiers de roadmap..." -Level Info

    $roadmapFiles = Get-RoadmapFiles -Directories $Directories -FileExtensions $FileExtensions -IncludeContent:$IncludeContent -IncludeMetadata:$IncludeMetadata

    Write-Log "Inventaire terminé. $($roadmapFiles.Count) fichiers trouvés au total." -Level Success

    # Exporter les résultats si demandé
    if ($OutputPath) {
        Export-Results -Results $roadmapFiles -OutputPath $OutputPath -Format $OutputFormat
    }

    # Retourner les résultats
    if ($OutputFormat -eq "Object" -or -not $OutputPath) {
        return $roadmapFiles
    }
} catch {
    Write-Log "Erreur lors de l'inventaire des fichiers : $_" -Level Error
    throw $_
}
