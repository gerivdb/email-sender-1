# Test-RoadmapParser3SimpleExport.ps1
# Script pour tester les fonctions d'export du module RoadmapParser3Simple

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser3Simple2.psm1"
Write-Host "Module path: $modulePath"
Write-Host "Module exists: $(Test-Path -Path $modulePath)"

# Creer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $PSScriptRoot -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider les fonctions d'export du module RoadmapParser3Simple.

## Section 1

- [ ] **1** Tache 1
  - [x] **1.1** Tache 1.1
  - [ ] **1.2** Tache 1.2
    - [~] **1.2.1** Tache 1.2.1
    - [!] **1.2.2** Tache 1.2.2

## Section 2

- [ ] **2** Tache 2
  - [ ] **2.1** Tache 2.1
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

# Creer un dossier pour les fichiers de sortie
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

try {
    Import-Module $modulePath -Force -Verbose
    Write-Host "Module imported successfully."

    # Convertir le fichier markdown en arbre de roadmap
    Write-Host "Converting markdown file to roadmap tree..."
    $roadmap = ConvertFrom-MarkdownToRoadmapTree -FilePath $testMarkdownPath
    Write-Host "Roadmap created with $($roadmap.AllTasks.Count) tasks."

    # Tester Export-RoadmapTreeToJson
    Write-Host "Testing Export-RoadmapTreeToJson..."
    $jsonPath = Join-Path -Path $outputDir -ChildPath "roadmap.json"
    Export-RoadmapTreeToJson -RoadmapTree $roadmap -FilePath $jsonPath
    Write-Host "JSON file created: $jsonPath"

    # Tester Export-RoadmapTreeToMarkdown
    Write-Host "Testing Export-RoadmapTreeToMarkdown..."
    $markdownPath = Join-Path -Path $outputDir -ChildPath "roadmap.md"
    Export-RoadmapTreeToMarkdown -RoadmapTree $roadmap -FilePath $markdownPath
    Write-Host "Markdown file created: $markdownPath"

    # Tester Import-RoadmapTreeFromJson
    Write-Host "Testing Import-RoadmapTreeFromJson..."
    $importedRoadmap = Import-RoadmapTreeFromJson -FilePath $jsonPath
    Write-Host "Roadmap imported with $($importedRoadmap.AllTasks.Count) tasks."

    # Tester New-RoadmapReport
    Write-Host "Testing New-RoadmapReport..."
    $reportPath = Join-Path -Path $outputDir -ChildPath "report.md"
    $report = New-RoadmapReport -RoadmapTree $roadmap -FilePath $reportPath
    Write-Host "Report created: $reportPath"

    # Tester Get-RoadmapStatistics
    Write-Host "Testing Get-RoadmapStatistics..."
    $stats = Get-RoadmapStatistics -RoadmapTree $roadmap
    Write-Host "Statistics calculated:"
    Write-Host "  - Total tasks: $($stats.TotalTasks)"
    Write-Host "  - Complete tasks: $($stats.CompleteTasks) ($($stats.CompletePercentage)%)"
    Write-Host "  - In progress tasks: $($stats.InProgressTasks) ($($stats.InProgressPercentage)%)"
    Write-Host "  - Blocked tasks: $($stats.BlockedTasks) ($($stats.BlockedPercentage)%)"
    Write-Host "  - Incomplete tasks: $($stats.IncompleteTasks) ($($stats.IncompletePercentage)%)"

    # Tester New-RoadmapVisualization
    Write-Host "Testing New-RoadmapVisualization..."
    $visualizationPath = Join-Path -Path $outputDir -ChildPath "visualization.md"
    $visualization = New-RoadmapVisualization -RoadmapTree $roadmap -FilePath $visualizationPath
    Write-Host "Visualization created: $visualizationPath"

    Write-Host "Tests completed successfully."
} catch {
    Write-Host "Error: $_"
    Write-Host $_.ScriptStackTrace
} finally {
    # Supprimer le fichier de test
    if (Test-Path -Path $testMarkdownPath) {
        Remove-Item -Path $testMarkdownPath -Force
    }
}
