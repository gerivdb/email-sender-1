# Test-RoadmapFromJson.ps1
# Script pour tester la fonction Import-RoadmapFromJson

# Importer les fonctions Ã  tester
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$exportFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Export-RoadmapToJson.ps1"
$importFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Import-RoadmapFromJson.ps1"

. $extendedFunctionPath
. $exportFunctionPath
. $importFunctionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider la fonction Import-RoadmapFromJson.

## Section 1

- [ ] **1** TÃ¢che 1
  - [x] **1.1** TÃ¢che 1.1
  - [ ] **1.2** TÃ¢che 1.2 @depends:1.1
    - [~] **1.2.1** TÃ¢che 1.2.1 @john #important
    - [!] **1.2.2** TÃ¢che 1.2.2 P1

## Section 2

- [ ] **2** TÃ¢che 2 @depends:1
  - [ ] **2.1** TÃ¢che 2.1 @date:2023-12-31
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $originalRoadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies
    
    # Exporter la roadmap en JSON
    $jsonPath = Join-Path -Path $testDir -ChildPath "roadmap.json"
    Export-RoadmapToJson -Roadmap $originalRoadmap -OutputPath $jsonPath -IncludeMetadata -IncludeDependencies -PrettyPrint
    
    Write-Host "Roadmap exportÃ©e en JSON: $jsonPath" -ForegroundColor Green
    
    # Importer la roadmap Ã  partir du JSON
    $importedRoadmap = Import-RoadmapFromJson -FilePath $jsonPath -DetectDependencies
    
    # VÃ©rifier l'importation
    Write-Host "`nVÃ©rification de l'importation:" -ForegroundColor Cyan
    Write-Host "Titre: $($importedRoadmap.Title)" -ForegroundColor Yellow
    Write-Host "Description: $($importedRoadmap.Description)" -ForegroundColor Yellow
    Write-Host "Nombre de sections: $($importedRoadmap.Sections.Count)" -ForegroundColor Yellow
    Write-Host "Nombre de tÃ¢ches: $($importedRoadmap.AllTasks.Count)" -ForegroundColor Yellow
    
    # VÃ©rifier que les nombres correspondent
    if ($importedRoadmap.Sections.Count -eq $originalRoadmap.Sections.Count) {
        Write-Host "âœ“ Nombre de sections correct" -ForegroundColor Green
    } else {
        Write-Host "âœ— Nombre de sections incorrect" -ForegroundColor Red
    }
    
    if ($importedRoadmap.AllTasks.Count -eq $originalRoadmap.AllTasks.Count) {
        Write-Host "âœ“ Nombre de tÃ¢ches correct" -ForegroundColor Green
    } else {
        Write-Host "âœ— Nombre de tÃ¢ches incorrect" -ForegroundColor Red
    }
    
    # VÃ©rifier les mÃ©tadonnÃ©es
    $task = $importedRoadmap.AllTasks["1.2.1"]
    if ($task -and $task.Metadata.Count -gt 0) {
        Write-Host "âœ“ MÃ©tadonnÃ©es importÃ©es correctement" -ForegroundColor Green
        Write-Host "MÃ©tadonnÃ©es de la tÃ¢che 1.2.1: $($task.Metadata.Keys -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— MÃ©tadonnÃ©es non importÃ©es correctement" -ForegroundColor Red
    }
    
    # VÃ©rifier les dÃ©pendances
    $task = $importedRoadmap.AllTasks["1.2"]
    if ($task -and $task.Dependencies.Count -gt 0) {
        Write-Host "âœ“ DÃ©pendances importÃ©es correctement" -ForegroundColor Green
        Write-Host "La tÃ¢che 1.2 dÃ©pend de: $($task.Dependencies.Id -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— DÃ©pendances non importÃ©es correctement" -ForegroundColor Red
    }
    
    Write-Host "`nTest terminÃ©." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du test: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
