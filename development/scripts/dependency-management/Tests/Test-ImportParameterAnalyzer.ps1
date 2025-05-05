#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le module ImportParameterAnalyzer.

.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s du module ImportParameterAnalyzer
    qui analyse les paramÃ¨tres d'importation dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImportParameterAnalyzer.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell de test avec diffÃ©rentes instructions Import-Module
$sampleCode = @'
# Import simple avec paramÃ¨tre positionnel
Import-Module PSScriptAnalyzer

# Import avec paramÃ¨tre nommÃ©
Import-Module -Name Pester

# Import avec chemin
Import-Module -Path "C:\Modules\MyModule.psm1"

# Import avec version
Import-Module -Name PSScriptAnalyzer -RequiredVersion 1.18.0

# Import avec caractÃ¨res spÃ©ciaux
Import-Module -Name "Module-With-Hyphens"

# Import avec plusieurs paramÃ¨tres
Import-Module -Name PSScriptAnalyzer -Global -Force -Verbose

# Import avec chemin relatif
Import-Module -Path "..\Modules\MyModule.psm1"

# Import avec variable
$moduleName = "MyModule"
Import-Module -Name $moduleName

# Import avec MinimumVersion et MaximumVersion
Import-Module -Name PSScriptAnalyzer -MinimumVersion 1.18.0 -MaximumVersion 2.0.0
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Trouver toutes les instructions Import-Module
$importModuleCalls = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and
        $node.CommandElements.Count -gt 0 -and
        $node.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $node.CommandElements[0].Value -eq 'Import-Module'
    }, $true)

Write-Host "=== Test du module ImportParameterAnalyzer ===" -ForegroundColor Cyan
Write-Host "Nombre d'instructions Import-Module trouvÃ©es: $($importModuleCalls.Count)" -ForegroundColor Yellow

# Test 1: Analyser les diffÃ©rents types de paramÃ¨tres d'importation
Write-Host "`nTest 1: Analyser les diffÃ©rents types de paramÃ¨tres d'importation" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    $parameterTypes = Get-ImportParameterTypes -CommandAst $call

    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green
    Write-Host "    ParamÃ¨tres nommÃ©s: $($parameterTypes.NamedParameters.Keys -join ', ')" -ForegroundColor Gray
    Write-Host "    ParamÃ¨tres positionnels: $($parameterTypes.PositionalParameters.Count)" -ForegroundColor Gray
    Write-Host "    ParamÃ¨tres switch: $($parameterTypes.SwitchParameters -join ', ')" -ForegroundColor Gray
    Write-Host "    A paramÃ¨tre Name: $($parameterTypes.HasNameParameter)" -ForegroundColor Gray
    Write-Host "    A paramÃ¨tre Path: $($parameterTypes.HasPathParameter)" -ForegroundColor Gray
    Write-Host "    A paramÃ¨tre Version: $($parameterTypes.HasVersionParameter)" -ForegroundColor Gray
    Write-Host "    A caractÃ¨res spÃ©ciaux: $($parameterTypes.HasSpecialCharacters)" -ForegroundColor Gray
    Write-Host "    ParamÃ¨tres requis: $($parameterTypes.RequiredParameters -join ', ')" -ForegroundColor Gray
    Write-Host "    ParamÃ¨tres optionnels: $($parameterTypes.OptionalParameters -join ', ')" -ForegroundColor Gray
    Write-Host ""
}

# Test 2: DÃ©tecter les paramÃ¨tres nommÃ©s
Write-Host "`nTest 2: DÃ©tecter les paramÃ¨tres nommÃ©s" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    $namedParameters = Get-NamedParameters -CommandAst $call

    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green
    Write-Host "    ParamÃ¨tres nommÃ©s dÃ©tectÃ©s: $($namedParameters.Keys -join ', ')" -ForegroundColor Gray

    foreach ($paramName in $namedParameters.Keys) {
        $paramInfo = $namedParameters[$paramName]
        $valueText = if ($paramInfo.HasValue) {
            $paramValue = Get-ParameterValue -CommandAst $call -ParameterName $paramName
            $paramValue
        } else {
            "Switch (pas de valeur)"
        }
        Write-Host "      $paramName = $valueText" -ForegroundColor Gray
    }

    Write-Host ""
}

# Test 3: Extraire les valeurs de paramÃ¨tres
Write-Host "`nTest 3: Extraire les valeurs de paramÃ¨tres" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green

    # Essayer d'extraire la valeur du paramÃ¨tre Name
    $nameValue = Get-ParameterValue -CommandAst $call -ParameterName "Name"
    Write-Host "    Valeur du paramÃ¨tre Name: $nameValue" -ForegroundColor Gray

    # Essayer d'extraire la valeur du paramÃ¨tre Path
    $pathValue = Get-ParameterValue -CommandAst $call -ParameterName "Path"
    Write-Host "    Valeur du paramÃ¨tre Path: $pathValue" -ForegroundColor Gray

    Write-Host ""
}

# Test 4: CrÃ©er la gestion des paramÃ¨tres avec caractÃ¨res spÃ©ciaux
Write-Host "`nTest 4: CrÃ©er la gestion des paramÃ¨tres avec caractÃ¨res spÃ©ciaux" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green

    # VÃ©rifier si le paramÃ¨tre Name contient des caractÃ¨res spÃ©ciaux
    $hasSpecialChars = Test-SpecialCharactersInParameter -CommandAst $call -ParameterName "Name"
    Write-Host "    Le paramÃ¨tre Name contient des caractÃ¨res spÃ©ciaux: $hasSpecialChars" -ForegroundColor Gray

    Write-Host ""
}

# Test 5: DÃ©velopper la dÃ©tection des paramÃ¨tres optionnels
Write-Host "`nTest 5: DÃ©velopper la dÃ©tection des paramÃ¨tres optionnels" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green

    # Obtenir les paramÃ¨tres optionnels
    $optionalParams = Get-OptionalParameters -CommandAst $call
    Write-Host "    ParamÃ¨tres optionnels: $($optionalParams -join ', ')" -ForegroundColor Gray

    Write-Host ""
}

Write-Host "Tests terminÃ©s avec succÃ¨s!" -ForegroundColor Green
