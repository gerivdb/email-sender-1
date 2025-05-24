<#
.SYNOPSIS
    Collecte les métriques de performance de n8n.

.DESCRIPTION
    Ce script collecte les métriques de performance de n8n, comme le temps de réponse,
    l'utilisation de la mémoire et du CPU.

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

.PARAMETER HistoryFile
    Fichier pour stocker l'historique des métriques de performance.

.EXAMPLE
    .\dashboard-performance-metrics.ps1 -N8nRootFolder "n8n" -DefaultPort 5678 -DefaultProtocol "http" -DefaultHostname "localhost"

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
    [object]$MetricsConfig = $null,
    
    [Parameter(Mandatory=$false)]
    [string]$HistoryFile = "n8n/logs/performance-history.json"
)

# Fonction pour mesurer le temps de réponse de l'API n8n
function Measure-ApiResponseTime {
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
        [int]$Samples = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 5000
    )
    
    $url = "${Protocol}://${Hostname}:${Port}${Endpoint}"
    $responseTimes = @()
    
    for ($i = 0; $i -lt $Samples; $i++) {
        try {
            $startTime = Get-Date
            $response = Invoke-WebRequest -Uri $url -TimeoutSec ($Timeout / 1000) -UseBasicParsing
            $endTime = Get-Date
            $responseTime = ($endTime - $startTime).TotalMilliseconds
            
            $responseTimes += $responseTime
        } catch {
            # Ignorer les erreurs et continuer
        }
        
        # Attendre un peu entre les échantillons
        Start-Sleep -Milliseconds 100
    }
    
    # Calculer la moyenne des temps de réponse
    if ($responseTimes.Count -gt 0) {
        $averageResponseTime = ($responseTimes | Measure-Object -Average).Average
        
        return @{
            Success = $true
            ResponseTime = $averageResponseTime
            Samples = $responseTimes.Count
            Error = $null
        }
    } else {
        return @{
            Success = $false
            ResponseTime = $null
            Samples = 0
            Error = "Aucun échantillon valide"
        }
    }
}

# Fonction pour obtenir l'utilisation de la mémoire et du CPU du processus n8n
function Get-ProcessResourceUsage {
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
                # Obtenir l'utilisation de la mémoire
                $memoryMB = [Math]::Round($process.WorkingSet64 / 1MB, 2)
                
                # Obtenir l'utilisation du CPU
                # Note: Cette méthode n'est pas très précise pour l'utilisation instantanée du CPU
                # Pour une mesure plus précise, il faudrait échantillonner sur une période
                $cpuPercent = [Math]::Round($process.CPU, 2)
                
                return @{
                    Success = $true
                    PID = $pid
                    MemoryMB = $memoryMB
                    CPUPercent = $cpuPercent
                    Error = $null
                }
            }
        } catch {
            # Le processus n'existe pas
        }
    }
    
    return @{
        Success = $false
        PID = $null
        MemoryMB = $null
        CPUPercent = $null
        Error = "Processus n8n non trouvé"
    }
}

# Fonction pour charger l'historique des métriques de performance
function Import-PerformanceHistory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$HistoryFile,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxPoints = 20
    )
    
    if (Test-Path -Path $HistoryFile) {
        try {
            $history = Get-Content -Path $HistoryFile -Raw | ConvertFrom-Json
            
            # Limiter le nombre de points d'historique
            if ($history.ResponseTime.Count -gt $MaxPoints) {
                $history.ResponseTime = $history.ResponseTime | Select-Object -Last $MaxPoints
                $history.MemoryMB = $history.MemoryMB | Select-Object -Last $MaxPoints
                $history.CPUPercent = $history.CPUPercent | Select-Object -Last $MaxPoints
                $history.Timestamps = $history.Timestamps | Select-Object -Last $MaxPoints
            }
            
            return $history
        } catch {
            # Erreur lors du chargement de l'historique
        }
    }
    
    # Retourner un historique vide
    return @{
        ResponseTime = @()
        MemoryMB = @()
        CPUPercent = @()
        Timestamps = @()
    }
}

# Fonction pour sauvegarder l'historique des métriques de performance
function Save-PerformanceHistory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$HistoryFile,
        
        [Parameter(Mandatory=$true)]
        [object]$History
    )
    
    try {
        # Créer le dossier parent s'il n'existe pas
        $historyFolder = Split-Path -Path $HistoryFile -Parent
        if (-not (Test-Path -Path $historyFolder)) {
            New-Item -Path $historyFolder -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder l'historique
        $History | ConvertTo-Json | Set-Content -Path $HistoryFile -Encoding UTF8
        
        return $true
    } catch {
        # Erreur lors de la sauvegarde de l'historique
        return $false
    }
}

# Fonction principale pour collecter les métriques de performance
function Get-PerformanceMetrics {
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
        [object]$MetricsConfig = $null,
        
        [Parameter(Mandatory=$false)]
        [string]$HistoryFile = "n8n/logs/performance-history.json",
        
        [Parameter(Mandatory=$false)]
        [int]$MaxHistoryPoints = 20
    )
    
    # Mesurer le temps de réponse de l'API
    $responseTimeResult = Measure-ApiResponseTime -Protocol $Protocol -Hostname $Hostname -Port $Port
    
    # Obtenir l'utilisation des ressources du processus
    $resourceUsage = Get-ProcessResourceUsage -N8nRootFolder $N8nRootFolder
    
    # Charger l'historique des métriques
    $history = Import-PerformanceHistory -HistoryFile $HistoryFile -MaxPoints $MaxHistoryPoints
    
    # Ajouter les nouvelles métriques à l'historique
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $history.Timestamps += $timestamp
    $history.ResponseTime += if ($responseTimeResult.Success) { $responseTimeResult.ResponseTime } else { $null }
    $history.MemoryMB += if ($resourceUsage.Success) { $resourceUsage.MemoryMB } else { $null }
    $history.CPUPercent += if ($resourceUsage.Success) { $resourceUsage.CPUPercent } else { $null }
    
    # Sauvegarder l'historique mis à jour
    Save-PerformanceHistory -HistoryFile $HistoryFile -History $history
    
    # Préparer les métriques
    $metrics = @{
        ResponseTime = @{
            Value = if ($responseTimeResult.Success) { $responseTimeResult.ResponseTime } else { $null }
            DisplayValue = if ($responseTimeResult.Success) { "$([Math]::Round($responseTimeResult.ResponseTime, 2)) ms" } else { "N/A" }
            Status = if ($responseTimeResult.Success) {
                if ($responseTimeResult.ResponseTime -lt 200) { "success" }
                elseif ($responseTimeResult.ResponseTime -lt 500) { "warning" }
                else { "danger" }
            } else { "danger" }
            Description = "Temps de réponse de l'API n8n"
            Details = if ($responseTimeResult.Success) { "Basé sur $($responseTimeResult.Samples) échantillons" } else { "Erreur: $($responseTimeResult.Error)" }
            History = $history.ResponseTime
        }
        Memory = @{
            Value = if ($resourceUsage.Success) { $resourceUsage.MemoryMB } else { $null }
            DisplayValue = if ($resourceUsage.Success) { "$($resourceUsage.MemoryMB) MB" } else { "N/A" }
            Status = if ($resourceUsage.Success) {
                if ($resourceUsage.MemoryMB -lt 200) { "success" }
                elseif ($resourceUsage.MemoryMB -lt 500) { "warning" }
                else { "danger" }
            } else { "danger" }
            Description = "Utilisation de la mémoire par le processus n8n"
            Details = if ($resourceUsage.Success) { "PID: $($resourceUsage.PID)" } else { "Erreur: $($resourceUsage.Error)" }
            History = $history.MemoryMB
        }
        CPU = @{
            Value = if ($resourceUsage.Success) { $resourceUsage.CPUPercent } else { $null }
            DisplayValue = if ($resourceUsage.Success) { "$($resourceUsage.CPUPercent)%" } else { "N/A" }
            Status = if ($resourceUsage.Success) {
                if ($resourceUsage.CPUPercent -lt 30) { "success" }
                elseif ($resourceUsage.CPUPercent -lt 70) { "warning" }
                else { "danger" }
            } else { "danger" }
            Description = "Utilisation du CPU par le processus n8n"
            Details = if ($resourceUsage.Success) { "PID: $($resourceUsage.PID)" } else { "Erreur: $($resourceUsage.Error)" }
            History = $history.CPUPercent
        }
    }
    
    # Retourner les métriques
    return @{
        Metrics = $metrics
        History = $history
        CollectedAt = Get-Date
    }
}

# Si le script est exécuté directement, collecter et retourner les métriques
if ($MyInvocation.InvocationName -ne ".") {
    Get-PerformanceMetrics -N8nRootFolder $N8nRootFolder -Protocol $DefaultProtocol -Hostname $DefaultHostname -Port $DefaultPort -MetricsConfig $MetricsConfig -HistoryFile $HistoryFile
}

