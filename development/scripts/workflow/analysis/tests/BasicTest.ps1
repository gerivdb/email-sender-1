﻿# Test basique pour les fonctions d'analyse des dÃ©clencheurs et des actions
# Ce script teste les fonctions implÃ©mentÃ©es de maniÃ¨re trÃ¨s simple

# Importer le module Ã  tester
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "WorkflowAnalyzer.psm1"
Import-Module $modulePath -Force

# Charger un workflow de test
$workflowPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "examples\sample-workflow-triggers.json"
$workflow = Get-Content -Path $workflowPath -Raw | ConvertFrom-Json

# Tester les fonctions
Write-Host "Test des fonctions d'analyse des dÃ©clencheurs et des actions" -ForegroundColor Cyan

# Test 1: Get-N8nWorkflowTriggerConditions
Write-Host "`nTest 1: Get-N8nWorkflowTriggerConditions" -ForegroundColor Yellow
$triggerConditions = Get-N8nWorkflowTriggerConditions -Workflow $workflow
Write-Host "Nombre de dÃ©clencheurs trouvÃ©s: $($triggerConditions.Count)" -ForegroundColor White
Write-Host "Types de dÃ©clencheurs: $($triggerConditions | ForEach-Object { $_.TriggerType } | Sort-Object -Unique)" -ForegroundColor White

# Test 2: Get-N8nWorkflowEventSources
Write-Host "`nTest 2: Get-N8nWorkflowEventSources" -ForegroundColor Yellow
$eventSources = Get-N8nWorkflowEventSources -Workflow $workflow
Write-Host "Nombre de sources d'Ã©vÃ©nements trouvÃ©es: $($eventSources.Count)" -ForegroundColor White
Write-Host "Types de sources d'Ã©vÃ©nements: $($eventSources | ForEach-Object { $_.SourceType } | Sort-Object -Unique)" -ForegroundColor White

# Test 3: Get-N8nWorkflowTriggerParameters
Write-Host "`nTest 3: Get-N8nWorkflowTriggerParameters" -ForegroundColor Yellow
$triggerParameters = Get-N8nWorkflowTriggerParameters -Workflow $workflow
Write-Host "Nombre de dÃ©clencheurs analysÃ©s: $($triggerParameters.Count)" -ForegroundColor White
Write-Host "Exemple d'impact: $($triggerParameters[0].Impact | ConvertTo-Json -Compress)" -ForegroundColor White

# Test 4: Get-N8nWorkflowActions
Write-Host "`nTest 4: Get-N8nWorkflowActions" -ForegroundColor Yellow
$actions = Get-N8nWorkflowActions -Workflow $workflow
Write-Host "Nombre d'actions trouvÃ©es: $($actions.Count)" -ForegroundColor White
Write-Host "Types d'actions: $($actions | ForEach-Object { $_.ActionType } | Sort-Object -Unique)" -ForegroundColor White

# Test 5: Get-N8nWorkflowActionParameters
Write-Host "`nTest 5: Get-N8nWorkflowActionParameters" -ForegroundColor Yellow
$actionParameters = Get-N8nWorkflowActionParameters -Workflow $workflow
Write-Host "Nombre d'actions analysÃ©es: $($actionParameters.Count)" -ForegroundColor White
Write-Host "Exemple d'impact: $($actionParameters[0].Impact | ConvertTo-Json -Compress)" -ForegroundColor White

# Test 6: Get-N8nWorkflowActionResults
Write-Host "`nTest 6: Get-N8nWorkflowActionResults" -ForegroundColor Yellow
$actionResults = Get-N8nWorkflowActionResults -Workflow $workflow
Write-Host "Nombre d'actions analysÃ©es: $($actionResults.Count)" -ForegroundColor White
Write-Host "Types de sortie: $($actionResults | ForEach-Object { $_.OutputType } | Sort-Object -Unique)" -ForegroundColor White

Write-Host "`nTests terminÃ©s." -ForegroundColor Cyan
