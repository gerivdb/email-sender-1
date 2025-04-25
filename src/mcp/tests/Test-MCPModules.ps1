#Requires -Version 5.1
<#
.SYNOPSIS
    Test simple pour vérifier que les modules MCP fonctionnent correctement.
.DESCRIPTION
    Ce script effectue des tests simples pour vérifier que les modules MCPManager et MCPClient fonctionnent correctement.
.EXAMPLE
    .\Test-MCPModules.ps1
    Exécute les tests simples.
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

# Fonction pour tester un module
function Test-Module {
    param (
        [string]$ModulePath,
        [string]$ModuleName
    )

    Write-Log "Test du module $ModuleName..." -Level "INFO"

    # Vérifier que le module existe
    if (-not (Test-Path $ModulePath)) {
        Write-Log "Module $ModuleName introuvable à $ModulePath" -Level "ERROR"
        return $false
    }

    # Essayer d'importer le module
    try {
        Import-Module $ModulePath -Force
        Write-Log "Module $ModuleName importé avec succès" -Level "SUCCESS"

        # Vérifier que les fonctions sont exportées
        $exportedFunctions = Get-Command -Module $ModuleName | Select-Object -ExpandProperty Name
        Write-Log "Fonctions exportées par ${ModuleName}" -Level "INFO"
        $exportedFunctions | ForEach-Object { Write-Log "- $_" -Level "INFO" }

        return $true
    } catch {
        Write-Log "Erreur lors de l'importation du module ${ModuleName}: $_" -Level "ERROR"
        return $false
    }
}

# Chemins des modules
$managerModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MCPManager.psm1"
$clientModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MCPClient.psm1"

# Tester les modules
$managerSuccess = Test-Module -ModulePath $managerModulePath -ModuleName "MCPManager"
$clientSuccess = Test-Module -ModulePath $clientModulePath -ModuleName "MCPClient"

# Afficher le résultat
if ($managerSuccess -and $clientSuccess) {
    Write-Log "Tous les modules ont été testés avec succès" -Level "SUCCESS"
} else {
    Write-Log "Certains modules n'ont pas pu être testés correctement" -Level "ERROR"
}

# Créer un dossier temporaire pour les tests
$testDrive = Join-Path -Path $env:TEMP -ChildPath "MCPTests_$(Get-Random)"
if (Test-Path $testDrive) {
    Remove-Item $testDrive -Recurse -Force
}
New-Item -Path $testDrive -ItemType Directory -Force | Out-Null

# Tester la fonction New-MCPConfiguration
Write-Log "Test de la fonction New-MCPConfiguration..." -Level "INFO"
$configPath = Join-Path -Path $testDrive -ChildPath "mcp-config.json"
try {
    $result = New-MCPConfiguration -OutputPath $configPath -Force
    if ($result -eq $true -and (Test-Path $configPath)) {
        Write-Log "Fonction New-MCPConfiguration testée avec succès" -Level "SUCCESS"

        # Vérifier que le contenu est un JSON valide
        $content = Get-Content -Path $configPath -Raw
        $config = $content | ConvertFrom-Json

        if ($config.mcpServers.filesystem -and $config.mcpServers.n8n -and $config.mcpServers.augment) {
            Write-Log "La configuration contient les serveurs attendus" -Level "SUCCESS"
        } else {
            Write-Log "La configuration ne contient pas tous les serveurs attendus" -Level "WARNING"
        }
    } else {
        Write-Log "Fonction New-MCPConfiguration échouée" -Level "ERROR"
    }
} catch {
    Write-Log "Erreur lors du test de New-MCPConfiguration: $_" -Level "ERROR"
}

# Nettoyer
if (Test-Path $testDrive) {
    Remove-Item $testDrive -Recurse -Force
    Write-Log "Dossier temporaire supprimé" -Level "INFO"
}
