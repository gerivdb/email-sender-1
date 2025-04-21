<#
.SYNOPSIS
    Script pour synchroniser les workflows avec les serveurs MCP.

.DESCRIPTION
    Ce script synchronise les workflows avec les serveurs MCP en utilisant le module McpN8nIntegration.ps1.
#>

#Requires -Version 5.1

# Paramètres
param (
    [string]$N8nUrl = "http://localhost:5678",
    [string]$ApiKey = "",
    [string]$McpPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp"
)

# Importer le module
$ModuleFile = Join-Path -Path $PSScriptRoot -ChildPath "McpN8nIntegration.ps1"
if (-not (Test-Path -Path $ModuleFile)) {
    Write-Error "Le fichier module McpN8nIntegration.ps1 n'existe pas."
    exit 1
}

# Synchroniser les workflows avec les serveurs MCP
Write-Host "Synchronisation des workflows avec les serveurs MCP..." -ForegroundColor Yellow
$Result = & $ModuleFile -N8nUrl $N8nUrl -ApiKey $ApiKey -McpPath $McpPath -Action Sync

if ($Result) {
    Write-Host "Synchronisation des workflows réussie." -ForegroundColor Green
}
else {
    Write-Host "Erreur lors de la synchronisation des workflows." -ForegroundColor Red
}
