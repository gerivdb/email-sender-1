<#
.SYNOPSIS
    Adaptateur TestOmnibus pour les tests du module ProactiveOptimization.
.DESCRIPTION
    Cet adaptateur permet d'exÃ©cuter les tests du module ProactiveOptimization
    dans le cadre de TestOmnibus, en utilisant les mocks nÃ©cessaires.
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

    # VÃ©rifier que le chemin des tests existe
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

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # ExÃ©cuter les tests avec les mocks
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

    # PrÃ©parer les paramÃ¨tres pour le script de mocks
    $params = @{}

    if ($ShowDetailedResults) {
        $params.Add("ShowDetailedResults", $true)
    }

    if ($GenerateHtmlReport) {
        $params.Add("GenerateCodeCoverage", $true)
    }

    # Mesurer le temps d'exÃ©cution
    $startTime = Get-Date

    # ExÃ©cuter les tests
    try {
        # Capturer la sortie du script pour Ã©viter qu'elle n'encombre la console
        $output = & $mockScriptPath @params -ErrorAction Stop 2>&1

        # Extraire les rÃ©sultats de la sortie
        $testsRun = 0
        $testsPassed = 0
        $testsFailed = 0
        $testsSkipped = 0

        foreach ($line in $output) {
            if ($line -match "Tests exÃ©cutÃ©s: (\d+)") {
                $testsRun = [int]$Matches[1]
            } elseif ($line -match "Tests rÃ©ussis: (\d+)") {
                $testsPassed = [int]$Matches[1]
            } elseif ($line -match "Tests Ã©chouÃ©s: (\d+)") {
                $testsFailed = [int]$Matches[1]
            } elseif ($line -match "Tests ignorÃ©s: (\d+)") {
                $testsSkipped = [int]$Matches[1]
            }
        }

        # CrÃ©er un objet de rÃ©sultats
        $results = [PSCustomObject]@{
            TotalCount   = $testsRun
            PassedCount  = $testsPassed
            FailedCount  = $testsFailed
            SkippedCount = $testsSkipped
            NotRunCount  = 0
        }
    } catch {
        Write-Error "Erreur lors de l'exÃ©cution des tests: $_"
        return @{
            Success      = $false
            ErrorMessage = "Erreur lors de l'exÃ©cution des tests: $_"
            TestsRun     = 0
            TestsPassed  = 0
            TestsFailed  = 0
            Duration     = 0
        }
    }

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds

    # Utiliser les rÃ©sultats dÃ©jÃ  extraits ou les obtenir de l'objet de rÃ©sultats
    if (-not $testsRun) {
        $testsRun = $results.TotalCount
        $testsPassed = $results.PassedCount
        $testsFailed = $results.FailedCount
        $testsSkipped = $results.SkippedCount
    }

    # GÃ©nÃ©rer un rapport HTML si demandÃ©
    if ($GenerateHtmlReport) {
        $reportScriptPath = Join-Path -Path $TestPath -ChildPath "Generate-TestReport.ps1"

        if (Test-Path -Path $reportScriptPath) {
            & $reportScriptPath
        }
    }

    # Retourner les rÃ©sultats
    return @{
        Success      = ($testsFailed -eq 0)
        ErrorMessage = if ($testsFailed -gt 0) { "$testsFailed tests ont Ã©chouÃ©" } else { "" }
        TestsRun     = $testsRun
        TestsPassed  = $testsPassed
        TestsFailed  = $testsFailed
        TestsSkipped = $testsSkipped
        Duration     = $duration
    }
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-ProactiveOptimizationTests
