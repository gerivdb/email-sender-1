#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour PSScriptAnalyzer et la fusion des rÃƒÂ©sultats.

.DESCRIPTION
    Ce script teste PSScriptAnalyzer et fusionne ses rÃƒÂ©sultats avec ceux de TodoAnalyzer.

.PARAMETER FilePath
    Chemin du fichier ÃƒÂ  analyser.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃƒÂ©sultats.

.EXAMPLE
    .\Test-PSScriptAnalyzerAndMerge.ps1 -FilePath ".\development\scripts\analysis\tests\test_script.ps1" -OutputPath ".\development\scripts\analysis\tests\results\merged-results.json"

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath = ".\development\scripts\analysis\tests\test_script.ps1",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\development\scripts\analysis\tests\results\merged-results.json",

    [Parameter(Mandatory = $false)]
    [string]$TodoResultsPath = ".\development\scripts\analysis\tests\results\todo-results.json",

    [Parameter(Mandatory = $false)]
    [string]$PSScriptAnalyzerResultsPath = ".\development\scripts\analysis\tests\results\pssa-results.json",

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHtmlReport
)

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$unifiedResultsFormatPath = Join-Path -Path $modulesPath -ChildPath "UnifiedResultsFormat.psm1"

Import-Module -Name $unifiedResultsFormatPath -Force
Import-Module -Name PSScriptAnalyzer -Force

# CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
$outputDirectory = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputDirectory -PathType Container)) {
    try {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃƒÂ©pertoire de sortie '$outputDirectory' crÃƒÂ©ÃƒÂ©."
    } catch {
        Write-Error "Impossible de crÃƒÂ©er le rÃƒÂ©pertoire de sortie '$outputDirectory': $_"
        return
    }
}

# Analyser le fichier avec PSScriptAnalyzer
Write-Host "Analyse du fichier avec PSScriptAnalyzer..." -ForegroundColor Cyan
$psaResults = Invoke-ScriptAnalyzer -Path $FilePath
$unifiedPsaResults = ConvertFrom-PSScriptAnalyzerResult -Results $psaResults

# Enregistrer les rÃƒÂ©sultats de PSScriptAnalyzer
$unifiedPsaResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $PSScriptAnalyzerResultsPath -Encoding utf8 -Force
Write-Host "RÃƒÂ©sultats de PSScriptAnalyzer enregistrÃƒÂ©s dans '$PSScriptAnalyzerResultsPath'." -ForegroundColor Green

# Charger les rÃƒÂ©sultats de TodoAnalyzer
Write-Host "Chargement des rÃƒÂ©sultats de TodoAnalyzer..." -ForegroundColor Cyan
if (Test-Path -Path $TodoResultsPath -PathType Leaf) {
    $todoResults = Get-Content -Path $TodoResultsPath -Raw | ConvertFrom-Json
} else {
    Write-Warning "Fichier de rÃƒÂ©sultats TodoAnalyzer introuvable: $TodoResultsPath"
    $todoResults = @()
}

# Fusionner les rÃƒÂ©sultats
Write-Host "Fusion des rÃƒÂ©sultats..." -ForegroundColor Cyan
$mergedResults = @()
$mergedResults += $unifiedPsaResults
$mergedResults += $todoResults

# Enregistrer les rÃƒÂ©sultats fusionnÃƒÂ©s
$mergedResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
Write-Host "RÃƒÂ©sultats fusionnÃƒÂ©s enregistrÃƒÂ©s dans '$OutputPath'." -ForegroundColor Green

# GÃƒÂ©nÃƒÂ©rer un rapport HTML si demandÃƒÂ©
if ($GenerateHtmlReport) {
    $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")

    # CrÃƒÂ©er le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'analyse</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
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
        .summary-item {
            display: inline-block;
            margin-right: 20px;
            padding: 10px;
            border-radius: 5px;
        }
        .error-count {
            background-color: #ffdddd;
        }
        .warning-count {
            background-color: #ffffdd;
        }
        .info-count {
            background-color: #ddffff;
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
        .severity-Error {
            background-color: #ffdddd;
        }
        .severity-Warning {
            background-color: #ffffdd;
        }
        .severity-Information {
            background-color: #ddffff;
        }
        .filters {
            margin-bottom: 20px;
        }
        .filter-group {
            display: inline-block;
            margin-right: 20px;
        }
        .filter-group label {
            font-weight: bold;
        }
        .hidden {
            display: none;
        }
    </style>
</head>
<body>
    <h1>Rapport d'analyse</h1>

    <div class="summary">
        <h2>RÃƒÂ©sumÃƒÂ©</h2>
        <div class="summary-item error-count">
            <strong>Erreurs:</strong> <span id="error-count">$($mergedResults | Where-Object { $_.Severity -eq "Error" } | Measure-Object).Count</span>
        </div>
        <div class="summary-item warning-count">
            <strong>Avertissements:</strong> <span id="warning-count">$($mergedResults | Where-Object { $_.Severity -eq "Warning" } | Measure-Object).Count</span>
        </div>
        <div class="summary-item info-count">
            <strong>Informations:</strong> <span id="info-count">$($mergedResults | Where-Object { $_.Severity -eq "Information" } | Measure-Object).Count</span>
        </div>
        <div class="summary-item">
            <strong>Total:</strong> <span id="total-count">$($mergedResults.Count)</span>
        </div>
    </div>

    <div class="filters">
        <h2>Filtres</h2>
        <div class="filter-group">
            <label>SÃƒÂ©vÃƒÂ©ritÃƒÂ©:</label>
            <input type="checkbox" id="filter-error" checked> Erreurs
            <input type="checkbox" id="filter-warning" checked> Avertissements
            <input type="checkbox" id="filter-info" checked> Informations
        </div>
        <div class="filter-group">
            <label>Outil:</label>
            <select id="filter-tool">
                <option value="all">Tous</option>
$(
    $tools = $mergedResults | Select-Object -ExpandProperty ToolName -Unique
    foreach ($tool in $tools) {
        "                <option value=`"$tool`">$tool</option>"
    }
)
            </select>
        </div>
        <div class="filter-group">
            <label>CatÃƒÂ©gorie:</label>
            <select id="filter-category">
                <option value="all">Toutes</option>
$(
    $categories = $mergedResults | Select-Object -ExpandProperty Category -Unique
    foreach ($category in $categories) {
        "                <option value=`"$category`">$category</option>"
    }
)
            </select>
        </div>
    </div>

    <h2>RÃƒÂ©sultats dÃƒÂ©taillÃƒÂ©s</h2>
    <table id="results-table">
        <thead>
            <tr>
                <th>Fichier</th>
                <th>Ligne</th>
                <th>Colonne</th>
                <th>SÃƒÂ©vÃƒÂ©ritÃƒÂ©</th>
                <th>Outil</th>
                <th>RÃƒÂ¨gle</th>
                <th>CatÃƒÂ©gorie</th>
                <th>Message</th>
            </tr>
        </thead>
        <tbody>
$(
    foreach ($result in $mergedResults) {
        $severityClass = "severity-$($result.Severity)"
        "            <tr class=`"$severityClass`" data-severity=`"$($result.Severity)`" data-tool=`"$($result.ToolName)`" data-category=`"$($result.Category)`">"
        "                <td>$($result.FileName)</td>"
        "                <td>$($result.Line)</td>"
        "                <td>$($result.Column)</td>"
        "                <td>$($result.Severity)</td>"
        "                <td>$($result.ToolName)</td>"
        "                <td>$($result.RuleId)</td>"
        "                <td>$($result.Category)</td>"
        "                <td>$($result.Message)</td>"
        "            </tr>"
    }
)
        </tbody>
    </table>

    <script>
        // Filtrage des rÃƒÂ©sultats
        function applyFilters() {
            const showError = document.getElementById('filter-error').checked;
            const showWarning = document.getElementById('filter-warning').checked;
            const showInfo = document.getElementById('filter-info').checked;
            const selectedTool = document.getElementById('filter-tool').value;
            const selectedCategory = document.getElementById('filter-category').value;

            const rows = document.querySelectorAll('#results-table tbody tr');
            let visibleCount = 0;
            let errorCount = 0;
            let warningCount = 0;
            let infoCount = 0;

            rows.forEach(row => {
                const severity = row.getAttribute('data-severity');
                const tool = row.getAttribute('data-tool');
                const category = row.getAttribute('data-category');

                const showBySeverity = (severity === 'Error' && showError) ||
                                      (severity === 'Warning' && showWarning) ||
                                      (severity === 'Information' && showInfo);

                const showByTool = selectedTool === 'all' || tool === selectedTool;
                const showByCategory = selectedCategory === 'all' || category === selectedCategory;

                const visible = showBySeverity && showByTool && showByCategory;

                row.classList.toggle('hidden', !visible);

                if (visible) {
                    visibleCount++;
                    if (severity === 'Error') errorCount++;
                    if (severity === 'Warning') warningCount++;
                    if (severity === 'Information') infoCount++;
                }
            });

            document.getElementById('error-count').textContent = errorCount;
            document.getElementById('warning-count').textContent = warningCount;
            document.getElementById('info-count').textContent = infoCount;
            document.getElementById('total-count').textContent = visibleCount;
        }

        // Ajouter les ÃƒÂ©couteurs d'ÃƒÂ©vÃƒÂ©nements
        document.getElementById('filter-error').addEventListener('change', applyFilters);
        document.getElementById('filter-warning').addEventListener('change', applyFilters);
        document.getElementById('filter-info').addEventListener('change', applyFilters);
        document.getElementById('filter-tool').addEventListener('change', applyFilters);
        document.getElementById('filter-category').addEventListener('change', applyFilters);

        // Appliquer les filtres au chargement
        document.addEventListener('DOMContentLoaded', applyFilters);
    </script>
</body>
</html>
"@

    # Ãƒâ€°crire le fichier HTML avec l'encodage UTF-8 avec BOM pour assurer la compatibilitÃƒÂ© avec les navigateurs
    [System.IO.File]::WriteAllText($htmlPath, $htmlContent, [System.Text.Encoding]::UTF8)
    Write-Host "Rapport HTML gÃƒÂ©nÃƒÂ©rÃƒÂ© dans '$htmlPath'." -ForegroundColor Green

    # Ouvrir le rapport HTML dans le navigateur par dÃƒÂ©faut
    Start-Process $htmlPath
}

# Afficher un rÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats
$totalIssues = $mergedResults.Count
$errorCount = ($mergedResults | Where-Object { $_.Severity -eq "Error" }).Count
$warningCount = ($mergedResults | Where-Object { $_.Severity -eq "Warning" }).Count
$infoCount = ($mergedResults | Where-Object { $_.Severity -eq "Information" }).Count

Write-Host "`nRÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats:" -ForegroundColor Cyan
Write-Host "  - Erreurs: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "  - Avertissements: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
Write-Host "  - Informations: $infoCount" -ForegroundColor "Blue"
Write-Host "  - Total: $totalIssues" -ForegroundColor "White"

# Afficher la rÃƒÂ©partition par outil
$toolCounts = $mergedResults | Group-Object -Property ToolName | Select-Object Name, Count

Write-Host "`nRÃƒÂ©partition par outil:" -ForegroundColor Cyan
foreach ($toolCount in $toolCounts) {
    Write-Host "  - $($toolCount.Name): $($toolCount.Count)" -ForegroundColor "White"
}
