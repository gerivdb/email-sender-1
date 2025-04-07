# Script de correction pour les MCP dans n8n

Write-Host "=== Correction des problemes MCP pour n8n ===" -ForegroundColor Cyan

# 1. Definir la variable d'environnement a tous les niveaux
Write-Host "`n[1] Definition des variables d'environnement" -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'User')
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'Process')
Write-Host "âœ… Variables d'environnement definies" -ForegroundColor Green

# 2. Mettre a jour le fichier .env
Write-Host "`n[2] Mise a jour du fichier .env" -ForegroundColor Yellow
$envPath = ".env"
$envContent = @"
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
OPENROUTER_API_KEY=sk-or-v1-...
"@

Set-Content -Path $envPath -Value $envContent
Write-Host "âœ… Fichier .env mis a jour" -ForegroundColor Green

# 3. Creer un fichier batch pour le MCP standard
Write-Host "`n[3] Creation d'un fichier batch pour le MCP standard" -ForegroundColor Yellow
$mcpBatchPath = "mcp-standard.cmd"
$mcpBatchContent = @"
@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
node ./node_modules/n8n-nodes-mcp/dist/nodes/McpClient/McpClient.node.js %*
"@

Set-Content -Path $mcpBatchPath -Value $mcpBatchContent
Write-Host "âœ… Fichier mcp-standard.cmd cree" -ForegroundColor Green

# 4. Creer un fichier batch pour le MCP Notion
Write-Host "`n[4] Creation d'un fichier batch pour le MCP Notion" -ForegroundColor Yellow
$mcpNotionBatchPath = "mcp-notion.cmd"
$mcpNotionBatchContent = @"
@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
set NOTION_API_TOKEN=secret_...
npx -y @suekou/mcp-notion-server %*
"@

Set-Content -Path $mcpNotionBatchPath -Value $mcpNotionBatchContent
Write-Host "âœ… Fichier mcp-notion.cmd cree" -ForegroundColor Green

# 5. Mettre a jour le fichier gateway.exe.cmd
Write-Host "`n[5] Mise a jour du fichier gateway.exe.cmd" -ForegroundColor Yellow
$gatewayBatchPath = "gateway.exe.cmd"
$gatewayBatchContent = @"
@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
powershell -ExecutionPolicy Bypass -File "%~dp0gateway.ps1" %*
"@

Set-Content -Path $gatewayBatchPath -Value $gatewayBatchContent
Write-Host "âœ… Fichier gateway.exe.cmd mis a jour" -ForegroundColor Green

# 6. Creer un fichier de configuration pour n8n
Write-Host "`n[6] Creation d'un fichier de configuration pour n8n" -ForegroundColor Yellow
$n8nConfigPath = ".n8n/config"
if (-not (Test-Path ".n8n")) {
    New-Item -ItemType Directory -Path ".n8n" | Out-Null
}

$n8nConfigContent = @"
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
"@

Set-Content -Path $n8nConfigPath -Value $n8nConfigContent
Write-Host "âœ… Fichier de configuration n8n cree" -ForegroundColor Green

# 7. Creer un guide de configuration des identifiants MCP dans n8n
Write-Host "`n[7] Creation d'un guide de configuration mis a jour" -ForegroundColor Yellow
$guidePath = "CONFIGURATION_MCP_MISE_A_JOUR.md"
$guideContent = @"
# Configuration mise a jour des MCP dans n8n

## Probleme des toasts d'erreur au demarrage

Si vous voyez des toasts d'erreur indiquant que les MCP n'ont pas demarre, suivez ces instructions pour resoudre le probleme.

## 1. MCP Standard (n8n-nodes-mcp)

1. Ouvrez n8n et accedez a "Credentials"
2. Creez un nouvel identifiant "MCP Client (STDIO) API"
3. Configurez-le comme suit :
   - **Credential Name**: MCP Standard
   - **Command**: $((Resolve-Path "mcp-standard.cmd").Path)
   - **Arguments**: (laissez vide)
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true,OPENROUTER_API_KEY=sk-or-v1-...

## 2. MCP Notion Server

1. Ouvrez n8n et accedez a "Credentials"
2. Creez un nouvel identifiant "MCP Client (STDIO) API"
3. Configurez-le comme suit :
   - **Credential Name**: MCP Notion
   - **Command**: $((Resolve-Path "mcp-notion.cmd").Path)
   - **Arguments**: (laissez vide)
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true,NOTION_API_TOKEN=secret_...

## 3. MCP Gateway

1. Ouvrez n8n et accedez a "Credentials"
2. Creez un nouvel identifiant "MCP Client (STDIO) API"
3. Configurez-le comme suit :
   - **Credential Name**: MCP Gateway
   - **Command**: $((Resolve-Path "gateway.exe.cmd").Path)
   - **Arguments**: start --config "$((Resolve-Path "gateway.yaml").Path)" mcp-stdio
   - **Environments**: N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

## Important

- Utilisez des chemins absolus pour tous les fichiers
- Redemarrez n8n apres avoir configure les identifiants
- Verifiez les logs de n8n pour voir les erreurs eventuelles
"@

Set-Content -Path $guidePath -Value $guideContent
Write-Host "âœ… Guide de configuration mis a jour cree: $guidePath" -ForegroundColor Green

Write-Host "`n=== Corrections terminees ===" -ForegroundColor Cyan
Write-Host "Veuillez suivre les instructions dans le fichier $guidePath pour configurer les identifiants MCP dans n8n."
Write-Host "Redemarrez n8n apres avoir effectue ces modifications."

