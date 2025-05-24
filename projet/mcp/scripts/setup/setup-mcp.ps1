#Requires -Version 5.1
<#
.SYNOPSIS
    Configure et installe les serveurs MCP.
.DESCRIPTION
    Ce script configure et installe tous les composants nécessaires pour les serveurs MCP.
    Il crée la structure de dossiers, installe les dépendances et configure les serveurs.
.PARAMETER Environment
    Environnement à configurer (development, production). Par défaut: development.
.PARAMETER Force
    Force l'installation sans demander de confirmation.
.EXAMPLE
    .\setup-mcp.ps1 -Environment production
    Configure les serveurs MCP pour l'environnement de production.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("development", "production")]
    [string]$Environment = "development",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $scriptsRoot).Parent.FullName
$projectRoot = (Get-Item $mcpRoot).Parent.FullName

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

function New-Directory {
    param (
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Log "Répertoire créé: $Path" -Level "SUCCESS"
    } else {
        Write-Log "Répertoire existant: $Path" -Level "INFO"
    }
}

# Corps principal du script
try {
    Write-Log "Configuration des serveurs MCP..." -Level "TITLE"

    # Demander confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous configurer les serveurs MCP pour l'environnement $Environment ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Configuration annulée par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }

    # Étape 1: Créer la structure de dossiers
    Write-Log "Création de la structure de dossiers..." -Level "INFO"

    $directories = @(
        "core/client",
        "core/server",
        "core/common",
        "servers/filesystem",
        "servers/github",
        "servers/gcp",
        "servers/notion",
        "servers/gateway",
        "scripts/setup",
        "scripts/maintenance",
        "scripts/utils",
        "modules/MCPManager",
        "python/pymcpfy",
        "tests/unit",
        "tests/integration",
        "tests/performance",
        "config/templates",
        "config/environments",
        "config/servers",
        "docs/guides",
        "docs/api",
        "docs/servers",
        "docs/development",
        "integrations/n8n/credentials",
        "integrations/n8n/workflows",
        "integrations/n8n/scripts",
        "monitoring/scripts",
        "monitoring/dashboards",
        "monitoring/alerts",
        "monitoring/logs",
        "versioning/scripts",
        "versioning/backups",
        "versioning/changelog",
        "dependencies/npm",
        "dependencies/pip",
        "dependencies/binary/gateway"
    )

    foreach ($dir in $directories) {
        $path = Join-Path -Path $mcpRoot -ChildPath $dir
        New-Directory -Path $path
    }

    # Étape 2: Installer les dépendances
    Write-Log "Installation des dépendances..." -Level "INFO"

    $installDependenciesScript = Join-Path -Path $mcpRoot -ChildPath "dependencies\scripts\install-dependencies.ps1"

    if (Test-Path $installDependenciesScript) {
        if ($PSCmdlet.ShouldProcess("Dependencies", "Install")) {
            & $installDependenciesScript
        }
    } else {
        Write-Log "Script d'installation des dépendances non trouvé: $installDependenciesScript" -Level "ERROR"
    }

    # Étape 3: Configurer les serveurs
    Write-Log "Configuration des serveurs..." -Level "INFO"

    # Copier les fichiers de configuration
    $configSourceDir = Join-Path -Path $mcpRoot -ChildPath "config\templates"
    $configTargetDir = Join-Path -Path $mcpRoot -ChildPath "config"

    # Copier le fichier de configuration principal
    $configTemplatePath = Join-Path -Path $configSourceDir -ChildPath "mcp-config-template.json"
    $configPath = Join-Path -Path $configTargetDir -ChildPath "mcp-config.json"

    if (Test-Path $configTemplatePath) {
        if ($PSCmdlet.ShouldProcess($configTemplatePath, "Copy to $configPath")) {
            # Lire le contenu du modèle
            $configTemplate = Get-Content -Path $configTemplatePath -Raw

            # Remplacer les variables
            $projectRootForwardSlash = $projectRoot -replace '\\', '/'
            $configContent = $configTemplate -replace '{{PROJECT_ROOT_FORWARD_SLASH}}', $projectRootForwardSlash

            # Écrire le fichier de configuration
            Set-Content -Path $configPath -Value $configContent
            Write-Log "Fichier de configuration créé: $configPath" -Level "SUCCESS"
        }
    } else {
        Write-Log "Modèle de configuration non trouvé: $configTemplatePath" -Level "WARNING"
    }

    # Copier la configuration de l'environnement
    $envConfigPath = Join-Path -Path $mcpRoot -ChildPath "config\environments\$Environment.json"

    if (Test-Path $envConfigPath) {
        if ($PSCmdlet.ShouldProcess($envConfigPath, "Apply environment configuration")) {
            # Lire la configuration principale
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

            # Lire la configuration de l'environnement
            $envConfig = Get-Content -Path $envConfigPath -Raw | ConvertFrom-Json

            # Fusionner les configurations
            foreach ($serverName in $envConfig.mcpServers.PSObject.Properties.Name) {
                $serverConfig = $envConfig.mcpServers.$serverName

                if ($config.mcpServers.PSObject.Properties.Name -contains $serverName) {
                    # Mettre à jour les propriétés existantes
                    foreach ($propName in $serverConfig.PSObject.Properties.Name) {
                        $config.mcpServers.$serverName.$propName = $serverConfig.$propName
                    }
                }
            }

            # Mettre à jour les propriétés globales
            foreach ($propName in $envConfig.global.PSObject.Properties.Name) {
                $config.global.$propName = $envConfig.global.$propName
            }

            # Enregistrer la configuration mise à jour
            $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
            Write-Log "Configuration de l'environnement $Environment appliquée." -Level "SUCCESS"
        }
    } else {
        Write-Log "Configuration de l'environnement non trouvée: $envConfigPath" -Level "WARNING"
    }

    # Étape 4: Importer le module MCPManager
    Write-Log "Importation du module MCPManager..." -Level "INFO"

    $modulePath = Join-Path -Path $mcpRoot -ChildPath "modules\MCPManager"

    if (Test-Path $modulePath) {
        if ($PSCmdlet.ShouldProcess("MCPManager", "Import module")) {
            # Importer le module
            Import-Module $modulePath -Force
            Write-Log "Module MCPManager importé avec succès." -Level "SUCCESS"
        }
    } else {
        Write-Log "Module MCPManager non trouvé: $modulePath" -Level "WARNING"
    }

    Write-Log "Configuration des serveurs MCP terminée." -Level "SUCCESS"
    Write-Log "Pour démarrer les serveurs MCP, exécutez: Start-MCPServer" -Level "INFO"
} catch {
    Write-Log "Erreur lors de la configuration des serveurs MCP: $_" -Level "ERROR"
    exit 1
}

