#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre le gestionnaire de serveurs MCP ou un agent MCP.
.DESCRIPTION
    Ce script permet de démarrer le gestionnaire de serveurs MCP ou un agent MCP
    qui utilise la bibliothèque mcp-use pour interagir avec les serveurs MCP.
.PARAMETER Agent
    Démarre un agent MCP au lieu du gestionnaire de serveurs.
.PARAMETER Query
    Spécifie la requête à exécuter par l'agent MCP.
.EXAMPLE
    .\Start-MCPManager.ps1
    Démarre le gestionnaire de serveurs MCP.
.EXAMPLE
    .\Start-MCPManager.ps1 -Agent
    Démarre un agent MCP et demande à l'utilisateur d'entrer une requête.
.EXAMPLE
    .\Start-MCPManager.ps1 -Agent -Query "Trouve les meilleurs restaurants à Paris"
    Démarre un agent MCP et exécute la requête spécifiée.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Agent,
    
    [Parameter(Mandatory = $false)]
    [string]$Query
)

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
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Vérifier si Python est installé
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pythonPath) {
    Write-Log "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.11 ou supérieur." -Level "ERROR"
    exit 1
}

# Vérifier la version de Python
$pythonVersion = python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
if ([version]$pythonVersion -lt [version]"3.11") {
    Write-Log "Python 3.11 ou supérieur est requis. Version actuelle: $pythonVersion" -Level "ERROR"
    exit 1
}

# Vérifier si les packages nécessaires sont installés
$packages = @("mcp-use", "langchain-openai", "python-dotenv")
foreach ($package in $packages) {
    $packageName = $package.Replace("-", "_")
    $installed = python -c "try: import $packageName; print('OK'); except ImportError: print('NOT_INSTALLED')" 2>$null
    if ($installed -ne "OK") {
        Write-Log "Installation du package $package..." -Level "INFO"
        python -m pip install $package
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Échec de l'installation du package $package." -Level "ERROR"
            exit 1
        }
        Write-Log "Package $package installé avec succès." -Level "SUCCESS"
    }
}

# Créer le répertoire mcp-servers s'il n'existe pas
$mcpServersDir = Join-Path -Path $projectRoot -ChildPath "mcp-servers"
if (-not (Test-Path $mcpServersDir)) {
    Write-Log "Création du répertoire mcp-servers..." -Level "INFO"
    New-Item -Path $mcpServersDir -ItemType Directory -Force | Out-Null
    Write-Log "Répertoire mcp-servers créé avec succès." -Level "SUCCESS"
}

# Créer le fichier .env s'il n'existe pas
$envPath = Join-Path -Path $projectRoot -ChildPath ".env"
if (-not (Test-Path $envPath)) {
    Write-Log "Création du fichier .env..." -Level "INFO"
    $apiKey = Read-Host "Entrez votre clé API OpenAI (ou laissez vide pour configurer plus tard)"
    if ($apiKey) {
        "OPENAI_API_KEY=$apiKey" | Out-File -FilePath $envPath -Encoding utf8
        Write-Log "Clé API OpenAI ajoutée au fichier .env." -Level "SUCCESS"
    } else {
        "# OPENAI_API_KEY=votre_clé_api" | Out-File -FilePath $envPath -Encoding utf8
        Write-Log "Fichier .env créé sans clé API OpenAI." -Level "WARNING"
    }
}

# Copier les scripts Python dans le répertoire du projet s'ils ne sont pas déjà présents
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$managerScript = Join-Path -Path $scriptDir -ChildPath "mcp_manager.py"
$agentScript = Join-Path -Path $scriptDir -ChildPath "mcp_agent.py"

$targetManagerScript = Join-Path -Path $projectRoot -ChildPath "mcp_manager.py"
$targetAgentScript = Join-Path -Path $projectRoot -ChildPath "mcp_agent.py"

if (-not (Test-Path $targetManagerScript) -and (Test-Path $managerScript)) {
    Write-Log "Copie du script mcp_manager.py vers le répertoire du projet..." -Level "INFO"
    Copy-Item -Path $managerScript -Destination $targetManagerScript -Force
    Write-Log "Script mcp_manager.py copié avec succès." -Level "SUCCESS"
}

if (-not (Test-Path $targetAgentScript) -and (Test-Path $agentScript)) {
    Write-Log "Copie du script mcp_agent.py vers le répertoire du projet..." -Level "INFO"
    Copy-Item -Path $agentScript -Destination $targetAgentScript -Force
    Write-Log "Script mcp_agent.py copié avec succès." -Level "SUCCESS"
}

# Exécuter le script approprié
if ($Agent) {
    if ($Query) {
        Write-Log "Exécution de l'agent MCP avec la requête: $Query" -Level "INFO"
        python "$projectRoot\mcp_agent.py" $Query
    } else {
        Write-Log "Exécution de l'agent MCP..." -Level "INFO"
        python "$projectRoot\mcp_agent.py"
    }
} else {
    Write-Log "Démarrage du gestionnaire de serveurs MCP..." -Level "INFO"
    python "$projectRoot\mcp_manager.py"
}

# Vérifier si l'exécution a réussi
if ($LASTEXITCODE -eq 0) {
    Write-Log "Exécution terminée avec succès." -Level "SUCCESS"
} else {
    Write-Log "Échec de l'exécution avec le code de sortie $LASTEXITCODE." -Level "ERROR"
}
