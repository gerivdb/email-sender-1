# Script de démarrage unifié pour tous les serveurs MCP (version 2.0)
# Ce script démarre tous les serveurs MCP nécessaires pour le projet

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
        "TITLE" { Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan; Write-Host $Message -ForegroundColor Cyan; Write-Host ("=" * 60) -ForegroundColor Cyan }
    }

    # Écrire dans le fichier journal
    try {
        $logDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\logs"
        $logPath = Join-Path -Path $logDir -ChildPath "mcp_servers_$(Get-Date -Format 'yyyy-MM-dd').log"

        # Créer le répertoire de logs si nécessaire
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}

# Fonction pour vérifier si un programme est installé
function Test-CommandExists {
    param (
        [string]$Command
    )

    $exists = $null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue)
    return $exists
}

# Fonction pour vérifier si un serveur MCP est déjà en cours d'exécution
function Test-McpServerRunning {
    param (
        [string]$Name,
        [string]$Pattern
    )

    # Récupérer tous les processus avec leur ligne de commande
    try {
        $processes = Get-CimInstance -ClassName Win32_Process -ErrorAction Stop |
            Select-Object ProcessId, Name, CommandLine
    } catch {
        Write-Log "Erreur lors de la récupération des processus: $_" -Level "WARNING"
        return $false
    }

    # Rechercher le processus correspondant au pattern
    foreach ($process in $processes) {
        if ($process.CommandLine -match $Pattern) {
            Write-Log "Le serveur MCP '$Name' est déjà en cours d'exécution (PID: $($process.ProcessId))" -Level "INFO"
            return $true
        }
    }

    return $false
}

# Fonction pour démarrer un serveur MCP
function Start-McpServer {
    param (
        [string]$Name,
        [string]$Command,
        [string[]]$Arguments = @(),
        [hashtable]$EnvironmentVariables = @{},
        [switch]$NoWindow
    )

    Write-Log "Démarrage du serveur MCP: $Name" -Level "INFO"

    # Construire la commande complète pour la vérification
    $commandPattern = $Command
    if ($Arguments.Count -gt 0) {
        $commandPattern += ".*" + ($Arguments[0] -replace "[\\^\$\.\[\]\(\)\{\}\|\*\+\?]", "\$&")
    }

    # Vérifier si le serveur est déjà en cours d'exécution
    if (Test-McpServerRunning -Name $Name -Pattern $commandPattern) {
        Write-Log "Le serveur MCP '$Name' est déjà en cours d'exécution. Pas besoin de le démarrer à nouveau." -Level "SUCCESS"
        return $true
    }

    # Vérifier si la commande existe
    if (-not (Test-CommandExists -Command $Command)) {
        Write-Log "La commande '$Command' n'existe pas. Installation en cours..." -Level "WARNING"

        # Tenter d'installer la commande
        try {
            if ($Command -like "*mcp-server*") {
                npm install -g @modelcontextprotocol/server-filesystem @modelcontextprotocol/server-github
                Write-Log "Installation des serveurs MCP réussie" -Level "SUCCESS"
            } elseif ($Command -eq "npx") {
                Write-Log "npx est généralement inclus avec Node.js. Veuillez installer Node.js si ce n'est pas déjà fait." -Level "WARNING"
            } else {
                Write-Log "Installation automatique non prise en charge pour '$Command'. Veuillez l'installer manuellement." -Level "WARNING"
            }
        } catch {
            Write-Log "Échec de l'installation de '$Command': $_" -Level "ERROR"
            return $false
        }
    }

    # Préparer les variables d'environnement
    $env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"
    foreach ($key in $EnvironmentVariables.Keys) {
        Set-Item -Path "env:$key" -Value $EnvironmentVariables[$key]
    }

    # Construire la commande complète
    $commandLine = $Command
    if ($Arguments.Count -gt 0) {
        $commandLine += " " + ($Arguments -join " ")
    }

    # Démarrer le processus
    try {
        if ($NoWindow) {
            $process = Start-Process -FilePath $Command -ArgumentList $Arguments -NoNewWindow -PassThru
        } else {
            $process = Start-Process -FilePath $Command -ArgumentList $Arguments -PassThru
        }

        Write-Log "Serveur MCP '$Name' démarré avec PID: $($process.Id)" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Échec du démarrage du serveur MCP '$Name': $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour démarrer un serveur MCP avec un script
function Start-McpServerWithScript {
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

    # Extraire le nom du script pour la vérification
    $scriptName = Split-Path -Path $ScriptPath -Leaf

    # Vérifier si le serveur est déjà en cours d'exécution
    if (Test-McpServerRunning -Name $Name -Pattern $scriptName) {
        Write-Log "Le serveur MCP '$Name' est déjà en cours d'exécution. Pas besoin de le démarrer à nouveau." -Level "SUCCESS"
        return $true
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

Write-Log "DÉMARRAGE COMPLET DES SERVEURS MCP" -Level "TITLE"

# 0. Nettoyer les notifications des serveurs MCP
Write-Log "0. Nettoyage des notifications des serveurs MCP..." -Level "INFO"
& "$PSScriptRoot\clear-mcp-notifications.ps1"

# 1. Configurer VS Code pour les serveurs MCP
Write-Log "1. Configuration de VS Code pour les serveurs MCP..." -Level "INFO"
& "$PSScriptRoot\configure-vscode-mcp.ps1"

# 2. Configurer Claude Desktop pour les serveurs MCP
Write-Log "2. Configuration de Claude Desktop pour les serveurs MCP..." -Level "INFO"
& "$PSScriptRoot\configure-claude-desktop-mcp.ps1"

# 3. Démarrer les serveurs MCP principaux
Write-Log "3. Démarrage des serveurs MCP principaux..." -Level "INFO"

# 3.1. Démarrer le serveur MCP Filesystem
Write-Log "3.1. Démarrage du serveur MCP Filesystem..." -Level "INFO"
$filesystemSuccess = Start-McpServer -Name "Filesystem" -Command "npx" -Arguments @("@modelcontextprotocol/server-filesystem", $projectRoot)

# 3.2. Démarrer le serveur MCP GitHub
Write-Log "3.2. Démarrage du serveur MCP GitHub..." -Level "INFO"
$githubConfigPath = Join-Path -Path $projectRoot -ChildPath "mcp-servers\github\config.json"
if (-not (Test-Path $githubConfigPath)) {
    # Créer une configuration par défaut si elle n'existe pas
    $githubConfig = @{
        "port"  = 3001
        "token" = "Veuillez configurer votre token GitHub ici"
    } | ConvertTo-Json -Depth 10

    $githubConfigDir = Split-Path -Path $githubConfigPath -Parent
    if (-not (Test-Path $githubConfigDir)) {
        New-Item -Path $githubConfigDir -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $githubConfigPath -Value $githubConfig -Encoding UTF8
    Write-Log "Configuration GitHub créée à $githubConfigPath. Veuillez configurer votre token GitHub." -Level "WARNING"
}
$githubSuccess = Start-McpServer -Name "GitHub" -Command "npx" -Arguments @("@modelcontextprotocol/server-github", "--config", $githubConfigPath)

# 3.3. Démarrer le serveur MCP GCP
Write-Log "3.3. Démarrage du serveur MCP GCP..." -Level "INFO"
$gcpTokenPath = Join-Path -Path $projectRoot -ChildPath "mcp-servers\gcp\token.json"
if (Test-Path $gcpTokenPath) {
    $env:GOOGLE_APPLICATION_CREDENTIALS = $gcpTokenPath
    $gcpSuccess = Start-McpServer -Name "GCP" -Command "npx" -Arguments @("gcp-mcp")
} else {
    Write-Log "Le fichier token.json pour GCP n'existe pas à $gcpTokenPath. Le serveur MCP GCP ne sera pas démarré." -Level "WARNING"
    $gcpSuccess = $false
}

# 3.4. Démarrer le serveur MCP Supergateway
Write-Log "3.4. Démarrage du serveur MCP Supergateway..." -Level "INFO"
$gatewayConfigPath = Join-Path -Path $projectRoot -ChildPath "src\mcp\config\gateway.yaml"
if (Test-Path $gatewayConfigPath) {
    $gatewaySuccess = Start-McpServer -Name "Supergateway" -Command "npx" -Arguments @("supergateway", "start", "--config", $gatewayConfigPath, "mcp-stdio")
} else {
    Write-Log "Le fichier de configuration gateway.yaml n'existe pas à $gatewayConfigPath. Le serveur MCP Supergateway ne sera pas démarré." -Level "WARNING"
    $gatewaySuccess = $false
}

# 4. Démarrer les serveurs MCP supplémentaires
Write-Log "4. Démarrage des serveurs MCP supplémentaires..." -Level "INFO"

# 4.1. Démarrer le serveur MCP GDrive
Write-Log "4.1. Démarrage du serveur MCP GDrive..." -Level "INFO"
$gdriveMcpPath = Join-Path -Path $projectRoot -ChildPath "scripts\email\gdrive-mcp.cmd"
$gdriveSuccess = Start-McpServerWithScript -Name "GDrive" -ScriptPath $gdriveMcpPath

# 4.2. Démarrer le serveur MCP Augment Standard
Write-Log "4.2. Démarrage du serveur MCP Augment Standard..." -Level "INFO"
$augmentStandardPath = Join-Path -Path $projectRoot -ChildPath "scripts\workflow\augment-mcp-standard.cmd"
$augmentStandardSuccess = Start-McpServerWithScript -Name "Augment Standard" -ScriptPath $augmentStandardPath

# 4.3. Démarrer le serveur MCP Augment Gateway
Write-Log "4.3. Démarrage du serveur MCP Augment Gateway..." -Level "INFO"
$augmentGatewayPath = Join-Path -Path $projectRoot -ChildPath "scripts\mcp\augment-mcp-gateway.cmd"
$augmentGatewaySuccess = Start-McpServerWithScript -Name "Augment Gateway" -ScriptPath $augmentGatewayPath

# 4.4. Démarrer le serveur MCP Augment Notion
Write-Log "4.4. Démarrage du serveur MCP Augment Notion..." -Level "INFO"
$augmentNotionPath = Join-Path -Path $projectRoot -ChildPath "scripts\mcp\augment-mcp-notion.cmd"
$augmentNotionSuccess = Start-McpServerWithScript -Name "Augment Notion" -ScriptPath $augmentNotionPath

# 4.5. Démarrer le serveur MCP Augment Git Ingest
Write-Log "4.5. Démarrage du serveur MCP Augment Git Ingest..." -Level "INFO"
$augmentGitIngestPath = Join-Path -Path $projectRoot -ChildPath "scripts\mcp\augment-mcp-git-ingest.cmd"
$augmentGitIngestSuccess = Start-McpServerWithScript -Name "Augment Git Ingest" -ScriptPath $augmentGitIngestPath

# 4.6. Démarrer le serveur MCP Augment GitHub
Write-Log "4.6. Démarrage du serveur MCP Augment GitHub..." -Level "INFO"
$augmentGitHubPath = Join-Path -Path $projectRoot -ChildPath "scripts\utils\git\augment-mcp-github.cmd"
$augmentGitHubSuccess = Start-McpServerWithScript -Name "Augment GitHub" -ScriptPath $augmentGitHubPath

# 5. Résumer l'état du démarrage
Write-Log "5. Résumé du démarrage des serveurs MCP..." -Level "INFO"

# Créer un tableau récapitulatif des serveurs démarrés
$serverStatus = @(
    @{ Name = "MCP Filesystem"; Success = $filesystemSuccess },
    @{ Name = "MCP GitHub"; Success = $githubSuccess },
    @{ Name = "MCP GCP"; Success = $gcpSuccess },
    @{ Name = "MCP Supergateway"; Success = $gatewaySuccess },
    @{ Name = "MCP GDrive"; Success = $gdriveSuccess },
    @{ Name = "MCP Augment Standard"; Success = $augmentStandardSuccess },
    @{ Name = "MCP Augment Gateway"; Success = $augmentGatewaySuccess },
    @{ Name = "MCP Augment Notion"; Success = $augmentNotionSuccess },
    @{ Name = "MCP Augment Git Ingest"; Success = $augmentGitIngestSuccess },
    @{ Name = "MCP Augment GitHub"; Success = $augmentGitHubSuccess }
)

# Afficher le résumé
Write-Log "Résumé du démarrage des serveurs MCP :" -Level "TITLE"
foreach ($server in $serverStatus) {
    $statusText = if ($server.Success) { "DÉMARRÉ" } else { "NON DÉMARRÉ" }
    $statusColor = if ($server.Success) { "Green" } else { "Red" }

    # Formatage aligné
    $namePadded = $server.Name.PadRight(30)
    Write-Host "- $namePadded : " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor
}

# 6. Vérifier l'état des serveurs MCP
Write-Log "6. Vérification de l'état des serveurs MCP..." -Level "INFO"
Start-Sleep -Seconds 3 # Attendre que les serveurs démarrent
& "$PSScriptRoot\check-mcp-servers-v2-noadmin.ps1"
