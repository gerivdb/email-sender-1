<#
.SYNOPSIS
    Organise les fichiers à la racine du répertoire roadmap dans des sous-dossiers thématiques.

.DESCRIPTION
    Ce script déplace les fichiers de la racine du répertoire roadmap vers des sous-dossiers
    thématiques selon leur fonction. Il utilise les sous-dossiers existants lorsque c'est pertinent,
    ou crée de nouveaux sous-dossiers si nécessaire.

.PARAMETER DryRun
    Si spécifié, le script simule les opérations sans effectuer de modifications réelles.

.PARAMETER Force
    Si spécifié, le script effectue les opérations sans demander de confirmation.

.EXAMPLE
    .\Organize-RoadmapFiles.ps1 -DryRun
    Simule l'organisation des fichiers sans effectuer de modifications.

.EXAMPLE
    .\Organize-RoadmapFiles.ps1
    Organise les fichiers avec confirmation pour chaque action.

.EXAMPLE
    .\Organize-RoadmapFiles.ps1 -Force
    Organise les fichiers sans demander de confirmation.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Définir les chemins
$roadmapRoot = Join-Path -Path $PSScriptRoot -ChildPath ".."
$roadmapRoot = Resolve-Path $roadmapRoot

# Fonction pour déplacer un fichier
function Move-FileToDirectory {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $fileName = Split-Path -Path $SourcePath -Leaf
    $destinationPath = Join-Path -Path $DestinationDirectory -ChildPath $fileName

    if ($DryRun) {
        Write-Host "[SIMULATION] Déplacement: $SourcePath -> $destinationPath" -ForegroundColor Yellow
        return $true
    }

    # Vérifier si le fichier de destination existe déjà
    if (Test-Path -Path $destinationPath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe déjà : $destinationPath. Voulez-vous le remplacer ?", "Confirmation")
        }

        if (-not $shouldContinue) {
            Write-Host "Déplacement annulé pour $SourcePath" -ForegroundColor Yellow
            return $false
        }
    }

    if ($PSCmdlet.ShouldProcess($SourcePath, "Déplacer vers $destinationPath")) {
        try {
            Move-Item -Path $SourcePath -Destination $destinationPath -Force
            Write-Host "Déplacé: $SourcePath -> $destinationPath" -ForegroundColor Green
            return $true
        } catch {
            Write-Error "Erreur lors du déplacement de $SourcePath vers $destinationPath : $_"
            return $false
        }
    }

    return $false
}

# Fonction principale pour organiser les fichiers
function Start-FileOrganization {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Définir les mappages de fichiers vers les sous-dossiers
    $fileMappings = @{
        # Fichiers liés à l'archivage
        "Archive-CompletedTasks.ps1"      = "maintenance"
        "ArchiveTask.xml"                 = "maintenance"
        "Execute-ArchiveIfNeeded.ps1"     = "maintenance"
        "last_archive_run.json"           = "maintenance"
        "Register-ArchiveTask.ps1"        = "maintenance"
        "RegisterTask.bat"                = "maintenance"
        "RunArchiveTask.bat"              = "maintenance"
        "RunArchiveTaskHidden.vbs"        = "maintenance"
        "Setup-ArchiveScheduledTask.ps1"  = "maintenance"
        "Start-AutoArchiveBackground.ps1" = "maintenance"
        "Start-AutoArchiveMonitor.ps1"    = "maintenance"
        "Stop-AutoArchiveMonitor.ps1"     = "maintenance"
        "Unregister-ArchiveTask.ps1"      = "maintenance"
        "UnregisterTask.bat"              = "maintenance"

        # Fichiers liés à la gestion des tâches
        "Filter-Tasks.ps1"                = "core"
        "Fix-ParentTaskStatus.ps1"        = "core"
        "Simple-Split-Roadmap.ps1"        = "core"
        "Split-Roadmap.ps1"               = "core"
        "update-roadmap-checkboxes.ps1"   = "core"

        # Fichiers liés à la visualisation
        "Generate-ActiveRoadmapView.ps1"  = "visualization"
        "Generate-CompletedTasksView.ps1" = "visualization"
        "Generate-PriorityTasksView.ps1"  = "visualization"

        # Fichiers liés à l'IA et RAG
        "Apply-ThematicAttribution.ps1"   = "ai"
        "Explore-QdrantWebUI.ps1"         = "rag"
        "Index-PlanDevQdrant.ps1"         = "rag"
        "Index-TaskVectors.ps1"           = "rag"
        "Index-TaskVectorsQdrant.ps1"     = "rag"
        "qwen3-dev-r.ps1"                 = "ai"
        "Simple-ThematicTest.ps1"         = "ai"
        "Start-QdrantContainer.ps1"       = "rag"
        "Store-VectorsInChroma.ps1"       = "rag"
        "Store-VectorsInQdrant.ps1"       = "rag"
        "Use-AIFeatures.ps1"              = "ai"

        # Fichiers liés à la sécurité
        "Manage-SecurityCompliance.ps1"   = "security"

        # Fichiers liés à l'intégration
        "Sync-RoadmapServices.ps1"        = "integration"

        # Fichiers liés aux managers
        "define-manager-structure.ps1"    = "modules"
        "reorganize-manager-files.ps1"    = "modules"
        "standardize-manager-names.ps1"   = "modules"

        # Fichiers liés au nettoyage
        "Cleanup-OldArchiveScripts.ps1"   = "maintenance"

        # Documentation
        "README.md"                       = "docs"
        "README_RAG.md"                   = "docs"
    }

    # Créer les sous-dossiers nécessaires
    $subDirectories = $fileMappings.Values | Sort-Object -Unique
    foreach ($dir in $subDirectories) {
        $dirPath = Join-Path -Path $roadmapRoot -ChildPath $dir

        if (-not (Test-Path -Path $dirPath)) {
            if ($DryRun) {
                Write-Host "[SIMULATION] Création du répertoire: $dirPath" -ForegroundColor Yellow
            } else {
                if ($PSCmdlet.ShouldProcess($dirPath, "Créer le répertoire")) {
                    try {
                        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
                        Write-Host "Créé: $dirPath" -ForegroundColor Green
                    } catch {
                        Write-Error "Erreur lors de la création du répertoire $dirPath : $_"
                    }
                }
            }
        } else {
            Write-Host "Le répertoire $dirPath existe déjà" -ForegroundColor Cyan
        }
    }

    # Lister les fichiers à la racine
    $files = Get-ChildItem -Path $roadmapRoot -File

    # Déplacer les fichiers
    foreach ($file in $files) {
        # Vérifier si le fichier est dans le dossier organize
        $organizeDir = Join-Path -Path $roadmapRoot -ChildPath "organize"
        if ($file.DirectoryName -eq $organizeDir) {
            Write-Host "Fichier dans le dossier organize, ignoré: $($file.Name)" -ForegroundColor Cyan
            continue
        }

        if ($fileMappings.ContainsKey($file.Name)) {
            $destDir = Join-Path -Path $roadmapRoot -ChildPath $fileMappings[$file.Name]
            Move-FileToDirectory -SourcePath $file.FullName -DestinationDirectory $destDir -DryRun:$DryRun -Force:$Force
        } else {
            Write-Host "Aucun mapping défini pour le fichier: $($file.Name)" -ForegroundColor Yellow
        }
    }
}

# Créer le répertoire organize s'il n'existe pas
$organizeDir = Join-Path -Path $roadmapRoot -ChildPath "organize"
if (-not (Test-Path -Path $organizeDir)) {
    if (-not $DryRun) {
        New-Item -Path $organizeDir -ItemType Directory -Force | Out-Null
        Write-Host "Créé: $organizeDir" -ForegroundColor Green
    } else {
        Write-Host "[SIMULATION] Création du répertoire: $organizeDir" -ForegroundColor Yellow
    }
}

# Organiser les fichiers
Write-Host "Organisation des fichiers roadmap..." -ForegroundColor Cyan
Write-Host "Répertoire racine: $roadmapRoot" -ForegroundColor Cyan

# Lister les fichiers à la racine pour vérification
Write-Host "Fichiers à la racine:" -ForegroundColor Cyan
Get-ChildItem -Path $roadmapRoot -File | Select-Object Name | ForEach-Object { Write-Host "- $($_.Name)" -ForegroundColor Gray }

Start-FileOrganization -DryRun:$DryRun -Force:$Force

Write-Host "Organisation terminée." -ForegroundColor Green
