#Requires -Version 5.1
<#
.SYNOPSIS
    Teste le serveur MCP avec curl.
.DESCRIPTION
    Ce script teste le serveur MCP avec curl pour vérifier qu'il répond correctement.
.EXAMPLE
    .\Test-MCPServerWithCurl.ps1
    Teste le serveur MCP avec curl.
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
function Test-MCPServerWithCurl {
    [CmdletBinding()]
    param ()
    
    try {
        # URL du serveur MCP
        $serverUrl = "http://localhost:8000"
        
        # Vérifier si curl est disponible
        if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
            Write-Log "curl n'est pas disponible. Veuillez l'installer." -Level "ERROR"
            return
        }
        
        # Test 1: Vérifier que le serveur répond
        Write-Log "Test 1: Vérifier que le serveur répond" -Level "INFO"
        $response = curl -s $serverUrl
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Le serveur répond" -Level "SUCCESS"
        }
        else {
            Write-Log "Le serveur ne répond pas" -Level "ERROR"
            return
        }
        
        # Test 2: Vérifier que le serveur accepte les requêtes SSE
        Write-Log "Test 2: Vérifier que le serveur accepte les requêtes SSE" -Level "INFO"
        $response = curl -s -H "Accept: text/event-stream" $serverUrl
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Le serveur accepte les requêtes SSE" -Level "SUCCESS"
        }
        else {
            Write-Log "Le serveur n'accepte pas les requêtes SSE" -Level "ERROR"
            return
        }
        
        # Test 3: Appeler l'outil add
        Write-Log "Test 3: Appeler l'outil add" -Level "INFO"
        $response = curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d '{"a": 2, "b": 3}' "$serverUrl/tools/add"
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Réponse: $response" -Level "SUCCESS"
        }
        else {
            Write-Log "Erreur lors de l'appel à l'outil add" -Level "ERROR"
            return
        }
        
        Write-Log "Tests terminés avec succès" -Level "SUCCESS"
    }
    catch {
        Write-Log "Erreur lors des tests: $_" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Test-MCPServerWithCurl -Verbose
