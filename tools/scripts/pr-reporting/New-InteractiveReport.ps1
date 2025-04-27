#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re un rapport d'analyse interactif pour les pull requests.

.DESCRIPTION
    Ce script gÃ©nÃ¨re un rapport HTML interactif Ã  partir des rÃ©sultats d'analyse
    de pull requests, avec des visualisations, des filtres et des fonctionnalitÃ©s
    de tri avancÃ©es.

.PARAMETER InputPath
    Le chemin du fichier JSON contenant les rÃ©sultats d'analyse.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer le rapport HTML gÃ©nÃ©rÃ©.
    Par dÃ©faut: "reports\pr-analysis\interactive_report.html"

.PARAMETER TemplateType
    Le type de template Ã  utiliser pour le rapport.
    Valeurs possibles: "Standard", "Developer", "Executive", "QA"
    Par dÃ©faut: "Standard"

.PARAMETER Theme
    Le thÃ¨me Ã  utiliser pour le rapport.
    Valeurs possibles: "Light", "Dark", "Blue", "Green"
    Par dÃ©faut: "Light"

.PARAMETER IncludeAssets
    Indique s'il faut inclure les assets (CSS, JS) dans le fichier HTML.
    Si $false, les assets seront rÃ©fÃ©rencÃ©s depuis le dossier assets.
    Par dÃ©faut: $true

.EXAMPLE
    .\New-InteractiveReport.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -TemplateType "Developer"
    GÃ©nÃ¨re un rapport interactif pour les dÃ©veloppeurs Ã  partir des rÃ©sultats d'analyse de la PR #42.

.EXAMPLE
    .\New-InteractiveReport.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -Theme "Dark" -OutputPath "reports\pr-analysis\dark_report.html"
    GÃ©nÃ¨re un rapport interactif avec le thÃ¨me sombre et l'enregistre dans un fichier personnalisÃ©.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis\interactive_report.html",

    [Parameter()]
    [ValidateSet("Standard", "Developer", "Executive", "QA")]
    [string]$TemplateType = "Standard",

    [Parameter()]
    [ValidateSet("Light", "Dark", "Blue", "Green")]
    [string]$Theme = "Light",

    [Parameter()]
    [bool]$IncludeAssets = $true
)

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$modulesToImport = @(
    "PRReportTemplates.psm1",
    "PRVisualization.psm1",
    "PRReportFilters.psm1"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $module
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "Module $module non trouvÃ© Ã  l'emplacement: $modulePath"
        exit 1
    }
}

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $InputPath)) {
    Write-Error "Le fichier d'entrÃ©e n'existe pas: $InputPath"
    exit 1
}

# Charger les donnÃ©es d'analyse
try {
    $analysisData = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement des donnÃ©es d'analyse: $_"
    exit 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Charger les templates
$templatesDir = Join-Path -Path $PSScriptRoot -ChildPath "templates"
Import-PRReportTemplates -TemplatesDirectory $templatesDir

# DÃ©terminer le template Ã  utiliser
$templateName = "PR-Analysis-$TemplateType"

# PrÃ©parer les donnÃ©es pour le rapport
$reportData = [PSCustomObject]@{
    Title = "Rapport d'analyse de la Pull Request #$($analysisData.PullRequest.Number)"
    PullRequest = $analysisData.PullRequest
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalIssues = $analysisData.TotalIssues
    SuccessCount = $analysisData.SuccessCount
    FailureCount = $analysisData.FailureCount
    Theme = $Theme.ToLower()
    AnalysisType = $analysisData.AnalysisType
    Results = $analysisData.Results
    Issues = @()
}

# Extraire tous les problÃ¨mes
foreach ($result in $analysisData.Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 }) {
    foreach ($issue in $result.Issues) {
        $reportData.Issues += [PSCustomObject]@{
            FilePath = $result.FilePath
            Type = $issue.Type
            Line = $issue.Line
            Column = $issue.Column
            Message = $issue.Message
            Severity = $issue.Severity
            Rule = $issue.Rule
        }
    }
}

# GÃ©nÃ©rer les visualisations
$issuesByType = $reportData.Issues | Group-Object -Property Type | Select-Object Name, Count
$issuesBySeverity = $reportData.Issues | Group-Object -Property Severity | Select-Object Name, Count
$issuesByFile = $reportData.Issues | Group-Object -Property FilePath | Select-Object Name, Count | Sort-Object -Property Count -Descending | Select-Object -First 10

# CrÃ©er les donnÃ©es pour les graphiques
$typeData = @{}
foreach ($group in $issuesByType) {
    $typeData[$group.Name] = $group.Count
}

$severityData = @{}
foreach ($group in $issuesBySeverity) {
    $severityData[$group.Name] = $group.Count
}

$fileData = @{}
foreach ($group in $issuesByFile) {
    $fileData[($group.Name -replace '.*[/\\]', '')] = $group.Count
}

# GÃ©nÃ©rer les graphiques
$typeChart = New-PRBarChart -Data $typeData -Title "ProblÃ¨mes par type"
$severityChart = New-PRPieChart -Data $severityData -Title "ProblÃ¨mes par sÃ©vÃ©ritÃ©"
$fileChart = New-PRBarChart -Data $fileData -Title "Top 10 des fichiers avec problÃ¨mes"

# CrÃ©er les filtres
$filterControls = Add-FilterControls -Issues $reportData.Issues -FilterProperties @("Type", "Severity", "Rule")

# Ajouter les capacitÃ©s de tri
$sortingCapabilities = Add-SortingCapabilities -DefaultSortColumn "Severity" -DefaultSortDirection "desc"

# CrÃ©er des vues personnalisÃ©es
$errorView = New-CustomReportView -Name "Erreurs critiques" -Filters @{ Severity = "Error" } -Description "Afficher uniquement les erreurs critiques" -Icon "exclamation-circle"
$warningView = New-CustomReportView -Name "Avertissements" -Filters @{ Severity = "Warning" } -Description "Afficher uniquement les avertissements" -Icon "exclamation-triangle"
$syntaxView = New-CustomReportView -Name "ProblÃ¨mes de syntaxe" -Filters @{ Type = "Syntax" } -Description "Afficher uniquement les problÃ¨mes de syntaxe" -Icon "code"
$styleView = New-CustomReportView -Name "ProblÃ¨mes de style" -Filters @{ Type = "Style" } -Description "Afficher uniquement les problÃ¨mes de style" -Icon "paint-brush"

# CrÃ©er le rapport avec recherche avancÃ©e
$searchableReport = New-SearchableReport -Issues $reportData.Issues -Title $reportData.Title -Description "Analyse de la pull request #$($analysisData.PullRequest.Number) - $($analysisData.PullRequest.Title)"

# GÃ©nÃ©rer le HTML final
$html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($reportData.Title)</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <style>
        :root {
            --primary-color: $(switch ($Theme) {
                "Light" { "#4285F4" }
                "Dark" { "#BB86FC" }
                "Blue" { "#0078D7" }
                "Green" { "#34A853" }
            });
            --background-color: $(switch ($Theme) {
                "Light" { "#FFFFFF" }
                "Dark" { "#121212" }
                "Blue" { "#F0F8FF" }
                "Green" { "#F0FFF0" }
            });
            --text-color: $(switch ($Theme) {
                "Light" { "#333333" }
                "Dark" { "#E0E0E0" }
                "Blue" { "#333333" }
                "Green" { "#333333" }
            });
            --border-color: $(switch ($Theme) {
                "Light" { "#DDDDDD" }
                "Dark" { "#333333" }
                "Blue" { "#B0C4DE" }
                "Green" { "#C0DCC0" }
            });
            --card-background: $(switch ($Theme) {
                "Light" { "#F8F9FA" }
                "Dark" { "#1E1E1E" }
                "Blue" { "#E6F2FF" }
                "Green" { "#E6FFE6" }
            });
            --hover-color: $(switch ($Theme) {
                "Light" { "#E9ECEF" }
                "Dark" { "#2D2D2D" }
                "Blue" { "#D4E6F9" }
                "Green" { "#D4F9D4" }
            });
        }
        
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: var(--background-color);
            color: var(--text-color);
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 30px;
            padding-bottom: 15px;
            border-bottom: 1px solid var(--border-color);
        }
        
        .header h1 {
            margin: 0;
            color: var(--primary-color);
        }
        
        .pr-info {
            background-color: var(--card-background);
            border: 1px solid var(--border-color);
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 30px;
        }
        
        .pr-info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 15px;
        }
        
        .pr-info-item {
            display: flex;
            flex-direction: column;
        }
        
        .pr-info-label {
            font-size: 14px;
            color: #666;
            margin-bottom: 5px;
        }
        
        .pr-info-value {
            font-size: 16px;
            font-weight: bold;
        }
        
        .charts-container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .views-container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .tab-container {
            margin-bottom: 30px;
        }
        
        .tabs {
            display: flex;
            border-bottom: 1px solid var(--border-color);
            margin-bottom: 15px;
        }
        
        .tab {
            padding: 10px 20px;
            cursor: pointer;
            border: 1px solid transparent;
            border-bottom: none;
            border-radius: 5px 5px 0 0;
            margin-right: 5px;
            background-color: var(--card-background);
        }
        
        .tab.active {
            border-color: var(--border-color);
            background-color: var(--background-color);
            font-weight: bold;
            color: var(--primary-color);
        }
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .footer {
            margin-top: 50px;
            padding-top: 20px;
            border-top: 1px solid var(--border-color);
            text-align: center;
            font-size: 14px;
            color: #666;
        }
        
        /* Styles spÃ©cifiques au thÃ¨me sombre */
        body.theme-dark {
            background-color: #121212;
            color: #E0E0E0;
        }
        
        body.theme-dark .pr-info {
            background-color: #1E1E1E;
            border-color: #333333;
        }
        
        body.theme-dark .tab {
            background-color: #1E1E1E;
        }
        
        body.theme-dark .tab.active {
            background-color: #121212;
            color: #BB86FC;
        }
        
        /* Styles responsifs */
        @media (max-width: 768px) {
            .charts-container, .views-container {
                grid-template-columns: 1fr;
            }
            
            .pr-info-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body class="theme-$($Theme.ToLower())">
    <div class="container">
        <div class="header">
            <h1>$($reportData.Title)</h1>
            <div class="timestamp">GÃ©nÃ©rÃ© le $($reportData.Timestamp)</div>
        </div>
        
        <div class="pr-info">
            <h2>Informations sur la Pull Request</h2>
            <div class="pr-info-grid">
                <div class="pr-info-item">
                    <span class="pr-info-label">NumÃ©ro</span>
                    <span class="pr-info-value">#$($reportData.PullRequest.Number)</span>
                </div>
                <div class="pr-info-item">
                    <span class="pr-info-label">Titre</span>
                    <span class="pr-info-value">$($reportData.PullRequest.Title)</span>
                </div>
                <div class="pr-info-item">
                    <span class="pr-info-label">Branche source</span>
                    <span class="pr-info-value">$($reportData.PullRequest.HeadBranch)</span>
                </div>
                <div class="pr-info-item">
                    <span class="pr-info-label">Branche cible</span>
                    <span class="pr-info-value">$($reportData.PullRequest.BaseBranch)</span>
                </div>
                <div class="pr-info-item">
                    <span class="pr-info-label">Fichiers modifiÃ©s</span>
                    <span class="pr-info-value">$($reportData.PullRequest.FileCount)</span>
                </div>
                <div class="pr-info-item">
                    <span class="pr-info-label">ProblÃ¨mes dÃ©tectÃ©s</span>
                    <span class="pr-info-value">$($reportData.TotalIssues)</span>
                </div>
                <div class="pr-info-item">
                    <span class="pr-info-label">Type d'analyse</span>
                    <span class="pr-info-value">$($reportData.AnalysisType)</span>
                </div>
            </div>
        </div>
        
        <div class="tab-container">
            <div class="tabs">
                <div class="tab active" data-tab="overview">Vue d'ensemble</div>
                <div class="tab" data-tab="issues">ProblÃ¨mes dÃ©tectÃ©s</div>
                <div class="tab" data-tab="files">Fichiers analysÃ©s</div>
            </div>
            
            <div class="tab-content active" id="tab-overview">
                <div class="charts-container">
                    $severityChart
                    $typeChart
                    $fileChart
                </div>
                
                <h3>Vues prÃ©dÃ©finies</h3>
                <div class="views-container">
                    $errorView
                    $warningView
                    $syntaxView
                    $styleView
                </div>
            </div>
            
            <div class="tab-content" id="tab-issues">
                $filterControls
                $searchableReport
                $sortingCapabilities
            </div>
            
            <div class="tab-content" id="tab-files">
                <h3>Fichiers analysÃ©s</h3>
                <table class="pr-issues-table">
                    <thead>
                        <tr>
                            <th>Fichier</th>
                            <th>ProblÃ¨mes</th>
                            <th>Lignes modifiÃ©es</th>
                            <th>Lignes analysÃ©es</th>
                        </tr>
                    </thead>
                    <tbody>
"@

foreach ($result in $analysisData.Results | Sort-Object -Property { $_.Issues.Count } -Descending) {
    $html += @"
                        <tr>
                            <td>$($result.FilePath)</td>
                            <td>$($result.Issues.Count)</td>
                            <td>$(if ($result.PSObject.Properties.Name -contains "ChangedLines") { $result.ChangedLines } else { "N/A" })</td>
                            <td>$(if ($result.PSObject.Properties.Name -contains "AnalyzedLines") { $result.AnalyzedLines } else { "N/A" })</td>
                        </tr>
"@
}

$html += @"
                    </tbody>
                </table>
            </div>
        </div>
        
        <div class="footer">
            <p>Rapport gÃ©nÃ©rÃ© par le systÃ¨me d'analyse de pull requests</p>
            <p>Version 1.0 - &copy; 2025</p>
        </div>
    </div>
    
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Gestion des onglets
            const tabs = document.querySelectorAll('.tab');
            const tabContents = document.querySelectorAll('.tab-content');
            
            tabs.forEach(tab => {
                tab.addEventListener('click', function() {
                    const tabId = this.dataset.tab;
                    
                    // DÃ©sactiver tous les onglets
                    tabs.forEach(t => t.classList.remove('active'));
                    tabContents.forEach(c => c.classList.remove('active'));
                    
                    // Activer l'onglet sÃ©lectionnÃ©
                    this.classList.add('active');
                    document.getElementById(`tab-\${tabId}`).classList.add('active');
                });
            });
        });
    </script>
</body>
</html>
"@

# Enregistrer le rapport HTML
Set-Content -Path $OutputPath -Value $html -Encoding UTF8

Write-Host "Rapport interactif gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -ForegroundColor Green

# Ouvrir le rapport dans le navigateur par dÃ©faut
if (Test-Path -Path $OutputPath) {
    Start-Process $OutputPath
}

return $OutputPath
