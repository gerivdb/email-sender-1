<#
.SYNOPSIS
    Script pour configurer les identifiants MCP dans n8n.

.DESCRIPTION
    Ce script configure les identifiants MCP dans n8n en utilisant le module McpN8nIntegration.ps1.
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

# Configurer les identifiants MCP dans n8n
Write-Host "Configuration des identifiants MCP dans n8n..." -ForegroundColor Yellow
$Result = & $ModuleFile -N8nUrl $N8nUrl -ApiKey $ApiKey -McpPath $McpPath -Action Configure

if ($Result) {
    Write-Host "Configuration des identifiants MCP réussie." -ForegroundColor Green
}
else {
    Write-Host "Erreur lors de la configuration des identifiants MCP." -ForegroundColor Red
}
