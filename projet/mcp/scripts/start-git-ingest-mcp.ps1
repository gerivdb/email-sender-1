#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre le serveur MCP Git Ingest.
.DESCRIPTION
    Ce script permet de démarrer le serveur MCP Git Ingest qui permet d'explorer
    et de lire les structures de dépôts GitHub et les fichiers importants.
.PARAMETER Http
    Démarre le serveur en mode HTTP au lieu de STDIO.
.PARAMETER Port
    Spécifie le port à utiliser pour le mode HTTP. Par défaut: 8001.
.EXAMPLE
    .\start-git-ingest-mcp.ps1
    Démarre le serveur MCP Git Ingest en mode STDIO.
.EXAMPLE
    .\start-git-ingest-mcp.ps1 -Http -Port 8002
    Démarre le serveur MCP Git Ingest en mode HTTP sur le port 8002.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Http,

    [Parameter(Mandatory = $false)]
    [int]$Port = 8001
)

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

try {
    # Chemin du répertoire racine du projet
    $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\"
    $projectRoot = (Resolve-Path $projectRoot).Path

    # Chemin du fichier de configuration
    $configPath = Join-Path -Path $projectRoot -ChildPath "projet\mcp\config\servers\git-ingest.json"

    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path $configPath)) {
        Write-Log "Le fichier de configuration $configPath n'existe pas." -Level "ERROR"
        Write-Log "Veuillez exécuter setup-mcp-git-ingest.ps1 pour installer et configurer le serveur." -Level "INFO"
        exit 1
    }

    # Vérifier si mcp-git-ingest est installé
    $mcpGitIngestInstalled = python -m pip list | Select-String -Pattern "mcp-git-ingest"

    if (-not $mcpGitIngestInstalled) {
        Write-Log "mcp-git-ingest n'est pas installé." -Level "ERROR"
        Write-Log "Veuillez exécuter setup-mcp-git-ingest.ps1 pour installer et configurer le serveur." -Level "INFO"
        exit 1
    }

    # Définir la variable d'environnement pour n8n
    $env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"

    # Démarrer le serveur MCP Git Ingest
    if ($Http) {
        Write-Log "Démarrage du serveur MCP Git Ingest en mode HTTP sur le port $Port..." -Level "INFO"

        # Créer les répertoires de sortie et de clonage s'ils n'existent pas
        $config = Get-Content $configPath -Raw | ConvertFrom-Json

        if (-not (Test-Path $config.outputDir)) {
            New-Item -ItemType Directory -Path $config.outputDir -Force | Out-Null
            Write-Log "Répertoire de sortie créé: $($config.outputDir)" -Level "INFO"
        }

        if (-not (Test-Path $config.cloneDir)) {
            New-Item -ItemType Directory -Path $config.cloneDir -Force | Out-Null
            Write-Log "Répertoire de clonage créé: $($config.cloneDir)" -Level "INFO"
        }

        # Démarrer le serveur en mode HTTP
        python -m mcp_git_ingest.main --port $Port
    } else {
        Write-Log "Démarrage du serveur MCP Git Ingest en mode STDIO..." -Level "INFO"

        # Démarrer le serveur en mode STDIO
        python -m mcp_git_ingest.main --stdio
    }

    Write-Log "Serveur MCP Git Ingest arrêté." -Level "INFO"
} catch {
    Write-Log "Erreur lors du démarrage du serveur MCP Git Ingest: $_" -Level "ERROR"
    exit 1
}
