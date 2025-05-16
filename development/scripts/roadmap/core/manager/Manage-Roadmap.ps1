# Manage-Roadmap.ps1
# Script principal pour gÃ©rer la roadmap et ses fonctionnalitÃ©s

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Split", "Update", "Navigate", "Report", "Help")]
    [string]$Action = "Help",

    [Parameter(Mandatory = $false)]
    [string]$TaskId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Complete", "Incomplete")]
    [string]$Status,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Active", "Completed", "All", "Search")]
    [string]$NavigateMode = "Active",

    [Parameter(Mandatory = $false)]
    [int]$DetailLevel = 2,

    [Parameter(Mandatory = $false)]
    [string]$SearchTerm,

    [Parameter(Mandatory = $false)]
    [string]$SectionId,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$ArchiveSections,

    [Parameter(Mandatory = $false)]
    [switch]$OpenInEditor
)

function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

function Show-Help {
    Write-Host @"

GESTION DE LA ROADMAP - EMAIL_SENDER_1
======================================

Ce script permet de gÃ©rer la roadmap du projet EMAIL_SENDER_1.

SYNTAXE
-------
    .\Manage-Roadmap.ps1 -Action <Action> [options]

ACTIONS
-------
    Split    : SÃ©pare la roadmap en fichiers actif et complÃ©tÃ©
    Update   : Met Ã  jour le statut d'une tÃ¢che
    Navigate : Navigue dans la roadmap
    Report   : GÃ©nÃ¨re un rapport d'avancement
    Help     : Affiche cette aide

OPTIONS COMMUNES
---------------
    -Force          : Force l'Ã©crasement des fichiers existants
    -OpenInEditor   : Ouvre le fichier dans l'Ã©diteur aprÃ¨s l'opÃ©ration

OPTIONS POUR SPLIT
-----------------
    -ArchiveSections : Archive Ã©galement les sections complÃ©tÃ©es

OPTIONS POUR UPDATE
-----------------
    -TaskId <id>           : Identifiant de la tÃ¢che Ã  mettre Ã  jour
    -Status <statut>       : Nouveau statut (Complete ou Incomplete)

OPTIONS POUR NAVIGATE
-------------------
    -NavigateMode <mode>   : Mode de navigation (Active, Completed, All, Search)
    -DetailLevel <niveau>  : Niveau de dÃ©tail (1-6)
    -SearchTerm <terme>    : Terme Ã  rechercher (pour le mode Search)
    -SectionId <id>        : Identifiant de la section Ã  afficher

OPTIONS POUR REPORT
-----------------
    Aucune option spÃ©cifique

EXEMPLES
--------
    # SÃ©parer la roadmap
    .\Manage-Roadmap.ps1 -Action Split -ArchiveSections -Force

    # Mettre Ã  jour une tÃ¢che
    .\Manage-Roadmap.ps1 -Action Update -TaskId "1.2.3" -Status Complete

    # Naviguer dans la roadmap active
    .\Manage-Roadmap.ps1 -Action Navigate -NavigateMode Active -DetailLevel 3

    # Rechercher un terme
    .\Manage-Roadmap.ps1 -Action Navigate -NavigateMode Search -SearchTerm "gestionnaire"

    # Afficher une section spÃ©cifique
    .\Manage-Roadmap.ps1 -Action Navigate -SectionId "1.2.3"

    # GÃ©nÃ©rer un rapport
    .\Manage-Roadmap.ps1 -Action Report

"@
}

# Chemins des fichiers
$sourceRoadmapPath = "projet\roadmaps\roadmap_complete_converted.md"
$activeRoadmapPath = "projet\roadmaps\active\roadmap_active.md"
$completedRoadmapPath = "projet\roadmaps\archive\roadmap_completed.md"
$sectionsArchivePath = "projet\roadmaps\archive\sections"

# Chemins des scripts
$splitRoadmapScript = Join-Path -Path $PSScriptRoot -ChildPath "Split-Roadmap.ps1"
$updateRoadmapStatusScript = Join-Path -Path $PSScriptRoot -ChildPath "Update-RoadmapStatus.ps1"
$navigateRoadmapScript = Join-Path -Path $PSScriptRoot -ChildPath "Navigate-Roadmap.ps1"

# VÃ©rifier que les scripts existent
$missingScripts = @()

if (-not (Test-Path -Path $splitRoadmapScript)) {
    $missingScripts += "Split-Roadmap.ps1"
}

if (-not (Test-Path -Path $updateRoadmapStatusScript)) {
    $missingScripts += "Update-RoadmapStatus.ps1"
}

if (-not (Test-Path -Path $navigateRoadmapScript)) {
    $missingScripts += "Navigate-Roadmap.ps1"
}

if ($missingScripts.Count -gt 0) {
    Write-Log "Les scripts suivants sont manquants: $($missingScripts -join ', ')" -Level Error
    Write-Log "Veuillez vous assurer que tous les scripts sont prÃ©sents dans le mÃªme dossier que ce script." -Level Error
    return
}

# ExÃ©cution de l'action demandÃ©e
switch ($Action) {
    "Split" {
        Write-Log "SÃ©paration de la roadmap..." -Level Info

        $params = @{
            SourceRoadmapPath        = $sourceRoadmapPath
            ActiveRoadmapPath        = $activeRoadmapPath
            CompletedRoadmapPath     = $completedRoadmapPath
            SectionsArchivePath      = $sectionsArchivePath
            ArchiveCompletedSections = $ArchiveSections
            Force                    = $Force
        }

        & $splitRoadmapScript @params

        if ($OpenInEditor -and (Test-Path -Path $activeRoadmapPath)) {
            # Utiliser code (VS Code) si disponible, sinon notepad
            $editor = if (Get-Command "code" -ErrorAction SilentlyContinue) { "code" } else { "notepad" }

            if ($editor -eq "code") {
                & code $activeRoadmapPath
            } else {
                & notepad $activeRoadmapPath
            }
        }
    }
    "Update" {
        if ([string]::IsNullOrEmpty($TaskId)) {
            Write-Log "L'identifiant de la tÃ¢che est requis pour l'action Update." -Level Error
            return
        }

        if ([string]::IsNullOrEmpty($Status)) {
            Write-Log "Le statut est requis pour l'action Update." -Level Error
            return
        }

        Write-Log "Mise Ã  jour du statut de la tÃ¢che ${TaskId}: ${Status}" -Level Info

        $params = @{
            ActiveRoadmapPath    = $activeRoadmapPath
            CompletedRoadmapPath = $completedRoadmapPath
            TaskId               = $TaskId
            Status               = $Status
            AutoArchive          = $true
        }

        & $updateRoadmapStatusScript @params

        if ($OpenInEditor -and (Test-Path -Path $activeRoadmapPath)) {
            # Utiliser code (VS Code) si disponible, sinon notepad
            $editor = if (Get-Command "code" -ErrorAction SilentlyContinue) { "code" } else { "notepad" }

            if ($editor -eq "code") {
                & code $activeRoadmapPath
            } else {
                & notepad $activeRoadmapPath
            }
        }
    }
    "Navigate" {
        $params = @{
            Mode                 = $NavigateMode
            DetailLevel          = $DetailLevel
            ActiveRoadmapPath    = $activeRoadmapPath
            CompletedRoadmapPath = $completedRoadmapPath
            SectionsArchivePath  = $sectionsArchivePath
            OpenInEditor         = $OpenInEditor
        }

        if (-not [string]::IsNullOrEmpty($SearchTerm)) {
            $params.SearchTerm = $SearchTerm
        }

        if (-not [string]::IsNullOrEmpty($SectionId)) {
            $params.SectionId = $SectionId
        }

        & $navigateRoadmapScript @params
    }
    "Report" {
        Write-Log "GÃ©nÃ©ration du rapport d'avancement..." -Level Info

        $params = @{
            ActiveRoadmapPath    = $activeRoadmapPath
            CompletedRoadmapPath = $completedRoadmapPath
            GenerateReport       = $true
        }

        & $updateRoadmapStatusScript @params
    }
    "Help" {
        Show-Help
    }
    default {
        Write-Log "Action non reconnue: $Action" -Level Error
        Show-Help
    }
}
