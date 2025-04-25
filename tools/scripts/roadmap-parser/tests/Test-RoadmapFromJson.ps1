# Test-RoadmapFromJson.ps1
# Script pour tester la fonction Import-RoadmapFromJson

# Importer les fonctions à tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$exportFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Export-RoadmapToJson.ps1"
$importFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Import-RoadmapFromJson.ps1"

. $extendedFunctionPath
. $exportFunctionPath
. $importFunctionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider la fonction Import-RoadmapFromJson.

## Section 1

- [ ] **1** Tâche 1
  - [x] **1.1** Tâche 1.1
  - [ ] **1.2** Tâche 1.2 @depends:1.1
    - [~] **1.2.1** Tâche 1.2.1 @john #important
    - [!] **1.2.2** Tâche 1.2.2 P1

## Section 2

- [ ] **2** Tâche 2 @depends:1
  - [ ] **2.1** Tâche 2.1 @date:2023-12-31
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $originalRoadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    # Exporter la roadmap en JSON
    $jsonPath = Join-Path -Path $testDir -ChildPath "roadmap.json"
    Export-RoadmapToJson -Roadmap $originalRoadmap -OutputPath $jsonPath -IncludeMetadata -IncludeDependencies -PrettyPrint
    
    Write-Host "Roadmap exportée en JSON: $jsonPath" -ForegroundColor Green
    
    # Importer la roadmap à partir du JSON
    $importedRoadmap = Import-RoadmapFromJson -FilePath $jsonPath -DetectDependencies
    
    # Vérifier l'importation
    Write-Host "`nVérification de l'importation:" -ForegroundColor Cyan
    Write-Host "Titre: $($importedRoadmap.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($importedRoadmap.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($importedRoadmap.Sections.Count)" -ForegroundColor Yellow
    Write-Host "Nombre de tâches: $($importedRoadmap.AllTasks.Count)" -ForegroundColor Yellow
    
    # Vérifier que les nombres correspondent
    if ($importedRoadmap.Sections.Count -eq $originalRoadmap.Sections.Count) {
        Write-Host "✓ Nombre de sections correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Nombre de sections incorrect" -ForegroundColor Red
    }
    
    if ($importedRoadmap.AllTasks.Count -eq $originalRoadmap.AllTasks.Count) {
        Write-Host "✓ Nombre de tâches correct" -ForegroundColor Green
    } else {
        Write-Host "✗ Nombre de tâches incorrect" -ForegroundColor Red
    }
    
    # Vérifier les métadonnées
    $task = $importedRoadmap.AllTasks["1.2.1"]
    if ($task -and $task.Metadata.Count -gt 0) {
        Write-Host "✓ Métadonnées importées correctement" -ForegroundColor Green
        Write-Host "Métadonnées de la tâche 1.2.1: $($task.Metadata.Keys -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Métadonnées non importées correctement" -ForegroundColor Red
    }
    
    # Vérifier les dépendances
    $task = $importedRoadmap.AllTasks["1.2"]
    if ($task -and $task.Dependencies.Count -gt 0) {
        Write-Host "✓ Dépendances importées correctement" -ForegroundColor Green
        Write-Host "La tâche 1.2 dépend de: $($task.Dependencies.Id -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Dépendances non importées correctement" -ForegroundColor Red
    }
    
    Write-Host "`nTest terminé." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRépertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
