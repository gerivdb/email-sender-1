#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la dÃ©tection des variables globales spÃ©cifiques Ã  des modules.

.DESCRIPTION
    Ce script teste la fonction Find-GlobalVariableWithoutExplicitImport du module ImplicitModuleDependencyDetector
    qui dÃ©tecte les variables globales spÃ©cifiques Ã  des modules dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

# Importer le module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# CrÃ©er un script PowerShell de test avec diffÃ©rentes rÃ©fÃ©rences Ã  des variables globales
$sampleCode = @'
# Script avec des rÃ©fÃ©rences Ã  des variables globales de diffÃ©rents modules

# Variables PowerShell Core
Write-Host "PowerShell Version: $PSVersionTable"
Write-Host "PowerShell Edition: $PSEdition"
Write-Host "Script Root: $PSScriptRoot"

# Import explicite du module ActiveDirectory
Import-Module ActiveDirectory

# RÃ©fÃ©rences Ã  des variables Active Directory
$settings = $ADServerSettings
$sessionSettings = $ADSessionSettings

# RÃ©fÃ©rences Ã  des variables Azure sans import
$context = $AzContext
$profile = $AzProfile
$location = $AzDefaultLocation

# Import explicite du module SqlServer
Import-Module SqlServer

# RÃ©fÃ©rences Ã  des variables SQL Server
$errorLevel = $SqlServerMaximumErrorLevel
$timeout = $SqlServerConnectionTimeout

# RÃ©fÃ©rences Ã  des variables Pester sans import
$config = $PesterPreference
$state = $PesterState

# RÃ©fÃ©rences Ã  des variables dbatools sans import
$config = $DbatoolsConfig
$installRoot = $DbatoolsInstallRoot
$path = $DbatoolsPath

# RÃ©fÃ©rences Ã  des variables ImportExcel sans import
$folder = $ExcelPackageFolder
$format = $ExcelDefaultXlsxFormat
$numberFormat = $ExcelDefaultNumberFormat
'@

Write-Host "=== Test de la dÃ©tection des variables globales spÃ©cifiques Ã  des modules ===" -ForegroundColor Cyan

# Test 1: DÃ©tecter les variables globales sans import explicite
Write-Host "`nTest 1: DÃ©tecter les variables globales sans import explicite" -ForegroundColor Cyan
$results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $sampleCode

Write-Host "  Variables globales dÃ©tectÃ©es sans import explicite:" -ForegroundColor Green
foreach ($result in $results) {
    Write-Host "    $($result.VariableName) (Module: $($result.ModuleName)) - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 2: DÃ©tecter toutes les variables globales, y compris celles des modules importÃ©s
Write-Host "`nTest 2: DÃ©tecter toutes les variables globales, y compris celles des modules importÃ©s" -ForegroundColor Cyan
$allResults = Find-GlobalVariableWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

Write-Host "  Toutes les variables globales dÃ©tectÃ©es:" -ForegroundColor Green
foreach ($result in $allResults) {
    $importStatus = if ($result.IsImported) { "Module importÃ©" } else { "Module non importÃ©" }
    Write-Host "    $($result.VariableName) (Module: $($result.ModuleName)) - $importStatus - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 3: VÃ©rifier la dÃ©tection des imports explicites
Write-Host "`nTest 3: VÃ©rifier la dÃ©tection des imports explicites" -ForegroundColor Cyan
$importedModules = $allResults | Where-Object { $_.IsImported } | Select-Object -ExpandProperty ModuleName -Unique
$nonImportedModules = $allResults | Where-Object { -not $_.IsImported } | Select-Object -ExpandProperty ModuleName -Unique

Write-Host "  Modules importÃ©s explicitement:" -ForegroundColor Green
foreach ($module in $importedModules) {
    Write-Host "    $module" -ForegroundColor Gray
}

Write-Host "  Modules non importÃ©s:" -ForegroundColor Green
foreach ($module in $nonImportedModules) {
    Write-Host "    $module" -ForegroundColor Gray
}

# Test 4: VÃ©rifier les variables PowerShell Core
Write-Host "`nTest 4: VÃ©rifier les variables PowerShell Core" -ForegroundColor Cyan
$psVariables = $allResults | Where-Object { $_.ModuleName -eq "Microsoft.PowerShell.Core" }

Write-Host "  Variables PowerShell Core dÃ©tectÃ©es:" -ForegroundColor Green
foreach ($var in $psVariables) {
    Write-Host "    $($var.VariableName) - Ligne $($var.LineNumber)" -ForegroundColor Gray
}

Write-Host "`nTests terminÃ©s avec succÃ¨s!" -ForegroundColor Green
