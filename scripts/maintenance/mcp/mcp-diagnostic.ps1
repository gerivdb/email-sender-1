# Script de diagnostic pour les MCP dans n8n

Write-Host "=== Diagnostic des MCP pour n8n ===" -ForegroundColor Cyan

# Verifier les variables d'environnement
Write-Host "`n[1] Verification des variables d'environnement" -ForegroundColor Yellow
$envVarUser = [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'User')
$envVarProcess = [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'Process')
$envVarMachine = [Environment]::GetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'Machine')

Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE (User): $envVarUser"
Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE (Process): $envVarProcess"
Write-Host "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE (Machine): $envVarMachine"

if ($envVarUser -eq "true" -or $envVarProcess -eq "true" -or $envVarMachine -eq "true") {
    Write-Host "✅ La variable d'environnement est correctement definie" -ForegroundColor Green
} else {
    Write-Host "❌ La variable d'environnement n'est pas definie correctement" -ForegroundColor Red
    Write-Host "   Solution: Executez la commande suivante pour definir la variable d'environnement:"
    Write-Host "   [Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'User')"
}

# Verifier le fichier .env
Write-Host "`n[2] Verification du fichier .env" -ForegroundColor Yellow
if (Test-Path ".env") {
    $envContent = Get-Content ".env"
    $hasEnvVar = $envContent | Where-Object { $_ -match "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true" }
    
    if ($hasEnvVar) {
        Write-Host "✅ La variable est correctement definie dans le fichier .env" -ForegroundColor Green
    } else {
        Write-Host "❌ La variable n'est pas definie dans le fichier .env" -ForegroundColor Red
        Write-Host "   Solution: Ajoutez la ligne suivante au fichier .env:"
        Write-Host "   N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
    }
} else {
    Write-Host "❌ Le fichier .env n'existe pas" -ForegroundColor Red
    Write-Host "   Solution: Creez un fichier .env avec le contenu suivant:"
    Write-Host "   N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
}

# Verifier les packages npm
Write-Host "`n[3] Verification des packages npm" -ForegroundColor Yellow
$npmList = npm list --depth=0
$hasMcpPackage = $npmList | Where-Object { $_ -match "n8n-nodes-mcp" }
$hasNotionPackage = $npmList | Where-Object { $_ -match "@suekou/mcp-notion-server" }

if ($hasMcpPackage) {
    Write-Host "✅ Le package n8n-nodes-mcp est installe" -ForegroundColor Green
} else {
    Write-Host "❌ Le package n8n-nodes-mcp n'est pas installe" -ForegroundColor Red
    Write-Host "   Solution: Installez le package avec la commande:"
    Write-Host "   npm install n8n-nodes-mcp"
}

if ($hasNotionPackage) {
    Write-Host "✅ Le package @suekou/mcp-notion-server est installe" -ForegroundColor Green
} else {
    Write-Host "❌ Le package @suekou/mcp-notion-server n'est pas installe" -ForegroundColor Red
    Write-Host "   Solution: Installez le package avec la commande:"
    Write-Host "   npm install @suekou/mcp-notion-server"
}

# Verifier le simulateur Gateway
Write-Host "`n[4] Verification du simulateur Gateway" -ForegroundColor Yellow
if (Test-Path "gateway.exe.cmd") {
    Write-Host "✅ Le fichier gateway.exe.cmd existe" -ForegroundColor Green
    
    # Tester l'execution
    try {
        $gatewayOutput = & .\gateway.exe.cmd help 2>&1
        Write-Host "✅ Le script gateway.exe.cmd s'execute correctement" -ForegroundColor Green
    } catch {
        Write-Host "❌ Erreur lors de l'execution de gateway.exe.cmd: $_" -ForegroundColor Red
        Write-Host "   Solution: Verifiez le contenu du fichier et les permissions d'execution"
    }
} else {
    Write-Host "❌ Le fichier gateway.exe.cmd n'existe pas" -ForegroundColor Red
    Write-Host "   Solution: Creez le fichier gateway.exe.cmd avec le contenu suivant:"
    Write-Host "   @echo off"
    Write-Host "   powershell -ExecutionPolicy Bypass -File `"%~dp0gateway.ps1`" %*"
}

if (Test-Path "gateway.ps1") {
    Write-Host "✅ Le fichier gateway.ps1 existe" -ForegroundColor Green
} else {
    Write-Host "❌ Le fichier gateway.ps1 n'existe pas" -ForegroundColor Red
    Write-Host "   Solution: Creez le fichier gateway.ps1 avec le script PowerShell approprie"
}

if (Test-Path "gateway.yaml") {
    Write-Host "✅ Le fichier gateway.yaml existe" -ForegroundColor Green
} else {
    Write-Host "❌ Le fichier gateway.yaml n'existe pas" -ForegroundColor Red
    Write-Host "   Solution: Creez le fichier gateway.yaml avec la configuration appropriee"
}

# Verifier la politique d'execution PowerShell
Write-Host "`n[5] Verification de la politique d'execution PowerShell" -ForegroundColor Yellow
$executionPolicy = Get-ExecutionPolicy
Write-Host "Politique d'execution PowerShell actuelle: $executionPolicy"

if ($executionPolicy -eq "Restricted") {
    Write-Host "❌ La politique d'execution PowerShell est restrictive" -ForegroundColor Red
    Write-Host "   Solution: Modifiez temporairement la politique d'execution avec la commande:"
    Write-Host "   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass"
} else {
    Write-Host "✅ La politique d'execution PowerShell permet l'execution de scripts" -ForegroundColor Green
}

# Recommandations finales
Write-Host "`n[6] Recommandations finales" -ForegroundColor Yellow
Write-Host "1. Redemarrez n8n apres avoir effectue les corrections necessaires"
Write-Host "2. Verifiez que les chemins dans la configuration des identifiants MCP sont corrects et utilisent des chemins absolus"
Write-Host "3. Assurez-vous que n8n a les permissions necessaires pour executer les scripts et acceder aux fichiers"
Write-Host "4. Consultez les logs de n8n pour voir les erreurs eventuelles"

Write-Host "`n=== Fin du diagnostic ===" -ForegroundColor Cyan

