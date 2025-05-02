#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la détection des variables globales spécifiques à des modules.

.DESCRIPTION
    Ce script teste la fonction Find-GlobalVariableWithoutExplicitImport du module ImplicitModuleDependencyDetector
    qui détecte les variables globales spécifiques à des modules dans les scripts PowerShell.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ImplicitModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# Créer un script PowerShell de test avec différentes références à des variables globales
$sampleCode = @'
# Script avec des références à des variables globales de différents modules

# Variables PowerShell Core
Write-Host "PowerShell Version: $PSVersionTable"
Write-Host "PowerShell Edition: $PSEdition"
Write-Host "Script Root: $PSScriptRoot"

# Import explicite du module ActiveDirectory
Import-Module ActiveDirectory

# Références à des variables Active Directory
$settings = $ADServerSettings
$sessionSettings = $ADSessionSettings

# Références à des variables Azure sans import
$context = $AzContext
$profile = $AzProfile
$location = $AzDefaultLocation

# Import explicite du module SqlServer
Import-Module SqlServer

# Références à des variables SQL Server
$errorLevel = $SqlServerMaximumErrorLevel
$timeout = $SqlServerConnectionTimeout

# Références à des variables Pester sans import
$config = $PesterPreference
$state = $PesterState

# Références à des variables dbatools sans import
$config = $DbatoolsConfig
$installRoot = $DbatoolsInstallRoot
$path = $DbatoolsPath

# Références à des variables ImportExcel sans import
$folder = $ExcelPackageFolder
$format = $ExcelDefaultXlsxFormat
$numberFormat = $ExcelDefaultNumberFormat
'@

Write-Host "=== Test de la détection des variables globales spécifiques à des modules ===" -ForegroundColor Cyan

# Test 1: Détecter les variables globales sans import explicite
Write-Host "`nTest 1: Détecter les variables globales sans import explicite" -ForegroundColor Cyan
$results = Find-GlobalVariableWithoutExplicitImport -ScriptContent $sampleCode

Write-Host "  Variables globales détectées sans import explicite:" -ForegroundColor Green
foreach ($result in $results) {
    Write-Host "    $($result.VariableName) (Module: $($result.ModuleName)) - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 2: Détecter toutes les variables globales, y compris celles des modules importés
Write-Host "`nTest 2: Détecter toutes les variables globales, y compris celles des modules importés" -ForegroundColor Cyan
$allResults = Find-GlobalVariableWithoutExplicitImport -ScriptContent $sampleCode -IncludeImportedModules

Write-Host "  Toutes les variables globales détectées:" -ForegroundColor Green
foreach ($result in $allResults) {
    $importStatus = if ($result.IsImported) { "Module importé" } else { "Module non importé" }
    Write-Host "    $($result.VariableName) (Module: $($result.ModuleName)) - $importStatus - Ligne $($result.LineNumber)" -ForegroundColor Gray
}

# Test 3: Vérifier la détection des imports explicites
Write-Host "`nTest 3: Vérifier la détection des imports explicites" -ForegroundColor Cyan
$importedModules = $allResults | Where-Object { $_.IsImported } | Select-Object -ExpandProperty ModuleName -Unique
$nonImportedModules = $allResults | Where-Object { -not $_.IsImported } | Select-Object -ExpandProperty ModuleName -Unique

Write-Host "  Modules importés explicitement:" -ForegroundColor Green
foreach ($module in $importedModules) {
    Write-Host "    $module" -ForegroundColor Gray
}

Write-Host "  Modules non importés:" -ForegroundColor Green
foreach ($module in $nonImportedModules) {
    Write-Host "    $module" -ForegroundColor Gray
}

# Test 4: Vérifier les variables PowerShell Core
Write-Host "`nTest 4: Vérifier les variables PowerShell Core" -ForegroundColor Cyan
$psVariables = $allResults | Where-Object { $_.ModuleName -eq "Microsoft.PowerShell.Core" }

Write-Host "  Variables PowerShell Core détectées:" -ForegroundColor Green
foreach ($var in $psVariables) {
    Write-Host "    $($var.VariableName) - Ligne $($var.LineNumber)" -ForegroundColor Gray
}

Write-Host "`nTests terminés avec succès!" -ForegroundColor Green
