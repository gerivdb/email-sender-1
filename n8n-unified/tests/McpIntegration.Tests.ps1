Describe "Intégration MCP avec n8n" {
    BeforeAll {
        # Chemin vers le module
        $rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\n8n-unified"
        $modulePath = Join-Path -Path $rootPath -ChildPath "integrations\mcp\McpN8nIntegration.ps1"

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
            } elseif ($Uri -match "/api/v1/workflows$" -and $Method -eq "Get") {
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
            } elseif ($Uri -match "/api/v1/credentials$" -and $Method -eq "Get") {
                return @(
                    @{
                        id   = "1"
                        name = "MCP-filesystem"
                        type = "mcpApi"
                        data = @{
                            server = "filesystem"
                            path   = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp\servers\filesystem"
                        }
                    },
                    @{
                        id   = "2"
                        name = "MCP-github"
                        type = "mcpApi"
                        data = @{
                            server = "github"
                            path   = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp\servers\github"
                        }
                    }
                )
            } elseif ($Uri -match "/api/v1/credentials$" -and $Method -eq "Post") {
                return @{
                    id   = "3"
                    name = $Body | ConvertFrom-Json | Select-Object -ExpandProperty name
                    type = "mcpApi"
                    data = @{}
                }
            } elseif ($Uri -match "/api/v1/credentials/(\d+)$" -and $Method -eq "Put") {
                $credentialId = $Matches[1]
                $updatedCredential = $Body | ConvertFrom-Json
                return @{
                    id   = $credentialId
                    name = $updatedCredential.name
                    type = $updatedCredential.type
                    data = $updatedCredential.data
                }
            } elseif ($Uri -match "/api/v1/credentials/(\d+)$" -and $Method -eq "Delete") {
                $credentialId = $Matches[1]
                return @{
                    success = $true
                }
            }
        }

        # Mock pour Get-Content
        Mock Get-Content {
            if ($Path -match "mcp-n8n-config.json") {
                return '{"N8nUrl":"http://localhost:5678","ApiKey":"","McpPath":"D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp","LastSync":"2025-04-21 00:00:00","Servers":[{"Name":"filesystem","Path":"D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\servers\\filesystem"},{"Name":"github","Path":"D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\servers\\github"}],"Credentials":[{"id":"1","name":"MCP-filesystem","type":"mcpApi"},{"id":"2","name":"MCP-github","type":"mcpApi"}]}'
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
            if ($Path -match "mcp-n8n-config.json") {
                return $true
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp") {
                return $true
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\servers") {
                return $true
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\servers\\filesystem") {
                return $true
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\servers\\github") {
                return $true
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\utils\\commands\\start-n8n-mcp.cmd") {
                return $true
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\utils\\commands\\stop-n8n-mcp.cmd") {
                return $true
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\core\\.n8n\\credentials") {
                return $true
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\core\\.n8n") {
                return $true
            } else {
                return $false
            }
        }

        # Mock pour New-Item
        Mock New-Item {}

        # Mock pour Get-ChildItem
        Mock Get-ChildItem {
            if ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\servers") {
                return @(
                    [PSCustomObject]@{
                        Name     = "filesystem"
                        FullName = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp\servers\filesystem"
                    },
                    [PSCustomObject]@{
                        Name     = "github"
                        FullName = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp\servers\github"
                    }
                )
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\core\\.n8n\\credentials") {
                return @(
                    [PSCustomObject]@{
                        Name     = "1.json"
                        FullName = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp\core\.n8n\credentials\1.json"
                    },
                    [PSCustomObject]@{
                        Name     = "2.json"
                        FullName = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp\core\.n8n\credentials\2.json"
                    }
                )
            } elseif ($Path -match "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\mcp\\core\\.n8n") {
                return @(
                    [PSCustomObject]@{
                        Name     = "credentials.db"
                        FullName = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp\core\.n8n\credentials.db"
                    }
                )
            } else {
                return @()
            }
        }

        # Mock pour Copy-Item
        Mock Copy-Item {}

        # Mock pour Start-Process
        Mock Start-Process {}
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

        It "Get-N8nCredentials devrait retourner des identifiants" {
            $credentials = Get-N8nCredentials
            $credentials.Count | Should -Be 2
            $credentials[0].id | Should -Be "1"
            $credentials[0].name | Should -Be "MCP-filesystem"
        }

        It "New-N8nCredential devrait créer un identifiant" {
            $credential = New-N8nCredential -Name "MCP-Test" -Type "mcpApi" -Data @{ server = "test"; path = "test" } -NodesAccess @()
            $credential.id | Should -Be "3"
            $credential.name | Should -Be "MCP-Test"
        }

        It "Update-N8nCredential devrait mettre à jour un identifiant" {
            $credential = Update-N8nCredential -CredentialId "1" -Name "MCP-filesystem-updated" -Type "mcpApi" -Data @{ server = "filesystem"; path = "updated" } -NodesAccess @()
            $credential.id | Should -Be "1"
            $credential.name | Should -Be "MCP-filesystem-updated"
        }

        It "Remove-N8nCredential devrait supprimer un identifiant" {
            $result = Remove-N8nCredential -CredentialId "1"
            $result.success | Should -Be $true
        }
    }

    Context "Fonctions d'intégration" {
        It "Get-McpServers devrait retourner des serveurs MCP" {
            $servers = Get-McpServers
            $servers.Count | Should -Be 2
            $servers[0].Name | Should -Be "filesystem"
            $servers[1].Name | Should -Be "github"
        }

        It "Set-McpCredentialsInN8n devrait configurer les identifiants MCP dans n8n" {
            # Mock pour Get-McpN8nConfig pour retourner un objet avec les propriétés nécessaires
            Mock Get-McpN8nConfig {
                return [PSCustomObject]@{
                    N8nUrl      = "http://localhost:5678"
                    ApiKey      = ""
                    McpPath     = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp"
                    LastSync    = $null
                    Servers     = @()
                    Credentials = @()
                }
            }

            # Mock pour Save-McpN8nConfig pour capturer l'objet Config
            $script:savedConfig = $null
            Mock Save-McpN8nConfig {
                param($Config)
                $script:savedConfig = $Config
            }

            $result = Set-McpCredentialsInN8n
            $result | Should -Be $true
        }

        It "Copy-McpCredentialsToN8n devrait copier les identifiants MCP vers n8n" {
            $result = Copy-McpCredentialsToN8n
            $result | Should -Be $true
            Should -Invoke Copy-Item -Times 2
        }

        It "Copy-McpDatabaseToN8n devrait copier la base de données MCP vers n8n" {
            $result = Copy-McpDatabaseToN8n
            $result | Should -Be $true
            Should -Invoke Copy-Item -Times 1
        }

        It "Start-N8nWithMcp devrait démarrer n8n avec les serveurs MCP" {
            $result = Start-N8nWithMcp
            $result | Should -Be $true
            Should -Invoke Start-Process -Times 1
        }

        It "Start-McpN8nIntegration avec Action=Test devrait réussir" {
            $result = Start-McpN8nIntegration -Action "Test"
            $result.Count | Should -Be 2
            $result[0].Name | Should -Be "filesystem"
        }
    }
}
