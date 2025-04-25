# Script pour arrêter tous les serveurs MCP
# Ce script arrête tous les serveurs MCP en cours d'exécution

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

# Fonction pour arrêter un processus
function Stop-McpProcess {
    param (
        [string]$ProcessName,
        [string]$CommandLinePattern
    )
    
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    
    if ($null -eq $processes -or $processes.Count -eq 0) {
        return 0
    }
    
    $stoppedCount = 0
    
    foreach ($process in $processes) {
        try {
            $commandLine = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
            if ([string]::IsNullOrEmpty($CommandLinePattern) -or $commandLine -match $CommandLinePattern) {
                $process.Kill()
                $stoppedCount++
            }
        } catch {
            Write-Log "Erreur lors de l'arrêt du processus $($process.Id) : $_" -Level "ERROR"
        }
    }
    
    return $stoppedCount
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "      ARRÊT DES SERVEURS MCP EMAIL_SENDER_1              " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Arrêter le serveur MCP Filesystem
Write-Host "1. Arrêt du serveur MCP Filesystem..." -ForegroundColor Cyan
$filesystemStopped = Stop-McpProcess -ProcessName "node" -CommandLinePattern "modelcontextprotocol/server-filesystem"
if ($filesystemStopped -gt 0) {
    Write-Log "$filesystemStopped processus MCP Filesystem arrêtés" -Level "SUCCESS"
} else {
    Write-Log "Aucun processus MCP Filesystem trouvé" -Level "WARNING"
}

# 2. Arrêter le serveur MCP GitHub
Write-Host "2. Arrêt du serveur MCP GitHub..." -ForegroundColor Cyan
$githubStopped = Stop-McpProcess -ProcessName "node" -CommandLinePattern "modelcontextprotocol/server-github"
if ($githubStopped -gt 0) {
    Write-Log "$githubStopped processus MCP GitHub arrêtés" -Level "SUCCESS"
} else {
    Write-Log "Aucun processus MCP GitHub trouvé" -Level "WARNING"
}

# 3. Arrêter le serveur MCP GCP
Write-Host "3. Arrêt du serveur MCP GCP..." -ForegroundColor Cyan
$gcpStopped = Stop-McpProcess -ProcessName "node" -CommandLinePattern "gcp-mcp"
if ($gcpStopped -gt 0) {
    Write-Log "$gcpStopped processus MCP GCP arrêtés" -Level "SUCCESS"
} else {
    Write-Log "Aucun processus MCP GCP trouvé" -Level "WARNING"
}

# 4. Arrêter le serveur MCP Supergateway
Write-Host "4. Arrêt du serveur MCP Supergateway..." -ForegroundColor Cyan
$gatewayStopped = Stop-McpProcess -ProcessName "node" -CommandLinePattern "supergateway"
if ($gatewayStopped -gt 0) {
    Write-Log "$gatewayStopped processus MCP Supergateway arrêtés" -Level "SUCCESS"
} else {
    Write-Log "Aucun processus MCP Supergateway trouvé" -Level "WARNING"
}

# 5. Arrêter le serveur MCP Augment
Write-Host "5. Arrêt du serveur MCP Augment..." -ForegroundColor Cyan
$augmentStopped = Stop-McpProcess -ProcessName "node" -CommandLinePattern "augment-mcp"
if ($augmentStopped -gt 0) {
    Write-Log "$augmentStopped processus MCP Augment arrêtés" -Level "SUCCESS"
} else {
    Write-Log "Aucun processus MCP Augment trouvé" -Level "WARNING"
}

# 6. Arrêter le serveur MCP GDrive
Write-Host "6. Arrêt du serveur MCP GDrive..." -ForegroundColor Cyan
$gdriveStopped = Stop-McpProcess -ProcessName "node" -CommandLinePattern "mcp-gdriv"
if ($gdriveStopped -gt 0) {
    Write-Log "$gdriveStopped processus MCP GDrive arrêtés" -Level "SUCCESS"
} else {
    Write-Log "Aucun processus MCP GDrive trouvé" -Level "WARNING"
}

# Résumé
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                  RÉSUMÉ DE L'ARRÊT                      " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

$totalStopped = $filesystemStopped + $githubStopped + $gcpStopped + $gatewayStopped + $augmentStopped + $gdriveStopped

if ($totalStopped -gt 0) {
    Write-Host "Total des processus MCP arrêtés : $totalStopped" -ForegroundColor Green
} else {
    Write-Host "Aucun processus MCP n'était en cours d'exécution" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Pour démarrer les serveurs MCP, exécutez le script 'start-all-mcp-servers.cmd'." -ForegroundColor Yellow
Write-Host ""
