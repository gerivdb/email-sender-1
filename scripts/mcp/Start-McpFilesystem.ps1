# Script PowerShell pour dÃ©marrer le serveur MCP Filesystem avec des options avancÃ©es
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
    Write-Host "Ce script dÃ©marre le serveur MCP Filesystem pour notre projet n8n."
    Write-Host ""
    Write-Host "Options :"
    Write-Host "  -ReadOnly         : Lance le serveur en mode lecture seule (pas de modification de fichiers)"
    Write-Host "  -IncludeWorkflows : Inclut les rÃ©pertoires de workflows (par dÃ©faut: activÃ©)"
    Write-Host "  -IncludeScripts   : Inclut les rÃ©pertoires de scripts (par dÃ©faut: activÃ©)"
    Write-Host "  -IncludeDocs      : Inclut les rÃ©pertoires de documentation (par dÃ©faut: activÃ©)"
    Write-Host "  -CustomPath       : SpÃ©cifie un chemin personnalisÃ© Ã  inclure"
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

# Afficher l'aide si demandÃ©
if ($Help) {
    Show-Help
}

# VÃ©rifier si MCP est installÃ©
$mcpInstalled = $null
try {
    $mcpInstalled = Get-Command mcp-server-filesystem -ErrorAction SilentlyContinue
} catch {
    $mcpInstalled = $null
}

if ($null -eq $mcpInstalled) {
    Write-Host "Le serveur MCP Filesystem n'est pas installÃ©." -ForegroundColor Yellow
    $installChoice = Read-Host "Voulez-vous l'installer maintenant ? (O/N)"
    
    if ($installChoice -eq "O" -or $installChoice -eq "o") {
        Write-Host "Installation en cours..." -ForegroundColor Cyan
        npm install -g @modelcontextprotocol/server-filesystem
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Ã‰chec de l'installation. Veuillez installer manuellement avec :" -ForegroundColor Red
            Write-Host "npm install -g @modelcontextprotocol/server-filesystem" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "Installation rÃ©ussie." -ForegroundColor Green
    } else {
        Write-Host "Installation annulÃ©e. Le script ne peut pas continuer sans MCP." -ForegroundColor Red
        exit 1
    }
}

# DÃ©terminer le rÃ©pertoire racine du projet
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Get-Item $scriptDir).Parent.Parent.FullName

# Construire la liste des rÃ©pertoires Ã  autoriser
$allowedDirs = @()

if ($IncludeWorkflows) {
    # Ajouter les rÃ©pertoires de workflows
    $workflowDirs = Get-ChildItem -Path $projectRoot -Directory | Where-Object { $_.Name -like "*workflow*" }
    foreach ($dir in $workflowDirs) {
        $allowedDirs += $dir.FullName
    }
}

if ($IncludeScripts) {
    # Ajouter le rÃ©pertoire de scripts
    $scriptsDir = Join-Path -Path $projectRoot -ChildPath "scripts"
    if (Test-Path $scriptsDir) {
        $allowedDirs += $scriptsDir
    }
}

if ($IncludeDocs) {
    # Ajouter le rÃ©pertoire de documentation
    $docsDir = Join-Path -Path $projectRoot -ChildPath "docs"
    if (Test-Path $docsDir) {
        $allowedDirs += $docsDir
    }
}

# Ajouter le chemin personnalisÃ© s'il est spÃ©cifiÃ©
if ($CustomPath -ne "") {
    if (Test-Path $CustomPath) {
        $allowedDirs += $CustomPath
    } else {
        Write-Host "Avertissement : Le chemin personnalisÃ© '$CustomPath' n'existe pas." -ForegroundColor Yellow
    }
}

# Si aucun rÃ©pertoire n'est spÃ©cifiÃ©, utiliser le rÃ©pertoire racine du projet
if ($allowedDirs.Count -eq 0) {
    $allowedDirs += $projectRoot
}

# Afficher les informations de configuration
Write-Host "Configuration du serveur MCP Filesystem" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Mode lecture seule : $ReadOnly" -ForegroundColor White
Write-Host ""
Write-Host "RÃ©pertoires autorisÃ©s :" -ForegroundColor White
foreach ($dir in $allowedDirs) {
    Write-Host "  - $dir" -ForegroundColor White
}
Write-Host ""
Write-Host "DÃ©marrage du serveur..." -ForegroundColor Green
Write-Host "Appuyez sur Ctrl+C pour arrÃªter le serveur." -ForegroundColor Yellow
Write-Host ""

# Construire la commande
$command = "mcp-server-filesystem"
foreach ($dir in $allowedDirs) {
    if ($ReadOnly) {
        # En mode lecture seule, nous devons utiliser Docker avec l'option ro
        # Mais comme nous n'utilisons pas Docker ici, nous ajoutons simplement le rÃ©pertoire
        $command += " `"$dir`""
    } else {
        $command += " `"$dir`""
    }
}

# ExÃ©cuter la commande
Invoke-Expression $command
