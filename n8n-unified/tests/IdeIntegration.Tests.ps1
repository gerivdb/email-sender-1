Describe "Intégration IDE avec n8n" {
    BeforeAll {
        # Chemin vers le module
        $rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified"
        $modulePath = Join-Path -Path $rootPath -ChildPath "integrations\ide\IdeN8nIntegration.ps1"
        
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
            }
            elseif ($Uri -match "/api/v1/workflows$" -and $Method -eq "Get") {
                return @(
                    @{
                        id = "1"
                        name = "Test Workflow 1"
                        active = $true
                        createdAt = "2025-04-21T00:00:00.000Z"
                        updatedAt = "2025-04-21T00:00:00.000Z"
                    },
                    @{
                        id = "2"
                        name = "Test Workflow 2"
                        active = $false
                        createdAt = "2025-04-21T00:00:00.000Z"
                        updatedAt = "2025-04-21T00:00:00.000Z"
                    }
                )
            }
            elseif ($Uri -match "/api/v1/workflows$" -and $Method -eq "Post") {
                return @{
                    id = "3"
                    name = $Body | ConvertFrom-Json | Select-Object -ExpandProperty name
                    active = $false
                    createdAt = "2025-04-21T00:00:00.000Z"
                    updatedAt = "2025-04-21T00:00:00.000Z"
                }
            }
            elseif ($Uri -match "/api/v1/workflows/(\d+)$" -and $Method -eq "Get") {
                $workflowId = $Matches[1]
                return @{
                    id = $workflowId
                    name = "Test Workflow $workflowId"
                    active = $true
                    createdAt = "2025-04-21T00:00:00.000Z"
                    updatedAt = "2025-04-21T00:00:00.000Z"
                }
            }
            elseif ($Uri -match "/api/v1/workflows/(\d+)$" -and $Method -eq "Put") {
                $workflowId = $Matches[1]
                $updatedWorkflow = $Body | ConvertFrom-Json
                return @{
                    id = $workflowId
                    name = $updatedWorkflow.name
                    active = $updatedWorkflow.active
                    createdAt = "2025-04-21T00:00:00.000Z"
                    updatedAt = "2025-04-21T00:00:00.000Z"
                }
            }
            elseif ($Uri -match "/api/v1/workflows/(\d+)$" -and $Method -eq "Delete") {
                $workflowId = $Matches[1]
                return @{
                    success = $true
                }
            }
            elseif ($Uri -match "/api/v1/workflows/(\d+)/execute$") {
                $workflowId = $Matches[1]
                return @{
                    id = "exec_$workflowId"
                    finished = $true
                    status = "success"
                }
            }
        }
        
        # Mock pour Get-Content
        Mock Get-Content {
            if ($Path -match "ide-n8n-config.json") {
                return '{"N8nUrl":"http://localhost:5678","ApiKey":"","LastSync":"2025-04-21 00:00:00","Workflows":[{"id":"1","name":"Test Workflow 1","active":true,"createdAt":"2025-04-21T00:00:00.000Z","updatedAt":"2025-04-21T00:00:00.000Z"},{"id":"2","name":"Test Workflow 2","active":false,"createdAt":"2025-04-21T00:00:00.000Z","updatedAt":"2025-04-21T00:00:00.000Z"}],"Templates":[],"VsCodeExtension":{"Installed":false,"Version":""}}'
            }
            elseif ($Path -match "simple-workflow.json") {
                return '{"name":"Simple Workflow Template","nodes":[{"parameters":{"rule":{"interval":[{"field":"hours","minutesInterval":1,"hoursInterval":1}]}},"name":"Schedule Trigger","type":"n8n-nodes-base.scheduleTrigger","typeVersion":1,"position":[250,300]},{"parameters":{"keepOnlySet":true,"values":{"string":[{"name":"message","value":"{{message}}"}]}},"name":"Set Message","type":"n8n-nodes-base.set","typeVersion":1,"position":[450,300]}],"connections":{"Schedule_Trigger":[{"node":"Set Message","type":"main","index":0}]}}'
            }
            else {
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
        
        # Mock pour code
        Mock code {
            return $null
        }
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
        
        It "New-N8nWorkflow devrait créer un workflow" {
            $workflow = New-N8nWorkflow -Name "New Test Workflow"
            $workflow.id | Should -Be "3"
            $workflow.name | Should -Be "New Test Workflow"
        }
        
        It "Update-N8nWorkflow devrait mettre à jour un workflow" {
            $workflow = Update-N8nWorkflow -WorkflowId "1" -Name "Updated Test Workflow" -Active $false
            $workflow.id | Should -Be "1"
            $workflow.name | Should -Be "Updated Test Workflow"
            $workflow.active | Should -Be $false
        }
        
        It "Remove-N8nWorkflow devrait supprimer un workflow" {
            $result = Remove-N8nWorkflow -WorkflowId "1"
            $result.success | Should -Be $true
        }
    }
    
    Context "Fonctions d'intégration" {
        It "Sync-N8nWorkflowsWithIde devrait synchroniser les workflows" {
            # Mock pour Get-IdeN8nConfig pour retourner un objet avec une propriété Workflows
            Mock Get-IdeN8nConfig {
                return [PSCustomObject]@{
                    N8nUrl = "http://localhost:5678"
                    ApiKey = ""
                    LastSync = $null
                    Workflows = @()
                    Templates = @()
                    VsCodeExtension = @{
                        Installed = $false
                        Version = ""
                    }
                }
            }
            
            # Mock pour Save-IdeN8nConfig pour capturer l'objet Config
            $script:savedConfig = $null
            Mock Save-IdeN8nConfig {
                param($Config)
                $script:savedConfig = $Config
            }
            
            $workflows = Sync-N8nWorkflowsWithIde
            $workflows.Count | Should -Be 2
        }
        
        It "New-N8nWorkflowFromTemplate devrait créer un workflow à partir d'un modèle" {
            $workflow = New-N8nWorkflowFromTemplate -TemplateName "simple-workflow" -Name "Template Workflow" -Parameters @{ message = "Hello World" }
            $workflow.id | Should -Be "3"
            $workflow.name | Should -Be "Template Workflow"
        }
        
        It "Test-VsCodeExtension devrait vérifier si l'extension VS Code est installée" {
            Mock code {
                return @("ms-vscode.powershell", "n8n-io.n8n-vscode")
            }
            
            $result = Test-VsCodeExtension
            $result | Should -Be $true
        }
        
        It "Start-IdeN8nIntegration avec Action=Test devrait réussir" {
            $result = Start-IdeN8nIntegration -Action "Test"
            $result.Count | Should -Be 2
            $result[0].id | Should -Be "1"
            $result[0].name | Should -Be "Test Workflow 1"
        }
    }
}
