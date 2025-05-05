# Tests simples pour les fonctions d'analyse des dÃ©clencheurs et des actions
# Ce script teste les fonctions implÃ©mentÃ©es sans utiliser Pester

# Importer le module Ã  tester
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "WorkflowAnalyzer.psm1"
Import-Module $modulePath -Force

# CrÃ©er un workflow n8n de test simple
$testWorkflow = @{
    id = "test-workflow"
    name = "Test Workflow"
    nodes = @(
        @{
            id = "cron-trigger"
            name = "Cron Trigger"
            type = "n8n-nodes-base.cron"
            typeVersion = 1
            position = @(100, 100)
            parameters = @{
                triggerTimes = @{
                    item = @(
                        @{
                            mode = "everyDay"
                            hour = 9
                            minute = 0
                        }
                    )
                }
            }
        },
        @{
            id = "set-node"
            name = "Set Data"
            type = "n8n-nodes-base.set"
            typeVersion = 1
            position = @(300, 100)
            parameters = @{
                values = @{
                    string = @(
                        @{
                            name = "message"
                            value = "Test message"
                        }
                    )
                }
            }
        },
        @{
            id = "function-node"
            name = "Process Data"
            type = "n8n-nodes-base.function"
            typeVersion = 1
            position = @(500, 100)
            parameters = @{
                functionCode = "return [\n  {\n    json: {\n      processed: items[0].json.message + ' processed'\n    }\n  }\n];"
            }
        }
    )
    connections = @{
        "cron-trigger" = @{
            main = @(
                @(
                    @{
                        node = "set-node"
                        type = "main"
                        index = 0
                    }
                )
            )
        }
        "set-node" = @{
            main = @(
                @(
                    @{
                        node = "function-node"
                        type = "main"
                        index = 0
                    }
                )
            )
        }
    }
    active = $true
}

# Fonction pour afficher les rÃ©sultats des tests
function Write-TestResult {
    param (
        [string]$TestName,
        [bool]$Success,
        [string]$Message = ""
    )
    
    if ($Success) {
        Write-Host "[PASS] $TestName" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "       $Message" -ForegroundColor Red
        }
    }
}

# Test 1: Get-N8nWorkflowTriggerConditions
Write-Host "Test 1: Get-N8nWorkflowTriggerConditions" -ForegroundColor Cyan
$triggerConditions = Get-N8nWorkflowTriggerConditions -Workflow $testWorkflow

Write-TestResult -TestName "Should return a result" -Success ($triggerConditions -ne $null)
Write-TestResult -TestName "Should find all triggers" -Success ($triggerConditions.Count -eq 1)
if ($triggerConditions.Count -eq 1) {
    Write-TestResult -TestName "Should identify trigger type correctly" -Success ($triggerConditions[0].TriggerType -eq "Schedule")
    Write-TestResult -TestName "Should extract conditions" -Success ($triggerConditions[0].Conditions.Count -gt 0)
}

# Test 2: Get-N8nWorkflowEventSources
Write-Host "`nTest 2: Get-N8nWorkflowEventSources" -ForegroundColor Cyan
$eventSources = Get-N8nWorkflowEventSources -Workflow $testWorkflow

Write-TestResult -TestName "Should return a result" -Success ($eventSources -ne $null)
Write-TestResult -TestName "Should find all event sources" -Success ($eventSources.Count -eq 1)
if ($eventSources.Count -eq 1) {
    Write-TestResult -TestName "Should identify source type correctly" -Success ($eventSources[0].SourceType -eq "Schedule")
    Write-TestResult -TestName "Should extract details" -Success ($eventSources[0].Details.Count -gt 0)
}

# Test 3: Get-N8nWorkflowTriggerParameters
Write-Host "`nTest 3: Get-N8nWorkflowTriggerParameters" -ForegroundColor Cyan
$triggerParameters = Get-N8nWorkflowTriggerParameters -Workflow $testWorkflow

Write-TestResult -TestName "Should return a result" -Success ($triggerParameters -ne $null)
Write-TestResult -TestName "Should find all triggers" -Success ($triggerParameters.Count -eq 1)
if ($triggerParameters.Count -eq 1) {
    Write-TestResult -TestName "Should extract parameters" -Success ($triggerParameters[0].Parameters.Count -gt 0)
    Write-TestResult -TestName "Should analyze impact" -Success ($triggerParameters[0].Impact -ne $null)
}

# Test 4: Get-N8nWorkflowActions
Write-Host "`nTest 4: Get-N8nWorkflowActions" -ForegroundColor Cyan
$actions = Get-N8nWorkflowActions -Workflow $testWorkflow -IncludeRelationships

Write-TestResult -TestName "Should return a result" -Success ($actions -ne $null)
Write-TestResult -TestName "Should find all actions" -Success ($actions.Count -eq 2)
if ($actions.Count -eq 2) {
    Write-TestResult -TestName "Should identify action types correctly" -Success (
        ($actions | Where-Object { $_.ActionType -eq "DataManipulation" }).Count -eq 1 -and
        ($actions | Where-Object { $_.ActionType -eq "CodeExecution" }).Count -eq 1
    )
    Write-TestResult -TestName "Should extract parameters" -Success (
        ($actions | ForEach-Object { $_.Parameters.Count -gt 0 }) -notcontains $false
    )
    Write-TestResult -TestName "Should include relationships" -Success (
        ($actions | ForEach-Object { $_.InputNodes.Count -gt 0 -or $_.OutputNodes.Count -gt 0 }) -notcontains $false
    )
}

# Test 5: Get-N8nWorkflowActionParameters
Write-Host "`nTest 5: Get-N8nWorkflowActionParameters" -ForegroundColor Cyan
$actionParameters = Get-N8nWorkflowActionParameters -Workflow $testWorkflow

Write-TestResult -TestName "Should return a result" -Success ($actionParameters -ne $null)
Write-TestResult -TestName "Should find all actions" -Success ($actionParameters.Count -eq 2)
if ($actionParameters.Count -eq 2) {
    Write-TestResult -TestName "Should extract parameters" -Success (
        ($actionParameters | ForEach-Object { $_.Parameters.Count -gt 0 }) -notcontains $false
    )
    Write-TestResult -TestName "Should analyze impact" -Success (
        ($actionParameters | ForEach-Object { $_.Impact -ne $null }) -notcontains $false
    )
}

# Test 6: Get-N8nWorkflowActionResults
Write-Host "`nTest 6: Get-N8nWorkflowActionResults" -ForegroundColor Cyan
$actionResults = Get-N8nWorkflowActionResults -Workflow $testWorkflow

Write-TestResult -TestName "Should return a result" -Success ($actionResults -ne $null)
Write-TestResult -TestName "Should find all actions" -Success ($actionResults.Count -eq 2)
if ($actionResults.Count -eq 2) {
    Write-TestResult -TestName "Should determine output types" -Success (
        ($actionResults | ForEach-Object { $_.OutputType -ne $null }) -notcontains $false
    )
    Write-TestResult -TestName "Should identify consumers" -Success (
        ($actionResults | Where-Object { $_.Consumers.Count -gt 0 }).Count -eq 1
    )
    Write-TestResult -TestName "Should analyze data flow" -Success (
        ($actionResults | Where-Object { $_.DataFlow.Count -gt 0 }).Count -eq 1
    )
}

Write-Host "`nAll tests completed." -ForegroundColor Cyan
