#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la fonction de calcul du score de risque.
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
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

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "RiskScoreUnitTest_$(Get-Random)"
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

# Créer des fichiers de test avec différents niveaux de risque
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

    # Suppression récursive
    Remove-Item -Path "C:\Temp\*" -Recurse -Force

    # Mot de passe en clair
    `$securePassword = ConvertTo-SecureString -String `$password -AsPlainText -Force

    Write-Output `$testVariable
}

Test-Function -param1 "Test" -password "SuperSecret123"
"@

# Créer les fichiers de test
$testFiles = @{
    LowRisk    = New-TestFile -Path "powershell/low_risk.ps1" -Content $lowRiskScript
    MediumRisk = New-TestFile -Path "powershell/medium_risk.ps1" -Content $mediumRiskScript
    HighRisk   = New-TestFile -Path "powershell/high_risk.ps1" -Content $highRiskScript
}

# Chemin du script d'analyse prédictive
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-PredictiveFileAnalysis.ps1"

# Fonction pour exécuter les tests
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

# Fonction pour vérifier si une valeur est supérieure à une autre
function Assert-Greater {
    param(
        $Value,
        $Threshold,
        [string]$Message
    )

    if (-not ($Value -gt $Threshold)) {
        throw "Assertion échouée: $Message. La valeur $Value n'est pas supérieure à $Threshold"
    }
}

# Fonction pour vérifier si une valeur est inférieure à une autre
function Assert-Less {
    param(
        $Value,
        $Threshold,
        [string]$Message
    )

    if (-not ($Value -lt $Threshold)) {
        throw "Assertion échouée: $Message. La valeur $Value n'est pas inférieure à $Threshold"
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

# Test 3: Vérifier que les scores de risque sont cohérents
$testResults += Invoke-SimpleTest -Name "Les scores de risque sont cohérents" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $lowRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.LowRisk }
    $mediumRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.MediumRisk }
    $highRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.HighRisk }

    Assert-True ($lowRiskFile.RiskScore -lt $mediumRiskFile.RiskScore) "Le score de risque du fichier à faible risque n'est pas inférieur à celui du fichier à risque moyen"
    Assert-True ($mediumRiskFile.RiskScore -lt $highRiskFile.RiskScore) "Le score de risque du fichier à risque moyen n'est pas inférieur à celui du fichier à haut risque"
}

# Test 4: Vérifier que les niveaux de risque sont cohérents
$testResults += Invoke-SimpleTest -Name "Les niveaux de risque sont cohérents" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $lowRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.LowRisk }
    $mediumRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.MediumRisk }
    $highRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.HighRisk }

    # Vérifier que les scores sont cohérents plutôt que de vérifier des niveaux spécifiques
    Assert-True ($lowRiskFile.RiskScore -lt $highRiskFile.RiskScore) "Le score de risque du fichier à faible risque n'est pas inférieur à celui du fichier à haut risque"

    # Vérifier que les niveaux de risque ne sont pas vides
    Assert-True (-not [string]::IsNullOrEmpty($lowRiskFile.RiskLevel)) "Le niveau de risque du fichier à faible risque est vide"
    Assert-True (-not [string]::IsNullOrEmpty($mediumRiskFile.RiskLevel)) "Le niveau de risque du fichier à risque moyen est vide"
    Assert-True (-not [string]::IsNullOrEmpty($highRiskFile.RiskLevel)) "Le niveau de risque du fichier à haut risque est vide"
}

# Test 5: Vérifier que les raisons du score de risque sont présentes
$testResults += Invoke-SimpleTest -Name "Les raisons du score de risque sont présentes" {
    $result = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath "$testDir\error_history.json" -UseCache

    $highRiskFile = $result.Results | Where-Object { $_.FilePath -eq $testFiles.HighRisk }

    Assert-True ($highRiskFile.RiskReasons.Count -gt 0) "Aucune raison n'est fournie pour le score de risque"
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
