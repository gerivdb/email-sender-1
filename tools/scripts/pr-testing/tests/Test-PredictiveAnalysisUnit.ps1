#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le systÃ¨me d'analyse prÃ©dictive.
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    du systÃ¨me d'analyse prÃ©dictive.
.EXAMPLE
    .\Test-PredictiveAnalysisUnit.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param()

# Importer Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    } catch {
        Write-Error "Impossible d'installer Pester. Les tests seront exÃ©cutÃ©s sans Pester."
    }
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PredictiveAnalysisUnitTest_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Fonction pour crÃ©er des fichiers de test
function New-TestFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $fullPath = Join-Path -Path $testDir -ChildPath $Path
    $directory = Split-Path -Path $fullPath -Parent

    if (-not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    return $fullPath
}

# CrÃ©er des fichiers de test
$psScriptSafe = @"
# Test PowerShell Script (Safe)
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )

    `$testVariable = "Test value"
    Write-Output `$testVariable
}

Test-Function -param1 "Test" -param2 42
"@

$psScriptRisky = @"
# Test PowerShell Script (Risky)
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )

    `$testVariable = "Test value"

    # Utilisation d'un alias
    gci -Path "C:\" | Where { `$_.Name -like "*.txt" }

    # Utilisation de Invoke-Expression
    Invoke-Expression "Get-Process"

    # Suppression rÃ©cursive
    Remove-Item -Path "C:\Temp\*" -Recurse -Force

    Write-Output `$testVariable
}

Test-Function -param1 "Test"
"@

# CrÃ©er les fichiers de test
$testFiles = @{
    Safe  = New-TestFile -Path "powershell/test_safe.ps1" -Content $psScriptSafe
    Risky = New-TestFile -Path "powershell/test_risky.ps1" -Content $psScriptRisky
}

# Chemin du script d'analyse prÃ©dictive
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-PredictiveFileAnalysis.ps1"

# Fonction pour exÃ©cuter les tests sans Pester
function Invoke-SimpleTest {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    Write-Host "Test: $Name" -ForegroundColor Cyan

    try {
        & $Test
        Write-Host "  RÃ©ussi" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Ã‰chouÃ©: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour vÃ©rifier si une condition est vraie
function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "Assertion Ã©chouÃ©e: $Message"
    }
}

# Fonction pour vÃ©rifier si deux valeurs sont Ã©gales
function Assert-Equal {
    param(
        $Expected,
        $Actual,
        [string]$Message
    )

    if ($Expected -ne $Actual) {
        throw "Assertion Ã©chouÃ©e: $Message. Attendu: $Expected, Obtenu: $Actual"
    }
}

# Fonction pour vÃ©rifier si une valeur est nulle
function Assert-Null {
    param(
        $Value,
        [string]$Message
    )

    if ($null -ne $Value) {
        throw "Assertion Ã©chouÃ©e: $Message. La valeur n'est pas nulle: $Value"
    }
}

# Fonction pour vÃ©rifier si une valeur n'est pas nulle
function Assert-NotNull {
    param(
        $Value,
        [string]$Message
    )

    if ($null -eq $Value) {
        throw "Assertion Ã©chouÃ©e: $Message. La valeur est nulle"
    }
}

# Fonction pour vÃ©rifier si une collection contient un Ã©lÃ©ment
function Assert-Contains {
    param(
        $Collection,
        $Item,
        [string]$Message
    )

    if ($Collection -notcontains $Item) {
        throw "Assertion Ã©chouÃ©e: $Message. La collection ne contient pas l'Ã©lÃ©ment: $Item"
    }
}

# Fonction pour vÃ©rifier si une chaÃ®ne contient une sous-chaÃ®ne
function Assert-StringContains {
    param(
        [string]$String,
        [string]$Substring,
        [string]$Message
    )

    if ($String -notlike "*$Substring*") {
        throw "Assertion Ã©chouÃ©e: $Message. La chaÃ®ne ne contient pas la sous-chaÃ®ne: $Substring"
    }
}

# ExÃ©cuter les tests
$testResults = @()

# Test 1: VÃ©rifier que le script existe
$testResults += Invoke-SimpleTest -Name "Le script d'analyse prÃ©dictive existe" {
    Assert-True (Test-Path -Path $scriptPath) "Le script d'analyse prÃ©dictive n'existe pas: $scriptPath"
}

# Test 2: VÃ©rifier que le script peut Ãªtre exÃ©cutÃ©
$testResults += Invoke-SimpleTest -Name "Le script d'analyse prÃ©dictive peut Ãªtre exÃ©cutÃ©" {
    $null = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache
    Assert-True (Test-Path -Path "$testDir\report.html") "Le rapport n'a pas Ã©tÃ© gÃ©nÃ©rÃ©"
}

# Test 3: VÃ©rifier que le script dÃ©tecte les problÃ¨mes dans les fichiers risquÃ©s
$testResults += Invoke-SimpleTest -Name "Le script dÃ©tecte les problÃ¨mes dans les fichiers risquÃ©s" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $riskyFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.Risky }
    Assert-NotNull $riskyFile "Le fichier risquÃ© n'a pas Ã©tÃ© analysÃ©"
    Assert-True ($riskyFile.Issues.Count -gt 0) "Aucun problÃ¨me n'a Ã©tÃ© dÃ©tectÃ© dans le fichier risquÃ©"

    $invokeExpressionIssue = $riskyFile.Issues | Where-Object { $_.Message -like "*Invoke-Expression*" }
    Assert-NotNull $invokeExpressionIssue "Le problÃ¨me Invoke-Expression n'a pas Ã©tÃ© dÃ©tectÃ©"
}

# Test 4: VÃ©rifier que le script calcule correctement le score de risque
$testResults += Invoke-SimpleTest -Name "Le script calcule correctement le score de risque" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $safeFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.Safe }
    $riskyFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.Risky }

    Assert-NotNull $safeFile "Le fichier sÃ»r n'a pas Ã©tÃ© analysÃ©"
    Assert-NotNull $riskyFile "Le fichier risquÃ© n'a pas Ã©tÃ© analysÃ©"

    Assert-True ($riskyFile.RiskScore -gt $safeFile.RiskScore) "Le score de risque du fichier risquÃ© n'est pas supÃ©rieur Ã  celui du fichier sÃ»r"
}

# Test 5: VÃ©rifier que le script met Ã  jour l'historique des erreurs
$testResults += Invoke-SimpleTest -Name "Le script met Ã  jour l'historique des erreurs" {
    # PremiÃ¨re exÃ©cution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report1.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache | Out-Null

    # DeuxiÃ¨me exÃ©cution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report2.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache | Out-Null

    Assert-True (Test-Path -Path "$testDir\error_history.json") "L'historique des erreurs n'a pas Ã©tÃ© crÃ©Ã©"

    $errorHistory = Get-Content -Path "$testDir\error_history.json" -Raw | ConvertFrom-Json
    Assert-NotNull $errorHistory "L'historique des erreurs est vide"
    Assert-NotNull $errorHistory.Files "L'historique des fichiers est vide"

    $relativeRiskyPath = $testFiles.Risky -replace [regex]::Escape($testDir), "" -replace "^\\", ""
    Assert-NotNull $errorHistory.Files.$relativeRiskyPath "Le fichier risquÃ© n'est pas dans l'historique des erreurs"
}

# Afficher un rÃ©sumÃ© des tests
$successCount = ($testResults | Where-Object { $_ -eq $true }).Count
$failureCount = ($testResults | Where-Object { $_ -eq $false }).Count
$totalCount = $testResults.Count

Write-Host ""
Write-Host "RÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests rÃ©ussis: $successCount" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $failureCount" -ForegroundColor Red
Write-Host "  Total: $totalCount" -ForegroundColor White
Write-Host ""

# Nettoyer
Write-Host "Nettoyage..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  RÃ©pertoire de test supprimÃ©" -ForegroundColor Green
Write-Host ""

# Retourner le rÃ©sultat global
$success = $failureCount -eq 0
Write-Host "RÃ©sultat global: $(if ($success) { "SuccÃ¨s" } else { "Ã‰chec" })" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
exit $(if ($success) { 0 } else { 1 })
