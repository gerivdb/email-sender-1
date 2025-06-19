# =========================================================================
# Script: validate-phase1-implementation.ps1
# Objectif: Valider l'implémentation complète des tâches 009-022
# =========================================================================

[CmdletBinding()]
param(
    [string]$ScriptsDir = "scripts/phase1",
    [string]$OutputDir = "output/phase1"
)

$ErrorActionPreference = "Stop"

Write-Host "🔍 VALIDATION IMPLÉMENTATION PHASE 1.2 et 1.3" -ForegroundColor Cyan
Write-Host "=" * 60

# Tâches à valider (selection lines 382-493)
$expectedTasks = @(
    @{ Id = "009"; Name = "Scanner Workflows N8N"; File = "task-009-scanner-workflows-n8n.ps1"; Output = "n8n-workflows-export.json" },
    @{ Id = "010"; Name = "Classifier Types Workflows"; File = "task-010-classifier-types-workflows.ps1"; Output = "workflow-classification.yaml" },
    @{ Id = "011"; Name = "Extraire Nodes Email Critiques"; File = "task-011-extraire-nodes-email-critiques.ps1"; Output = "critical-email-nodes.json" },
    @{ Id = "012"; Name = "Mapper Triggers Workflows"; File = "task-012-mapper-triggers-workflows.ps1"; Output = "triggers-mapping.md" },
    @{ Id = "013"; Name = "Identifier Dépendances Workflows"; File = "task-013-identifier-dependances-workflows.ps1"; Output = "workflow-dependencies.graphml" },
    @{ Id = "014"; Name = "Documenter Points Intégration"; File = "task-014-documenter-points-integration.ps1"; Output = "integration-endpoints.yaml" },
    @{ Id = "015"; Name = "Extraire Schémas Données N8N"; File = "task-015-extraire-schemas-donnees-n8n.ps1"; Output = "n8n-data-schemas.json" },
    @{ Id = "016"; Name = "Identifier Transformations Données"; File = "task-016-identifier-transformations-donnees.ps1"; Output = "data-transformations.md" },
    @{ Id = "017"; Name = "Spécifier Interface N8N→Go"; File = "task-017-specifier-interface-n8n-go.ps1"; Output = "interface-n8n-to-go.go" },
    @{ Id = "018"; Name = "Spécifier Interface Go→N8N"; File = "task-018-specifier-interface-go-n8n.ps1"; Output = "interface-go-to-n8n.yaml" },
    @{ Id = "019"; Name = "Définir Protocole Synchronisation"; File = "task-019-definir-protocole-synchronisation.ps1"; Output = "sync-protocol.md" },
    @{ Id = "020"; Name = "Établir Stratégie Blue-Green"; File = "task-020-etablir-strategie-blue-green.ps1"; Output = "migration-strategy.md" },
    @{ Id = "021"; Name = "Définir Métriques Performance"; File = "task-021-definir-metriques-performance.ps1"; Output = "performance-kpis.yaml" },
    @{ Id = "022"; Name = "Planifier Tests A/B"; File = "task-022-planifier-tests-ab.ps1"; Output = "ab-testing-plan.md" }
)

$validationResults = @()

Write-Host "🔍 Validation des scripts..." -ForegroundColor Yellow

foreach ($task in $expectedTasks) {
    $scriptPath = Join-Path $ScriptsDir $task.File
    $result = @{
        TaskId = $task.Id
        TaskName = $task.Name
        ScriptExists = Test-Path $scriptPath
        ScriptPath = $scriptPath
        ExpectedOutput = $task.Output
        Status = "❌ MANQUANT"
    }
    
    if ($result.ScriptExists) {
        $result.Status = "✅ PRÉSENT"
        Write-Host "  ✅ Task $($task.Id): $($task.Name)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Task $($task.Id): $($task.Name) - SCRIPT MANQUANT" -ForegroundColor Red
    }
    
    $validationResults += $result
}

# Statistiques de validation
$totalTasks = $expectedTasks.Count
$implementedTasks = ($validationResults | Where-Object { $_.ScriptExists }).Count
$missingTasks = $totalTasks - $implementedTasks
$completionRate = [math]::Round(($implementedTasks / $totalTasks) * 100, 2)

Write-Host ""
Write-Host "📊 RÉSULTATS DE VALIDATION" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host "Total tâches requises    : $totalTasks" -ForegroundColor White
Write-Host "Tâches implémentées      : $implementedTasks" -ForegroundColor Green
Write-Host "Tâches manquantes        : $missingTasks" -ForegroundColor $(if ($missingTasks -eq 0) { "Green" } else { "Red" })
Write-Host "Taux de completion       : $completionRate%" -ForegroundColor $(if ($completionRate -eq 100) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "🎯 COUVERTURE PAR PHASE" -ForegroundColor Cyan
Write-Host "=" * 60

# Phase 1.2 - Mapping Workflows N8N Existants (tâches 009-016)
$phase12Tasks = $validationResults | Where-Object { [int]$_.TaskId -ge 9 -and [int]$_.TaskId -le 16 }
$phase12Implemented = ($phase12Tasks | Where-Object { $_.ScriptExists }).Count
$phase12Rate = [math]::Round(($phase12Implemented / $phase12Tasks.Count) * 100, 2)

Write-Host "Phase 1.2 - Mapping Workflows N8N :" -ForegroundColor Yellow
Write-Host "  Tâches 009-016: $phase12Implemented/$($phase12Tasks.Count) ($phase12Rate%)" -ForegroundColor $(if ($phase12Rate -eq 100) { "Green" } else { "Yellow" })

# Phase 1.3 - Spécifications Techniques Bridge (tâches 017-022)
$phase13Tasks = $validationResults | Where-Object { [int]$_.TaskId -ge 17 -and [int]$_.TaskId -le 22 }
$phase13Implemented = ($phase13Tasks | Where-Object { $_.ScriptExists }).Count
$phase13Rate = [math]::Round(($phase13Implemented / $phase13Tasks.Count) * 100, 2)

Write-Host "Phase 1.3 - Spécifications Bridge :" -ForegroundColor Yellow
Write-Host "  Tâches 017-022: $phase13Implemented/$($phase13Tasks.Count) ($phase13Rate%)" -ForegroundColor $(if ($phase13Rate -eq 100) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "📋 DÉTAIL PAR SOUS-PHASE" -ForegroundColor Cyan
Write-Host "=" * 60

# 1.2.1 Inventaire Workflows Email (009-011)
Write-Host "1.2.1 Inventaire Workflows Email (009-011):" -ForegroundColor White
foreach ($task in $expectedTasks[0..2]) {
    $status = if ((Test-Path (Join-Path $ScriptsDir $task.File))) { "✅" } else { "❌" }
    Write-Host "  $status Task $($task.Id): $($task.Name)" -ForegroundColor $(if ($status -eq "✅") { "Green" } else { "Red" })
}

# 1.2.2 Analyser Intégrations Critiques (012-014)
Write-Host "1.2.2 Analyser Intégrations Critiques (012-014):" -ForegroundColor White
foreach ($task in $expectedTasks[3..5]) {
    $status = if ((Test-Path (Join-Path $ScriptsDir $task.File))) { "✅" } else { "❌" }
    Write-Host "  $status Task $($task.Id): $($task.Name)" -ForegroundColor $(if ($status -eq "✅") { "Green" } else { "Red" })
}

# 1.2.3 Analyser Formats et Structures Données (015-016)
Write-Host "1.2.3 Analyser Formats et Structures (015-016):" -ForegroundColor White
foreach ($task in $expectedTasks[6..7]) {
    $status = if ((Test-Path (Join-Path $ScriptsDir $task.File))) { "✅" } else { "❌" }
    Write-Host "  $status Task $($task.Id): $($task.Name)" -ForegroundColor $(if ($status -eq "✅") { "Green" } else { "Red" })
}

# 1.3.1 Définir Interfaces Communication (017-019)
Write-Host "1.3.1 Définir Interfaces Communication (017-019):" -ForegroundColor White
foreach ($task in $expectedTasks[8..10]) {
    $status = if ((Test-Path (Join-Path $ScriptsDir $task.File))) { "✅" } else { "❌" }
    Write-Host "  $status Task $($task.Id): $($task.Name)" -ForegroundColor $(if ($status -eq "✅") { "Green" } else { "Red" })
}

# 1.3.2 Planifier Migration Progressive (020-022)
Write-Host "1.3.2 Planifier Migration Progressive (020-022):" -ForegroundColor White
foreach ($task in $expectedTasks[11..13]) {
    $status = if ((Test-Path (Join-Path $ScriptsDir $task.File))) { "✅" } else { "❌" }
    Write-Host "  $status Task $($task.Id): $($task.Name)" -ForegroundColor $(if ($status -eq "✅") { "Green" } else { "Red" })
}

Write-Host ""
Write-Host "🎯 VALIDATION FINALE" -ForegroundColor Cyan
Write-Host "=" * 60

if ($completionRate -eq 100) {
    Write-Host "🎉 SUCCÈS COMPLET !" -ForegroundColor Green
    Write-Host "✅ Toutes les tâches atomiques 009-022 sont implémentées" -ForegroundColor Green
    Write-Host "✅ Phase 1.2 - Mapping Workflows N8N : COMPLÈTE" -ForegroundColor Green
    Write-Host "✅ Phase 1.3 - Spécifications Bridge : COMPLÈTE" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 PRÊT POUR EXÉCUTION" -ForegroundColor Green
    Write-Host "Tous les scripts sont disponibles dans : $ScriptsDir" -ForegroundColor White
    Write-Host "Les sorties seront générées dans : $OutputDir" -ForegroundColor White
} else {
    Write-Host "⚠️  IMPLÉMENTATION INCOMPLÈTE" -ForegroundColor Yellow
    Write-Host "❌ $missingTasks tâche(s) manquante(s) sur $totalTasks" -ForegroundColor Red
    Write-Host ""
    Write-Host "📝 TÂCHES MANQUANTES:" -ForegroundColor Red
    foreach ($task in ($validationResults | Where-Object { -not $_.ScriptExists })) {
        Write-Host "  ❌ Task $($task.TaskId): $($task.TaskName)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "📄 FICHIERS DE SORTIE ATTENDUS" -ForegroundColor Cyan
Write-Host "=" * 60
foreach ($task in $expectedTasks) {
    Write-Host "Task $($task.Id) → $($task.Output)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✅ VALIDATION TERMINÉE" -ForegroundColor Green
return $completionRate -eq 100
