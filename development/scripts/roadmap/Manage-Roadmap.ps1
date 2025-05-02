# Manage-Roadmap.ps1
# Script principal pour gérer la roadmap et ses fonctionnalités

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

Ce script permet de gérer la roadmap du projet EMAIL_SENDER_1.

SYNTAXE
-------
    .\Manage-Roadmap.ps1 -Action <Action> [options]

ACTIONS
-------
    Split    : Sépare la roadmap en fichiers actif et complété
    Update   : Met à jour le statut d'une tâche
    Navigate : Navigue dans la roadmap
    Report   : Génère un rapport d'avancement
    Help     : Affiche cette aide

OPTIONS COMMUNES
---------------
    -Force          : Force l'écrasement des fichiers existants
    -OpenInEditor   : Ouvre le fichier dans l'éditeur après l'opération

OPTIONS POUR SPLIT
-----------------
    -ArchiveSections : Archive également les sections complétées

OPTIONS POUR UPDATE
-----------------
    -TaskId <id>           : Identifiant de la tâche à mettre à jour
    -Status <statut>       : Nouveau statut (Complete ou Incomplete)

OPTIONS POUR NAVIGATE
-------------------
    -NavigateMode <mode>   : Mode de navigation (Active, Completed, All, Search)
    -DetailLevel <niveau>  : Niveau de détail (1-6)
    -SearchTerm <terme>    : Terme à rechercher (pour le mode Search)
    -SectionId <id>        : Identifiant de la section à afficher

OPTIONS POUR REPORT
-----------------
    Aucune option spécifique

EXEMPLES
--------
    # Séparer la roadmap
    .\Manage-Roadmap.ps1 -Action Split -ArchiveSections -Force

    # Mettre à jour une tâche
    .\Manage-Roadmap.ps1 -Action Update -TaskId "1.2.3" -Status Complete

    # Naviguer dans la roadmap active
    .\Manage-Roadmap.ps1 -Action Navigate -NavigateMode Active -DetailLevel 3

    # Rechercher un terme
    .\Manage-Roadmap.ps1 -Action Navigate -NavigateMode Search -SearchTerm "gestionnaire"

    # Afficher une section spécifique
    .\Manage-Roadmap.ps1 -Action Navigate -SectionId "1.2.3"

    # Générer un rapport
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

# Vérifier que les scripts existent
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
    Write-Log "Veuillez vous assurer que tous les scripts sont présents dans le même dossier que ce script." -Level Error
    return
}

# Exécution de l'action demandée
switch ($Action) {
    "Split" {
        Write-Log "Séparation de la roadmap..." -Level Info

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
            Write-Log "L'identifiant de la tâche est requis pour l'action Update." -Level Error
            return
        }

        if ([string]::IsNullOrEmpty($Status)) {
            Write-Log "Le statut est requis pour l'action Update." -Level Error
            return
        }

        Write-Log "Mise à jour du statut de la tâche ${TaskId}: ${Status}" -Level Info

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
        Write-Log "Génération du rapport d'avancement..." -Level Info

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
