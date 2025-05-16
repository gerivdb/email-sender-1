<#
.SYNOPSIS
    Installe le module AugmentIntegration pour l'intégration avec n8n.

.DESCRIPTION
    Ce script vérifie si le module AugmentIntegration est installé et l'installe si nécessaire.
    Il configure également les paramètres nécessaires pour l'intégration avec n8n.

.PARAMETER Force
    Force la réinstallation du module même s'il est déjà installé.

.EXAMPLE
    .\install-augment-integration.ps1
    .\install-augment-integration.ps1 -Force
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$Force
)

# Définir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))
$developmentScriptsPath = Join-Path -Path $projectRoot -ChildPath "development\scripts"
$maintenanceScriptsPath = Join-Path -Path $developmentScriptsPath -ChildPath "maintenance\augment"
$installScriptPath = Join-Path -Path $maintenanceScriptsPath -ChildPath "Install-AugmentIntegration.ps1"

# Vérifier si le module est déjà installé
$moduleInstalled = $false
try {
    $moduleInstalled = Get-Module -Name AugmentIntegration -ListAvailable
} catch {
    Write-Verbose "Le module AugmentIntegration n'est pas installé."
}

# Installer le module si nécessaire
if (-not $moduleInstalled -or $Force) {
    Write-Host "Installation du module AugmentIntegration..." -ForegroundColor Cyan
    
    # Vérifier si le script d'installation existe
    if (Test-Path -Path $installScriptPath) {
        try {
            # Exécuter le script d'installation
            & $installScriptPath -Force:$Force
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Le module AugmentIntegration a été installé avec succès." -ForegroundColor Green
            } else {
                Write-Error "Erreur lors de l'installation du module AugmentIntegration. Code de sortie : $LASTEXITCODE"
                exit 1
            }
        } catch {
            Write-Error "Erreur lors de l'exécution du script d'installation : $_"
            exit 1
        }
    } else {
        Write-Error "Le script d'installation n'existe pas : $installScriptPath"
        exit 1
    }
} else {
    Write-Host "Le module AugmentIntegration est déjà installé." -ForegroundColor Green
}

# Configurer l'intégration avec n8n
Write-Host "Configuration de l'intégration avec n8n..." -ForegroundColor Cyan

# Vérifier si le module est chargé
if (-not (Get-Module -Name AugmentIntegration)) {
    try {
        Import-Module AugmentIntegration
    } catch {
        Write-Error "Impossible de charger le module AugmentIntegration : $_"
        exit 1
    }
}

# Vérifier si la fonction Initialize-AugmentIntegration existe
if (Get-Command -Name Initialize-AugmentIntegration -ErrorAction SilentlyContinue) {
    try {
        # Initialiser l'intégration avec Augment Code
        Initialize-AugmentIntegration -StartServers
        
        Write-Host "L'intégration avec n8n a été configurée avec succès." -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'initialisation de l'intégration : $_"
        exit 1
    }
} else {
    Write-Error "La fonction Initialize-AugmentIntegration n'existe pas dans le module AugmentIntegration."
    exit 1
}

# Vérifier si les serveurs MCP sont en cours d'exécution
Write-Host "Vérification des serveurs MCP..." -ForegroundColor Cyan

$mcpServersRunning = $false
try {
    # Exécuter le script de vérification des serveurs MCP
    $checkScriptPath = Join-Path -Path $projectRoot -ChildPath "src\mcp\utils\scripts\check-mcp-servers.ps1"
    if (Test-Path -Path $checkScriptPath) {
        $result = & $checkScriptPath
        $mcpServersRunning = $result -match "En cours d'exécution"
    }
} catch {
    Write-Warning "Impossible de vérifier l'état des serveurs MCP : $_"
}

if ($mcpServersRunning) {
    Write-Host "Les serveurs MCP sont en cours d'exécution." -ForegroundColor Green
} else {
    Write-Warning "Certains serveurs MCP ne sont pas en cours d'exécution. Exécutez le script start-all-mcp-servers.cmd pour les démarrer."
}

Write-Host "Installation et configuration terminées." -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le node Augment Client dans n8n." -ForegroundColor Green
