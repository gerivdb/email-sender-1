<#
.SYNOPSIS
    Script pour exÃ©cuter tous les tests du mode MANAGER.

.DESCRIPTION
    Ce script exÃ©cute tous les tests du mode MANAGER et gÃ©nÃ¨re un rapport de test.

.PARAMETER OutputPath
    Chemin vers le rÃ©pertoire de sortie pour les rapports de test.
    Par dÃ©faut : "reports".

.PARAMETER GenerateHTML
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ©.
    Par dÃ©faut : $true.

.EXAMPLE
    .\Run-AllTests.ps1 -OutputPath "reports" -GenerateHTML

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "reports",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML,

    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Unit", "Integration", "Performance", "Workflow", "Error", "Config", "Simple", "PerformanceAdvanced", "WorkflowAdvanced", "UI", "Security", "Documentation", "Installation", "Regression", "Load", "IntegrationRoadmapParser", "Compatibility", "Localization", "LongTermPerformance", "IntegrationReporting", "SimpleTest", "SimpleIntegratedManager", "SimpleRoadmapModes", "SimpleWorkflows", "UnitIntegratedManager", "UnitRoadmapModes", "UnitWorkflows", "IntegratedManager")]
    [string]$TestType = "All",

    [Parameter(Mandatory = $false)]
    [switch]$SkipPerformanceTests = $false
)

# Importer le module Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# DÃ©finir le chemin des tests
$testsPath = $PSScriptRoot

# DÃ©finir le chemin de sortie
$outputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
if (-not (Test-Path -Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# DÃ©finir le chemin du rapport
$reportPath = Join-Path -Path $outputPath -ChildPath "mode-manager-tests.xml"
$htmlReportPath = Join-Path -Path $outputPath -ChildPath "mode-manager-tests.html"

# Afficher les informations de dÃ©marrage
Write-Host "ExÃ©cution des tests du mode MANAGER" -ForegroundColor Cyan
Write-Host "Chemin des tests : $testsPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport : $reportPath" -ForegroundColor Cyan
if ($GenerateHTML) {
    Write-Host "Chemin du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
}

# VÃ©rifier la version de Pester
$pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version

# Configurer les options de Pester en fonction de la version
if ($pesterVersion -ge [Version]"5.0.0") {
    # Pester 5.0 ou supÃ©rieur
    Write-Host "Utilisation de Pester version $pesterVersion" -ForegroundColor Cyan
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $testsPath
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = 'Detailed'
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = $reportPath
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    if ($pesterVersion -ge [Version]"5.1.0") {
        $pesterConfig.CodeCoverage.Enabled = $true
    }
} else {
    # Pester 4.x ou infÃ©rieur
    Write-Host "Utilisation de Pester version $pesterVersion" -ForegroundColor Cyan
    $pesterConfig = @{
        Path         = $testsPath
        PassThru     = $true
        OutputFormat = 'Detailed'
        OutputFile   = $reportPath
    }
}

# Filtrer les tests Ã  exÃ©cuter en fonction des paramÃ¨tres
$testFiles = @()

switch ($TestType) {
    "All" {
        # Tests du mode manager
        $testFiles += "Test-ModeManager.ps1"
        $testFiles += "Test-ModeManagerIntegration.ps1"
        $testFiles += "Simple-Test.ps1"
        $testFiles += "Test-ModeManagerWorkflows.ps1"
        $testFiles += "Test-ModeManagerErrors.ps1"
        $testFiles += "Test-ModeManagerConfigs.ps1"
        $testFiles += "Test-ModeManagerWorkflowsAdvanced.ps1"
        $testFiles += "Test-ModeManagerUI.ps1"
        $testFiles += "Test-ModeManagerSecurity.ps1"
        $testFiles += "Test-ModeManagerDocumentation.ps1"
        $testFiles += "Test-ModeManagerInstallation.ps1"
        $testFiles += "Test-ModeManagerRegression.ps1"
        $testFiles += "Test-ModeManagerIntegrationRoadmapParser.ps1"
        $testFiles += "Test-ModeManagerCompatibility.ps1"
        $testFiles += "Test-ModeManagerLocalization.ps1"
        $testFiles += "Test-ModeManagerIntegrationReporting.ps1"

        # Tests du gestionnaire intÃ©grÃ©
        $testFiles += "Test-SimpleIntegratedManager.ps1"
        $testFiles += "Test-SimpleRoadmapModes.ps1"
        $testFiles += "Test-SimpleWorkflows.ps1"
        $testFiles += "Test-UnitIntegratedManager.ps1"
        $testFiles += "Test-UnitRoadmapModes.ps1"
        $testFiles += "Test-UnitWorkflows.ps1"

        if (-not $SkipPerformanceTests) {
            $testFiles += "Test-ModeManagerPerformance.ps1"
            $testFiles += "Test-ModeManagerPerformanceAdvanced.ps1"
            $testFiles += "Test-ModeManagerLoad.ps1"
            $testFiles += "Test-ModeManagerLongTermPerformanceSimple.ps1"
        }
    }
    "Unit" {
        $testFiles += "Test-ModeManager.ps1"
    }
    "Integration" {
        $testFiles += "Test-ModeManagerIntegration.ps1"
    }
    "Performance" {
        $testFiles += "Test-ModeManagerPerformance.ps1"
    }
    "Simple" {
        $testFiles += "Simple-Test.ps1"
    }
    "SimpleTest" {
        $testFiles += "Simple-Test.ps1"
    }
    "Workflow" {
        $testFiles += "Test-ModeManagerWorkflows.ps1"
    }
    "Error" {
        $testFiles += "Test-ModeManagerErrors.ps1"
    }
    "Config" {
        $testFiles += "Test-ModeManagerConfigs.ps1"
    }
    "PerformanceAdvanced" {
        $testFiles += "Test-ModeManagerPerformanceAdvanced.ps1"
    }
    "WorkflowAdvanced" {
        $testFiles += "Test-ModeManagerWorkflowsAdvanced.ps1"
    }
    "UI" {
        $testFiles += "Test-ModeManagerUI.ps1"
    }
    "Security" {
        $testFiles += "Test-ModeManagerSecurity.ps1"
    }
    "Documentation" {
        $testFiles += "Test-ModeManagerDocumentation.ps1"
    }
    "Installation" {
        $testFiles += "Test-ModeManagerInstallation.ps1"
    }
    "Regression" {
        $testFiles += "Test-ModeManagerRegression.ps1"
    }
    "Load" {
        $testFiles += "Test-ModeManagerLoad.ps1"
    }
    "IntegrationRoadmapParser" {
        $testFiles += "Test-ModeManagerIntegrationRoadmapParser.ps1"
    }
    "Compatibility" {
        $testFiles += "Test-ModeManagerCompatibility.ps1"
    }
    "Localization" {
        $testFiles += "Test-ModeManagerLocalization.ps1"
    }
    "LongTermPerformance" {
        $testFiles += "Test-ModeManagerLongTermPerformanceSimple.ps1"
    }
    "IntegrationReporting" {
        $testFiles += "Test-ModeManagerIntegrationReporting.ps1"
    }
    "SimpleIntegratedManager" {
        $testFiles += "Test-SimpleIntegratedManager.ps1"
    }
    "SimpleRoadmapModes" {
        $testFiles += "Test-SimpleRoadmapModes.ps1"
    }
    "SimpleWorkflows" {
        $testFiles += "Test-SimpleWorkflows.ps1"
    }
    "UnitIntegratedManager" {
        $testFiles += "Test-UnitIntegratedManager.ps1"
    }
    "UnitRoadmapModes" {
        $testFiles += "Test-UnitRoadmapModes.ps1"
    }
    "UnitWorkflows" {
        $testFiles += "Test-UnitWorkflows.ps1"
    }
    "IntegratedManager" {
        $testFiles += "Test-SimpleIntegratedManager.ps1"
        $testFiles += "Test-SimpleRoadmapModes.ps1"
        $testFiles += "Test-SimpleWorkflows.ps1"
        $testFiles += "Test-UnitIntegratedManager.ps1"
        $testFiles += "Test-UnitRoadmapModes.ps1"
        $testFiles += "Test-UnitWorkflows.ps1"
    }
}

# Afficher les tests qui seront exÃ©cutÃ©s
Write-Host "Tests Ã  exÃ©cuter :" -ForegroundColor Cyan
foreach ($testFile in $testFiles) {
    Write-Host "- $testFile" -ForegroundColor Yellow
}

# Configurer les tests Ã  exÃ©cuter
if ($pesterVersion -ge [Version]"5.0.0") {
    $pesterConfig.Run.Path = $testFiles | ForEach-Object { Join-Path -Path $testsPath -ChildPath $_ }

    # ExÃ©cuter les tests
    $testResults = Invoke-Pester -Configuration $pesterConfig
} else {
    # Pour Pester 4.x, nous devons utiliser un tableau de chemins
    $testPaths = $testFiles | ForEach-Object { Join-Path -Path $testsPath -ChildPath $_ }
    $pesterConfig.Path = $testPaths

    # ExÃ©cuter les tests
    $testResults = Invoke-Pester @pesterConfig
}

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHTML) {
    if (Test-Path -Path $reportPath) {
        try {
            # VÃ©rifier si le module ReportUnit est installÃ©
            if (-not (Get-Module -Name ReportUnit -ListAvailable)) {
                Write-Warning "Le module ReportUnit n'est pas installÃ©. Installation en cours..."
                Install-Module -Name ReportUnit -Force -SkipPublisherCheck
            }

            # GÃ©nÃ©rer le rapport HTML
            Import-Module -Name ReportUnit
            ConvertTo-ReportUnit -InputPath $reportPath -OutputPath $htmlReportPath
            Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $htmlReportPath" -ForegroundColor Green
        } catch {
            Write-Warning "Impossible de gÃ©nÃ©rer le rapport HTML : $_"

            # MÃ©thode alternative : crÃ©er un rapport HTML simple
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de test du mode MANAGER</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin-bottom: 20px; }
        .passed { color: green; }
        .failed { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport de test du mode MANAGER</h1>
    <div class="summary">
        <p>Tests exÃ©cutÃ©s : $($testResults.TotalCount)</p>
        <p>Tests rÃ©ussis : <span class="passed">$($testResults.PassedCount)</span></p>
        <p>Tests Ã©chouÃ©s : <span class="failed">$($testResults.FailedCount)</span></p>
        <p>Tests ignorÃ©s : $($testResults.SkippedCount)</p>
        <p>DurÃ©e : $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    <h2>DÃ©tails des tests</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>RÃ©sultat</th>
            <th>DurÃ©e (ms)</th>
        </tr>
"@

            foreach ($test in $testResults.Tests) {
                $result = if ($test.Result -eq "Passed") { "<span class='passed'>RÃ©ussi</span>" } else { "<span class='failed'>Ã‰chouÃ©</span>" }
                $htmlContent += @"
        <tr>
            <td>$($test.Name)</td>
            <td>$result</td>
            <td>$($test.Duration.TotalMilliseconds)</td>
        </tr>
"@
            }

            $htmlContent += @"
    </table>
</body>
</html>
"@

            Set-Content -Path $htmlReportPath -Value $htmlContent
            Write-Host "Rapport HTML simple gÃ©nÃ©rÃ© : $htmlReportPath" -ForegroundColor Green
        }
    } else {
        Write-Warning "Le rapport XML n'a pas Ã©tÃ© gÃ©nÃ©rÃ©. Impossible de crÃ©er le rapport HTML."
    }
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "Tests exÃ©cutÃ©s : $($testResults.TotalCount)" -ForegroundColor Cyan
Write-Host "Tests rÃ©ussis : " -NoNewline
Write-Host "$($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s : " -NoNewline
Write-Host "$($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorÃ©s : $($testResults.SkippedCount)" -ForegroundColor Cyan
Write-Host "DurÃ©e : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor Cyan

# Retourner le code de sortie
if ($testResults.FailedCount -gt 0) {
    exit 1
} else {
    exit 0
}
