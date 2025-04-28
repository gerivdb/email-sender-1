#Requires -Version 5.1
<#
.SYNOPSIS
    Vérifie l'état de santé des serveurs MCP.
.DESCRIPTION
    Ce script vérifie l'état de tous les serveurs MCP configurés,
    collecte des métriques de performance et génère un rapport de santé.
.PARAMETER OutputFormat
    Format de sortie du rapport (Text, JSON, HTML). Par défaut: Text.
.PARAMETER SendAlert
    Envoie une alerte en cas de problème détecté.
.PARAMETER ConfigPath
    Chemin du fichier de configuration MCP. Par défaut, "config/mcp-config.json".
.EXAMPLE
    .\check-mcp-health.ps1 -OutputFormat HTML
    Vérifie l'état des serveurs et génère un rapport HTML.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "JSON", "HTML")]
    [string]$OutputFormat = "Text",
    
    [Parameter(Mandatory = $false)]
    [switch]$SendAlert,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "config/mcp-config.json"
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$monitoringRoot = (Get-Item $scriptPath).Parent.FullName
$projectRoot = (Get-Item $monitoringRoot).Parent.FullName
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
$reportPath = Join-Path -Path $monitoringRoot -ChildPath "reports\mcp-health-$(Get-Date -Format 'yyyyMMdd-HHmmss').$($OutputFormat.ToLower())"

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

function Test-McpServer {
    param (
        [string]$ServerName,
        [PSCustomObject]$ServerConfig
    )
    
    $serverHealth = @{
        Name = $ServerName
        Status = "Unknown"
        ResponseTime = $null
        LastChecked = Get-Date
        Details = $null
        Metrics = @{}
        Process = $null
    }
    
    try {
        $startTime = Get-Date
        
        # Vérifier si le serveur est en cours d'exécution
        $mcpProcesses = Get-McpProcesses
        $serverProcess = $mcpProcesses | Where-Object { $_.ServerName -eq $ServerName }
        
        if ($serverProcess) {
            $serverHealth.Process = $serverProcess
            $serverHealth.Metrics.Add("PID", $serverProcess.Process.Id)
            $serverHealth.Metrics.Add("Memory", $serverProcess.Process.WorkingSet64)
            $serverHealth.Metrics.Add("CPU", $serverProcess.Process.CPU)
        }
        
        # Vérifier le type de serveur et effectuer la vérification appropriée
        if ($ServerConfig.url) {
            # Serveur basé sur URL (HTTP/WebSocket)
            try {
                $response = Invoke-WebRequest -Uri $ServerConfig.url -Method Head -TimeoutSec 5 -ErrorAction Stop
                $endTime = Get-Date
                $responseTime = ($endTime - $startTime).TotalMilliseconds
                
                $serverHealth.Status = "Healthy"
                $serverHealth.ResponseTime = $responseTime
                $serverHealth.Details = "HTTP Status: $($response.StatusCode)"
                $serverHealth.Metrics.Add("StatusCode", $response.StatusCode)
            }
            catch {
                $serverHealth.Status = "Unhealthy"
                $serverHealth.Details = "Erreur de connexion: $($_.Exception.Message)"
            }
        }
        elseif ($serverProcess) {
            # Serveur basé sur processus
            $endTime = Get-Date
            $responseTime = ($endTime - $startTime).TotalMilliseconds
            
            $serverHealth.Status = "Running"
            $serverHealth.ResponseTime = $responseTime
            $serverHealth.Details = "Processus en cours d'exécution (PID: $($serverProcess.Process.Id))"
        }
        else {
            $serverHealth.Status = "Stopped"
            $serverHealth.Details = "Serveur non démarré"
        }
    }
    catch {
        $serverHealth.Status = "Error"
        $serverHealth.Details = "Erreur lors de la vérification: $($_.Exception.Message)"
    }
    
    return $serverHealth
}

function Format-Output {
    param (
        [array]$Results,
        [string]$Format
    )
    
    switch ($Format) {
        "JSON" {
            return $Results | ConvertTo-Json -Depth 5
        }
        "HTML" {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>MCP Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .healthy { background-color: #dff0d8; }
        .running { background-color: #dff0d8; }
        .unhealthy { background-color: #f2dede; }
        .stopped { background-color: #fcf8e3; }
        .error { background-color: #f2dede; }
        .unknown { background-color: #f5f5f5; }
    </style>
</head>
<body>
    <h1>MCP Health Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    <table>
        <tr>
            <th>Server</th>
            <th>Status</th>
            <th>Response Time (ms)</th>
            <th>Last Checked</th>
            <th>Details</th>
        </tr>
"@

            foreach ($result in $Results) {
                $statusClass = $result.Status.ToLower()
                
                $html += @"
        <tr class="$statusClass">
            <td>$($result.Name)</td>
            <td>$($result.Status)</td>
            <td>$($result.ResponseTime)</td>
            <td>$($result.LastChecked)</td>
            <td>$($result.Details)</td>
        </tr>
"@
            }
            
            $html += @"
    </table>
</body>
</html>
"@
            
            return $html
        }
        default {
            # Format texte par défaut
            $text = "MCP Health Report`n"
            $text += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
            
            foreach ($result in $Results) {
                $text += "Server: $($result.Name)`n"
                $text += "Status: $($result.Status)`n"
                $text += "Response Time: $($result.ResponseTime) ms`n"
                $text += "Last Checked: $($result.LastChecked)`n"
                $text += "Details: $($result.Details)`n`n"
            }
            
            return $text
        }
    }
}

function Send-HealthAlert {
    param (
        [array]$UnhealthyServers
    )
    
    $alertSubject = "MCP Health Alert: $($UnhealthyServers.Count) serveurs non sains"
    $alertBody = "Les serveurs MCP suivants sont dans un état non sain :`n`n"
    
    foreach ($server in $UnhealthyServers) {
        $alertBody += "Serveur: $($server.Name)`n"
        $alertBody += "Statut: $($server.Status)`n"
        $alertBody += "Détails: $($server.Details)`n`n"
    }
    
    $alertBody += "Veuillez vérifier l'état des serveurs MCP.`n"
    $alertBody += "Rapport complet: $reportPath`n"
    
    Write-Log "Envoi d'une alerte par e-mail..." -Level "WARNING"
    
    # Ici, vous pouvez implémenter l'envoi d'e-mail, l'intégration avec un système de monitoring, etc.
    # Exemple avec Send-MailMessage (nécessite configuration SMTP) :
    # Send-MailMessage -From "mcp-monitoring@example.com" -To "admin@example.com" -Subject $alertSubject -Body $alertBody -SmtpServer "smtp.example.com"
    
    # Pour l'instant, nous nous contentons d'écrire l'alerte dans un fichier
    $alertPath = Join-Path -Path $monitoringRoot -ChildPath "alerts\mcp-alert-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $alertDir = Split-Path -Parent $alertPath
    if (-not (Test-Path $alertDir)) {
        New-Item -Path $alertDir -ItemType Directory -Force | Out-Null
    }
    
    Set-Content -Path $alertPath -Value "$alertSubject`n`n$alertBody"
    Write-Log "Alerte enregistrée dans: $alertPath" -Level "WARNING"
}

# Corps principal du script
try {
    Write-Log "Vérification de l'état de santé des serveurs MCP..." -Level "TITLE"
    
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
    
    # Vérifier l'état de chaque serveur
    $results = @()
    
    foreach ($serverName in $servers.PSObject.Properties.Name) {
        $serverConfig = $servers.$serverName
        
        # Ignorer les serveurs désactivés
        if ($serverConfig.enabled -eq $false) {
            Write-Log "Serveur $serverName désactivé, ignoré." -Level "INFO"
            continue
        }
        
        Write-Log "Vérification du serveur $serverName..." -Level "INFO"
        $serverHealth = Test-McpServer -ServerName $serverName -ServerConfig $serverConfig
        $results += $serverHealth
        
        $statusColor = switch ($serverHealth.Status) {
            "Healthy" { "SUCCESS" }
            "Running" { "SUCCESS" }
            "Unhealthy" { "ERROR" }
            "Stopped" { "WARNING" }
            "Error" { "ERROR" }
            default { "INFO" }
        }
        
        Write-Log "Serveur $serverName: $($serverHealth.Status) (Temps de réponse: $($serverHealth.ResponseTime) ms)" -Level $statusColor
    }
    
    # Générer le rapport
    $outputDir = Split-Path -Parent $reportPath
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    $output = Format-Output -Results $results -Format $OutputFormat
    Set-Content -Path $reportPath -Value $output
    
    Write-Log "Rapport généré: $reportPath" -Level "SUCCESS"
    
    # Envoyer une alerte si nécessaire
    if ($SendAlert) {
        $unhealthyServers = $results | Where-Object { $_.Status -ne "Healthy" -and $_.Status -ne "Running" }
        if ($unhealthyServers.Count -gt 0) {
            Send-HealthAlert -UnhealthyServers $unhealthyServers
        }
        else {
            Write-Log "Tous les serveurs sont sains, aucune alerte nécessaire." -Level "SUCCESS"
        }
    }
    
    Write-Log "Vérification de l'état de santé des serveurs MCP terminée." -Level "SUCCESS"
    
    # Afficher le rapport en mode texte
    if ($OutputFormat -eq "Text") {
        Write-Host "`n$output" -ForegroundColor White
    }
} catch {
    Write-Log "Erreur lors de la vérification de l'état de santé des serveurs MCP: $_" -Level "ERROR"
    exit 1
}
