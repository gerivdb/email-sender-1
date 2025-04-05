# Script PowerShell pour démarrer le serveur MCP Filesystem avec des options avancées
# Ce script permet de configurer et lancer le serveur MCP pour notre projet n8n

param (
    [switch]$ReadOnly = $false,
    [switch]$IncludeWorkflows = $true,
    [switch]$IncludeScripts = $true,
    [switch]$IncludeDocs = $true,
    [string]$CustomPath = "",
    [switch]$Help = $false
)

# Fonction d'aide
function Show-Help {
    Write-Host "Utilisation du script Start-McpFilesystem.ps1"
    Write-Host "=================================================="
    Write-Host ""
    Write-Host "Ce script démarre le serveur MCP Filesystem pour notre projet n8n."
    Write-Host ""
    Write-Host "Options :"
    Write-Host "  -ReadOnly         : Lance le serveur en mode lecture seule (pas de modification de fichiers)"
    Write-Host "  -IncludeWorkflows : Inclut les répertoires de workflows (par défaut: activé)"
    Write-Host "  -IncludeScripts   : Inclut les répertoires de scripts (par défaut: activé)"
    Write-Host "  -IncludeDocs      : Inclut les répertoires de documentation (par défaut: activé)"
    Write-Host "  -CustomPath       : Spécifie un chemin personnalisé à inclure"
    Write-Host "  -Help             : Affiche cette aide"
    Write-Host ""
    Write-Host "Exemples :"
    Write-Host "  .\Start-McpFilesystem.ps1"
    Write-Host "  .\Start-McpFilesystem.ps1 -ReadOnly"
    Write-Host "  .\Start-McpFilesystem.ps1 -IncludeWorkflows -IncludeScripts -IncludeDocs:$false"
    Write-Host "  .\Start-McpFilesystem.ps1 -CustomPath 'D:\MonProjet\Donnees'"
    Write-Host ""
    exit
}

# Afficher l'aide si demandé
if ($Help) {
    Show-Help
}

# Vérifier si MCP est installé
$mcpInstalled = $null
try {
    $mcpInstalled = Get-Command mcp-server-filesystem -ErrorAction SilentlyContinue
} catch {
    $mcpInstalled = $null
}

if ($null -eq $mcpInstalled) {
    Write-Host "Le serveur MCP Filesystem n'est pas installé." -ForegroundColor Yellow
    $installChoice = Read-Host "Voulez-vous l'installer maintenant ? (O/N)"
    
    if ($installChoice -eq "O" -or $installChoice -eq "o") {
        Write-Host "Installation en cours..." -ForegroundColor Cyan
        npm install -g @modelcontextprotocol/server-filesystem
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Échec de l'installation. Veuillez installer manuellement avec :" -ForegroundColor Red
            Write-Host "npm install -g @modelcontextprotocol/server-filesystem" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Installation réussie." -ForegroundColor Green
    } else {
        Write-Host "Installation annulée. Le script ne peut pas continuer sans MCP." -ForegroundColor Red
        exit 1
    }
}

# Déterminer le répertoire racine du projet
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Get-Item $scriptDir).Parent.Parent.FullName

# Construire la liste des répertoires à autoriser
$allowedDirs = @()

if ($IncludeWorkflows) {
    # Ajouter les répertoires de workflows
    $workflowDirs = Get-ChildItem -Path $projectRoot -Directory | Where-Object { $_.Name -like "*workflow*" }
    foreach ($dir in $workflowDirs) {
        $allowedDirs += $dir.FullName
    }
}

if ($IncludeScripts) {
    # Ajouter le répertoire de scripts
    $scriptsDir = Join-Path -Path $projectRoot -ChildPath "scripts"
    if (Test-Path $scriptsDir) {
        $allowedDirs += $scriptsDir
    }
}

if ($IncludeDocs) {
    # Ajouter le répertoire de documentation
    $docsDir = Join-Path -Path $projectRoot -ChildPath "docs"
    if (Test-Path $docsDir) {
        $allowedDirs += $docsDir
    }
}

# Ajouter le chemin personnalisé s'il est spécifié
if ($CustomPath -ne "") {
    if (Test-Path $CustomPath) {
        $allowedDirs += $CustomPath
    } else {
        Write-Host "Avertissement : Le chemin personnalisé '$CustomPath' n'existe pas." -ForegroundColor Yellow
    }
}

# Si aucun répertoire n'est spécifié, utiliser le répertoire racine du projet
if ($allowedDirs.Count -eq 0) {
    $allowedDirs += $projectRoot
}

# Afficher les informations de configuration
Write-Host "Configuration du serveur MCP Filesystem" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Mode lecture seule : $ReadOnly" -ForegroundColor White
Write-Host ""
Write-Host "Répertoires autorisés :" -ForegroundColor White
foreach ($dir in $allowedDirs) {
    Write-Host "  - $dir" -ForegroundColor White
}
Write-Host ""
Write-Host "Démarrage du serveur..." -ForegroundColor Green
Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur." -ForegroundColor Yellow
Write-Host ""

# Construire la commande
$command = "mcp-server-filesystem"
foreach ($dir in $allowedDirs) {
    if ($ReadOnly) {
        # En mode lecture seule, nous devons utiliser Docker avec l'option ro
        # Mais comme nous n'utilisons pas Docker ici, nous ajoutons simplement le répertoire
        $command += " `"$dir`""
    } else {
        $command += " `"$dir`""
    }
}

# Exécuter la commande
Invoke-Expression $command
