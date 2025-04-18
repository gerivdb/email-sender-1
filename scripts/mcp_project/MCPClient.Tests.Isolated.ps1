#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires isolés pour le module MCPClient.
.DESCRIPTION
    Ce script contient les tests unitaires isolés pour le module MCPClient qui interagit avec le serveur FastAPI.
    Ces tests utilisent des mocks pour éviter de se connecter à un serveur réel.
.EXAMPLE
    Invoke-Pester -Path .\MCPClient.Tests.Isolated.ps1
    Exécute les tests unitaires isolés pour le module MCPClient.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
#>

# Importer le module Pester s'il n'est pas déjà importé
if (-not (Get-Module -Name Pester)) {
    Import-Module -Name Pester -ErrorAction Stop
}

# Créer un module temporaire pour les tests
$moduleContent = @'
# Variables globales
$script:MCPServerUrl = "http://localhost:8000"

<#
.SYNOPSIS
    Initialise la connexion au serveur MCP.
.DESCRIPTION
    Cette fonction initialise la connexion au serveur MCP en définissant l'URL du serveur.
.PARAMETER ServerUrl
    L'URL du serveur MCP.
.EXAMPLE
    Initialize-MCPConnection -ServerUrl "http://localhost:8000"
    Initialise la connexion au serveur MCP à l'adresse http://localhost:8000.
#>
function Initialize-MCPConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServerUrl
    )

    $script:MCPServerUrl = $ServerUrl
    Write-Verbose "Connexion au serveur MCP initialisée à l'adresse $ServerUrl"
}

<#
.SYNOPSIS
    Récupère la liste des outils disponibles sur le serveur MCP.
.DESCRIPTION
    Cette fonction récupère la liste des outils disponibles sur le serveur MCP.
.EXAMPLE
    Get-MCPTools
    Récupère la liste des outils disponibles sur le serveur MCP.
#>
function Get-MCPTools {
    [CmdletBinding()]
    param ()

    try {
        $url = "$script:MCPServerUrl/tools"
        Write-Verbose "Récupération des outils depuis $url"

        $response = Invoke-RestMethod -Uri $url -Method Get -Headers @{
            "Accept" = "application/json"
        }

        return $response
    }
    catch {
        Write-Error "Erreur lors de la récupération des outils: $_"
    }
}

<#
.SYNOPSIS
    Appelle un outil sur le serveur MCP.
.DESCRIPTION
    Cette fonction appelle un outil sur le serveur MCP avec les paramètres spécifiés.
.PARAMETER ToolName
    Le nom de l'outil à appeler.
.PARAMETER Parameters
    Les paramètres à passer à l'outil, au format hashtable.
.EXAMPLE
    Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
    Appelle l'outil "add" avec les paramètres a=2 et b=3.
#>
function Invoke-MCPTool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    try {
        $url = "$script:MCPServerUrl/tools/$ToolName"
        Write-Verbose "Appel de l'outil $ToolName depuis $url avec les paramètres $($Parameters | ConvertTo-Json -Compress)"

        $body = $Parameters | ConvertTo-Json -Compress
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -Headers @{
            "Accept" = "application/json"
        }

        return $response
    }
    catch {
        Write-Error "Erreur lors de l'appel a l'outil ${ToolName}: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Additionne deux nombres via le serveur MCP.
.DESCRIPTION
    Cette fonction appelle l'outil "add" sur le serveur MCP pour additionner deux nombres.
.PARAMETER A
    Le premier nombre.
.PARAMETER B
    Le deuxième nombre.
.EXAMPLE
    Add-MCPNumbers -A 2 -B 3
    Additionne 2 et 3 via le serveur MCP.
#>
function Add-MCPNumbers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$A,

        [Parameter(Mandatory = $true)]
        [int]$B
    )

    return Invoke-MCPTool -ToolName "add" -Parameters @{
        a = $A
        b = $B
    }
}

<#
.SYNOPSIS
    Multiplie deux nombres via le serveur MCP.
.DESCRIPTION
    Cette fonction appelle l'outil "multiply" sur le serveur MCP pour multiplier deux nombres.
.PARAMETER A
    Le premier nombre.
.PARAMETER B
    Le deuxième nombre.
.EXAMPLE
    ConvertTo-MCPProduct -A 4 -B 5
    Multiplie 4 et 5 via le serveur MCP.
#>
function ConvertTo-MCPProduct {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$A,

        [Parameter(Mandatory = $true)]
        [int]$B
    )

    return Invoke-MCPTool -ToolName "multiply" -Parameters @{
        a = $A
        b = $B
    }
}

<#
.SYNOPSIS
    Récupère des informations sur le système via le serveur MCP.
.DESCRIPTION
    Cette fonction appelle l'outil "get_system_info" sur le serveur MCP pour récupérer des informations sur le système.
.EXAMPLE
    Get-MCPSystemInfo
    Récupère des informations sur le système via le serveur MCP.
#>
function Get-MCPSystemInfo {
    [CmdletBinding()]
    param ()

    return Invoke-MCPTool -ToolName "get_system_info" -Parameters @{}
}

# Exportation des fonctions
Export-ModuleMember -Function Initialize-MCPConnection, Get-MCPTools, Invoke-MCPTool, Add-MCPNumbers, ConvertTo-MCPProduct, Get-MCPSystemInfo
'@

# Créer un fichier temporaire pour le module
$tempDir = "$PSScriptRoot\temp"
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
}
$tempModulePath = Join-Path -Path $tempDir -ChildPath "MCPClient.psm1"
$moduleContent | Out-File -FilePath $tempModulePath -Encoding utf8

# Définir les tests
Describe "MCPClient Module Tests (Isolated)" {
    BeforeAll {
        # Importer le module temporaire
        Import-Module -Name $tempModulePath -Force

        # Initialiser la connexion au serveur MCP
        Initialize-MCPConnection -ServerUrl "http://localhost:8000"

        # Mock pour Invoke-RestMethod
        Mock Invoke-RestMethod {
            # Simuler la réponse pour Get-MCPTools
            @(
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

        # Mock pour Invoke-RestMethod pour l'outil add
        Mock Invoke-RestMethod {
            param($Uri, $Method, $Body, $ContentType, $Headers)

            $bodyObj = $Body | ConvertFrom-Json
            @{
                result = $bodyObj.a + $bodyObj.b
            }
        } -ParameterFilter {
            $Uri -eq "http://localhost:8000/tools/add" -and
            $Method -eq "Post"
        }

        # Mock pour Invoke-RestMethod pour l'outil multiply
        Mock Invoke-RestMethod {
            param($Uri, $Method, $Body, $ContentType, $Headers)

            $bodyObj = $Body | ConvertFrom-Json
            @{
                result = $bodyObj.a * $bodyObj.b
            }
        } -ParameterFilter {
            $Uri -eq "http://localhost:8000/tools/multiply" -and
            $Method -eq "Post"
        }

        # Mock pour Invoke-RestMethod pour l'outil get_system_info
        Mock Invoke-RestMethod {
            @{
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

        # Mock pour Invoke-RestMethod pour l'outil nonexistent
        Mock Invoke-RestMethod {
            throw "404 Not Found"
        } -ParameterFilter {
            $Uri -eq "http://localhost:8000/tools/nonexistent" -and
            $Method -eq "Post"
        }
    }

    AfterAll {
        # Supprimer le fichier temporaire
        if (Test-Path -Path $tempModulePath) {
            Remove-Item -Path $tempModulePath -Force
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
            # Appeler la fonction et vérifier qu'elle lève une erreur
            { Invoke-MCPTool -ToolName "nonexistent" -Parameters @{} } | Should -Throw

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
