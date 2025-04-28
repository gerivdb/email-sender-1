#Requires -Version 5.1
<#
.SYNOPSIS
    Script pour arrêter tous les serveurs MCP.
.DESCRIPTION
    Ce script arrête tous les serveurs MCP en cours d'exécution ou un serveur spécifique.
.PARAMETER Server
    Nom du serveur à arrêter. Si non spécifié, tous les serveurs seront arrêtés.
.PARAMETER Force
    Force l'arrêt sans demander de confirmation.
.EXAMPLE
    .\stop-mcp-server.ps1
    Arrête tous les serveurs MCP en cours d'exécution.
.EXAMPLE
    .\stop-mcp-server.ps1 -Server filesystem
    Arrête uniquement le serveur MCP filesystem.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$Server,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Get-Item $scriptPath).Parent.Parent.FullName

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
    param (
        [string]$ServerName = ""
    )
    
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
    
    # Filtrer par nom de serveur si spécifié
    if ($ServerName) {
        $mcpProcesses = $mcpProcesses | Where-Object { $_.ServerName -eq $ServerName }
    }
    
    return $mcpProcesses
}

function Stop-McpProcess {
    param (
        [hashtable]$ProcessInfo
    )
    
    $process = $ProcessInfo.Process
    $serverName = $ProcessInfo.ServerName
    
    Write-Log "Arrêt du serveur MCP $serverName (PID: $($process.Id))..." -Level "INFO"
    
    try {
        $process | Stop-Process -Force
        Write-Log "Serveur $serverName arrêté avec succès." -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de l'arrêt du serveur $serverName: $_" -Level "ERROR"
        return $false
    }
}

# Corps principal du script
try {
    Write-Log "Arrêt des serveurs MCP..." -Level "TITLE"
    
    # Récupérer les processus MCP
    $mcpProcesses = Get-McpProcesses -ServerName $Server
    
    if ($mcpProcesses.Count -eq 0) {
        if ($Server) {
            Write-Log "Aucun serveur MCP $Server en cours d'exécution." -Level "WARNING"
        }
        else {
            Write-Log "Aucun serveur MCP en cours d'exécution." -Level "WARNING"
        }
        exit 0
    }
    
    # Demander confirmation si nécessaire
    if (-not $Force -and -not $WhatIfPreference) {
        $serverList = $mcpProcesses | ForEach-Object { "$($_.ServerName) (PID: $($_.Process.Id))" }
        Write-Log "Serveurs MCP à arrêter:" -Level "INFO"
        $serverList | ForEach-Object { Write-Log "- $_" -Level "INFO" }
        
        $confirmation = Read-Host "Voulez-vous arrêter ces serveurs MCP ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Opération annulée par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }
    
    # Arrêter les processus
    $stoppedProcesses = 0
    $failedProcesses = 0
    
    foreach ($processInfo in $mcpProcesses) {
        if ($PSCmdlet.ShouldProcess($processInfo.ServerName, "Stop MCP server")) {
            $result = Stop-McpProcess -ProcessInfo $processInfo
            if ($result) {
                $stoppedProcesses++
            }
            else {
                $failedProcesses++
            }
        }
    }
    
    Write-Log "Arrêt des serveurs MCP terminé. $stoppedProcesses serveurs arrêtés, $failedProcesses échecs." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de l'arrêt des serveurs MCP: $_" -Level "ERROR"
    exit 1
}
