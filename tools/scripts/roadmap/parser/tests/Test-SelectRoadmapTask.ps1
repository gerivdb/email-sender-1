# Test-SelectRoadmapTask.ps1
# Script pour tester la fonction Select-RoadmapTask

# Importer les fonctions à tester
$dependenciesFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapWithDependencies.ps1"
$selectFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Select-RoadmapTask.ps1"

. $dependenciesFunctionPath
. $selectFunctionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-select.md"
$testMarkdown = @"
# Roadmap de Test pour Sélection

Ceci est une roadmap de test pour valider la fonction Select-RoadmapTask.

## Planification

- [ ] **PLAN-1** Analyse des besoins
  - [x] **PLAN-1.1** Recueillir les exigences @john #important
  - [ ] **PLAN-1.2** Analyser la faisabilité @depends:PLAN-1.1
    - [~] **PLAN-1.2.1** Étude technique @start:2023-07-05 @end:2023-07-10
    - [!] **PLAN-1.2.2** Évaluation des coûts P1 ref:PLAN-1.1

## Développement

- [ ] **DEV-1** Implémentation @depends:PLAN-1
  - [ ] **DEV-1.1** Développer le backend @sarah @estimate:5d
  - [ ] **DEV-1.2** Créer l'interface utilisateur ref:DEV-1.1

## Tests

- [ ] **TEST-1** Tests unitaires @depends:DEV-1.1
- [ ] **TEST-2** Tests d'intégration @depends:DEV-1,TEST-1
- [x] **TEST-3** Tests de performance @depends:TEST-2 @john #performance
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test créé: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies

    # Test 1: Sélection par statut
    Write-Host "`nTest 1: Sélection par statut" -ForegroundColor Cyan
    $completeTasks = Select-RoadmapTask -Roadmap $roadmap -Status "Complete"

    Write-Host "Tâches complétées:" -ForegroundColor Yellow
    foreach ($task in $completeTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($completeTasks.Count -gt 0) {
        Write-Host "✓ Sélection par statut fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tâches complétées: $($completeTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Sélection par statut ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 2: Sélection par ID
    Write-Host "`nTest 2: Sélection par ID" -ForegroundColor Cyan
    $planTasks = Select-RoadmapTask -Roadmap $roadmap -Id "PLAN*"

    Write-Host "Tâches avec ID commençant par PLAN:" -ForegroundColor Yellow
    foreach ($task in $planTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($planTasks.Count -gt 0) {
        Write-Host "✓ Sélection par ID fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tâches avec ID commençant par PLAN: $($planTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Sélection par ID ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 3: Sélection par métadonnées
    Write-Host "`nTest 3: Sélection par métadonnées" -ForegroundColor Cyan
    $johnTasks = Select-RoadmapTask -Roadmap $roadmap -MetadataKey "Assignee" -MetadataValue "john"

    Write-Host "Tâches assignées à John:" -ForegroundColor Yellow
    foreach ($task in $johnTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($johnTasks.Count -gt 0) {
        Write-Host "✓ Sélection par métadonnées fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tâches assignées à John: $($johnTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Sélection par métadonnées ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 4: Sélection par dépendances
    Write-Host "`nTest 4: Sélection par dépendances" -ForegroundColor Cyan
    $tasksWithDependencies = Select-RoadmapTask -Roadmap $roadmap -HasDependencies

    Write-Host "Tâches avec dépendances:" -ForegroundColor Yellow
    foreach ($task in $tasksWithDependencies) {
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        Write-Host "  - $($task.Id): $($task.Title) (dépend de: $($dependencies -join ', '))" -ForegroundColor Yellow
    }

    if ($tasksWithDependencies.Count -gt 0) {
        Write-Host "✓ Sélection par dépendances fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tâches avec dépendances: $($tasksWithDependencies.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Sélection par dépendances ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 5: Sélection par section
    Write-Host "`nTest 5: Sélection par section" -ForegroundColor Cyan
    $devTasks = Select-RoadmapTask -Roadmap $roadmap -SectionTitle "Développement"

    Write-Host "Tâches dans la section Développement:" -ForegroundColor Yellow
    foreach ($task in $devTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($devTasks.Count -gt 0) {
        Write-Host "✓ Sélection par section fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tâches dans la section Développement: $($devTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Sélection par section ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 6: Sélection avec inclusion des sous-tâches
    Write-Host "`nTest 6: Sélection avec inclusion des sous-tâches" -ForegroundColor Cyan
    $planTasksWithSubTasks = Select-RoadmapTask -Roadmap $roadmap -Id "PLAN-1" -IncludeSubTasks

    Write-Host "Tâche PLAN-1 avec sous-tâches:" -ForegroundColor Yellow

    function Show-TaskHierarchy {
        param (
            [PSCustomObject]$Task,
            [int]$Indent = 0
        )

        $indentation = "  " * $Indent
        Write-Host "$indentation- $($Task.Id): $($Task.Title)" -ForegroundColor Yellow

        foreach ($subTask in $Task.SubTasks) {
            Show-TaskHierarchy -Task $subTask -Indent ($Indent + 1)
        }
    }

    foreach ($task in $planTasksWithSubTasks) {
        Show-TaskHierarchy -Task $task
    }

    $totalTaskCount = 0
    function Measure-TaskCount {
        param (
            [PSCustomObject]$Task
        )

        $count = 1
        foreach ($subTask in $Task.SubTasks) {
            $count += (Measure-TaskCount -Task $subTask)
        }

        return $count
    }

    foreach ($task in $planTasksWithSubTasks) {
        $totalTaskCount += (Measure-TaskCount -Task $task)
    }

    if ($totalTaskCount -gt 1) {
        Write-Host "✓ Sélection avec inclusion des sous-tâches fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre total de tâches et sous-tâches: $totalTaskCount" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Sélection avec inclusion des sous-tâches ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 7: Sélection avec aplatissement
    Write-Host "`nTest 7: Sélection avec aplatissement" -ForegroundColor Cyan
    $flattenedTasks = Select-RoadmapTask -Roadmap $roadmap -Id "PLAN*" -Flatten

    Write-Host "Tâches PLAN aplaties:" -ForegroundColor Yellow
    foreach ($task in $flattenedTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($flattenedTasks.Count -gt 0) {
        Write-Host "✓ Sélection avec aplatissement fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tâches aplaties: $($flattenedTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Sélection avec aplatissement ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 8: Sélection avec First
    Write-Host "`nTest 8: Sélection avec First" -ForegroundColor Cyan
    $allTasksFlattened = Select-RoadmapTask -Roadmap $roadmap -Flatten
    $firstTasks = Select-RoadmapTask -Roadmap $roadmap -First 3 -Flatten

    Write-Host "Premières 3 tâches:" -ForegroundColor Yellow
    foreach ($task in $firstTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    # Vérifier que le nombre de tâches retournées est correct
    # Si le nombre total de tâches est inférieur à 3, on s'attend à avoir toutes les tâches
    $expectedCount = [Math]::Min(3, $allTasksFlattened.Count)

    if ($firstTasks.Count -eq $expectedCount) {
        Write-Host "✓ Sélection avec First fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre total de tâches: $($allTasksFlattened.Count)" -ForegroundColor Yellow
        Write-Host "  Nombre de tâches retournées: $($firstTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Sélection avec First ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Nombre total de tâches: $($allTasksFlattened.Count)" -ForegroundColor Red
        Write-Host "  Nombre de tâches retournées: $($firstTasks.Count)" -ForegroundColor Red
        Write-Host "  Nombre attendu: $expectedCount" -ForegroundColor Red
    }

    # Test 9: Sélection avec Last
    Write-Host "`nTest 9: Sélection avec Last" -ForegroundColor Cyan
    $lastTasks = Select-RoadmapTask -Roadmap $roadmap -Last 2

    Write-Host "Dernières 2 tâches:" -ForegroundColor Yellow
    foreach ($task in $lastTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($lastTasks.Count -eq 2) {
        Write-Host "✓ Sélection avec Last fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "✗ Sélection avec Last ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Nombre de tâches retournées: $($lastTasks.Count)" -ForegroundColor Red
    }

    # Test 10: Sélection avec Skip
    Write-Host "`nTest 10: Sélection avec Skip" -ForegroundColor Cyan
    $allTasksFlattened = Select-RoadmapTask -Roadmap $roadmap -Flatten
    $skippedTasks = Select-RoadmapTask -Roadmap $roadmap -Skip 5 -Flatten

    Write-Host "Tâches après avoir sauté les 5 premières:" -ForegroundColor Yellow
    foreach ($task in $skippedTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    # Vérifier que le nombre de tâches retournées est correct
    # Si le nombre total de tâches est inférieur ou égal à 5, on s'attend à avoir 0 tâche
    # Sinon, on s'attend à avoir (nombre total - 5) tâches
    $expectedCount = [Math]::Max(0, $allTasksFlattened.Count - 5)

    if ($skippedTasks.Count -eq $expectedCount) {
        Write-Host "✓ Sélection avec Skip fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre total de tâches: $($allTasksFlattened.Count)" -ForegroundColor Yellow
        Write-Host "  Nombre de tâches après Skip: $($skippedTasks.Count)" -ForegroundColor Yellow
        Write-Host "  Nombre attendu: $expectedCount" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Sélection avec Skip ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Nombre total de tâches: $($allTasksFlattened.Count)" -ForegroundColor Red
        Write-Host "  Nombre de tâches après Skip: $($skippedTasks.Count)" -ForegroundColor Red
        Write-Host "  Nombre attendu: $expectedCount" -ForegroundColor Red
    }

    Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRépertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
