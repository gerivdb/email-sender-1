# Script pour configurer les serveurs MCP pour Claude Desktop
# Ce script crée un fichier de configuration pour Claude Desktop

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

# Chemin du répertoire racine du projet
$projectRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\"
$projectRoot = (Resolve-Path $projectRoot).Path

# Chemin vers le fichier de configuration Claude Desktop
$claudeConfigPath = Join-Path -Path $projectRoot -ChildPath "docs\guides\CLAUDE_DESKTOP_CONFIG.json"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "    CONFIGURATION DES SERVEURS MCP POUR CLAUDE DESKTOP   " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Créer la configuration pour Claude Desktop
Write-Host "1. Création de la configuration pour Claude Desktop..." -ForegroundColor Cyan

# Créer l'objet de configuration
$claudeConfig = @{
    mcpServers = @{
        filesystem = @{
            command = "npx"
            args    = @(
                "-y",
                "@modelcontextprotocol/server-filesystem",
                $projectRoot
            )
        }
    }
}

# Ajouter le serveur MCP GitHub si la configuration existe
$githubConfigPath = Join-Path -Path $projectRoot -ChildPath "mcp-servers\github\config.json"
if (Test-Path $githubConfigPath) {
    $claudeConfig.mcpServers.github = @{
        command = "npx"
        args    = @(
            "-y",
            "@modelcontextprotocol/server-github",
            "--config",
            $githubConfigPath
        )
    }
    Write-Log "Serveur MCP GitHub ajouté à la configuration" -Level "SUCCESS"
} else {
    Write-Log "Fichier de configuration GitHub non trouvé. Le serveur MCP GitHub ne sera pas configuré." -Level "WARNING"
}

# Ajouter le serveur MCP GCP si le token existe
$gcpTokenPath = Join-Path -Path $projectRoot -ChildPath "mcp-servers\gcp\token.json"
if (Test-Path $gcpTokenPath) {
    $claudeConfig.mcpServers.gcp = @{
        command = "npx"
        args    = @(
            "-y",
            "gcp-mcp"
        )
        env     = @{
            GOOGLE_APPLICATION_CREDENTIALS = $gcpTokenPath
        }
    }
    Write-Log "Serveur MCP GCP ajouté à la configuration" -Level "SUCCESS"
} else {
    Write-Log "Fichier token.json pour GCP non trouvé. Le serveur MCP GCP ne sera pas configuré." -Level "WARNING"
}

# 2. Sauvegarder la configuration
Write-Host "2. Sauvegarde de la configuration..." -ForegroundColor Cyan
try {
    # Créer le répertoire parent si nécessaire
    $claudeConfigDir = Split-Path -Path $claudeConfigPath -Parent
    if (-not (Test-Path $claudeConfigDir)) {
        New-Item -Path $claudeConfigDir -ItemType Directory -Force | Out-Null
        Write-Log "Répertoire docs\guides créé" -Level "SUCCESS"
    }

    # Sauvegarder la configuration
    $claudeConfigJson = $claudeConfig | ConvertTo-Json -Depth 10
    Set-Content -Path $claudeConfigPath -Value $claudeConfigJson
    Write-Log "Configuration Claude Desktop sauvegardée avec succès : $claudeConfigPath" -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de la sauvegarde de la configuration Claude Desktop : $_" -Level "ERROR"
}

# Résumé
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                  RÉSUMÉ DE LA CONFIGURATION             " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "La configuration pour Claude Desktop a été créée :"
Write-Host "Fichier : $claudeConfigPath"
Write-Host ""
Write-Host "Pour utiliser cette configuration avec Claude Desktop :"
Write-Host "1. Ouvrez Claude Desktop"
Write-Host "2. Cliquez sur l'icône de paramètres (⚙️)"
Write-Host "3. Sélectionnez 'MCP Configuration'"
Write-Host "4. Cliquez sur 'Load from file'"
Write-Host "5. Sélectionnez le fichier : $claudeConfigPath"
Write-Host "6. Cliquez sur 'Save'"
Write-Host ""
Write-Host "Vous pouvez également copier-coller le contenu suivant :"
Write-Host ""
Write-Host '```json' -ForegroundColor Yellow
Write-Host $claudeConfigJson -ForegroundColor Yellow
Write-Host '```' -ForegroundColor Yellow
Write-Host ""
