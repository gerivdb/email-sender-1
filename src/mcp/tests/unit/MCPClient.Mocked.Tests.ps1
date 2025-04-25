#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires avec mocks complets pour le module MCPClient.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module MCPClient,
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
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MCPClient.psm1"

# Vérifier que le module existe
if (-not (Test-Path $modulePath)) {
    throw "Module MCPClient introuvable à $modulePath"
}

# Créer un dossier temporaire pour les tests
$script:TestDrive = Join-Path -Path $env:TEMP -ChildPath "MCPClientTests_$(Get-Random)"
New-Item -Path $script:TestDrive -ItemType Directory -Force | Out-Null

# Définir les chemins de test
$script:TestLogPath = Join-Path -Path $script:TestDrive -ChildPath "MCPClient.log"

Describe "MCPClient Module Tests with Mocks" {
    BeforeAll {
        # Importer le module
        Import-Module $modulePath -Force
        
        # Initialiser les variables globales du module
        $script:MCPConfig = @{
            ServerUrl = $null
            LogPath = $null
            Timeout = 30
            RetryCount = 3
            RetryDelay = 2
            LogLevel = "INFO"
        }
        
        $script:MCPCache = @{}
        
        # Mock pour Invoke-RestMethod
        Mock Invoke-RestMethod {
            param($Uri, $Method, $Body, $Headers, $TimeoutSec)
            
            if ($Uri -like "*/health") {
                return @{
                    status = "ok"
                    version = "1.0.0"
                }
            }
            elseif ($Uri -like "*/tools") {
                return @{
                    tools = @(
                        @{
                            name = "add"
                            description = "Adds two numbers"
                            parameters = @{
                                a = @{ type = "number" }
                                b = @{ type = "number" }
                            }
                        },
                        @{
                            name = "multiply"
                            description = "Multiplies two numbers"
                            parameters = @{
                                a = @{ type = "number" }
                                b = @{ type = "number" }
                            }
                        }
                    )
                }
            }
            elseif ($Uri -like "*/tools/add") {
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    result = $bodyObj.a + $bodyObj.b
                }
            }
            elseif ($Uri -like "*/tools/multiply") {
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    result = $bodyObj.a * $bodyObj.b
                }
            }
            elseif ($Uri -like "*/tools/run_powershell_command") {
                return @{
                    result = "PowerShell command executed"
                }
            }
            elseif ($Uri -like "*/tools/run_python_script") {
                return @{
                    result = "Python script executed"
                }
            }
            elseif ($Uri -like "*/tools/get_system_info") {
                return @{
                    result = @{
                        os = "Windows"
                        os_version = "10.0.19045"
                        python_version = "3.11.0"
                        hostname = "DESKTOP-TEST"
                        cpu_count = 8
                    }
                }
            }
            else {
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
        It "Should initialize a connection" {
            $result = Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
            
            $result | Should -Be $true
            $script:MCPConfig.ServerUrl | Should -Be "http://localhost:8000"
            $script:MCPConfig.LogPath | Should -Be $script:TestLogPath
        }
    }
    
    Context "Get-MCPClientConfiguration" {
        It "Should get the client configuration" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
            
            $result = Get-MCPClientConfiguration
            
            $result | Should -Not -BeNullOrEmpty
            $result.ServerUrl | Should -Be "http://localhost:8000"
            $result.LogPath | Should -Be $script:TestLogPath
        }
    }
    
    Context "Set-MCPClientConfiguration" {
        It "Should update the client configuration" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
            
            $result = Set-MCPClientConfiguration -Timeout 60 -RetryCount 5 -RetryDelay 3 -LogLevel "DEBUG"
            
            $result | Should -Be $true
            $script:MCPConfig.Timeout | Should -Be 60
            $script:MCPConfig.RetryCount | Should -Be 5
            $script:MCPConfig.RetryDelay | Should -Be 3
            $script:MCPConfig.LogLevel | Should -Be "DEBUG"
        }
    }
    
    Context "Get-MCPTools" {
        It "Should get the list of available tools" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
            
            $result = Get-MCPTools
            
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
            
            $result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
            
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be 5
        }
        
        It "Should invoke the multiply tool" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
            
            $result = Invoke-MCPTool -ToolName "multiply" -Parameters @{ a = 4; b = 5 }
            
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be 20
        }
    }
    
    Context "Invoke-MCPPowerShell" {
        It "Should invoke a PowerShell command" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
            
            $result = Invoke-MCPPowerShell -Command "Get-Process"
            
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be "PowerShell command executed"
        }
    }
    
    Context "Invoke-MCPPython" {
        It "Should invoke a Python script" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
            
            $result = Invoke-MCPPython -Script "print('Hello, World!')"
            
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be "Python script executed"
        }
    }
    
    Context "Get-MCPSystemInfo" {
        It "Should get system information" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
            
            $result = Get-MCPSystemInfo
            
            $result | Should -Not -BeNullOrEmpty
            $result.result.os | Should -Be "Windows"
            $result.result.python_version | Should -Be "3.11.0"
        }
    }
    
    Context "Clear-MCPCache" {
        It "Should clear the cache" {
            # Initialiser la connexion
            Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
            
            # Ajouter une entrée au cache
            $script:MCPCache = @{
                "test-key" = @{
                    Result = "test-result"
                    Timestamp = Get-Date
                }
            }
            
            $result = Clear-MCPCache -Force
            
            $result | Should -Be $true
            $script:MCPCache.Count | Should -Be 0
        }
    }
}
