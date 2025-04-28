# Test-ExportFunctions.ps1
# Script pour tester les fonctions d'export et de gÃ©nÃ©ration

# Importer le module RoadmapParser3
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser3.psm1"
Import-Module $modulePath -Force

# CrÃ©er un fichier markdown de test
$testMarkdownPath = Join-Path -Path $PSScriptRoot -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider les fonctions d'export et de gÃ©nÃ©ration.

## Section 1

- [ ] **1** TÃ¢che 1
  - [x] **1.1** TÃ¢che 1.1
  - [ ] **1.2** TÃ¢che 1.2
    - [~] **1.2.1** TÃ¢che 1.2.1
    - [!] **1.2.2** TÃ¢che 1.2.2

## Section 2

- [ ] **2** TÃ¢che 2
  - [ ] **2.1** TÃ¢che 2.1
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

# CrÃ©er un dossier pour les fichiers de sortie
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Tester les fonctions d'export et de gÃ©nÃ©ration
try {
    # Convertir le fichier markdown en arbre de roadmap
    Write-Host "Conversion du fichier markdown en arbre de roadmap..." -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapTree -FilePath $testMarkdownPath
    Write-Host "Arbre de roadmap crÃ©Ã© avec $($roadmap.AllTasks.Count) tÃ¢ches." -ForegroundColor Green

    # Tester Export-RoadmapTreeToJson
    Write-Host "`nTest de Export-RoadmapTreeToJson..." -ForegroundColor Cyan
    $jsonPath = Join-Path -Path $outputDir -ChildPath "roadmap.json"
    Export-RoadmapTreeToJson -RoadmapTree $roadmap -FilePath $jsonPath
    Write-Host "Fichier JSON crÃ©Ã©: $jsonPath" -ForegroundColor Green
    
    # Tester Export-RoadmapTreeToMarkdown
    Write-Host "`nTest de Export-RoadmapTreeToMarkdown..." -ForegroundColor Cyan
    $markdownPath = Join-Path -Path $outputDir -ChildPath "roadmap.md"
    Export-RoadmapTreeToMarkdown -RoadmapTree $roadmap -FilePath $markdownPath
    Write-Host "Fichier Markdown crÃ©Ã©: $markdownPath" -ForegroundColor Green
    
    # Tester Import-RoadmapTreeFromJson
    Write-Host "`nTest de Import-RoadmapTreeFromJson..." -ForegroundColor Cyan
    $importedRoadmap = Import-RoadmapTreeFromJson -FilePath $jsonPath
    Write-Host "Arbre de roadmap importÃ© avec $($importedRoadmap.AllTasks.Count) tÃ¢ches." -ForegroundColor Green
    
    # Tester New-RoadmapReport
    Write-Host "`nTest de New-RoadmapReport..." -ForegroundColor Cyan
    $reportPath = Join-Path -Path $outputDir -ChildPath "report.md"
    $report = New-RoadmapReport -RoadmapTree $roadmap -FilePath $reportPath
    Write-Host "Rapport crÃ©Ã©: $reportPath" -ForegroundColor Green
    
    # Tester Get-RoadmapStatistics
    Write-Host "`nTest de Get-RoadmapStatistics..." -ForegroundColor Cyan
    $stats = Get-RoadmapStatistics -RoadmapTree $roadmap
    Write-Host "Statistiques calculÃ©es:" -ForegroundColor Green
    Write-Host "  - Nombre total de tÃ¢ches: $($stats.TotalTasks)" -ForegroundColor Green
    Write-Host "  - TÃ¢ches complÃ©tÃ©es: $($stats.CompleteTasks) ($($stats.CompletePercentage)%)" -ForegroundColor Green
    Write-Host "  - TÃ¢ches en cours: $($stats.InProgressTasks) ($($stats.InProgressPercentage)%)" -ForegroundColor Green
    Write-Host "  - TÃ¢ches bloquÃ©es: $($stats.BlockedTasks) ($($stats.BlockedPercentage)%)" -ForegroundColor Green
    Write-Host "  - TÃ¢ches incomplÃ¨tes: $($stats.IncompleteTasks) ($($stats.IncompletePercentage)%)" -ForegroundColor Green
    
    # Tester New-RoadmapVisualization
    Write-Host "`nTest de New-RoadmapVisualization..." -ForegroundColor Cyan
    $visualizationPath = Join-Path -Path $outputDir -ChildPath "visualization.md"
    $visualization = New-RoadmapVisualization -RoadmapTree $roadmap -FilePath $visualizationPath
    Write-Host "Visualisation crÃ©Ã©e: $visualizationPath" -ForegroundColor Green
    
    Write-Host "`nTests terminÃ©s avec succÃ¨s!" -ForegroundColor Cyan
}
catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Supprimer le fichier de test
    if (Test-Path -Path $testMarkdownPath) {
        Remove-Item -Path $testMarkdownPath -Force
    }
}
