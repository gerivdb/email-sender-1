# Script pour vérifier l'état des serveurs MCP (version simple)
# Ce script vérifie si les serveurs MCP sont en cours d'exécution

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

# Fonction pour vérifier si un serveur MCP est en cours d'exécution
function Test-McpServerRunning {
    param (
        [string]$ServerName,
        [hashtable]$Patterns,
        [array]$ProcessList
    )
    
    # Vérifier si le serveur est en cours d'exécution
    if ($Patterns.ContainsKey($ServerName)) {
        $pattern = $Patterns[$ServerName]
        
        foreach ($process in $ProcessList) {
            if ($process -match $pattern) {
                return $true
            }
        }
    }
    
    return $false
}

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "      VÉRIFICATION DES SERVEURS MCP EMAIL_SENDER_1       " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# Obtenir la liste des processus en cours d'exécution
Write-Host "Récupération des processus en cours..." -ForegroundColor Cyan
$processList = tasklist /v /fo list | Out-String

# Définir les patterns pour chaque serveur MCP
$patterns = @{
    "Filesystem"         = "server-filesystem"
    "GitHub"             = "server-github"
    "GCP"                = "gcp-mcp"
    "Supergateway"       = "supergateway"
    "Augment"            = "augment-mcp"
    "GDrive"             = "gdrive-mcp"
    "Augment Standard"   = "n8n-nodes-mcp"
    "Augment Gateway"    = "gateway"
    "Augment Notion"     = "notion"
    "Augment Git Ingest" = "git-ingest"
    "Augment GitHub"     = "mcp-github"
}

# 1. Vérifier le serveur MCP Filesystem
Write-Host "1. Vérification du serveur MCP Filesystem..." -ForegroundColor Cyan
$filesystemRunning = Test-McpServerRunning -ServerName "Filesystem" -Patterns $patterns -ProcessList $processList
if ($filesystemRunning) {
    Write-Log "Serveur MCP Filesystem en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP Filesystem non trouvé" -Level "WARNING"
}

# 2. Vérifier le serveur MCP GitHub
Write-Host "2. Vérification du serveur MCP GitHub..." -ForegroundColor Cyan
$githubRunning = Test-McpServerRunning -ServerName "GitHub" -Patterns $patterns -ProcessList $processList
if ($githubRunning) {
    Write-Log "Serveur MCP GitHub en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP GitHub non trouvé" -Level "WARNING"
}

# 3. Vérifier le serveur MCP GCP
Write-Host "3. Vérification du serveur MCP GCP..." -ForegroundColor Cyan
$gcpRunning = Test-McpServerRunning -ServerName "GCP" -Patterns $patterns -ProcessList $processList
if ($gcpRunning) {
    Write-Log "Serveur MCP GCP en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP GCP non trouvé" -Level "WARNING"
}

# 4. Vérifier le serveur MCP Supergateway
Write-Host "4. Vérification du serveur MCP Supergateway..." -ForegroundColor Cyan
$gatewayRunning = Test-McpServerRunning -ServerName "Supergateway" -Patterns $patterns -ProcessList $processList
if ($gatewayRunning) {
    Write-Log "Serveur MCP Supergateway en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP Supergateway non trouvé" -Level "WARNING"
}

# 5. Vérifier le serveur MCP Augment
Write-Host "5. Vérification du serveur MCP Augment..." -ForegroundColor Cyan
$augmentRunning = Test-McpServerRunning -ServerName "Augment" -Patterns $patterns -ProcessList $processList
if ($augmentRunning) {
    Write-Log "Serveur MCP Augment en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP Augment non trouvé" -Level "WARNING"
}

# 6. Vérifier le serveur MCP GDrive
Write-Host "6. Vérification du serveur MCP GDrive..." -ForegroundColor Cyan
$gdriveRunning = Test-McpServerRunning -ServerName "GDrive" -Patterns $patterns -ProcessList $processList
if ($gdriveRunning) {
    Write-Log "Serveur MCP GDrive en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP GDrive non trouvé" -Level "WARNING"
}

# 7. Vérifier le serveur MCP Augment Standard
Write-Host "7. Vérification du serveur MCP Augment Standard..." -ForegroundColor Cyan
$augmentStandardRunning = Test-McpServerRunning -ServerName "Augment Standard" -Patterns $patterns -ProcessList $processList
if ($augmentStandardRunning) {
    Write-Log "Serveur MCP Augment Standard en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP Augment Standard non trouvé" -Level "WARNING"
}

# 8. Vérifier le serveur MCP Augment Gateway
Write-Host "8. Vérification du serveur MCP Augment Gateway..." -ForegroundColor Cyan
$augmentGatewayRunning = Test-McpServerRunning -ServerName "Augment Gateway" -Patterns $patterns -ProcessList $processList
if ($augmentGatewayRunning) {
    Write-Log "Serveur MCP Augment Gateway en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP Augment Gateway non trouvé" -Level "WARNING"
}

# 9. Vérifier le serveur MCP Augment Notion
Write-Host "9. Vérification du serveur MCP Augment Notion..." -ForegroundColor Cyan
$augmentNotionRunning = Test-McpServerRunning -ServerName "Augment Notion" -Patterns $patterns -ProcessList $processList
if ($augmentNotionRunning) {
    Write-Log "Serveur MCP Augment Notion en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP Augment Notion non trouvé" -Level "WARNING"
}

# 10. Vérifier le serveur MCP Augment Git Ingest
Write-Host "10. Vérification du serveur MCP Augment Git Ingest..." -ForegroundColor Cyan
$augmentGitIngestRunning = Test-McpServerRunning -ServerName "Augment Git Ingest" -Patterns $patterns -ProcessList $processList
if ($augmentGitIngestRunning) {
    Write-Log "Serveur MCP Augment Git Ingest en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP Augment Git Ingest non trouvé" -Level "WARNING"
}

# 11. Vérifier le serveur MCP Augment GitHub
Write-Host "11. Vérification du serveur MCP Augment GitHub..." -ForegroundColor Cyan
$augmentGitHubRunning = Test-McpServerRunning -ServerName "Augment GitHub" -Patterns $patterns -ProcessList $processList
if ($augmentGitHubRunning) {
    Write-Log "Serveur MCP Augment GitHub en cours d'exécution" -Level "SUCCESS"
} else {
    Write-Log "Serveur MCP Augment GitHub non trouvé" -Level "WARNING"
}

# Résumé
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                  RÉSUMÉ DES SERVEURS MCP                " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

$servers = @(
    @{ Name = "MCP Filesystem"; Running = $filesystemRunning },
    @{ Name = "MCP GitHub"; Running = $githubRunning },
    @{ Name = "MCP GCP"; Running = $gcpRunning },
    @{ Name = "MCP Supergateway"; Running = $gatewayRunning },
    @{ Name = "MCP Augment"; Running = $augmentRunning },
    @{ Name = "MCP GDrive"; Running = $gdriveRunning },
    @{ Name = "MCP Augment Standard"; Running = $augmentStandardRunning },
    @{ Name = "MCP Augment Gateway"; Running = $augmentGatewayRunning },
    @{ Name = "MCP Augment Notion"; Running = $augmentNotionRunning },
    @{ Name = "MCP Augment Git Ingest"; Running = $augmentGitIngestRunning },
    @{ Name = "MCP Augment GitHub"; Running = $augmentGitHubRunning }
)

foreach ($server in $servers) {
    $status = if ($server.Running) { "EN COURS D'EXÉCUTION" } else { "ARRÊTÉ" }
    $color = if ($server.Running) { "Green" } else { "Red" }
    Write-Host "- $($server.Name): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

Write-Host ""
Write-Host "Pour démarrer les serveurs MCP, exécutez le script 'start-all-mcp-servers.cmd'." -ForegroundColor Yellow
Write-Host ""
