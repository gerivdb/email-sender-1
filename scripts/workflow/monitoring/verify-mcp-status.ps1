# Script pour verifier l'etat des MCP dans n8n

Write-Host "=== Verification de l'etat des MCP dans n8n ===" -ForegroundColor Cyan

# Verifier si n8n est en cours d'execution
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "✅ n8n est en cours d'execution ($($nodeProcesses.Count) processus node.exe detectes)" -ForegroundColor Green
} else {
    Write-Host "❌ n8n n'est pas en cours d'execution" -ForegroundColor Red
    Write-Host "Demarrez n8n en utilisant le script start-n8n.cmd ou en executant la commande npx n8n start"
    exit 1
}

# Verifier si les fichiers batch existent
$mcpStandardPath = ".\mcp-standard.cmd"
$mcpNotionPath = ".\mcp-notion.cmd"
$gatewayPath = ".\gateway.exe.cmd"

if (Test-Path $mcpStandardPath) {
    Write-Host "✅ Le fichier $mcpStandardPath existe" -ForegroundColor Green
} else {
    Write-Host "❌ Le fichier $mcpStandardPath n'existe pas" -ForegroundColor Red
}

if (Test-Path $mcpNotionPath) {
    Write-Host "✅ Le fichier $mcpNotionPath existe" -ForegroundColor Green
} else {
    Write-Host "❌ Le fichier $mcpNotionPath n'existe pas" -ForegroundColor Red
}

if (Test-Path $gatewayPath) {
    Write-Host "✅ Le fichier $gatewayPath existe" -ForegroundColor Green
} else {
    Write-Host "❌ Le fichier $gatewayPath n'existe pas" -ForegroundColor Red
}

# Verifier si les identifiants MCP sont configures
$n8nDir = ".\.n8n"
$credentialsDbPath = "$n8nDir\credentials.db"

if (Test-Path $credentialsDbPath) {
    $credentialsDb = Get-Content $credentialsDbPath -Raw
    
    if ($credentialsDb -match "MCP Standard") {
        Write-Host "✅ L'identifiant MCP Standard est configure" -ForegroundColor Green
    } else {
        Write-Host "❌ L'identifiant MCP Standard n'est pas configure" -ForegroundColor Red
    }
    
    if ($credentialsDb -match "MCP Notion") {
        Write-Host "✅ L'identifiant MCP Notion est configure" -ForegroundColor Green
    } else {
        Write-Host "❌ L'identifiant MCP Notion n'est pas configure" -ForegroundColor Red
    }
    
    if ($credentialsDb -match "MCP Gateway") {
        Write-Host "✅ L'identifiant MCP Gateway est configure" -ForegroundColor Green
    } else {
        Write-Host "❌ L'identifiant MCP Gateway n'est pas configure" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Le fichier credentials.db n'existe pas" -ForegroundColor Red
    Write-Host "Les identifiants MCP ne sont pas configures"
}

# Verifier si la variable d'environnement est definie
$envVarUser = [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'User')
$envVarProcess = [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'Process')

if ($envVarUser -eq "true" -or $envVarProcess -eq "true") {
    Write-Host "✅ La variable d'environnement N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE est definie" -ForegroundColor Green
} else {
    Write-Host "❌ La variable d'environnement N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE n'est pas definie" -ForegroundColor Red
}

Write-Host "`n=== Verification terminee ===" -ForegroundColor Cyan
Write-Host "Si tous les elements sont marques comme ✅, les MCP devraient fonctionner correctement dans n8n."
Write-Host "Suivez les instructions du fichier TESTER_MCP_WORKFLOW.md pour tester les MCP dans n8n."

