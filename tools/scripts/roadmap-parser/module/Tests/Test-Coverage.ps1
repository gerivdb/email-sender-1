<#
.SYNOPSIS
    Valide la couverture de tests du module RoadmapParser.

.DESCRIPTION
    Ce script analyse la couverture de tests du module RoadmapParser et génère
    un rapport détaillé. Il identifie les fonctions non testées ou insuffisamment
    testées et suggère des améliorations.

.PARAMETER MinCoverage
    Pourcentage minimum de couverture requis. Par défaut: 80.

.PARAMETER OutputPath
    Chemin où enregistrer le rapport de couverture. Si non spécifié, le rapport sera
    enregistré dans le répertoire TestReports à la racine du module.

.PARAMETER GenerateHtmlReport
    Indique s'il faut générer un rapport HTML détaillé.

.EXAMPLE
    .\Test-Coverage.ps1 -MinCoverage 90 -GenerateHtmlReport

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-05-15
#>

[CmdletBinding()]
param(
    [int]$MinCoverage = 80,
    
    [string]$OutputPath,
    
    [switch]$GenerateHtmlReport
)

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Error "Le module Pester est requis pour exécuter ces tests. Installez-le avec 'Install-Module -Name Pester -Force'"
    return
}

# Importer le module Pester
Import-Module Pester -Force

# Déterminer le chemin du module
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent

# Définir le chemin de sortie pour le rapport
if (-not $OutputPath) {
    $OutputPath = Join-Path -Path $moduleRoot -ChildPath "TestReports"
    if (-not (Test-Path -Path $OutputPath -PathType Container)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
}

# Configurer les options de Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = @(
    Join-Path -Path $moduleRoot -ChildPath "Functions\Public\*.ps1"
    Join-Path -Path $moduleRoot -ChildPath "Functions\Private\*.ps1"
)
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "coverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"

# Exécuter les tests avec couverture
Write-Host "Exécution des tests avec analyse de couverture..."
$results = Invoke-Pester -Configuration $pesterConfig

# Analyser les résultats de couverture
$coverageReport = $results.CodeCoverage
$totalCommands = $coverageReport.NumberOfCommandsAnalyzed
$coveredCommands = $coverageReport.NumberOfCommandsExecuted
$missedCommands = $totalCommands - $coveredCommands
$coveragePercent = [math]::Round(($coveredCommands / $totalCommands) * 100, 2)

# Afficher un résumé de la couverture
Write-Host "`nRésumé de la couverture de tests:"
Write-Host "-----------------------------"
Write-Host "Commandes analysées: $totalCommands"
Write-Host "Commandes exécutées: $coveredCommands"
Write-Host "Commandes non couvertes: $missedCommands"
Write-Host "Pourcentage de couverture: $coveragePercent%"

# Vérifier si la couverture minimale est atteinte
if ($coveragePercent -lt $MinCoverage) {
    Write-Host "`nLa couverture de tests est inférieure au minimum requis ($MinCoverage%)." -ForegroundColor Red
} else {
    Write-Host "`nLa couverture de tests est supérieure au minimum requis ($MinCoverage%)." -ForegroundColor Green
}

# Identifier les fonctions non testées ou insuffisamment testées
$functionCoverage = @{}
foreach ($file in $coverageReport.MissedCommands.File | Select-Object -Unique) {
    $fileContent = Get-Content -Path $file -Raw
    $functionMatches = [regex]::Matches($fileContent, 'function\s+([A-Za-z0-9\-]+)')
    
    foreach ($match in $functionMatches) {
        $functionName = $match.Groups[1].Value
        $missedCommands = $coverageReport.MissedCommands | Where-Object { $_.File -eq $file }
        $totalCommands = $coverageReport.AnalyzedCommands | Where-Object { $_.File -eq $file }
        
        $functionMissedCommands = $missedCommands.Count
        $functionTotalCommands = $totalCommands.Count
        $functionCoveredCommands = $functionTotalCommands - $functionMissedCommands
        $functionCoveragePercent = if ($functionTotalCommands -gt 0) {
            [math]::Round(($functionCoveredCommands / $functionTotalCommands) * 100, 2)
        } else {
            0
        }
        
        $functionCoverage[$functionName] = @{
            File = $file
            MissedCommands = $functionMissedCommands
            TotalCommands = $functionTotalCommands
            CoveredCommands = $functionCoveredCommands
            CoveragePercent = $functionCoveragePercent
        }
    }
}

# Afficher les fonctions avec une couverture insuffisante
Write-Host "`nFonctions avec une couverture insuffisante (<$MinCoverage%):"
Write-Host "--------------------------------------------------------"
$insufficientCoverage = $functionCoverage.GetEnumerator() | Where-Object { $_.Value.CoveragePercent -lt $MinCoverage }
if ($insufficientCoverage.Count -eq 0) {
    Write-Host "Aucune fonction n'a une couverture insuffisante." -ForegroundColor Green
} else {
    foreach ($function in $insufficientCoverage) {
        Write-Host "$($function.Key): $($function.Value.CoveragePercent)% ($($function.Value.CoveredCommands)/$($function.Value.TotalCommands))" -ForegroundColor Yellow
    }
}

# Générer un rapport HTML détaillé si demandé
if ($GenerateHtmlReport) {
    $htmlReportPath = Join-Path -Path $OutputPath -ChildPath "coverage-report.html"
    
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de couverture de tests - RoadmapParser</title>
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
    <h1>Rapport de couverture de tests - RoadmapParser</h1>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Date d'exécution : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <div class="progress-container">
            <div class="progress-bar" style="width: $coveragePercent%">
                $coveragePercent%
            </div>
        </div>
        <p>Commandes analysées : <strong>$totalCommands</strong></p>
        <p>Commandes exécutées : <strong>$coveredCommands</strong></p>
        <p>Commandes non couvertes : <strong>$missedCommands</strong></p>
        <p>Pourcentage de couverture : <strong>$coveragePercent%</strong></p>
        <p>Minimum requis : <strong>$MinCoverage%</strong></p>
        <p>Statut : <span class="$(if ($coveragePercent -ge $MinCoverage) { "success" } else { "danger" })"><strong>$(if ($coveragePercent -ge $MinCoverage) { "Conforme" } else { "Non conforme" })</strong></span></p>
    </div>
    
    <h2>Couverture par fonction</h2>
    <table>
        <tr>
            <th>Fonction</th>
            <th>Fichier</th>
            <th>Couverture</th>
            <th>Commandes couvertes</th>
            <th>Total des commandes</th>
        </tr>
"@

    foreach ($function in $functionCoverage.GetEnumerator() | Sort-Object { $_.Value.CoveragePercent }) {
        $coverageClass = if ($function.Value.CoveragePercent -ge $MinCoverage) { "success" } elseif ($function.Value.CoveragePercent -ge 50) { "warning" } else { "danger" }
        $relativePath = $function.Value.File.Replace($moduleRoot, "").TrimStart("\")
        
        $htmlReport += @"
        <tr>
            <td>$($function.Key)</td>
            <td>$relativePath</td>
            <td class="$coverageClass">$($function.Value.CoveragePercent)%</td>
            <td>$($function.Value.CoveredCommands)</td>
            <td>$($function.Value.TotalCommands)</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
    
    <h2>Recommandations</h2>
    <ul>
"@

    if ($insufficientCoverage.Count -eq 0) {
        $htmlReport += @"
        <li class="success">Toutes les fonctions ont une couverture suffisante.</li>
"@
    } else {
        $htmlReport += @"
        <li class="danger">Améliorer la couverture des fonctions suivantes :</li>
        <ul>
"@
        foreach ($function in $insufficientCoverage) {
            $htmlReport += @"
            <li>$($function.Key) ($($function.Value.CoveragePercent)%)</li>
"@
        }
        $htmlReport += @"
        </ul>
"@
    }

    $htmlReport += @"
    </ul>
</body>
</html>
"@

    $htmlReport | Set-Content -Path $htmlReportPath -Encoding UTF8
    Write-Host "`nRapport HTML généré: $htmlReportPath" -ForegroundColor Green
}

# Retourner le résultat
return @{
    CoveragePercent = $coveragePercent
    MinCoverage = $MinCoverage
    IsCompliant = $coveragePercent -ge $MinCoverage
    InsufficientCoverage = $insufficientCoverage
}
