#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse les feedbacks des utilisateurs.
.DESCRIPTION
    Ce script analyse les feedbacks des utilisateurs et gÃ©nÃ¨re un rapport
    d'analyse et d'opportunitÃ©s d'amÃ©lioration.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de sortie.
.PARAMETER GenerateHTML
    GÃ©nÃ¨re un rapport HTML en plus du rapport JSON.
.EXAMPLE
    .\Analyze-Feedback.ps1 -OutputPath ".\reports\feedback" -GenerateHTML
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-23
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\feedback",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML
)

# Importer le module de collecte de feedback
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\FeedbackCollection.psm1"
Import-Module $modulePath -Force

# Fonction pour Ã©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# GÃ©nÃ©rer le rapport d'analyse
$analysisPath = Join-Path -Path $OutputPath -ChildPath "feedback_analysis_$(Get-Date -Format 'yyyyMMdd').json"
$analysis = Analyze-Feedbacks -OutputPath $analysisPath

if (-not $analysis) {
    Write-Log "Aucun feedback Ã  analyser" -Level "WARNING"
    exit 0
}

Write-Log "Rapport d'analyse gÃ©nÃ©rÃ©: $analysisPath" -Level "SUCCESS"

# GÃ©nÃ©rer le rapport d'opportunitÃ©s d'amÃ©lioration
$opportunitiesPath = Join-Path -Path $OutputPath -ChildPath "improvement_opportunities_$(Get-Date -Format 'yyyyMMdd').json"
$opportunities = Identify-ImprovementOpportunities -OutputPath $opportunitiesPath

Write-Log "Rapport d'opportunitÃ©s d'amÃ©lioration gÃ©nÃ©rÃ©: $opportunitiesPath" -Level "SUCCESS"

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "feedback_report_$(Get-Date -Format 'yyyyMMdd').html"
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de feedback</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0066cc;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .section {
            margin-bottom: 30px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .chart {
            width: 100%;
            height: 300px;
            margin-bottom: 20px;
        }
        .timestamp {
            color: #666;
            font-style: italic;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>Rapport de feedback</h1>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Total des feedbacks: <strong>$($analysis.TotalFeedbacks)</strong></p>
        <p>Rapport gÃ©nÃ©rÃ© le: <strong>$($analysis.GeneratedAt)</strong></p>
    </div>
    
    <div class="section">
        <h2>Statistiques par composant</h2>
        <table>
            <tr>
                <th>Composant</th>
                <th>Nombre</th>
            </tr>
"@

    foreach ($stat in $analysis.ComponentStats) {
        $htmlContent += @"
            <tr>
                <td>$($stat.Component)</td>
                <td>$($stat.Count)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
    </div>
    
    <div class="section">
        <h2>Statistiques par type de feedback</h2>
        <table>
            <tr>
                <th>Type</th>
                <th>Nombre</th>
            </tr>
"@

    foreach ($stat in $analysis.TypeStats) {
        $htmlContent += @"
            <tr>
                <td>$($stat.FeedbackType)</td>
                <td>$($stat.Count)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
    </div>
    
    <div class="section">
        <h2>Statistiques par statut</h2>
        <table>
            <tr>
                <th>Statut</th>
                <th>Nombre</th>
            </tr>
"@

    foreach ($stat in $analysis.StatusStats) {
        $htmlContent += @"
            <tr>
                <td>$($stat.Status)</td>
                <td>$($stat.Count)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
    </div>
    
    <div class="section">
        <h2>Statistiques par sÃ©vÃ©ritÃ©</h2>
        <table>
            <tr>
                <th>SÃ©vÃ©ritÃ©</th>
                <th>Nombre</th>
            </tr>
"@

    foreach ($stat in $analysis.SeverityStats) {
        $htmlContent += @"
            <tr>
                <td>$($stat.Severity)</td>
                <td>$($stat.Count)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
    </div>
    
    <div class="section">
        <h2>OpportunitÃ©s d'amÃ©lioration</h2>
        
        <h3>Composants avec le plus de bugs</h3>
        <table>
            <tr>
                <th>Composant</th>
                <th>Nombre de bugs</th>
            </tr>
"@

    foreach ($comp in $opportunities.BuggyComponents) {
        $htmlContent += @"
            <tr>
                <td>$($comp.Component)</td>
                <td>$($comp.BugCount)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
        
        <h3>Composants avec le plus de problÃ¨mes de performance</h3>
        <table>
            <tr>
                <th>Composant</th>
                <th>Nombre de problÃ¨mes</th>
            </tr>
"@

    foreach ($comp in $opportunities.SlowComponents) {
        $htmlContent += @"
            <tr>
                <td>$($comp.Component)</td>
                <td>$($comp.PerformanceIssueCount)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
        
        <h3>Demandes de fonctionnalitÃ©s les plus populaires</h3>
        <table>
            <tr>
                <th>FonctionnalitÃ©</th>
                <th>Nombre de demandes</th>
            </tr>
"@

    foreach ($feature in $opportunities.PopularFeatures) {
        $htmlContent += @"
            <tr>
                <td>$($feature.Feature)</td>
                <td>$($feature.RequestCount)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
        
        <h3>ProblÃ¨mes critiques non rÃ©solus</h3>
        <table>
            <tr>
                <th>ID</th>
                <th>Composant</th>
                <th>Type</th>
                <th>Description</th>
                <th>SÃ©vÃ©ritÃ©</th>
                <th>Statut</th>
            </tr>
"@

    foreach ($issue in $opportunities.CriticalIssues) {
        $htmlContent += @"
            <tr>
                <td>$($issue.Id)</td>
                <td>$($issue.Component)</td>
                <td>$($issue.FeedbackType)</td>
                <td>$($issue.Description)</td>
                <td>$($issue.Severity)</td>
                <td>$($issue.Status)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
    </div>
    
    <p class="timestamp">Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@

    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $htmlPath" -Level "SUCCESS"
}

# Afficher un rÃ©sumÃ©
Write-Log "`nRÃ©sumÃ© de l'analyse des feedbacks:" -Level "INFO"
Write-Log "  Total des feedbacks: $($analysis.TotalFeedbacks)" -Level "INFO"
Write-Log "  Composants: $($analysis.ComponentStats.Count)" -Level "INFO"
Write-Log "  Types de feedback: $($analysis.TypeStats.Count)" -Level "INFO"
Write-Log "  Statuts: $($analysis.StatusStats.Count)" -Level "INFO"

Write-Log "`nOpportunitÃ©s d'amÃ©lioration:" -Level "INFO"
Write-Log "  Composants avec bugs: $($opportunities.BuggyComponents.Count)" -Level "INFO"
Write-Log "  Composants avec problÃ¨mes de performance: $($opportunities.SlowComponents.Count)" -Level "INFO"
Write-Log "  Demandes de fonctionnalitÃ©s populaires: $($opportunities.PopularFeatures.Count)" -Level "INFO"
Write-Log "  ProblÃ¨mes critiques non rÃ©solus: $($opportunities.CriticalIssues.Count)" -Level "INFO"
