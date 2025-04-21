#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires complets pour le module MCPClient.
.DESCRIPTION
    Ce script contient les tests unitaires complets pour toutes les fonctions du module MCPClient.
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
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MCPClient.psm1"

# Vérifier que le module existe
if (-not (Test-Path $modulePath)) {
    throw "Module MCPClient introuvable à $modulePath"
}

# Créer un dossier temporaire pour les tests
$script:TestDrive = Join-Path -Path $env:TEMP -ChildPath "MCPClientTests_$(Get-Random)"
if (Test-Path $script:TestDrive) {
    Remove-Item $script:TestDrive -Recurse -Force
}
New-Item -Path $script:TestDrive -ItemType Directory -Force | Out-Null

# Définir les chemins de test
$script:TestLogPath = Join-Path -Path $script:TestDrive -ChildPath "MCPClient.log"

Describe "MCPClient Module Tests" {
    BeforeAll {
        # Importer le module
        Import-Module $modulePath -Force

        # Rediriger la sortie de Write-MCPLog pour les tests
        function global:Write-MCPLog { param([string]$Message, [string]$Level = "INFO") }

        # Créer un mock pour Invoke-RestMethod
        Mock Invoke-RestMethod {
            param($Uri, $Method, $Body, $Headers, $TimeoutSec)

            if ($Uri -like "*/health") {
                return @{
                    status  = "ok"
                    version = "1.0.0"
                }
            } elseif ($Uri -like "*/tools") {
                return @{
                    tools = @(
                        @{
                            name        = "add"
                            description = "Adds two numbers"
                            parameters  = @{
                                a = @{ type = "number" }
                                b = @{ type = "number" }
                            }
                        },
                        @{
                            name        = "multiply"
                            description = "Multiplies two numbers"
                            parameters  = @{
                                a = @{ type = "number" }
                                b = @{ type = "number" }
                            }
                        }
                    )
                }
            } elseif ($Uri -like "*/tools/add") {
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    result = $bodyObj.a + $bodyObj.b
                }
            } elseif ($Uri -like "*/tools/multiply") {
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    result = $bodyObj.a * $bodyObj.b
                }
            } elseif ($Uri -like "*/tools/get_system_info") {
                return @{
                    result = @{
                        os             = "Windows"
                        os_version     = "10.0.19045"
                        python_version = "3.11.0"
                        hostname       = "DESKTOP-TEST"
                        cpu_count      = 8
                    }
                }
            } else {
                throw "404 Not Found"
            }
        }
    }

    AfterAll {
        # Nettoyer
        if (Test-Path $script:TestDrive) {
            Remove-Item $script:TestDrive -Recurse -Force
        }
    }

    Context "Initialize-MCPConnection" {
        It "Should initialize a connection to an MCP server" {
            # Exécuter la fonction
            $result = Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Vérifier le résultat
            $result | Should -Be $true
            $script:MCPConfig.ServerUrl | Should -Be "http://localhost:8000"
            $script:MCPConfig.LogPath | Should -Be $script:TestLogPath
        }
    }

    Context "Get-MCPTools" {
        It "Should get the list of available tools" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Exécuter la fonction
            $result = Get-MCPTools

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0].name | Should -Be "add"
            $result[1].name | Should -Be "multiply"
        }
    }

    Context "Invoke-MCPTool" {
        It "Should invoke the add tool" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Exécuter la fonction
            $result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be 5
        }

        It "Should invoke the multiply tool" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Exécuter la fonction
            $result = Invoke-MCPTool -ToolName "multiply" -Parameters @{ a = 4; b = 5 }

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be 20
        }

        It "Should throw an error for a non-existent tool" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Exécuter la fonction et vérifier qu'elle lève une exception
            { Invoke-MCPTool -ToolName "nonexistent" -Parameters @{} } | Should -Throw
        }
    }

    Context "Invoke-MCPPowerShell" {
        It "Should invoke a PowerShell command" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Créer un mock pour Invoke-MCPTool
            Mock Invoke-MCPTool {
                param($ToolName, $Parameters)
                return @{
                    result = "PowerShell command executed"
                }
            }

            # Exécuter la fonction
            $result = Invoke-MCPPowerShell -Command "Get-Process"

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be "PowerShell command executed"
        }
    }

    Context "Get-MCPSystemInfo" {
        It "Should get system information" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Exécuter la fonction
            $result = Get-MCPSystemInfo

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Not -BeNullOrEmpty
            $result.result.os | Should -Be "Windows"
            $result.result.os_version | Should -Be "10.0.19045"
            $result.result.python_version | Should -Be "3.11.0"
            $result.result.hostname | Should -Be "DESKTOP-TEST"
            $result.result.cpu_count | Should -Be 8
        }
    }

    Context "Invoke-MCPPython" {
        It "Should invoke a Python script" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Créer un mock pour Invoke-MCPTool
            Mock Invoke-MCPTool {
                param($ToolName, $Parameters)
                return @{
                    result = "Python script executed"
                }
            }

            # Exécuter la fonction
            $result = Invoke-MCPPython -Script "print('Hello, World!')"

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be "Python script executed"
        }
    }

    Context "Invoke-MCPHttpRequest" {
        It "Should invoke an HTTP request" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Créer un mock pour Invoke-MCPTool
            Mock Invoke-MCPTool {
                param($ToolName, $Parameters)
                return @{
                    status_code = 200
                    content     = "HTTP request executed"
                }
            }

            # Exécuter la fonction
            $result = Invoke-MCPHttpRequest -Url "https://example.com" -Method "GET"

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.status_code | Should -Be 200
            $result.content | Should -Be "HTTP request executed"
        }
    }

    Context "Set-MCPClientConfiguration" {
        It "Should update the client configuration" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Exécuter la fonction
            $result = Set-MCPClientConfiguration -Timeout 60 -RetryCount 5 -RetryDelay 3 -LogLevel "DEBUG"

            # Vérifier le résultat
            $result | Should -Be $true
            $script:MCPConfig.Timeout | Should -Be 60
            $script:MCPConfig.RetryCount | Should -Be 5
            $script:MCPConfig.RetryDelay | Should -Be 3
            $script:MCPConfig.LogLevel | Should -Be "DEBUG"
        }
    }

    Context "Get-MCPClientConfiguration" {
        It "Should get the client configuration" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Mettre à jour la configuration
            Set-MCPClientConfiguration -Timeout 60 -RetryCount 5 -RetryDelay 3 -LogLevel "DEBUG"

            # Exécuter la fonction
            $result = Get-MCPClientConfiguration

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.ServerUrl | Should -Be "http://localhost:8000"
            $result.Timeout | Should -Be 60
            $result.RetryCount | Should -Be 5
            $result.RetryDelay | Should -Be 3
            $result.LogLevel | Should -Be "DEBUG"
        }
    }

    Context "Clear-MCPCache" {
        It "Should clear the cache" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath

            # Ajouter une entrée au cache
            $script:MCPCache = @{
                "test-key" = @{
                    Result    = "test-result"
                    Timestamp = Get-Date
                }
            }

            # Exécuter la fonction
            $result = Clear-MCPCache -Force

            # Vérifier le résultat
            $result | Should -Be $true
            $script:MCPCache.Count | Should -Be 0
        }
    }
}

# Les tests seront exécutés par le script Run-AllTests.ps1
