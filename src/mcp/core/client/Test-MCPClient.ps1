#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour le module MCPClient.
.DESCRIPTION
    Ce script teste les fonctionnalités du module MCPClient en interagissant avec un serveur MCP.
.EXAMPLE
    .\Test-MCPClient.ps1
    Teste le module MCPClient.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
#>
[CmdletBinding()]
param ()

# Importer le module MCPClient
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "MCPClient.psm1"
Import-Module -Name $modulePath -Force

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
function Test-MCPClient {
    [CmdletBinding()]
    param ()

    try {
        # Initialiser la connexion au serveur MCP
        Write-Log "Initialisation de la connexion au serveur MCP" -Level "INFO"
        Initialize-MCPConnection -ServerUrl "http://localhost:8000"

        # Récupérer la liste des outils disponibles
        Write-Log "Récupération de la liste des outils disponibles" -Level "INFO"
        $tools = Get-MCPTools
        Write-Log "Outils disponibles: $($tools | ConvertTo-Json -Depth 3)" -Level "INFO"

        # Exemple 1: Additionner deux nombres
        Write-Log "Exemple 1: Additionner deux nombres" -Level "INFO"
        $addResult = Add-MCPNumbers -A 2 -B 3
        Write-Log "Résultat de l'addition: 2 + 3 = $addResult" -Level "SUCCESS"

        # Exemple 2: Multiplier deux nombres
        Write-Log "Exemple 2: Multiplier deux nombres" -Level "INFO"
        $multiplyResult = ConvertTo-MCPProduct -A 4 -B 5
        Write-Log "Résultat de la multiplication: 4 * 5 = $multiplyResult" -Level "SUCCESS"

        # Exemple 3: Obtenir des informations sur le système
        Write-Log "Exemple 3: Obtenir des informations sur le système" -Level "INFO"
        $systemInfo = Get-MCPSystemInfo
        Write-Log "Informations système: $($systemInfo | ConvertTo-Json -Depth 3)" -Level "SUCCESS"

        Write-Log "Tests terminés avec succès" -Level "SUCCESS"
    } catch {
        Write-Log "Erreur lors des tests: $_" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Test-MCPClient -Verbose
