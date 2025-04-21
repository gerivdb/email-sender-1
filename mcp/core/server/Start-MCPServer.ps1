#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre le serveur MCP.
.DESCRIPTION
    Ce script démarre le serveur MCP avec le transport SSE.
.EXAMPLE
    .\Start-MCPServer.ps1
    Démarre le serveur MCP.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
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

# Fonction principale
function Start-MCPServer {
    [CmdletBinding()]
    param ()
    
    try {
        # Chemin vers le script du serveur MCP
        $serverPath = Join-Path -Path $PSScriptRoot -ChildPath "server.py"
        
        # Vérifier si le script du serveur MCP existe
        if (-not (Test-Path $serverPath)) {
            Write-Log "Script du serveur MCP introuvable à $serverPath" -Level "ERROR"
            return
        }
        
        # Démarrer le serveur MCP
        Write-Log "Démarrage du serveur MCP..." -Level "INFO"
        Write-Log "Serveur MCP accessible à l'adresse http://localhost:8000" -Level "INFO"
        Write-Log "Utilisez Ctrl+C pour arrêter le serveur" -Level "INFO"
        
        # Exécuter le serveur MCP avec python -m uv run
        python -m uv run $serverPath
    }
    catch {
        Write-Log "Erreur lors du démarrage du serveur MCP: $_" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Start-MCPServer -Verbose
