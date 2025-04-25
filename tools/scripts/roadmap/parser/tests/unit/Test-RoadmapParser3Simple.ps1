# Test-RoadmapParser3Simple.ps1
# Script pour tester le module RoadmapParser3Simple

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser3Simple.psm1"
Write-Host "Module path: $modulePath"
Write-Host "Module exists: $(Test-Path -Path $modulePath)"

# Creer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $PSScriptRoot -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider le module RoadmapParser3Simple.

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

try {
    Import-Module $modulePath -Force -Verbose
    Write-Host "Module imported successfully."
    
    # Tester ConvertFrom-MarkdownToRoadmapTree
    Write-Host "Testing ConvertFrom-MarkdownToRoadmapTree..."
    $roadmap = ConvertFrom-MarkdownToRoadmapTree -FilePath $testMarkdownPath
    Write-Host "Roadmap created with $($roadmap.AllTasks.Count) tasks."
    
    # Afficher les taches
    Write-Host "Tasks:"
    foreach ($task in $roadmap.AllTasks) {
        $indent = "  " * $task.Level
        $statusMark = switch ($task.Status) {
            ([TaskStatus]::Complete) { "[x]" }
            ([TaskStatus]::InProgress) { "[~]" }
            ([TaskStatus]::Blocked) { "[!]" }
            default { "[ ]" }
        }
        Write-Host "$indent- $statusMark $($task.Id) $($task.Title)"
    }
    
    Write-Host "Test completed successfully."
}
catch {
    Write-Host "Error: $_"
    Write-Host $_.ScriptStackTrace
}
finally {
    # Supprimer le fichier de test
    if (Test-Path -Path $testMarkdownPath) {
        Remove-Item -Path $testMarkdownPath -Force
    }
}
