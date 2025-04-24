# Test-ConvertFromMarkdownToRoadmapTree.ps1
# Script pour tester la fonction ConvertFrom-MarkdownToRoadmapTree

# Créer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $PSScriptRoot -ChildPath "test-roadmap.md"
$testMarkdown = @"
# Roadmap de Test

Ceci est une roadmap de test pour valider la fonction ConvertFrom-MarkdownToRoadmapTree.

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

# Importer le module RoadmapParser3
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser3.psm1"
Import-Module $modulePath -Force

# Tester la fonction ConvertFrom-MarkdownToRoadmapTree
try {
    Write-Host "Test de la fonction ConvertFrom-MarkdownToRoadmapTree..." -ForegroundColor Cyan

    # Afficher le contenu du fichier de test
    Write-Host "Contenu du fichier de test:" -ForegroundColor Cyan
    Get-Content -Path $testMarkdownPath | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

    # Importer le module avec verbose
    Write-Host "Importation du module..." -ForegroundColor Cyan
    Import-Module $modulePath -Force -Verbose

    # Vérifier que les fonctions sont disponibles
    Write-Host "Fonctions disponibles:" -ForegroundColor Cyan
    Get-Command -Module RoadmapParser3 | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }

    # Tester la création d'un arbre de roadmap
    Write-Host "Test de la création d'un arbre de roadmap..." -ForegroundColor Cyan
    $tree = New-RoadmapTree -Title "Test" -Description "Test"
    Write-Host "Arbre créé: $($tree.Title)" -ForegroundColor Green

    # Tester la création d'une tâche
    Write-Host "Test de la création d'une tâche..." -ForegroundColor Cyan
    $task = New-RoadmapTask -Id "1" -Title "Test" -Status ([TaskStatus]::Incomplete)
    Write-Host "Tâche créée: $($task.Id) - $($task.Title)" -ForegroundColor Green

    # Tester l'ajout d'une tâche à l'arbre
    Write-Host "Test de l'ajout d'une tâche à l'arbre..." -ForegroundColor Cyan
    Add-RoadmapTask -RoadmapTree $tree -Task $task -ParentTask $null
    Write-Host "Tâche ajoutée: $($tree.AllTasks.Count) tâches dans l'arbre" -ForegroundColor Green

    # Tester la fonction ConvertFrom-MarkdownToRoadmapTree
    Write-Host "Test de la fonction ConvertFrom-MarkdownToRoadmapTree..." -ForegroundColor Cyan
    $roadmap = ConvertFrom-MarkdownToRoadmapTree -FilePath $testMarkdownPath

    # Vérifier que le titre et la description ont été correctement extraits
    Write-Host "Titre: $($roadmap.Title)" -ForegroundColor Green
    Write-Host "Description: $($roadmap.Description)" -ForegroundColor Green

    # Vérifier que les tâches ont été correctement extraites
    Write-Host "Nombre de tâches: $($roadmap.AllTasks.Count)" -ForegroundColor Green

    # Afficher les tâches
    Write-Host "Tâches:" -ForegroundColor Green
    foreach ($task in $roadmap.AllTasks) {
        $indent = "  " * $task.Level
        $statusMark = switch ($task.Status) {
            ([TaskStatus]::Complete) { "[x]" }
            ([TaskStatus]::InProgress) { "[~]" }
            ([TaskStatus]::Blocked) { "[!]" }
            default { "[ ]" }
        }
        Write-Host "$indent- $statusMark $($task.Id) $($task.Title)" -ForegroundColor Yellow
    }

    Write-Host "Test réussi!" -ForegroundColor Green
} catch {
    Write-Host "Test échoué: $_" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Supprimer le fichier de test
    if (Test-Path -Path $testMarkdownPath) {
        Remove-Item -Path $testMarkdownPath -Force
    }
}
