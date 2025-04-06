# Script pour configurer le MCP GitHub dans n8n

Write-Host "=== Configuration du MCP GitHub dans n8n ===" -ForegroundColor Cyan

# Vérifier si n8n est installé
$n8nVersion = npx n8n --version 2>$null
if (-not $n8nVersion) {
    Write-Host "❌ n8n n'est pas installé ou n'est pas accessible via npx" -ForegroundColor Red
    Write-Host "Veuillez installer n8n ou vérifier votre installation"
    exit 1
}

Write-Host "✅ n8n version $n8nVersion détectée" -ForegroundColor Green

# Créer le fichier batch pour le MCP GitHub s'il n'existe pas déjà
$mcpGithubPath = ".\src\mcp\batch\mcp-github.cmd"
$mcpGithubDir = Split-Path -Parent $mcpGithubPath

if (-not (Test-Path $mcpGithubDir)) {
    New-Item -ItemType Directory -Path $mcpGithubDir -Force | Out-Null
    Write-Host "✅ Répertoire $mcpGithubDir créé" -ForegroundColor Green
}

if (-not (Test-Path $mcpGithubPath)) {
    $mcpGithubContent = @"
@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du MCP GitHub...

:: Vérifier si un token GitHub est configuré
if "%GITHUB_TOKEN%"=="" (
    :: Vérifier si un fichier .env existe
    if exist "%~dp0..\..\..\\.env" (
        for /f "tokens=2 delims==" %%a in ('findstr /C:"GITHUB_TOKEN" "%~dp0..\..\..\\.env"') do set GITHUB_TOKEN=%%a
        if not "%GITHUB_TOKEN%"=="" (
            echo Token GitHub trouvé dans le fichier .env
        )
    )
    
    :: Si toujours pas de token, informer l'utilisateur
    if "%GITHUB_TOKEN%"=="" (
        echo Aucun token GitHub trouvé. Le serveur fonctionnera en mode anonyme avec des limites de taux plus strictes.
    )
) else (
    echo Token GitHub configuré
)

:: Lancement du serveur MCP GitHub
mcp-server-github
"@
    Set-Content -Path $mcpGithubPath -Value $mcpGithubContent
    Write-Host "✅ Fichier $mcpGithubPath créé" -ForegroundColor Green
} else {
    Write-Host "✅ Fichier $mcpGithubPath existe déjà" -ForegroundColor Green
}

# Déterminer le répertoire .n8n
$n8nDir = "$env:APPDATA\.n8n"
if (-not (Test-Path $n8nDir)) {
    New-Item -ItemType Directory -Path $n8nDir | Out-Null
    Write-Host "✅ Répertoire .n8n créé" -ForegroundColor Green
} else {
    Write-Host "✅ Répertoire .n8n existe déjà" -ForegroundColor Green
}

# Créer le répertoire .n8n/credentials s'il n'existe pas
$credentialsDir = "$n8nDir\credentials"
if (-not (Test-Path $credentialsDir)) {
    New-Item -ItemType Directory -Path $credentialsDir | Out-Null
    Write-Host "✅ Répertoire .n8n/credentials créé" -ForegroundColor Green
} else {
    Write-Host "✅ Répertoire .n8n/credentials existe déjà" -ForegroundColor Green
}

# Générer un identifiant unique
$mcpGithubId = [guid]::NewGuid().ToString("N")

# Créer le fichier d'identifiants
$mcpGithubCredPath = "$credentialsDir\$mcpGithubId.json"
$mcpGithubCredContent = @"
{
  "name": "MCP GitHub",
  "type": "mcpClientApi",
  "data": {
    "command": "$(Resolve-Path $mcpGithubPath)",
    "args": "",
    "environments": "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"
  }
}
"@

Set-Content -Path $mcpGithubCredPath -Value $mcpGithubCredContent
Write-Host "✅ Fichier d'identifiants MCP GitHub créé" -ForegroundColor Green

# Mettre à jour le fichier credentials.db
$credentialsDbPath = "$n8nDir\credentials.db"
if (Test-Path $credentialsDbPath) {
    $credentialsDb = Get-Content -Path $credentialsDbPath -Raw | ConvertFrom-Json -AsHashtable
    $credentialsDb[$mcpGithubId] = @{
        "name" = "MCP GitHub"
        "type" = "mcpClientApi"
        "nodesAccess" = @(
            @{
                "nodeType" = "n8n-nodes-base.mcpClient"
            }
        )
    }
    $credentialsDbContent = $credentialsDb | ConvertTo-Json -Compress
    Set-Content -Path $credentialsDbPath -Value $credentialsDbContent
    Write-Host "✅ Fichier credentials.db mis à jour" -ForegroundColor Green
} else {
    $credentialsDbContent = @"
{"$mcpGithubId":{"name":"MCP GitHub","type":"mcpClientApi","nodesAccess":[{"nodeType":"n8n-nodes-base.mcpClient"}]}}
"@
    Set-Content -Path $credentialsDbPath -Value $credentialsDbContent
    Write-Host "✅ Fichier credentials.db créé" -ForegroundColor Green
}

Write-Host "`n✅ Configuration du MCP GitHub terminée" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le MCP GitHub dans vos workflows n8n" -ForegroundColor Cyan
Write-Host "Nom de l'identifiant : MCP GitHub" -ForegroundColor Cyan
