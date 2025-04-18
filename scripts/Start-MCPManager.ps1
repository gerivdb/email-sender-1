#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre le gestionnaire de serveurs MCP ou un agent MCP.
.DESCRIPTION
    Ce script permet de démarrer le gestionnaire de serveurs MCP ou un agent MCP
    qui utilise la bibliothèque mcp-use pour interagir avec les serveurs MCP.
.PARAMETER Agent
    Démarre un agent MCP au lieu du gestionnaire de serveurs.
.PARAMETER Query
    Spécifie la requête à exécuter par l'agent MCP.
.PARAMETER Force
    Force la recréation de la configuration MCP même si elle existe déjà.
.EXAMPLE
    .\Start-MCPManager.ps1
    Démarre le gestionnaire de serveurs MCP.
.EXAMPLE
    .\Start-MCPManager.ps1 -Agent
    Démarre un agent MCP et demande à l'utilisateur d'entrer une requête.
.EXAMPLE
    .\Start-MCPManager.ps1 -Agent -Query "Trouve les meilleurs restaurants à Paris"
    Démarre un agent MCP et exécute la requête spécifiée.
.NOTES
    Version: 1.1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
    Date de mise à jour: 2025-04-20
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
    Write-Error "Module MCPManager introuvable à $modulePath"
    exit 1
}

# Démarrer le gestionnaire de serveurs MCP
$result = Start-MCPManager -Agent:$Agent -Query $Query -Force:$Force

# Sortir avec le code approprié
if ($result) {
    exit 0
} else {
    exit 1
}
