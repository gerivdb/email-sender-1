# Script pour exécuter tous les tests dans un environnement CI/CD

# Définir les paramètres
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\reports\tests"),

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML = $true,

    [Parameter(Mandatory = $false)]
    [switch]$SkipPerformanceTests = $false,

    [Parameter(Mandatory = $false)]
    [switch]$FailOnError = $true,

    [Parameter(Mandatory = $false)]
    [int]$MaxParallelJobs = 4
)

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
$testsDir = Join-Path -Path $modeManagerDir -ChildPath "tests"

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Définir les chemins des rapports
$reportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.xml"
$htmlReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.html"
$coverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.xml"
$htmlCoverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.html"
$summaryReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-summary.md"

# Afficher les informations
Write-Host "Exécution des tests du mode MANAGER dans un environnement CI/CD" -ForegroundColor Cyan
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
Write-Host "Chemin des tests : $testsDir" -ForegroundColor Cyan
Write-Host "Chemin du rapport : $reportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture : $coverageReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture HTML : $htmlCoverageReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de synthèse : $summaryReportPath" -ForegroundColor Cyan

# Vérifier la version de PowerShell
$psVersion = $PSVersionTable.PSVersion
Write-Host "Version de PowerShell : $($psVersion.Major).$($psVersion.Minor)" -ForegroundColor Cyan

# Vérifier la version de Pester
$pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
if (-not $pesterVersion) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
    $pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
}
Write-Host "Version de Pester : $pesterVersion" -ForegroundColor Cyan

# Définir les types de tests à exécuter
$testTypes = @(
    "Unit",
    "Integration",
    "Workflow",
    "Error",
    "Config",
    "Simple",
    "WorkflowAdvanced",
    "UI",
    "Security",
    "Documentation",
    "Installation",
    "Regression",
    "IntegrationRoadmapParser",
    "Compatibility",
    "Localization",
    "IntegrationReporting"
)

if (-not $SkipPerformanceTests) {
    $testTypes += @(
        "Performance",
        "PerformanceAdvanced",
        "Load"
    )
}

# Fonction pour exécuter un type de test
function Invoke-TestType {
    param (
        [string]$TestType
    )
    
    Write-Host "Exécution des tests de type $TestType..." -ForegroundColor Cyan
    
    # Exécuter les tests
    $testScript = Join-Path -Path $testsDir -ChildPath "Run-AllTests.ps1"
    $testOutputPath = Join-Path -Path $OutputPath -ChildPath $TestType
    
    if (-not (Test-Path -Path $testOutputPath)) {
        New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
    }
    
    $testResult = & $testScript -TestType $TestType -OutputPath $testOutputPath -GenerateHTML
    
    # Vérifier le résultat
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Les tests de type $TestType ont échoué."
        return $false
    } else {
        Write-Host "Les tests de type $TestType ont réussi." -ForegroundColor Green
        return $true
    }
}

# Exécuter les tests en parallèle
$results = @{}
$jobs = @{}

if ($psVersion.Major -ge 7) {
    # PowerShell 7+ : utiliser ForEach-Object -Parallel
    $results = $testTypes | ForEach-Object -ThrottleLimit $MaxParallelJobs -Parallel {
        $testType = $_
        $result = & $using:PSScriptRoot\Run-AllTests.ps1 -TestType $testType -OutputPath "$using:OutputPath\$testType" -GenerateHTML
        return @{
            TestType = $testType
            Success = ($LASTEXITCODE -eq 0)
        }
    }
} else {
    # PowerShell 5.1 : utiliser des jobs
    foreach ($testType in $testTypes) {
        $jobs[$testType] = Start-Job -ScriptBlock {
            param($testType, $scriptRoot, $outputPath)
            & "$scriptRoot\Run-AllTests.ps1" -TestType $testType -OutputPath "$outputPath\$testType" -GenerateHTML
            return @{
                TestType = $testType
                Success = ($LASTEXITCODE -eq 0)
            }
        } -ArgumentList $testType, $PSScriptRoot, $OutputPath
        
        # Limiter le nombre de jobs en parallèle
        while ((Get-Job -State Running).Count -ge $MaxParallelJobs) {
            Start-Sleep -Seconds 1
        }
    }
    
    # Attendre que tous les jobs soient terminés
    foreach ($testType in $testTypes) {
        $results[$testType] = Receive-Job -Job $jobs[$testType] -Wait
        Remove-Job -Job $jobs[$testType]
    }
}

# Générer un rapport de synthèse
$successCount = ($results.Values | Where-Object { $_.Success } | Measure-Object).Count
$failureCount = ($results.Values | Where-Object { -not $_.Success } | Measure-Object).Count
$totalCount = $successCount + $failureCount

$summaryContent = @"
# Rapport de tests du mode MANAGER

## Résumé

- **Date d'exécution** : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Version de PowerShell** : $($psVersion.Major).$($psVersion.Minor)
- **Version de Pester** : $pesterVersion
- **Tests réussis** : $successCount / $totalCount
- **Tests échoués** : $failureCount / $totalCount
- **Taux de réussite** : $([math]::Round(($successCount / $totalCount) * 100, 2))%

## Détails des tests

| Type de test | Résultat |
|-------------|----------|
"@

foreach ($testType in $testTypes) {
    $success = $results[$testType].Success
    $status = if ($success) { "✅ Réussi" } else { "❌ Échoué" }
    $summaryContent += "| $testType | $status |`n"
}

$summaryContent | Set-Content -Path $summaryReportPath -Encoding UTF8

# Afficher le résumé
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "Tests réussis : $successCount / $totalCount" -ForegroundColor Cyan
Write-Host "Tests échoués : $failureCount / $totalCount" -ForegroundColor Cyan
Write-Host "Taux de réussite : $([math]::Round(($successCount / $totalCount) * 100, 2))%" -ForegroundColor Cyan

# Générer un rapport de couverture global
if ($GenerateHTML) {
    # Vérifier si le module ReportGenerator est installé
    if (-not (Get-Module -Name ReportGenerator -ListAvailable)) {
        Write-Warning "Le module ReportGenerator n'est pas installé. Installation en cours..."
        Install-Module -Name ReportGenerator -Force -SkipPublisherCheck
    }
    
    # Collecter tous les rapports de couverture
    $coverageReports = Get-ChildItem -Path $OutputPath -Recurse -Filter "*coverage.xml"
    
    if ($coverageReports.Count -gt 0) {
        # Générer un rapport de couverture global
        $coverageReportPaths = $coverageReports.FullName -join ";"
        
        try {
            Import-Module -Name ReportGenerator
            ConvertTo-ReportGeneratorReport -InputFile $coverageReportPaths -OutputFile $htmlCoverageReportPath -ReportType "Html"
            Write-Host "Rapport de couverture HTML global généré : $htmlCoverageReportPath" -ForegroundColor Green
        } catch {
            Write-Warning "Impossible de générer le rapport de couverture HTML global : $_"
        }
    } else {
        Write-Warning "Aucun rapport de couverture n'a été trouvé."
    }
}

# Retourner le code de sortie
if ($FailOnError -and $failureCount -gt 0) {
    exit 1
} else {
    exit 0
}
