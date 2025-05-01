# Tests unitaires pour le module WorkflowAnalyzer
# Ce script contient des tests unitaires pour vérifier le bon fonctionnement du module WorkflowAnalyzer

#Requires -Version 5.1
#Requires -Modules Pester

# Importer le module à tester
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "WorkflowAnalyzer.psm1"
Import-Module $modulePath -Force

# Créer un dossier temporaire pour les fichiers de test
$testDataPath = Join-Path -Path $PSScriptRoot -ChildPath "TestData"
if (-not (Test-Path -Path $testDataPath)) {
  New-Item -Path $testDataPath -ItemType Directory -Force | Out-Null
}

# Créer un dossier pour les résultats des tests
$testResultsPath = Join-Path -Path $PSScriptRoot -ChildPath "TestResults"
if (-not (Test-Path -Path $testResultsPath)) {
  New-Item -Path $testResultsPath -ItemType Directory -Force | Out-Null
}

# Créer un workflow n8n de test simple
$simpleWorkflowPath = Join-Path -Path $testDataPath -ChildPath "simple_workflow.json"
$simpleWorkflowJson = @"
{
  "id": "test-workflow-1",
  "name": "Test Workflow Simple",
  "nodes": [
    {
      "id": "node1",
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [100, 300]
    },
    {
      "id": "node2",
      "name": "Set Data",
      "type": "n8n-nodes-base.set",
      "typeVersion": 1,
      "position": [300, 300],
      "parameters": {
        "values": {
          "string": [
            {
              "name": "testValue",
              "value": "test"
            }
          ]
        }
      }
    },
    {
      "id": "node3",
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 1,
      "position": [500, 300],
      "parameters": {
        "url": "https://example.com",
        "method": "GET"
      }
    }
  ],
  "connections": {
    "node1": {
      "main": [
        [
          {
            "node": "node2",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node2": {
      "main": [
        [
          {
            "node": "node3",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {}
}
"@
Set-Content -Path $simpleWorkflowPath -Value $simpleWorkflowJson -Encoding UTF8

# Créer un workflow n8n de test avec des conditions
$conditionalWorkflowPath = Join-Path -Path $testDataPath -ChildPath "conditional_workflow.json"
$conditionalWorkflowJson = @"
{
  "id": "test-workflow-2",
  "name": "Test Workflow Conditional",
  "nodes": [
    {
      "id": "node1",
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [100, 300]
    },
    {
      "id": "node2",
      "name": "Set Data",
      "type": "n8n-nodes-base.set",
      "typeVersion": 1,
      "position": [300, 300],
      "parameters": {
        "values": {
          "string": [
            {
              "name": "testValue",
              "value": "test"
            }
          ]
        }
      }
    },
    {
      "id": "node3",
      "name": "Condition",
      "type": "n8n-nodes-base.if",
      "typeVersion": 1,
      "position": [500, 300],
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{$json.testValue}}",
              "operation": "equal",
              "value2": "test"
            }
          ]
        }
      }
    },
    {
      "id": "node4",
      "name": "True Path",
      "type": "n8n-nodes-base.set",
      "typeVersion": 1,
      "position": [700, 200],
      "parameters": {
        "values": {
          "string": [
            {
              "name": "result",
              "value": "true"
            }
          ]
        }
      }
    },
    {
      "id": "node5",
      "name": "False Path",
      "type": "n8n-nodes-base.set",
      "typeVersion": 1,
      "position": [700, 400],
      "parameters": {
        "values": {
          "string": [
            {
              "name": "result",
              "value": "false"
            }
          ]
        }
      }
    },
    {
      "id": "node6",
      "name": "Switch",
      "type": "n8n-nodes-base.switch",
      "typeVersion": 1,
      "position": [900, 300],
      "parameters": {
        "value": "={{$json.result}}",
        "rules": [
          {
            "operation": "equal",
            "value": "true",
            "output": 0
          },
          {
            "operation": "equal",
            "value": "false",
            "output": 1
          }
        ]
      }
    },
    {
      "id": "node7",
      "name": "Output True",
      "type": "n8n-nodes-base.noOp",
      "typeVersion": 1,
      "position": [1100, 200]
    },
    {
      "id": "node8",
      "name": "Output False",
      "type": "n8n-nodes-base.noOp",
      "typeVersion": 1,
      "position": [1100, 400]
    }
  ],
  "connections": {
    "node1": {
      "main": [
        [
          {
            "node": "node2",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node2": {
      "main": [
        [
          {
            "node": "node3",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node3": {
      "main": [
        [
          {
            "node": "node4",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "node5",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node4": {
      "main": [
        [
          {
            "node": "node6",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node5": {
      "main": [
        [
          {
            "node": "node6",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node6": {
      "main": [
        [
          {
            "node": "node7",
            "type": "main",
            "index": 0
          }
        ],
        [
          {
            "node": "node8",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {}
}
"@
Set-Content -Path $conditionalWorkflowPath -Value $conditionalWorkflowJson -Encoding UTF8

# Créer un workflow n8n de test complexe avec différents types de nœuds
$complexWorkflowPath = Join-Path -Path $testDataPath -ChildPath "complex_workflow.json"
$complexWorkflowJson = @"
{
  "id": "test-workflow-3",
  "name": "Test Workflow Complex",
  "nodes": [
    {
      "id": "node1",
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [100, 300]
    },
    {
      "id": "node2",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [300, 300],
      "parameters": {
        "path": "test-webhook",
        "responseMode": "lastNode"
      }
    },
    {
      "id": "node3",
      "name": "Set Data",
      "type": "n8n-nodes-base.set",
      "typeVersion": 1,
      "position": [500, 300],
      "parameters": {
        "values": {
          "string": [
            {
              "name": "testValue",
              "value": "test"
            }
          ]
        }
      }
    },
    {
      "id": "node4",
      "name": "Function",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [700, 300],
      "parameters": {
        "functionCode": "return [\n  {\n    json: {\n      result: items[0].json.testValue + '_processed'\n    }\n  }\n];"
      }
    },
    {
      "id": "node5",
      "name": "Split In Batches",
      "type": "n8n-nodes-base.splitInBatches",
      "typeVersion": 1,
      "position": [900, 300],
      "parameters": {
        "batchSize": 1
      }
    },
    {
      "id": "node6",
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 1,
      "position": [1100, 300],
      "parameters": {
        "url": "https://example.com",
        "method": "GET"
      }
    },
    {
      "id": "node7",
      "name": "Merge",
      "type": "n8n-nodes-base.merge",
      "typeVersion": 1,
      "position": [1300, 300],
      "parameters": {
        "mode": "append"
      }
    },
    {
      "id": "node8",
      "name": "Wait",
      "type": "n8n-nodes-base.wait",
      "typeVersion": 1,
      "position": [1500, 300],
      "parameters": {
        "amount": 1,
        "unit": "seconds"
      }
    },
    {
      "id": "node9",
      "name": "Sticky Note",
      "type": "n8n-nodes-base.stickyNote",
      "typeVersion": 1,
      "position": [1700, 300],
      "parameters": {
        "content": "This is a test workflow"
      }
    }
  ],
  "connections": {
    "node1": {
      "main": [
        [
          {
            "node": "node2",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node2": {
      "main": [
        [
          {
            "node": "node3",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node3": {
      "main": [
        [
          {
            "node": "node4",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node4": {
      "main": [
        [
          {
            "node": "node5",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node5": {
      "main": [
        [
          {
            "node": "node6",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node6": {
      "main": [
        [
          {
            "node": "node7",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "node7": {
      "main": [
        [
          {
            "node": "node8",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {}
}
"@
Set-Content -Path $complexWorkflowPath -Value $complexWorkflowJson -Encoding UTF8

# Définir les tests Pester
Describe "WorkflowAnalyzer Module Tests" {
  Context "Get-N8nWorkflow Function" {
    It "Should load a simple workflow correctly" {
      $workflow = Get-N8nWorkflow -WorkflowPath $simpleWorkflowPath
      $workflow | Should -Not -BeNullOrEmpty
      $workflow.name | Should -Be "Test Workflow Simple"
      $workflow.nodes.Count | Should -Be 3
      $workflow.connections.Count | Should -Be 2
    }

    It "Should load a conditional workflow correctly" {
      $workflow = Get-N8nWorkflow -WorkflowPath $conditionalWorkflowPath
      $workflow | Should -Not -BeNullOrEmpty
      $workflow.name | Should -Be "Test Workflow Conditional"
      $workflow.nodes.Count | Should -Be 8
      $workflow.connections.Count | Should -Be 6
    }

    It "Should load a complex workflow correctly" {
      $workflow = Get-N8nWorkflow -WorkflowPath $complexWorkflowPath
      $workflow | Should -Not -BeNullOrEmpty
      $workflow.name | Should -Be "Test Workflow Complex"
      $workflow.nodes.Count | Should -Be 9
      $workflow.connections.Count | Should -Be 7
    }

    It "Should return null for non-existent workflow" {
      $workflow = Get-N8nWorkflow -WorkflowPath "non-existent-workflow.json"
      $workflow | Should -BeNullOrEmpty
    }
  }

  Context "Get-N8nWorkflowActivities Function" {
    It "Should detect activities in a simple workflow" {
      $workflow = Get-N8nWorkflow -WorkflowPath $simpleWorkflowPath
      $activities = Get-N8nWorkflowActivities -Workflow $workflow
      $activities | Should -Not -BeNullOrEmpty
      $activities.Count | Should -Be 3
      $activities[0].Type | Should -Be "n8n-nodes-base.start"
      $activities[1].Type | Should -Be "n8n-nodes-base.set"
      $activities[2].Type | Should -Be "n8n-nodes-base.httpRequest"
    }

    It "Should detect activities with details in a simple workflow" {
      $workflow = Get-N8nWorkflow -WorkflowPath $simpleWorkflowPath
      $activities = Get-N8nWorkflowActivities -Workflow $workflow -IncludeDetails
      $activities | Should -Not -BeNullOrEmpty
      $activities.Count | Should -Be 3
      $activities[0].Parameters | Should -Not -BeNullOrEmpty
      $activities[1].Parameters.values.string[0].name | Should -Be "testValue"
      $activities[1].Parameters.values.string[0].value | Should -Be "test"
      $activities[2].Parameters.url | Should -Be "https://example.com"
      $activities[2].Parameters.method | Should -Be "GET"
    }

    It "Should categorize activities correctly" {
      $workflow = Get-N8nWorkflow -WorkflowPath $complexWorkflowPath
      $activities = Get-N8nWorkflowActivities -Workflow $workflow
      $activities | Should -Not -BeNullOrEmpty

      $triggerNodes = $activities | Where-Object { $_.Category -eq "Trigger" }
      $triggerNodes.Count | Should -BeGreaterThan 0

      $dataOperationNodes = $activities | Where-Object { $_.Category -eq "Data Operation" }
      $dataOperationNodes.Count | Should -BeGreaterThan 0

      $apiNodes = $activities | Where-Object { $_.Category -eq "API" }
      $apiNodes.Count | Should -BeGreaterThan 0

      $flowControlNodes = $activities | Where-Object { $_.Category -eq "Flow Control" }
      $flowControlNodes.Count | Should -BeGreaterThan 0
    }
  }

  Context "Get-N8nWorkflowTransitions Function" {
    It "Should extract transitions in a simple workflow" {
      $workflow = Get-N8nWorkflow -WorkflowPath $simpleWorkflowPath
      $transitions = Get-N8nWorkflowTransitions -Workflow $workflow
      $transitions | Should -Not -BeNullOrEmpty
      $transitions.Count | Should -Be 2
      $transitions[0].SourceNodeId | Should -Be "node1"
      $transitions[0].TargetNodeId | Should -Be "node2"
      $transitions[1].SourceNodeId | Should -Be "node2"
      $transitions[1].TargetNodeId | Should -Be "node3"
    }

    It "Should extract transitions with node details in a simple workflow" {
      $workflow = Get-N8nWorkflow -WorkflowPath $simpleWorkflowPath
      $transitions = Get-N8nWorkflowTransitions -Workflow $workflow -IncludeNodeDetails
      $transitions | Should -Not -BeNullOrEmpty
      $transitions.Count | Should -Be 2
      $transitions[0].SourceNode | Should -Not -BeNullOrEmpty
      $transitions[0].TargetNode | Should -Not -BeNullOrEmpty
      $transitions[0].SourceNode.type | Should -Be "n8n-nodes-base.start"
      $transitions[0].TargetNode.type | Should -Be "n8n-nodes-base.set"
    }

    It "Should extract transitions in a conditional workflow" {
      $workflow = Get-N8nWorkflow -WorkflowPath $conditionalWorkflowPath
      $transitions = Get-N8nWorkflowTransitions -Workflow $workflow
      $transitions | Should -Not -BeNullOrEmpty
      $transitions.Count | Should -Be 8

      # Vérifier les transitions de l'IF
      $ifTransitions = $transitions | Where-Object { $_.SourceNodeId -eq "node3" }
      $ifTransitions.Count | Should -Be 2
      $ifTransitions[0].TargetNodeId | Should -Be "node4" # True path
      $ifTransitions[1].TargetNodeId | Should -Be "node5" # False path

      # Vérifier les transitions du Switch
      $switchTransitions = $transitions | Where-Object { $_.SourceNodeId -eq "node6" }
      $switchTransitions.Count | Should -Be 2
      $switchTransitions[0].TargetNodeId | Should -Be "node7" # Output 0
      $switchTransitions[1].TargetNodeId | Should -Be "node8" # Output 1
    }
  }

  Context "Get-N8nWorkflowConditions Function" {
    It "Should not find conditions in a simple workflow" {
      $workflow = Get-N8nWorkflow -WorkflowPath $simpleWorkflowPath
      $conditions = Get-N8nWorkflowConditions -Workflow $workflow
      $conditions | Should -Not -BeNullOrEmpty
      $conditions.Count | Should -Be 0
    }

    It "Should find conditions in a conditional workflow" {
      $workflow = Get-N8nWorkflow -WorkflowPath $conditionalWorkflowPath
      $conditions = Get-N8nWorkflowConditions -Workflow $workflow
      $conditions | Should -Not -BeNullOrEmpty
      $conditions.Count | Should -Be 2

      # Vérifier le nœud IF
      $ifCondition = $conditions | Where-Object { $_.Type -eq "n8n-nodes-base.if" }
      $ifCondition | Should -Not -BeNullOrEmpty
      $ifCondition.Conditions.Count | Should -Be 1
      $ifCondition.Conditions[0].Value1 | Should -Be "={{$json.testValue}}"
      $ifCondition.Conditions[0].Operation | Should -Be "equal"
      $ifCondition.Conditions[0].Value2 | Should -Be "test"

      # Vérifier le nœud Switch
      $switchCondition = $conditions | Where-Object { $_.Type -eq "n8n-nodes-base.switch" }
      $switchCondition | Should -Not -BeNullOrEmpty
      $switchCondition.Conditions.Count | Should -Be 2
      $switchCondition.Conditions[0].Value1 | Should -Be "={{$json.result}}"
      $switchCondition.Conditions[0].Operation | Should -Be "equal"
      $switchCondition.Conditions[0].Value2 | Should -Be "true"
      $switchCondition.Conditions[1].Value1 | Should -Be "={{$json.result}}"
      $switchCondition.Conditions[1].Operation | Should -Be "equal"
      $switchCondition.Conditions[1].Value2 | Should -Be "false"
    }

    It "Should find conditions with transitions in a conditional workflow" {
      $workflow = Get-N8nWorkflow -WorkflowPath $conditionalWorkflowPath
      $conditions = Get-N8nWorkflowConditions -Workflow $workflow -IncludeTransitions
      $conditions | Should -Not -BeNullOrEmpty
      $conditions.Count | Should -Be 2

      # Vérifier les transitions du nœud IF
      $ifCondition = $conditions | Where-Object { $_.Type -eq "n8n-nodes-base.if" }
      $ifCondition.Transitions | Should -Not -BeNullOrEmpty
      $ifCondition.Transitions.Count | Should -Be 2
      $ifCondition.Transitions[0].OutputLabel | Should -Be "true"
      $ifCondition.Transitions[0].TargetNodeName | Should -Be "True Path"
      $ifCondition.Transitions[1].OutputLabel | Should -Be "false"
      $ifCondition.Transitions[1].TargetNodeName | Should -Be "False Path"

      # Vérifier les transitions du nœud Switch
      $switchCondition = $conditions | Where-Object { $_.Type -eq "n8n-nodes-base.switch" }
      $switchCondition.Transitions | Should -Not -BeNullOrEmpty
      $switchCondition.Transitions.Count | Should -Be 2
      $switchCondition.Transitions[0].OutputLabel | Should -Be "output0"
      $switchCondition.Transitions[0].TargetNodeName | Should -Be "Output True"
      $switchCondition.Transitions[1].OutputLabel | Should -Be "output1"
      $switchCondition.Transitions[1].TargetNodeName | Should -Be "Output False"
    }
  }

  Context "Get-N8nWorkflowAnalysisReport Function" {
    It "Should generate a Markdown report for a simple workflow" {
      $outputPath = Join-Path -Path $testDataPath -ChildPath "simple_workflow_report.md"
      $report = Get-N8nWorkflowAnalysisReport -WorkflowPath $simpleWorkflowPath -OutputPath $outputPath -Format "Markdown"
      $report | Should -Not -BeNullOrEmpty
      Test-Path -Path $outputPath | Should -Be $true
      $reportContent = Get-Content -Path $outputPath -Raw
      $reportContent | Should -Match "Test Workflow Simple"
      $reportContent | Should -Match "Activités"
      $reportContent | Should -Match "Transitions"
    }

    It "Should generate a JSON report for a conditional workflow" {
      $outputPath = Join-Path -Path $testDataPath -ChildPath "conditional_workflow_report.json"
      $report = Get-N8nWorkflowAnalysisReport -WorkflowPath $conditionalWorkflowPath -OutputPath $outputPath -Format "JSON"
      $report | Should -Not -BeNullOrEmpty
      Test-Path -Path $outputPath | Should -Be $true
      $reportContent = Get-Content -Path $outputPath -Raw
      $reportContent | Should -Match "Test Workflow Conditional"
      $reportJson = $reportContent | ConvertFrom-Json
      $reportJson.WorkflowName | Should -Be "Test Workflow Conditional"
      $reportJson.Conditions.Count | Should -Be 2
    }

    It "Should generate an HTML report for a complex workflow" {
      $outputPath = Join-Path -Path $testDataPath -ChildPath "complex_workflow_report.html"
      $report = Get-N8nWorkflowAnalysisReport -WorkflowPath $complexWorkflowPath -OutputPath $outputPath -Format "HTML"
      $report | Should -Not -BeNullOrEmpty
      Test-Path -Path $outputPath | Should -Be $true
      $reportContent = Get-Content -Path $outputPath -Raw
      $reportContent | Should -Match "Test Workflow Complex"
      $reportContent | Should -Match "<html>"
      $reportContent | Should -Match "</html>"
    }

    It "Should generate a Text report for a simple workflow" {
      $outputPath = Join-Path -Path $testDataPath -ChildPath "simple_workflow_report.txt"
      $report = Get-N8nWorkflowAnalysisReport -WorkflowPath $simpleWorkflowPath -OutputPath $outputPath -Format "Text"
      $report | Should -Not -BeNullOrEmpty
      Test-Path -Path $outputPath | Should -Be $true
      $reportContent = Get-Content -Path $outputPath -Raw
      $reportContent | Should -Match "Test Workflow Simple"
      $reportContent | Should -Match "Activités:"
      $reportContent | Should -Match "Transitions:"
    }
  }
}

# Nettoyer les fichiers de test après l'exécution des tests
AfterAll {
  # Supprimer les fichiers de test
  if (Test-Path -Path $testDataPath) {
    Remove-Item -Path $testDataPath -Recurse -Force
  }
}
