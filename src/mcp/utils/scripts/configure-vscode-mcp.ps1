# Script pour configurer les serveurs MCP dans VS Code
# Ce script met à jour le fichier settings.json de VS Code pour configurer les serveurs MCP

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

# Chemin vers le fichier settings.json de VS Code
$workspaceSettingsPath = Join-Path -Path $projectRoot -ChildPath ".vscode\settings.json"
$userSettingsPath = "$env:APPDATA\Code\User\settings.json"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "      CONFIGURATION DES SERVEURS MCP DANS VS CODE        " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier si le fichier settings.json existe dans l'espace de travail
Write-Host "1. Vérification du fichier settings.json..." -ForegroundColor Cyan
if (Test-Path $workspaceSettingsPath) {
    Write-Log "Fichier settings.json trouvé dans l'espace de travail : $workspaceSettingsPath" -Level "SUCCESS"
    $settingsPath = $workspaceSettingsPath
} else {
    Write-Log "Fichier settings.json non trouvé dans l'espace de travail. Utilisation du fichier utilisateur : $userSettingsPath" -Level "WARNING"

    # Vérifier si le fichier settings.json existe pour l'utilisateur
    if (Test-Path $userSettingsPath) {
        Write-Log "Fichier settings.json trouvé pour l'utilisateur" -Level "SUCCESS"
        $settingsPath = $userSettingsPath
    } else {
        Write-Log "Fichier settings.json non trouvé pour l'utilisateur. Création d'un nouveau fichier..." -Level "WARNING"

        # Créer le répertoire .vscode s'il n'existe pas
        $vscodePath = Join-Path -Path $projectRoot -ChildPath ".vscode"
        if (-not (Test-Path $vscodePath)) {
            New-Item -Path $vscodePath -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire .vscode créé" -Level "SUCCESS"
        }

        # Créer un fichier settings.json vide
        $settings = @{}
        $settingsJson = $settings | ConvertTo-Json -Depth 10
        Set-Content -Path $workspaceSettingsPath -Value $settingsJson
        Write-Log "Fichier settings.json créé dans l'espace de travail" -Level "SUCCESS"
        $settingsPath = $workspaceSettingsPath
    }
}

# 2. Charger le fichier settings.json
Write-Host "2. Chargement du fichier settings.json..." -ForegroundColor Cyan
try {
    $settingsContent = Get-Content -Path $settingsPath -Raw
    $settings = $settingsContent | ConvertFrom-Json
    Write-Log "Fichier settings.json chargé avec succès" -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors du chargement du fichier settings.json : $_" -Level "ERROR"
    Write-Log "Création d'un nouveau fichier settings.json..." -Level "WARNING"
    $settings = [PSCustomObject]@{}
}

# 3. Configurer les serveurs MCP
Write-Host "3. Configuration des serveurs MCP..." -ForegroundColor Cyan

# Désactiver les notifications d'erreur pour les serveurs MCP
if (-not (Get-Member -InputObject $settings -Name "notifications.excludeWarnings" -MemberType Properties)) {
    $settings | Add-Member -NotePropertyName "notifications.excludeWarnings" -NotePropertyValue @("*MCP server*", "*modelcontextprotocol*", "*supergateway*") -Force
    Write-Log "Notifications d'erreur pour les serveurs MCP désactivées" -Level "SUCCESS"
} else {
    # Ajouter les patterns aux exclusions existantes
    $excludeWarnings = $settings."notifications.excludeWarnings"
    if ($excludeWarnings -isnot [array]) {
        $excludeWarnings = @($excludeWarnings)
    }

    $newExclusions = @("*MCP server*", "*modelcontextprotocol*", "*supergateway*")
    foreach ($exclusion in $newExclusions) {
        if ($excludeWarnings -notcontains $exclusion) {
            $excludeWarnings += $exclusion
        }
    }

    $settings."notifications.excludeWarnings" = $excludeWarnings
    Write-Log "Notifications d'erreur pour les serveurs MCP mises à jour" -Level "SUCCESS"
}

# Créer la propriété mcpServers si elle n'existe pas
if (-not (Get-Member -InputObject $settings -Name "mcpServers" -MemberType Properties)) {
    $settings | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([PSCustomObject]@{})
    Write-Log "Propriété mcpServers ajoutée" -Level "SUCCESS"
}

# Configurer le serveur MCP Filesystem
$filesystemPath = $projectRoot -replace '\\', '\\'
$settings.mcpServers | Add-Member -NotePropertyName "filesystem" -NotePropertyValue ([PSCustomObject]@{
        command = "npx"
        args    = @("-y", "@modelcontextprotocol/server-filesystem", $filesystemPath)
    }) -Force
Write-Log "Serveur MCP Filesystem configuré" -Level "SUCCESS"

# Configurer le serveur MCP GitHub
$githubConfigPath = Join-Path -Path $projectRoot -ChildPath "mcp-servers\github\config.json"
if (Test-Path $githubConfigPath) {
    $settings.mcpServers | Add-Member -NotePropertyName "github" -NotePropertyValue ([PSCustomObject]@{
            command = "npx"
            args    = @("-y", "@modelcontextprotocol/server-github", "--config", ($githubConfigPath -replace '\\', '\\'))
        }) -Force
    Write-Log "Serveur MCP GitHub configuré" -Level "SUCCESS"
} else {
    Write-Log "Fichier de configuration GitHub non trouvé. Le serveur MCP GitHub ne sera pas configuré." -Level "WARNING"
}

# Configurer le serveur MCP GCP
$gcpTokenPath = Join-Path -Path $projectRoot -ChildPath "mcp-servers\gcp\token.json"
if (Test-Path $gcpTokenPath) {
    $settings.mcpServers | Add-Member -NotePropertyName "gcp" -NotePropertyValue ([PSCustomObject]@{
            command = "npx"
            args    = @("-y", "gcp-mcp")
            env     = @{
                GOOGLE_APPLICATION_CREDENTIALS = ($gcpTokenPath -replace '\\', '\\')
            }
        }) -Force
    Write-Log "Serveur MCP GCP configuré" -Level "SUCCESS"
} else {
    Write-Log "Fichier token.json pour GCP non trouvé. Le serveur MCP GCP ne sera pas configuré." -Level "WARNING"
}

# Configurer le serveur MCP Supergateway
$gatewayConfigPath = Join-Path -Path $projectRoot -ChildPath "src\mcp\config\gateway.yaml"
if (Test-Path $gatewayConfigPath) {
    $settings.mcpServers | Add-Member -NotePropertyName "supergateway" -NotePropertyValue ([PSCustomObject]@{
            command = "npx"
            args    = @("-y", "supergateway", "start", "--config", ($gatewayConfigPath -replace '\\', '\\'), "mcp-stdio")
        }) -Force
    Write-Log "Serveur MCP Supergateway configuré" -Level "SUCCESS"
} else {
    Write-Log "Fichier de configuration gateway.yaml non trouvé. Le serveur MCP Supergateway ne sera pas configuré." -Level "WARNING"
}

# 4. Sauvegarder les modifications
Write-Host "4. Sauvegarde des modifications..." -ForegroundColor Cyan
try {
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $settingsJson
    Write-Log "Fichier settings.json mis à jour avec succès" -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de la sauvegarde du fichier settings.json : $_" -Level "ERROR"
}

# Résumé
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                  RÉSUMÉ DE LA CONFIGURATION             " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Les serveurs MCP ont été configurés dans VS Code."
Write-Host "Fichier settings.json mis à jour : $settingsPath"
Write-Host ""
Write-Host "Pour appliquer les changements, redémarrez VS Code."
Write-Host ""
Write-Host "Si vous utilisez Claude Desktop, vous pouvez copier la configuration suivante :"
Write-Host ""
Write-Host '```json' -ForegroundColor Yellow
Write-Host '{' -ForegroundColor Yellow
Write-Host '  "mcpServers": {' -ForegroundColor Yellow
Write-Host '    "filesystem": {' -ForegroundColor Yellow
Write-Host '      "command": "npx",' -ForegroundColor Yellow
Write-Host '      "args": [' -ForegroundColor Yellow
Write-Host '        "-y",' -ForegroundColor Yellow
Write-Host '        "@modelcontextprotocol/server-filesystem",' -ForegroundColor Yellow
Write-Host "        `"$filesystemPath`"" -ForegroundColor Yellow
Write-Host '      ]' -ForegroundColor Yellow
Write-Host '    }' -ForegroundColor Yellow
Write-Host '  }' -ForegroundColor Yellow
Write-Host '}' -ForegroundColor Yellow
Write-Host '```' -ForegroundColor Yellow
Write-Host ""
