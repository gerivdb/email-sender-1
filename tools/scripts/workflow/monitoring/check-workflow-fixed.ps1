# Script simplifie pour verifier les resultats du workflow
# Version avec encodage corrige

Write-Host "=== Verification simplifiee des resultats du workflow ===" -ForegroundColor Cyan

# Verifier si n8n est en cours d'execution
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "[OK] n8n est en cours d'execution ($($nodeProcesses.Count) processus node.exe detectes)" -ForegroundColor Green
} else {
    Write-Host "[ERREUR] n8n n'est pas en cours d'execution" -ForegroundColor Red
    exit 1
}

# Verifier les variables d'environnement
Write-Host "`n[1] Verification des variables d'environnement" -ForegroundColor Yellow
$envVarUser = [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'User')
$envVarProcess = [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'Process')

Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE (User): $envVarUser"
Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE (Process): $envVarProcess"

if ($envVarUser -eq "true" -or $envVarProcess -eq "true") {
    Write-Host "[OK] La variable d'environnement est correctement definie" -ForegroundColor Green
} else {
    Write-Host "[ERREUR] La variable d'environnement n'est pas definie correctement" -ForegroundColor Red
}

# Verifier les identifiants MCP
Write-Host "`n[2] Verification des identifiants MCP" -ForegroundColor Yellow
$n8nDir = ".\.n8n"
$credentialsDbPath = "$n8nDir\credentials.db"

if (Test-Path $credentialsDbPath) {
    $credentialsDb = Get-Content $credentialsDbPath -Raw
    
    if ($credentialsDb -match "MCP Standard") {
        Write-Host "[OK] L'identifiant MCP Standard est configure" -ForegroundColor Green
    } else {
        Write-Host "[ERREUR] L'identifiant MCP Standard n'est pas configure" -ForegroundColor Red
    }
    
    if ($credentialsDb -match "MCP Notion") {
        Write-Host "[OK] L'identifiant MCP Notion est configure" -ForegroundColor Green
    } else {
        Write-Host "[ERREUR] L'identifiant MCP Notion n'est pas configure" -ForegroundColor Red
    }
    
    if ($credentialsDb -match "MCP Gateway") {
        Write-Host "[OK] L'identifiant MCP Gateway est configure" -ForegroundColor Green
    } else {
        Write-Host "[ERREUR] L'identifiant MCP Gateway n'est pas configure" -ForegroundColor Red
    }
} else {
    Write-Host "[ERREUR] Le fichier credentials.db n'existe pas" -ForegroundColor Red
}

Write-Host "`n=== Verification terminee ===" -ForegroundColor Cyan
Write-Host "Si tous les elements sont marques comme [OK], les MCP devraient fonctionner correctement dans n8n."
Write-Host "Importez et executez le workflow de test pour verifier que les MCP fonctionnent correctement."
Write-Host "Si vous ne voyez plus de toasts d'erreur indiquant que les MCP n'ont pas demarre, cela signifie que le probleme est resolu."
