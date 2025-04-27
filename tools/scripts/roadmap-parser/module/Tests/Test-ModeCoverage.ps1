<#
.SYNOPSIS
    VÃ©rifie la couverture de tests pour tous les modes.

.DESCRIPTION
    Ce script vÃ©rifie que tous les modes ont des tests associÃ©s et que ces tests
    couvrent correctement les fonctionnalitÃ©s des modes. Il gÃ©nÃ¨re un rapport
    de couverture pour chaque mode et un rapport global.

.PARAMETER OutputPath
    Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les rapports de couverture.

.PARAMETER MinimumCoverage
    Pourcentage minimum de couverture requis pour considÃ©rer qu'un mode est correctement testÃ©.

.PARAMETER ShowResults
    Indique si les rÃ©sultats de la vÃ©rification doivent Ãªtre affichÃ©s dans la console.

.PARAMETER GenerateReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ©.

.EXAMPLE
    .\Test-ModeCoverage.ps1 -OutputPath "coverage-reports" -MinimumCoverage 80 -ShowResults $true -GenerateReport $true

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "coverage-reports",
    
    [Parameter(Mandatory = $false)]
    [int]$MinimumCoverage = 80,
    
    [Parameter(Mandatory = $false)]
    [bool]$ShowResults = $true,
    
    [Parameter(Mandatory = $false)]
    [bool]$GenerateReport = $true
)

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
        Import-Module Pester
        Write-Host "Module Pester installÃ© avec succÃ¨s." -ForegroundColor Green
    } catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
} else {
    Import-Module Pester
    Write-Host "Module Pester dÃ©jÃ  installÃ©." -ForegroundColor Green
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath" -ForegroundColor Green
}

# Chemin vers les scripts et les tests
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)

# Trouver tous les scripts de mode
$modeScripts = Get-ChildItem -Path $projectRoot -Filter "*-mode.ps1"
$modeTests = Get-ChildItem -Path $scriptPath -Filter "Test-*Mode.ps1" | Where-Object { $_.Name -ne "Test-ModeCoverage.ps1" -and $_.Name -ne "Test-ModesIntegration.ps1" -and $_.Name -ne "Test-ModesDataSharing.ps1" }

Write-Host "Scripts de mode trouvÃ©s : $($modeScripts.Count)" -ForegroundColor Green
foreach ($modeScript in $modeScripts) {
    Write-Host "  - $($modeScript.Name)" -ForegroundColor Gray
}

Write-Host "Tests de mode trouvÃ©s : $($modeTests.Count)" -ForegroundColor Green
foreach ($modeTest in $modeTests) {
    Write-Host "  - $($modeTest.Name)" -ForegroundColor Gray
}

# VÃ©rifier que chaque script de mode a un test associÃ©
$missingTests = @()
foreach ($modeScript in $modeScripts) {
    $modeName = $modeScript.BaseName -replace "-mode", ""
    $expectedTestName = "Test-$($modeName.Substring(0, 1).ToUpper() + $modeName.Substring(1))Mode.ps1"
    
    if (-not ($modeTests | Where-Object { $_.Name -eq $expectedTestName })) {
        $missingTests += $modeScript.Name
    }
}

if ($missingTests.Count -gt 0) {
    Write-Warning "Les scripts de mode suivants n'ont pas de test associÃ© : $($missingTests -join ', ')"
}

# VÃ©rifier la couverture de tests pour chaque mode
$coverageResults = @()

foreach ($modeTest in $modeTests) {
    $modeName = $modeTest.BaseName -replace "Test-", "" -replace "Mode", ""
    $modeScriptName = "$($modeName.ToLower())-mode.ps1"
    $modeScriptPath = Join-Path -Path $projectRoot -ChildPath $modeScriptName
    
    if (Test-Path -Path $modeScriptPath) {
        Write-Host "VÃ©rification de la couverture pour le mode $modeName..." -ForegroundColor Yellow
        
        # Configuration des tests
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = $modeTest.FullName
        $pesterConfig.Run.PassThru = $true
        $pesterConfig.Output.Verbosity = 'Detailed'
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.CodeCoverage.Path = @($modeScriptPath)
        $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "coverage-$($modeName.ToLower()).xml"
        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
        
        # ExÃ©cuter les tests
        $testResults = Invoke-Pester -Configuration $pesterConfig
        
        # Calculer la couverture
        $coverage = 0
        if ($testResults.CodeCoverage.CommandsExecutedCount -gt 0) {
            $coverage = [Math]::Round(($testResults.CodeCoverage.CommandsExecutedCount / $testResults.CodeCoverage.CommandsAnalyzedCount) * 100)
        }
        
        # Ajouter les rÃ©sultats
        $coverageResults += [PSCustomObject]@{
            Mode = $modeName
            Script = $modeScriptName
            Test = $modeTest.Name
            Coverage = $coverage
            Status = if ($coverage -ge $MinimumCoverage) { "OK" } else { "Insuffisant" }
            CommandsAnalyzed = $testResults.CodeCoverage.CommandsAnalyzedCount
            CommandsExecuted = $testResults.CodeCoverage.CommandsExecutedCount
            TestsTotal = $testResults.TotalCount
            TestsPassed = $testResults.PassedCount
            TestsFailed = $testResults.FailedCount
            TestsSkipped = $testResults.SkippedCount
        }
    } else {
        Write-Warning "Le script de mode $modeScriptName n'existe pas."
    }
}

# Afficher les rÃ©sultats
if ($ShowResults) {
    Write-Host "`nRÃ©sultats de la couverture de tests :" -ForegroundColor Yellow
    
    foreach ($result in $coverageResults) {
        $statusColor = if ($result.Status -eq "OK") { "Green" } else { "Red" }
        
        Write-Host "Mode : $($result.Mode)" -ForegroundColor Cyan
        Write-Host "  - Script : $($result.Script)" -ForegroundColor Gray
        Write-Host "  - Test : $($result.Test)" -ForegroundColor Gray
        Write-Host "  - Couverture : $($result.Coverage)%" -ForegroundColor $(if ($result.Coverage -ge $MinimumCoverage) { "Green" } else { "Red" })
        Write-Host "  - Status : $($result.Status)" -ForegroundColor $statusColor
        Write-Host "  - Commandes analysÃ©es : $($result.CommandsAnalyzed)" -ForegroundColor Gray
        Write-Host "  - Commandes exÃ©cutÃ©es : $($result.CommandsExecuted)" -ForegroundColor Gray
        Write-Host "  - Tests exÃ©cutÃ©s : $($result.TestsTotal)" -ForegroundColor Gray
        Write-Host "  - Tests rÃ©ussis : $($result.TestsPassed)" -ForegroundColor $(if ($result.TestsPassed -eq $result.TestsTotal) { "Green" } else { "Yellow" })
        Write-Host "  - Tests Ã©chouÃ©s : $($result.TestsFailed)" -ForegroundColor $(if ($result.TestsFailed -eq 0) { "Green" } else { "Red" })
        Write-Host "  - Tests ignorÃ©s : $($result.TestsSkipped)" -ForegroundColor $(if ($result.TestsSkipped -eq 0) { "Green" } else { "Yellow" })
        Write-Host ""
    }
    
    # Afficher un rÃ©sumÃ©
    $averageCoverage = if ($coverageResults.Count -gt 0) { [Math]::Round(($coverageResults | Measure-Object -Property Coverage -Average).Average) } else { 0 }
    $modesWithInsufficientCoverage = $coverageResults | Where-Object { $_.Status -eq "Insuffisant" } | Select-Object -ExpandProperty Mode
    
    Write-Host "RÃ©sumÃ© :" -ForegroundColor Yellow
    Write-Host "  - Nombre de modes testÃ©s : $($coverageResults.Count)" -ForegroundColor Gray
    Write-Host "  - Couverture moyenne : $averageCoverage%" -ForegroundColor $(if ($averageCoverage -ge $MinimumCoverage) { "Green" } else { "Red" })
    Write-Host "  - Modes avec une couverture insuffisante : $($modesWithInsufficientCoverage -join ', ')" -ForegroundColor $(if ($modesWithInsufficientCoverage.Count -eq 0) { "Green" } else { "Red" })
}

# GÃ©nÃ©rer un rapport HTML
if ($GenerateReport) {
    Write-Host "`nGÃ©nÃ©ration du rapport HTML..." -ForegroundColor Yellow
    
    # CrÃ©er le rapport HTML
    $reportPath = Join-Path -Path $OutputPath -ChildPath "coverage-report.html"
    
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de couverture de tests - Modes RoadmapParser</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .success {
            color: #28a745;
        }
        .warning {
            color: #ffc107;
        }
        .danger {
            color: #dc3545;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .progress-container {
            width: 100%;
            height: 20px;
            background-color: #f1f1f1;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .progress-bar {
            height: 20px;
            background-color: #4CAF50;
            border-radius: 5px;
            text-align: center;
            line-height: 20px;
            color: white;
        }
    </style>
</head>
<body>
    <h1>Rapport de couverture de tests - Modes RoadmapParser</h1>
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Date d'exÃ©cution : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p>Nombre de modes testÃ©s : <strong>$($coverageResults.Count)</strong></p>
        <p>Couverture moyenne : <span class="$(if ($averageCoverage -ge $MinimumCoverage) { "success" } else { "danger" })"><strong>$averageCoverage%</strong></span></p>
        <p>Seuil minimum de couverture : <strong>$MinimumCoverage%</strong></p>
        <p>Modes avec une couverture insuffisante : <span class="$(if ($modesWithInsufficientCoverage.Count -eq 0) { "success" } else { "danger" })"><strong>$($modesWithInsufficientCoverage -join ', ')</strong></span></p>
    </div>
    
    <h2>DÃ©tails de la couverture par mode</h2>
    <table>
        <tr>
            <th>Mode</th>
            <th>Script</th>
            <th>Test</th>
            <th>Couverture</th>
            <th>Status</th>
            <th>Commandes analysÃ©es</th>
            <th>Commandes exÃ©cutÃ©es</th>
            <th>Tests exÃ©cutÃ©s</th>
            <th>Tests rÃ©ussis</th>
            <th>Tests Ã©chouÃ©s</th>
            <th>Tests ignorÃ©s</th>
        </tr>
"@

    foreach ($result in $coverageResults) {
        $statusClass = if ($result.Status -eq "OK") { "success" } else { "danger" }
        $coverageClass = if ($result.Coverage -ge $MinimumCoverage) { "success" } else { "danger" }
        $passedClass = if ($result.TestsPassed -eq $result.TestsTotal) { "success" } else { "warning" }
        $failedClass = if ($result.TestsFailed -eq 0) { "success" } else { "danger" }
        $skippedClass = if ($result.TestsSkipped -eq 0) { "success" } else { "warning" }
        
        $htmlReport += @"
        <tr>
            <td>$($result.Mode)</td>
            <td>$($result.Script)</td>
            <td>$($result.Test)</td>
            <td class="$coverageClass">$($result.Coverage)%</td>
            <td class="$statusClass">$($result.Status)</td>
            <td>$($result.CommandsAnalyzed)</td>
            <td>$($result.CommandsExecuted)</td>
            <td>$($result.TestsTotal)</td>
            <td class="$passedClass">$($result.TestsPassed)</td>
            <td class="$failedClass">$($result.TestsFailed)</td>
            <td class="$skippedClass">$($result.TestsSkipped)</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
    
    <h2>Graphique de couverture</h2>
    <div>
"@

    foreach ($result in $coverageResults) {
        $barColor = if ($result.Coverage -ge $MinimumCoverage) { "#4CAF50" } else { "#dc3545" }
        
        $htmlReport += @"
        <div style="margin-bottom: 15px;">
            <p><strong>$($result.Mode)</strong> - $($result.Coverage)%</p>
            <div class="progress-container">
                <div class="progress-bar" style="width: $($result.Coverage)%; background-color: $barColor;">
                    $($result.Coverage)%
                </div>
            </div>
        </div>
"@
    }

    $htmlReport += @"
    </div>
    
    <h2>Modes sans test</h2>
"@

    if ($missingTests.Count -gt 0) {
        $htmlReport += @"
    <table>
        <tr>
            <th>Script</th>
        </tr>
"@

        foreach ($missingTest in $missingTests) {
            $htmlReport += @"
        <tr>
            <td class="danger">$missingTest</td>
        </tr>
"@
        }

        $htmlReport += @"
    </table>
"@
    } else {
        $htmlReport += @"
    <p class="success">Tous les modes ont des tests associÃ©s.</p>
"@
    }

    $htmlReport += @"
</body>
</html>
"@

    $htmlReport | Set-Content -Path $reportPath -Encoding UTF8
    Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $reportPath" -ForegroundColor Green
}

# Retourner les rÃ©sultats
return $coverageResults
