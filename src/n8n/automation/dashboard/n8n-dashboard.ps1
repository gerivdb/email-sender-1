<#
.SYNOPSIS
    Script principal du tableau de bord n8n.

.DESCRIPTION
    Ce script génère un tableau de bord HTML pour surveiller l'état de n8n.

.PARAMETER ConfigFile
    Fichier de configuration à utiliser (par défaut: n8n/config/n8n-manager-config.json).

.PARAMETER OutputFile
    Fichier de sortie HTML du tableau de bord (par défaut: n8n/data/dashboard.html).

.PARAMETER AutoRefreshInterval
    Intervalle de rafraîchissement automatique en secondes (0 pour désactiver, par défaut: 60).

.PARAMETER OpenBrowser
    Indique s'il faut ouvrir le navigateur après la génération du tableau de bord (par défaut: $true).

.PARAMETER NoInteractive
    Exécute le script en mode non interactif (sans demander de confirmation).

.EXAMPLE
    .\n8n-dashboard.ps1
    Génère le tableau de bord avec les paramètres par défaut et l'ouvre dans le navigateur.

.EXAMPLE
    .\n8n-dashboard.ps1 -OutputFile "C:\temp\n8n-dashboard.html" -AutoRefreshInterval 0 -OpenBrowser $false
    Génère le tableau de bord dans un fichier personnalisé, sans rafraîchissement automatique et sans ouvrir le navigateur.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  26/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "n8n/config/n8n-manager-config.json",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "n8n/data/dashboard.html",
    
    [Parameter(Mandatory=$false)]
    [int]$AutoRefreshInterval = 60,
    
    [Parameter(Mandatory=$false)]
    [bool]$OpenBrowser = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$NoInteractive
)

# Fonction pour charger la configuration
function Import-Configuration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigFile
    )
    
    if (Test-Path -Path $ConfigFile) {
        try {
            $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Warning "Erreur lors du chargement de la configuration: $_"
        }
    } else {
        Write-Warning "Fichier de configuration non trouvé: $ConfigFile"
    }
    
    # Configuration par défaut
    return @{
        N8nRootFolder = "n8n"
        WorkflowFolder = "n8n/data/.n8n/workflows"
        LogFolder = "n8n/logs"
        DefaultPort = 5678
        DefaultProtocol = "http"
        DefaultHostname = "localhost"
    }
}

# Fonction pour charger les métriques
function Import-DashboardMetrics {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Config,
        
        [Parameter(Mandatory=$false)]
        [object]$MetricsConfig = $null
    )
    
    # Chemin des scripts
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
    
    # Charger les métriques de service
    $serviceMetricsScript = Join-Path -Path $scriptPath -ChildPath "dashboard-service-metrics.ps1"
    $serviceMetrics = & $serviceMetricsScript -N8nRootFolder $Config.N8nRootFolder -DefaultPort $Config.DefaultPort -DefaultProtocol $Config.DefaultProtocol -DefaultHostname $Config.DefaultHostname -MetricsConfig $MetricsConfig
    
    # Charger les métriques de performance
    $performanceMetricsScript = Join-Path -Path $scriptPath -ChildPath "dashboard-performance-metrics.ps1"
    $performanceMetrics = & $performanceMetricsScript -N8nRootFolder $Config.N8nRootFolder -DefaultPort $Config.DefaultPort -DefaultProtocol $Config.DefaultProtocol -DefaultHostname $Config.DefaultHostname -MetricsConfig $MetricsConfig -HistoryFile "$($Config.LogFolder)/performance-history.json"
    
    # Charger les métriques de workflows
    $workflowMetricsScript = Join-Path -Path $scriptPath -ChildPath "dashboard-workflow-metrics.ps1"
    $workflowMetrics = & $workflowMetricsScript -DefaultPort $Config.DefaultPort -DefaultProtocol $Config.DefaultProtocol -DefaultHostname $Config.DefaultHostname -WorkflowFolder $Config.WorkflowFolder -MetricsConfig $MetricsConfig
    
    # Charger les métriques d'historique
    $historyMetricsScript = Join-Path -Path $scriptPath -ChildPath "dashboard-history-metrics.ps1"
    $historyMetrics = & $historyMetricsScript -N8nRootFolder $Config.N8nRootFolder -LogFolder $Config.LogFolder -MetricsConfig $MetricsConfig
    
    # Charger les métriques d'endpoints
    $endpointMetricsScript = Join-Path -Path $scriptPath -ChildPath "dashboard-endpoint-metrics.ps1"
    $endpointMetrics = & $endpointMetricsScript -DefaultPort $Config.DefaultPort -DefaultProtocol $Config.DefaultProtocol -DefaultHostname $Config.DefaultHostname -MetricsConfig $MetricsConfig
    
    # Charger les événements récents
    $eventsScript = Join-Path -Path $scriptPath -ChildPath "dashboard-events.ps1"
    $eventsMetrics = & $eventsScript -LogFolder $Config.LogFolder -MaxEvents 10 -MetricsConfig $MetricsConfig
    
    return @{
        ServiceMetrics = $serviceMetrics
        PerformanceMetrics = $performanceMetrics
        WorkflowMetrics = $workflowMetrics
        HistoryMetrics = $historyMetrics
        EndpointMetrics = $endpointMetrics
        EventsMetrics = $eventsMetrics
    }
}

# Fonction pour générer le tableau de bord
function New-Dashboard {
    param (
        [Parameter(Mandatory=$true)]
        [object]$Config,
        
        [Parameter(Mandatory=$true)]
        [object]$Metrics,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFile,
        
        [Parameter(Mandatory=$false)]
        [int]$AutoRefreshInterval = 60
    )
    
    # Chemin des scripts
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
    
    # Chemin du modèle HTML
    $templateFile = Join-Path -Path $scriptPath -ChildPath "dashboard-template.html"
    
    # Générer le HTML du tableau de bord
    $htmlGeneratorScript = Join-Path -Path $scriptPath -ChildPath "dashboard-html-generator.ps1"
    $dashboardFile = & $htmlGeneratorScript -TemplateFile $templateFile -OutputFile $OutputFile -ServiceMetrics $Metrics.ServiceMetrics -PerformanceMetrics $Metrics.PerformanceMetrics -WorkflowMetrics $Metrics.WorkflowMetrics -HistoryMetrics $Metrics.HistoryMetrics -EndpointMetrics $Metrics.EndpointMetrics -EventsMetrics $Metrics.EventsMetrics -AutoRefreshInterval $AutoRefreshInterval
    
    return $dashboardFile
}

# Fonction pour ouvrir le tableau de bord dans le navigateur
function Open-Dashboard {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DashboardFile
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $DashboardFile)) {
        Write-Warning "Fichier de tableau de bord non trouvé: $DashboardFile"
        return $false
    }
    
    # Obtenir le chemin absolu du fichier
    $absolutePath = Resolve-Path -Path $DashboardFile
    
    # Ouvrir le fichier dans le navigateur par défaut
    try {
        Start-Process "file:///$($absolutePath.Path.Replace('\', '/'))"
        return $true
    } catch {
        Write-Warning "Erreur lors de l'ouverture du tableau de bord: $_"
        return $false
    }
}

# Fonction principale
function Main {
    # Afficher le message de démarrage
    Write-Host "Génération du tableau de bord n8n..." -ForegroundColor Cyan
    
    # Charger la configuration
    $config = Import-Configuration -ConfigFile $ConfigFile
    
    # Charger les métriques
    Write-Host "Collecte des métriques..." -ForegroundColor Cyan
    $metrics = Import-DashboardMetrics -Config $config
    
    # Générer le tableau de bord
    Write-Host "Génération du tableau de bord..." -ForegroundColor Cyan
    $dashboardFile = New-Dashboard -Config $config -Metrics $metrics -OutputFile $OutputFile -AutoRefreshInterval $AutoRefreshInterval
    
    # Afficher le chemin du fichier de tableau de bord
    Write-Host "Tableau de bord généré: $dashboardFile" -ForegroundColor Green
    
    # Ouvrir le tableau de bord dans le navigateur
    if ($OpenBrowser) {
        Write-Host "Ouverture du tableau de bord dans le navigateur..." -ForegroundColor Cyan
        $opened = Open-Dashboard -DashboardFile $dashboardFile
        
        if ($opened) {
            Write-Host "Tableau de bord ouvert dans le navigateur." -ForegroundColor Green
        } else {
            Write-Host "Impossible d'ouvrir le tableau de bord dans le navigateur." -ForegroundColor Red
        }
    }
    
    # Retourner le chemin du fichier de tableau de bord
    return $dashboardFile
}

# Exécuter la fonction principale
if ($MyInvocation.InvocationName -ne ".") {
    Main
}

