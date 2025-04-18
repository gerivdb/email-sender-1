#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module MCPClient avec InModuleScope.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module MCPClient qui interagit avec le serveur FastAPI.
    Ces tests utilisent InModuleScope pour accéder aux fonctions internes du module.
.EXAMPLE
    Invoke-Pester -Path .\MCPClient.Tests.InModuleScope.ps1
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

# Importer le module MCPClient
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "MCPClient.psm1"
Import-Module -Name $modulePath -Force

# Définir les tests
Describe "MCPClient Module Tests" {
    # Utiliser InModuleScope pour accéder aux variables et fonctions internes du module
    InModuleScope "MCPClient" {
        BeforeAll {
            # Initialiser la connexion au serveur MCP
            Initialize-MCPConnection -ServerUrl "http://localhost:8000"

            # Mock pour Invoke-RestMethod - Get-MCPTools
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
                $Uri -eq "http://localhost:8000/tools" -and
                $Method -eq "Get"
            }

            # Mock pour Invoke-RestMethod - Add
            Mock Invoke-RestMethod {
                param($Uri, $Method, $Body, $ContentType, $Headers)

                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    result = $bodyObj.a + $bodyObj.b
                }
            } -ParameterFilter {
                $Uri -eq "http://localhost:8000/tools/add" -and
                $Method -eq "Post"
            }

            # Mock pour Invoke-RestMethod - Multiply
            Mock Invoke-RestMethod {
                param($Uri, $Method, $Body, $ContentType, $Headers)

                $bodyObj = $Body | ConvertFrom-Json
                return @{
                    result = $bodyObj.a * $bodyObj.b
                }
            } -ParameterFilter {
                $Uri -eq "http://localhost:8000/tools/multiply" -and
                $Method -eq "Post"
            }

            # Mock pour Invoke-RestMethod - Get System Info
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
                $Uri -eq "http://localhost:8000/tools/get_system_info" -and
                $Method -eq "Post"
            }

            # Mock pour Invoke-RestMethod - Nonexistent Tool
            Mock Invoke-RestMethod {
                throw "404 Not Found"
            } -ParameterFilter {
                $Uri -eq "http://localhost:8000/tools/nonexistent" -and
                $Method -eq "Post"
            }
        }

        # Tests pour Initialize-MCPConnection
        Context "Initialize-MCPConnection" {
            It "Should set the server URL correctly" {
                # Appeler la fonction
                Initialize-MCPConnection -ServerUrl "http://example.com"

                # Vérifier que la variable globale a été mise à jour
                $script:MCPServerUrl | Should -Be "http://example.com"

                # Réinitialiser la variable globale
                Initialize-MCPConnection -ServerUrl "http://localhost:8000"
            }
        }

        # Tests pour Get-MCPTools
        Context "Get-MCPTools" {
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
                    $Uri -eq "http://localhost:8000/tools" -and
                    $Method -eq "Get" -and
                    $Headers.Accept -eq "application/json"
                }
            }
        }

        # Tests pour Invoke-MCPTool
        Context "Invoke-MCPTool" {
            It "Should call the add tool correctly" {
                # Appeler la fonction
                $result = Invoke-MCPTool -ToolName "add" -Parameters @{a = 2; b = 3 }

                # Vérifier le résultat
                $result | Should -Not -BeNullOrEmpty
                $result.result | Should -Be 5

                # Vérifier que Invoke-RestMethod a été appelé correctement
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Uri -eq "http://localhost:8000/tools/add" -and
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
                    $Uri -eq "http://localhost:8000/tools/multiply" -and
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
                    $Uri -eq "http://localhost:8000/tools/get_system_info" -and
                    $Method -eq "Post" -and
                    $ContentType -eq "application/json" -and
                    $Headers.Accept -eq "application/json"
                }
            }

            It "Should handle errors correctly" {
                # Appeler la fonction et vérifier qu'elle écrit une erreur
                Mock Write-Error { } -Verifiable

                # Appeler la fonction
                Invoke-MCPTool -ToolName "nonexistent" -Parameters @{}

                # Vérifier que Write-Error a été appelé
                Should -Invoke Write-Error -Times 1

                # Vérifier que Invoke-RestMethod a été appelé correctement
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Uri -eq "http://localhost:8000/tools/nonexistent" -and
                    $Method -eq "Post" -and
                    $ContentType -eq "application/json" -and
                    $Headers.Accept -eq "application/json"
                }
            }
        }

        # Tests pour Add-MCPNumbers
        Context "Add-MCPNumbers" {
            It "Should add two numbers correctly" {
                # Appeler la fonction
                $result = Add-MCPNumbers -A 2 -B 3

                # Vérifier le résultat
                $result | Should -Not -BeNullOrEmpty
                $result.result | Should -Be 5

                # Vérifier que Invoke-MCPTool a été appelé correctement
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Uri -eq "http://localhost:8000/tools/add" -and
                    $Method -eq "Post"
                }
            }
        }

        # Tests pour ConvertTo-MCPProduct
        Context "ConvertTo-MCPProduct" {
            It "Should multiply two numbers correctly" {
                # Appeler la fonction
                $result = ConvertTo-MCPProduct -A 4 -B 5

                # Vérifier le résultat
                $result | Should -Not -BeNullOrEmpty
                $result.result | Should -Be 20

                # Vérifier que Invoke-MCPTool a été appelé correctement
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Uri -eq "http://localhost:8000/tools/multiply" -and
                    $Method -eq "Post"
                }
            }
        }

        # Tests pour Get-MCPSystemInfo
        Context "Get-MCPSystemInfo" {
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
                Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                    $Uri -eq "http://localhost:8000/tools/get_system_info" -and
                    $Method -eq "Post"
                }
            }
        }
    }
}
