<#
.SYNOPSIS
    Exécute tous les tests Pester liés au délai adaptatif.
.DESCRIPTION
    Ce script exécute tous les tests Pester liés au délai adaptatif dans Wait-ForCompletedRunspace
    et génère un rapport détaillé des résultats.
.PARAMETER Verbose
    Affiche des informations détaillées sur l'exécution des tests.
.PARAMETER SkipPerformanceTests
    Ignore les tests de performance qui peuvent prendre du temps.
.PARAMETER GenerateReport
    Génère un rapport détaillé des résultats des tests au format Markdown.
.PARAMETER Parallel
    Exécute les tests en parallèle pour améliorer les performances.
.PARAMETER CodeCoverage
    Génère un rapport de couverture de code.
.EXAMPLE
    .\Run-AllAdaptiveSleepTests.ps1 -GenerateReport
    Exécute tous les tests et génère un rapport détaillé.
.EXAMPLE
    .\Run-AllAdaptiveSleepTests.ps1 -Parallel -CodeCoverage
    Exécute tous les tests en parallèle et génère un rapport de couverture de code.
.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2023-05-19
    Encoding:       UTF-8 with BOM
#>

# Paramètres
param(
    [switch]$Verbose,
    [switch]$SkipPerformanceTests,
    [switch]$GenerateReport,
    [switch]$Parallel,
    [switch]$CodeCoverage
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
        [switch]$SkipTest,
        [switch]$CodeCoverage,
        [string]$ModulePath
    )

    if ($SkipTest) {
        Write-TestMessage "Test '$TestName' ignoré." -Type "Warning"
        return @{
            Success     = $true
            Skipped     = $true
            PassedCount = 0
            FailedCount = 0
            TotalCount  = 0
            Duration    = 0
            Coverage    = $null
        }
    }

    Write-TestMessage "Exécution du test '$TestName'..." -Type "Header"

    try {
        # Configurer les options Pester
        $pesterConfig = [PesterConfiguration]::Default
        $pesterConfig.Run.Path = $TestPath
        $pesterConfig.Output.Verbosity = if ($Verbose) { 'Detailed' } else { 'Normal' }
        $pesterConfig.Run.PassThru = $true

        # Configurer la couverture de code si demandée
        if ($CodeCoverage -and $ModulePath) {
            $pesterConfig.CodeCoverage.Enabled = $true
            $pesterConfig.CodeCoverage.Path = $ModulePath
            $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
            $coverageOutputPath = Join-Path -Path $PSScriptRoot -ChildPath "coverage-$TestName.xml"
            $pesterConfig.CodeCoverage.OutputPath = $coverageOutputPath
            $pesterConfig.CodeCoverage.CoveragePercentTarget = 80
        }

        # Exécuter le test Pester
        $result = Invoke-Pester -Configuration $pesterConfig

        # Vérifier le résultat
        if ($result.FailedCount -eq 0) {
            Write-TestMessage "Test '$TestName' réussi ($($result.PassedCount) tests passés)." -Type "Success"
            return @{
                Success     = $true
                Skipped     = $false
                PassedCount = $result.PassedCount
                FailedCount = $result.FailedCount
                TotalCount  = $result.TotalCount
                Duration    = $result.Duration.TotalMilliseconds
                Coverage    = $null
            }
        } else {
            Write-TestMessage "Test '$TestName' échoué ($($result.FailedCount) tests échoués sur $($result.TotalCount))." -Type "Error"
            return @{
                Success     = $false
                Skipped     = $false
                PassedCount = $result.PassedCount
                FailedCount = $result.FailedCount
                TotalCount  = $result.TotalCount
                Duration    = $result.Duration.TotalMilliseconds
                Coverage    = $null
            }
        }
    } catch {
        Write-TestMessage "Erreur lors de l'exécution du test '$TestName': $_" -Type "Error"
        return @{
            Success     = $false
            Skipped     = $false
            PassedCount = 0
            FailedCount = 1
            TotalCount  = 1
            Duration    = 0
            Coverage    = $null
            Error       = $_
        }
    }
}

# Fonction pour extraire les informations de couverture de code
function Get-CodeCoverageInfo {
    param(
        [string]$TestName
    )

    # Vérifier si le fichier de couverture existe
    $coverageFile = Join-Path -Path $PSScriptRoot -ChildPath "coverage-$TestName.xml"
    if (Test-Path -Path $coverageFile) {
        try {
            # Lire le fichier de couverture
            $coverageXml = [xml](Get-Content -Path $coverageFile -Raw)

            # Extraire les informations de couverture
            $lineCounter = $coverageXml.report.counter | Where-Object { $_.type -eq 'LINE' }
            if ($lineCounter) {
                $coveredLines = [int]$lineCounter.covered
                $missedLines = [int]$lineCounter.missed
                $analyzedLines = $coveredLines + $missedLines

                # Calculer le pourcentage de couverture
                $coveragePercent = if ($analyzedLines -gt 0) {
                    [Math]::Round(($coveredLines / $analyzedLines) * 100, 2)
                } else {
                    0
                }

                return @{
                    CoveredLines    = $coveredLines
                    AnalyzedLines   = $analyzedLines
                    CoveragePercent = $coveragePercent
                }
            }
        } catch {
            Write-TestMessage "Erreur lors de l'extraction des informations de couverture de code: $_" -Type "Error"
        }
    }

    # Retourner des valeurs par défaut si le fichier n'existe pas ou s'il y a une erreur
    return @{
        CoveredLines    = 0
        AnalyzedLines   = 0
        CoveragePercent = 0
    }
}

# Fonction pour générer un rapport de test
function New-TestReport {
    param(
        [hashtable]$Results,
        [hashtable]$CoverageResults = @{}
    )

    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "AdaptiveSleepTestReport.md"
    $successCount = ($Results.Values | Where-Object { $_.Success -eq $true } | Measure-Object).Count
    $totalCount = $Results.Count
    $successRate = [Math]::Round($successCount / $totalCount * 100, 2)

    $totalDuration = ($Results.Values | Measure-Object -Property Duration -Sum).Sum
    $totalPassedCount = ($Results.Values | Measure-Object -Property PassedCount -Sum).Sum
    $totalFailedCount = ($Results.Values | Measure-Object -Property FailedCount -Sum).Sum
    $totalTestCount = ($Results.Values | Measure-Object -Property TotalCount -Sum).Sum

    $report = @"
# Rapport de tests pour le délai adaptatif dans Wait-ForCompletedRunspace

## Résumé
- **Date d'exécution**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Tests exécutés**: $totalCount
- **Tests réussis**: $successCount
- **Tests échoués**: $($totalCount - $successCount)
- **Taux de réussite**: $successRate%
- **Durée totale**: $([Math]::Round($totalDuration / 1000, 2)) secondes
- **Tests unitaires passés**: $totalPassedCount
- **Tests unitaires échoués**: $totalFailedCount
- **Total des tests unitaires**: $totalTestCount

## Détails des tests

| Test | Résultat | Durée (ms) | Tests passés | Tests échoués |
|------|----------|------------|--------------|---------------|
$($Results.GetEnumerator() | ForEach-Object {
    "| $($_.Key) | $($_.Value.Success ? 'Réussi ✅' : 'Échoué ❌') | $([Math]::Round($_.Value.Duration, 2)) | $($_.Value.PassedCount) | $($_.Value.FailedCount) |"
} | Out-String)

"@

    # Ajouter les informations de couverture de code si disponibles
    if ($CoverageResults.Count -gt 0) {
        $totalCoveredLines = ($CoverageResults.Values | Measure-Object -Property CoveredLines -Sum).Sum
        $totalAnalyzedLines = ($CoverageResults.Values | Measure-Object -Property AnalyzedLines -Sum).Sum
        $coveragePercent = if ($totalAnalyzedLines -gt 0) { [Math]::Round(($totalCoveredLines / $totalAnalyzedLines) * 100, 2) } else { 0 }

        $report += @"

## Couverture de code

- **Lignes couvertes**: $totalCoveredLines
- **Lignes analysées**: $totalAnalyzedLines
- **Pourcentage de couverture**: $coveragePercent%

| Fichier | Lignes couvertes | Lignes analysées | Couverture |
|---------|------------------|------------------|------------|
$($CoverageResults.GetEnumerator() | ForEach-Object {
    $coveragePercent = if ($_.Value.AnalyzedLines -gt 0) { [Math]::Round(($_.Value.CoveredLines / $_.Value.AnalyzedLines) * 100, 2) } else { 0 }
    "| $($_.Key) | $($_.Value.CoveredLines) | $($_.Value.AnalyzedLines) | $coveragePercent% |"
} | Out-String)

"@
    }

    $report += @"

## Recommandations

- Vérifier les tests échoués et corriger les problèmes
- Exécuter les tests régulièrement pour s'assurer que les modifications ne cassent pas les fonctionnalités existantes
- Ajouter de nouveaux tests pour couvrir les cas d'utilisation supplémentaires
"@

    $report | Out-File -FilePath $reportPath -Encoding utf8
    Write-TestMessage "Rapport de test généré: $reportPath" -Type "Success"

    return $reportPath
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

# Définir les tests liés au délai adaptatif à exécuter
$adaptiveSleepTests = @{
    # Tests Pester formels
    "Critical-AdaptiveSleepTest.Pester.ps1"   = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "Critical-AdaptiveSleepTest.Pester.ps1"
        Skip = $false
    }
    "Timeout-HandlingTest.Pester.ps1"         = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "Timeout-HandlingTest.Pester.ps1"
        Skip = $false
    }
    "LongDelay-StabilityTest.Pester.ps1"      = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "LongDelay-StabilityTest.Pester.ps1"
        Skip = $false
    }
    "ShortDelay-ReactivityTest.Pester.ps1"    = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "ShortDelay-ReactivityTest.Pester.ps1"
        Skip = $false
    }

    # Tests unitaires de base
    "UnifiedParallel.AdaptiveSleep.Tests.ps1" = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "UnifiedParallel.AdaptiveSleep.Tests.ps1"
        Skip = $false
    }

    # Tests d'impact CPU
    "AdaptiveSleep-CPUImpact.Tests.ps1"       = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "AdaptiveSleep-CPUImpact.Tests.ps1"
        Skip = $false
    }
    "CPULoad-BehaviorTest.Pester.ps1"         = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "CPULoad-BehaviorTest.Pester.ps1"
        Skip = $false
    }

    # Tests de scalabilité
    "Minimal-ScalabilityTest.Pester.ps1"      = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "Minimal-ScalabilityTest.Pester.ps1"
        Skip = $false
    }

    # Tests de performance
    "Performance-Comparison.Tests.ps1"        = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "Performance-Comparison.Tests.ps1"
        Skip = $SkipPerformanceTests
    }

    # Tests de métriques
    "ResponseTime-Metrics.Tests.ps1"          = @{
        Path = Join-Path -Path $PSScriptRoot -ChildPath "ResponseTime-Metrics.Tests.ps1"
        Skip = $false
    }
}

# Exécuter les tests
$results = @{}
$coverageResults = @{}

Write-TestMessage "Début de l'exécution des tests de délai adaptatif..." -Type "Header"
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Exécuter les tests en parallèle ou en séquence
if ($Parallel) {
    Write-TestMessage "Exécution des tests en parallèle..." -Type "Info"

    # Créer un runspace pool
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
    $runspacePool.Open()

    # Créer les runspaces pour chaque test
    $runspaces = @{}

    foreach ($testName in $adaptiveSleepTests.Keys) {
        $test = $adaptiveSleepTests[$testName]

        if (Test-Path -Path $test.Path) {
            # Créer un nouveau runspace pour ce test
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter le script et les paramètres
            [void]$powershell.AddScript({
                    param($TestPath, $TestName, $Skip, $CodeCoverage, $ModulePath, $Verbose)

                    # Importer Pester
                    Import-Module Pester -MinimumVersion 5.0.0

                    # Configurer les options Pester
                    $pesterConfig = [PesterConfiguration]::Default
                    $pesterConfig.Run.Path = $TestPath
                    $pesterConfig.Output.Verbosity = if ($Verbose) { 'Detailed' } else { 'Normal' }
                    $pesterConfig.Run.PassThru = $true

                    # Configurer la couverture de code si demandée
                    if ($CodeCoverage -and $ModulePath) {
                        $pesterConfig.CodeCoverage.Enabled = $true
                        $pesterConfig.CodeCoverage.Path = $ModulePath
                        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
                        $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path (Split-Path -Parent $TestPath) -ChildPath "coverage-$TestName.xml"
                    }

                    # Exécuter le test
                    if ($Skip) {
                        return @{
                            Success     = $true
                            Skipped     = $true
                            PassedCount = 0
                            FailedCount = 0
                            TotalCount  = 0
                            Duration    = 0
                            Coverage    = $null
                        }
                    } else {
                        try {
                            $result = Invoke-Pester -Configuration $pesterConfig

                            return @{
                                Success     = $result.FailedCount -eq 0
                                Skipped     = $false
                                PassedCount = $result.PassedCount
                                FailedCount = $result.FailedCount
                                TotalCount  = $result.TotalCount
                                Duration    = $result.Duration.TotalMilliseconds
                                Coverage    = $null
                            }
                        } catch {
                            return @{
                                Success     = $false
                                Skipped     = $false
                                PassedCount = 0
                                FailedCount = 1
                                TotalCount  = 1
                                Duration    = 0
                                Coverage    = $null
                                Error       = $_.ToString()
                            }
                        }
                    }
                })

            # Ajouter les paramètres
            [void]$powershell.AddParameter('TestPath', $test.Path)
            [void]$powershell.AddParameter('TestName', $testName)
            [void]$powershell.AddParameter('Skip', $test.Skip)
            [void]$powershell.AddParameter('CodeCoverage', $CodeCoverage)
            [void]$powershell.AddParameter('ModulePath', $modulePath)
            [void]$powershell.AddParameter('Verbose', $Verbose)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            $runspaces[$testName] = @{
                PowerShell = $powershell
                Handle     = $handle
            }
        } else {
            Write-TestMessage "Test '$testName' introuvable: $($test.Path)" -Type "Error"
            $results[$testName] = @{
                Success     = $false
                Skipped     = $false
                PassedCount = 0
                FailedCount = 1
                TotalCount  = 1
                Duration    = 0
                Coverage    = $null
                Error       = "Fichier de test introuvable"
            }
        }
    }

    # Attendre que tous les tests soient terminés
    foreach ($testName in $runspaces.Keys) {
        Write-TestMessage "Attente de la fin du test '$testName'..." -Type "Info"
        $runspace = $runspaces[$testName]

        try {
            # Récupérer le résultat
            $result = $runspace.PowerShell.EndInvoke($runspace.Handle)
            $results[$testName] = $result

            # Afficher le résultat
            if ($result.Success) {
                if ($result.Skipped) {
                    Write-TestMessage "Test '$testName' ignoré." -Type "Warning"
                } else {
                    Write-TestMessage "Test '$testName' réussi ($($result.PassedCount) tests passés)." -Type "Success"
                }
            } else {
                Write-TestMessage "Test '$testName' échoué ($($result.FailedCount) tests échoués sur $($result.TotalCount))." -Type "Error"
                if ($result.Error) {
                    Write-TestMessage "Erreur: $($result.Error)" -Type "Error"
                }
            }

            # Nettoyer le runspace
            $runspace.PowerShell.Dispose()
        } catch {
            Write-TestMessage "Erreur lors de la récupération du résultat du test '$testName': $_" -Type "Error"
            $results[$testName] = @{
                Success     = $false
                Skipped     = $false
                PassedCount = 0
                FailedCount = 1
                TotalCount  = 1
                Duration    = 0
                Coverage    = $null
                Error       = $_.ToString()
            }
        }
    }

    # Fermer le pool de runspaces
    $runspacePool.Close()
    $runspacePool.Dispose()
} else {
    # Exécution séquentielle
    foreach ($testName in $adaptiveSleepTests.Keys) {
        $test = $adaptiveSleepTests[$testName]

        if (Test-Path -Path $test.Path) {
            $result = Invoke-PesterTest -TestPath $test.Path -TestName $testName -SkipTest:$test.Skip -CodeCoverage:$CodeCoverage -ModulePath $modulePath
            $results[$testName] = $result

            # Collecter les résultats de couverture de code
            if ($CodeCoverage) {
                $coverageInfo = Get-CodeCoverageInfo -TestName $testName
                if ($coverageInfo.AnalyzedLines -gt 0) {
                    $coverageResults[$testName] = $coverageInfo
                    Write-TestMessage "Couverture de code pour '$testName': $($coverageInfo.CoveredLines)/$($coverageInfo.AnalyzedLines) lignes ($($coverageInfo.CoveragePercent)%)" -Type "Info"
                }
            }
        } else {
            Write-TestMessage "Test '$testName' introuvable: $($test.Path)" -Type "Error"
            $results[$testName] = @{
                Success     = $false
                Skipped     = $false
                PassedCount = 0
                FailedCount = 1
                TotalCount  = 1
                Duration    = 0
                Coverage    = $null
                Error       = "Fichier de test introuvable"
            }
        }
    }
}

$stopwatch.Stop()

# Afficher le résumé
$successCount = ($results.Values | Where-Object { $_.Success -eq $true } | Measure-Object).Count
$totalCount = $results.Count
$successRate = [Math]::Round($successCount / $totalCount * 100, 2)

Write-TestMessage "`nRésumé des tests de délai adaptatif:" -Type "Header"
Write-TestMessage "Tests exécutés: $totalCount" -Type "Info"
Write-TestMessage "Tests réussis: $successCount" -Type "Info"
Write-TestMessage "Tests échoués: $($totalCount - $successCount)" -Type "Info"
Write-TestMessage "Taux de réussite: $successRate%" -Type $(if ($successRate -eq 100) { "Success" } else { "Warning" })
Write-TestMessage "Durée totale: $([Math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) secondes" -Type "Info"

# Générer un rapport si demandé
if ($GenerateReport) {
    $reportPath = New-TestReport -Results $results -CoverageResults $coverageResults
    Write-TestMessage "Rapport généré: $reportPath" -Type "Success"
}

# Nettoyer
Clear-UnifiedParallel -Verbose:$Verbose

# Retourner le taux de réussite
return $successRate
