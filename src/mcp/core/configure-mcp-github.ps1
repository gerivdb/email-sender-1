


# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
# Script pour configurer le MCP GitHub dans n8n

Write-Host "=== Configuration du MCP GitHub dans n8n ===" -ForegroundColor Cyan

# VÃ©rifier si n8n est installÃ©
$n8nVersion = npx n8n --version 2>$null
if (-not $n8nVersion) {
    Write-Host "âŒ n8n n'est pas installÃ© ou n'est pas accessible via npx" -ForegroundColor Red
    Write-Host "Veuillez installer n8n ou vÃ©rifier votre installation"
    exit 1
}

Write-Host "âœ… n8n version $n8nVersion dÃ©tectÃ©e" -ForegroundColor Green

# CrÃ©er le fichier batch pour le MCP GitHub s'il n'existe pas dÃ©jÃ 
$mcpGithubPath = "..\..\D"
$mcpGithubDir = Split-Path -Parent $mcpGithubPath

if (-not (Test-Path $mcpGithubDir)) {
    New-Item -ItemType Directory -Path $mcpGithubDir -Force | Out-Null
    Write-Host "âœ… RÃ©pertoire $mcpGithubDir crÃ©Ã©" -ForegroundColor Green
}

if (-not (Test-Path $mcpGithubPath)) {
    $mcpGithubContent = @"
@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo DÃ©marrage du MCP GitHub...

:: VÃ©rifier si un token GitHub est configurÃ©
if "%GITHUB_TOKEN%"=="" (
    :: VÃ©rifier si un fichier .env existe
    if exist "%~dp0..\..\..\\.env" (
        for /f "tokens=2 delims==" %%a in ('findstr /C:"GITHUB_TOKEN" "%~dp0..\..\..\\.env"') do set GITHUB_TOKEN=%%a
        if not "%GITHUB_TOKEN%"=="" (
            echo Token GitHub trouvÃ© dans le fichier .env
        )
    )
    
    :: Si toujours pas de token, informer l'utilisateur
    if "%GITHUB_TOKEN%"=="" (
        echo Aucun token GitHub trouvÃ©. Le serveur fonctionnera en mode anonyme avec des limites de taux plus strictes.
    )
) else (
    echo Token GitHub configurÃ©
)

:: Lancement du serveur MCP GitHub
mcp-server-github
"@
    Set-Content -Path $mcpGithubPath -Value $mcpGithubContent
    Write-Host "âœ… Fichier $mcpGithubPath crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "âœ… Fichier $mcpGithubPath existe dÃ©jÃ " -ForegroundColor Green
}

# DÃ©terminer le rÃ©pertoire .n8n
$n8nDir = "$env:APPDATA\.n8n"
if (-not (Test-Path $n8nDir)) {
    New-Item -ItemType Directory -Path $n8nDir | Out-Null
    Write-Host "âœ… RÃ©pertoire .n8n crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "âœ… RÃ©pertoire .n8n existe dÃ©jÃ " -ForegroundColor Green
}

# CrÃ©er le rÃ©pertoire .n8n/credentials s'il n'existe pas
$credentialsDir = "$n8nDir\credentials"
if (-not (Test-Path $credentialsDir)) {
    New-Item -ItemType Directory -Path $credentialsDir | Out-Null
    Write-Host "âœ… RÃ©pertoire .n8n/credentials crÃ©Ã©" -ForegroundColor Green
} else {
    Write-Host "âœ… RÃ©pertoire .n8n/credentials existe dÃ©jÃ " -ForegroundColor Green
}

# GÃ©nÃ©rer un identifiant unique
$mcpGithubId = [guid]::NewGuid().ToString("N")

# CrÃ©er le fichier d'identifiants
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
Write-Host "âœ… Fichier d'identifiants MCP GitHub crÃ©Ã©" -ForegroundColor Green

# Mettre Ã  jour le fichier credentials.db
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
    Write-Host "âœ… Fichier credentials.db mis Ã  jour" -ForegroundColor Green
} else {
    $credentialsDbContent = @"
{"$mcpGithubId":{"name":"MCP GitHub","type":"mcpClientApi","nodesAccess":[{"nodeType":"n8n-nodes-base.mcpClient"}]}}
"@
    Set-Content -Path $credentialsDbPath -Value $credentialsDbContent
    Write-Host "âœ… Fichier credentials.db crÃ©Ã©" -ForegroundColor Green
}

Write-Host "`nâœ… Configuration du MCP GitHub terminÃ©e" -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le MCP GitHub dans vos workflows n8n" -ForegroundColor Cyan
Write-Host "Nom de l'identifiant : MCP GitHub" -ForegroundColor Cyan


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
