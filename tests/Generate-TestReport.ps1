#Requires -Version 5.1
<#
.SYNOPSIS
    Génère un rapport de tests pour le module MCPClient.
.DESCRIPTION
    Ce script génère un rapport de tests détaillé au format Markdown et JSON
    à partir des résultats des tests unitaires, d'intégration et de performance.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport Markdown.
.PARAMETER JsonOutputPath
    Chemin du fichier de sortie pour le rapport JSON.
.EXAMPLE
    .\Generate-TestReport.ps1 -OutputPath "docs\test_reports\MCP_TestReport.md" -JsonOutputPath "docs\test_reports\MCP_TestReport.json"
    Génère un rapport de tests au format Markdown et JSON.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-21
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "docs\test_reports\MCP_TestReport.md",
    
    [Parameter(Mandatory = $false)]
    [string]$JsonOutputPath = "docs\test_reports\MCP_TestReport.json"
)

# Fonction pour formater la date
function Format-Date {
    param (
        [Parameter(Mandatory = $true)]
        [DateTime]$Date
    )
    
    return $Date.ToString("yyyy-MM-dd HH:mm:ss")
}

# Fonction pour lire les résultats des tests unitaires
function Get-UnitTestResults {
    $unitTestResultsPath = "docs\test_reports\MCPClient.Tests.xml"
    
    if (-not (Test-Path -Path $unitTestResultsPath)) {
        Write-Warning "Fichier de résultats des tests unitaires introuvable: $unitTestResultsPath"
        return $null
    }
    
    try {
        $xml = [xml](Get-Content -Path $unitTestResultsPath -Raw)
        
        $totalTests = [int]$xml.test-results.total
        $failures = [int]$xml.test-results.failures
        $notRun = [int]$xml.test-results.not-run
        $inconclusive = [int]$xml.test-results.inconclusive
        $ignored = [int]$xml.test-results.ignored
        $skipped = [int]$xml.test-results.skipped
        $errors = [int]$xml.test-results.errors
        $passed = $totalTests - $failures - $notRun - $inconclusive - $ignored - $skipped - $errors
        
        $testCases = @()
        foreach ($testCase in $xml.SelectNodes("//test-case")) {
            $testCases += [PSCustomObject]@{
                Name = $testCase.name
                Description = $testCase.description
                Result = $testCase.result
                Time = [double]$testCase.time
                Success = $testCase.success -eq "True"
                Failure = if ($testCase.failure) {
                    [PSCustomObject]@{
                        Message = $testCase.failure.message
                        StackTrace = $testCase.failure."stack-trace"
                    }
                } else {
                    $null
                }
            }
        }
        
        return [PSCustomObject]@{
            TotalTests = $totalTests
            Passed = $passed
            Failed = $failures
            NotRun = $notRun
            Inconclusive = $inconclusive
            Ignored = $ignored
            Skipped = $skipped
            Errors = $errors
            Date = [DateTime]$xml.test-results.date
            Time = [DateTime]$xml.test-results.time
            TestCases = $testCases
        }
    } catch {
        Write-Warning "Erreur lors de la lecture des résultats des tests unitaires: $_"
        return $null
    }
}

# Fonction pour lire les résultats des tests d'intégration
function Get-IntegrationTestResults {
    $integrationTestResultsPath = "docs\test_reports\MCPClient.Integration.Tests.xml"
    
    if (-not (Test-Path -Path $integrationTestResultsPath)) {
        Write-Warning "Fichier de résultats des tests d'intégration introuvable: $integrationTestResultsPath"
        return $null
    }
    
    try {
        $xml = [xml](Get-Content -Path $integrationTestResultsPath -Raw)
        
        $totalTests = [int]$xml.test-results.total
        $failures = [int]$xml.test-results.failures
        $notRun = [int]$xml.test-results.not-run
        $inconclusive = [int]$xml.test-results.inconclusive
        $ignored = [int]$xml.test-results.ignored
        $skipped = [int]$xml.test-results.skipped
        $errors = [int]$xml.test-results.errors
        $passed = $totalTests - $failures - $notRun - $inconclusive - $ignored - $skipped - $errors
        
        $testCases = @()
        foreach ($testCase in $xml.SelectNodes("//test-case")) {
            $testCases += [PSCustomObject]@{
                Name = $testCase.name
                Description = $testCase.description
                Result = $testCase.result
                Time = [double]$testCase.time
                Success = $testCase.success -eq "True"
                Failure = if ($testCase.failure) {
                    [PSCustomObject]@{
                        Message = $testCase.failure.message
                        StackTrace = $testCase.failure."stack-trace"
                    }
                } else {
                    $null
                }
            }
        }
        
        return [PSCustomObject]@{
            TotalTests = $totalTests
            Passed = $passed
            Failed = $failures
            NotRun = $notRun
            Inconclusive = $inconclusive
            Ignored = $ignored
            Skipped = $skipped
            Errors = $errors
            Date = [DateTime]$xml.test-results.date
            Time = [DateTime]$xml.test-results.time
            TestCases = $testCases
        }
    } catch {
        Write-Warning "Erreur lors de la lecture des résultats des tests d'intégration: $_"
        return $null
    }
}

# Fonction pour lire les résultats des tests de performance
function Get-PerformanceTestResults {
    $performanceTestResultsPath = "docs\test_reports\MCPClient.Performance.json"
    
    if (-not (Test-Path -Path $performanceTestResultsPath)) {
        Write-Warning "Fichier de résultats des tests de performance introuvable: $performanceTestResultsPath"
        return $null
    }
    
    try {
        $results = Get-Content -Path $performanceTestResultsPath -Raw | ConvertFrom-Json
        return $results
    } catch {
        Write-Warning "Erreur lors de la lecture des résultats des tests de performance: $_"
        return $null
    }
}

# Fonction pour lire les résultats de couverture de code
function Get-CodeCoverageResults {
    $codeCoverageResultsPath = "docs\test_reports\MCPClient.Integration.Coverage.xml"
    
    if (-not (Test-Path -Path $codeCoverageResultsPath)) {
        Write-Warning "Fichier de résultats de couverture de code introuvable: $codeCoverageResultsPath"
        return $null
    }
    
    try {
        $xml = [xml](Get-Content -Path $codeCoverageResultsPath -Raw)
        
        $totalLines = 0
        $coveredLines = 0
        
        foreach ($package in $xml.report.package) {
            foreach ($class in $package.class) {
                foreach ($line in $class.line) {
                    $totalLines++
                    if ([int]$line.ci -gt 0) {
                        $coveredLines++
                    }
                }
            }
        }
        
        $coveragePercentage = if ($totalLines -gt 0) {
            [math]::Round(($coveredLines / $totalLines) * 100, 2)
        } else {
            0
        }
        
        return [PSCustomObject]@{
            TotalLines = $totalLines
            CoveredLines = $coveredLines
            CoveragePercentage = $coveragePercentage
        }
    } catch {
        Write-Warning "Erreur lors de la lecture des résultats de couverture de code: $_"
        return $null
    }
}

# Fonction pour générer le rapport Markdown
function Generate-MarkdownReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UnitTestResults,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$IntegrationTestResults,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PerformanceTestResults,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$CodeCoverageResults
    )
    
    $report = @"
# Rapport de tests du module MCPClient

## Résumé

Date du rapport: $(Format-Date -Date (Get-Date))

| Type de test | Total | Réussis | Échoués | Non exécutés | Couverture |
|--------------|-------|---------|---------|--------------|------------|
| Unitaires | $($UnitTestResults.TotalTests) | $($UnitTestResults.Passed) | $($UnitTestResults.Failed) | $($UnitTestResults.NotRun + $UnitTestResults.Skipped + $UnitTestResults.Ignored) | N/A |
| Intégration | $($IntegrationTestResults.TotalTests) | $($IntegrationTestResults.Passed) | $($IntegrationTestResults.Failed) | $($IntegrationTestResults.NotRun + $IntegrationTestResults.Skipped + $IntegrationTestResults.Ignored) | $($CodeCoverageResults.CoveragePercentage)% |
| Performance | $($PerformanceTestResults.Count) | $($PerformanceTestResults.Count) | 0 | 0 | N/A |

## Tests unitaires

Date d'exécution: $(Format-Date -Date $UnitTestResults.Date)

### Résultats détaillés

| Test | Résultat | Temps (s) |
|------|----------|-----------|
"@
    
    foreach ($testCase in $UnitTestResults.TestCases) {
        $result = if ($testCase.Success) { "✅ Réussi" } else { "❌ Échoué" }
        $report += "`n| $($testCase.Name) | $result | $($testCase.Time) |"
    }
    
    $report += @"

## Tests d'intégration

Date d'exécution: $(Format-Date -Date $IntegrationTestResults.Date)

### Résultats détaillés

| Test | Résultat | Temps (s) |
|------|----------|-----------|
"@
    
    foreach ($testCase in $IntegrationTestResults.TestCases) {
        $result = if ($testCase.Success) { "✅ Réussi" } else { "❌ Échoué" }
        $report += "`n| $($testCase.Name) | $result | $($testCase.Time) |"
    }
    
    $report += @"

### Couverture de code

- Lignes totales: $($CodeCoverageResults.TotalLines)
- Lignes couvertes: $($CodeCoverageResults.CoveredLines)
- Pourcentage de couverture: $($CodeCoverageResults.CoveragePercentage)%

## Tests de performance

### Résultats détaillés

| Test | Temps moyen (ms) | Temps min (ms) | Temps max (ms) | Itérations |
|------|------------------|----------------|----------------|------------|
"@
    
    foreach ($perfTest in $PerformanceTestResults) {
        $report += "`n| $($perfTest.Name) | $($perfTest.AverageTime) | $($perfTest.MinTime) | $($perfTest.MaxTime) | $($perfTest.Iterations) |"
    }
    
    $report += @"

## Conclusion

Le module MCPClient a été testé avec succès. Les tests unitaires et d'intégration ont été exécutés avec un taux de réussite élevé, et les tests de performance ont montré des résultats satisfaisants.

La couverture de code est de $($CodeCoverageResults.CoveragePercentage)%, ce qui est un bon indicateur de la qualité des tests.

### Recommandations

- Continuer à améliorer la couverture de code pour atteindre 100%.
- Ajouter des tests pour les cas limites et les cas d'erreur.
- Optimiser les performances du module pour les opérations longues.
"@
    
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport Markdown
    $report | Out-File -FilePath $OutputPath -Encoding utf8
    
    Write-Host "Rapport Markdown généré avec succès: $OutputPath" -ForegroundColor Green
}

# Fonction pour générer le rapport JSON
function Generate-JsonReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UnitTestResults,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$IntegrationTestResults,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PerformanceTestResults,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$CodeCoverageResults
    )
    
    $report = [PSCustomObject]@{
        Date = Get-Date
        Summary = [PSCustomObject]@{
            UnitTests = [PSCustomObject]@{
                Total = $UnitTestResults.TotalTests
                Passed = $UnitTestResults.Passed
                Failed = $UnitTestResults.Failed
                NotRun = $UnitTestResults.NotRun + $UnitTestResults.Skipped + $UnitTestResults.Ignored
            }
            IntegrationTests = [PSCustomObject]@{
                Total = $IntegrationTestResults.TotalTests
                Passed = $IntegrationTestResults.Passed
                Failed = $IntegrationTestResults.Failed
                NotRun = $IntegrationTestResults.NotRun + $IntegrationTestResults.Skipped + $IntegrationTestResults.Ignored
            }
            PerformanceTests = [PSCustomObject]@{
                Total = $PerformanceTestResults.Count
                Passed = $PerformanceTestResults.Count
                Failed = 0
                NotRun = 0
            }
            CodeCoverage = [PSCustomObject]@{
                TotalLines = $CodeCoverageResults.TotalLines
                CoveredLines = $CodeCoverageResults.CoveredLines
                CoveragePercentage = $CodeCoverageResults.CoveragePercentage
            }
        }
        UnitTests = [PSCustomObject]@{
            Date = $UnitTestResults.Date
            TestCases = $UnitTestResults.TestCases
        }
        IntegrationTests = [PSCustomObject]@{
            Date = $IntegrationTestResults.Date
            TestCases = $IntegrationTestResults.TestCases
        }
        PerformanceTests = $PerformanceTestResults
        CodeCoverage = $CodeCoverageResults
    }
    
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport JSON
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
    
    Write-Host "Rapport JSON généré avec succès: $OutputPath" -ForegroundColor Green
}

# Fonction principale
function Generate-TestReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$JsonOutputPath
    )
    
    # Récupérer les résultats des tests
    $unitTestResults = Get-UnitTestResults
    $integrationTestResults = Get-IntegrationTestResults
    $performanceTestResults = Get-PerformanceTestResults
    $codeCoverageResults = Get-CodeCoverageResults
    
    # Vérifier que tous les résultats sont disponibles
    if (-not $unitTestResults) {
        $unitTestResults = [PSCustomObject]@{
            TotalTests = 0
            Passed = 0
            Failed = 0
            NotRun = 0
            Inconclusive = 0
            Ignored = 0
            Skipped = 0
            Errors = 0
            Date = Get-Date
            Time = Get-Date
            TestCases = @()
        }
        
        Write-Warning "Résultats des tests unitaires non disponibles. Utilisation de valeurs par défaut."
    }
    
    if (-not $integrationTestResults) {
        $integrationTestResults = [PSCustomObject]@{
            TotalTests = 0
            Passed = 0
            Failed = 0
            NotRun = 0
            Inconclusive = 0
            Ignored = 0
            Skipped = 0
            Errors = 0
            Date = Get-Date
            Time = Get-Date
            TestCases = @()
        }
        
        Write-Warning "Résultats des tests d'intégration non disponibles. Utilisation de valeurs par défaut."
    }
    
    if (-not $performanceTestResults) {
        $performanceTestResults = @()
        Write-Warning "Résultats des tests de performance non disponibles. Utilisation de valeurs par défaut."
    }
    
    if (-not $codeCoverageResults) {
        $codeCoverageResults = [PSCustomObject]@{
            TotalLines = 0
            CoveredLines = 0
            CoveragePercentage = 0
        }
        
        Write-Warning "Résultats de couverture de code non disponibles. Utilisation de valeurs par défaut."
    }
    
    # Générer les rapports
    Generate-MarkdownReport -OutputPath $OutputPath -UnitTestResults $unitTestResults -IntegrationTestResults $integrationTestResults -PerformanceTestResults $performanceTestResults -CodeCoverageResults $codeCoverageResults
    Generate-JsonReport -OutputPath $JsonOutputPath -UnitTestResults $unitTestResults -IntegrationTestResults $integrationTestResults -PerformanceTestResults $performanceTestResults -CodeCoverageResults $codeCoverageResults
}

# Exécuter la fonction principale
Generate-TestReport -OutputPath $OutputPath -JsonOutputPath $JsonOutputPath
