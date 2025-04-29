<#
.SYNOPSIS
    Script pour exécuter tous les tests du mode MANAGER.

.DESCRIPTION
    Ce script exécute tous les tests du mode MANAGER et génère un rapport de test.

.PARAMETER OutputPath
    Chemin vers le répertoire de sortie pour les rapports de test.
    Par défaut : "reports".

.PARAMETER GenerateHTML
    Indique si un rapport HTML doit être généré.
    Par défaut : $true.

.EXAMPLE
    .\Run-AllTests.ps1 -OutputPath "reports" -GenerateHTML

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de création: 2023-08-15
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

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# Définir le chemin des tests
$testsPath = $PSScriptRoot

# Définir le chemin de sortie
$outputPath = Join-Path -Path $projectRoot -ChildPath $OutputPath
if (-not (Test-Path -Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# Définir le chemin du rapport
$reportPath = Join-Path -Path $outputPath -ChildPath "mode-manager-tests.xml"
$htmlReportPath = Join-Path -Path $outputPath -ChildPath "mode-manager-tests.html"

# Afficher les informations de démarrage
Write-Host "Exécution des tests du mode MANAGER" -ForegroundColor Cyan
Write-Host "Chemin des tests : $testsPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport : $reportPath" -ForegroundColor Cyan
if ($GenerateHTML) {
    Write-Host "Chemin du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
}

# Vérifier la version de Pester
$pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version

# Configurer les options de Pester en fonction de la version
if ($pesterVersion -ge [Version]"5.0.0") {
    # Pester 5.0 ou supérieur
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
    # Pester 4.x ou inférieur
    Write-Host "Utilisation de Pester version $pesterVersion" -ForegroundColor Cyan
    $pesterConfig = @{
        Path         = $testsPath
        PassThru     = $true
        OutputFormat = 'Detailed'
        OutputFile   = $reportPath
    }
}

# Filtrer les tests à exécuter en fonction des paramètres
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

        # Tests du gestionnaire intégré
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

# Afficher les tests qui seront exécutés
Write-Host "Tests à exécuter :" -ForegroundColor Cyan
foreach ($testFile in $testFiles) {
    Write-Host "- $testFile" -ForegroundColor Yellow
}

# Configurer les tests à exécuter
if ($pesterVersion -ge [Version]"5.0.0") {
    $pesterConfig.Run.Path = $testFiles | ForEach-Object { Join-Path -Path $testsPath -ChildPath $_ }

    # Exécuter les tests
    $testResults = Invoke-Pester -Configuration $pesterConfig
} else {
    # Pour Pester 4.x, nous devons utiliser un tableau de chemins
    $testPaths = $testFiles | ForEach-Object { Join-Path -Path $testsPath -ChildPath $_ }
    $pesterConfig.Path = $testPaths

    # Exécuter les tests
    $testResults = Invoke-Pester @pesterConfig
}

# Générer un rapport HTML si demandé
if ($GenerateHTML) {
    if (Test-Path -Path $reportPath) {
        try {
            # Vérifier si le module ReportUnit est installé
            if (-not (Get-Module -Name ReportUnit -ListAvailable)) {
                Write-Warning "Le module ReportUnit n'est pas installé. Installation en cours..."
                Install-Module -Name ReportUnit -Force -SkipPublisherCheck
            }

            # Générer le rapport HTML
            Import-Module -Name ReportUnit
            ConvertTo-ReportUnit -InputPath $reportPath -OutputPath $htmlReportPath
            Write-Host "Rapport HTML généré : $htmlReportPath" -ForegroundColor Green
        } catch {
            Write-Warning "Impossible de générer le rapport HTML : $_"

            # Méthode alternative : créer un rapport HTML simple
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
        <p>Tests exécutés : $($testResults.TotalCount)</p>
        <p>Tests réussis : <span class="passed">$($testResults.PassedCount)</span></p>
        <p>Tests échoués : <span class="failed">$($testResults.FailedCount)</span></p>
        <p>Tests ignorés : $($testResults.SkippedCount)</p>
        <p>Durée : $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    <h2>Détails des tests</h2>
    <table>
        <tr>
            <th>Nom</th>
            <th>Résultat</th>
            <th>Durée (ms)</th>
        </tr>
"@

            foreach ($test in $testResults.Tests) {
                $result = if ($test.Result -eq "Passed") { "<span class='passed'>Réussi</span>" } else { "<span class='failed'>Échoué</span>" }
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
            Write-Host "Rapport HTML simple généré : $htmlReportPath" -ForegroundColor Green
        }
    } else {
        Write-Warning "Le rapport XML n'a pas été généré. Impossible de créer le rapport HTML."
    }
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "Tests exécutés : $($testResults.TotalCount)" -ForegroundColor Cyan
Write-Host "Tests réussis : " -NoNewline
Write-Host "$($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués : " -NoNewline
Write-Host "$($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés : $($testResults.SkippedCount)" -ForegroundColor Cyan
Write-Host "Durée : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor Cyan

# Retourner le code de sortie
if ($testResults.FailedCount -gt 0) {
    exit 1
} else {
    exit 0
}
