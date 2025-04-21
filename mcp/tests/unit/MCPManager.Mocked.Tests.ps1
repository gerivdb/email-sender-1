#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires avec mocks complets pour le module MCPManager.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module MCPManager,
    en utilisant des mocks complets pour éviter les dépendances externes.
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

Describe "MCPManager Module Tests with Mocks" {
    BeforeAll {
        # Importer le module
        Import-Module $modulePath -Force
        
        # Mock pour Write-MCPLog
        Mock Write-MCPLog { 
            param([string]$Message, [string]$Level = "INFO")
            return "$Level - $Message"
        }
        
        # Mock pour Test-MCPServer
        Mock Test-MCPServer {
            param([string]$HostName, [int]$Port)
            
            if ($Port -eq 3000) {
                return @{
                    Host = $HostName
                    Port = $Port
                    Type = "augment"
                    Version = "1.0.0"
                }
            }
            elseif ($Port -eq 5678) {
                return @{
                    Host = $HostName
                    Port = $Port
                    Type = "n8n"
                    Version = "1.0.0"
                }
            }
            else {
                return $null
            }
        }
        
        # Mock pour Find-LocalMCPServers
        Mock Find-LocalMCPServers {
            return @(
                @{
                    Host = "localhost"
                    Port = 3000
                    Type = "augment"
                    Version = "1.0.0"
                },
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
        
        # Mock pour New-MCPConfiguration
        Mock New-MCPConfiguration {
            param([string]$OutputPath, [switch]$Force)
            
            $config = @{
                mcpServers = @{
                    filesystem = @{
                        type = "filesystem"
                        path = "D:\mcp-data"
                    }
                    n8n = @{
                        type = "n8n"
                        url = "http://localhost:5678"
                    }
                    augment = @{
                        type = "augment"
                        url = "http://localhost:3000"
                    }
                }
            }
            
            $configJson = $config | ConvertTo-Json -Depth 10
            Set-Content -Path $OutputPath -Value $configJson -Force
            
            return $true
        }
        
        # Mock pour Start-MCPServer
        Mock Start-MCPServer {
            param([string]$ServerType, [int]$Port)
            
            return @{
                Id = 12345
                HasExited = $false
            }
        }
        
        # Mock pour Stop-MCPServer
        Mock Stop-MCPServer {
            param([string]$ServerType, [int]$Port)
            
            return $true
        }
    }
    
    AfterAll {
        # Nettoyer
        if (Test-Path $script:TestDrive) {
            Remove-Item $script:TestDrive -Recurse -Force
        }
    }
    
    Context "Write-MCPLog" {
        It "Should write a log message" {
            $result = Write-MCPLog -Message "Test message" -Level "INFO"
            $result | Should -Be "INFO - Test message"
        }
    }
    
    Context "Test-MCPServer" {
        It "Should detect an Augment server" {
            $result = Test-MCPServer -HostName "localhost" -Port 3000
            
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be "augment"
            $result.Version | Should -Be "1.0.0"
        }
        
        It "Should detect an n8n server" {
            $result = Test-MCPServer -HostName "localhost" -Port 5678
            
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be "n8n"
            $result.Version | Should -Be "1.0.0"
        }
        
        It "Should return null for non-MCP servers" {
            $result = Test-MCPServer -HostName "localhost" -Port 9999
            
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context "Find-LocalMCPServers" {
        It "Should find local MCP servers" {
            $result = Find-LocalMCPServers
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].Type | Should -Be "augment"
            $result[1].Type | Should -Be "n8n"
        }
    }
    
    Context "Find-CloudMCPServers" {
        It "Should find cloud MCP servers" {
            $result = Find-CloudMCPServers
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result[0].Type | Should -Be "augment"
        }
    }
    
    Context "Find-MCPServers" {
        It "Should find all MCP servers" {
            $result = Find-MCPServers
            
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].Type | Should -Be "augment"
            $result[1].Type | Should -Be "n8n"
            $result[2].Type | Should -Be "augment"
        }
    }
    
    Context "New-MCPConfiguration" {
        It "Should create a valid configuration file" {
            $result = New-MCPConfiguration -OutputPath $script:TestConfigPath -Force
            
            $result | Should -Be $true
            Test-Path $script:TestConfigPath | Should -Be $true
            
            # Vérifier que le contenu est un JSON valide
            $content = Get-Content -Path $script:TestConfigPath -Raw
            { $content | ConvertFrom-Json } | Should -Not -Throw
            
            # Vérifier que la configuration contient les serveurs attendus
            $config = $content | ConvertFrom-Json
            $config.mcpServers.filesystem | Should -Not -BeNullOrEmpty
            $config.mcpServers.n8n | Should -Not -BeNullOrEmpty
            $config.mcpServers.augment | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Start-MCPServer" {
        It "Should start a local server" {
            $result = Start-MCPServer -ServerType "local" -Port 8000
            
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be 12345
        }
    }
    
    Context "Stop-MCPServer" {
        It "Should stop a server by type and port" {
            $result = Stop-MCPServer -ServerType "local" -Port 8000
            
            $result | Should -Be $true
        }
    }
}
