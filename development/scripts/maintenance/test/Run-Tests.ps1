#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute la suite de tests pour la solution d'organisation des scripts de maintenance.
.DESCRIPTION
    Ce script est un wrapper qui exÃ©cute la suite de tests pour la solution d'organisation
    des scripts de maintenance. Il appelle les scripts de test dans le dossier test/.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de test.
.PARAMETER GenerateHTML
    GÃ©nÃ¨re des rapports HTML en plus des rapports XML.
.PARAMETER TestType
    Type de tests Ã  exÃ©cuter: All (tous les tests), Unit (tests unitaires),
    Coverage (couverture de code), Integration (tests d'intÃ©gration).
.EXAMPLE
    .\Run-Tests.ps1 -OutputPath ".\reports" -GenerateHTML
.EXAMPLE
    .\Run-Tests.ps1 -TestType Unit -OutputPath ".\reports\tests"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-10
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

# VÃ©rifier si le dossier de tests existe
if (-not (Test-Path -Path $testDir)) {
    Write-Error "Le dossier de tests n'existe pas: $testDir"
    exit 1
}

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de sortie crÃ©Ã©: $OutputPath"
}

# ExÃ©cuter les tests en fonction du type spÃ©cifiÃ©
switch ($TestType) {
    "All" {
        # ExÃ©cuter la suite complÃ¨te de tests
        $testScript = Join-Path -Path $testDir -ChildPath "Run-TestSuite.ps1"
        Write-Host "ExÃ©cution de la suite complÃ¨te de tests..."
        $params = @{
            OutputPath = $OutputPath
        }
        if ($GenerateHTML) {
            $params.Add("GenerateHTML", $true)
        }
        & $testScript @params
    }
    "Unit" {
        # ExÃ©cuter uniquement les tests unitaires
        $testScript = Join-Path -Path $testDir -ChildPath "Run-AllTests.ps1"
        Write-Host "ExÃ©cution des tests unitaires..."
        $params = @{
            OutputPath = $OutputPath
        }
        if ($GenerateHTML) {
            $params.Add("GenerateHTML", $true)
        }
        & $testScript @params
    }
    "Coverage" {
        # GÃ©nÃ©rer un rapport de couverture de code
        $testScript = Join-Path -Path $testDir -ChildPath "Get-CodeCoverage.ps1"
        Write-Host "GÃ©nÃ©ration de la couverture de code..."
        $params = @{
            OutputPath = $OutputPath
        }
        if ($GenerateHTML) {
            $params.Add("GenerateHTML", $true)
        }
        & $testScript @params
    }
    "Integration" {
        # ExÃ©cuter les tests d'intÃ©gration
        $testScript = Join-Path -Path $testDir -ChildPath "Test-Integration.ps1"
        Write-Host "ExÃ©cution des tests d'intÃ©gration..."
        & $testScript -OutputPath $OutputPath
    }
}

# Afficher un message de fin
Write-Host "`nExÃ©cution des tests terminÃ©e. Consultez les rapports dans le dossier: $OutputPath"
