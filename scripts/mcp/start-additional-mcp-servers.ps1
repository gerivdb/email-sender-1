# Script pour démarrer les serveurs MCP supplémentaires
# Ce script démarre les serveurs MCP supplémentaires trouvés dans le projet

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

# Fonction pour démarrer un serveur MCP
function Start-McpServer {
    param (
        [string]$Name,
        [string]$ScriptPath
    )
    
    Write-Log "Démarrage du serveur MCP: $Name" -Level "INFO"
    
    # Vérifier si le script existe
    if (-not (Test-Path $ScriptPath)) {
        Write-Log "Le script '$ScriptPath' n'existe pas." -Level "ERROR"
        return $false
    }
    
    # Démarrer le processus
    try {
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $ScriptPath -PassThru
        Write-Log "Serveur MCP '$Name' démarré avec PID: $($process.Id)" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Échec du démarrage du serveur MCP '$Name': $_" -Level "ERROR"
        return $false
    }
}

# Chemin du répertoire racine du projet
$projectRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\"
$projectRoot = (Resolve-Path $projectRoot).Path

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "    DÉMARRAGE DES SERVEURS MCP SUPPLÉMENTAIRES           " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Démarrer le serveur MCP GDrive
Write-Host "1. Démarrage du serveur MCP GDrive..." -ForegroundColor Cyan
$gdriveMcpPath = Join-Path -Path $projectRoot -ChildPath "scripts\email\gdrive-mcp.cmd"
$gdriveSuccess = Start-McpServer -Name "GDrive" -ScriptPath $gdriveMcpPath

# 2. Démarrer le serveur MCP Augment Standard
Write-Host "2. Démarrage du serveur MCP Augment Standard..." -ForegroundColor Cyan
$augmentStandardPath = Join-Path -Path $projectRoot -ChildPath "scripts\workflow\augment-mcp-standard.cmd"
$augmentStandardSuccess = Start-McpServer -Name "Augment Standard" -ScriptPath $augmentStandardPath

# 3. Démarrer le serveur MCP Augment Gateway
Write-Host "3. Démarrage du serveur MCP Augment Gateway..." -ForegroundColor Cyan
$augmentGatewayPath = Join-Path -Path $projectRoot -ChildPath "scripts\mcp\augment-mcp-gateway.cmd"
$augmentGatewaySuccess = Start-McpServer -Name "Augment Gateway" -ScriptPath $augmentGatewayPath

# 4. Démarrer le serveur MCP Augment Notion
Write-Host "4. Démarrage du serveur MCP Augment Notion..." -ForegroundColor Cyan
$augmentNotionPath = Join-Path -Path $projectRoot -ChildPath "scripts\mcp\augment-mcp-notion.cmd"
$augmentNotionSuccess = Start-McpServer -Name "Augment Notion" -ScriptPath $augmentNotionPath

# 5. Démarrer le serveur MCP Augment Git Ingest
Write-Host "5. Démarrage du serveur MCP Augment Git Ingest..." -ForegroundColor Cyan
$augmentGitIngestPath = Join-Path -Path $projectRoot -ChildPath "scripts\mcp\augment-mcp-git-ingest.cmd"
$augmentGitIngestSuccess = Start-McpServer -Name "Augment Git Ingest" -ScriptPath $augmentGitIngestPath

# 6. Démarrer le serveur MCP Augment GitHub
Write-Host "6. Démarrage du serveur MCP Augment GitHub..." -ForegroundColor Cyan
$augmentGitHubPath = Join-Path -Path $projectRoot -ChildPath "scripts\utils\git\augment-mcp-github.cmd"
$augmentGitHubSuccess = Start-McpServer -Name "Augment GitHub" -ScriptPath $augmentGitHubPath

# Résumé
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                  RÉSUMÉ DES SERVEURS MCP                " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

$servers = @(
    @{ Name = "MCP GDrive"; Success = $gdriveSuccess },
    @{ Name = "MCP Augment Standard"; Success = $augmentStandardSuccess },
    @{ Name = "MCP Augment Gateway"; Success = $augmentGatewaySuccess },
    @{ Name = "MCP Augment Notion"; Success = $augmentNotionSuccess },
    @{ Name = "MCP Augment Git Ingest"; Success = $augmentGitIngestSuccess },
    @{ Name = "MCP Augment GitHub"; Success = $augmentGitHubSuccess }
)

foreach ($server in $servers) {
    $status = if ($server.Success) { "DÉMARRÉ" } else { "ÉCHEC" }
    $color = if ($server.Success) { "Green" } else { "Red" }
    Write-Host "- $($server.Name): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

Write-Host ""
Write-Host "Pour arrêter les serveurs MCP, fermez les fenêtres de terminal ou utilisez Ctrl+C dans chaque fenêtre." -ForegroundColor Yellow
Write-Host ""
