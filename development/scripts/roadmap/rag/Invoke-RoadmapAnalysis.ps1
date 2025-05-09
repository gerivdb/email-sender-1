﻿# Invoke-RoadmapAnalysis.ps1
# Script principal pour analyser la structure des roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "Inventory", "Analyze", "FindDuplicates",
        "All"
    )]
    [string]$Action = "All",

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{},

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/analysis",

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Object")]
    [string]$OutputFormat = "JSON",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer le module de journalisation
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

# Fonction pour afficher l'aide
function Show-Help {
    Write-Host "Invoke-RoadmapAnalysis.ps1 - Script d'analyse des roadmaps"
    Write-Host ""
    Write-Host "SYNTAXE:"
    Write-Host "    .\Invoke-RoadmapAnalysis.ps1 -Action <Action> [-Parameters <Hashtable>] [-OutputDirectory <String>] [-OutputFormat <String>] [-Force]"
    Write-Host ""
    Write-Host "ACTIONS:"
    Write-Host "    Inventory       : Inventorie tous les fichiers de roadmap"
    Write-Host "    Analyze         : Analyse la structure des fichiers de roadmap"
    Write-Host "    FindDuplicates  : Identifie les doublons et versions obsolètes"
    Write-Host "    All             : Exécute toutes les actions dans l'ordre"
    Write-Host ""
    Write-Host "PARAMÈTRES:"
    Write-Host "    -Parameters     : Hashtable de paramètres spécifiques à l'action"
    Write-Host "    -OutputDirectory: Dossier de sortie pour les résultats"
    Write-Host "    -OutputFormat   : Format de sortie (JSON, CSV, Object)"
    Write-Host "    -Force          : Force l'écrasement des fichiers existants"
    Write-Host ""
    Write-Host "EXEMPLES:"
    Write-Host "    # Inventorier tous les fichiers de roadmap"
    Write-Host "    .\Invoke-RoadmapAnalysis.ps1 -Action Inventory -OutputDirectory 'projet/roadmaps/analysis'"
    Write-Host ""
    Write-Host "    # Analyser la structure des fichiers de roadmap"
    Write-Host "    .\Invoke-RoadmapAnalysis.ps1 -Action Analyze -Parameters @{"
    Write-Host "        InputPath = 'projet/roadmaps/analysis/inventory.json'"
    Write-Host "    }"
    Write-Host ""
    Write-Host "    # Identifier les doublons et versions obsolètes"
    Write-Host "    .\Invoke-RoadmapAnalysis.ps1 -Action FindDuplicates -Parameters @{"
    Write-Host "        InputPath = 'projet/roadmaps/analysis/inventory.json'"
    Write-Host "        SimilarityThreshold = 0.8"
    Write-Host "    }"
    Write-Host ""
    Write-Host "    # Exécuter toutes les actions"
    Write-Host "    .\Invoke-RoadmapAnalysis.ps1 -Action All -OutputDirectory 'projet/roadmaps/analysis' -Force"
}

# Fonction pour créer le dossier de sortie
function Initialize-OutputDirectory {
    param (
        [string]$Directory,
        [switch]$Force
    )

    if (-not (Test-Path -Path $Directory)) {
        Write-Log "Création du dossier de sortie $Directory..." -Level Info
        New-Item -Path $Directory -ItemType Directory -Force | Out-Null
    } elseif ($Force) {
        Write-Log "Le dossier de sortie $Directory existe déjà. Les fichiers existants seront écrasés." -Level Warning
    } else {
        Write-Log "Le dossier de sortie $Directory existe déjà." -Level Info
    }
}

# Fonction pour exécuter l'inventaire des fichiers
function Invoke-Inventory {
    param (
        [hashtable]$Params,
        [string]$OutputDir,
        [string]$Format,
        [switch]$Force
    )

    Write-Log "Démarrage de l'inventaire des fichiers de roadmap..." -Level Info

    # Définir les paramètres par défaut
    $defaultParams = @{
        Directories     = @("projet/roadmaps", "development/roadmap")
        FileExtensions  = @(".md")
        IncludeContent  = $true
        IncludeMetadata = $true
        OutputPath      = "$OutputDir/inventory.$($Format.ToLower())"
        OutputFormat    = $Format
    }

    # Fusionner avec les paramètres fournis
    $mergedParams = $defaultParams.Clone()
    foreach ($key in $Params.Keys) {
        $mergedParams[$key] = $Params[$key]
    }

    # Vérifier si le fichier de sortie existe déjà
    if ((Test-Path -Path $mergedParams.OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie $($mergedParams.OutputPath) existe déjà. Utilisez -Force pour l'écraser." -Level Warning
        return $null
    }

    # Exécuter le script d'inventaire
    $scriptPath = "$PSScriptRoot\Get-RoadmapFiles.ps1"
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Log "Le script $scriptPath n'existe pas." -Level Error
        return $null
    }

    $result = & $scriptPath @mergedParams

    Write-Log "Inventaire terminé. Résultats enregistrés dans $($mergedParams.OutputPath)" -Level Success

    return $mergedParams.OutputPath
}

# Fonction pour exécuter l'analyse de structure
function Invoke-StructureAnalysis {
    param (
        [hashtable]$Params,
        [string]$OutputDir,
        [string]$Format,
        [switch]$Force
    )

    Write-Log "Démarrage de l'analyse de la structure des fichiers de roadmap..." -Level Info

    # Définir les paramètres par défaut
    $defaultParams = @{
        OutputPath   = "$OutputDir/structure_analysis.$($Format.ToLower())"
        OutputFormat = $Format
    }

    # Fusionner avec les paramètres fournis
    $mergedParams = $defaultParams.Clone()
    foreach ($key in $Params.Keys) {
        $mergedParams[$key] = $Params[$key]
    }

    # Vérifier si le fichier d'entrée est spécifié
    if (-not $mergedParams.ContainsKey("InputPath") -and -not $mergedParams.ContainsKey("RoadmapFiles")) {
        Write-Log "Aucun fichier d'entrée spécifié. Utilisez -Parameters @{InputPath = 'chemin/vers/inventory.json'}" -Level Error
        return $null
    }

    # Vérifier si le fichier de sortie existe déjà
    if ((Test-Path -Path $mergedParams.OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie $($mergedParams.OutputPath) existe déjà. Utilisez -Force pour l'écraser." -Level Warning
        return $null
    }

    # Exécuter le script d'analyse
    $scriptPath = "$PSScriptRoot\Analyze-RoadmapStructure.ps1"
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Log "Le script $scriptPath n'existe pas." -Level Error
        return $null
    }

    $result = & $scriptPath @mergedParams

    Write-Log "Analyse terminée. Résultats enregistrés dans $($mergedParams.OutputPath)" -Level Success

    return $mergedParams.OutputPath
}

# Fonction pour exécuter la recherche de doublons
function Invoke-DuplicateSearch {
    param (
        [hashtable]$Params,
        [string]$OutputDir,
        [string]$Format,
        [switch]$Force
    )

    Write-Log "Démarrage de la recherche de doublons et versions obsolètes..." -Level Info

    # Définir les paramètres par défaut
    $defaultParams = @{
        OutputPath          = "$OutputDir/duplicates.$($Format.ToLower())"
        OutputFormat        = $Format
        SimilarityThreshold = 0.8
    }

    # Fusionner avec les paramètres fournis
    $mergedParams = $defaultParams.Clone()
    foreach ($key in $Params.Keys) {
        $mergedParams[$key] = $Params[$key]
    }

    # Vérifier si le fichier d'entrée est spécifié
    if (-not $mergedParams.ContainsKey("InputPath")) {
        Write-Log "Aucun fichier d'entrée spécifié. Utilisez -Parameters @{InputPath = 'chemin/vers/inventory.json'}" -Level Error
        return $null
    }

    # Vérifier si le fichier de sortie existe déjà
    if ((Test-Path -Path $mergedParams.OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie $($mergedParams.OutputPath) existe déjà. Utilisez -Force pour l'écraser." -Level Warning
        return $null
    }

    # Exécuter le script de recherche de doublons
    $scriptPath = "$PSScriptRoot\Find-DuplicateRoadmaps.ps1"
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Log "Le script $scriptPath n'existe pas." -Level Error
        return $null
    }

    $result = & $scriptPath @mergedParams

    Write-Log "Recherche terminée. Résultats enregistrés dans $($mergedParams.OutputPath)" -Level Success

    return $mergedParams.OutputPath
}

# Fonction principale
function Invoke-RoadmapAnalysis {
    param (
        [string]$Action,
        [hashtable]$Params,
        [string]$OutputDir,
        [string]$Format,
        [switch]$Force
    )

    # Initialiser le dossier de sortie
    Initialize-OutputDirectory -Directory $OutputDir -Force:$Force

    # Exécuter l'action demandée
    switch ($Action) {
        "Inventory" {
            return Invoke-Inventory -Params $Params -OutputDir $OutputDir -Format $Format -Force:$Force
        }
        "Analyze" {
            return Invoke-StructureAnalysis -Params $Params -OutputDir $OutputDir -Format $Format -Force:$Force
        }
        "FindDuplicates" {
            return Invoke-DuplicateSearch -Params $Params -OutputDir $OutputDir -Format $Format -Force:$Force
        }
        "All" {
            Write-Log "Exécution de toutes les actions..." -Level Info

            # Exécuter l'inventaire
            $inventoryPath = Invoke-Inventory -Params $Params -OutputDir $OutputDir -Format $Format -Force:$Force

            if (-not $inventoryPath) {
                Write-Log "L'inventaire a échoué. Impossible de continuer." -Level Error
                return $null
            }

            # Exécuter l'analyse de structure
            $analysisParams = $Params.Clone()
            $analysisParams["InputPath"] = $inventoryPath
            $structurePath = Invoke-StructureAnalysis -Params $analysisParams -OutputDir $OutputDir -Format $Format -Force:$Force

            # Exécuter la recherche de doublons
            $duplicateParams = $Params.Clone()
            $duplicateParams["InputPath"] = $inventoryPath
            $duplicatesPath = Invoke-DuplicateSearch -Params $duplicateParams -OutputDir $OutputDir -Format $Format -Force:$Force

            # Créer un rapport de synthèse
            $summaryPath = "$OutputDir/summary.$($Format.ToLower())"

            $summary = @{
                Timestamp             = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                InventoryPath         = $inventoryPath
                StructureAnalysisPath = $structurePath
                DuplicatesPath        = $duplicatesPath
                Statistics            = @{
                    TotalFiles      = 0
                    DuplicateFiles  = 0
                    ObsoleteFiles   = 0
                    VersionedGroups = 0
                }
            }

            # Ajouter des statistiques si disponibles
            if (Test-Path -Path $inventoryPath) {
                $inventoryData = Get-Content -Path $inventoryPath -Raw | ConvertFrom-Json
                $summary.Statistics.TotalFiles = $inventoryData.Count
            }

            if (Test-Path -Path $duplicatesPath) {
                $duplicatesData = Get-Content -Path $duplicatesPath -Raw | ConvertFrom-Json
                $summary.Statistics.DuplicateFiles = $duplicatesData.Duplicates.Count
                $summary.Statistics.ObsoleteFiles = $duplicatesData.Obsolete.Count
                $summary.Statistics.VersionedGroups = $duplicatesData.VersionedFiles.Count
            }

            # Enregistrer le rapport de synthèse
            $summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8

            Write-Log "Toutes les actions terminées. Rapport de synthèse enregistré dans $summaryPath" -Level Success

            return $summaryPath
        }
        default {
            Show-Help
            return $null
        }
    }
}

# Exécution principale
try {
    if ($Action -eq "Help") {
        Show-Help
        return
    }

    $result = Invoke-RoadmapAnalysis -Action $Action -Params $Parameters -OutputDir $OutputDirectory -Format $OutputFormat -Force:$Force

    # Retourner le résultat
    return $result
} catch {
    Write-Log "Erreur lors de l'exécution de l'action $Action : $_" -Level Error
    throw $_
}
