# Test-SelectRoadmapTask.ps1
# Script pour tester la fonction Select-RoadmapTask

# Importer les fonctions Ã  tester
$dependenciesFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapWithDependencies.ps1"
$selectFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\Select-RoadmapTask.ps1"

. $dependenciesFunctionPath
. $selectFunctionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier markdown de test
$testMarkdownPath = Join-Path -Path $testDir -ChildPath "test-select.md"
$testMarkdown = @"
# Roadmap de Test pour SÃ©lection

Ceci est une roadmap de test pour valider la fonction Select-RoadmapTask.

## Planification

- [ ] **PLAN-1** Analyse des besoins
  - [x] **PLAN-1.1** Recueillir les exigences @john #important
  - [ ] **PLAN-1.2** Analyser la faisabilitÃ© @depends:PLAN-1.1
    - [~] **PLAN-1.2.1** Ã‰tude technique @start:2023-07-05 @end:2023-07-10
    - [!] **PLAN-1.2.2** Ã‰valuation des coÃ»ts P1 ref:PLAN-1.1

## DÃ©veloppement

- [ ] **DEV-1** ImplÃ©mentation @depends:PLAN-1
  - [ ] **DEV-1.1** DÃ©velopper le backend @sarah @estimate:5d
  - [ ] **DEV-1.2** CrÃ©er l'interface utilisateur ref:DEV-1.1

## Tests

- [ ] **TEST-1** Tests unitaires @depends:DEV-1.1
- [ ] **TEST-2** Tests d'intÃ©gration @depends:DEV-1,TEST-1
- [x] **TEST-3** Tests de performance @depends:TEST-2 @john #performance
"@

$testMarkdown | Out-File -FilePath $testMarkdownPath -Encoding UTF8

Write-Host "Fichier de test crÃ©Ã©: $testMarkdownPath" -ForegroundColor Green

try {
    # Convertir le markdown en roadmap
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath $testMarkdownPath -IncludeMetadata -DetectDependencies

    # Test 1: SÃ©lection par statut
    Write-Host "`nTest 1: SÃ©lection par statut" -ForegroundColor Cyan
    $completeTasks = Select-RoadmapTask -Roadmap $roadmap -Status "Complete"

    Write-Host "TÃ¢ches complÃ©tÃ©es:" -ForegroundColor Yellow
    foreach ($task in $completeTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($completeTasks.Count -gt 0) {
        Write-Host "âœ“ SÃ©lection par statut fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tÃ¢ches complÃ©tÃ©es: $($completeTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— SÃ©lection par statut ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 2: SÃ©lection par ID
    Write-Host "`nTest 2: SÃ©lection par ID" -ForegroundColor Cyan
    $planTasks = Select-RoadmapTask -Roadmap $roadmap -Id "PLAN*"

    Write-Host "TÃ¢ches avec ID commenÃ§ant par PLAN:" -ForegroundColor Yellow
    foreach ($task in $planTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($planTasks.Count -gt 0) {
        Write-Host "âœ“ SÃ©lection par ID fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tÃ¢ches avec ID commenÃ§ant par PLAN: $($planTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— SÃ©lection par ID ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 3: SÃ©lection par mÃ©tadonnÃ©es
    Write-Host "`nTest 3: SÃ©lection par mÃ©tadonnÃ©es" -ForegroundColor Cyan
    $johnTasks = Select-RoadmapTask -Roadmap $roadmap -MetadataKey "Assignee" -MetadataValue "john"

    Write-Host "TÃ¢ches assignÃ©es Ã  John:" -ForegroundColor Yellow
    foreach ($task in $johnTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($johnTasks.Count -gt 0) {
        Write-Host "âœ“ SÃ©lection par mÃ©tadonnÃ©es fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tÃ¢ches assignÃ©es Ã  John: $($johnTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— SÃ©lection par mÃ©tadonnÃ©es ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 4: SÃ©lection par dÃ©pendances
    Write-Host "`nTest 4: SÃ©lection par dÃ©pendances" -ForegroundColor Cyan
    $tasksWithDependencies = Select-RoadmapTask -Roadmap $roadmap -HasDependencies

    Write-Host "TÃ¢ches avec dÃ©pendances:" -ForegroundColor Yellow
    foreach ($task in $tasksWithDependencies) {
        $dependencies = $task.Dependencies | ForEach-Object { $_.Id }
        Write-Host "  - $($task.Id): $($task.Title) (dÃ©pend de: $($dependencies -join ', '))" -ForegroundColor Yellow
    }

    if ($tasksWithDependencies.Count -gt 0) {
        Write-Host "âœ“ SÃ©lection par dÃ©pendances fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tÃ¢ches avec dÃ©pendances: $($tasksWithDependencies.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— SÃ©lection par dÃ©pendances ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 5: SÃ©lection par section
    Write-Host "`nTest 5: SÃ©lection par section" -ForegroundColor Cyan
    $devTasks = Select-RoadmapTask -Roadmap $roadmap -SectionTitle "DÃ©veloppement"

    Write-Host "TÃ¢ches dans la section DÃ©veloppement:" -ForegroundColor Yellow
    foreach ($task in $devTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($devTasks.Count -gt 0) {
        Write-Host "âœ“ SÃ©lection par section fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tÃ¢ches dans la section DÃ©veloppement: $($devTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— SÃ©lection par section ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 6: SÃ©lection avec inclusion des sous-tÃ¢ches
    Write-Host "`nTest 6: SÃ©lection avec inclusion des sous-tÃ¢ches" -ForegroundColor Cyan
    $planTasksWithSubTasks = Select-RoadmapTask -Roadmap $roadmap -Id "PLAN-1" -IncludeSubTasks

    Write-Host "TÃ¢che PLAN-1 avec sous-tÃ¢ches:" -ForegroundColor Yellow

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
        Write-Host "âœ“ SÃ©lection avec inclusion des sous-tÃ¢ches fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre total de tÃ¢ches et sous-tÃ¢ches: $totalTaskCount" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— SÃ©lection avec inclusion des sous-tÃ¢ches ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 7: SÃ©lection avec aplatissement
    Write-Host "`nTest 7: SÃ©lection avec aplatissement" -ForegroundColor Cyan
    $flattenedTasks = Select-RoadmapTask -Roadmap $roadmap -Id "PLAN*" -Flatten

    Write-Host "TÃ¢ches PLAN aplaties:" -ForegroundColor Yellow
    foreach ($task in $flattenedTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($flattenedTasks.Count -gt 0) {
        Write-Host "âœ“ SÃ©lection avec aplatissement fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre de tÃ¢ches aplaties: $($flattenedTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— SÃ©lection avec aplatissement ne fonctionne pas correctement" -ForegroundColor Red
    }

    # Test 8: SÃ©lection avec First
    Write-Host "`nTest 8: SÃ©lection avec First" -ForegroundColor Cyan
    $allTasksFlattened = Select-RoadmapTask -Roadmap $roadmap -Flatten
    $firstTasks = Select-RoadmapTask -Roadmap $roadmap -First 3 -Flatten

    Write-Host "PremiÃ¨res 3 tÃ¢ches:" -ForegroundColor Yellow
    foreach ($task in $firstTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    # VÃ©rifier que le nombre de tÃ¢ches retournÃ©es est correct
    # Si le nombre total de tÃ¢ches est infÃ©rieur Ã  3, on s'attend Ã  avoir toutes les tÃ¢ches
    $expectedCount = [Math]::Min(3, $allTasksFlattened.Count)

    if ($firstTasks.Count -eq $expectedCount) {
        Write-Host "âœ“ SÃ©lection avec First fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre total de tÃ¢ches: $($allTasksFlattened.Count)" -ForegroundColor Yellow
        Write-Host "  Nombre de tÃ¢ches retournÃ©es: $($firstTasks.Count)" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— SÃ©lection avec First ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Nombre total de tÃ¢ches: $($allTasksFlattened.Count)" -ForegroundColor Red
        Write-Host "  Nombre de tÃ¢ches retournÃ©es: $($firstTasks.Count)" -ForegroundColor Red
        Write-Host "  Nombre attendu: $expectedCount" -ForegroundColor Red
    }

    # Test 9: SÃ©lection avec Last
    Write-Host "`nTest 9: SÃ©lection avec Last" -ForegroundColor Cyan
    $lastTasks = Select-RoadmapTask -Roadmap $roadmap -Last 2

    Write-Host "DerniÃ¨res 2 tÃ¢ches:" -ForegroundColor Yellow
    foreach ($task in $lastTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    if ($lastTasks.Count -eq 2) {
        Write-Host "âœ“ SÃ©lection avec Last fonctionne correctement" -ForegroundColor Green
    } else {
        Write-Host "âœ— SÃ©lection avec Last ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Nombre de tÃ¢ches retournÃ©es: $($lastTasks.Count)" -ForegroundColor Red
    }

    # Test 10: SÃ©lection avec Skip
    Write-Host "`nTest 10: SÃ©lection avec Skip" -ForegroundColor Cyan
    $allTasksFlattened = Select-RoadmapTask -Roadmap $roadmap -Flatten
    $skippedTasks = Select-RoadmapTask -Roadmap $roadmap -Skip 5 -Flatten

    Write-Host "TÃ¢ches aprÃ¨s avoir sautÃ© les 5 premiÃ¨res:" -ForegroundColor Yellow
    foreach ($task in $skippedTasks) {
        Write-Host "  - $($task.Id): $($task.Title)" -ForegroundColor Yellow
    }

    # VÃ©rifier que le nombre de tÃ¢ches retournÃ©es est correct
    # Si le nombre total de tÃ¢ches est infÃ©rieur ou Ã©gal Ã  5, on s'attend Ã  avoir 0 tÃ¢che
    # Sinon, on s'attend Ã  avoir (nombre total - 5) tÃ¢ches
    $expectedCount = [Math]::Max(0, $allTasksFlattened.Count - 5)

    if ($skippedTasks.Count -eq $expectedCount) {
        Write-Host "âœ“ SÃ©lection avec Skip fonctionne correctement" -ForegroundColor Green
        Write-Host "  Nombre total de tÃ¢ches: $($allTasksFlattened.Count)" -ForegroundColor Yellow
        Write-Host "  Nombre de tÃ¢ches aprÃ¨s Skip: $($skippedTasks.Count)" -ForegroundColor Yellow
        Write-Host "  Nombre attendu: $expectedCount" -ForegroundColor Yellow
    } else {
        Write-Host "âœ— SÃ©lection avec Skip ne fonctionne pas correctement" -ForegroundColor Red
        Write-Host "  Nombre total de tÃ¢ches: $($allTasksFlattened.Count)" -ForegroundColor Red
        Write-Host "  Nombre de tÃ¢ches aprÃ¨s Skip: $($skippedTasks.Count)" -ForegroundColor Red
        Write-Host "  Nombre attendu: $expectedCount" -ForegroundColor Red
    }

    Write-Host "`nTous les tests sont terminÃ©s." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors des tests: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
} finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRÃ©pertoire de test nettoyÃ©: $testDir" -ForegroundColor Gray
    }
}
