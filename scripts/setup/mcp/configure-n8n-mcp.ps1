# Script pour configurer automatiquement les identifiants MCP dans n8n

Write-Host "=== Configuration automatique des identifiants MCP dans n8n ===" -ForegroundColor Cyan

# Verifier si n8n est installe
$n8nVersion = npx n8n --version 2>$null
if (-not $n8nVersion) {
    Write-Host "âŒ n8n n'est pas installe ou n'est pas accessible via npx" -ForegroundColor Red
    Write-Host "Veuillez installer n8n ou verifier votre installation"
    exit 1
}

Write-Host "âœ… n8n version $n8nVersion detectee" -ForegroundColor Green

# Verifier si les fichiers batch existent
$mcpStandardPath = ".\mcp-standard.cmd"
$mcpNotionPath = ".\mcp-notion.cmd"
$gatewayPath = ".\gateway.exe.cmd"

if (-not (Test-Path $mcpStandardPath)) {
    Write-Host "âŒ Le fichier $mcpStandardPath n'existe pas" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $mcpNotionPath)) {
    Write-Host "âŒ Le fichier $mcpNotionPath n'existe pas" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $gatewayPath)) {
    Write-Host "âŒ Le fichier $gatewayPath n'existe pas" -ForegroundColor Red
    exit 1
}

Write-Host "âœ… Tous les fichiers batch necessaires existent" -ForegroundColor Green

# Definir les variables d'environnement
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'User')
[Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'Process')

Write-Host "âœ… Variables d'environnement definies" -ForegroundColor Green

# Creer le repertoire .n8n s'il n'existe pas
$n8nDir = ".\.n8n"
if (-not (Test-Path $n8nDir)) {
    New-Item -ItemType Directory -Path $n8nDir | Out-Null
    Write-Host "âœ… Repertoire .n8n cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Repertoire .n8n existe deja" -ForegroundColor Green
}

# Creer le fichier de configuration n8n
$n8nConfigPath = "$n8nDir\config"
$n8nConfigContent = @"
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
"@

Set-Content -Path $n8nConfigPath -Value $n8nConfigContent
Write-Host "âœ… Fichier de configuration n8n cree" -ForegroundColor Green

# Creer le repertoire .n8n/credentials s'il n'existe pas
$credentialsDir = "$n8nDir\credentials"
if (-not (Test-Path $credentialsDir)) {
    New-Item -ItemType Directory -Path $credentialsDir | Out-Null
    Write-Host "âœ… Repertoire .n8n/credentials cree" -ForegroundColor Green
} else {
    Write-Host "âœ… Repertoire .n8n/credentials existe deja" -ForegroundColor Green
}

# Generer des identifiants uniques
$mcpStandardId = [guid]::NewGuid().ToString("N")
$mcpNotionId = [guid]::NewGuid().ToString("N")
$mcpGatewayId = [guid]::NewGuid().ToString("N")

# Creer les fichiers d'identifiants
$mcpStandardCredPath = "$credentialsDir\$mcpStandardId.json"
$mcpStandardCredContent = @"
{
  "name": "MCP Standard",
  "type": "mcpClientApi",
  "data": {
    "command": "$(Resolve-Path $mcpStandardPath)",
    "args": "",
    "environments": "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true,OPENROUTER_API_KEY=sk-or-v1-..."
  }
}
"@

$mcpNotionCredPath = "$credentialsDir\$mcpNotionId.json"
$mcpNotionCredContent = @"
{
  "name": "MCP Notion",
  "type": "mcpClientApi",
  "data": {
    "command": "$(Resolve-Path $mcpNotionPath)",
    "args": "",
    "environments": "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true,NOTION_API_TOKEN=secret_..."
  }
}
"@

$mcpGatewayCredPath = "$credentialsDir\$mcpGatewayId.json"
$mcpGatewayCredContent = @"
{
  "name": "MCP Gateway",
  "type": "mcpClientApi",
  "data": {
    "command": "$(Resolve-Path $gatewayPath)",
    "args": "start --config \"$(Resolve-Path "gateway.yaml")\" mcp-stdio",
    "environments": "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
  }
}
"@

Set-Content -Path $mcpStandardCredPath -Value $mcpStandardCredContent
Set-Content -Path $mcpNotionCredPath -Value $mcpNotionCredContent
Set-Content -Path $mcpGatewayCredPath -Value $mcpGatewayCredContent

Write-Host "âœ… Fichiers d'identifiants crees" -ForegroundColor Green

# Creer le fichier credentials.db
$credentialsDbPath = "$n8nDir\credentials.db"
$credentialsDbContent = @"
{"$mcpStandardId":{"name":"MCP Standard","type":"mcpClientApi","nodesAccess":[{"nodeType":"n8n-nodes-base.mcpClient"}]},"$mcpNotionId":{"name":"MCP Notion","type":"mcpClientApi","nodesAccess":[{"nodeType":"n8n-nodes-base.mcpClient"}]},"$mcpGatewayId":{"name":"MCP Gateway","type":"mcpClientApi","nodesAccess":[{"nodeType":"n8n-nodes-base.mcpClient"}]}}
"@

Set-Content -Path $credentialsDbPath -Value $credentialsDbContent
Write-Host "âœ… Fichier credentials.db cree" -ForegroundColor Green

Write-Host "`n=== Configuration terminee ===" -ForegroundColor Cyan
Write-Host "Les identifiants MCP ont ete configures automatiquement dans n8n."
Write-Host "Redemarrez n8n pour appliquer les changements."
Write-Host "Vous pouvez demarrer n8n en utilisant le script start-n8n.cmd ou en executant la commande npx n8n start."

