#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©marre le gestionnaire de serveurs MCP ou un agent MCP.
.DESCRIPTION
    Ce script permet de dÃ©marrer le gestionnaire de serveurs MCP ou un agent MCP
    qui utilise la bibliothÃ¨que mcp-use pour interagir avec les serveurs MCP.
.PARAMETER Agent
    DÃ©marre un agent MCP au lieu du gestionnaire de serveurs.
.PARAMETER Query
    SpÃ©cifie la requÃªte Ã  exÃ©cuter par l'agent MCP.
.PARAMETER Force
    Force la recrÃ©ation de la configuration MCP mÃªme si elle existe dÃ©jÃ .
.EXAMPLE
    .\mcp-manager.ps1
    DÃ©marre le gestionnaire de serveurs MCP.
.EXAMPLE
    .\mcp-manager.ps1 -Agent
    DÃ©marre un agent MCP et demande Ã  l'utilisateur d'entrer une requÃªte.
.EXAMPLE
    .\mcp-manager.ps1 -Agent -Query "Trouve les meilleurs restaurants Ã  Paris"
    DÃ©marre un agent MCP et exÃ©cute la requÃªte spÃ©cifiÃ©e.
.NOTES
    Version: 1.1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
    Date de mise Ã  jour: 2025-04-20
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Agent,

    [Parameter(Mandatory = $false)]
    [string]$Query,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer le module MCPManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MCPManager.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module MCPManager introuvable Ã  $modulePath"
    exit 1
}

# DÃ©marrer le gestionnaire de serveurs MCP
$result = mcp-manager -Agent:$Agent -Query $Query -Force:$Force

# Sortir avec le code appropriÃ©
if ($result) {
    exit 0
} else {
    exit 1
}

