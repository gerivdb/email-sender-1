#Requires -Version 5.1
<#
.SYNOPSIS
    Fusionne les rÃ©sultats d'analyse de diffÃ©rentes sources.

.DESCRIPTION
    Ce script permet de fusionner les rÃ©sultats d'analyse provenant de diffÃ©rentes sources
    (PSScriptAnalyzer, ESLint, Pylint, SonarQube, etc.) dans un format unifiÃ©. Il peut
    Ã©galement filtrer les rÃ©sultats par sÃ©vÃ©ritÃ©, outil ou catÃ©gorie, et supprimer les doublons.

.PARAMETER InputPath
    Chemin du fichier ou des fichiers contenant les rÃ©sultats d'analyse Ã  fusionner.
    Peut Ãªtre un tableau de chemins ou un chemin avec des caractÃ¨res gÃ©nÃ©riques.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les rÃ©sultats fusionnÃ©s. Si non spÃ©cifiÃ©, les rÃ©sultats sont affichÃ©s dans la console.

.PARAMETER RemoveDuplicates
    Supprimer les rÃ©sultats en double.

.PARAMETER Severity
    Filtrer les rÃ©sultats par sÃ©vÃ©ritÃ©. Valeurs possibles: Error, Warning, Information, All.

.PARAMETER ToolName
    Filtrer les rÃ©sultats par outil d'analyse.

.PARAMETER Category
    Filtrer les rÃ©sultats par catÃ©gorie.

.PARAMETER GenerateHtmlReport
    GÃ©nÃ©rer un rapport HTML en plus du fichier JSON.

.EXAMPLE
    .\Merge-AnalysisResults.ps1 -InputPath "C:\Results\pssa-results.json", "C:\Results\eslint-results.json" -OutputPath "C:\Results\merged-results.json" -RemoveDuplicates

.EXAMPLE
    .\Merge-AnalysisResults.ps1 -InputPath "C:\Results\*.json" -Severity Error, Warning -ToolName PSScriptAnalyzer, ESLint -GenerateHtmlReport

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  15/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$InputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$RemoveDuplicates,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Information", "All")]
    [string[]]$Severity = @("Error", "Warning", "Information"),
    
    [Parameter(Mandatory = $false)]
    [string[]]$ToolName,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Category,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHtmlReport
)

# Importer les modules requis
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$unifiedResultsFormatPath = Join-Path -Path $modulesPath -ChildPath "UnifiedResultsFormat.psm1"

if (Test-Path -Path $unifiedResultsFormatPath) {
    Import-Module -Name $unifiedResultsFormatPath -Force
}
else {
    throw "Module UnifiedResultsFormat.psm1 introuvable."
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-HtmlReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # CrÃ©er le contenu HTML
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
        <h2>RÃ©sumÃ©</h2>
        <div class="summary-item error-count">
            <strong>Erreurs:</strong> <span id="error-count">$($Results | Where-Object { $_.Severity -eq "Error" } | Measure-Object).Count</span>
        </div>
        <div class="summary-item warning-count">
            <strong>Avertissements:</strong> <span id="warning-count">$($Results | Where-Object { $_.Severity -eq "Warning" } | Measure-Object).Count</span>
        </div>
        <div class="summary-item info-count">
            <strong>Informations:</strong> <span id="info-count">$($Results | Where-Object { $_.Severity -eq "Information" } | Measure-Object).Count</span>
        </div>
        <div class="summary-item">
            <strong>Total:</strong> <span id="total-count">$($Results.Count)</span>
        </div>
    </div>
    
    <div class="filters">
        <h2>Filtres</h2>
        <div class="filter-group">
            <label>SÃ©vÃ©ritÃ©:</label>
            <input type="checkbox" id="filter-error" checked> Erreurs
            <input type="checkbox" id="filter-warning" checked> Avertissements
            <input type="checkbox" id="filter-info" checked> Informations
        </div>
        <div class="filter-group">
            <label>Outil:</label>
            <select id="filter-tool">
                <option value="all">Tous</option>
$(
    $tools = $Results | Select-Object -ExpandProperty ToolName -Unique
    foreach ($tool in $tools) {
        "                <option value=`"$tool`">$tool</option>"
    }
)
            </select>
        </div>
        <div class="filter-group">
            <label>CatÃ©gorie:</label>
            <select id="filter-category">
                <option value="all">Toutes</option>
$(
    $categories = $Results | Select-Object -ExpandProperty Category -Unique
    foreach ($category in $categories) {
        "                <option value=`"$category`">$category</option>"
    }
)
            </select>
        </div>
    </div>
    
    <h2>RÃ©sultats dÃ©taillÃ©s</h2>
    <table id="results-table">
        <thead>
            <tr>
                <th>Fichier</th>
                <th>Ligne</th>
                <th>Colonne</th>
                <th>SÃ©vÃ©ritÃ©</th>
                <th>Outil</th>
                <th>RÃ¨gle</th>
                <th>CatÃ©gorie</th>
                <th>Message</th>
            </tr>
        </thead>
        <tbody>
$(
    foreach ($result in $Results) {
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
        // Filtrage des rÃ©sultats
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
        
        // Ajouter les Ã©couteurs d'Ã©vÃ©nements
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
    
    # Ã‰crire le fichier HTML
    try {
        $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8 -Force
        Write-Verbose "Rapport HTML gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport HTML: $_"
        return $false
    }
}

# Fonction principale
function Merge-Results {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$InputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveDuplicates,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warning", "Information", "All")]
        [string[]]$Severity = @("Error", "Warning", "Information"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ToolName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Category,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateHtmlReport
    )
    
    # RÃ©cupÃ©rer tous les fichiers correspondant aux chemins spÃ©cifiÃ©s
    $files = @()
    foreach ($path in $InputPath) {
        if ($path -match '\*') {
            # Chemin avec caractÃ¨res gÃ©nÃ©riques
            $matchingFiles = Get-ChildItem -Path $path -File
            $files += $matchingFiles
        }
        else {
            # Chemin spÃ©cifique
            if (Test-Path -Path $path -PathType Leaf) {
                $files += Get-Item -Path $path
            }
            else {
                Write-Warning "Le fichier '$path' n'existe pas."
            }
        }
    }
    
    if ($files.Count -eq 0) {
        Write-Error "Aucun fichier trouvÃ© correspondant aux chemins spÃ©cifiÃ©s."
        return $null
    }
    
    # Charger et fusionner les rÃ©sultats
    $allResults = @()
    
    foreach ($file in $files) {
        try {
            $content = Get-Content -Path $file.FullName -Raw
            $results = $content | ConvertFrom-Json
            
            # VÃ©rifier si les rÃ©sultats sont dÃ©jÃ  au format unifiÃ©
            $isUnified = $results | Where-Object { $_.ToolName -ne $null -and $_.Severity -ne $null -and $_.FilePath -ne $null }
            
            if ($isUnified) {
                $allResults += $results
            }
            else {
                # Essayer de dÃ©terminer le format des rÃ©sultats
                $toolName = if ($file.Name -match 'pssa|scriptanalyzer') {
                    "PSScriptAnalyzer"
                }
                elseif ($file.Name -match 'eslint') {
                    "ESLint"
                }
                elseif ($file.Name -match 'pylint') {
                    "Pylint"
                }
                elseif ($file.Name -match 'sonarqube') {
                    "SonarQube"
                }
                else {
                    "Unknown"
                }
                
                # Convertir les rÃ©sultats selon le format dÃ©tectÃ©
                switch ($toolName) {
                    "PSScriptAnalyzer" {
                        $allResults += ConvertFrom-PSScriptAnalyzerResult -Results $results
                    }
                    "ESLint" {
                        $allResults += ConvertFrom-ESLintResult -Results $results
                    }
                    "Pylint" {
                        $allResults += ConvertFrom-PylintResult -Results $results
                    }
                    "SonarQube" {
                        $allResults += ConvertFrom-SonarQubeResult -Results $results
                    }
                    default {
                        Write-Warning "Format de rÃ©sultats inconnu dans le fichier '$($file.FullName)'. IgnorÃ©."
                    }
                }
            }
        }
        catch {
            Write-Error "Erreur lors du chargement du fichier '$($file.FullName)': $_"
        }
    }
    
    # Supprimer les doublons si demandÃ©
    if ($RemoveDuplicates) {
        $allResults = Merge-AnalysisResults -Results $allResults -RemoveDuplicates
    }
    
    # Filtrer par sÃ©vÃ©ritÃ© si spÃ©cifiÃ©
    if ($Severity -notcontains "All") {
        $allResults = Filter-AnalysisResultsBySeverity -Results $allResults -Severity $Severity
    }
    
    # Filtrer par outil si spÃ©cifiÃ©
    if ($ToolName) {
        $allResults = Filter-AnalysisResultsByTool -Results $allResults -ToolName $ToolName
    }
    
    # Filtrer par catÃ©gorie si spÃ©cifiÃ©
    if ($Category) {
        $allResults = Filter-AnalysisResultsByCategory -Results $allResults -Category $Category
    }
    
    # Enregistrer les rÃ©sultats dans un fichier si demandÃ©
    if ($OutputPath) {
        try {
            $allResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
            Write-Host "RÃ©sultats fusionnÃ©s enregistrÃ©s dans '$OutputPath'." -ForegroundColor Green
            
            # GÃ©nÃ©rer un rapport HTML si demandÃ©
            if ($GenerateHtmlReport) {
                $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
                New-HtmlReport -Results $allResults -OutputPath $htmlPath
                Write-Host "Rapport HTML gÃ©nÃ©rÃ© dans '$htmlPath'." -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Erreur lors de l'enregistrement des rÃ©sultats: $_"
        }
    }
    
    return $allResults
}

# ExÃ©cuter la fonction principale
$results = Merge-Results -InputPath $InputPath -OutputPath $OutputPath -RemoveDuplicates:$RemoveDuplicates -Severity $Severity -ToolName $ToolName -Category $Category -GenerateHtmlReport:$GenerateHtmlReport

# Afficher un rÃ©sumÃ© des rÃ©sultats
if ($null -ne $results) {
    $totalIssues = $results.Count
    $errorCount = ($results | Where-Object { $_.Severity -eq "Error" }).Count
    $warningCount = ($results | Where-Object { $_.Severity -eq "Warning" }).Count
    $infoCount = ($results | Where-Object { $_.Severity -eq "Information" }).Count
    
    Write-Host "Fusion terminÃ©e avec $totalIssues problÃ¨mes au total:" -ForegroundColor Cyan
    Write-Host "  - Erreurs: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
    Write-Host "  - Avertissements: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  - Informations: $infoCount" -ForegroundColor "Blue"
    
    # Afficher la rÃ©partition par outil
    $toolCounts = $results | Group-Object -Property ToolName | Select-Object Name, Count
    
    Write-Host "`nRÃ©partition par outil:" -ForegroundColor Cyan
    foreach ($toolCount in $toolCounts) {
        Write-Host "  - $($toolCount.Name): $($toolCount.Count)" -ForegroundColor "White"
    }
    
    # Afficher la rÃ©partition par catÃ©gorie
    $categoryCounts = $results | Group-Object -Property Category | Select-Object Name, Count
    
    Write-Host "`nRÃ©partition par catÃ©gorie:" -ForegroundColor Cyan
    foreach ($categoryCount in $categoryCounts) {
        Write-Host "  - $($categoryCount.Name): $($categoryCount.Count)" -ForegroundColor "White"
    }
}
