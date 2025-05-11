﻿# Invoke-RoadmapChangeAnalysis.ps1
# Script pour analyser les changements dans les roadmaps et les intégrer au système RAG
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet/roadmaps/active/roadmap_active.md",

    [Parameter(Mandatory = $false)]
    [string]$PreviousVersionPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/analysis",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "JSON", "Markdown", "HTML", "All")]
    [string]$OutputFormat = "All",

    [Parameter(Mandatory = $false)]
    [string]$SnapshotDirectory = "projet/roadmaps/snapshots",

    [Parameter(Mandatory = $false)]
    [switch]$CreateSnapshot,

    [Parameter(Mandatory = $false)]
    [switch]$UpdateVectors,

    [Parameter(Mandatory = $false)]
    [switch]$Detailed,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"
$commonPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "common"

# Importer les fonctions utilitaires
. (Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1")
. (Join-Path -Path $utilsPath -ChildPath "Parse-Markdown.ps1")
. (Join-Path -Path $utilsPath -ChildPath "Format-Output.ps1")

# Importer le script de détection des changements
$detectChangesScript = Join-Path -Path $scriptPath -ChildPath "Detect-RoadmapChanges.ps1"
. $detectChangesScript

# Fonction pour créer le répertoire de sortie
function New-OutputDirectory {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )

    if (-not (Test-Path -Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        Write-Log "Répertoire de sortie créé: $OutputDirectory" -Level Info
    }

    return $OutputDirectory
}

# Fonction pour générer un rapport de changements dans tous les formats
function New-ChangeReport {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Changes,

        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "Markdown", "HTML", "All")]
        [string]$Format = "All",

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reports = @{}

    if ($Format -eq "All" -or $Format -eq "Text") {
        $textPath = Join-Path -Path $OutputDirectory -ChildPath "changes_$timestamp.txt"
        $textContent = Format-ChangesAsText -Changes $Changes -Detailed:$Detailed
        $textContent | Out-File -FilePath $textPath -Encoding UTF8
        $reports["Text"] = $textPath
        Write-Log "Rapport de changements au format texte créé: $textPath" -Level Success
    }

    if ($Format -eq "All" -or $Format -eq "JSON") {
        $jsonPath = Join-Path -Path $OutputDirectory -ChildPath "changes_$timestamp.json"
        $jsonContent = Format-ChangesAsJson -Changes $Changes -Detailed:$Detailed
        $jsonContent | Out-File -FilePath $jsonPath -Encoding UTF8
        $reports["JSON"] = $jsonPath
        Write-Log "Rapport de changements au format JSON créé: $jsonPath" -Level Success
    }

    if ($Format -eq "All" -or $Format -eq "Markdown") {
        $markdownPath = Join-Path -Path $OutputDirectory -ChildPath "changes_$timestamp.md"
        $markdownContent = Format-ChangesAsMarkdown -Changes $Changes -Detailed:$Detailed
        $markdownContent | Out-File -FilePath $markdownPath -Encoding UTF8
        $reports["Markdown"] = $markdownPath
        Write-Log "Rapport de changements au format Markdown créé: $markdownPath" -Level Success
    }

    if ($Format -eq "All" -or $Format -eq "HTML") {
        $htmlPath = Join-Path -Path $OutputDirectory -ChildPath "changes_$timestamp.html"
        $htmlContent = Format-ChangesAsHtml -Changes $Changes -Detailed:$Detailed
        $htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
        $reports["HTML"] = $htmlPath
        Write-Log "Rapport de changements au format HTML créé: $htmlPath" -Level Success
    }

    return $reports
}

# Fonction pour mettre à jour les vecteurs dans Qdrant
function Update-RoadmapVectors {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Changes
    )

    # Vérifier si le script de synchronisation des vecteurs existe
    $vectorSyncScript = Join-Path -Path $scriptPath -ChildPath "Invoke-RoadmapVectorSync.ps1"

    if (Test-Path -Path $vectorSyncScript) {
        Write-Log "Mise à jour des vecteurs pour la roadmap: $RoadmapPath" -Level Info

        # Construire les arguments pour le script de synchronisation
        $arguments = @{
            RoadmapPath = $RoadmapPath
            Force       = $true
        }

        # Si des tâches ont été modifiées, ajouter leurs IDs comme paramètre
        if ($Changes.StatusChanged.Count -gt 0 -or $Changes.ContentChanged.Count -gt 0) {
            $modifiedTaskIds = @()

            foreach ($change in $Changes.StatusChanged) {
                $modifiedTaskIds += $change.Task.Id
            }

            foreach ($change in $Changes.ContentChanged) {
                $modifiedTaskIds += $change.Task.Id
            }

            $arguments["TaskIds"] = $modifiedTaskIds | Select-Object -Unique
        }

        # Exécuter le script de synchronisation
        & $vectorSyncScript @arguments

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Mise à jour des vecteurs réussie" -Level Success
            return $true
        } else {
            Write-Log "Échec de la mise à jour des vecteurs (code: $LASTEXITCODE)" -Level Error
            return $false
        }
    } else {
        Write-Log "Script de synchronisation des vecteurs non trouvé: $vectorSyncScript" -Level Warning
        return $false
    }
}

# Fonction principale
function Invoke-RoadmapChangeAnalysis {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$PreviousVersionPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputDirectory,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "JSON", "Markdown", "HTML", "All")]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [string]$SnapshotDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$CreateSnapshot,

        [Parameter(Mandatory = $false)]
        [switch]$UpdateVectors,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Fichier de roadmap non trouvé: $RoadmapPath" -Level Error
        return $false
    }

    # Créer le répertoire de sortie
    $outputDir = New-OutputDirectory -OutputDirectory $OutputDirectory

    # Détecter les changements
    Write-Log "Détection des changements dans la roadmap: $RoadmapPath" -Level Info

    $detectChangesParams = @{
        RoadmapPath       = $RoadmapPath
        SnapshotDirectory = $SnapshotDirectory
        CreateSnapshot    = $CreateSnapshot
        Detailed          = $Detailed
        Force             = $Force
    }

    if ($PreviousVersionPath) {
        $detectChangesParams["PreviousVersionPath"] = $PreviousVersionPath
    }

    $changes = Invoke-RoadmapChangeDetection @detectChangesParams

    if (-not $changes) {
        Write-Log "Aucun changement détecté dans la roadmap" -Level Info
        return $false
    }

    # Générer les rapports de changements
    $reports = New-ChangeReport -Changes $changes -OutputDirectory $outputDir -Format $OutputFormat -Detailed:$Detailed

    # Mettre à jour les vecteurs si demandé
    if ($UpdateVectors) {
        $vectorUpdateResult = Update-RoadmapVectors -RoadmapPath $RoadmapPath -Changes $changes
    }

    # Retourner les résultats
    return @{
        HasChanges     = $true
        Changes        = $changes
        Reports        = $reports
        VectorsUpdated = if ($UpdateVectors) { $vectorUpdateResult } else { $null }
    }
}

# Exécution principale
try {
    $result = Invoke-RoadmapChangeAnalysis -RoadmapPath $RoadmapPath -PreviousVersionPath $PreviousVersionPath `
        -OutputDirectory $OutputDirectory -OutputFormat $OutputFormat `
        -SnapshotDirectory $SnapshotDirectory -CreateSnapshot:$CreateSnapshot `
        -UpdateVectors:$UpdateVectors -Detailed:$Detailed -Force:$Force

    if ($result.HasChanges) {
        Write-Log "Analyse des changements terminée avec succès" -Level Success
        exit 0
    } else {
        Write-Log "Aucun changement détecté" -Level Info
        exit 1
    }
} catch {
    Write-Log "Erreur lors de l'analyse des changements: $_" -Level Error
    exit 2
}
