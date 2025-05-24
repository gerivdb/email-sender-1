#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour le projet MCP.
.EXAMPLE
    .\Start-Tests.ps1
    Exécute tous les tests unitaires.
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
function Start-Tests {
    [CmdletBinding()]
    param ()

    try {
        # Vérifier si pytest est installé
        Write-Log "Vérification de l'installation de pytest..." -Level "INFO"
        $pytestInstalled = python -c "import pytest" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "pytest n'est pas installé. Installation en cours..." -Level "WARNING"
            python -m uv add pytest
        }

        # Vérifier si Pester est installé
        Write-Log "Vérification de l'installation de Pester..." -Level "INFO"
        $pesterInstalled = Get-Module -Name Pester -ListAvailable
        if (-not $pesterInstalled) {
            Write-Log "Pester n'est pas installé. Installation en cours..." -Level "WARNING"
            Install-Module -Name Pester -Force -SkipPublisherCheck
        }

        # Exécuter les tests unitaires Python
        Write-Log "Exécution des tests unitaires Python..." -Level "INFO"
        $currentDir = Get-Location
        python -m pytest $currentDir\test_server.py -v
        python -m pytest $currentDir\test_client.py -v

        # Vérifier si pytest-asyncio est installé
        Write-Log "Vérification de l'installation de pytest-asyncio..." -Level "INFO"
        $pytestAsyncioInstalled = python -c "import pytest_asyncio" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "pytest-asyncio n'est pas installé. Installation en cours..." -Level "WARNING"
            python -m uv add pytest-asyncio
        }

        # Exécuter les tests unitaires PowerShell
        Write-Log "Exécution des tests unitaires PowerShell..." -Level "INFO"

        # Mettre à jour le chemin du module MCPClient.psm1 dans les tests
        $testFile = Join-Path -Path $PSScriptRoot -ChildPath "MCPClient.Tests.InModuleScope.ps1"
        $content = Get-Content -Path $testFile -Raw
        $newContent = $content -replace '\$modulePath = Join-Path -Path \$PSScriptRoot -ChildPath "MCPClient.psm1"', '\$modulePath = Join-Path -Path \$PSScriptRoot -ChildPath "..\client\MCPClient.psm1"'
        Set-Content -Path $testFile -Value $newContent

        Invoke-Pester -Path .\MCPClient.Tests.InModuleScope.ps1 -Output Detailed

        Write-Log "Tous les tests unitaires ont été exécutés avec succès" -Level "SUCCESS"
    } catch {
        Write-Log "Erreur lors de l'exécution des tests unitaires : $($_.Exception.Message)" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Start-Tests -Verbose

