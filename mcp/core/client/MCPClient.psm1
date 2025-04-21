#Requires -Version 5.1
<#
.SYNOPSIS
    Module PowerShell pour interagir avec un serveur MCP.
.DESCRIPTION
    Ce module fournit des fonctions pour interagir avec un serveur MCP via le transport SSE.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
#>

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
    } catch {
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
    } catch {
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
