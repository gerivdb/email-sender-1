# Script pour exécuter tous les tests avec couverture de code

# Définir les paramètres
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Unit", "Integration", "Performance", "Workflow", "Error", "Config", "Simple", "PerformanceAdvanced", "WorkflowAdvanced", "UI", "Security", "Documentation", "Installation", "Regression", "Load", "IntegrationRoadmapParser", "Compatibility", "Localization", "LongTermPerformance", "IntegrationReporting")]
    [string]$TestType = "All",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\tests"),

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML = $true,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPerformanceTests = $false,

    [Parameter(Mandatory = $false)]
    [switch]$OpenReport = $true,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateBadge = $true
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

# Définir les chemins des fichiers à tester
$modeManagerScript = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\mode-manager.ps1"
$modeManagerDir = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager"

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Définir les chemins des rapports
$reportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.xml"
$htmlReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.html"
$coverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.xml"
$htmlCoverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.html"

# Afficher les informations
Write-Host "Exécution des tests du mode MANAGER avec couverture de code" -ForegroundColor Cyan
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
Write-Host "Chemin des tests : $PSScriptRoot" -ForegroundColor Cyan
Write-Host "Chemin du rapport : $reportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture : $coverageReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture HTML : $htmlCoverageReportPath" -ForegroundColor Cyan

# Vérifier la version de Pester
$pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version

# Configurer Pester
if ($pesterVersion -ge [Version]"5.0.0") {
    Write-Host "Utilisation de Pester version $pesterVersion" -ForegroundColor Cyan

    # Créer la configuration Pester
    $pesterConfig = New-PesterConfiguration

    # Configurer les tests à exécuter
    if ($TestType -eq "All") {
        $pesterConfig.Run.Path = $PSScriptRoot
    } else {
        $testScript = Join-Path -Path $PSScriptRoot -ChildPath "Test-ModeManager$TestType.ps1"
        if (Test-Path -Path $testScript) {
            $pesterConfig.Run.Path = $testScript
        } else {
            Write-Warning "Le script de test pour le type $TestType est introuvable : $testScript"
            $pesterConfig.Run.Path = $PSScriptRoot
        }
    }

    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = "Detailed"
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"
    $pesterConfig.TestResult.OutputPath = $reportPath

    # Configurer la couverture de code
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = @($modeManagerScript)
    $pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"
    $pesterConfig.CodeCoverage.OutputPath = $coverageReportPath

    # Filtrer les tests à exécuter
    if ($SkipPerformanceTests) {
        $pesterConfig.Filter.ExcludeTag = @("Performance")
    }

    # Exécuter les tests
    $testResults = Invoke-Pester -Configuration $pesterConfig
} else {
    Write-Host "Utilisation de Pester version $pesterVersion" -ForegroundColor Cyan

    # Configurer les paramètres Pester
    $pesterParams = @{
        PassThru                     = $true
        OutputFormat                 = "NUnitXml"
        OutputFile                   = $reportPath
        CodeCoverage                 = $modeManagerScript
        CodeCoverageOutputFile       = $coverageReportPath
        CodeCoverageOutputFileFormat = "JaCoCo"
    }

    # Configurer les tests à exécuter
    if ($TestType -eq "All") {
        $pesterParams.Path = $PSScriptRoot
    } else {
        $testScript = Join-Path -Path $PSScriptRoot -ChildPath "Test-ModeManager$TestType.ps1"
        if (Test-Path -Path $testScript) {
            $pesterParams.Path = $testScript
        } else {
            Write-Warning "Le script de test pour le type $TestType est introuvable : $testScript"
            $pesterParams.Path = $PSScriptRoot
        }
    }

    # Filtrer les tests à exécuter
    if ($SkipPerformanceTests) {
        $pesterParams.ExcludeTag = "Performance"
    }

    # Exécuter les tests
    $testResults = Invoke-Pester @pesterParams
}

# Générer le rapport HTML
if ($GenerateHTML) {
    # Vérifier si le rapport XML existe
    if (Test-Path -Path $reportPath) {
        # Vérifier si le module ReportUnit est installé
        if (-not (Get-Module -Name ReportUnit -ListAvailable)) {
            Write-Warning "Le module ReportUnit n'est pas installé. Installation en cours..."
            Install-Module -Name ReportUnit -Force -SkipPublisherCheck
        }

        try {
            # Générer le rapport HTML
            Import-Module -Name ReportUnit
            ConvertTo-ReportUnit -InputFile $reportPath -OutputFile $htmlReportPath
            Write-Host "Rapport HTML généré : $htmlReportPath" -ForegroundColor Green
        } catch {
            Write-Warning "Impossible de générer le rapport HTML : $_"

            # Générer un rapport HTML simple
            $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de tests du mode MANAGER</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .passed { color: green; }
        .failed { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport de tests du mode MANAGER</h1>
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

            Set-Content -Path $htmlReportPath -Value $htmlContent -Encoding UTF8
            Write-Host "Rapport HTML simple généré : $htmlReportPath" -ForegroundColor Green
        }
    } else {
        Write-Warning "Le rapport XML n'a pas été généré. Impossible de créer le rapport HTML."
    }

    # Générer le rapport de couverture HTML
    if (Test-Path -Path $coverageReportPath) {
        try {
            # Vérifier si le module ReportGenerator est installé
            if (-not (Get-Module -Name ReportGenerator -ListAvailable)) {
                Write-Warning "Le module ReportGenerator n'est pas installé. Installation en cours..."
                Install-Module -Name ReportGenerator -Force -SkipPublisherCheck
            }

            # Générer le rapport de couverture HTML
            Import-Module -Name ReportGenerator
            ConvertTo-ReportGeneratorReport -InputFile $coverageReportPath -OutputFile $htmlCoverageReportPath -ReportType "Html"
            Write-Host "Rapport de couverture HTML généré : $htmlCoverageReportPath" -ForegroundColor Green
        } catch {
            Write-Warning "Impossible de générer le rapport de couverture HTML : $_"
        }
    } else {
        Write-Warning "Le rapport de couverture XML n'a pas été généré. Impossible de créer le rapport de couverture HTML."
    }
}

# Ouvrir le rapport HTML
if ($OpenReport -and $GenerateHTML) {
    if (Test-Path -Path $htmlReportPath) {
        Start-Process $htmlReportPath
    }

    if (Test-Path -Path $htmlCoverageReportPath) {
        Start-Process $htmlCoverageReportPath
    }
}

# Afficher le résumé des tests
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "Tests exécutés : $($testResults.TotalCount)" -ForegroundColor Cyan
Write-Host "Tests réussis : " -ForegroundColor Cyan -NoNewline
Write-Host "$($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués : " -ForegroundColor Cyan -NoNewline
Write-Host "$($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés : $($testResults.SkippedCount)" -ForegroundColor Cyan
Write-Host "Durée : $($testResults.Duration.TotalSeconds) secondes" -ForegroundColor Cyan

# Générer un badge de couverture
if ($GenerateBadge) {
    $badgeScript = Join-Path -Path $PSScriptRoot -ChildPath "Generate-CoverageBadge.ps1"
    if (Test-Path -Path $badgeScript) {
        & $badgeScript -CoverageReportPath $coverageReportPath
    } else {
        Write-Warning "Le script de génération de badge est introuvable : $badgeScript"
    }
}

# Retourner le code de sortie
if ($testResults.FailedCount -gt 0) {
    exit 1
} else {
    exit 0
}
