# Script pour simuler l'execution du workflow et verifier si les MCP fonctionnent correctement

Write-Host "=== Simulation de l'execution du workflow ===" -ForegroundColor Cyan

# Verifier si n8n est en cours d'execution
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "[OK] n8n est en cours d'execution ($($nodeProcesses.Count) processus node.exe detectes)" -ForegroundColor Green
} else {
    Write-Host "[ERREUR] n8n n'est pas en cours d'execution" -ForegroundColor Red
    exit 1
}

# Tester le MCP Standard
Write-Host "`n[1] Test du MCP Standard" -ForegroundColor Yellow
try {
    Write-Host "Execution de mcp-standard.cmd..."
    $output = cmd /c "echo { `"type`": `"list_tools`" } | mcp-standard.cmd" 2>&1
    if ($output -match "error") {
        Write-Host "[ERREUR] Le MCP Standard a rencontre une erreur : $output" -ForegroundColor Red
    } else {
        Write-Host "[OK] Le MCP Standard a repondu" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERREUR] Erreur lors de l'execution du MCP Standard : $_" -ForegroundColor Red
}

# Tester le MCP Gateway
Write-Host "`n[2] Test du MCP Gateway" -ForegroundColor Yellow
try {
    Write-Host "Execution de gateway.exe.cmd help..."
    $output = cmd /c "gateway.exe.cmd help" 2>&1
    if ($output -match "error") {
        Write-Host "[ERREUR] Le MCP Gateway a rencontre une erreur : $output" -ForegroundColor Red
    } else {
        Write-Host "[OK] Le MCP Gateway a repondu" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERREUR] Erreur lors de l'execution du MCP Gateway : $_" -ForegroundColor Red
}

# Verifier les identifiants MCP
Write-Host "`n[3] Verification des identifiants MCP" -ForegroundColor Yellow
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

Write-Host "`n=== Simulation terminee ===" -ForegroundColor Cyan
Write-Host "Si tous les elements sont marques comme [OK], les MCP devraient fonctionner correctement dans n8n."
Write-Host "Importez et executez le workflow de test dans l'interface web de n8n pour verifier que les MCP fonctionnent correctement."
Write-Host "Si vous ne voyez plus de toasts d'erreur indiquant que les MCP n'ont pas demarre, cela signifie que le probleme est resolu."
