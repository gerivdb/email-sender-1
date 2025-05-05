# Script pour exÃ©cuter tous les tests dans un environnement CI/CD

# DÃ©finir les paramÃ¨tres
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

# DÃ©finir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# DÃ©finir les chemins des fichiers Ã  tester
$modeManagerScript = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\mode-manager.ps1"
$modeManagerDir = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager"
$testsDir = Join-Path -Path $modeManagerDir -ChildPath "tests"

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# DÃ©finir les chemins des rapports
$reportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.xml"
$htmlReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-tests.html"
$coverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.xml"
$htmlCoverageReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-coverage.html"
$summaryReportPath = Join-Path -Path $OutputPath -ChildPath "mode-manager-summary.md"

# Afficher les informations
Write-Host "ExÃ©cution des tests du mode MANAGER dans un environnement CI/CD" -ForegroundColor Cyan
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
Write-Host "Chemin des tests : $testsDir" -ForegroundColor Cyan
Write-Host "Chemin du rapport : $reportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport HTML : $htmlReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture : $coverageReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de couverture HTML : $htmlCoverageReportPath" -ForegroundColor Cyan
Write-Host "Chemin du rapport de synthÃ¨se : $summaryReportPath" -ForegroundColor Cyan

# VÃ©rifier la version de PowerShell
$psVersion = $PSVersionTable.PSVersion
Write-Host "Version de PowerShell : $($psVersion.Major).$($psVersion.Minor)" -ForegroundColor Cyan

# VÃ©rifier la version de Pester
$pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
if (-not $pesterVersion) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
    $pesterVersion = (Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
}
Write-Host "Version de Pester : $pesterVersion" -ForegroundColor Cyan

# DÃ©finir les types de tests Ã  exÃ©cuter
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

# Fonction pour exÃ©cuter un type de test
function Invoke-TestType {
    param (
        [string]$TestType
    )
    
    Write-Host "ExÃ©cution des tests de type $TestType..." -ForegroundColor Cyan
    
    # ExÃ©cuter les tests
    $testScript = Join-Path -Path $testsDir -ChildPath "Run-AllTests.ps1"
    $testOutputPath = Join-Path -Path $OutputPath -ChildPath $TestType
    
    if (-not (Test-Path -Path $testOutputPath)) {
        New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
    }
    
    $testResult = & $testScript -TestType $TestType -OutputPath $testOutputPath -GenerateHTML
    
    # VÃ©rifier le rÃ©sultat
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Les tests de type $TestType ont Ã©chouÃ©."
        return $false
    } else {
        Write-Host "Les tests de type $TestType ont rÃ©ussi." -ForegroundColor Green
        return $true
    }
}

# ExÃ©cuter les tests en parallÃ¨le
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
        
        # Limiter le nombre de jobs en parallÃ¨le
        while ((Get-Job -State Running).Count -ge $MaxParallelJobs) {
            Start-Sleep -Seconds 1
        }
    }
    
    # Attendre que tous les jobs soient terminÃ©s
    foreach ($testType in $testTypes) {
        $results[$testType] = Receive-Job -Job $jobs[$testType] -Wait
        Remove-Job -Job $jobs[$testType]
    }
}

# GÃ©nÃ©rer un rapport de synthÃ¨se
$successCount = ($results.Values | Where-Object { $_.Success } | Measure-Object).Count
$failureCount = ($results.Values | Where-Object { -not $_.Success } | Measure-Object).Count
$totalCount = $successCount + $failureCount

$summaryContent = @"
# Rapport de tests du mode MANAGER

## RÃ©sumÃ©

- **Date d'exÃ©cution** : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Version de PowerShell** : $($psVersion.Major).$($psVersion.Minor)
- **Version de Pester** : $pesterVersion
- **Tests rÃ©ussis** : $successCount / $totalCount
- **Tests Ã©chouÃ©s** : $failureCount / $totalCount
- **Taux de rÃ©ussite** : $([math]::Round(($successCount / $totalCount) * 100, 2))%

## DÃ©tails des tests

| Type de test | RÃ©sultat |
|-------------|----------|
"@

foreach ($testType in $testTypes) {
    $success = $results[$testType].Success
    $status = if ($success) { "âœ… RÃ©ussi" } else { "âŒ Ã‰chouÃ©" }
    $summaryContent += "| $testType | $status |`n"
}

$summaryContent | Set-Content -Path $summaryReportPath -Encoding UTF8

# Afficher le rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "Tests rÃ©ussis : $successCount / $totalCount" -ForegroundColor Cyan
Write-Host "Tests Ã©chouÃ©s : $failureCount / $totalCount" -ForegroundColor Cyan
Write-Host "Taux de rÃ©ussite : $([math]::Round(($successCount / $totalCount) * 100, 2))%" -ForegroundColor Cyan

# GÃ©nÃ©rer un rapport de couverture global
if ($GenerateHTML) {
    # VÃ©rifier si le module ReportGenerator est installÃ©
    if (-not (Get-Module -Name ReportGenerator -ListAvailable)) {
        Write-Warning "Le module ReportGenerator n'est pas installÃ©. Installation en cours..."
        Install-Module -Name ReportGenerator -Force -SkipPublisherCheck
    }
    
    # Collecter tous les rapports de couverture
    $coverageReports = Get-ChildItem -Path $OutputPath -Recurse -Filter "*coverage.xml"
    
    if ($coverageReports.Count -gt 0) {
        # GÃ©nÃ©rer un rapport de couverture global
        $coverageReportPaths = $coverageReports.FullName -join ";"
        
        try {
            Import-Module -Name ReportGenerator
            ConvertTo-ReportGeneratorReport -InputFile $coverageReportPaths -OutputFile $htmlCoverageReportPath -ReportType "Html"
            Write-Host "Rapport de couverture HTML global gÃ©nÃ©rÃ© : $htmlCoverageReportPath" -ForegroundColor Green
        } catch {
            Write-Warning "Impossible de gÃ©nÃ©rer le rapport de couverture HTML global : $_"
        }
    } else {
        Write-Warning "Aucun rapport de couverture n'a Ã©tÃ© trouvÃ©."
    }
}

# Retourner le code de sortie
if ($FailOnError -and $failureCount -gt 0) {
    exit 1
} else {
    exit 0
}
