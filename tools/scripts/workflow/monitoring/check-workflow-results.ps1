# Script pour verifier les resultats du workflow apres son execution

Write-Host "=== Verification des resultats du workflow ===" -ForegroundColor Cyan

# Verifier si n8n est en cours d'execution
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "✅ n8n est en cours d'execution ($($nodeProcesses.Count) processus node.exe detectes)" -ForegroundColor Green
} else {
    Write-Host "❌ n8n n'est pas en cours d'execution" -ForegroundColor Red
    Write-Host "Demarrez n8n en utilisant le script start-n8n.cmd ou en executant la commande npx n8n start"
    exit 1
}

# Verifier si les fichiers batch sont executables
$mcpStandardPath = "..\..\D"
$mcpNotionPath = "..\..\D"
$gatewayPath = "..\email\gateway.exe.cmd"

Write-Host "`n[1] Verification de l'executabilite des fichiers batch" -ForegroundColor Yellow

try {
    $mcpStandardOutput = & $mcpStandardPath 2>&1
    Write-Host "✅ Le fichier $mcpStandardPath est executable" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de l'execution de $mcpStandardPath : $_" -ForegroundColor Red
}

try {
    $mcpNotionOutput = & $mcpNotionPath 2>&1
    Write-Host "✅ Le fichier $mcpNotionPath est executable" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de l'execution de $mcpNotionPath : $_" -ForegroundColor Red
}

try {
    $gatewayOutput = & $gatewayPath help 2>&1
    Write-Host "✅ Le fichier $gatewayPath est executable" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de l'execution de $gatewayPath : $_" -ForegroundColor Red
}

# Verifier les variables d'environnement
Write-Host "`n[2] Verification des variables d'environnement" -ForegroundColor Yellow
$envVarUser = [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'User')
$envVarProcess = [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'Process')

Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE (User): $envVarUser"
Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE (Process): $envVarProcess"

if ($envVarUser -eq "true" -or $envVarProcess -eq "true") {
    Write-Host "✅ La variable d'environnement est correctement definie" -ForegroundColor Green
} else {
    Write-Host "❌ La variable d'environnement n'est pas definie correctement" -ForegroundColor Red
    Write-Host "   Solution: Executez la commande suivante pour definir la variable d'environnement:"
    Write-Host "   [Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'User')"
}

# Verifier les identifiants MCP
Write-Host "`n[3] Verification des identifiants MCP" -ForegroundColor Yellow
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

Write-Host "`n=== Verification terminee ===" -ForegroundColor Cyan
Write-Host "Si tous les elements sont marques comme ✅, les MCP devraient fonctionner correctement dans n8n."
Write-Host "Importez et executez le workflow de test pour verifier que les MCP fonctionnent correctement."
Write-Host "Si vous ne voyez plus de toasts d'erreur indiquant que les MCP n'ont pas demarre, cela signifie que le probleme est resolu."


