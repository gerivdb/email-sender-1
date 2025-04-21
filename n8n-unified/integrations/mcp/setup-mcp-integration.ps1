<#
.SYNOPSIS
    Script de configuration de l'intégration entre n8n et les serveurs MCP.

.DESCRIPTION
    Ce script configure l'intégration entre n8n et les serveurs MCP en créant les dossiers
    et fichiers nécessaires, et en vérifiant que n8n et les serveurs MCP sont accessibles.
#>

#Requires -Version 5.1

# Paramètres
param (
    [string]$N8nUrl = "http://localhost:5678",
    [string]$ApiKey = "",
    [string]$McpPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp",
    [switch]$Force
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Join-Path -Path $ScriptPath -ChildPath "config"
$LogsDir = Join-Path -Path $ScriptPath -ChildPath "logs"
$ConfigFile = Join-Path -Path $ConfigDir -ChildPath "mcp-n8n-config.json"
$ModuleFile = Join-Path -Path $ScriptPath -ChildPath "McpN8nIntegration.ps1"

# Fonction pour écrire dans la console avec des couleurs
function Write-ColorOutput {
    param (
        [string]$Message,
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White
    )
    
    $OriginalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $OriginalColor
}

# Afficher l'en-tête
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "Configuration de l'intégration n8n avec les serveurs MCP" -ForegroundColor Cyan
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput ""

# Vérifier si le module existe
if (-not (Test-Path -Path $ModuleFile)) {
    Write-ColorOutput "Erreur : Le fichier module McpN8nIntegration.ps1 n'existe pas." -ForegroundColor Red
    Write-ColorOutput "Veuillez vous assurer que le fichier est présent dans le dossier $ScriptPath." -ForegroundColor Red
    exit 1
}

# Créer les dossiers nécessaires
Write-ColorOutput "Création des dossiers nécessaires..." -ForegroundColor Yellow

$Directories = @($ConfigDir, $LogsDir)
foreach ($Dir in $Directories) {
    if (-not (Test-Path -Path $Dir)) {
        New-Item -Path $Dir -ItemType Directory -Force | Out-Null
        Write-ColorOutput "  - Dossier créé : $Dir" -ForegroundColor Green
    }
    else {
        Write-ColorOutput "  - Dossier existant : $Dir" -ForegroundColor Gray
    }
}

# Créer ou mettre à jour le fichier de configuration
Write-ColorOutput "Configuration de l'intégration..." -ForegroundColor Yellow

$Config = @{
    N8nUrl = $N8nUrl
    ApiKey = $ApiKey
    McpPath = $McpPath
    LastSync = $null
    Servers = @()
    Credentials = @()
}

if (Test-Path -Path $ConfigFile -and -not $Force) {
    $ExistingConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
    
    # Conserver les valeurs existantes si elles ne sont pas spécifiées
    if (-not $PSBoundParameters.ContainsKey('N8nUrl')) {
        $Config.N8nUrl = $ExistingConfig.N8nUrl
    }
    
    if (-not $PSBoundParameters.ContainsKey('ApiKey')) {
        $Config.ApiKey = $ExistingConfig.ApiKey
    }
    
    if (-not $PSBoundParameters.ContainsKey('McpPath')) {
        $Config.McpPath = $ExistingConfig.McpPath
    }
    
    $Config.LastSync = $ExistingConfig.LastSync
    $Config.Servers = $ExistingConfig.Servers
    $Config.Credentials = $ExistingConfig.Credentials
    
    Write-ColorOutput "  - Configuration existante mise à jour" -ForegroundColor Green
}
else {
    Write-ColorOutput "  - Nouvelle configuration créée" -ForegroundColor Green
}

# Sauvegarder la configuration
$Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8

# Vérifier si le dossier MCP existe
Write-ColorOutput "Vérification du dossier MCP..." -ForegroundColor Yellow

if (Test-Path -Path $McpPath) {
    Write-ColorOutput "  - Dossier MCP trouvé : $McpPath" -ForegroundColor Green
    
    # Vérifier si le dossier des serveurs MCP existe
    $ServersPath = Join-Path -Path $McpPath -ChildPath "servers"
    if (Test-Path -Path $ServersPath) {
        $Servers = Get-ChildItem -Path $ServersPath -Directory
        Write-ColorOutput "  - $($Servers.Count) serveurs MCP trouvés" -ForegroundColor Green
        
        foreach ($Server in $Servers) {
            Write-ColorOutput "    - $($Server.Name)" -ForegroundColor Gray
        }
    }
    else {
        Write-ColorOutput "  - Dossier des serveurs MCP non trouvé : $ServersPath" -ForegroundColor Red
    }
}
else {
    Write-ColorOutput "  - Dossier MCP non trouvé : $McpPath" -ForegroundColor Red
    Write-ColorOutput "    Veuillez spécifier le chemin correct du dossier MCP." -ForegroundColor Red
}

# Tester la connexion à n8n
Write-ColorOutput "Test de la connexion à n8n..." -ForegroundColor Yellow

try {
    $Headers = @{ "Accept" = "application/json" }
    
    if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
        $Headers["X-N8N-API-KEY"] = $Config.ApiKey
    }
    
    $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/healthz" -Method Get -Headers $Headers -TimeoutSec 5
    
    if ($Response.status -eq "ok") {
        Write-ColorOutput "  - Connexion à n8n réussie" -ForegroundColor Green
    }
    else {
        Write-ColorOutput "  - Connexion à n8n échouée : $($Response.status)" -ForegroundColor Red
        Write-ColorOutput "    Veuillez vérifier que n8n est en cours d'exécution et accessible à l'adresse $($Config.N8nUrl)." -ForegroundColor Red
    }
}
catch {
    Write-ColorOutput "  - Erreur lors de la connexion à n8n : $_" -ForegroundColor Red
    Write-ColorOutput "    Veuillez vérifier que n8n est en cours d'exécution et accessible à l'adresse $($Config.N8nUrl)." -ForegroundColor Red
}

# Créer les scripts de démarrage et d'arrêt
Write-ColorOutput "Création des scripts de démarrage et d'arrêt..." -ForegroundColor Yellow

# Script de démarrage
$StartScriptPath = Join-Path -Path $ScriptPath -ChildPath "start-n8n-with-mcp.cmd"
$StartScriptContent = @"
@echo off
echo Démarrage de n8n avec les serveurs MCP...
powershell -ExecutionPolicy Bypass -File "$ModuleFile" -N8nUrl "$N8nUrl" -ApiKey "$ApiKey" -McpPath "$McpPath" -Action Start
echo n8n démarré avec les serveurs MCP.
"@

Set-Content -Path $StartScriptPath -Value $StartScriptContent -Encoding ASCII
Write-ColorOutput "  - Script de démarrage créé : $StartScriptPath" -ForegroundColor Green

# Script d'arrêt
$StopScriptPath = Join-Path -Path $ScriptPath -ChildPath "stop-n8n-with-mcp.cmd"
$StopScriptContent = @"
@echo off
echo Arrêt de n8n...
powershell -ExecutionPolicy Bypass -File "$ModuleFile" -N8nUrl "$N8nUrl" -ApiKey "$ApiKey" -McpPath "$McpPath" -Action Stop
echo n8n arrêté.
"@

Set-Content -Path $StopScriptPath -Value $StopScriptContent -Encoding ASCII
Write-ColorOutput "  - Script d'arrêt créé : $StopScriptPath" -ForegroundColor Green

# Script de configuration
$ConfigScriptPath = Join-Path -Path $ScriptPath -ChildPath "configure-n8n-mcp.ps1"
$ConfigScriptContent = @"
<#
.SYNOPSIS
    Script pour configurer les identifiants MCP dans n8n.

.DESCRIPTION
    Ce script configure les identifiants MCP dans n8n en utilisant le module McpN8nIntegration.ps1.
#>

#Requires -Version 5.1

# Paramètres
param (
    [string]`$N8nUrl = "$N8nUrl",
    [string]`$ApiKey = "$ApiKey",
    [string]`$McpPath = "$McpPath"
)

# Importer le module
`$ModuleFile = Join-Path -Path `$PSScriptRoot -ChildPath "McpN8nIntegration.ps1"
if (-not (Test-Path -Path `$ModuleFile)) {
    Write-Error "Le fichier module McpN8nIntegration.ps1 n'existe pas."
    exit 1
}

# Configurer les identifiants MCP dans n8n
Write-Host "Configuration des identifiants MCP dans n8n..." -ForegroundColor Yellow
`$Result = & `$ModuleFile -N8nUrl `$N8nUrl -ApiKey `$ApiKey -McpPath `$McpPath -Action Configure

if (`$Result) {
    Write-Host "Configuration des identifiants MCP réussie." -ForegroundColor Green
}
else {
    Write-Host "Erreur lors de la configuration des identifiants MCP." -ForegroundColor Red
}
"@

Set-Content -Path $ConfigScriptPath -Value $ConfigScriptContent -Encoding UTF8
Write-ColorOutput "  - Script de configuration créé : $ConfigScriptPath" -ForegroundColor Green

# Script de synchronisation
$SyncScriptPath = Join-Path -Path $ScriptPath -ChildPath "sync-workflows-with-mcp.ps1"
$SyncScriptContent = @"
<#
.SYNOPSIS
    Script pour synchroniser les workflows avec les serveurs MCP.

.DESCRIPTION
    Ce script synchronise les workflows avec les serveurs MCP en utilisant le module McpN8nIntegration.ps1.
#>

#Requires -Version 5.1

# Paramètres
param (
    [string]`$N8nUrl = "$N8nUrl",
    [string]`$ApiKey = "$ApiKey",
    [string]`$McpPath = "$McpPath"
)

# Importer le module
`$ModuleFile = Join-Path -Path `$PSScriptRoot -ChildPath "McpN8nIntegration.ps1"
if (-not (Test-Path -Path `$ModuleFile)) {
    Write-Error "Le fichier module McpN8nIntegration.ps1 n'existe pas."
    exit 1
}

# Synchroniser les workflows avec les serveurs MCP
Write-Host "Synchronisation des workflows avec les serveurs MCP..." -ForegroundColor Yellow
`$Result = & `$ModuleFile -N8nUrl `$N8nUrl -ApiKey `$ApiKey -McpPath `$McpPath -Action Sync

if (`$Result) {
    Write-Host "Synchronisation des workflows réussie." -ForegroundColor Green
}
else {
    Write-Host "Erreur lors de la synchronisation des workflows." -ForegroundColor Red
}
"@

Set-Content -Path $SyncScriptPath -Value $SyncScriptContent -Encoding UTF8
Write-ColorOutput "  - Script de synchronisation créé : $SyncScriptPath" -ForegroundColor Green

# Configurer les identifiants MCP dans n8n
Write-ColorOutput "Configuration des identifiants MCP dans n8n..." -ForegroundColor Yellow

try {
    # Importer le module
    Import-Module $ModuleFile -Force
    
    # Configurer les identifiants MCP dans n8n
    $Result = Start-McpN8nIntegration -Action Configure
    
    if ($Result) {
        Write-ColorOutput "  - Configuration des identifiants MCP réussie" -ForegroundColor Green
    }
    else {
        Write-ColorOutput "  - Erreur lors de la configuration des identifiants MCP" -ForegroundColor Red
    }
}
catch {
    Write-ColorOutput "  - Erreur lors de la configuration des identifiants MCP : $_" -ForegroundColor Red
}

# Afficher les instructions finales
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "Configuration terminée avec succès !" -ForegroundColor Green
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Pour utiliser l'intégration, importez le module :" -ForegroundColor White
Write-ColorOutput "  Import-Module '$ModuleFile'" -ForegroundColor Yellow
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Puis utilisez les fonctions disponibles :" -ForegroundColor White
Write-ColorOutput "  Start-McpN8nIntegration -Action Test" -ForegroundColor Yellow
Write-ColorOutput "  Start-McpN8nIntegration -Action Configure" -ForegroundColor Yellow
Write-ColorOutput "  Start-McpN8nIntegration -Action Start" -ForegroundColor Yellow
Write-ColorOutput "  Start-McpN8nIntegration -Action Stop" -ForegroundColor Yellow
Write-ColorOutput "  Start-McpN8nIntegration -Action Sync" -ForegroundColor Yellow
Write-ColorOutput "  Start-McpN8nIntegration -Action Copy" -ForegroundColor Yellow
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Ou utilisez les scripts créés :" -ForegroundColor White
Write-ColorOutput "  .\start-n8n-with-mcp.cmd" -ForegroundColor Yellow
Write-ColorOutput "  .\stop-n8n-with-mcp.cmd" -ForegroundColor Yellow
Write-ColorOutput "  .\configure-n8n-mcp.ps1" -ForegroundColor Yellow
Write-ColorOutput "  .\sync-workflows-with-mcp.ps1" -ForegroundColor Yellow
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Pour plus d'informations, consultez le fichier README.md." -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
