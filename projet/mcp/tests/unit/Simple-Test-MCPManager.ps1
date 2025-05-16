#Requires -Version 5.1
<#
.SYNOPSIS
    Test simplifié pour le module MCPManager.
.DESCRIPTION
    Ce script exécute un test simplifié pour vérifier le bon fonctionnement du module MCPManager.
.EXAMPLE
    .\Simple-Test-MCPManager.ps1
    Exécute le test simplifié pour le module MCPManager.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding()]
param ()

# Initialisation
$ErrorActionPreference = "Continue"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $testsRoot).Parent.FullName
$modulePath = Join-Path -Path $mcpRoot -ChildPath "modules\MCPManager\MCPManager.psm1"

Write-Host "Test simplifié pour le module MCPManager..." -ForegroundColor Cyan
Write-Host "Chemin du module: $modulePath" -ForegroundColor Cyan

# Test 1: Vérifier que le module existe
Write-Host "`nTest 1: Vérifier que le module existe" -ForegroundColor Yellow
if (Test-Path $modulePath) {
    Write-Host "Le module existe: $modulePath" -ForegroundColor Green
} else {
    Write-Host "Le module n'existe pas: $modulePath" -ForegroundColor Red
    exit 1
}

# Test 2: Vérifier que le module peut être importé
Write-Host "`nTest 2: Vérifier que le module peut être importé" -ForegroundColor Yellow
try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "Le module a été importé avec succès" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'importation du module: $_" -ForegroundColor Red
    exit 1
}

# Test 3: Vérifier que les fonctions sont exportées
Write-Host "`nTest 3: Vérifier que les fonctions sont exportées" -ForegroundColor Yellow
$exportedFunctions = Get-Command -Module MCPManager | Select-Object -ExpandProperty Name
Write-Host "Fonctions exportées:" -ForegroundColor Cyan
$exportedFunctions | ForEach-Object { Write-Host "- $_" -ForegroundColor White }

# Test 4: Vérifier que les fonctions requises sont exportées
Write-Host "`nTest 4: Vérifier que les fonctions requises sont exportées" -ForegroundColor Yellow
$requiredFunctions = @(
    "Get-MCPServers",
    "Get-MCPServerStatus",
    "Start-MCPServer",
    "Stop-MCPServer",
    "Restart-MCPServer",
    "Enable-MCPServer",
    "Disable-MCPServer",
    "Invoke-MCPCommand"
)

$missingFunctions = $requiredFunctions | Where-Object { $exportedFunctions -notcontains $_ }

if ($missingFunctions.Count -eq 0) {
    Write-Host "Toutes les fonctions requises sont exportées" -ForegroundColor Green
} else {
    Write-Host "Fonctions manquantes:" -ForegroundColor Red
    $missingFunctions | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
}

# Test 5: Vérifier que les fonctions peuvent être appelées
Write-Host "`nTest 5: Vérifier que les fonctions peuvent être appelées" -ForegroundColor Yellow
try {
    $servers = Get-MCPServers
    Write-Host "Get-MCPServers a été appelé avec succès" -ForegroundColor Green
    Write-Host "Nombre de serveurs: $($servers.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "Erreur lors de l'appel de Get-MCPServers: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
exit 0
