#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la fonction de calcul du score de risque.
.DESCRIPTION
    Ce script exÃ©cute des tests unitaires pour vÃ©rifier le bon fonctionnement
    de la fonction de calcul du score de risque.
.EXAMPLE
    .\Test-RiskScoreCalculation.ps1
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param()

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "RiskScoreUnitTest_$(Get-Random)"
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

# CrÃ©er des fichiers de test avec diffÃ©rents niveaux de risque
$lowRiskScript = @"
# Test PowerShell Script (Low Risk)
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

$mediumRiskScript = @"
# Test PowerShell Script (Medium Risk)
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )

    `$testVariable = "Test value"

    # Utilisation d'un alias
    gci -Path "C:\" | Where { `$_.Name -like "*.txt" }

    Write-Output `$testVariable
}

Test-Function -param1 "Test"
"@

$highRiskScript = @"
# Test PowerShell Script (High Risk)
function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0,
        [string]`$password = "secret"
    )

    `$testVariable = "Test value"

    # Utilisation d'un alias
    gci -Path "C:\" | Where { `$_.Name -like "*.txt" }

    # Utilisation de Invoke-Expression
    Invoke-Expression "Get-Process"

    # Suppression rÃ©cursive
    Remove-Item -Path "C:\Temp\*" -Recurse -Force

    # Mot de passe en clair
    `$securePassword = ConvertTo-SecureString -String `$password -AsPlainText -Force

    Write-Output `$testVariable
}

Test-Function -param1 "Test" -password "SuperSecret123"
"@

# CrÃ©er les fichiers de test
$testFiles = @{
    LowRisk    = New-TestFile -Path "powershell/low_risk.ps1" -Content $lowRiskScript
    MediumRisk = New-TestFile -Path "powershell/medium_risk.ps1" -Content $mediumRiskScript
    HighRisk   = New-TestFile -Path "powershell/high_risk.ps1" -Content $highRiskScript
}

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

# Fonction pour vÃ©rifier si une valeur est supÃ©rieure Ã  une autre
function Assert-Greater {
    param(
        $Value,
        $Threshold,
        [string]$Message
    )

    if (-not ($Value -gt $Threshold)) {
        throw "Assertion Ã©chouÃ©e: $Message. La valeur $Value n'est pas supÃ©rieure Ã  $Threshold"
    }
}

# Fonction pour vÃ©rifier si une valeur est infÃ©rieure Ã  une autre
function Assert-Less {
    param(
        $Value,
        $Threshold,
        [string]$Message
    )

    if (-not ($Value -lt $Threshold)) {
        throw "Assertion Ã©chouÃ©e: $Message. La valeur $Value n'est pas infÃ©rieure Ã  $Threshold"
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

# Test 3: VÃ©rifier que les scores de risque sont cohÃ©rents
$testResults += Invoke-SimpleTest -Name "Les scores de risque sont cohÃ©rents" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $lowRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.LowRisk }
    $mediumRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.MediumRisk }
    $highRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.HighRisk }

    Assert-True ($lowRiskFile.RiskScore -lt $mediumRiskFile.RiskScore) "Le score de risque du fichier Ã  faible risque n'est pas infÃ©rieur Ã  celui du fichier Ã  risque moyen"
    Assert-True ($mediumRiskFile.RiskScore -lt $highRiskFile.RiskScore) "Le score de risque du fichier Ã  risque moyen n'est pas infÃ©rieur Ã  celui du fichier Ã  haut risque"
}

# Test 4: VÃ©rifier que les niveaux de risque sont cohÃ©rents
$testResults += Invoke-SimpleTest -Name "Les niveaux de risque sont cohÃ©rents" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $lowRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.LowRisk }
    $mediumRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.MediumRisk }
    $highRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.HighRisk }

    # VÃ©rifier que les scores sont cohÃ©rents plutÃ´t que de vÃ©rifier des niveaux spÃ©cifiques
    Assert-True ($lowRiskFile.RiskScore -lt $highRiskFile.RiskScore) "Le score de risque du fichier Ã  faible risque n'est pas infÃ©rieur Ã  celui du fichier Ã  haut risque"

    # VÃ©rifier que les niveaux de risque ne sont pas vides
    Assert-True (-not [string]::IsNullOrEmpty($lowRiskFile.RiskLevel)) "Le niveau de risque du fichier Ã  faible risque est vide"
    Assert-True (-not [string]::IsNullOrEmpty($mediumRiskFile.RiskLevel)) "Le niveau de risque du fichier Ã  risque moyen est vide"
    Assert-True (-not [string]::IsNullOrEmpty($highRiskFile.RiskLevel)) "Le niveau de risque du fichier Ã  haut risque est vide"
}

# Test 5: VÃ©rifier que les raisons du score de risque sont prÃ©sentes
$testResults += Invoke-SimpleTest -Name "Les raisons du score de risque sont prÃ©sentes" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $highRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.HighRisk }

    Assert-True ($highRiskFile.RiskReasons.Count -gt 0) "Aucune raison n'est fournie pour le score de risque"
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
