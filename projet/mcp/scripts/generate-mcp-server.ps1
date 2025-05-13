#Requires -Version 5.1
<#
.SYNOPSIS
    Génère un nouveau serveur MCP avec Hygen.
.DESCRIPTION
    Ce script permet de générer un nouveau serveur MCP avec Hygen en utilisant
    les templates définis dans le répertoire _templates/mcp-server.
.PARAMETER Name
    Nom du serveur MCP (sans le préfixe 'mcp-').
.PARAMETER Description
    Description du serveur MCP.
.PARAMETER Command
    Commande pour démarrer le serveur (ex: npx).
.PARAMETER Args
    Arguments de la commande (séparés par des virgules).
.PARAMETER EnvVars
    Variables d'environnement (format: NOM=VALEUR, séparées par des virgules).
.PARAMETER Port
    Port par défaut pour le serveur.
.PARAMETER NoConfig
    Ne pas créer de fichier de configuration pour ce serveur.
.PARAMETER NoDocs
    Ne pas créer de documentation pour ce serveur.
.EXAMPLE
    .\generate-mcp-server.ps1 -Name "git-ingest" -Description "permet d'explorer et de lire les structures de dépôts GitHub et les fichiers importants" -Command "npx" -Args "-y,--package=git+https://github.com/adhikasp/mcp-git-ingest,mcp-git-ingest" -EnvVars "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true" -Port 8001
    Génère un nouveau serveur MCP Git Ingest.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [string]$Command,

    [Parameter(Mandatory = $true)]
    [string]$Args,

    [Parameter(Mandatory = $false)]
    [string]$EnvVars = "",

    [Parameter(Mandatory = $false)]
    [string]$Port = "",

    [Parameter(Mandatory = $false)]
    [switch]$NoConfig,

    [Parameter(Mandatory = $false)]
    [switch]$NoDocs
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
    # Vérifier si Hygen est installé
    $hygenInstalled = $null
    try {
        $hygenInstalled = Get-Command npx hygen -ErrorAction SilentlyContinue
    } catch {
        $hygenInstalled = $null
    }

    if (-not $hygenInstalled) {
        Write-Log "Hygen n'est pas installé. Installation en cours..." -Level "WARNING"
        npm install -g hygen

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'installation de Hygen. Veuillez l'installer manuellement avec 'npm install -g hygen'." -Level "ERROR"
            exit 1
        }

        Write-Log "Hygen installé avec succès." -Level "SUCCESS"
    }

    # Chemin du répertoire racine du projet
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

    # Chemin du répertoire des templates
    $templatesDir = Join-Path -Path $projectRoot -ChildPath "development\templates\hygen"

    # Vérifier si le répertoire des templates existe
    if (-not (Test-Path $templatesDir)) {
        Write-Log "Le répertoire des templates $templatesDir n'existe pas." -Level "ERROR"
        exit 1
    }

    # Créer le répertoire du serveur s'il n'existe pas
    $serverDir = Join-Path -Path $projectRoot -ChildPath "projet\mcp\servers\$Name"
    if (-not (Test-Path $serverDir)) {
        New-Item -ItemType Directory -Path $serverDir -Force | Out-Null
        Write-Log "Répertoire du serveur créé: $serverDir" -Level "SUCCESS"
    }

    # Générer le serveur MCP avec Hygen
    Write-Log "Génération du serveur MCP $Name..." -Level "INFO"

    # Préparer les arguments pour Hygen
    $hygenArgs = @(
        "mcp-server",
        "new",
        "--name", $Name,
        "--description", $Description,
        "--command", $Command,
        "--args", $Args
    )

    if ($EnvVars) {
        $hygenArgs += @("--needsEnv", "true", "--envVars", $EnvVars)
    }

    if ($Port) {
        $hygenArgs += @("--port", $Port)
    }

    if ($NoConfig) {
        $hygenArgs += @("--createConfig", "false")
    } else {
        $hygenArgs += @("--createConfig", "true")
    }

    if ($NoDocs) {
        $hygenArgs += @("--createDocs", "false")
    } else {
        $hygenArgs += @("--createDocs", "true")
    }

    # Exécuter Hygen
    $currentDir = Get-Location
    Set-Location $projectRoot

    try {
        npx hygen $hygenArgs

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de la génération du serveur MCP $Name." -Level "ERROR"
            exit 1
        }

        Write-Log "Serveur MCP $Name généré avec succès." -Level "SUCCESS"
    } finally {
        Set-Location $currentDir
    }

    # Mettre à jour le fichier de configuration MCP principal
    $mcpConfigPath = Join-Path -Path $projectRoot -ChildPath "projet\mcp\config\mcp-config.json"

    if (Test-Path $mcpConfigPath) {
        Write-Log "Mise à jour du fichier de configuration MCP principal..." -Level "INFO"

        # Lire le fichier de configuration
        $mcpConfig = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json

        # Vérifier si le serveur existe déjà
        if ($mcpConfig.mcpServers.PSObject.Properties.Name -contains $Name) {
            Write-Log "Le serveur $Name existe déjà dans la configuration MCP. Mise à jour..." -Level "WARNING"
        }

        # Créer la configuration du serveur
        $serverConfig = @{
            command = $Command
            args    = $Args.Split(',') | ForEach-Object { $_.Trim() }
            enabled = $true
        }

        if (-not $NoConfig) {
            $serverConfig.configPath = "config/servers/$Name.json"
        }

        if ($EnvVars) {
            $envVarsObj = @{}
            $EnvVars.Split(',') | ForEach-Object {
                $parts = $_.Split('=')
                if ($parts.Length -eq 2) {
                    $envVarsObj[$parts[0].Trim()] = $parts[1].Trim()
                }
            }
            $serverConfig.env = $envVarsObj
        }

        # Ajouter ou mettre à jour le serveur dans la configuration
        $mcpConfig.mcpServers | Add-Member -MemberType NoteProperty -Name $Name -Value $serverConfig -Force

        # Sauvegarder la configuration
        $mcpConfig | ConvertTo-Json -Depth 10 | Out-File $mcpConfigPath -Encoding utf8

        Write-Log "Fichier de configuration MCP principal mis à jour." -Level "SUCCESS"
    } else {
        Write-Log "Le fichier de configuration MCP principal n'existe pas: $mcpConfigPath" -Level "WARNING"
    }

    Write-Log "Génération du serveur MCP $Name terminée." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de la génération du serveur MCP: $_" -Level "ERROR"
    exit 1
}
