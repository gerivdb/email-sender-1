<#
.SYNOPSIS
    Collecte les métriques liées à l'état du service n8n.

.DESCRIPTION
    Ce script collecte les métriques liées à l'état du service n8n, comme l'état d'exécution,
    le temps de fonctionnement, l'accessibilité du port et de l'API.

.PARAMETER N8nRootFolder
    Dossier racine de n8n.

.PARAMETER DefaultPort
    Port par défaut utilisé par n8n.

.PARAMETER DefaultProtocol
    Protocole par défaut utilisé par n8n (http ou https).

.PARAMETER DefaultHostname
    Nom d'hôte par défaut utilisé par n8n.

.PARAMETER MetricsConfig
    Configuration des métriques à collecter.

.EXAMPLE
    .\dashboard-service-metrics.ps1 -N8nRootFolder "n8n" -DefaultPort 5678 -DefaultProtocol "http" -DefaultHostname "localhost"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  26/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$N8nRootFolder = "n8n",
    
    [Parameter(Mandatory=$false)]
    [int]$DefaultPort = 5678,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("http", "https")]
    [string]$DefaultProtocol = "http",
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultHostname = "localhost",
    
    [Parameter(Mandatory=$false)]
    [object]$MetricsConfig = $null
)

# Fonction pour vérifier si n8n est en cours d'exécution
function Test-N8nRunning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$N8nRootFolder
    )
    
    $pidFile = Join-Path -Path $N8nRootFolder -ChildPath "data/n8n.pid"
    
    if (Test-Path -Path $pidFile) {
        $pid = Get-Content -Path $pidFile
        
        try {
            $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
            
            if ($null -ne $process) {
                return @{
                    Running = $true
                    PID = $pid
                    Process = $process
                    StartTime = $process.StartTime
                    Uptime = (Get-Date) - $process.StartTime
                }
            }
        } catch {
            # Le processus n'existe pas
        }
    }
    
    return @{
        Running = $false
        PID = $null
        Process = $null
        StartTime = $null
        Uptime = $null
    }
}

# Fonction pour vérifier si le port n8n est accessible
function Test-N8nPort {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 5000
    )
    
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    
    try {
        $connectionTask = $tcpClient.ConnectAsync($Hostname, $Port)
        $connectionTask.Wait($Timeout)
        
        if ($connectionTask.IsCompleted -and -not $connectionTask.IsFaulted) {
            return @{
                Accessible = $true
                ResponseTime = $connectionTask.AsyncState
                Error = $null
            }
        } else {
            return @{
                Accessible = $false
                ResponseTime = $null
                Error = "Timeout ou connexion refusée"
            }
        }
    } catch {
        return @{
            Accessible = $false
            ResponseTime = $null
            Error = $_.Exception.Message
        }
    } finally {
        $tcpClient.Close()
    }
}

# Fonction pour vérifier si l'API n8n est accessible
function Test-N8nApi {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Protocol,
        
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [string]$Endpoint = "/healthz",
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 5000
    )
    
    $url = "${Protocol}://${Hostname}:${Port}${Endpoint}"
    
    try {
        $startTime = Get-Date
        $response = Invoke-WebRequest -Uri $url -TimeoutSec ($Timeout / 1000) -UseBasicParsing
        $endTime = Get-Date
        $responseTime = ($endTime - $startTime).TotalMilliseconds
        
        return @{
            Accessible = $true
            StatusCode = $response.StatusCode
            ResponseTime = $responseTime
            Error = $null
        }
    } catch {
        return @{
            Accessible = $false
            StatusCode = $null
            ResponseTime = $null
            Error = $_.Exception.Message
        }
    }
}

# Fonction principale pour collecter les métriques de service
function Get-ServiceMetrics {
    param (
        [Parameter(Mandatory=$true)]
        [string]$N8nRootFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$Protocol,
        
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [object]$MetricsConfig = $null
    )
    
    # Vérifier si n8n est en cours d'exécution
    $runningStatus = Test-N8nRunning -N8nRootFolder $N8nRootFolder
    
    # Vérifier si le port n8n est accessible
    $portStatus = Test-N8nPort -Hostname $Hostname -Port $Port
    
    # Vérifier si l'API n8n est accessible
    $apiStatus = Test-N8nApi -Protocol $Protocol -Hostname $Hostname -Port $Port
    
    # Préparer les métriques
    $metrics = @{
        Running = @{
            Value = $runningStatus.Running
            DisplayValue = if ($runningStatus.Running) { "En cours d'exécution" } else { "Arrêté" }
            Status = if ($runningStatus.Running) { "success" } else { "danger" }
            Description = "Indique si n8n est en cours d'exécution"
            Details = if ($runningStatus.Running) { "PID: $($runningStatus.PID)" } else { "Aucun processus n8n trouvé" }
        }
        Uptime = @{
            Value = $runningStatus.Uptime
            DisplayValue = if ($runningStatus.Running) {
                $uptime = $runningStatus.Uptime
                if ($uptime.TotalDays -ge 1) {
                    "{0:D2}j {1:D2}h {2:D2}m {3:D2}s" -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds
                } elseif ($uptime.TotalHours -ge 1) {
                    "{0:D2}h {1:D2}m {2:D2}s" -f $uptime.Hours, $uptime.Minutes, $uptime.Seconds
                } else {
                    "{0:D2}m {1:D2}s" -f $uptime.Minutes, $uptime.Seconds
                }
            } else { "N/A" }
            Status = if ($runningStatus.Running) { "success" } else { "danger" }
            Description = "Durée depuis le dernier démarrage de n8n"
            Details = if ($runningStatus.Running) { "Démarré le: $($runningStatus.StartTime)" } else { "n8n n'est pas en cours d'exécution" }
        }
        Port = @{
            Value = $portStatus.Accessible
            DisplayValue = if ($portStatus.Accessible) { "Accessible" } else { "Inaccessible" }
            Status = if ($portStatus.Accessible) { "success" } else { "danger" }
            Description = "Indique si le port n8n est accessible"
            Details = if ($portStatus.Accessible) { "Port $Port est accessible" } else { "Port $Port est inaccessible: $($portStatus.Error)" }
        }
        Api = @{
            Value = $apiStatus.Accessible
            DisplayValue = if ($apiStatus.Accessible) { "Accessible" } else { "Inaccessible" }
            Status = if ($apiStatus.Accessible) { "success" } else { "danger" }
            Description = "Indique si l'API n8n est accessible"
            Details = if ($apiStatus.Accessible) { "API accessible, temps de réponse: $($apiStatus.ResponseTime) ms" } else { "API inaccessible: $($apiStatus.Error)" }
        }
    }
    
    # Déterminer l'état global du service
    $overallStatus = if ($runningStatus.Running -and $portStatus.Accessible -and $apiStatus.Accessible) {
        "online"
    } elseif ($runningStatus.Running) {
        "warning"
    } else {
        "offline"
    }
    
    $overallStatusText = switch ($overallStatus) {
        "online" { "n8n est en ligne" }
        "warning" { "n8n est en ligne avec des problèmes" }
        "offline" { "n8n est hors ligne" }
    }
    
    # Retourner les métriques
    return @{
        Metrics = $metrics
        OverallStatus = $overallStatus
        OverallStatusText = $overallStatusText
        CollectedAt = Get-Date
    }
}

# Si le script est exécuté directement, collecter et retourner les métriques
if ($MyInvocation.InvocationName -ne ".") {
    Get-ServiceMetrics -N8nRootFolder $N8nRootFolder -Protocol $DefaultProtocol -Hostname $DefaultHostname -Port $DefaultPort -MetricsConfig $MetricsConfig
}
