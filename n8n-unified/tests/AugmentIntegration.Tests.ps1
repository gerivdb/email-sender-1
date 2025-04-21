Describe "Intégration Augment avec n8n" {
    BeforeAll {
        # Chemin vers le module
        $rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified"
        $modulePath = Join-Path -Path $rootPath -ChildPath "integrations\augment\AugmentN8nIntegration.ps1"

        # Importer le module
        if (Test-Path -Path $modulePath) {
            Import-Module $modulePath -Force
        }

        # Mock pour Invoke-RestMethod
        Mock Invoke-RestMethod {
            if ($Uri -match "/healthz") {
                return @{
                    status = "ok"
                }
            } elseif ($Uri -match "/api/v1/workflows$") {
                return @(
                    @{
                        id        = "1"
                        name      = "Test Workflow 1"
                        active    = $true
                        createdAt = "2025-04-21T00:00:00.000Z"
                        updatedAt = "2025-04-21T00:00:00.000Z"
                    },
                    @{
                        id        = "2"
                        name      = "Test Workflow 2"
                        active    = $false
                        createdAt = "2025-04-21T00:00:00.000Z"
                        updatedAt = "2025-04-21T00:00:00.000Z"
                    }
                )
            } elseif ($Uri -match "/api/v1/workflows/(\d+)$") {
                $workflowId = $Matches[1]
                return @{
                    id        = $workflowId
                    name      = "Test Workflow $workflowId"
                    active    = $true
                    createdAt = "2025-04-21T00:00:00.000Z"
                    updatedAt = "2025-04-21T00:00:00.000Z"
                }
            } elseif ($Uri -match "/api/v1/workflows/(\d+)/execute$") {
                $workflowId = $Matches[1]
                return @{
                    id       = "exec_$workflowId"
                    finished = $true
                    status   = "success"
                }
            } elseif ($Uri -match "/api/v1/executions$") {
                return @(
                    @{
                        id         = "exec_1"
                        workflowId = "1"
                        status     = "success"
                        startedAt  = "2025-04-21T00:00:00.000Z"
                        finishedAt = "2025-04-21T00:00:01.000Z"
                    }
                )
            } elseif ($Uri -match "/api/v1/executions/(.+)$") {
                $executionId = $Matches[1]
                return @{
                    id         = $executionId
                    workflowId = "1"
                    status     = "success"
                    startedAt  = "2025-04-21T00:00:00.000Z"
                    finishedAt = "2025-04-21T00:00:01.000Z"
                }
            }
        }

        # Mock pour Get-Content
        Mock Get-Content {
            if ($Path -match "augment-n8n-config.json") {
                return '{"N8nUrl":"http://localhost:5678","ApiKey":"","LastSync":"2025-04-21 00:00:00","Workflows":[{"id":"1","name":"Test Workflow 1","active":true,"createdAt":"2025-04-21T00:00:00.000Z","updatedAt":"2025-04-21T00:00:00.000Z"},{"id":"2","name":"Test Workflow 2","active":false,"createdAt":"2025-04-21T00:00:00.000Z","updatedAt":"2025-04-21T00:00:00.000Z"}]}'
            } elseif ($Path -match "augment_memories.json") {
                return '[{"id":"mem_001","type":"augment_memory","description":"Workflow pour envoyer un email quotidien","content":"Créer un workflow n8n pour envoyer un email quotidien à 8h00 avec un résumé des tâches du jour.","createdAt":"2025-04-21T01:00:00.000Z"}]'
            } else {
                return $null
            }
        }

        # Mock pour Set-Content
        Mock Set-Content {}

        # Mock pour Add-Content
        Mock Add-Content {}

        # Mock pour Test-Path
        Mock Test-Path {
            return $true
        }

        # Mock pour New-Item
        Mock New-Item {}
    }

    Context "Fonctions de base" {
        It "Test-N8nConnection devrait réussir" {
            $result = Test-N8nConnection
            $result | Should -Be $true
        }

        It "Get-N8nWorkflows devrait retourner des workflows" {
            $workflows = Get-N8nWorkflows
            $workflows.Count | Should -Be 2
            $workflows[0].id | Should -Be "1"
            $workflows[0].name | Should -Be "Test Workflow 1"
        }

        It "Get-N8nWorkflow devrait retourner un workflow spécifique" {
            $workflow = Get-N8nWorkflow -WorkflowId "1"
            $workflow.id | Should -Be "1"
            $workflow.name | Should -Be "Test Workflow 1"
        }

        It "Invoke-N8nWorkflow devrait exécuter un workflow" {
            $execution = Invoke-N8nWorkflow -WorkflowId "1"
            $execution.id | Should -Be "exec_1"
            $execution.status | Should -Be "success"
        }
    }

    Context "Fonctions d'intégration" {
        It "Sync-N8nWorkflowsWithAugment devrait synchroniser les workflows" {
            # Mock pour Get-N8nConfig pour retourner un objet avec une propriété Workflows
            Mock Get-N8nConfig {
                return [PSCustomObject]@{
                    N8nUrl    = "http://localhost:5678"
                    ApiKey    = ""
                    LastSync  = $null
                    Workflows = @()
                }
            }

            # Mock pour Save-N8nConfig pour capturer l'objet Config
            $script:savedConfig = $null
            Mock Save-N8nConfig {
                param($Config)
                $script:savedConfig = $Config
            }

            $workflows = Sync-N8nWorkflowsWithAugment
            $workflows.Count | Should -Be 2
        }

        It "Export-N8nDataToAugmentMemories devrait exporter les données" {
            $memories = Export-N8nDataToAugmentMemories
            $memories.Count | Should -Be 2
            $memories[0].id | Should -Be "1"
            $memories[0].type | Should -Be "n8n_workflow"
        }

        It "Import-AugmentMemoriesToN8n devrait importer les données" {
            $result = Import-AugmentMemoriesToN8n
            $result | Should -Be $true
        }

        It "Start-AugmentN8nIntegration avec Action=Test devrait réussir" {
            $result = Start-AugmentN8nIntegration -Action "Test"
            $result.Count | Should -Be 2
            $result[0].id | Should -Be "1"
            $result[0].name | Should -Be "Test Workflow 1"
        }
    }
}
