#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les fonctions d'analyse des dÃ©clencheurs et des actions du module WorkflowAnalyzer.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions d'analyse des dÃ©clencheurs et des actions
    dans les workflows n8n, notamment Get-N8nWorkflowTriggerConditions, Get-N8nWorkflowEventSources,
    Get-N8nWorkflowTriggerParameters, Get-N8nWorkflowActions, Get-N8nWorkflowActionParameters et
    Get-N8nWorkflowActionResults.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin du module Ã  tester
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "WorkflowAnalyzer.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path $modulePath)) {
    throw "Module WorkflowAnalyzer introuvable Ã  $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# CrÃ©er un dossier temporaire pour les fichiers de test
$testDataPath = Join-Path -Path $PSScriptRoot -ChildPath "TestData"
if (-not (Test-Path -Path $testDataPath)) {
    New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
}

# CrÃ©er un workflow n8n de test avec diffÃ©rents types de dÃ©clencheurs et d'actions
$testWorkflowPath = Join-Path -Path $testDataPath -ChildPath "test_workflow_triggers_actions.json"
$testWorkflowJson = @"
{
  "id": "test-workflow-triggers-actions",
  "name": "Test Workflow Triggers and Actions",
  "nodes": [
    {
      "id": "cron-trigger",
      "name": "Cron Trigger",
      "type": "n8n-nodes-base.cron",
      "typeVersion": 1,
      "position": [100, 100],
      "parameters": {
        "triggerTimes": {
          "item": [
            {
              "mode": "everyDay",
              "hour": 9,
              "minute": 0
            }
          ]
        }
      }
    },
    {
      "id": "webhook-trigger",
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [100, 300],
      "parameters": {
        "path": "test-webhook",
        "httpMethod": "POST",
        "responseMode": "lastNode",
        "authentication": "basicAuth"
      }
    },
    {
      "id": "manual-trigger",
      "name": "Manual Trigger",
      "type": "n8n-nodes-base.manualTrigger",
      "typeVersion": 1,
      "position": [100, 500],
      "parameters": {}
    },
    {
      "id": "set-node",
      "name": "Set Data",
      "type": "n8n-nodes-base.set",
      "typeVersion": 1,
      "position": [300, 300],
      "parameters": {
        "values": {
          "string": [
            {
              "name": "message",
              "value": "Test message"
            }
          ]
        }
      }
    },
    {
      "id": "function-node",
      "name": "Process Data",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [500, 300],
      "parameters": {
        "functionCode": "return [\n  {\n    json: {\n      processed: items[0].json.message + ' processed'\n    }\n  }\n];"
      }
    },
    {
      "id": "if-node",
      "name": "Check Condition",
      "type": "n8n-nodes-base.if",
      "typeVersion": 1,
      "position": [700, 300],
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{$json.processed}}",
              "operation": "contains",
              "value2": "processed"
            }
          ]
        }
      }
    },
    {
      "id": "http-node",
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 1,
      "position": [900, 200],
      "parameters": {
        "url": "https://example.com",
        "method": "GET"
      }
    },
    {
      "id": "error-node",
      "name": "Error Handler",
      "type": "n8n-nodes-base.stopAndError",
      "typeVersion": 1,
      "position": [900, 400],
      "parameters": {
        "errorMessage": "Process failed",
        "errorDescription": "The condition was not met"
      }
    }
  ],
  "connections": {
    "cron-trigger": {
      "main": [
        [
          {
            "node": "set-node",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "webhook-trigger": {
      "main": [
        [
          {
            "node": "set-node",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "manual-trigger": {
      "main": [
        [
          {
            "node": "set-node",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "set-node": {
      "main": [
        [
          {
            "node": "function-node",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "function-node": {
      "main": [
        [
          {
            "node": "if-node",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "if-node": {
      "main": [
        [
          {
            "node": "http-node",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "error-node",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": true,
  "settings": {}
}
"@
Set-Content -Path $testWorkflowPath -Value $testWorkflowJson -Encoding UTF8

# Charger le workflow de test
$testWorkflow = Get-Content -Path $testWorkflowPath -Raw | ConvertFrom-Json

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = 'Detailed'

# Tests pour les fonctions d'analyse des dÃ©clencheurs
Describe "Tests des fonctions d'analyse des dÃ©clencheurs" {
    Context "Get-N8nWorkflowTriggerConditions" {
        BeforeAll {
            # ExÃ©cuter la fonction Ã  tester
            $triggerConditions = Get-N8nWorkflowTriggerConditions -Workflow $testWorkflow -IncludeDetails
        }

        It "Devrait retourner un rÃ©sultat non nul" {
            $triggerConditions | Should -Not -BeNullOrEmpty
        }

        It "Devrait trouver tous les dÃ©clencheurs dans le workflow" {
            $triggerConditions.Count | Should -Be 3
        }

        It "Devrait identifier correctement les types de dÃ©clencheurs" {
            $triggerTypes = $triggerConditions | ForEach-Object { $_.TriggerType }
            $triggerTypes | Should -Contain "Schedule"
            $triggerTypes | Should -Contain "Webhook"
            $triggerTypes | Should -Contain "Manual"
        }

        It "Devrait extraire les conditions pour chaque dÃ©clencheur" {
            foreach ($trigger in $triggerConditions) {
                $trigger.Conditions | Should -Not -BeNullOrEmpty
            }
        }

        It "Devrait inclure les dÃ©tails si demandÃ©" {
            foreach ($trigger in $triggerConditions) {
                $trigger.Parameters | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Get-N8nWorkflowEventSources" {
        BeforeAll {
            # ExÃ©cuter la fonction Ã  tester
            $eventSources = Get-N8nWorkflowEventSources -Workflow $testWorkflow -IncludeDetails
        }

        It "Devrait retourner un rÃ©sultat non nul" {
            $eventSources | Should -Not -BeNullOrEmpty
        }

        It "Devrait trouver toutes les sources d'Ã©vÃ©nements dans le workflow" {
            $eventSources.Count | Should -Be 3
        }

        It "Devrait identifier correctement les types de sources d'Ã©vÃ©nements" {
            $sourceTypes = $eventSources | ForEach-Object { $_.SourceType }
            $sourceTypes | Should -Contain "Schedule"
            $sourceTypes | Should -Contain "HTTP"
            $sourceTypes | Should -Contain "Manual"
        }

        It "Devrait extraire les dÃ©tails pour chaque source d'Ã©vÃ©nements" {
            foreach ($source in $eventSources) {
                $source.Details | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Get-N8nWorkflowTriggerParameters" {
        BeforeAll {
            # ExÃ©cuter la fonction Ã  tester
            $triggerParameters = Get-N8nWorkflowTriggerParameters -Workflow $testWorkflow -IncludeDetails
        }

        It "Devrait retourner un rÃ©sultat non nul" {
            $triggerParameters | Should -Not -BeNullOrEmpty
        }

        It "Devrait trouver tous les dÃ©clencheurs dans le workflow" {
            $triggerParameters.Count | Should -Be 3
        }

        It "Devrait extraire les paramÃ¨tres pour chaque dÃ©clencheur" {
            foreach ($trigger in $triggerParameters) {
                $trigger.Parameters | Should -Not -BeNullOrEmpty
            }
        }

        It "Devrait analyser l'impact des paramÃ¨tres de dÃ©clenchement" {
            foreach ($trigger in $triggerParameters) {
                $trigger.Impact | Should -Not -BeNullOrEmpty
                $trigger.Impact.Frequency | Should -Not -BeNullOrEmpty
                $trigger.Impact.DataVolume | Should -Not -BeNullOrEmpty
                $trigger.Impact.Reliability | Should -Not -BeNullOrEmpty
                $trigger.Impact.Security | Should -Not -BeNullOrEmpty
                $trigger.Impact.Dependencies | Should -Not -BeNullOrEmpty
            }
        }
    }
}

# Tests pour les fonctions d'analyse des actions
Describe "Tests des fonctions d'analyse des actions" {
    Context "Get-N8nWorkflowActions" {
        BeforeAll {
            # ExÃ©cuter la fonction Ã  tester
            $actions = Get-N8nWorkflowActions -Workflow $testWorkflow -IncludeDetails -IncludeRelationships
        }

        It "Devrait retourner un rÃ©sultat non nul" {
            $actions | Should -Not -BeNullOrEmpty
        }

        It "Devrait trouver toutes les actions dans le workflow" {
            $actions.Count | Should -Be 5
        }

        It "Devrait identifier correctement les types d'actions" {
            $actionTypes = $actions | ForEach-Object { $_.ActionType }
            $actionTypes | Should -Contain "DataManipulation"
            $actionTypes | Should -Contain "FlowControl"
            $actionTypes | Should -Contain "CodeExecution"
            $actionTypes | Should -Contain "HTTP"
            $actionTypes | Should -Contain "ErrorHandling"
        }

        It "Devrait extraire les paramÃ¨tres pour chaque action" {
            foreach ($action in $actions) {
                $action.Parameters | Should -Not -BeNullOrEmpty
            }
        }

        It "Devrait inclure les relations si demandÃ©" {
            foreach ($action in $actions) {
                $action.InputNodes -or $action.OutputNodes | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Get-N8nWorkflowActionParameters" {
        BeforeAll {
            # ExÃ©cuter la fonction Ã  tester
            $actionParameters = Get-N8nWorkflowActionParameters -Workflow $testWorkflow -IncludeDetails
        }

        It "Devrait retourner un rÃ©sultat non nul" {
            $actionParameters | Should -Not -BeNullOrEmpty
        }

        It "Devrait trouver toutes les actions dans le workflow" {
            $actionParameters.Count | Should -Be 5
        }

        It "Devrait extraire les paramÃ¨tres pour chaque action" {
            foreach ($action in $actionParameters) {
                $action.Parameters | Should -Not -BeNullOrEmpty
            }
        }

        It "Devrait analyser l'impact des paramÃ¨tres d'action" {
            foreach ($action in $actionParameters) {
                $action.Impact | Should -Not -BeNullOrEmpty
                $action.Impact.Performance | Should -Not -BeNullOrEmpty
                $action.Impact.DataSize | Should -Not -BeNullOrEmpty
                $action.Impact.Reliability | Should -Not -BeNullOrEmpty
                $action.Impact.Security | Should -Not -BeNullOrEmpty
                $action.Impact.Dependencies | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Get-N8nWorkflowActionResults" {
        BeforeAll {
            # ExÃ©cuter la fonction Ã  tester
            $actionResults = Get-N8nWorkflowActionResults -Workflow $testWorkflow -IncludeDetails
        }

        It "Devrait retourner un rÃ©sultat non nul" {
            $actionResults | Should -Not -BeNullOrEmpty
        }

        It "Devrait trouver toutes les actions dans le workflow" {
            $actionResults.Count | Should -Be 5
        }

        It "Devrait dÃ©terminer le type de sortie pour chaque action" {
            foreach ($action in $actionResults) {
                $action.OutputType | Should -Not -BeNullOrEmpty
            }
        }

        It "Devrait identifier les consommateurs pour chaque action" {
            # Certaines actions peuvent ne pas avoir de consommateurs (nÅ“uds terminaux)
            $actionsWithConsumers = $actionResults | Where-Object { $_.Consumers.Count -gt 0 }
            $actionsWithConsumers.Count | Should -BeGreaterThan 0
        }

        It "Devrait analyser le flux de donnÃ©es entre les actions" {
            # Certaines actions peuvent ne pas avoir de flux de donnÃ©es (nÅ“uds terminaux)
            $actionsWithDataFlow = $actionResults | Where-Object { $_.DataFlow.Count -gt 0 }
            $actionsWithDataFlow.Count | Should -BeGreaterThan 0
        }
    }
}

# Tests pour les fonctions auxiliaires
Describe "Tests des fonctions auxiliaires" {
    Context "Get-TriggerType" {
        It "Devrait identifier correctement les dÃ©clencheurs de planification" {
            $triggerType = Get-TriggerType -NodeType "n8n-nodes-base.cron"
            $triggerType | Should -Be "Schedule"
        }

        It "Devrait identifier correctement les dÃ©clencheurs webhook" {
            $triggerType = Get-TriggerType -NodeType "n8n-nodes-base.webhook"
            $triggerType | Should -Be "Webhook"
        }

        It "Devrait identifier correctement les dÃ©clencheurs manuels" {
            $triggerType = Get-TriggerType -NodeType "n8n-nodes-base.manualTrigger"
            $triggerType | Should -Be "Manual"
        }

        It "Devrait retourner 'Other' pour les types inconnus" {
            $triggerType = Get-TriggerType -NodeType "unknown-type"
            $triggerType | Should -Be "Other"
        }
    }

    Context "Get-ActionType" {
        It "Devrait identifier correctement les actions HTTP" {
            $actionType = Get-ActionType -NodeType "n8n-nodes-base.httpRequest"
            $actionType | Should -Be "HTTP"
        }

        It "Devrait identifier correctement les actions de manipulation de donnÃ©es" {
            $actionType = Get-ActionType -NodeType "n8n-nodes-base.set"
            $actionType | Should -Be "DataManipulation"
        }

        It "Devrait identifier correctement les actions d'exÃ©cution de code" {
            $actionType = Get-ActionType -NodeType "n8n-nodes-base.function"
            $actionType | Should -Be "CodeExecution"
        }

        It "Devrait identifier correctement les actions de contrÃ´le de flux" {
            $actionType = Get-ActionType -NodeType "n8n-nodes-base.if"
            $actionType | Should -Be "FlowControl"
        }

        It "Devrait retourner 'Other' pour les types inconnus" {
            $actionType = Get-ActionType -NodeType "unknown-type"
            $actionType | Should -Be "Other"
        }
    }

    Context "Get-EventSourceType" {
        It "Devrait identifier correctement les sources d'Ã©vÃ©nements de planification" {
            $sourceType = Get-EventSourceType -NodeType "n8n-nodes-base.cron"
            $sourceType | Should -Be "Schedule"
        }

        It "Devrait identifier correctement les sources d'Ã©vÃ©nements HTTP" {
            $sourceType = Get-EventSourceType -NodeType "n8n-nodes-base.webhook"
            $sourceType | Should -Be "HTTP"
        }

        It "Devrait identifier correctement les sources d'Ã©vÃ©nements manuelles" {
            $sourceType = Get-EventSourceType -NodeType "n8n-nodes-base.manualTrigger"
            $sourceType | Should -Be "Manual"
        }

        It "Devrait retourner 'Other' pour les types inconnus" {
            $sourceType = Get-EventSourceType -NodeType "unknown-type"
            $sourceType | Should -Be "Other"
        }
    }

    Context "Get-ActionOutputType" {
        It "Devrait identifier correctement les types de sortie HTTP" {
            $outputType = Get-ActionOutputType -Node @{type = "n8n-nodes-base.httpRequest"} -ActionType "HTTP"
            $outputType | Should -Be "JSON/Text"
        }

        It "Devrait identifier correctement les types de sortie de manipulation de donnÃ©es" {
            $outputType = Get-ActionOutputType -Node @{type = "n8n-nodes-base.set"} -ActionType "DataManipulation"
            $outputType | Should -Be "JSON"
        }

        It "Devrait identifier correctement les types de sortie d'exÃ©cution de code" {
            $outputType = Get-ActionOutputType -Node @{type = "n8n-nodes-base.function"} -ActionType "CodeExecution"
            $outputType | Should -Be "JSON"
        }

        It "Devrait identifier correctement les types de sortie de contrÃ´le de flux" {
            $outputType = Get-ActionOutputType -Node @{type = "n8n-nodes-base.if"} -ActionType "FlowControl"
            $outputType | Should -Be "Boolean"
        }

        It "Devrait retourner 'Unknown' pour les types inconnus" {
            $outputType = Get-ActionOutputType -Node @{type = "unknown-type"} -ActionType "Other"
            $outputType | Should -Be "Unknown"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Configuration $pesterConfig

# Nettoyer les fichiers de test aprÃ¨s l'exÃ©cution des tests
AfterAll {
    # Supprimer les fichiers de test
    if (Test-Path -Path $testDataPath) {
        Remove-Item -Path $testDataPath -Recurse -Force
    }
}
