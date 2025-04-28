<#
.SYNOPSIS
    GÃ©nÃ¨re un rapport de couverture de code pour TestOmnibus.
.DESCRIPTION
    Ce script gÃ©nÃ¨re un rapport de couverture de code pour TestOmnibus en utilisant
    les donnÃ©es de couverture gÃ©nÃ©rÃ©es par Pester.
.PARAMETER CoveragePath
    Chemin vers le fichier de couverture de code au format JaCoCo.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport de couverture de code.
.PARAMETER SourcePath
    Chemin vers les fichiers source Ã  analyser.
.EXAMPLE
    .\Generate-CodeCoverageReport.ps1 -CoveragePath "D:\TestResults\coverage.xml" -OutputPath "D:\TestResults\coverage_report.html" -SourcePath "D:\Scripts"
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$CoveragePath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path (Split-Path -Path $CoveragePath -Parent) -ChildPath "coverage_report.html"),
    
    [Parameter(Mandatory = $false)]
    [string]$SourcePath
)

# VÃ©rifier que le fichier de couverture existe
if (-not (Test-Path -Path $CoveragePath)) {
    Write-Error "Le fichier de couverture n'existe pas: $CoveragePath"
    return 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Fonction pour analyser le fichier de couverture JaCoCo
function Get-JaCoCoData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CoveragePath
    )
    
    try {
        # Charger le fichier XML
        $xml = [xml](Get-Content -Path $CoveragePath -Encoding UTF8)
        
        # Extraire les donnÃ©es de couverture
        $coverageData = @{
            Packages = @()
            TotalLines = 0
            CoveredLines = 0
            TotalBranches = 0
            CoveredBranches = 0
            TotalInstructions = 0
            CoveredInstructions = 0
        }
        
        # Parcourir les packages
        foreach ($package in $xml.report.package) {
            $packageData = @{
                Name = $package.name
                Classes = @()
                TotalLines = 0
                CoveredLines = 0
                TotalBranches = 0
                CoveredBranches = 0
                TotalInstructions = 0
                CoveredInstructions = 0
            }
            
            # Parcourir les classes
            foreach ($class in $package.class) {
                $classData = @{
                    Name = $class.name
                    SourceFile = $class.sourcefilename
                    Methods = @()
                    TotalLines = 0
                    CoveredLines = 0
                    TotalBranches = 0
                    CoveredBranches = 0
                    TotalInstructions = 0
                    CoveredInstructions = 0
                    LinesCovered = @()
                    LinesNotCovered = @()
                }
                
                # Parcourir les mÃ©thodes
                foreach ($method in $class.method) {
                    $methodData = @{
                        Name = $method.name
                        TotalLines = 0
                        CoveredLines = 0
                        TotalBranches = 0
                        CoveredBranches = 0
                        TotalInstructions = 0
                        CoveredInstructions = 0
                    }
                    
                    # Parcourir les compteurs
                    foreach ($counter in $method.counter) {
                        switch ($counter.type) {
                            "LINE" {
                                $methodData.TotalLines = [int]$counter.missed + [int]$counter.covered
                                $methodData.CoveredLines = [int]$counter.covered
                            }
                            "BRANCH" {
                                $methodData.TotalBranches = [int]$counter.missed + [int]$counter.covered
                                $methodData.CoveredBranches = [int]$counter.covered
                            }
                            "INSTRUCTION" {
                                $methodData.TotalInstructions = [int]$counter.missed + [int]$counter.covered
                                $methodData.CoveredInstructions = [int]$counter.covered
                            }
                        }
                    }
                    
                    # Ajouter les donnÃ©es de la mÃ©thode Ã  la classe
                    $classData.Methods += $methodData
                    $classData.TotalLines += $methodData.TotalLines
                    $classData.CoveredLines += $methodData.CoveredLines
                    $classData.TotalBranches += $methodData.TotalBranches
                    $classData.CoveredBranches += $methodData.CoveredBranches
                    $classData.TotalInstructions += $methodData.TotalInstructions
                    $classData.CoveredInstructions += $methodData.CoveredInstructions
                }
                
                # Parcourir les lignes
                foreach ($line in $class.line) {
                    if ([int]$line.ci -gt 0) {
                        $classData.LinesCovered += [int]$line.nr
                    }
                    else {
                        $classData.LinesNotCovered += [int]$line.nr
                    }
                }
                
                # Ajouter les donnÃ©es de la classe au package
                $packageData.Classes += $classData
                $packageData.TotalLines += $classData.TotalLines
                $packageData.CoveredLines += $classData.CoveredLines
                $packageData.TotalBranches += $classData.TotalBranches
                $packageData.CoveredBranches += $classData.CoveredBranches
                $packageData.TotalInstructions += $classData.TotalInstructions
                $packageData.CoveredInstructions += $classData.CoveredInstructions
            }
            
            # Ajouter les donnÃ©es du package au rapport
            $coverageData.Packages += $packageData
            $coverageData.TotalLines += $packageData.TotalLines
            $coverageData.CoveredLines += $packageData.CoveredLines
            $coverageData.TotalBranches += $packageData.TotalBranches
            $coverageData.CoveredBranches += $packageData.CoveredBranches
            $coverageData.TotalInstructions += $packageData.TotalInstructions
            $coverageData.CoveredInstructions += $packageData.CoveredInstructions
        }
        
        return $coverageData
    }
    catch {
        Write-Error "Erreur lors de l'analyse du fichier de couverture: $_"
        return $null
    }
}

# Fonction pour gÃ©nÃ©rer le rapport HTML
function New-CoverageReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$CoverageData,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$SourcePath
    )
    
    # Calculer les pourcentages de couverture
    $lineCoveragePercent = if ($CoverageData.TotalLines -gt 0) { [math]::Round(($CoverageData.CoveredLines / $CoverageData.TotalLines) * 100, 2) } else { 0 }
    $branchCoveragePercent = if ($CoverageData.TotalBranches -gt 0) { [math]::Round(($CoverageData.CoveredBranches / $CoverageData.TotalBranches) * 100, 2) } else { 0 }
    $instructionCoveragePercent = if ($CoverageData.TotalInstructions -gt 0) { [math]::Round(($CoverageData.CoveredInstructions / $CoverageData.TotalInstructions) * 100, 2) } else { 0 }
    
    # GÃ©nÃ©rer le rapport HTML
    $htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de couverture de code</title>
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
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        h2 {
            margin-top: 30px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
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
        .progress {
            height: 20px;
            background-color: #f1f1f1;
            border-radius: 5px;
            overflow: hidden;
            margin-bottom: 10px;
        }
        .progress-bar {
            height: 100%;
            color: white;
            text-align: center;
            line-height: 20px;
        }
        .progress-bar-success {
            background-color: #2ecc71;
        }
        .progress-bar-warning {
            background-color: #f39c12;
        }
        .progress-bar-danger {
            background-color: #e74c3c;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #7f8c8d;
            font-size: 0.9em;
        }
        .chart-container {
            width: 100%;
            height: 300px;
            margin-bottom: 20px;
        }
        .coverage-summary {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        .coverage-item {
            flex: 1;
            text-align: center;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 5px;
            margin: 0 5px;
        }
        .coverage-item h3 {
            margin-top: 0;
        }
        .coverage-percent {
            font-size: 2em;
            font-weight: bold;
        }
        .coverage-high {
            color: #2ecc71;
        }
        .coverage-medium {
            color: #f39c12;
        }
        .coverage-low {
            color: #e74c3c;
        }
        .source-code {
            font-family: monospace;
            white-space: pre;
            overflow-x: auto;
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
        }
        .line-covered {
            background-color: #d5f5e3;
        }
        .line-not-covered {
            background-color: #fadbd8;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport de couverture de code</h1>
        <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "dd/MM/yyyy Ã  HH:mm:ss")</p>
        
        <div class="coverage-summary">
            <div class="coverage-item">
                <h3>Couverture de lignes</h3>
                <div class="coverage-percent $((if ($lineCoveragePercent -ge 80) { "coverage-high" } elseif ($lineCoveragePercent -ge 60) { "coverage-medium" } else { "coverage-low" }))">
                    $lineCoveragePercent%
                </div>
                <p>$($CoverageData.CoveredLines) / $($CoverageData.TotalLines) lignes</p>
            </div>
            <div class="coverage-item">
                <h3>Couverture de branches</h3>
                <div class="coverage-percent $((if ($branchCoveragePercent -ge 80) { "coverage-high" } elseif ($branchCoveragePercent -ge 60) { "coverage-medium" } else { "coverage-low" }))">
                    $branchCoveragePercent%
                </div>
                <p>$($CoverageData.CoveredBranches) / $($CoverageData.TotalBranches) branches</p>
            </div>
            <div class="coverage-item">
                <h3>Couverture d'instructions</h3>
                <div class="coverage-percent $((if ($instructionCoveragePercent -ge 80) { "coverage-high" } elseif ($instructionCoveragePercent -ge 60) { "coverage-medium" } else { "coverage-low" }))">
                    $instructionCoveragePercent%
                </div>
                <p>$($CoverageData.CoveredInstructions) / $($CoverageData.TotalInstructions) instructions</p>
            </div>
        </div>
        
        <div class="chart-container">
            <canvas id="coverageChart"></canvas>
        </div>
        
        <h2>Couverture par package</h2>
        <table>
            <tr>
                <th>Package</th>
                <th>Lignes</th>
                <th>Couverture</th>
                <th>Branches</th>
                <th>Couverture</th>
                <th>Instructions</th>
                <th>Couverture</th>
            </tr>
"@

    foreach ($package in $CoverageData.Packages) {
        $packageLineCoveragePercent = if ($package.TotalLines -gt 0) { [math]::Round(($package.CoveredLines / $package.TotalLines) * 100, 2) } else { 0 }
        $packageBranchCoveragePercent = if ($package.TotalBranches -gt 0) { [math]::Round(($package.CoveredBranches / $package.TotalBranches) * 100, 2) } else { 0 }
        $packageInstructionCoveragePercent = if ($package.TotalInstructions -gt 0) { [math]::Round(($package.CoveredInstructions / $package.TotalInstructions) * 100, 2) } else { 0 }
        
        $htmlReport += @"
            <tr>
                <td>$($package.Name)</td>
                <td>$($package.CoveredLines) / $($package.TotalLines)</td>
                <td>
                    <div class="progress">
                        <div class="progress-bar $((if ($packageLineCoveragePercent -ge 80) { "progress-bar-success" } elseif ($packageLineCoveragePercent -ge 60) { "progress-bar-warning" } else { "progress-bar-danger" }))" style="width: $packageLineCoveragePercent%">
                            $packageLineCoveragePercent%
                        </div>
                    </div>
                </td>
                <td>$($package.CoveredBranches) / $($package.TotalBranches)</td>
                <td>
                    <div class="progress">
                        <div class="progress-bar $((if ($packageBranchCoveragePercent -ge 80) { "progress-bar-success" } elseif ($packageBranchCoveragePercent -ge 60) { "progress-bar-warning" } else { "progress-bar-danger" }))" style="width: $packageBranchCoveragePercent%">
                            $packageBranchCoveragePercent%
                        </div>
                    </div>
                </td>
                <td>$($package.CoveredInstructions) / $($package.TotalInstructions)</td>
                <td>
                    <div class="progress">
                        <div class="progress-bar $((if ($packageInstructionCoveragePercent -ge 80) { "progress-bar-success" } elseif ($packageInstructionCoveragePercent -ge 60) { "progress-bar-warning" } else { "progress-bar-danger" }))" style="width: $packageInstructionCoveragePercent%">
                            $packageInstructionCoveragePercent%
                        </div>
                    </div>
                </td>
            </tr>
"@
    }

    $htmlReport += @"
        </table>
        
        <h2>Couverture par classe</h2>
        <table>
            <tr>
                <th>Classe</th>
                <th>Lignes</th>
                <th>Couverture</th>
                <th>Branches</th>
                <th>Couverture</th>
                <th>Instructions</th>
                <th>Couverture</th>
            </tr>
"@

    foreach ($package in $CoverageData.Packages) {
        foreach ($class in $package.Classes) {
            $classLineCoveragePercent = if ($class.TotalLines -gt 0) { [math]::Round(($class.CoveredLines / $class.TotalLines) * 100, 2) } else { 0 }
            $classBranchCoveragePercent = if ($class.TotalBranches -gt 0) { [math]::Round(($class.CoveredBranches / $class.TotalBranches) * 100, 2) } else { 0 }
            $classInstructionCoveragePercent = if ($class.TotalInstructions -gt 0) { [math]::Round(($class.CoveredInstructions / $class.TotalInstructions) * 100, 2) } else { 0 }
            
            $htmlReport += @"
            <tr>
                <td>$($class.Name)</td>
                <td>$($class.CoveredLines) / $($class.TotalLines)</td>
                <td>
                    <div class="progress">
                        <div class="progress-bar $((if ($classLineCoveragePercent -ge 80) { "progress-bar-success" } elseif ($classLineCoveragePercent -ge 60) { "progress-bar-warning" } else { "progress-bar-danger" }))" style="width: $classLineCoveragePercent%">
                            $classLineCoveragePercent%
                        </div>
                    </div>
                </td>
                <td>$($class.CoveredBranches) / $($class.TotalBranches)</td>
                <td>
                    <div class="progress">
                        <div class="progress-bar $((if ($classBranchCoveragePercent -ge 80) { "progress-bar-success" } elseif ($classBranchCoveragePercent -ge 60) { "progress-bar-warning" } else { "progress-bar-danger" }))" style="width: $classBranchCoveragePercent%">
                            $classBranchCoveragePercent%
                        </div>
                    </div>
                </td>
                <td>$($class.CoveredInstructions) / $($class.TotalInstructions)</td>
                <td>
                    <div class="progress">
                        <div class="progress-bar $((if ($classInstructionCoveragePercent -ge 80) { "progress-bar-success" } elseif ($classInstructionCoveragePercent -ge 60) { "progress-bar-warning" } else { "progress-bar-danger" }))" style="width: $classInstructionCoveragePercent%">
                            $classInstructionCoveragePercent%
                        </div>
                    </div>
                </td>
            </tr>
"@
        }
    }

    $htmlReport += @"
        </table>
"@

    # Ajouter le code source avec la couverture si le chemin source est spÃ©cifiÃ©
    if ($SourcePath -and (Test-Path -Path $SourcePath)) {
        $htmlReport += @"
        <h2>Code source avec couverture</h2>
"@

        foreach ($package in $CoverageData.Packages) {
            foreach ($class in $package.Classes) {
                $sourceFile = Join-Path -Path $SourcePath -ChildPath $class.SourceFile
                
                if (Test-Path -Path $sourceFile) {
                    $htmlReport += @"
        <h3>$($class.Name)</h3>
        <div class="source-code">
"@

                    $lineNumber = 1
                    foreach ($line in Get-Content -Path $sourceFile) {
                        $lineClass = if ($class.LinesCovered -contains $lineNumber) {
                            "line-covered"
                        }
                        elseif ($class.LinesNotCovered -contains $lineNumber) {
                            "line-not-covered"
                        }
                        else {
                            ""
                        }
                        
                        $htmlReport += @"
<div class="$lineClass">$lineNumber: $($line -replace "<", "&lt;" -replace ">", "&gt;")</div>
"@
                        
                        $lineNumber++
                    }
                    
                    $htmlReport += @"
        </div>
"@
                }
            }
        }
    }

    $htmlReport += @"
        <script>
            // CrÃ©er un graphique de couverture
            const ctx = document.getElementById('coverageChart').getContext('2d');
            const coverageChart = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: ['Lignes', 'Branches', 'Instructions'],
                    datasets: [{
                        label: 'Couverture (%)',
                        data: [$lineCoveragePercent, $branchCoveragePercent, $instructionCoveragePercent],
                        backgroundColor: [
                            '$((if ($lineCoveragePercent -ge 80) { "#2ecc71" } elseif ($lineCoveragePercent -ge 60) { "#f39c12" } else { "#e74c3c" }))',
                            '$((if ($branchCoveragePercent -ge 80) { "#2ecc71" } elseif ($branchCoveragePercent -ge 60) { "#f39c12" } else { "#e74c3c" }))',
                            '$((if ($instructionCoveragePercent -ge 80) { "#2ecc71" } elseif ($instructionCoveragePercent -ge 60) { "#f39c12" } else { "#e74c3c" }))'
                        ],
                        borderColor: [
                            '$((if ($lineCoveragePercent -ge 80) { "#27ae60" } elseif ($lineCoveragePercent -ge 60) { "#e67e22" } else { "#c0392b" }))',
                            '$((if ($branchCoveragePercent -ge 80) { "#27ae60" } elseif ($branchCoveragePercent -ge 60) { "#e67e22" } else { "#c0392b" }))',
                            '$((if ($instructionCoveragePercent -ge 80) { "#27ae60" } elseif ($instructionCoveragePercent -ge 60) { "#e67e22" } else { "#c0392b" }))'
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        },
                        title: {
                            display: true,
                            text: 'Couverture de code'
                        }
                    }
                }
            });
        </script>
        
        <div class="footer">
            <p>GÃ©nÃ©rÃ© par TestOmnibus Code Coverage</p>
        </div>
    </div>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($OutputPath, $htmlReport, $utf8WithBom)
    
    return $OutputPath
}

# Point d'entrÃ©e principal
try {
    # Analyser le fichier de couverture
    Write-Host "Analyse du fichier de couverture: $CoveragePath" -ForegroundColor Cyan
    $coverageData = Get-JaCoCoData -CoveragePath $CoveragePath
    
    if (-not $coverageData) {
        Write-Error "Impossible d'analyser le fichier de couverture."
        return 1
    }
    
    # GÃ©nÃ©rer le rapport HTML
    Write-Host "GÃ©nÃ©ration du rapport de couverture de code..." -ForegroundColor Cyan
    $reportPath = New-CoverageReport -CoverageData $coverageData -OutputPath $OutputPath -SourcePath $SourcePath
    
    Write-Host "Rapport de couverture de code gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green
    
    return $reportPath
}
catch {
    Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport de couverture de code: $_"
    return 1
}
