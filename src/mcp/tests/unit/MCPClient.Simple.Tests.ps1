#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiés pour le module MCPClient.
.DESCRIPTION
    Ce script contient des tests unitaires simplifiés pour le module MCPClient,
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

# Importer le module
Import-Module $modulePath -Force

# Test 1: Initialize-MCPConnection
Describe "Initialize-MCPConnection" {
    It "Should initialize a connection" {
        $result = Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
        
        $result | Should -Be $true
        $script:MCPConfig.ServerUrl | Should -Be "http://localhost:8000"
        $script:MCPConfig.LogPath | Should -Be $script:TestLogPath
    }
}

# Test 2: Get-MCPClientConfiguration
Describe "Get-MCPClientConfiguration" {
    BeforeAll {
        # Initialiser la connexion
        Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
    }
    
    It "Should get the client configuration" {
        $result = Get-MCPClientConfiguration
        
        $result | Should -Not -BeNullOrEmpty
        $result.ServerUrl | Should -Be "http://localhost:8000"
        $result.LogPath | Should -Be $script:TestLogPath
    }
}

# Test 3: Set-MCPClientConfiguration
Describe "Set-MCPClientConfiguration" {
    BeforeAll {
        # Initialiser la connexion
        Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
    }
    
    It "Should update the client configuration" {
        $result = Set-MCPClientConfiguration -Timeout 60 -RetryCount 5 -RetryDelay 3 -LogLevel "DEBUG"
        
        $result | Should -Be $true
        $script:MCPConfig.Timeout | Should -Be 60
        $script:MCPConfig.RetryCount | Should -Be 5
        $script:MCPConfig.RetryDelay | Should -Be 3
        $script:MCPConfig.LogLevel | Should -Be "DEBUG"
    }
}

# Test 4: Get-MCPTools
Describe "Get-MCPTools" {
    BeforeAll {
        # Initialiser la connexion
        Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
        
        # Mock pour Invoke-RestMethod
        Mock Invoke-RestMethod {
            return @{
                tools = @(
                    @{
                        name = "add"
                        description = "Adds two numbers"
                    },
                    @{
                        name = "multiply"
                        description = "Multiplies two numbers"
                    }
                )
            }
        }
    }
    
    It "Should get the list of available tools" {
        $result = Get-MCPTools
        
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 2
        $result[0].name | Should -Be "add"
        $result[1].name | Should -Be "multiply"
    }
}

# Test 5: Invoke-MCPTool
Describe "Invoke-MCPTool" {
    BeforeAll {
        # Initialiser la connexion
        Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
        
        # Mock pour Invoke-RestMethod
        Mock Invoke-RestMethod {
            param($Uri, $Method, $Body, $Headers)
            
            if ($Uri -like "*/tools/add") {
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
            else {
                throw "404 Not Found"
            }
        }
    }
    
    It "Should invoke the add tool" {
        $result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
        
        $result | Should -Not -BeNullOrEmpty
        $result.result | Should -Be 5
    }
    
    It "Should invoke the multiply tool" {
        $result = Invoke-MCPTool -ToolName "multiply" -Parameters @{ a = 4; b = 5 }
        
        $result | Should -Not -BeNullOrEmpty
        $result.result | Should -Be 20
    }
}

# Test 6: Invoke-MCPPowerShell
Describe "Invoke-MCPPowerShell" {
    BeforeAll {
        # Initialiser la connexion
        Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
        
        # Mock pour Invoke-MCPTool
        Mock Invoke-MCPTool {
            return @{
                result = "PowerShell command executed"
            }
        }
    }
    
    It "Should invoke a PowerShell command" {
        $result = Invoke-MCPPowerShell -Command "Get-Process"
        
        $result | Should -Not -BeNullOrEmpty
        $result.result | Should -Be "PowerShell command executed"
    }
}

# Test 7: Invoke-MCPPython
Describe "Invoke-MCPPython" {
    BeforeAll {
        # Initialiser la connexion
        Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
        
        # Mock pour Invoke-MCPTool
        Mock Invoke-MCPTool {
            return @{
                result = "Python script executed"
            }
        }
    }
    
    It "Should invoke a Python script" {
        $result = Invoke-MCPPython -Script "print('Hello, World!')"
        
        $result | Should -Not -BeNullOrEmpty
        $result.result | Should -Be "Python script executed"
    }
}

# Test 8: Get-MCPSystemInfo
Describe "Get-MCPSystemInfo" {
    BeforeAll {
        # Initialiser la connexion
        Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
        
        # Mock pour Invoke-MCPTool
        Mock Invoke-MCPTool {
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
    }
    
    It "Should get system information" {
        $result = Get-MCPSystemInfo
        
        $result | Should -Not -BeNullOrEmpty
        $result.result.os | Should -Be "Windows"
        $result.result.python_version | Should -Be "3.11.0"
    }
}

# Test 9: Clear-MCPCache
Describe "Clear-MCPCache" {
    BeforeAll {
        # Initialiser la connexion
        Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $script:TestLogPath
        
        # Ajouter une entrée au cache
        $script:MCPCache = @{
            "test-key" = @{
                Result = "test-result"
                Timestamp = Get-Date
            }
        }
    }
    
    It "Should clear the cache" {
        $result = Clear-MCPCache -Force
        
        $result | Should -Be $true
        $script:MCPCache.Count | Should -Be 0
    }
}

# Nettoyer
if (Test-Path $script:TestDrive) {
    Remove-Item $script:TestDrive -Recurse -Force
}
