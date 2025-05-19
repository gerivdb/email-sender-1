<#
.SYNOPSIS
    Génère un rapport de couverture de code par phase de test.

.DESCRIPTION
    Ce script génère un rapport de couverture de code pour chaque phase de test
    (P1, P2, P3, P4) et un rapport global pour toutes les phases.

.PARAMETER CoveragePath
    Chemin vers les fichiers de couverture de code générés par Invoke-ProgressiveTest.
    Par défaut: le répertoire temporaire.

.PARAMETER OutputPath
    Chemin vers le répertoire où les rapports de couverture seront générés.
    Par défaut: le sous-répertoire "reports" dans le répertoire courant.

.PARAMETER ModulePath
    Chemin vers les fichiers du module à inclure dans le rapport de couverture.
    Par défaut: le répertoire parent du répertoire contenant ce script.

.PARAMETER GenerateHtml
    Indique si un rapport HTML doit être généré.
    Par défaut: $true.

.PARAMETER GenerateXml
    Indique si un rapport XML doit être généré.
    Par défaut: $true.

.EXAMPLE
    .\Get-ProgressiveTestCoverage.ps1 -OutputPath ".\reports" -ModulePath ".\src"

    Génère des rapports de couverture de code pour chaque phase de test et un rapport global
    à partir des fichiers de couverture dans le répertoire temporaire, et les enregistre
    dans le répertoire ".\reports".

.NOTES
    Version:        1.0.0
    Auteur:         UnifiedParallel Team
    Date création:  2023-05-20
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$CoveragePath = [System.IO.Path]::GetTempPath(),

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "reports"),

    [Parameter(Mandatory = $false)]
    [string]$ModulePath = (Split-Path -Parent $PSScriptRoot),

    [Parameter(Mandatory = $false)]
    [bool]$GenerateHtml = $true,

    [Parameter(Mandatory = $false)]
    [bool]$GenerateXml = $true
)

# Importer le module ProgressiveTestFramework
$frameworkPath = Join-Path -Path $PSScriptRoot -ChildPath "ProgressiveTestFramework.psm1"
if (-not (Test-Path -Path $frameworkPath)) {
    throw "Le module ProgressiveTestFramework n'a pas été trouvé à l'emplacement $frameworkPath."
}
Import-Module $frameworkPath -Force

# Vérifier que le répertoire de couverture existe
if (-not (Test-Path -Path $CoveragePath)) {
    throw "Le répertoire de couverture $CoveragePath n'existe pas."
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Récupérer les fichiers de couverture par phase
$coverageFiles = @{
    'P1'  = Get-ChildItem -Path $CoveragePath -Filter "coverage_P1.xml" -ErrorAction SilentlyContinue
    'P2'  = Get-ChildItem -Path $CoveragePath -Filter "coverage_P2.xml" -ErrorAction SilentlyContinue
    'P3'  = Get-ChildItem -Path $CoveragePath -Filter "coverage_P3.xml" -ErrorAction SilentlyContinue
    'P4'  = Get-ChildItem -Path $CoveragePath -Filter "coverage_P4.xml" -ErrorAction SilentlyContinue
    'All' = Get-ChildItem -Path $CoveragePath -Filter "coverage_All.xml" -ErrorAction SilentlyContinue
}

# Initialiser l'objet de résultat
$coverageResults = [PSCustomObject]@{
    P1  = $null
    P2  = $null
    P3  = $null
    P4  = $null
    All = $null
}

# Traiter chaque phase
foreach ($phase in @('P1', 'P2', 'P3', 'P4', 'All')) {
    $file = $coverageFiles[$phase]
    if ($file) {
        # Analyser le fichier de couverture
        $coverageXml = [xml](Get-Content -Path $file.FullName)
        $totalLines = 0
        $coveredLines = 0

        # Calculer la couverture
        foreach ($package in $coverageXml.report.package) {
            foreach ($class in $package.class) {
                foreach ($line in $class.line) {
                    $totalLines++
                    if ([int]$line.ci -gt 0) {
                        $coveredLines++
                    }
                }
            }
        }

        # Calculer le pourcentage de couverture
        $coveragePercent = if ($totalLines -gt 0) { [math]::Round(($coveredLines / $totalLines) * 100, 2) } else { 0 }

        # Stocker les résultats
        $coverageResults.$phase = [PSCustomObject]@{
            TotalLines      = $totalLines
            CoveredLines    = $coveredLines
            CoveragePercent = $coveragePercent
            FilePath        = $file.FullName
        }

        # Générer un rapport HTML
        if ($GenerateHtml) {
            $reportPath = Join-Path -Path $OutputPath -ChildPath "coverage_$phase.html"

            # Déterminer la classe CSS pour le pourcentage de couverture
            $coverageClass = if ($coveragePercent -ge 80) { 'good' } elseif ($coveragePercent -ge 60) { 'warning' } else { 'bad' }

            $reportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de couverture de code - Phase $phase</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .good { color: green; }
        .warning { color: orange; }
        .bad { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport de couverture de code - Phase $phase</h1>
    <div class="summary">
        <p>Total des lignes: $totalLines</p>
        <p>Lignes couvertes: $coveredLines</p>
        <p>Pourcentage de couverture: <span class="$coverageClass">$coveragePercent%</span></p>
    </div>
</body>
</html>
"@
            Set-Content -Path $reportPath -Value $reportContent
            Write-Host "Rapport de couverture HTML pour la phase $phase généré: $reportPath" -ForegroundColor Green
        }

        # Générer un rapport XML
        if ($GenerateXml) {
            $xmlReportPath = Join-Path -Path $OutputPath -ChildPath "coverage_$phase.xml"
            Copy-Item -Path $file.FullName -Destination $xmlReportPath -Force
            Write-Host "Rapport de couverture XML pour la phase $phase généré: $xmlReportPath" -ForegroundColor Green
        }
    } else {
        Write-Host "Aucun fichier de couverture trouvé pour la phase $phase" -ForegroundColor Yellow
    }
}

# Générer un rapport de couverture global
if ($GenerateHtml) {
    $globalReportPath = Join-Path -Path $OutputPath -ChildPath "coverage_global.html"
    $globalReportContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de couverture de code global</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .good { color: green; }
        .warning { color: orange; }
        .bad { color: red; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Rapport de couverture de code global</h1>
    <div class="summary">
        <table>
            <tr>
                <th>Phase</th>
                <th>Total des lignes</th>
                <th>Lignes couvertes</th>
                <th>Pourcentage de couverture</th>
            </tr>
"@

    foreach ($phase in @('P1', 'P2', 'P3', 'P4', 'All')) {
        $coverage = $coverageResults.$phase
        if ($coverage) {
            $coverageClass = if ($coverage.CoveragePercent -ge 80) { 'good' } elseif ($coverage.CoveragePercent -ge 60) { 'warning' } else { 'bad' }
            $globalReportContent += @"
            <tr>
                <td>$phase</td>
                <td>$($coverage.TotalLines)</td>
                <td>$($coverage.CoveredLines)</td>
                <td class='$coverageClass'>$($coverage.CoveragePercent)%</td>
            </tr>
"@
        } else {
            $globalReportContent += @"
            <tr>
                <td>$phase</td>
                <td colspan="3">Aucune donnée disponible</td>
            </tr>
"@
        }
    }

    $globalReportContent += @"
        </table>
    </div>
</body>
</html>
"@

    Set-Content -Path $globalReportPath -Value $globalReportContent
    Write-Host "Rapport de couverture global généré: $globalReportPath" -ForegroundColor Green
}

# Afficher un résumé des résultats
Write-Host "`nRésumé de la couverture de code:" -ForegroundColor Cyan
foreach ($phase in @('P1', 'P2', 'P3', 'P4', 'All')) {
    $coverage = $coverageResults.$phase
    if ($coverage) {
        $color = if ($coverage.CoveragePercent -ge 80) { 'Green' } elseif ($coverage.CoveragePercent -ge 60) { 'Yellow' } else { 'Red' }
        Write-Host "  Phase $phase : $($coverage.CoveragePercent)% ($($coverage.CoveredLines)/$($coverage.TotalLines) lignes)" -ForegroundColor $color
    } else {
        Write-Host "  Phase $phase : Aucune donnée disponible" -ForegroundColor Gray
    }
}

# Retourner les résultats
return $coverageResults
