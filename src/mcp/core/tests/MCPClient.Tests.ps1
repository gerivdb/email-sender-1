#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module MCPClient.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module MCPClient qui interagit avec le serveur FastAPI.
.EXAMPLE
    Invoke-Pester -Path .\MCPClient.Tests.ps1
    Exécute les tests unitaires pour le module MCPClient.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
#>

# Importer le module Pester s'il n'est pas déjà importé
if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester -ErrorAction Stop
}

# Définir les tests
Describe "MCPClient Module Tests" {
    BeforeAll {
        # Importer le module MCPClient
        $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "MCPClient.psm1"
        Import-Module -Name $modulePath -Force

        # Variables globales pour les tests
        $script:serverUrl = "http://localhost:8000"

        # Initialiser la connexion au serveur MCP
        Initialize-MCPConnection -ServerUrl $script:serverUrl
    }

    # Tests pour Initialize-MCPConnection
    Context "Initialize-MCPConnection" {
        It "Should set the server URL correctly" {
            # Appeler la fonction
            Initialize-MCPConnection -ServerUrl "http://example.com"

            # Vérifier que la variable globale a été mise à jour
            # Accéder à la variable globale du module
            $moduleVars = Get-Variable -Scope Script -Name MCPServerUrl -ValueOnly -ErrorAction SilentlyContinue
            $moduleVars | Should -Be "http://example.com"

            # Réinitialiser la variable globale
            Initialize-MCPConnection -ServerUrl $script:serverUrl
        }
    }

    # Tests pour Get-MCPTools
    Context "Get-MCPTools" {
        BeforeEach {
            # Mock pour Invoke-RestMethod
            Mock Invoke-RestMethod {
                return @(
                    @{
                        name        = "add"
                        description = "Additionne deux nombres"
                        parameters  = @{a = "int"; b = "int" }
                        returns     = "int"
                    },
                    @{
                        name        = "multiply"
                        description = "Multiplie deux nombres"
                        parameters  = @{a = "int"; b = "int" }
                        returns     = "int"
                    },
                    @{
                        name        = "get_system_info"
                        description = "Retourne des informations sur le système"
                        parameters  = @{}
                        returns     = "dict"
                    }
                )
            } -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools" -and
                $Method -eq "Get" -and
                $Headers.Accept -eq "application/json"
            }
        }

        It "Should return the list of tools" {
            # Appeler la fonction
            $tools = Get-MCPTools

            # Vérifier le résultat
            $tools | Should -Not -BeNullOrEmpty
            $tools.Count | Should -Be 3
            $tools[0].name | Should -Be "add"
            $tools[1].name | Should -Be "multiply"
            $tools[2].name | Should -Be "get_system_info"
        }

        It "Should call Invoke-RestMethod with the correct parameters" {
            # Appeler la fonction
            Get-MCPTools | Out-Null

            # Vérifier que Invoke-RestMethod a été appelé correctement
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools" -and
                $Method -eq "Get" -and
                $Headers.Accept -eq "application/json"
            }
        }
    }

    # Tests pour Invoke-MCPTool
    Context "Invoke-MCPTool" {
        BeforeAll {
            # Mock pour Invoke-RestMethod pour l'outil add
            Mock Invoke-RestMethod {
                param($Uri, $Method, $Body, $ContentType, $Headers)
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    result = $bodyObj.a + $bodyObj.b
                }
            } -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools/add" -and
                $Method -eq "Post" -and
                $ContentType -eq "application/json" -and
                $Headers.Accept -eq "application/json"
            }

            # Mock pour Invoke-RestMethod pour l'outil multiply
            Mock Invoke-RestMethod {
                param($Uri, $Method, $Body, $ContentType, $Headers)
                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    result = $bodyObj.a * $bodyObj.b
                }
            } -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools/multiply" -and
                $Method -eq "Post" -and
                $ContentType -eq "application/json" -and
                $Headers.Accept -eq "application/json"
            }

            # Mock pour Invoke-RestMethod pour l'outil get_system_info
            Mock Invoke-RestMethod {
                return @{
                    result = @{
                        os             = "Windows"
                        os_version     = "10.0.19042"
                        python_version = "3.9.7"
                        hostname       = "DESKTOP-1234567"
                        cpu_count      = 8
                    }
                }
            } -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools/get_system_info" -and
                $Method -eq "Post" -and
                $ContentType -eq "application/json" -and
                $Headers.Accept -eq "application/json"
            }
        }

        It "Should call the add tool correctly" {
            # Appeler la fonction
            $result = Invoke-MCPTool -ToolName "add" -Parameters @{a = 2; b = 3 }

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be 5

            # Vérifier que Invoke-RestMethod a été appelé correctement
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools/add" -and
                $Method -eq "Post" -and
                $ContentType -eq "application/json" -and
                $Headers.Accept -eq "application/json"
            }
        }

        It "Should call the multiply tool correctly" {
            # Appeler la fonction
            $result = Invoke-MCPTool -ToolName "multiply" -Parameters @{a = 4; b = 5 }

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be 20

            # Vérifier que Invoke-RestMethod a été appelé correctement
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools/multiply" -and
                $Method -eq "Post" -and
                $ContentType -eq "application/json" -and
                $Headers.Accept -eq "application/json"
            }
        }

        It "Should call the get_system_info tool correctly" {
            # Appeler la fonction
            $result = Invoke-MCPTool -ToolName "get_system_info" -Parameters @{}

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Not -BeNullOrEmpty
            $result.result.os | Should -Be "Windows"
            $result.result.os_version | Should -Be "10.0.19042"
            $result.result.python_version | Should -Be "3.9.7"
            $result.result.hostname | Should -Be "DESKTOP-1234567"
            $result.result.cpu_count | Should -Be 8

            # Vérifier que Invoke-RestMethod a été appelé correctement
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools/get_system_info" -and
                $Method -eq "Post" -and
                $ContentType -eq "application/json" -and
                $Headers.Accept -eq "application/json"
            }
        }

        It "Should handle errors correctly" {
            # Configurer le mock pour lever une exception
            Mock Invoke-RestMethod {
                throw "404 Not Found"
            } -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools/nonexistent" -and
                $Method -eq "Post" -and
                $ContentType -eq "application/json" -and
                $Headers.Accept -eq "application/json"
            }

            # Appeler la fonction et vérifier qu'elle lève une erreur
            { Invoke-MCPTool -ToolName "nonexistent" -Parameters @{} } | Should -Throw

            # Vérifier que Invoke-RestMethod a été appelé correctement
            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq "$script:serverUrl/tools/nonexistent" -and
                $Method -eq "Post" -and
                $ContentType -eq "application/json" -and
                $Headers.Accept -eq "application/json"
            }
        }
    }

    # Tests pour Add-MCPNumbers
    Context "Add-MCPNumbers" {
        # Mock pour Invoke-MCPTool
        BeforeEach {
            Mock Invoke-MCPTool {
                param($ToolName, $Parameters)

                # Vérifier l'outil appelé
                if ($ToolName -eq "add") {
                    return @{
                        result = $Parameters.a + $Parameters.b
                    }
                } else {
                    throw "Invalid tool name"
                }
            }
        }

        It "Should add two numbers correctly" {
            # Appeler la fonction
            $result = Add-MCPNumbers -A 2 -B 3

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be 5

            # Vérifier que Invoke-MCPTool a été appelé correctement
            Should -Invoke Invoke-MCPTool -Times 1 -ParameterFilter {
                $ToolName -eq "add" -and
                $Parameters.a -eq 2 -and
                $Parameters.b -eq 3
            }
        }
    }

    # Tests pour ConvertTo-MCPProduct
    Context "ConvertTo-MCPProduct" {
        # Mock pour Invoke-MCPTool
        BeforeEach {
            Mock Invoke-MCPTool {
                param($ToolName, $Parameters)

                # Vérifier l'outil appelé
                if ($ToolName -eq "multiply") {
                    return @{
                        result = $Parameters.a * $Parameters.b
                    }
                } else {
                    throw "Invalid tool name"
                }
            }
        }

        It "Should multiply two numbers correctly" {
            # Appeler la fonction
            $result = ConvertTo-MCPProduct -A 4 -B 5

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Be 20

            # Vérifier que Invoke-MCPTool a été appelé correctement
            Should -Invoke Invoke-MCPTool -Times 1 -ParameterFilter {
                $ToolName -eq "multiply" -and
                $Parameters.a -eq 4 -and
                $Parameters.b -eq 5
            }
        }
    }

    # Tests pour Get-MCPSystemInfo
    Context "Get-MCPSystemInfo" {
        # Mock pour Invoke-MCPTool
        BeforeEach {
            Mock Invoke-MCPTool {
                param($ToolName, $Parameters)

                # Vérifier l'outil appelé
                if ($ToolName -eq "get_system_info") {
                    return @{
                        result = @{
                            os             = "Windows"
                            os_version     = "10.0.19042"
                            python_version = "3.9.7"
                            hostname       = "DESKTOP-1234567"
                            cpu_count      = 8
                        }
                    }
                } else {
                    throw "Invalid tool name"
                }
            }
        }

        It "Should get system info correctly" {
            # Appeler la fonction
            $result = Get-MCPSystemInfo

            # Vérifier le résultat
            $result | Should -Not -BeNullOrEmpty
            $result.result | Should -Not -BeNullOrEmpty
            $result.result.os | Should -Be "Windows"
            $result.result.os_version | Should -Be "10.0.19042"
            $result.result.python_version | Should -Be "3.9.7"
            $result.result.hostname | Should -Be "DESKTOP-1234567"
            $result.result.cpu_count | Should -Be 8

            # Vérifier que Invoke-MCPTool a été appelé correctement
            Should -Invoke Invoke-MCPTool -Times 1 -ParameterFilter {
                $ToolName -eq "get_system_info" -and
                $Parameters.Count -eq 0
            }
        }
    }
}
