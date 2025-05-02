#Requires -Version 5.1

# Importer les modules à tester
$moduleRoot = Split-Path -Parent $PSScriptRoot
$functionCallParserPath = Join-Path -Path $moduleRoot -ChildPath "FunctionCallParser.psm1"
$importedFunctionDetectorPath = Join-Path -Path $moduleRoot -ChildPath "ImportedFunctionDetector.psm1"
$functionDependencyAnalyzerPath = Join-Path -Path $moduleRoot -ChildPath "FunctionDependencyAnalyzer.psm1"

Write-Host "Module root: $moduleRoot"
Write-Host "FunctionCallParser path: $functionCallParserPath"
Write-Host "ImportedFunctionDetector path: $importedFunctionDetectorPath"
Write-Host "FunctionDependencyAnalyzer path: $functionDependencyAnalyzerPath"

if (-not (Test-Path -Path $functionCallParserPath)) {
    throw "Le module FunctionCallParser.psm1 n'existe pas dans le chemin spécifié: $functionCallParserPath"
}

if (-not (Test-Path -Path $importedFunctionDetectorPath)) {
    throw "Le module ImportedFunctionDetector.psm1 n'existe pas dans le chemin spécifié: $importedFunctionDetectorPath"
}

if (-not (Test-Path -Path $functionDependencyAnalyzerPath)) {
    throw "Le module FunctionDependencyAnalyzer.psm1 n'existe pas dans le chemin spécifié: $functionDependencyAnalyzerPath"
}

Import-Module -Name $functionCallParserPath -Force -Verbose
Import-Module -Name $importedFunctionDetectorPath -Force -Verbose
Import-Module -Name $functionDependencyAnalyzerPath -Force -Verbose

# Créer un script de test
$testScriptContent = @'
#Requires -Modules Microsoft.PowerShell.Management

<#
.SYNOPSIS
    Script de test.
#>

# Importer les modules requis
Import-Module -Name Microsoft.PowerShell.Utility

# Définir une fonction locale
function Get-LocalData {
    [CmdletBinding()]
    param()

    Write-Output "Local Data"
}

# Appeler des fonctions importées
Get-Process
Write-Host "Hello, World!"

# Appeler une fonction locale
Get-LocalData

# Appeler une fonction non importée
Get-Service
'@

# Test 1: Get-FunctionCalls
Write-Host "Test 1: Get-FunctionCalls" -ForegroundColor Cyan
$functionCalls = Get-FunctionCalls -ScriptContent $testScriptContent
Write-Host "Appels de fonctions trouvés: $($functionCalls.Count)" -ForegroundColor Yellow
foreach ($call in $functionCalls) {
    Write-Host "  - $($call.Name) (Type: $($call.Type), Ligne: $($call.Line))" -ForegroundColor Green
}

# Test 2: Get-LocalFunctions
Write-Host "`nTest 2: Get-LocalFunctions" -ForegroundColor Cyan
$localFunctions = Get-LocalFunctions -ScriptContent $testScriptContent
Write-Host "Fonctions locales trouvées: $($localFunctions.Count)" -ForegroundColor Yellow
foreach ($function in $localFunctions) {
    Write-Host "  - $($function.Name) (Ligne: $($function.Line))" -ForegroundColor Green
}

# Test 3: Get-ImportedModules
Write-Host "`nTest 3: Get-ImportedModules" -ForegroundColor Cyan
$importedModules = Get-ImportedModules -ScriptContent $testScriptContent -IncludeRequiresDirectives
Write-Host "Modules importés trouvés: $($importedModules.Count)" -ForegroundColor Yellow
foreach ($module in $importedModules) {
    Write-Host "  - $($module.Name) (Type: $($module.Type), Ligne: $($module.Line))" -ForegroundColor Green
}

# Test 4: Get-NonImportedFunctionCalls
Write-Host "`nTest 4: Get-NonImportedFunctionCalls" -ForegroundColor Cyan
$nonImportedFunctionCalls = Get-NonImportedFunctionCalls -ScriptContent $testScriptContent
Write-Host "Appels de fonctions non importées trouvés: $($nonImportedFunctionCalls.Count)" -ForegroundColor Yellow
foreach ($call in $nonImportedFunctionCalls) {
    Write-Host "  - $($call.Name) (Type: $($call.Type), Ligne: $($call.Line))" -ForegroundColor Green
}

# Test 5: Resolve-ModulesForFunctions
Write-Host "`nTest 5: Resolve-ModulesForFunctions" -ForegroundColor Cyan
$resolvedModules = Resolve-ModulesForFunctions -FunctionNames @("Get-Process", "Get-Service")
Write-Host "Modules résolus trouvés: $($resolvedModules.Count)" -ForegroundColor Yellow
foreach ($module in $resolvedModules) {
    Write-Host "  - $($module.FunctionName) -> $($module.ModuleName) (Version: $($module.ModuleVersion))" -ForegroundColor Green
}

# Test 6: Get-FunctionDependencies
Write-Host "`nTest 6: Get-FunctionDependencies" -ForegroundColor Cyan
$dependencies = Get-FunctionDependencies -ScriptContent $testScriptContent -ResolveModules
Write-Host "Modules importés: $($dependencies.ImportedModules.Count)" -ForegroundColor Yellow
Write-Host "Appels de fonctions non importées: $($dependencies.NonImportedFunctionCalls.Count)" -ForegroundColor Yellow
Write-Host "Modules résolus: $($dependencies.ResolvedModules.Count)" -ForegroundColor Yellow
Write-Host "Modules manquants: $($dependencies.MissingModules.Count)" -ForegroundColor Yellow

Write-Host "`nTous les tests ont été exécutés avec succès !" -ForegroundColor Green
