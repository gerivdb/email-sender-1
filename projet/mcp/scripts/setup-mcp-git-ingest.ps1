#Requires -Version 5.1
<#
.SYNOPSIS
    Configure et installe le serveur MCP Git Ingest.
.DESCRIPTION
    Ce script installe et configure le serveur MCP Git Ingest qui permet d'explorer
    et de lire les structures de dépôts GitHub et les fichiers importants.
.PARAMETER Force
    Force la réinstallation même si le package est déjà installé.
.EXAMPLE
    .\setup-mcp-git-ingest.ps1
    Installe et configure le serveur MCP Git Ingest.
.EXAMPLE
    .\setup-mcp-git-ingest.ps1 -Force
    Force la réinstallation du serveur MCP Git Ingest.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
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
    Write-Log "Démarrage du script d'installation et de configuration du serveur MCP Git Ingest..." -Level "INFO"

    # Chemin du répertoire racine du projet
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    Write-Log "Répertoire racine du projet: $projectRoot" -Level "INFO"

    # Chemin du répertoire des serveurs MCP
    $mcpServersDir = Join-Path -Path $projectRoot -ChildPath "projet\mcp\servers\git-ingest"

    # Créer le répertoire des serveurs MCP s'il n'existe pas
    if (-not (Test-Path $mcpServersDir)) {
        New-Item -ItemType Directory -Path $mcpServersDir -Force | Out-Null
        Write-Log "Répertoire des serveurs MCP créé: $mcpServersDir" -Level "SUCCESS"
    }

    # Créer les sous-répertoires
    $outputDir = Join-Path -Path $mcpServersDir -ChildPath "output"
    $reposDir = Join-Path -Path $mcpServersDir -ChildPath "repos"

    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        Write-Log "Répertoire de sortie créé: $outputDir" -Level "SUCCESS"
    }

    if (-not (Test-Path $reposDir)) {
        New-Item -ItemType Directory -Path $reposDir -Force | Out-Null
        Write-Log "Répertoire des dépôts créé: $reposDir" -Level "SUCCESS"
    }

    # Vérifier si Python est installé
    try {
        $pythonVersion = python --version 2>&1
        Write-Log "Python détecté: $pythonVersion" -Level "SUCCESS"
    } catch {
        Write-Log "Python n'est pas installé ou n'est pas accessible via la ligne de commande." -Level "ERROR"
        Write-Log "Veuillez installer Python 3.8 ou ultérieur: https://www.python.org/downloads/" -Level "INFO"
        exit 1
    }

    # Vérifier si pip est installé
    try {
        $pipVersion = python -m pip --version 2>&1
        Write-Log "pip détecté: $pipVersion" -Level "SUCCESS"
    } catch {
        Write-Log "pip n'est pas installé ou n'est pas accessible via la ligne de commande." -Level "ERROR"
        Write-Log "Veuillez installer pip: https://pip.pypa.io/en/stable/installation/" -Level "INFO"
        exit 1
    }

    # Installer ou mettre à jour mcp-git-ingest
    if ($Force) {
        Write-Log "Installation forcée de mcp-git-ingest..." -Level "INFO"
        python -m pip install --upgrade git+https://github.com/adhikasp/mcp-git-ingest
    } else {
        # Vérifier si mcp-git-ingest est déjà installé
        $mcpGitIngestInstalled = python -m pip list | Select-String -Pattern "mcp-git-ingest"

        if ($mcpGitIngestInstalled) {
            Write-Log "mcp-git-ingest est déjà installé: $mcpGitIngestInstalled" -Level "SUCCESS"
            Write-Log "Utilisez -Force pour forcer la réinstallation." -Level "INFO"
        } else {
            Write-Log "Installation de mcp-git-ingest..." -Level "INFO"
            python -m pip install git+https://github.com/adhikasp/mcp-git-ingest
        }
    }

    # Vérifier si l'installation a réussi
    $mcpGitIngestInstalled = python -m pip list | Select-String -Pattern "mcp-git-ingest"

    if ($mcpGitIngestInstalled) {
        Write-Log "mcp-git-ingest installé avec succès: $mcpGitIngestInstalled" -Level "SUCCESS"
    } else {
        Write-Log "Échec de l'installation de mcp-git-ingest." -Level "ERROR"
        exit 1
    }

    # Créer le fichier de configuration
    $configPath = Join-Path -Path $projectRoot -ChildPath "projet\mcp\config\servers\git-ingest.json"

    $config = @{
        port            = 8001
        outputDir       = $outputDir.Replace("\", "/")
        cloneDir        = $reposDir.Replace("\", "/")
        maxFiles        = 100
        excludePatterns = @(
            "node_modules/**",
            ".git/**",
            "**/*.min.js",
            "**/*.bundle.js",
            "**/*.map",
            "**/dist/**",
            "**/build/**"
        )
        includePatterns = @(
            "**/*.md",
            "**/*.py",
            "**/*.js",
            "**/*.ts",
            "**/*.json",
            "**/*.yaml",
            "**/*.yml"
        )
        cacheEnabled    = $true
        cacheTTL        = 3600
    }

    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8
    Write-Log "Fichier de configuration créé: $configPath" -Level "SUCCESS"

    # Mettre à jour le fichier de configuration MCP principal
    $mcpConfigPath = Join-Path -Path $projectRoot -ChildPath "projet\mcp\config\mcp-config.json"

    if (Test-Path $mcpConfigPath) {
        Write-Log "Mise à jour du fichier de configuration MCP principal..." -Level "INFO"

        # Lire le fichier de configuration
        $mcpConfig = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json

        # Vérifier si le serveur existe déjà
        if ($mcpConfig.mcpServers.PSObject.Properties.Name -contains "git-ingest") {
            Write-Log "Le serveur git-ingest existe déjà dans la configuration MCP. Mise à jour..." -Level "WARNING"
        }

        # Créer la configuration du serveur
        $serverConfig = @{
            command    = "python"
            args       = @("-m", "mcp_git_ingest.main")
            env        = @{
                N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"
            }
            enabled    = $true
            configPath = "config/servers/git-ingest.json"
        }

        # Ajouter ou mettre à jour le serveur dans la configuration
        $mcpConfig.mcpServers | Add-Member -MemberType NoteProperty -Name "git-ingest" -Value $serverConfig -Force

        # Sauvegarder la configuration
        $mcpConfig | ConvertTo-Json -Depth 10 | Out-File $mcpConfigPath -Encoding utf8

        Write-Log "Fichier de configuration MCP principal mis à jour." -Level "SUCCESS"
    } else {
        Write-Log "Le fichier de configuration MCP principal n'existe pas: $mcpConfigPath" -Level "WARNING"
    }

    Write-Log "Installation et configuration du serveur MCP Git Ingest terminées." -Level "SUCCESS"
    Write-Log "Vous pouvez maintenant démarrer le serveur avec la commande: .\start-git-ingest-mcp.cmd" -Level "INFO"
} catch {
    Write-Log "Erreur lors de l'installation et de la configuration du serveur MCP Git Ingest: $_" -Level "ERROR"
    exit 1
}
