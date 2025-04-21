#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module MCPClient.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module MCPClient.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MCPClient.psm1"

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module MCPClient.psm1 n'existe pas à l'emplacement spécifié: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = 'Detailed'

# Définir les tests
Describe "MCPClient Module Tests" {
    BeforeAll {
        # Mock pour Invoke-RestMethod
        function global:Invoke-RestMethod { 
            param($Uri, $Method, $Body, $ContentType, $TimeoutSec)
            
            # Simuler différentes réponses en fonction de l'URI
            switch -Wildcard ($Uri) {
                "*health*" {
                    return @{
                        version = "1.0.0"
                        status = "ok"
                    }
                }
                "*tools*" {
                    if ($Method -eq "Get") {
                        return @{
                            tools = @(
                                @{
                                    name = "add"
                                    description = "Adds two numbers"
                                    parameters = @{
                                        a = @{
                                            type = "number"
                                            description = "First number"
                                        }
                                        b = @{
                                            type = "number"
                                            description = "Second number"
                                        }
                                    }
                                },
                                @{
                                    name = "subtract"
                                    description = "Subtracts two numbers"
                                    parameters = @{
                                        a = @{
                                            type = "number"
                                            description = "First number"
                                        }
                                        b = @{
                                            type = "number"
                                            description = "Second number"
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
                "*tools/add*" {
                    $bodyObj = $Body | ConvertFrom-Json
                    return @{
                        result = $bodyObj.a + $bodyObj.b
                    }
                }
                "*tools/subtract*" {
                    $bodyObj = $Body | ConvertFrom-Json
                    return @{
                        result = $bodyObj.a - $bodyObj.b
                    }
                }
                "*tools/run_powershell_command*" {
                    $bodyObj = $Body | ConvertFrom-Json
                    return @{
                        output = "PowerShell command executed: $($bodyObj.command)"
                        exit_code = 0
                    }
                }
                "*tools/get_system_info*" {
                    return @{
                        os = "Windows"
                        version = "10.0.19042"
                        hostname = "DESKTOP-TEST"
                        cpu = "Intel(R) Core(TM) i7-10700K CPU @ 3.80GHz"
                        memory = "32GB"
                    }
                }
                "*tools/find_mcp_servers*" {
                    return @{
                        servers = @(
                            @{
                                url = "http://localhost:8000"
                                type = "local"
                                status = "running"
                            },
                            @{
                                url = "http://localhost:5678"
                                type = "n8n"
                                status = "running"
                            }
                        )
                    }
                }
                "*tools/run_python_script*" {
                    $bodyObj = $Body | ConvertFrom-Json
                    return @{
                        output = "Python script executed: $($bodyObj.script)"
                        exit_code = 0
                    }
                }
                "*tools/http_request*" {
                    $bodyObj = $Body | ConvertFrom-Json
                    return @{
                        status_code = 200
                        headers = @{
                            "Content-Type" = "application/json"
                        }
                        body = @{
                            message = "Success"
                        }
                    }
                }
                default {
                    throw "URI not mocked: $Uri"
                }
            }
        }
    }

    AfterAll {
        # Supprimer le mock
        Remove-Item -Path function:global:Invoke-RestMethod -ErrorAction SilentlyContinue
    }

    Context "Initialize-MCPConnection" {
        It "Should initialize connection successfully" {
            $result = Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $result | Should -Be $true
        }

        It "Should set the correct configuration" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -Timeout 60 -RetryCount 5 -RetryDelay 3
            $config = Get-MCPClientConfiguration
            $config.ServerUrl | Should -Be "http://localhost:8000"
            $config.Timeout | Should -Be 60
            $config.RetryCount | Should -Be 5
            $config.RetryDelay | Should -Be 3
        }
    }

    Context "Get-MCPTools" {
        It "Should return a list of tools" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $tools = Get-MCPTools
            $tools | Should -Not -BeNullOrEmpty
            $tools.Count | Should -Be 2
            $tools[0].name | Should -Be "add"
            $tools[1].name | Should -Be "subtract"
        }
    }

    Context "Invoke-MCPTool" {
        It "Should invoke the add tool correctly" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
            $result.result | Should -Be 5
        }

        It "Should invoke the subtract tool correctly" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $result = Invoke-MCPTool -ToolName "subtract" -Parameters @{ a = 5; b = 3 }
            $result.result | Should -Be 2
        }
    }

    Context "Invoke-MCPPowerShell" {
        It "Should execute PowerShell commands" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $result = Invoke-MCPPowerShell -Command "Get-Process"
            $result.output | Should -BeLike "*PowerShell command executed: Get-Process*"
            $result.exit_code | Should -Be 0
        }
    }

    Context "Get-MCPSystemInfo" {
        It "Should return system information" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $result = Get-MCPSystemInfo
            $result.os | Should -Be "Windows"
            $result.version | Should -Be "10.0.19042"
            $result.hostname | Should -Be "DESKTOP-TEST"
        }
    }

    Context "Find-MCPServers" {
        It "Should find available MCP servers" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $result = Find-MCPServers
            $result.servers | Should -Not -BeNullOrEmpty
            $result.servers.Count | Should -Be 2
            $result.servers[0].url | Should -Be "http://localhost:8000"
            $result.servers[1].url | Should -Be "http://localhost:5678"
        }
    }

    Context "Invoke-MCPPython" {
        It "Should execute Python scripts" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $result = Invoke-MCPPython -Script "print('Hello, World!')"
            $result.output | Should -BeLike "*Python script executed: print('Hello, World!')*"
            $result.exit_code | Should -Be 0
        }
    }

    Context "Invoke-MCPHttpRequest" {
        It "Should execute HTTP requests" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $result = Invoke-MCPHttpRequest -Url "https://api.example.com/data" -Method "GET"
            $result.status_code | Should -Be 200
            $result.body.message | Should -Be "Success"
        }
    }

    Context "Set-MCPClientConfiguration" {
        It "Should update the configuration" {
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            $result = Set-MCPClientConfiguration -Timeout 120 -RetryCount 10 -RetryDelay 5
            $result | Should -Be $true
            
            $config = Get-MCPClientConfiguration
            $config.Timeout | Should -Be 120
            $config.RetryCount | Should -Be 10
            $config.RetryDelay | Should -Be 5
        }
    }
}

# Exécuter les tests
Invoke-Pester -Configuration $pesterConfig
