#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du module MCPClient.
.DESCRIPTION
    Ce script montre comment utiliser le module MCPClient pour interagir avec le serveur MCP.
.EXAMPLE
    .\Example-MCPClient.ps1
    Exécute l'exemple d'utilisation du module MCPClient.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
#>
[CmdletBinding()]
param ()

# Importer le module MCPClient
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "MCPClient.psm1"
if (Test-Path $modulePath) {
    Import-Module -Name $modulePath -Force
    Write-Host "Module MCPClient importé depuis $modulePath" -ForegroundColor Green
}
else {
    # Essayer d'importer le module depuis le répertoire des modules PowerShell
    try {
        Import-Module -Name "MCPClient" -ErrorAction Stop
        Write-Host "Module MCPClient importé depuis le répertoire des modules PowerShell" -ForegroundColor Green
    }
    catch {
        Write-Host "Impossible d'importer le module MCPClient. Veuillez l'installer avec Install-MCPClient.ps1" -ForegroundColor Red
        exit
    }
}

# Initialiser la connexion au serveur MCP
Write-Host "Initialisation de la connexion au serveur MCP..." -ForegroundColor Cyan
Initialize-MCPConnection -ServerUrl "http://localhost:8000"

# Récupérer la liste des outils disponibles
Write-Host "Récupération de la liste des outils disponibles..." -ForegroundColor Cyan
$tools = Get-MCPTools
Write-Host "Outils disponibles :" -ForegroundColor Green
$tools | ForEach-Object {
    Write-Host "  - $($_.name): $($_.description)" -ForegroundColor White
}

# Exemple 1: Additionner deux nombres
Write-Host "`nExemple 1: Additionner deux nombres" -ForegroundColor Cyan
$a = 2
$b = 3
Write-Host "Additionner $a et $b..." -ForegroundColor White
$result = Add-MCPNumbers -A $a -B $b
Write-Host "Résultat: $a + $b = $($result.result)" -ForegroundColor Green

# Exemple 2: Multiplier deux nombres
Write-Host "`nExemple 2: Multiplier deux nombres" -ForegroundColor Cyan
$a = 4
$b = 5
Write-Host "Multiplier $a et $b..." -ForegroundColor White
$result = ConvertTo-MCPProduct -A $a -B $b
Write-Host "Résultat: $a * $b = $($result.result)" -ForegroundColor Green

# Exemple 3: Obtenir des informations sur le système
Write-Host "`nExemple 3: Obtenir des informations sur le système" -ForegroundColor Cyan
Write-Host "Récupération des informations système..." -ForegroundColor White
$systemInfo = Get-MCPSystemInfo
Write-Host "Informations système :" -ForegroundColor Green
Write-Host "  - Système d'exploitation: $($systemInfo.result.os)" -ForegroundColor White
Write-Host "  - Version du système: $($systemInfo.result.os_version)" -ForegroundColor White
Write-Host "  - Version de Python: $($systemInfo.result.python_version)" -ForegroundColor White
Write-Host "  - Nom d'hôte: $($systemInfo.result.hostname)" -ForegroundColor White
Write-Host "  - Nombre de processeurs: $($systemInfo.result.cpu_count)" -ForegroundColor White

# Exemple 4: Appeler un outil directement
Write-Host "`nExemple 4: Appeler un outil directement" -ForegroundColor Cyan
Write-Host "Appel de l'outil add avec les paramètres a=10, b=20..." -ForegroundColor White
$result = Invoke-MCPTool -ToolName "add" -Parameters @{
    a = 10
    b = 20
}
Write-Host "Résultat: 10 + 20 = $($result.result)" -ForegroundColor Green

Write-Host "`nExemples terminés avec succès" -ForegroundColor Green
