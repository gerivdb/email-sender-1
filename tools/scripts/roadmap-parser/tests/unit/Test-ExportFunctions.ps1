# Test-ExportFunctions.ps1
# Script pour tester les fonctions d'export et de génération

# Importer le module RoadmapParser3
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser3.psm1"
Import-Module $modulePath -Force

# Créer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $PSScriptRoot -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider les fonctions d'export et de génération.

## Section 1

- [ ] **1** Tâche 1
  - [x] **1.1** Tâche 1.1
  - [ ] **1.2** Tâche 1.2
    - [~] **1.2.1** Tâche 1.2.1
    - [!] **1.2.2** Tâche 1.2.2

## Section 2

- [ ] **2** Tâche 2
  - [ ] **2.1** Tâche 2.1
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

# Créer un dossier pour les fichiers de sortie
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Tester les fonctions d'export et de génération
try {
    # Convertir le fichier markdown en arbre de roadmap
    Write-Host "Conversion du fichier markdown en arbre de roadmap..." -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapTree -FilePath $testMarkdownPath
    Write-Host "Arbre de roadmap créé avec $($roadmap.AllTasks.Count) tâches." -ForegroundColor Green

    # Tester Export-RoadmapTreeToJson
    Write-Host "`nTest de Export-RoadmapTreeToJson..." -ForegroundColor Cyan
    $jsonPath = Join-Path -Path $outputDir -ChildPath "roadmap.json"
    Export-RoadmapTreeToJson -RoadmapTree $roadmap -FilePath $jsonPath
    Write-Host "Fichier JSON créé: $jsonPath" -ForegroundColor Green
    
    # Tester Export-RoadmapTreeToMarkdown
    Write-Host "`nTest de Export-RoadmapTreeToMarkdown..." -ForegroundColor Cyan
    $markdownPath = Join-Path -Path $outputDir -ChildPath "roadmap.md"
    Export-RoadmapTreeToMarkdown -RoadmapTree $roadmap -FilePath $markdownPath
    Write-Host "Fichier Markdown créé: $markdownPath" -ForegroundColor Green
    
    # Tester Import-RoadmapTreeFromJson
    Write-Host "`nTest de Import-RoadmapTreeFromJson..." -ForegroundColor Cyan
    $importedRoadmap = Import-RoadmapTreeFromJson -FilePath $jsonPath
    Write-Host "Arbre de roadmap importé avec $($importedRoadmap.AllTasks.Count) tâches." -ForegroundColor Green
    
    # Tester New-RoadmapReport
    Write-Host "`nTest de New-RoadmapReport..." -ForegroundColor Cyan
    $reportPath = Join-Path -Path $outputDir -ChildPath "report.md"
    $report = New-RoadmapReport -RoadmapTree $roadmap -FilePath $reportPath
    Write-Host "Rapport créé: $reportPath" -ForegroundColor Green
    
    # Tester Get-RoadmapStatistics
    Write-Host "`nTest de Get-RoadmapStatistics..." -ForegroundColor Cyan
    $stats = Get-RoadmapStatistics -RoadmapTree $roadmap
    Write-Host "Statistiques calculées:" -ForegroundColor Green
    Write-Host "  - Nombre total de tâches: $($stats.TotalTasks)" -ForegroundColor Green
    Write-Host "  - Tâches complétées: $($stats.CompleteTasks) ($($stats.CompletePercentage)%)" -ForegroundColor Green
    Write-Host "  - Tâches en cours: $($stats.InProgressTasks) ($($stats.InProgressPercentage)%)" -ForegroundColor Green
    Write-Host "  - Tâches bloquées: $($stats.BlockedTasks) ($($stats.BlockedPercentage)%)" -ForegroundColor Green
    Write-Host "  - Tâches incomplètes: $($stats.IncompleteTasks) ($($stats.IncompletePercentage)%)" -ForegroundColor Green
    
    # Tester New-RoadmapVisualization
    Write-Host "`nTest de New-RoadmapVisualization..." -ForegroundColor Cyan
    $visualizationPath = Join-Path -Path $outputDir -ChildPath "visualization.md"
    $visualization = New-RoadmapVisualization -RoadmapTree $roadmap -FilePath $visualizationPath
    Write-Host "Visualisation créée: $visualizationPath" -ForegroundColor Green
    
    Write-Host "`nTests terminés avec succès!" -ForegroundColor Cyan
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
