<#
.SYNOPSIS
    Génère le HTML du tableau de bord n8n.

.DESCRIPTION
    Ce script génère le HTML du tableau de bord n8n à partir des métriques collectées.

.PARAMETER TemplateFile
    Fichier de modèle HTML du tableau de bord.

.PARAMETER OutputFile
    Fichier de sortie HTML du tableau de bord.

.PARAMETER ServiceMetrics
    Métriques de service collectées.

.PARAMETER PerformanceMetrics
    Métriques de performance collectées.

.PARAMETER WorkflowMetrics
    Métriques de workflows collectées.

.PARAMETER HistoryMetrics
    Métriques d'historique collectées.

.PARAMETER EndpointMetrics
    Métriques d'endpoints collectées.

.PARAMETER EventsMetrics
    Événements récents collectés.

.PARAMETER AutoRefreshInterval
    Intervalle de rafraîchissement automatique en secondes (0 pour désactiver).

.EXAMPLE
    .\dashboard-html-generator.ps1 -TemplateFile "dashboard-template.html" -OutputFile "dashboard.html" -ServiceMetrics $serviceMetrics -PerformanceMetrics $performanceMetrics -WorkflowMetrics $workflowMetrics -HistoryMetrics $historyMetrics -EndpointMetrics $endpointMetrics -EventsMetrics $eventsMetrics -AutoRefreshInterval 60

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  26/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$TemplateFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$true)]
    [object]$ServiceMetrics,
    
    [Parameter(Mandatory=$true)]
    [object]$PerformanceMetrics,
    
    [Parameter(Mandatory=$true)]
    [object]$WorkflowMetrics,
    
    [Parameter(Mandatory=$true)]
    [object]$HistoryMetrics,
    
    [Parameter(Mandatory=$true)]
    [object]$EndpointMetrics,
    
    [Parameter(Mandatory=$true)]
    [object]$EventsMetrics,
    
    [Parameter(Mandatory=$false)]
    [int]$AutoRefreshInterval = 60
)

# Fonction pour générer le HTML des métriques
function Generate-MetricsHtml {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Metrics
    )
    
    $html = ""
    
    foreach ($key in $Metrics.Keys) {
        $metric = $Metrics[$key]
        
        $html += @"
<div class="metric">
    <div class="metric-header">
        <div class="metric-name">$($metric.Description)</div>
        <div class="metric-value $($metric.Status)">$($metric.DisplayValue)</div>
    </div>
    <div class="metric-description">$($metric.Details)</div>
</div>
"@
    }
    
    return $html
}

# Fonction pour générer le script de rafraîchissement automatique
function Generate-AutoRefreshScript {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Interval
    )
    
    if ($Interval -le 0) {
        return "// Rafraîchissement automatique désactivé"
    }
    
    return @"
// Rafraîchissement automatique
setTimeout(function() {
    window.location.reload();
}, $($Interval * 1000));
"@
}

# Fonction principale pour générer le HTML du tableau de bord
function Generate-DashboardHtml {
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplateFile,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFile,
        
        [Parameter(Mandatory=$true)]
        [object]$ServiceMetrics,
        
        [Parameter(Mandatory=$true)]
        [object]$PerformanceMetrics,
        
        [Parameter(Mandatory=$true)]
        [object]$WorkflowMetrics,
        
        [Parameter(Mandatory=$true)]
        [object]$HistoryMetrics,
        
        [Parameter(Mandatory=$true)]
        [object]$EndpointMetrics,
        
        [Parameter(Mandatory=$true)]
        [object]$EventsMetrics,
        
        [Parameter(Mandatory=$false)]
        [int]$AutoRefreshInterval = 60
    )
    
    # Vérifier si le fichier de modèle existe
    if (-not (Test-Path -Path $TemplateFile)) {
        throw "Fichier de modèle non trouvé: $TemplateFile"
    }
    
    # Lire le contenu du fichier de modèle
    $template = Get-Content -Path $TemplateFile -Raw
    
    # Générer le HTML des métriques
    $serviceMetricsHtml = Generate-MetricsHtml -Metrics $ServiceMetrics.Metrics
    $performanceMetricsHtml = Generate-MetricsHtml -Metrics $PerformanceMetrics.Metrics
    $workflowMetricsHtml = Generate-MetricsHtml -Metrics $WorkflowMetrics.Metrics
    $historyMetricsHtml = Generate-MetricsHtml -Metrics $HistoryMetrics.Metrics
    $endpointMetricsHtml = Generate-MetricsHtml -Metrics $EndpointMetrics.Metrics
    
    # Générer les données pour les graphiques
    $performanceChartLabels = $PerformanceMetrics.History.Timestamps | ConvertTo-Json
    $responseTimeData = $PerformanceMetrics.History.ResponseTime | ConvertTo-Json
    $memoryUsageData = $PerformanceMetrics.History.MemoryMB | ConvertTo-Json
    $cpuUsageData = $PerformanceMetrics.History.CPUPercent | ConvertTo-Json
    
    $workflowsChartData = @(
        $WorkflowMetrics.Metrics.ActiveWorkflows.Value,
        $WorkflowMetrics.Metrics.InactiveWorkflows.Value,
        $WorkflowMetrics.Metrics.WorkflowsWithErrors.Value
    ) | ConvertTo-Json
    
    # Générer le script de rafraîchissement automatique
    $autoRefreshScript = Generate-AutoRefreshScript -Interval $AutoRefreshInterval
    
    # Remplacer les variables dans le modèle
    $html = $template
    $html = $html -replace "{{SERVICE_STATUS_CLASS}}", $ServiceMetrics.OverallStatus
    $html = $html -replace "{{SERVICE_STATUS_TEXT}}", $ServiceMetrics.OverallStatusText
    $html = $html -replace "{{SERVICE_STATUS_METRICS}}", $serviceMetricsHtml
    $html = $html -replace "{{PERFORMANCE_METRICS}}", $performanceMetricsHtml
    $html = $html -replace "{{WORKFLOW_METRICS}}", $workflowMetricsHtml
    $html = $html -replace "{{HISTORY_METRICS}}", $historyMetricsHtml
    $html = $html -replace "{{ENDPOINT_METRICS}}", $endpointMetricsHtml
    $html = $html -replace "{{RECENT_EVENTS}}", $EventsMetrics.EventsHtml
    $html = $html -replace "{{PERFORMANCE_CHART_LABELS}}", $performanceChartLabels
    $html = $html -replace "{{RESPONSE_TIME_DATA}}", $responseTimeData
    $html = $html -replace "{{MEMORY_USAGE_DATA}}", $memoryUsageData
    $html = $html -replace "{{CPU_USAGE_DATA}}", $cpuUsageData
    $html = $html -replace "{{WORKFLOWS_CHART_DATA}}", $workflowsChartData
    $html = $html -replace "{{AUTO_REFRESH_SCRIPT}}", $autoRefreshScript
    $html = $html -replace "{{LAST_REFRESH}}", (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $html = $html -replace "{{AUTO_REFRESH}}", if ($AutoRefreshInterval -gt 0) { "Toutes les $AutoRefreshInterval secondes" } else { "Désactivé" }
    
    # Créer le dossier parent s'il n'existe pas
    $outputFolder = Split-Path -Path $OutputFile -Parent
    if (-not (Test-Path -Path $outputFolder)) {
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Écrire le HTML dans le fichier de sortie
    Set-Content -Path $OutputFile -Value $html -Encoding UTF8
    
    return $OutputFile
}

# Si le script est exécuté directement, générer le HTML du tableau de bord
if ($MyInvocation.InvocationName -ne ".") {
    Generate-DashboardHtml -TemplateFile $TemplateFile -OutputFile $OutputFile -ServiceMetrics $ServiceMetrics -PerformanceMetrics $PerformanceMetrics -WorkflowMetrics $WorkflowMetrics -HistoryMetrics $HistoryMetrics -EndpointMetrics $EndpointMetrics -EventsMetrics $EventsMetrics -AutoRefreshInterval $AutoRefreshInterval
}
