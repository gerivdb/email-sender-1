#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le module ImportParameterAnalyzer.

.DESCRIPTION
    Ce script teste les fonctionnalités du module ImportParameterAnalyzer
    qui analyse les paramètres d'importation dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImportParameterAnalyzer.psm1"
Import-Module $modulePath -Force

# Créer un script PowerShell de test avec différentes instructions Import-Module
$sampleCode = @'
# Import simple avec paramètre positionnel
Import-Module PSScriptAnalyzer

# Import avec paramètre nommé
Import-Module -Name Pester

# Import avec chemin
Import-Module -Path "C:\Modules\MyModule.psm1"

# Import avec version
Import-Module -Name PSScriptAnalyzer -RequiredVersion 1.18.0

# Import avec caractères spéciaux
Import-Module -Name "Module-With-Hyphens"

# Import avec plusieurs paramètres
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
Write-Host "Nombre d'instructions Import-Module trouvées: $($importModuleCalls.Count)" -ForegroundColor Yellow

# Test 1: Analyser les différents types de paramètres d'importation
Write-Host "`nTest 1: Analyser les différents types de paramètres d'importation" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    $parameterTypes = Get-ImportParameterTypes -CommandAst $call

    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green
    Write-Host "    Paramètres nommés: $($parameterTypes.NamedParameters.Keys -join ', ')" -ForegroundColor Gray
    Write-Host "    Paramètres positionnels: $($parameterTypes.PositionalParameters.Count)" -ForegroundColor Gray
    Write-Host "    Paramètres switch: $($parameterTypes.SwitchParameters -join ', ')" -ForegroundColor Gray
    Write-Host "    A paramètre Name: $($parameterTypes.HasNameParameter)" -ForegroundColor Gray
    Write-Host "    A paramètre Path: $($parameterTypes.HasPathParameter)" -ForegroundColor Gray
    Write-Host "    A paramètre Version: $($parameterTypes.HasVersionParameter)" -ForegroundColor Gray
    Write-Host "    A caractères spéciaux: $($parameterTypes.HasSpecialCharacters)" -ForegroundColor Gray
    Write-Host "    Paramètres requis: $($parameterTypes.RequiredParameters -join ', ')" -ForegroundColor Gray
    Write-Host "    Paramètres optionnels: $($parameterTypes.OptionalParameters -join ', ')" -ForegroundColor Gray
    Write-Host ""
}

# Test 2: Détecter les paramètres nommés
Write-Host "`nTest 2: Détecter les paramètres nommés" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    $namedParameters = Get-NamedParameters -CommandAst $call

    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green
    Write-Host "    Paramètres nommés détectés: $($namedParameters.Keys -join ', ')" -ForegroundColor Gray

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

# Test 3: Extraire les valeurs de paramètres
Write-Host "`nTest 3: Extraire les valeurs de paramètres" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green

    # Essayer d'extraire la valeur du paramètre Name
    $nameValue = Get-ParameterValue -CommandAst $call -ParameterName "Name"
    Write-Host "    Valeur du paramètre Name: $nameValue" -ForegroundColor Gray

    # Essayer d'extraire la valeur du paramètre Path
    $pathValue = Get-ParameterValue -CommandAst $call -ParameterName "Path"
    Write-Host "    Valeur du paramètre Path: $pathValue" -ForegroundColor Gray

    Write-Host ""
}

# Test 4: Créer la gestion des paramètres avec caractères spéciaux
Write-Host "`nTest 4: Créer la gestion des paramètres avec caractères spéciaux" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green

    # Vérifier si le paramètre Name contient des caractères spéciaux
    $hasSpecialChars = Test-SpecialCharactersInParameter -CommandAst $call -ParameterName "Name"
    Write-Host "    Le paramètre Name contient des caractères spéciaux: $hasSpecialChars" -ForegroundColor Gray

    Write-Host ""
}

# Test 5: Développer la détection des paramètres optionnels
Write-Host "`nTest 5: Développer la détection des paramètres optionnels" -ForegroundColor Cyan
foreach ($call in $importModuleCalls) {
    Write-Host "  Commande: $($call.Extent.Text)" -ForegroundColor Green

    # Obtenir les paramètres optionnels
    $optionalParams = Get-OptionalParameters -CommandAst $call
    Write-Host "    Paramètres optionnels: $($optionalParams -join ', ')" -ForegroundColor Gray

    Write-Host ""
}

Write-Host "Tests terminés avec succès!" -ForegroundColor Green
