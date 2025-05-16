# Create-RoadmapFolderStructure.ps1
# Script pour créer la structure de dossiers pour la réorganisation des scripts de roadmap

# Définir le chemin de base
$basePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\scripts\roadmap"

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
foreach ($folder in $folders) {
    $folderPath = Join-Path -Path $basePath -ChildPath $folder
    
    if (-not (Test-Path -Path $folderPath)) {
        Write-Host "Création du dossier: $folderPath"
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
    } else {
        Write-Host "Le dossier existe déjà: $folderPath"
    }
}

Write-Host "Structure de dossiers créée avec succès!"

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
foreach ($file in $fileMappings.Keys) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    $destinationPath = Join-Path -Path $basePath -ChildPath $fileMappings[$file]
    
    if (Test-Path -Path $sourcePath) {
        Write-Host "Déplacement du fichier: $sourcePath -> $destinationPath"
        
        # Créer le dossier de destination s'il n'existe pas
        $destinationFolder = Split-Path -Path $destinationPath -Parent
        if (-not (Test-Path -Path $destinationFolder)) {
            New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
        }
        
        # Copier le fichier vers la nouvelle destination
        Copy-Item -Path $sourcePath -Destination $destinationPath -Force
        
        # Supprimer le fichier source après la copie
        Remove-Item -Path $sourcePath -Force
    } else {
        Write-Host "Fichier source introuvable: $sourcePath"
    }
}

# Gérer le sous-dossier RAG existant
$ragMappings = @{
    "rag\Get-RoadmapFiles.ps1" = "utils\import\Get-RoadmapFiles.ps1"
    "rag\README.md" = "docs\guides\RAG-System.md"
}

foreach ($file in $ragMappings.Keys) {
    $sourcePath = Join-Path -Path $basePath -ChildPath $file
    $destinationPath = Join-Path -Path $basePath -ChildPath $ragMappings[$file]
    
    if (Test-Path -Path $sourcePath) {
        Write-Host "Déplacement du fichier RAG: $sourcePath -> $destinationPath"
        
        # Créer le dossier de destination s'il n'existe pas
        $destinationFolder = Split-Path -Path $destinationPath -Parent
        if (-not (Test-Path -Path $destinationFolder)) {
            New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
        }
        
        # Copier le fichier vers la nouvelle destination
        Copy-Item -Path $sourcePath -Destination $destinationPath -Force
        
        # Supprimer le fichier source après la copie
        Remove-Item -Path $sourcePath -Force
    } else {
        Write-Host "Fichier RAG source introuvable: $sourcePath"
    }
}

Write-Host "Réorganisation des fichiers terminée!"
