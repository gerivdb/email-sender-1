#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module MCPManager.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module MCPManager.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MCPManager.psm1"

# Vérifier que le module existe
if (Test-Path $modulePath) {
    Write-Host "Module MCPManager trouvé à $modulePath" -ForegroundColor Green
} else {
    Write-Host "Module MCPManager introuvable à $modulePath" -ForegroundColor Red
    exit 1
}

# Vérifier que le module peut être importé
try {
    Import-Module $modulePath -Force
    Write-Host "Module MCPManager importé avec succès" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'importation du module MCPManager: $_" -ForegroundColor Red
    exit 1
}

# Vérifier que les fonctions publiques sont exportées
$exportedFunctions = Get-Command -Module MCPManager | Select-Object -ExpandProperty Name
Write-Host "Fonctions exportées:" -ForegroundColor Cyan
$exportedFunctions | ForEach-Object { Write-Host "- $_" -ForegroundColor White }

# Vérifier que les fonctions requises sont exportées
$requiredFunctions = @("Find-MCPServers", "New-MCPConfiguration", "Start-MCPManager", "Invoke-MCPCommand")
$missingFunctions = $requiredFunctions | Where-Object { $exportedFunctions -notcontains $_ }

if ($missingFunctions.Count -gt 0) {
    Write-Host "Fonctions manquantes:" -ForegroundColor Red
    $missingFunctions | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "Toutes les fonctions requises sont exportées" -ForegroundColor Green
}

# Créer un dossier temporaire pour les tests
$TestDrive = Join-Path -Path $env:TEMP -ChildPath "MCPManagerTests"
if (Test-Path $TestDrive) {
    Remove-Item $TestDrive -Recurse -Force
}
New-Item -Path $TestDrive -ItemType Directory -Force | Out-Null
Write-Host "Dossier temporaire créé à $TestDrive" -ForegroundColor Green

# Créer un fichier de configuration de test
$TestConfigPath = Join-Path -Path $TestDrive -ChildPath "mcp-config.json"

# Tester la fonction New-MCPConfiguration
try {
    # Rediriger la sortie de Write-MCPLog vers $null
    function Write-MCPLog { param($Message, $Level) }

    $result = New-MCPConfiguration -OutputPath $TestConfigPath -Force

    if ($result -eq $true -and (Test-Path $TestConfigPath)) {
        Write-Host "Test de New-MCPConfiguration réussi" -ForegroundColor Green

        # Vérifier que le contenu est un JSON valide
        $content = Get-Content -Path $TestConfigPath -Raw
        $config = $content | ConvertFrom-Json

        if ($config.mcpServers.filesystem -and $config.mcpServers.n8n -and $config.mcpServers.augment) {
            Write-Host "La configuration contient les serveurs attendus" -ForegroundColor Green
        } else {
            Write-Host "La configuration ne contient pas tous les serveurs attendus" -ForegroundColor Red
        }
    } else {
        Write-Host "Test de New-MCPConfiguration échoué" -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors du test de New-MCPConfiguration: $_" -ForegroundColor Red
}

# Nettoyer
if (Test-Path $TestDrive) {
    Remove-Item $TestDrive -Recurse -Force
    Write-Host "Dossier temporaire supprimé" -ForegroundColor Green
}

Write-Host "Tests terminés" -ForegroundColor Cyan
