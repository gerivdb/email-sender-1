#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre un serveur MCP simple pour tester l'intégration avec PowerShell.
.DESCRIPTION
    Ce script démarre un serveur MCP simple qui expose quelques outils de base.
.EXAMPLE
    .\Start-SimpleMCPServer.ps1
    Démarre le serveur MCP simple sur le port par défaut (8000).
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>
[CmdletBinding()]
param ()

# Fonction de journalisation
function Write-Log {
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

# Vérifier si Python est installé
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pythonPath) {
    Write-Log "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.11 ou supérieur." -Level "ERROR"
    exit 1
}

# Vérifier la version de Python
$pythonVersion = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
if ([version]$pythonVersion -lt [version]"3.10") {
    Write-Log "Python 3.10 ou supérieur est requis. Version actuelle: $pythonVersion" -Level "ERROR"
    exit 1
}

# Vérifier si le SDK MCP est installé
$mcpInstalled = python -c "try: import mcp; print('OK'); except ImportError: print('NOT_INSTALLED')" 2>$null
if ($mcpInstalled -ne "OK") {
    Write-Log "Installation du SDK MCP..." -Level "INFO"
    python -m pip install mcp[cli]
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Échec de l'installation du SDK MCP." -Level "ERROR"
        exit 1
    }
    Write-Log "SDK MCP installé avec succès." -Level "SUCCESS"
}

# Vérifier si le script du serveur MCP existe
$serverScript = Join-Path -Path $PSScriptRoot -ChildPath "python\simple_mcp_server.py"
if (-not (Test-Path $serverScript)) {
    Write-Log "Script du serveur MCP introuvable à $serverScript" -Level "ERROR"
    exit 1
}

# Démarrer le serveur MCP
Write-Log "Démarrage du serveur MCP simple sur localhost:8000..." -Level "INFO"
python $serverScript

# Vérifier si l'exécution a réussi
if ($LASTEXITCODE -eq 0) {
    Write-Log "Serveur MCP simple arrêté." -Level "INFO"
    exit 0
} else {
    Write-Log "Échec du démarrage du serveur MCP simple avec le code de sortie $LASTEXITCODE." -Level "ERROR"
    exit 1
}
