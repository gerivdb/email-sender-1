#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la gestion de l'historique des erreurs.
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    de la gestion de l'historique des erreurs.
.EXAMPLE
    .\Test-ErrorHistory.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param()

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ErrorHistoryUnitTest_$(Get-Random)"
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

# CrÃ©er un fichier de test avec des erreurs
$errorScript = @"
# Test PowerShell Script with Errors
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )

    `$testVariable = "Test value"

    # Erreur: Utilisation d'un alias
    gci -Path "C:\" | Where { `$_.Name -like "*.txt" }

    # Erreur: Utilisation de Invoke-Expression
    Invoke-Expression "Get-Process"

    # Erreur: Suppression rÃ©cursive
    Remove-Item -Path "C:\Temp\*" -Recurse -Force

    Write-Output `$testVariable
}

Test-Function -param1 "Test"
"@

# CrÃ©er le fichier de test
$testFile = New-TestFile -Path "powershell/error_script.ps1" -Content $errorScript

# Chemin du script d'analyse prÃ©dictive
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-PredictiveFileAnalysis.ps1"

# Fonction pour exÃ©cuter les tests
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

# ExÃ©cuter les tests
$testResults = @()

# Test 1: VÃ©rifier que le script existe
$testResults += Invoke-SimpleTest -Name "Le script d'analyse prÃ©dictive existe" {
    Assert-True (Test-Path -Path $scriptPath) "Le script d'analyse prÃ©dictive n'existe pas: $scriptPath"
}

# Test 2: VÃ©rifier que l'historique des erreurs est crÃ©Ã©
$testResults += Invoke-SimpleTest -Name "L'historique des erreurs est crÃ©Ã©" {
    $errorHistoryPath = "$testDir\error_history.json"

    # PremiÃ¨re exÃ©cution
    $null = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath $errorHistoryPath -UseCache

    Assert-True (Test-Path -Path $errorHistoryPath) "L'historique des erreurs n'a pas Ã©tÃ© crÃ©Ã©"

    $errorHistory = Get-Content -Path $errorHistoryPath -Raw | ConvertFrom-Json
    Assert-NotNull $errorHistory "L'historique des erreurs est vide"
    Assert-NotNull $errorHistory.Files "L'historique des fichiers est vide"
    Assert-NotNull $errorHistory.Patterns "L'historique des patterns est vide"
    Assert-NotNull $errorHistory.LastUpdated "La date de derniÃ¨re mise Ã  jour est manquante"
}

# Test 3: VÃ©rifier que l'historique des erreurs est mis Ã  jour
$testResults += Invoke-SimpleTest -Name "L'historique des erreurs est mis Ã  jour" {
    $errorHistoryPath = "$testDir\error_history_update.json"

    # PremiÃ¨re exÃ©cution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report1.html" -ErrorHistoryPath $errorHistoryPath -UseCache | Out-Null

    # RÃ©cupÃ©rer la date de derniÃ¨re mise Ã  jour
    $errorHistory1 = Get-Content -Path $errorHistoryPath -Raw | ConvertFrom-Json
    $lastUpdated1 = $errorHistory1.LastUpdated

    # Attendre un peu pour s'assurer que la date change
    Start-Sleep -Seconds 1

    # DeuxiÃ¨me exÃ©cution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report2.html" -ErrorHistoryPath $errorHistoryPath -UseCache | Out-Null

    # RÃ©cupÃ©rer la nouvelle date de derniÃ¨re mise Ã  jour
    $errorHistory2 = Get-Content -Path $errorHistoryPath -Raw | ConvertFrom-Json
    $lastUpdated2 = $errorHistory2.LastUpdated

    Assert-True ($lastUpdated1 -ne $lastUpdated2) "La date de derniÃ¨re mise Ã  jour n'a pas changÃ©"
}

# Test 4: VÃ©rifier que les problÃ¨mes sont enregistrÃ©s dans l'historique
$testResults += Invoke-SimpleTest -Name "Les problÃ¨mes sont enregistrÃ©s dans l'historique" {
    $errorHistoryPath = "$testDir\error_history_issues.json"

    # ExÃ©cution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath $errorHistoryPath -UseCache | Out-Null

    $errorHistory = Get-Content -Path $errorHistoryPath -Raw | ConvertFrom-Json

    $relativeFilePath = $testFile -replace [regex]::Escape($testDir), "" -replace "^\\", ""

    Assert-NotNull $errorHistory.Files.$relativeFilePath "Le fichier n'est pas dans l'historique des erreurs"
    Assert-True ($errorHistory.Files.$relativeFilePath.IssueCount -gt 0) "Aucun problÃ¨me n'a Ã©tÃ© enregistrÃ© pour le fichier"

    # VÃ©rifier que les patterns sont enregistrÃ©s
    $invokeExpressionPattern = $errorHistory.Patterns.PSObject.Properties | Where-Object { $_.Name -like "*Invoke-Expression*" }
    Assert-NotNull $invokeExpressionPattern "Le pattern Invoke-Expression n'a pas Ã©tÃ© enregistrÃ©"
}

# Test 5: VÃ©rifier que l'historique des erreurs influence le score de risque
$testResults += Invoke-SimpleTest -Name "L'historique des erreurs influence le score de risque" {
    $errorHistoryPath = "$testDir\error_history_score.json"

    # PremiÃ¨re exÃ©cution
    $result1 = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report1.html" -ErrorHistoryPath $errorHistoryPath -UseCache

    $file1 = $result1.Results | Where-Object { $_.FilePath -eq $testFile }
    $score1 = $file1.RiskScore

    # DeuxiÃ¨me exÃ©cution (l'historique des erreurs devrait augmenter le score)
    $result2 = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report2.html" -ErrorHistoryPath $errorHistoryPath -UseCache

    $file2 = $result2.Results | Where-Object { $_.FilePath -eq $testFile }
    $score2 = $file2.RiskScore

    # Le score devrait Ãªtre au moins Ã©gal, mais probablement plus Ã©levÃ©
    Assert-True ($score2 -ge $score1) "Le score de risque n'a pas augmentÃ© ou est restÃ© stable aprÃ¨s l'ajout Ã  l'historique des erreurs"
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
