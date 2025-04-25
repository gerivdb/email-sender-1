#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires complets pour le module MCPManager.
.DESCRIPTION
    Ce script contient les tests unitaires complets pour toutes les fonctions du module MCPManager.
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
if (Test-Path $script:TestDrive) {
    Remove-Item $script:TestDrive -Recurse -Force
}
New-Item -Path $script:TestDrive -ItemType Directory -Force | Out-Null

# Définir les chemins de test
$script:TestConfigPath = Join-Path -Path $script:TestDrive -ChildPath "mcp-config.json"
$script:TestDetectedServersPath = Join-Path -Path $script:TestDrive -ChildPath "detected.json"

Describe "MCPManager Module Tests" {
    BeforeAll {
        # Importer le module
        Import-Module $modulePath -Force

        # Rediriger la sortie de Write-MCPLog pour les tests
        function global:Write-MCPLog { param([string]$Message, [string]$Level = "INFO") }

        # Créer un mock pour Invoke-RestMethod
        Mock Invoke-RestMethod {
            return @{
                status  = "ok"
                version = "1.0.0"
                service = "augment"
            }
        }

        # Créer un mock pour Get-NetIPAddress
        Mock Get-NetIPAddress {
            return @{
                IPAddress     = "192.168.1.100"
                AddressFamily = "IPv4"
                PrefixOrigin  = "Manual"
            }
        }

        # Créer un mock pour Start-Process
        Mock Start-Process {
            return @{
                Id        = 12345
                HasExited = $false
            }
        }

        # Créer un mock pour Get-Process
        Mock Get-Process {
            return @{
                Id          = 12345
                CommandLine = "python server:app --port 8000"
                Kill        = { }
            }
        }

        # Créer un mock pour Get-Command
        Mock Get-Command {
            return @{
                Source = "C:\Python\python.exe"
            }
        }

        # Créer un mock pour python
        Mock python {
            return "3.11.0"
        }

        # Créer un mock pour npm
        Mock npm {
            return "OK"
        }
    }

    AfterAll {
        # Nettoyer
        if (Test-Path $script:TestDrive) {
            Remove-Item $script:TestDrive -Recurse -Force
        }
    }

    Context "Write-MCPLog" {
        It "Should write a log message with INFO level" {
            # Redéfinir Write-MCPLog pour le test
            function global:Write-MCPLog { param([string]$Message, [string]$Level = "INFO") }

            # Créer un mock pour Write-Host
            Mock Write-Host { }

            # Exécuter la fonction
            Write-MCPLog -Message "Test message" -Level "INFO"

            # Vérifier que Write-Host a été appelé
            Should -Invoke Write-Host -Times 2
        }
    }

    Context "Test-MCPServer" {
        It "Should detect an Augment server" {
            # Créer un mock pour Invoke-RestMethod qui retourne un serveur Augment
            Mock Invoke-RestMethod {
                return @{
                    status  = "ok"
                    service = "augment"
                    version = "1.0.0"
                }
            }

            # Exécuter la fonction
            $result = Test-MCPServer -Host "localhost" -Port 3000

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be "augment"
            $result.Version | Should -Be "1.0.0"
        }

        It "Should detect an n8n server" {
            # Créer un mock pour Invoke-RestMethod qui retourne un serveur n8n
            Mock Invoke-RestMethod {
                return @{
                    status  = "ok"
                    version = "1.0.0"
                }
            }

            # Exécuter la fonction
            $result = Test-MCPServer -Host "localhost" -Port 5678

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be "n8n"
            $result.Version | Should -Be "1.0.0"
        }

        It "Should return null for non-MCP servers" {
            # Créer un mock pour Invoke-RestMethod qui lève une exception
            Mock Invoke-RestMethod {
                throw "Connection refused"
            }

            # Exécuter la fonction
            $result = Test-MCPServer -Host "localhost" -Port 9999

            # Vérifier le résultat
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Find-LocalMCPServers" {
        It "Should find local MCP servers" {
            # Créer un mock pour New-Object qui retourne un TcpClient
            Mock New-Object {
                return @{
                    ConnectAsync = {
                        param($HostName, $Port)
                        $task = [System.Threading.Tasks.Task]::FromResult($true)
                        return $task
                    }
                    Close        = { }
                }
            }

            # Créer un mock pour Test-MCPServer
            Mock Test-MCPServer {
                return @{
                    Type    = "n8n"
                    Version = "1.0.0"
                }
            }

            # Exécuter la fonction
            $result = Find-LocalMCPServers

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
            $result[0].Type | Should -Be "n8n"
        }
    }

    Context "New-MCPConfiguration" {
        It "Should create a valid MCP configuration" {
            # Exécuter la fonction
            $result = New-MCPConfiguration -OutputPath $script:TestConfigPath -Force

            # Vérifier le résultat
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
        It "Should start a local MCP server" {
            # Exécuter la fonction
            $result = Start-MCPServer -ServerType "local" -Port 8000

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be 12345
        }

        It "Should start an n8n server" {
            # Créer un mock pour Test-Path qui retourne $true
            Mock Test-Path { return $true }

            # Exécuter la fonction
            $result = Start-MCPServer -ServerType "n8n" -Port 5678

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be 12345
        }
    }

    Context "Stop-MCPServer" {
        It "Should stop a server by process" {
            # Créer un mock pour le processus
            $process = @{
                Id        = 12345
                HasExited = $false
                Kill      = { }
            }

            # Exécuter la fonction
            $result = Stop-MCPServer -Process $process

            # Vérifier le résultat
            $result | Should -Be $true
        }

        It "Should stop a local server by type and port" {
            # Exécuter la fonction
            $result = Stop-MCPServer -ServerType "local" -Port 8000

            # Vérifier le résultat
            $result | Should -Be $true
        }
    }

    Context "Install-MCPDependencies" {
        It "Should install Python dependencies" {
            # Exécuter la fonction
            $result = Install-MCPDependencies

            # Vérifier le résultat
            $result | Should -Be $true
        }
    }
}

# Les tests seront exécutés par le script Run-AllTests.ps1
