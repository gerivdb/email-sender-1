#Requires -Version 5.1
<#
.SYNOPSIS
    Vérifie l'état des serveurs MCP.
.DESCRIPTION
    Ce script permet de vérifier l'état des serveurs MCP et d'afficher un rapport.
.EXAMPLE
    .\check-mcp-servers.ps1
    Vérifie l'état des serveurs MCP et affiche un rapport.
#>

[CmdletBinding()]
param ()

# Fonction pour écrire des logs
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
    
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

function Test-HttpServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [int]$Timeout = 5
    )
    
    try {
        $request = [System.Net.WebRequest]::Create($Url)
        $request.Timeout = $Timeout * 1000
        $request.Method = "HEAD"
        
        try {
            $response = $request.GetResponse()
            $response.Close()
            return $true
        } catch {
            return $false
        }
    } catch {
        return $false
    }
}

function Get-McpServerStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Url = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ProcessName = "",
        
        [Parameter(Mandatory = $false)]
        [string]$WindowTitle = ""
    )
    
    $status = @{
        Name = $Name
        Status = "Arrêté"
        Url = $Url
        ProcessName = $ProcessName
        WindowTitle = $WindowTitle
    }
    
    # Vérifier si le serveur est en cours d'exécution
    if ($WindowTitle) {
        $process = Get-Process | Where-Object { $_.MainWindowTitle -like "*$WindowTitle*" }
        if ($process) {
            $status.Status = "En cours d'exécution"
        }
    }
    
    if ($ProcessName) {
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($process) {
            $status.Status = "En cours d'exécution"
        }
    }
    
    # Vérifier si le serveur HTTP est accessible
    if ($Url -and $status.Status -eq "En cours d'exécution") {
        $isAccessible = Test-HttpServer -Url $Url
        if ($isAccessible) {
            $status.Status = "En cours d'exécution (HTTP accessible)"
        } else {
            $status.Status = "En cours d'exécution (HTTP inaccessible)"
        }
    }
    
    return $status
}

try {
    Write-Log "Vérification de l'état des serveurs MCP..." -Level "INFO"
    
    # Liste des serveurs MCP
    $servers = @(
        @{
            Name = "Filesystem"
            WindowTitle = "MCP Filesystem"
        },
        @{
            Name = "GitHub"
            WindowTitle = "MCP GitHub"
        },
        @{
            Name = "Git Ingest"
            WindowTitle = "MCP Git Ingest"
            Url = "http://localhost:8001"
        },
        @{
            Name = "GCP"
            WindowTitle = "MCP GCP"
        },
        @{
            Name = "Notion"
            WindowTitle = "MCP Notion"
        },
        @{
            Name = "Gateway"
            WindowTitle = "MCP Gateway"
        },
        @{
            Name = "n8n"
            Url = "http://localhost:5678"
        }
    )
    
    # Vérifier l'état de chaque serveur
    $results = @()
    foreach ($server in $servers) {
        $status = Get-McpServerStatus @server
        $results += $status
    }
    
    # Afficher le rapport
    Write-Log "Rapport d'état des serveurs MCP:" -Level "INFO"
    Write-Log "-----------------------------" -Level "INFO"
    
    foreach ($result in $results) {
        $statusColor = switch ($result.Status) {
            "En cours d'exécution" { "SUCCESS" }
            "En cours d'exécution (HTTP accessible)" { "SUCCESS" }
            "En cours d'exécution (HTTP inaccessible)" { "WARNING" }
            default { "ERROR" }
        }
        
        Write-Log "Serveur: $($result.Name)" -Level "INFO"
        Write-Log "  Status: $($result.Status)" -Level $statusColor
        if ($result.Url) {
            Write-Log "  URL: $($result.Url)" -Level "INFO"
        }
        Write-Log "" -Level "INFO"
    }
    
    # Afficher un résumé
    $runningServers = $results | Where-Object { $_.Status -like "En cours d'exécution*" }
    $stoppedServers = $results | Where-Object { $_.Status -eq "Arrêté" }
    
    Write-Log "Résumé:" -Level "INFO"
    Write-Log "  Serveurs en cours d'exécution: $($runningServers.Count)" -Level "SUCCESS"
    Write-Log "  Serveurs arrêtés: $($stoppedServers.Count)" -Level "ERROR"
    
    if ($stoppedServers.Count -gt 0) {
        Write-Log "" -Level "INFO"
        Write-Log "Serveurs arrêtés:" -Level "WARNING"
        foreach ($server in $stoppedServers) {
            Write-Log "  - $($server.Name)" -Level "ERROR"
        }
        
        Write-Log "" -Level "INFO"
        Write-Log "Pour démarrer tous les serveurs, exécutez: .\start-all-mcp-servers.cmd" -Level "INFO"
    }
    
    Write-Log "Vérification terminée." -Level "INFO"
} catch {
    Write-Log "Erreur lors de la vérification de l'état des serveurs MCP: $_" -Level "ERROR"
    exit 1
}
