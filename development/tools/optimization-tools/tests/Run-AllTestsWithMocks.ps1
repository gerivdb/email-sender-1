<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour le module ProactiveOptimization avec des mocks.
.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour le module ProactiveOptimization en utilisant des mocks
    pour simuler les dÃ©pendances externes.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateCodeCoverage,

    [Parameter(Mandatory = $false)]
    [switch]$ShowDetailedResults
)

# Chemin vers les tests
$testsPath = $PSScriptRoot
$modulePath = Split-Path -Path $testsPath -Parent
$scriptFiles = Get-ChildItem -Path $modulePath -Filter "*.ps1" | Where-Object { $_.Name -notlike "Test-*" }

# VÃ©rifier que le module mock UsageMonitor existe
$mockModulePath = Join-Path -Path $testsPath -ChildPath "MockUsageMonitor.psm1"
if (-not (Test-Path -Path $mockModulePath)) {
    Write-Error "Module mock UsageMonitor non trouvÃ©: $mockModulePath"
    exit 1
}

# Charger les fonctions mock pour les tests
$mockFunctionsPath = Join-Path -Path $testsPath -ChildPath "MockFunctions.ps1"
if (Test-Path -Path $mockFunctionsPath) {
    . $mockFunctionsPath
    Write-Host "Fonctions mock chargÃ©es avec succÃ¨s." -ForegroundColor Green
} else {
    Write-Warning "Script de fonctions mock non trouvÃ©: $mockFunctionsPath"
}

# Charger les mocks pour l'accÃ¨s aux fichiers
$mockFileAccessPath = Join-Path -Path $testsPath -ChildPath "MockFileAccess.ps1"
if (Test-Path -Path $mockFileAccessPath) {
    . $mockFileAccessPath
    Write-Host "Mocks pour l'accÃ¨s aux fichiers chargÃ©s avec succÃ¨s." -ForegroundColor Green
} else {
    Write-Warning "Script de mocks pour l'accÃ¨s aux fichiers non trouvÃ©: $mockFileAccessPath"
}

# Charger les mocks pour les fonctions des scripts Ã  tester
$mockScriptFunctionsPath = Join-Path -Path $testsPath -ChildPath "MockScriptFunctions.ps1"
if (Test-Path -Path $mockScriptFunctionsPath) {
    . $mockScriptFunctionsPath
    Write-Host "Mocks pour les fonctions des scripts chargÃ©s avec succÃ¨s." -ForegroundColor Green
} else {
    Write-Warning "Script de mocks pour les fonctions des scripts non trouvÃ©: $mockScriptFunctionsPath"
}

# DÃ©finir les fonctions de mock globales
$global:Test_Path_Mock = { param($Path) Test-MockPath -Path $Path }
$global:Get_Content_Mock = { param($Path, $Raw) Get-MockContent -Path $Path -Raw:$Raw }
$global:Out_File_Mock = { param($FilePath, $InputObject, $Encoding) Out-MockFile -FilePath $FilePath -InputObject $InputObject -Encoding $Encoding }
$global:New_Item_Mock = { param($Path, $ItemType, $Force) New-MockItem -Path $Path -ItemType $ItemType -Force:$Force }

# Afficher les tests qui seront exÃ©cutÃ©s
$testScripts = Get-ChildItem -Path $testsPath -Filter "*.Tests.ps1"
if ($testScripts.Count -eq 0) {
    Write-Error "Aucun test trouvÃ© dans le dossier: $testsPath"
    exit 1
}

Write-Host "Tests Ã  exÃ©cuter:" -ForegroundColor Cyan
foreach ($testScript in $testScripts) {
    Write-Host "  - $($testScript.Name)" -ForegroundColor Cyan
}

# ParamÃ¨tres pour Invoke-Pester
$pesterParams = @{
    Path     = $testsPath
    PassThru = $true
}

# Ajouter les paramÃ¨tres de couverture de code si demandÃ©
if ($GenerateCodeCoverage) {
    $pesterParams.CodeCoverage = $scriptFiles.FullName
    $pesterParams.CodeCoverageOutputFile = Join-Path -Path $testsPath -ChildPath "coverage.xml"
    $pesterParams.CodeCoverageOutputFormat = 'JaCoCo'
}

# Ajouter le paramÃ¨tre de verbositÃ© si demandÃ©
if ($ShowDetailedResults) {
    $pesterParams.Output = 'Detailed'
}

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires pour le module ProactiveOptimization..." -ForegroundColor Cyan
$results = Invoke-Pester @pesterParams

# Afficher le rÃ©sumÃ© des tests
Write-Host "RÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor Cyan
Write-Host "  Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor $(if ($results.PassedCount -eq $results.TotalCount) { 'Green' } else { 'Cyan' })
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { 'Red' } else { 'Cyan' })
Write-Host "  Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Cyan
Write-Host "  Tests non exÃ©cutÃ©s: $($results.NotRunCount)" -ForegroundColor Cyan

# GÃ©nÃ©rer un rapport HTML
$reportPath = Join-Path -Path $modulePath -ChildPath "TestReports"
if (-not (Test-Path -Path $reportPath)) {
    New-Item -Path $reportPath -ItemType Directory -Force | Out-Null
}

$reportFile = Join-Path -Path $reportPath -ChildPath "test_report_$(Get-Date -Format 'yyyy-MM-dd').html"

$htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Tests - ProactiveOptimization</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        .summary {
            display: flex;
            justify-content: space-around;
            margin: 20px 0;
            text-align: center;
        }
        .summary-item {
            padding: 15px;
            border-radius: 5px;
            min-width: 150px;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
        }
        .warning {
            background-color: #fff3cd;
            color: #856404;
        }
        .danger {
            background-color: #f8d7da;
            color: #721c24;
        }
        .info {
            background-color: #d1ecf1;
            color: #0c5460;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f1f1f1;
        }
        .test-result {
            padding: 5px 10px;
            border-radius: 3px;
            font-weight: bold;
        }
        .passed {
            background-color: #d4edda;
            color: #155724;
        }
        .failed {
            background-color: #f8d7da;
            color: #721c24;
        }
        .skipped {
            background-color: #e2e3e5;
            color: #383d41;
        }
        .progress-bar {
            height: 20px;
            background-color: #e9ecef;
            border-radius: 10px;
            margin: 20px 0;
            overflow: hidden;
        }
        .progress {
            height: 100%;
            background-color: #28a745;
            text-align: center;
            color: white;
            line-height: 20px;
        }
        footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #777;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de Tests - Module ProactiveOptimization</h1>
"@

$htmlFooter = @"
        <footer>
            <p>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "dd/MM/yyyy Ã  HH:mm:ss")</p>
        </footer>
    </div>
</body>
</html>
"@

# Calculer les statistiques
$totalTests = $results.TotalCount
$passedTests = $results.PassedCount
$failedTests = $results.FailedCount
$skippedTests = $results.SkippedCount
$notRunTests = $results.NotRunCount
$successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

# GÃ©nÃ©rer le rÃ©sumÃ©
$htmlSummary = @"
        <div class="summary">
            <div class="summary-item info">
                <h3>Total</h3>
                <p>$totalTests tests</p>
            </div>
            <div class="summary-item success">
                <h3>RÃ©ussis</h3>
                <p>$passedTests tests</p>
            </div>
            <div class="summary-item danger">
                <h3>Ã‰chouÃ©s</h3>
                <p>$failedTests tests</p>
            </div>
            <div class="summary-item warning">
                <h3>IgnorÃ©s</h3>
                <p>$skippedTests tests</p>
            </div>
            <div class="summary-item info">
                <h3>Non exÃ©cutÃ©s</h3>
                <p>$notRunTests tests</p>
            </div>
        </div>

        <h2>Taux de rÃ©ussite</h2>
        <div class="progress-bar">
            <div class="progress" style="width: $successRate%">$successRate%</div>
        </div>
"@

# GÃ©nÃ©rer le rapport complet
$htmlContent = $htmlHeader + $htmlSummary + $htmlFooter

# Ã‰crire le rapport dans un fichier
$htmlContent | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "Rapport de test gÃ©nÃ©rÃ© avec succÃ¨s: $reportFile" -ForegroundColor Green

# Ouvrir le rapport dans le navigateur par dÃ©faut
if (Test-Path -Path $reportFile) {
    Start-Process $reportFile
}

# Retourner le code de sortie
exit $results.FailedCount
