#Requires -Version 5.1
<#
.SYNOPSIS
    Collecte des métriques de performance des serveurs MCP.
.DESCRIPTION
    Ce script collecte des métriques de performance des serveurs MCP
    et les enregistre dans un fichier pour analyse ultérieure.
.PARAMETER Interval
    Intervalle de collecte en secondes. Par défaut: 60.
.PARAMETER Duration
    Durée de collecte en minutes. Par défaut: 60 (1 heure).
.PARAMETER OutputFormat
    Format de sortie (CSV, JSON). Par défaut: CSV.
.PARAMETER ConfigPath
    Chemin du fichier de configuration MCP. Par défaut, "config/mcp-config.json".
.EXAMPLE
    .\collect-metrics.ps1 -Interval 30 -Duration 120
    Collecte des métriques toutes les 30 secondes pendant 2 heures.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$Interval = 60,
    
    [Parameter(Mandatory = $false)]
    [int]$Duration = 60,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("CSV", "JSON")]
    [string]$OutputFormat = "CSV",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "config/mcp-config.json"
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$monitoringRoot = (Get-Item $scriptPath).Parent.FullName
$projectRoot = (Get-Item $monitoringRoot).Parent.FullName
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
$outputPath = Join-Path -Path $monitoringRoot -ChildPath "metrics\mcp-metrics-$(Get-Date -Format 'yyyyMMdd-HHmmss').$($OutputFormat.ToLower())"

# Fonctions d'aide
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "TITLE" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-McpProcesses {
    $mcpProcesses = @()
    
    # Rechercher les processus MCP
    $processes = Get-Process | Where-Object {
        $_.ProcessName -like "*mcp*" -or
        $_.ProcessName -like "*node*" -or
        $_.ProcessName -like "*python*" -or
        $_.ProcessName -like "*gateway*"
    }
    
    foreach ($process in $processes) {
        # Vérifier si le processus est un serveur MCP
        $commandLine = $null
        try {
            $commandLine = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
        }
        catch {
            # Ignorer les erreurs
        }
        
        if ($commandLine -and ($commandLine -like "*mcp*" -or $commandLine -like "*modelcontextprotocol*")) {
            $mcpProcesses += @{
                Process = $process
                CommandLine = $commandLine
                ServerName = if ($commandLine -like "*filesystem*") { "filesystem" }
                            elseif ($commandLine -like "*github*") { "github" }
                            elseif ($commandLine -like "*gcp*") { "gcp" }
                            elseif ($commandLine -like "*notion*") { "notion" }
                            elseif ($commandLine -like "*gateway*") { "gateway" }
                            else { "unknown" }
            }
        }
    }
    
    return $mcpProcesses
}

function Collect-ServerMetrics {
    param (
        [string]$ServerName,
        [PSCustomObject]$ServerConfig
    )
    
    $metrics = @{
        Timestamp = Get-Date
        ServerName = $ServerName
        Status = "Unknown"
        CPU = $null
        Memory = $null
        Threads = $null
        Handles = $null
        ResponseTime = $null
        Details = $null
    }
    
    try {
        $startTime = Get-Date
        
        # Vérifier si le serveur est en cours d'exécution
        $mcpProcesses = Get-McpProcesses
        $serverProcess = $mcpProcesses | Where-Object { $_.ServerName -eq $ServerName }
        
        if ($serverProcess) {
            $process = $serverProcess.Process
            
            $metrics.Status = "Running"
            $metrics.CPU = $process.CPU
            $metrics.Memory = $process.WorkingSet64
            $metrics.Threads = $process.Threads.Count
            $metrics.Handles = $process.HandleCount
            $metrics.Details = "Processus en cours d'exécution (PID: $($process.Id))"
            
            # Vérifier le type de serveur et effectuer la vérification appropriée
            if ($ServerConfig.url) {
                # Serveur basé sur URL (HTTP/WebSocket)
                try {
                    $response = Invoke-WebRequest -Uri $ServerConfig.url -Method Head -TimeoutSec 5 -ErrorAction Stop
                    $endTime = Get-Date
                    $responseTime = ($endTime - $startTime).TotalMilliseconds
                    
                    $metrics.Status = "Healthy"
                    $metrics.ResponseTime = $responseTime
                    $metrics.Details = "HTTP Status: $($response.StatusCode)"
                }
                catch {
                    $metrics.Status = "Unhealthy"
                    $metrics.Details = "Erreur de connexion: $($_.Exception.Message)"
                }
            }
            else {
                # Serveur basé sur processus
                $endTime = Get-Date
                $responseTime = ($endTime - $startTime).TotalMilliseconds
                
                $metrics.ResponseTime = $responseTime
            }
        }
        else {
            $metrics.Status = "Stopped"
            $metrics.Details = "Serveur non démarré"
        }
    }
    catch {
        $metrics.Status = "Error"
        $metrics.Details = "Erreur lors de la collecte: $($_.Exception.Message)"
    }
    
    return $metrics
}

function Format-MetricsOutput {
    param (
        [array]$Metrics,
        [string]$Format
    )
    
    switch ($Format) {
        "JSON" {
            return $Metrics | ConvertTo-Json -Depth 5
        }
        default {
            # Format CSV par défaut
            $csv = "Timestamp,ServerName,Status,CPU,Memory,Threads,Handles,ResponseTime,Details`n"
            
            foreach ($metric in $Metrics) {
                $csv += "$($metric.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')),"
                $csv += "$($metric.ServerName),"
                $csv += "$($metric.Status),"
                $csv += "$($metric.CPU),"
                $csv += "$($metric.Memory),"
                $csv += "$($metric.Threads),"
                $csv += "$($metric.Handles),"
                $csv += "$($metric.ResponseTime),"
                $csv += """$($metric.Details.Replace('"', '""'))""`n"
            }
            
            return $csv
        }
    }
}

# Corps principal du script
try {
    Write-Log "Collecte des métriques de performance des serveurs MCP..." -Level "TITLE"
    
    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path $configPath)) {
        Write-Log "Fichier de configuration non trouvé: $configPath" -Level "ERROR"
        exit 1
    }
    
    # Charger la configuration
    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    $servers = $config.mcpServers
    
    # Vérifier si des serveurs sont configurés
    if (-not $servers -or $servers.PSObject.Properties.Count -eq 0) {
        Write-Log "Aucun serveur MCP configuré dans $configPath" -Level "WARNING"
        exit 0
    }
    
    # Créer le répertoire de sortie
    $outputDir = Split-Path -Parent $outputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Calculer le nombre d'itérations
    $iterations = [math]::Ceiling(($Duration * 60) / $Interval)
    
    # Collecter les métriques
    $allMetrics = @()
    
    Write-Log "Début de la collecte des métriques. Intervalle: $Interval secondes, Durée: $Duration minutes ($iterations itérations)" -Level "INFO"
    
    for ($i = 1; $i -le $iterations; $i++) {
        $iterationStart = Get-Date
        
        Write-Log "Itération $i/$iterations..." -Level "INFO"
        
        foreach ($serverName in $servers.PSObject.Properties.Name) {
            $serverConfig = $servers.$serverName
            
            # Ignorer les serveurs désactivés
            if ($serverConfig.enabled -eq $false) {
                continue
            }
            
            $metrics = Collect-ServerMetrics -ServerName $serverName -ServerConfig $serverConfig
            $allMetrics += $metrics
            
            $statusColor = switch ($metrics.Status) {
                "Healthy" { "SUCCESS" }
                "Running" { "SUCCESS" }
                "Unhealthy" { "ERROR" }
                "Stopped" { "WARNING" }
                "Error" { "ERROR" }
                default { "INFO" }
            }
            
            Write-Log "Serveur $serverName: $($metrics.Status) (CPU: $($metrics.CPU)%, Mémoire: $([math]::Round($metrics.Memory / 1MB, 2)) MB)" -Level $statusColor
        }
        
        # Enregistrer les métriques à chaque itération
        $output = Format-MetricsOutput -Metrics $allMetrics -Format $OutputFormat
        Set-Content -Path $outputPath -Value $output
        
        # Attendre l'intervalle
        if ($i -lt $iterations) {
            $iterationEnd = Get-Date
            $iterationDuration = ($iterationEnd - $iterationStart).TotalSeconds
            $sleepTime = $Interval - $iterationDuration
            
            if ($sleepTime -gt 0) {
                Write-Log "Attente de $([math]::Round($sleepTime, 2)) secondes avant la prochaine itération..." -Level "INFO"
                Start-Sleep -Seconds $sleepTime
            }
        }
    }
    
    Write-Log "Collecte des métriques terminée. $($allMetrics.Count) métriques collectées." -Level "SUCCESS"
    Write-Log "Métriques enregistrées dans: $outputPath" -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de la collecte des métriques: $_" -Level "ERROR"
    exit 1
}
