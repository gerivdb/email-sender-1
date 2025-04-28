#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute la suite de tests pour la solution d'organisation des scripts de maintenance.
.DESCRIPTION
    Ce script est un wrapper qui exécute la suite de tests pour la solution d'organisation
    des scripts de maintenance. Il appelle les scripts de test dans le dossier test/.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de test.
.PARAMETER GenerateHTML
    Génère des rapports HTML en plus des rapports XML.
.PARAMETER TestType
    Type de tests à exécuter: All (tous les tests), Unit (tests unitaires),
    Coverage (couverture de code), Integration (tests d'intégration).
.EXAMPLE
    .\Run-Tests.ps1 -OutputPath ".\reports" -GenerateHTML
.EXAMPLE
    .\Run-Tests.ps1 -TestType Unit -OutputPath ".\reports\tests"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Unit", "Coverage", "Integration")]
    [string]$TestType = "All"
)

# Chemin du dossier de tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "test"

# Vérifier si le dossier de tests existe
if (-not (Test-Path -Path $testDir)) {
    Write-Error "Le dossier de tests n'existe pas: $testDir"
    exit 1
}

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de sortie créé: $OutputPath"
}

# Exécuter les tests en fonction du type spécifié
switch ($TestType) {
    "All" {
        # Exécuter la suite complète de tests
        $testScript = Join-Path -Path $testDir -ChildPath "Run-TestSuite.ps1"
        Write-Host "Exécution de la suite complète de tests..."
        $params = @{
            OutputPath = $OutputPath
        }
        if ($GenerateHTML) {
            $params.Add("GenerateHTML", $true)
        }
        & $testScript @params
    }
    "Unit" {
        # Exécuter uniquement les tests unitaires
        $testScript = Join-Path -Path $testDir -ChildPath "Run-AllTests.ps1"
        Write-Host "Exécution des tests unitaires..."
        $params = @{
            OutputPath = $OutputPath
        }
        if ($GenerateHTML) {
            $params.Add("GenerateHTML", $true)
        }
        & $testScript @params
    }
    "Coverage" {
        # Générer un rapport de couverture de code
        $testScript = Join-Path -Path $testDir -ChildPath "Get-CodeCoverage.ps1"
        Write-Host "Génération de la couverture de code..."
        $params = @{
            OutputPath = $OutputPath
        }
        if ($GenerateHTML) {
            $params.Add("GenerateHTML", $true)
        }
        & $testScript @params
    }
    "Integration" {
        # Exécuter les tests d'intégration
        $testScript = Join-Path -Path $testDir -ChildPath "Test-Integration.ps1"
        Write-Host "Exécution des tests d'intégration..."
        & $testScript -OutputPath $OutputPath
    }
}

# Afficher un message de fin
Write-Host "`nExécution des tests terminée. Consultez les rapports dans le dossier: $OutputPath"
