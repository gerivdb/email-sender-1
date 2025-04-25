<#
.SYNOPSIS
    Adaptateur TestOmnibus pour les tests du module ProactiveOptimization.
.DESCRIPTION
    Cet adaptateur permet d'exécuter les tests du module ProactiveOptimization
    dans le cadre de TestOmnibus, en utilisant les mocks nécessaires.
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

function Invoke-ProactiveOptimizationTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TestPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\ProactiveOptimization\tests"),

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results\ProactiveOptimization"),

        [Parameter(Mandatory = $false)]
        [switch]$GenerateHtmlReport,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetailedResults
    )

    # Vérifier que le chemin des tests existe
    if (-not (Test-Path -Path $TestPath)) {
        Write-Error "Le chemin des tests n'existe pas: $TestPath"
        return @{
            Success      = $false
            ErrorMessage = "Le chemin des tests n'existe pas: $TestPath"
            TestsRun     = 0
            TestsPassed  = 0
            TestsFailed  = 0
            Duration     = 0
        }
    }

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Exécuter les tests avec les mocks
    $mockScriptPath = Join-Path -Path $TestPath -ChildPath "Run-AllTestsWithMocks.ps1"

    if (-not (Test-Path -Path $mockScriptPath)) {
        Write-Error "Le script de mocks n'existe pas: $mockScriptPath"
        return @{
            Success      = $false
            ErrorMessage = "Le script de mocks n'existe pas: $mockScriptPath"
            TestsRun     = 0
            TestsPassed  = 0
            TestsFailed  = 0
            Duration     = 0
        }
    }

    # Préparer les paramètres pour le script de mocks
    $params = @{}

    if ($ShowDetailedResults) {
        $params.Add("ShowDetailedResults", $true)
    }

    if ($GenerateHtmlReport) {
        $params.Add("GenerateCodeCoverage", $true)
    }

    # Mesurer le temps d'exécution
    $startTime = Get-Date

    # Exécuter les tests
    try {
        # Capturer la sortie du script pour éviter qu'elle n'encombre la console
        $output = & $mockScriptPath @params -ErrorAction Stop 2>&1

        # Extraire les résultats de la sortie
        $testsRun = 0
        $testsPassed = 0
        $testsFailed = 0
        $testsSkipped = 0

        foreach ($line in $output) {
            if ($line -match "Tests exécutés: (\d+)") {
                $testsRun = [int]$Matches[1]
            } elseif ($line -match "Tests réussis: (\d+)") {
                $testsPassed = [int]$Matches[1]
            } elseif ($line -match "Tests échoués: (\d+)") {
                $testsFailed = [int]$Matches[1]
            } elseif ($line -match "Tests ignorés: (\d+)") {
                $testsSkipped = [int]$Matches[1]
            }
        }

        # Créer un objet de résultats
        $results = [PSCustomObject]@{
            TotalCount   = $testsRun
            PassedCount  = $testsPassed
            FailedCount  = $testsFailed
            SkippedCount = $testsSkipped
            NotRunCount  = 0
        }
    } catch {
        Write-Error "Erreur lors de l'exécution des tests: $_"
        return @{
            Success      = $false
            ErrorMessage = "Erreur lors de l'exécution des tests: $_"
            TestsRun     = 0
            TestsPassed  = 0
            TestsFailed  = 0
            Duration     = 0
        }
    }

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds

    # Utiliser les résultats déjà extraits ou les obtenir de l'objet de résultats
    if (-not $testsRun) {
        $testsRun = $results.TotalCount
        $testsPassed = $results.PassedCount
        $testsFailed = $results.FailedCount
        $testsSkipped = $results.SkippedCount
    }

    # Générer un rapport HTML si demandé
    if ($GenerateHtmlReport) {
        $reportScriptPath = Join-Path -Path $TestPath -ChildPath "Generate-TestReport.ps1"

        if (Test-Path -Path $reportScriptPath) {
            & $reportScriptPath
        }
    }

    # Retourner les résultats
    return @{
        Success      = ($testsFailed -eq 0)
        ErrorMessage = if ($testsFailed -gt 0) { "$testsFailed tests ont échoué" } else { "" }
        TestsRun     = $testsRun
        TestsPassed  = $testsPassed
        TestsFailed  = $testsFailed
        TestsSkipped = $testsSkipped
        Duration     = $duration
    }
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-ProactiveOptimizationTests
