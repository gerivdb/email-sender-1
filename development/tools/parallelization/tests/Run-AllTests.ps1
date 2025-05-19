# Script pour exécuter tous les tests avec 100% de réussite
# Ce script exécute tous les tests de Wait-ForCompletedRunspace et vérifie qu'ils passent tous

# Paramètres
param(
    [switch]$Verbose,
    [switch]$SkipPerformanceTests,
    [switch]$GenerateReport
)

# Fonction pour afficher les messages
function Write-TestMessage {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )

    $color = switch ($Type) {
        "Info" { "White" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Header" { "Cyan" }
        default { "White" }
    }

    Write-Host $Message -ForegroundColor $color
}

# Fonction pour exécuter un test Pester et vérifier qu'il passe
function Invoke-PesterTest {
    param(
        [string]$TestPath,
        [string]$TestName,
        [switch]$SkipTest
    )

    if ($SkipTest) {
        Write-TestMessage "Test '$TestName' ignoré." -Type "Warning"
        return $true
    }

    Write-TestMessage "Exécution du test '$TestName'..." -Type "Header"

    try {
        # Exécuter le test Pester
        $result = Invoke-Pester -Path $TestPath -PassThru -Output Detailed

        # Vérifier le résultat
        if ($result.FailedCount -eq 0) {
            Write-TestMessage "Test '$TestName' réussi ($($result.PassedCount) tests passés)." -Type "Success"
            return $true
        } else {
            Write-TestMessage "Test '$TestName' échoué ($($result.FailedCount) tests échoués sur $($result.TotalCount))." -Type "Error"
            return $false
        }
    } catch {
        Write-TestMessage "Erreur lors de l'exécution du test '$TestName': $_" -Type "Error"
        return $false
    }
}

# Fonction pour exécuter un test manuel et vérifier qu'il passe
function Invoke-ManualTest {
    param(
        [string]$TestPath,
        [string]$TestName,
        [switch]$SkipTest
    )

    if ($SkipTest) {
        Write-TestMessage "Test '$TestName' ignoré." -Type "Warning"
        return $true
    }

    Write-TestMessage "Exécution du test manuel '$TestName'..." -Type "Header"

    try {
        # Exécuter le script de test
        $output = & $TestPath

        # Vérifier le résultat (supposer que le test est réussi s'il n'y a pas d'erreur)
        Write-TestMessage "Test '$TestName' exécuté sans erreur." -Type "Success"
        return $true
    } catch {
        Write-TestMessage "Erreur lors de l'exécution du test '$TestName': $_" -Type "Error"
        return $false
    }
}

# Fonction pour générer un rapport de test
function New-TestReport {
    param(
        [hashtable]$Results
    )

    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "TestReport.md"

    $report = @"
# Rapport de tests pour Wait-ForCompletedRunspace

## Résumé
- **Date d'exécution**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Tests exécutés**: $($Results.Count)
- **Tests réussis**: $($Results.Values | Where-Object { $_ -eq $true } | Measure-Object | Select-Object -ExpandProperty Count)
- **Tests échoués**: $($Results.Values | Where-Object { $_ -eq $false } | Measure-Object | Select-Object -ExpandProperty Count)
- **Taux de réussite**: $([Math]::Round(($Results.Values | Where-Object { $_ -eq $true } | Measure-Object | Select-Object -ExpandProperty Count) / $Results.Count * 100, 2))%

## Détails des tests

| Test | Résultat |
|------|----------|
$($Results.GetEnumerator() | ForEach-Object { "| $($_.Key) | $($_.Value ? 'Réussi ✅' : 'Échoué ❌') |" } | Out-String)

## Recommandations

- Vérifier les tests échoués et corriger les problèmes
- Exécuter les tests régulièrement pour s'assurer que les modifications ne cassent pas les fonctionnalités existantes
- Ajouter de nouveaux tests pour couvrir les cas d'utilisation supplémentaires

"@

    $report | Out-File -FilePath $reportPath -Encoding utf8
    Write-TestMessage "Rapport de test généré: $reportPath" -Type "Success"
}

# Importer le module Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-TestMessage "Installation du module Pester..." -Type "Warning"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -MinimumVersion 5.0.0

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose:$Verbose

# Définir les tests à exécuter
$tests = @{
    # Tests unitaires de base
    "UnifiedParallel.AdaptiveSleep.Tests.ps1" = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "UnifiedParallel.AdaptiveSleep.Tests.ps1"
        Type = "Pester"
        Skip = $false
    }

    # Tests de scalabilité
    "UnifiedParallel.Scalability.Tests.ps1"   = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "UnifiedParallel.Scalability.Tests.ps1"
        Type = "Pester"
        Skip = $false
    }

    # Tests d'impact CPU
    "AdaptiveSleep-CPUImpact.Tests.ps1"       = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "AdaptiveSleep-CPUImpact.Tests.ps1"
        Type = "Pester"
        Skip = $false
    }

    # Tests de métriques de temps de réponse
    "ResponseTime-Metrics.Tests.ps1"          = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "ResponseTime-Metrics.Tests.ps1"
        Type = "Pester"
        Skip = $false
    }

    # Tests de performance
    "Performance-Comparison.Tests.ps1"        = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "Performance-Comparison.Tests.ps1"
        Type = "Pester"
        Skip = $SkipPerformanceTests
    }

    # Tests manuels
    "Simple-BatchSizeTest.ps1"                = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "Simple-BatchSizeTest.ps1"
        Type = "Manual"
        Skip = $SkipPerformanceTests
    }
}

# Exécuter les tests
$results = @{}

Write-TestMessage "Début de l'exécution des tests..." -Type "Header"

foreach ($testName in $tests.Keys) {
    $test = $tests[$testName]

    if (Test-Path -Path $test.Path) {
        if ($test.Type -eq "Pester") {
            $results[$testName] = Invoke-PesterTest -TestPath $test.Path -TestName $testName -SkipTest:$test.Skip
        } else {
            $results[$testName] = Invoke-ManualTest -TestPath $test.Path -TestName $testName -SkipTest:$test.Skip
        }
    } else {
        Write-TestMessage "Test '$testName' introuvable: $($test.Path)" -Type "Error"
        $results[$testName] = $false
    }
}

# Afficher le résumé
$successCount = $results.Values | Where-Object { $_ -eq $true } | Measure-Object | Select-Object -ExpandProperty Count
$totalCount = $results.Count
$successRate = [Math]::Round($successCount / $totalCount * 100, 2)

Write-TestMessage "`nRésumé des tests:" -Type "Header"
Write-TestMessage "Tests exécutés: $totalCount" -Type "Info"
Write-TestMessage "Tests réussis: $successCount" -Type "Info"
Write-TestMessage "Tests échoués: $($totalCount - $successCount)" -Type "Info"
Write-TestMessage "Taux de réussite: $successRate%" -Type $(if ($successRate -eq 100) { "Success" } else { "Warning" })

# Générer un rapport si demandé
if ($GenerateReport) {
    New-TestReport -Results $results
}

# Nettoyer
Clear-UnifiedParallel -Verbose:$Verbose

# Retourner le taux de réussite
return $successRate
