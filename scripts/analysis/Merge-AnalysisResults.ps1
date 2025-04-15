#Requires -Version 5.1
<#
.SYNOPSIS
    Fusionne les résultats d'analyse de différentes sources.

.DESCRIPTION
    Ce script permet de fusionner les résultats d'analyse provenant de différentes sources
    (PSScriptAnalyzer, ESLint, Pylint, SonarQube, etc.) dans un format unifié. Il peut
    également filtrer les résultats par sévérité, outil ou catégorie, et supprimer les doublons.

.PARAMETER InputPath
    Chemin du fichier ou des fichiers contenant les résultats d'analyse à fusionner.
    Peut être un tableau de chemins ou un chemin avec des caractères génériques.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour les résultats fusionnés. Si non spécifié, les résultats sont affichés dans la console.

.PARAMETER RemoveDuplicates
    Supprimer les résultats en double.

.PARAMETER Severity
    Filtrer les résultats par sévérité. Valeurs possibles: Error, Warning, Information, All.

.PARAMETER ToolName
    Filtrer les résultats par outil d'analyse.

.PARAMETER Category
    Filtrer les résultats par catégorie.

.PARAMETER GenerateHtmlReport
    Générer un rapport HTML en plus du fichier JSON.

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

# Fonction pour générer un rapport HTML
function New-HtmlReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # Créer le contenu HTML
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
        <h2>Résumé</h2>
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
            <label>Sévérité:</label>
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
            <label>Catégorie:</label>
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
    
    <h2>Résultats détaillés</h2>
    <table id="results-table">
        <thead>
            <tr>
                <th>Fichier</th>
                <th>Ligne</th>
                <th>Colonne</th>
                <th>Sévérité</th>
                <th>Outil</th>
                <th>Règle</th>
                <th>Catégorie</th>
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
        // Filtrage des résultats
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
        
        // Ajouter les écouteurs d'événements
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
    
    # Écrire le fichier HTML
    try {
        $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8 -Force
        Write-Verbose "Rapport HTML généré avec succès: $OutputPath"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la génération du rapport HTML: $_"
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
    
    # Récupérer tous les fichiers correspondant aux chemins spécifiés
    $files = @()
    foreach ($path in $InputPath) {
        if ($path -match '\*') {
            # Chemin avec caractères génériques
            $matchingFiles = Get-ChildItem -Path $path -File
            $files += $matchingFiles
        }
        else {
            # Chemin spécifique
            if (Test-Path -Path $path -PathType Leaf) {
                $files += Get-Item -Path $path
            }
            else {
                Write-Warning "Le fichier '$path' n'existe pas."
            }
        }
    }
    
    if ($files.Count -eq 0) {
        Write-Error "Aucun fichier trouvé correspondant aux chemins spécifiés."
        return $null
    }
    
    # Charger et fusionner les résultats
    $allResults = @()
    
    foreach ($file in $files) {
        try {
            $content = Get-Content -Path $file.FullName -Raw
            $results = $content | ConvertFrom-Json
            
            # Vérifier si les résultats sont déjà au format unifié
            $isUnified = $results | Where-Object { $_.ToolName -ne $null -and $_.Severity -ne $null -and $_.FilePath -ne $null }
            
            if ($isUnified) {
                $allResults += $results
            }
            else {
                # Essayer de déterminer le format des résultats
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
                
                # Convertir les résultats selon le format détecté
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
                        Write-Warning "Format de résultats inconnu dans le fichier '$($file.FullName)'. Ignoré."
                    }
                }
            }
        }
        catch {
            Write-Error "Erreur lors du chargement du fichier '$($file.FullName)': $_"
        }
    }
    
    # Supprimer les doublons si demandé
    if ($RemoveDuplicates) {
        $allResults = Merge-AnalysisResults -Results $allResults -RemoveDuplicates
    }
    
    # Filtrer par sévérité si spécifié
    if ($Severity -notcontains "All") {
        $allResults = Filter-AnalysisResultsBySeverity -Results $allResults -Severity $Severity
    }
    
    # Filtrer par outil si spécifié
    if ($ToolName) {
        $allResults = Filter-AnalysisResultsByTool -Results $allResults -ToolName $ToolName
    }
    
    # Filtrer par catégorie si spécifié
    if ($Category) {
        $allResults = Filter-AnalysisResultsByCategory -Results $allResults -Category $Category
    }
    
    # Enregistrer les résultats dans un fichier si demandé
    if ($OutputPath) {
        try {
            $allResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force
            Write-Host "Résultats fusionnés enregistrés dans '$OutputPath'." -ForegroundColor Green
            
            # Générer un rapport HTML si demandé
            if ($GenerateHtmlReport) {
                $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
                New-HtmlReport -Results $allResults -OutputPath $htmlPath
                Write-Host "Rapport HTML généré dans '$htmlPath'." -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Erreur lors de l'enregistrement des résultats: $_"
        }
    }
    
    return $allResults
}

# Exécuter la fonction principale
$results = Merge-Results -InputPath $InputPath -OutputPath $OutputPath -RemoveDuplicates:$RemoveDuplicates -Severity $Severity -ToolName $ToolName -Category $Category -GenerateHtmlReport:$GenerateHtmlReport

# Afficher un résumé des résultats
if ($null -ne $results) {
    $totalIssues = $results.Count
    $errorCount = ($results | Where-Object { $_.Severity -eq "Error" }).Count
    $warningCount = ($results | Where-Object { $_.Severity -eq "Warning" }).Count
    $infoCount = ($results | Where-Object { $_.Severity -eq "Information" }).Count
    
    Write-Host "Fusion terminée avec $totalIssues problèmes au total:" -ForegroundColor Cyan
    Write-Host "  - Erreurs: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
    Write-Host "  - Avertissements: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  - Informations: $infoCount" -ForegroundColor "Blue"
    
    # Afficher la répartition par outil
    $toolCounts = $results | Group-Object -Property ToolName | Select-Object Name, Count
    
    Write-Host "`nRépartition par outil:" -ForegroundColor Cyan
    foreach ($toolCount in $toolCounts) {
        Write-Host "  - $($toolCount.Name): $($toolCount.Count)" -ForegroundColor "White"
    }
    
    # Afficher la répartition par catégorie
    $categoryCounts = $results | Group-Object -Property Category | Select-Object Name, Count
    
    Write-Host "`nRépartition par catégorie:" -ForegroundColor Cyan
    foreach ($categoryCount in $categoryCounts) {
        Write-Host "  - $($categoryCount.Name): $($categoryCount.Count)" -ForegroundColor "White"
    }
}
