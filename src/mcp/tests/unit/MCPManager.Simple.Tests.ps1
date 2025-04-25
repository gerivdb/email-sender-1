#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiés pour le module MCPManager.
.DESCRIPTION
    Ce script contient des tests unitaires simplifiés pour le module MCPManager,
    en testant chaque fonction individuellement avec des mocks simples.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MCPManager.psm1"

# Vérifier que le module existe
if (-not (Test-Path $modulePath)) {
    throw "Module MCPManager introuvable à $modulePath"
}

# Créer un dossier temporaire pour les tests
$script:TestDrive = Join-Path -Path $env:TEMP -ChildPath "MCPManagerTests_$(Get-Random)"
New-Item -Path $script:TestDrive -ItemType Directory -Force | Out-Null

# Définir les chemins de test
$script:TestConfigPath = Join-Path -Path $script:TestDrive -ChildPath "mcp-config.json"

# Importer le module
Import-Module $modulePath -Force

# Test 1: Write-MCPLog
Describe "Write-MCPLog" {
    It "Should write a log message" {
        # Rediriger la sortie vers une variable
        $output = Write-MCPLog -Message "Test message" -Level "INFO" 4>&1
        
        # Vérifier que la sortie contient le message
        $output | Should -Match "Test message"
    }
}

# Test 2: Test-MCPServer
Describe "Test-MCPServer" {
    BeforeAll {
        # Mock pour Invoke-RestMethod
        Mock Invoke-RestMethod {
            return @{
                status = "ok"
                version = "1.0.0"
            }
        }
    }
    
    It "Should detect a server" {
        $result = Test-MCPServer -Host "localhost" -Port 5678
        
        $result | Should -Not -BeNullOrEmpty
        $result.Type | Should -Be "n8n"
        $result.Version | Should -Be "1.0.0"
    }
}

# Test 3: New-MCPConfiguration
Describe "New-MCPConfiguration" {
    It "Should create a valid configuration file" {
        $result = New-MCPConfiguration -OutputPath $script:TestConfigPath -Force
        
        $result | Should -Be $true
        Test-Path $script:TestConfigPath | Should -Be $true
        
        # Vérifier que le contenu est un JSON valide
        $content = Get-Content -Path $script:TestConfigPath -Raw
        { $content | ConvertFrom-Json } | Should -Not -Throw
    }
}

# Test 4: Find-LocalMCPServers
Describe "Find-LocalMCPServers" {
    BeforeAll {
        # Mock pour New-Object (TcpClient)
        Mock New-Object {
            return @{
                ConnectAsync = {
                    param($HostName, $Port)
                    $task = [System.Threading.Tasks.Task]::FromResult($true)
                    return $task
                }
                Close = { }
            }
        }
        
        # Mock pour Test-MCPServer
        Mock Test-MCPServer {
            return @{
                Type = "n8n"
                Version = "1.0.0"
            }
        }
    }
    
    It "Should find local MCP servers" {
        $result = Find-LocalMCPServers
        
        $result | Should -Not -BeNullOrEmpty
        $result[0].Type | Should -Be "n8n"
    }
}

# Test 5: Find-CloudMCPServers
Describe "Find-CloudMCPServers" {
    BeforeAll {
        # Mock pour Invoke-RestMethod
        Mock Invoke-RestMethod {
            return @{
                servers = @(
                    @{
                        url = "https://example.com/api"
                        type = "augment"
                        version = "1.0.0"
                    }
                )
            }
        }
    }
    
    It "Should find cloud MCP servers" {
        $result = Find-CloudMCPServers
        
        $result | Should -Not -BeNullOrEmpty
        $result[0].Type | Should -Be "augment"
    }
}

# Test 6: Find-MCPServers
Describe "Find-MCPServers" {
    BeforeAll {
        # Mock pour Find-LocalMCPServers
        Mock Find-LocalMCPServers {
            return @(
                @{
                    Host = "localhost"
                    Port = 5678
                    Type = "n8n"
                    Version = "1.0.0"
                }
            )
        }
        
        # Mock pour Find-CloudMCPServers
        Mock Find-CloudMCPServers {
            return @(
                @{
                    Host = "example.com"
                    Port = 443
                    Type = "augment"
                    Version = "1.0.0"
                }
            )
        }
    }
    
    It "Should find all MCP servers" {
        $result = Find-MCPServers
        
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 2
        $result[0].Type | Should -Be "n8n"
        $result[1].Type | Should -Be "augment"
    }
}

# Test 7: Start-MCPServer
Describe "Start-MCPServer" {
    BeforeAll {
        # Mock pour Start-Process
        Mock Start-Process {
            return @{
                Id = 12345
                HasExited = $false
            }
        }
        
        # Mock pour Test-Path
        Mock Test-Path { return $true }
    }
    
    It "Should start a local server" {
        $result = Start-MCPServer -ServerType "local" -Port 8000
        
        $result | Should -Not -BeNullOrEmpty
        $result.Id | Should -Be 12345
    }
}

# Test 8: Stop-MCPServer
Describe "Stop-MCPServer" {
    BeforeAll {
        # Mock pour Get-Process
        Mock Get-Process {
            return @{
                Id = 12345
                Kill = { }
            }
        }
    }
    
    It "Should stop a server by type and port" {
        $result = Stop-MCPServer -ServerType "local" -Port 8000
        
        $result | Should -Be $true
    }
}

# Nettoyer
if (Test-Path $script:TestDrive) {
    Remove-Item $script:TestDrive -Recurse -Force
}
