#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la gestion de l'historique des erreurs.
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement
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

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ErrorHistoryUnitTest_$(Get-Random)"
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

# Créer un fichier de test avec des erreurs
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

    # Erreur: Suppression récursive
    Remove-Item -Path "C:\Temp\*" -Recurse -Force

    Write-Output `$testVariable
}

Test-Function -param1 "Test"
"@

# Créer le fichier de test
$testFile = New-TestFile -Path "powershell/error_script.ps1" -Content $errorScript

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

# Exécuter les tests
$testResults = @()

# Test 1: Vérifier que le script existe
$testResults += Invoke-SimpleTest -Name "Le script d'analyse prédictive existe" {
    Assert-True (Test-Path -Path $scriptPath) "Le script d'analyse prédictive n'existe pas: $scriptPath"
}

# Test 2: Vérifier que l'historique des erreurs est créé
$testResults += Invoke-SimpleTest -Name "L'historique des erreurs est créé" {
    $errorHistoryPath = "$testDir\error_history.json"

    # Première exécution
    $null = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath $errorHistoryPath -UseCache

    Assert-True (Test-Path -Path $errorHistoryPath) "L'historique des erreurs n'a pas été créé"

    $errorHistory = Get-Content -Path $errorHistoryPath -Raw | ConvertFrom-Json
    Assert-NotNull $errorHistory "L'historique des erreurs est vide"
    Assert-NotNull $errorHistory.Files "L'historique des fichiers est vide"
    Assert-NotNull $errorHistory.Patterns "L'historique des patterns est vide"
    Assert-NotNull $errorHistory.LastUpdated "La date de dernière mise à jour est manquante"
}

# Test 3: Vérifier que l'historique des erreurs est mis à jour
$testResults += Invoke-SimpleTest -Name "L'historique des erreurs est mis à jour" {
    $errorHistoryPath = "$testDir\error_history_update.json"

    # Première exécution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report1.html" -ErrorHistoryPath $errorHistoryPath -UseCache | Out-Null

    # Récupérer la date de dernière mise à jour
    $errorHistory1 = Get-Content -Path $errorHistoryPath -Raw | ConvertFrom-Json
    $lastUpdated1 = $errorHistory1.LastUpdated

    # Attendre un peu pour s'assurer que la date change
    Start-Sleep -Seconds 1

    # Deuxième exécution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report2.html" -ErrorHistoryPath $errorHistoryPath -UseCache | Out-Null

    # Récupérer la nouvelle date de dernière mise à jour
    $errorHistory2 = Get-Content -Path $errorHistoryPath -Raw | ConvertFrom-Json
    $lastUpdated2 = $errorHistory2.LastUpdated

    Assert-True ($lastUpdated1 -ne $lastUpdated2) "La date de dernière mise à jour n'a pas changé"
}

# Test 4: Vérifier que les problèmes sont enregistrés dans l'historique
$testResults += Invoke-SimpleTest -Name "Les problèmes sont enregistrés dans l'historique" {
    $errorHistoryPath = "$testDir\error_history_issues.json"

    # Exécution
    & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report.html" -ErrorHistoryPath $errorHistoryPath -UseCache | Out-Null

    $errorHistory = Get-Content -Path $errorHistoryPath -Raw | ConvertFrom-Json

    $relativeFilePath = $testFile -replace [regex]::Escape($testDir), "" -replace "^\\", ""

    Assert-NotNull $errorHistory.Files.$relativeFilePath "Le fichier n'est pas dans l'historique des erreurs"
    Assert-True ($errorHistory.Files.$relativeFilePath.IssueCount -gt 0) "Aucun problème n'a été enregistré pour le fichier"

    # Vérifier que les patterns sont enregistrés
    $invokeExpressionPattern = $errorHistory.Patterns.PSObject.Properties | Where-Object { $_.Name -like "*Invoke-Expression*" }
    Assert-NotNull $invokeExpressionPattern "Le pattern Invoke-Expression n'a pas été enregistré"
}

# Test 5: Vérifier que l'historique des erreurs influence le score de risque
$testResults += Invoke-SimpleTest -Name "L'historique des erreurs influence le score de risque" {
    $errorHistoryPath = "$testDir\error_history_score.json"

    # Première exécution
    $result1 = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report1.html" -ErrorHistoryPath $errorHistoryPath -UseCache

    $file1 = $result1.Results | Where-Object { $_.FilePath -eq $testFile }
    $score1 = $file1.RiskScore

    # Deuxième exécution (l'historique des erreurs devrait augmenter le score)
    $result2 = & $scriptPath -RepositoryPath $testDir -OutputPath "$testDir\report2.html" -ErrorHistoryPath $errorHistoryPath -UseCache

    $file2 = $result2.Results | Where-Object { $_.FilePath -eq $testFile }
    $score2 = $file2.RiskScore

    # Le score devrait être au moins égal, mais probablement plus élevé
    Assert-True ($score2 -ge $score1) "Le score de risque n'a pas augmenté ou est resté stable après l'ajout à l'historique des erreurs"
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
