# Reorganize-RoadmapScripts.ps1
# Script pour réorganiser les scripts de roadmap selon la nouvelle structure

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$BasePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\roadmap",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour créer un dossier s'il n'existe pas
function Confirm-Directory {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Création du dossier: $Path"
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        return $true
    } else {
        Write-Host "Le dossier existe déjà: $Path" -ForegroundColor Gray
        return $false
    }
}

# Fonction pour déplacer un fichier
function Move-FileToNewLocation {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [switch]$WhatIf,
        [switch]$Force
    )
    
    if (Test-Path -Path $SourcePath) {
        $destinationFolder = Split-Path -Path $DestinationPath -Parent
        Confirm-Directory -Path $destinationFolder | Out-Null
        
        if ($WhatIf) {
            Write-Host "WhatIf: Déplacement du fichier: $SourcePath -> $DestinationPath" -ForegroundColor Yellow
        } else {
            if (Test-Path -Path $DestinationPath) {
                if ($Force) {
                    Write-Host "Remplacement du fichier existant: $DestinationPath" -ForegroundColor Yellow
                    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
                    Remove-Item -Path $SourcePath -Force
                    Write-Host "Fichier déplacé: $SourcePath -> $DestinationPath" -ForegroundColor Green
                } else {
                    Write-Host "Le fichier existe déjà: $DestinationPath. Utilisez -Force pour remplacer." -ForegroundColor Red
                }
            } else {
                Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
                Remove-Item -Path $SourcePath -Force
                Write-Host "Fichier déplacé: $SourcePath -> $DestinationPath" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Fichier source introuvable: $SourcePath" -ForegroundColor Red
    }
}

# Définir la structure de dossiers à créer
$folders = @(
    "core\parser",
    "core\model",
    "core\converter",
    "core\manager",
    "utils\helpers",
    "utils\export",
    "utils\import",
    "rag\core",
    "rag\vectorization",
    "rag\search",
    "rag\metadata",
    "rag\config",
    "integration\n8n",
    "integration\notion",
    "maintenance\cleanup",
    "maintenance\validation",
    "visualization",
    "tests",
    "docs\examples",
    "docs\guides"
)

# Créer les dossiers
Write-Host "Création de la structure de dossiers..." -ForegroundColor Cyan
foreach ($folder in $folders) {
    $folderPath = Join-Path -Path $BasePath -ChildPath $folder
    Confirm-Directory -Path $folderPath | Out-Null
}

# Définir les mappages de fichiers
$fileMappings = @{
    "Manage-Roadmap.ps1" = "core\manager\Manage-Roadmap.ps1"
    "Start-RoadmapSystem.ps1" = "core\manager\Start-RoadmapSystem.ps1"
    "Update-RoadmapStatus.ps1" = "core\manager\Update-RoadmapStatus.ps1"
    "Update-TaskStatus.ps1" = "core\manager\Update-TaskStatus.ps1"
    "Update-ParentTaskStatus.ps1" = "core\manager\Update-ParentTaskStatus.ps1"
    "Invoke-RoadmapRAG.ps1" = "rag\core\Invoke-RoadmapRAG.ps1"
    "Convert-TaskToVector.ps1" = "rag\vectorization\Convert-TaskToVector.ps1"
    "Search-TasksSemanticQdrant.ps1" = "rag\search\Search-TasksSemanticQdrant.ps1"
    "Search-TasksQdrant.ps1" = "rag\search\Search-TasksQdrant.ps1"
    "Search-TasksSemantic.ps1" = "rag\search\Search-TasksSemantic.ps1"
    "Search-PlanDevQdrant.ps1" = "rag\search\Search-PlanDevQdrant.ps1"
    "Update-TaskStatusQdrant.ps1" = "rag\core\Update-TaskStatusQdrant.ps1"
    "Navigate-Roadmap.ps1" = "utils\helpers\Navigate-Roadmap.ps1"
    "Generate-RoadmapView.ps1" = "visualization\Generate-RoadmapView.ps1"
}

# Déplacer les fichiers
Write-Host "Déplacement des fichiers..." -ForegroundColor Cyan
foreach ($file in $fileMappings.Keys) {
    $sourcePath = Join-Path -Path $BasePath -ChildPath $file
    $destinationPath = Join-Path -Path $BasePath -ChildPath $fileMappings[$file]
    Move-FileToNewLocation -SourcePath $sourcePath -DestinationPath $destinationPath -WhatIf:$WhatIf -Force:$Force
}

# Gérer le sous-dossier RAG existant
$ragMappings = @{
    "rag\Get-RoadmapFiles.ps1" = "utils\import\Get-RoadmapFiles.ps1"
    "rag\README.md" = "docs\guides\RAG-System.md"
    "rag\Search-RoadmapVectors.ps1" = "rag\search\Search-RoadmapVectors.ps1"
    "rag\metadata\Search-TasksByTags.ps1" = "rag\metadata\Search-TasksByTags.ps1"
    "rag\config\Manage-Configuration.ps1" = "rag\config\Manage-Configuration.ps1"
}

foreach ($file in $ragMappings.Keys) {
    $sourcePath = Join-Path -Path $BasePath -ChildPath $file
    $destinationPath = Join-Path -Path $BasePath -ChildPath $ragMappings[$file]
    Move-FileToNewLocation -SourcePath $sourcePath -DestinationPath $destinationPath -WhatIf:$WhatIf -Force:$Force
}

# Créer des fichiers README.md dans les dossiers qui n'en ont pas
$readmeMappings = @{
    "core\parser\README.md" = "# Parser - Analyseurs de roadmap`n`nCe dossier contient les scripts pour analyser et parser les fichiers de roadmap."
    "core\model\README.md" = "# Model - Modèles de données`n`nCe dossier contient les modèles de données pour représenter les roadmaps."
    "core\converter\README.md" = "# Converter - Convertisseurs de format`n`nCe dossier contient les scripts pour convertir les roadmaps entre différents formats."
    "core\manager\README.md" = "# Manager - Gestion principale`n`nCe dossier contient les scripts principaux de gestion des roadmaps."
    "utils\helpers\README.md" = "# Helpers - Fonctions d'aide`n`nCe dossier contient les fonctions d'aide générales pour la gestion des roadmaps."
    "utils\export\README.md" = "# Export - Exportation`n`nCe dossier contient les scripts pour exporter les roadmaps vers différents formats."
    "utils\import\README.md" = "# Import - Importation`n`nCe dossier contient les scripts pour importer les roadmaps depuis différentes sources."
    "rag\core\README.md" = "# RAG Core - Fonctionnalités RAG principales`n`nCe dossier contient les fonctionnalités principales du système RAG."
    "rag\vectorization\README.md" = "# Vectorization - Vectorisation`n`nCe dossier contient les scripts pour vectoriser les roadmaps."
    "rag\search\README.md" = "# Search - Recherche`n`nCe dossier contient les scripts pour rechercher dans les roadmaps."
    "rag\metadata\README.md" = "# Metadata - Métadonnées`n`nCe dossier contient les scripts pour gérer les métadonnées des roadmaps."
    "rag\config\README.md" = "# Config - Configuration`n`nCe dossier contient les scripts de configuration du système RAG."
    "integration\n8n\README.md" = "# n8n - Intégration n8n`n`nCe dossier contient les scripts d'intégration avec n8n."
    "integration\notion\README.md" = "# Notion - Intégration Notion`n`nCe dossier contient les scripts d'intégration avec Notion."
    "maintenance\cleanup\README.md" = "# Cleanup - Nettoyage`n`nCe dossier contient les scripts de nettoyage et d'archivage."
    "maintenance\validation\README.md" = "# Validation - Validation`n`nCe dossier contient les scripts de validation de structure."
    "visualization\README.md" = "# Visualization - Visualisation`n`nCe dossier contient les scripts pour générer des visualisations des roadmaps."
    "tests\README.md" = "# Tests - Tests unitaires et d'intégration`n`nCe dossier contient les tests unitaires et d'intégration pour le système de roadmap."
    "docs\examples\README.md" = "# Examples - Exemples d'utilisation`n`nCe dossier contient des exemples d'utilisation des différents scripts."
    "docs\guides\README.md" = "# Guides - Guides d'utilisation`n`nCe dossier contient des guides détaillés pour l'utilisation du système de roadmap."
}

foreach ($readmePath in $readmeMappings.Keys) {
    $fullPath = Join-Path -Path $BasePath -ChildPath $readmePath
    if (-not (Test-Path -Path $fullPath)) {
        if ($WhatIf) {
            Write-Host "WhatIf: Création du fichier README: $fullPath" -ForegroundColor Yellow
        } else {
            $readmeContent = $readmeMappings[$readmePath]
            Set-Content -Path $fullPath -Value $readmeContent -Encoding UTF8
            Write-Host "Fichier README créé: $fullPath" -ForegroundColor Green
        }
    } else {
        Write-Host "Le fichier README existe déjà: $fullPath" -ForegroundColor Gray
    }
}

Write-Host "Réorganisation terminée!" -ForegroundColor Green

