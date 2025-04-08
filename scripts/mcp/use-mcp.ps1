# Script pour utiliser les MCP depuis le dossier mcp

# Definir les variables d'environnement
$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'Process')

# Fonction pour executer un MCP
function Execute-MCP {
    param (
        [Parameter(Mandatory=$true)]
        [string]$MCP,

        [Parameter(Mandatory=$false)]
        [string]$Args = ""
    )

    switch ($MCP) {
        "standard" {
            Write-Host "Execution du MCP Standard..." -ForegroundColor Cyan
            & "..\D" $Args
        }
        "notion" {
            Write-Host "Execution du MCP Notion..." -ForegroundColor Cyan
            & "..\D" $Args
        }
        "gateway" {
            Write-Host "Execution du MCP Gateway..." -ForegroundColor Cyan
            & "mcp\gateway.exe.cmd" $Args
        }
        "git-ingest" {
            Write-Host "Execution du MCP Git Ingest..." -ForegroundColor Cyan
            & "..\D" $Args
        }
        "bifrost" {
            Write-Host "Execution du MCP Bifrost..." -ForegroundColor Cyan
            & "..\D" $Args
        }
        default {
            Write-Host "MCP non reconnu : $MCP" -ForegroundColor Red
            Write-Host "MCPs disponibles : standard, notion, gateway, git-ingest, bifrost" -ForegroundColor Yellow
        }
    }
}

# Verifier les arguments
if ($args.Count -eq 0) {
    Write-Host "Usage : .\use-mcp.ps1 <mcp> [args]" -ForegroundColor Yellow
    Write-Host "MCPs disponibles : standard, notion, gateway, git-ingest, bifrost" -ForegroundColor Yellow
    exit
}

# Executer le MCP
$mcpName = $args[0]
$mcpArgs = $args[1..$args.Count] -join " "

Execute-MCP -MCP $mcpName -Args $mcpArgs


