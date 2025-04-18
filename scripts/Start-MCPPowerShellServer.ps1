#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre un serveur MCP pour exécuter des commandes PowerShell.
.DESCRIPTION
    Ce script démarre un serveur MCP qui permet d'exécuter des commandes PowerShell
    via le protocole MCP (Model Context Protocol). Il utilise le SDK MCP officiel d'Anthropic.
.PARAMETER Port
    Le port sur lequel le serveur MCP écoutera les connexions.
.PARAMETER Host
    L'adresse IP sur laquelle le serveur MCP écoutera les connexions.
.EXAMPLE
    .\Start-MCPPowerShellServer.ps1
    Démarre le serveur MCP sur le port par défaut (8000).
.EXAMPLE
    .\Start-MCPPowerShellServer.ps1 -Port 9000
    Démarre le serveur MCP sur le port 9000.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$Port = 8000,

    [Parameter(Mandatory = $false)]
    [string]$HostName = "localhost"
)

# Fonction de journalisation
function Write-MCPLog {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

# Importer le module MCPManager si disponible
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MCPManager.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-MCPLog "Module MCPManager introuvable à $modulePath. Utilisation des fonctions locales." -Level "WARNING"
}

# Vérifier si Python est installé
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pythonPath) {
    Write-MCPLog "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.11 ou supérieur." -Level "ERROR"
    exit 1
}

# Vérifier la version de Python
$pythonVersion = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
if ([version]$pythonVersion -lt [version]"3.10") {
    Write-MCPLog "Python 3.10 ou supérieur est requis. Version actuelle: $pythonVersion" -Level "ERROR"
    exit 1
}

# Vérifier si le SDK MCP est installé
$mcpInstalled = python -c "try: import mcp; print('OK'); except ImportError: print('NOT_INSTALLED')" 2>$null
if ($mcpInstalled -ne "OK") {
    Write-MCPLog "Installation du SDK MCP..." -Level "INFO"
    python -m pip install mcp[cli]
    if ($LASTEXITCODE -ne 0) {
        Write-MCPLog "Échec de l'installation du SDK MCP." -Level "ERROR"
        exit 1
    }
    Write-MCPLog "SDK MCP installé avec succès." -Level "SUCCESS"
}

# Vérifier si le script du serveur MCP existe
$serverScript = Join-Path -Path $PSScriptRoot -ChildPath "python\mcp_powershell_server.py"
if (-not (Test-Path $serverScript)) {
    Write-MCPLog "Script du serveur MCP introuvable à $serverScript" -Level "ERROR"
    exit 1
}

# Définir les variables d'environnement pour le serveur MCP
$env:MCP_HOST = $HostName
$env:MCP_PORT = $Port

# Démarrer le serveur MCP
Write-MCPLog "Démarrage du serveur MCP PowerShell sur ${HostName}:${Port}..." -Level "INFO"
python $serverScript

# Vérifier si l'exécution a réussi
if ($LASTEXITCODE -eq 0) {
    Write-MCPLog "Serveur MCP PowerShell arrêté." -Level "INFO"
    exit 0
} else {
    Write-MCPLog "Échec du démarrage du serveur MCP PowerShell avec le code de sortie $LASTEXITCODE." -Level "ERROR"
    exit 1
}
