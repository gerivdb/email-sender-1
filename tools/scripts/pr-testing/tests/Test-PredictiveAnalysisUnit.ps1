#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le système d'analyse prédictive.
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
    du système d'analyse prédictive.
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
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    } catch {
        Write-Error "Impossible d'installer Pester. Les tests seront exécutés sans Pester."
    }
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PredictiveAnalysisUnitTest_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Fonction pour créer des fichiers de test
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

# Créer des fichiers de test
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

    # Suppression récursive
    Remove-Item -Path "C:\Temp\*" -Recurse -Force

    Write-Output `$testVariable
}

Test-Function -param1 "Test"
"@

# Créer les fichiers de test
$testFiles = @{
    Safe  = New-TestFile -Path "powershell/test_safe.ps1" -Content $psScriptSafe
    Risky = New-TestFile -Path "powershell/test_risky.ps1" -Content $psScriptRisky
}

# Chemin du script d'analyse prédictive
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-PredictiveFileAnalysis.ps1"

# Fonction pour exécuter les tests sans Pester
function Invoke-SimpleTest {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    Write-Host "Test: $Name" -ForegroundColor Cyan

    try {
        & $Test
        Write-Host "  Réussi" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Échoué: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour vérifier si une condition est vraie
function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "Assertion échouée: $Message"
    }
}

# Fonction pour vérifier si deux valeurs sont égales
function Assert-Equal {
    param(
        $Expected,
        $Actual,
        [string]$Message
    )

    if ($Expected -ne $Actual) {
        throw "Assertion échouée: $Message. Attendu: $Expected, Obtenu: $Actual"
    }
}

# Fonction pour vérifier si une valeur est nulle
function Assert-Null {
    param(
        $Value,
        [string]$Message
    )

    if ($null -ne $Value) {
        throw "Assertion échouée: $Message. La valeur n'est pas nulle: $Value"
    }
}

# Fonction pour vérifier si une valeur n'est pas nulle
function Assert-NotNull {
    param(
        $Value,
        [string]$Message
    )

    if ($null -eq $Value) {
        throw "Assertion échouée: $Message. La valeur est nulle"
    }
}

# Fonction pour vérifier si une collection contient un élément
function Assert-Contains {
    param(
        $Collection,
        $Item,
        [string]$Message
    )

    if ($Collection -notcontains $Item) {
        throw "Assertion échouée: $Message. La collection ne contient pas l'élément: $Item"
    }
}

# Fonction pour vérifier si une chaîne contient une sous-chaîne
function Assert-StringContains {
    param(
        [string]$String,
        [string]$Substring,
        [string]$Message
    )

    if ($String -notlike "*$Substring*") {
        throw "Assertion échouée: $Message. La chaîne ne contient pas la sous-chaîne: $Substring"
    }
}

# Exécuter les tests
$testResults = @()

# Test 1: Vérifier que le script existe
$testResults += Invoke-SimpleTest -Name "Le script d'analyse prédictive existe" {
    Assert-True (Test-Path -Path $scriptPath) "Le script d'analyse prédictive n'existe pas: $scriptPath"
}

# Test 2: Vérifier que le script peut être exécuté
$testResults += Invoke-SimpleTest -Name "Le script d'analyse prédictive peut être exécuté" {
    $null = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache
    Assert-True (Test-Path -Path "$testDir\report.html") "Le rapport n'a pas été généré"
}

# Test 3: Vérifier que le script détecte les problèmes dans les fichiers risqués
$testResults += Invoke-SimpleTest -Name "Le script détecte les problèmes dans les fichiers risqués" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $riskyFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.Risky }
    Assert-NotNull $riskyFile "Le fichier risqué n'a pas été analysé"
    Assert-True ($riskyFile.Issues.Count -gt 0) "Aucun problème n'a été détecté dans le fichier risqué"

    $invokeExpressionIssue = $riskyFile.Issues | Where-Object { $_.Message -like "*Invoke-Expression*" }
    Assert-NotNull $invokeExpressionIssue "Le problème Invoke-Expression n'a pas été détecté"
}

# Test 4: Vérifier que le script calcule correctement le score de risque
$testResults += Invoke-SimpleTest -Name "Le script calcule correctement le score de risque" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $safeFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.Safe }
    $riskyFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.Risky }

    Assert-NotNull $safeFile "Le fichier sûr n'a pas été analysé"
    Assert-NotNull $riskyFile "Le fichier risqué n'a pas été analysé"

    Assert-True ($riskyFile.RiskScore -gt $safeFile.RiskScore) "Le score de risque du fichier risqué n'est pas supérieur à celui du fichier sûr"
}

# Test 5: Vérifier que le script met à jour l'historique des erreurs
$testResults += Invoke-SimpleTest -Name "Le script met à jour l'historique des erreurs" {
    # Première exécution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report1.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache | Out-Null

    # Deuxième exécution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report2.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache | Out-Null

    Assert-True (Test-Path -Path "$testDir\error_history.json") "L'historique des erreurs n'a pas été créé"

    $errorHistory = Get-Content -Path "$testDir\error_history.json" -Raw | ConvertFrom-Json
    Assert-NotNull $errorHistory "L'historique des erreurs est vide"
    Assert-NotNull $errorHistory.Files "L'historique des fichiers est vide"

    $relativeRiskyPath = $testFiles.Risky -replace [regex]::Escape($testDir), "" -replace "^\\", ""
    Assert-NotNull $errorHistory.Files.$relativeRiskyPath "Le fichier risqué n'est pas dans l'historique des erreurs"
}

# Afficher un résumé des tests
$successCount = ($testResults | Where-Object { $_ -eq $true }).Count
$failureCount = ($testResults | Where-Object { $_ -eq $false }).Count
$totalCount = $testResults.Count

Write-Host ""
Write-Host "Résumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests réussis: $successCount" -ForegroundColor Green
Write-Host "  Tests échoués: $failureCount" -ForegroundColor Red
Write-Host "  Total: $totalCount" -ForegroundColor White
Write-Host ""

# Nettoyer
Write-Host "Nettoyage..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  Répertoire de test supprimé" -ForegroundColor Green
Write-Host ""

# Retourner le résultat global
$success = $failureCount -eq 0
Write-Host "Résultat global: $(if ($success) { "Succès" } else { "Échec" })" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
exit $(if ($success) { 0 } else { 1 })
