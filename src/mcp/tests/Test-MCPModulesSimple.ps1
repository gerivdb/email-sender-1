#Requires -Version 5.1
<#
.SYNOPSIS
    Test très simple pour vérifier que les modules MCP peuvent être importés.
.DESCRIPTION
    Ce script effectue un test très simple pour vérifier que les modules MCPManager et MCPClient peuvent être importés.
.EXAMPLE
    .\Test-MCPModulesSimple.ps1
    Exécute le test très simple.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>
[CmdletBinding()]
param ()

# Chemins des modules
$managerModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MCPManager.psm1"
$clientModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MCPClient.psm1"

# Vérifier que les modules existent
Write-Host "Vérification de l'existence des modules..."
if (Test-Path $managerModulePath) {
    Write-Host "Module MCPManager trouvé à $managerModulePath" -ForegroundColor Green
} else {
    Write-Host "Module MCPManager introuvable à $managerModulePath" -ForegroundColor Red
}

if (Test-Path $clientModulePath) {
    Write-Host "Module MCPClient trouvé à $clientModulePath" -ForegroundColor Green
} else {
    Write-Host "Module MCPClient introuvable à $clientModulePath" -ForegroundColor Red
}

# Essayer d'importer les modules
Write-Host "Importation des modules..."
try {
    Import-Module $managerModulePath -Force
    Write-Host "Module MCPManager importé avec succès" -ForegroundColor Green
    
    # Afficher les fonctions exportées
    $managerFunctions = Get-Command -Module MCPManager | Select-Object -ExpandProperty Name
    Write-Host "Fonctions exportées par MCPManager:"
    $managerFunctions | ForEach-Object { Write-Host "- $_" }
} catch {
    Write-Host "Erreur lors de l'importation du module MCPManager: $_" -ForegroundColor Red
}

try {
    Import-Module $clientModulePath -Force
    Write-Host "Module MCPClient importé avec succès" -ForegroundColor Green
    
    # Afficher les fonctions exportées
    $clientFunctions = Get-Command -Module MCPClient | Select-Object -ExpandProperty Name
    Write-Host "Fonctions exportées par MCPClient:"
    $clientFunctions | ForEach-Object { Write-Host "- $_" }
} catch {
    Write-Host "Erreur lors de l'importation du module MCPClient: $_" -ForegroundColor Red
}
