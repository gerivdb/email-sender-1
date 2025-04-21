<#
.SYNOPSIS
    Script pour tester l'intégration entre n8n et les serveurs MCP.

.DESCRIPTION
    Ce script teste l'intégration entre n8n et les serveurs MCP en exécutant les différentes
    fonctions du module McpN8nIntegration.ps1.

.PARAMETER Action
    Action à exécuter : All, Test, Configure, Start, Stop, Sync, Copy.

.PARAMETER Verbose
    Affiche des informations détaillées.

.EXAMPLE
    .\test-mcp-integration.ps1 -Action All
#>

#Requires -Version 5.1

# Paramètres
param (
    [ValidateSet("All", "Test", "Configure", "Start", "Stop", "Sync", "Copy")]
    [string]$Action = "All",
    
    [switch]$Verbose
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleFile = Join-Path -Path $ScriptPath -ChildPath "McpN8nIntegration.ps1"

# Fonction pour écrire dans la console avec des couleurs
function Write-ColorOutput {
    param (
        [string]$Message,
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White
    )
    
    $OriginalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $OriginalColor
}

# Afficher l'en-tête
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "Test de l'intégration n8n avec les serveurs MCP" -ForegroundColor Cyan
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput ""

# Vérifier si le module existe
if (-not (Test-Path -Path $ModuleFile)) {
    Write-ColorOutput "Erreur : Le fichier module McpN8nIntegration.ps1 n'existe pas." -ForegroundColor Red
    Write-ColorOutput "Veuillez vous assurer que le fichier est présent dans le dossier $ScriptPath." -ForegroundColor Red
    exit 1
}

# Importer le module
Write-ColorOutput "Importation du module McpN8nIntegration.ps1..." -ForegroundColor Yellow
try {
    Import-Module $ModuleFile -Force
    Write-ColorOutput "  - Module importé avec succès" -ForegroundColor Green
}
catch {
    Write-ColorOutput "  - Erreur lors de l'importation du module : $_" -ForegroundColor Red
    exit 1
}

# Exécuter les tests
if ($Action -eq "All" -or $Action -eq "Test") {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Test de la connexion à n8n..." -ForegroundColor Yellow
    try {
        $Connected = Test-N8nConnection
        if ($Connected) {
            Write-ColorOutput "  - Connexion à n8n réussie" -ForegroundColor Green
        }
        else {
            Write-ColorOutput "  - Connexion à n8n échouée" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors du test de connexion : $_" -ForegroundColor Red
        exit 1
    }
    
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Récupération des serveurs MCP..." -ForegroundColor Yellow
    try {
        $Servers = Get-McpServers
        Write-ColorOutput "  - $($Servers.Count) serveurs MCP trouvés" -ForegroundColor Green
        
        if ($Verbose) {
            foreach ($Server in $Servers) {
                Write-ColorOutput "    - $($Server.Name) (Chemin: $($Server.Path))" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de la récupération des serveurs MCP : $_" -ForegroundColor Red
    }
}

if ($Action -eq "All" -or $Action -eq "Configure") {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Configuration des identifiants MCP dans n8n..." -ForegroundColor Yellow
    try {
        $Result = Set-McpCredentialsInN8n
        if ($Result) {
            Write-ColorOutput "  - Configuration des identifiants MCP réussie" -ForegroundColor Green
        }
        else {
            Write-ColorOutput "  - Erreur lors de la configuration des identifiants MCP" -ForegroundColor Red
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de la configuration des identifiants MCP : $_" -ForegroundColor Red
    }
}

if ($Action -eq "All" -or $Action -eq "Sync") {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Synchronisation des workflows avec les serveurs MCP..." -ForegroundColor Yellow
    try {
        $Result = Sync-WorkflowsWithMcp
        if ($Result) {
            Write-ColorOutput "  - Synchronisation des workflows réussie" -ForegroundColor Green
        }
        else {
            Write-ColorOutput "  - Erreur lors de la synchronisation des workflows" -ForegroundColor Red
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de la synchronisation des workflows : $_" -ForegroundColor Red
    }
}

if ($Action -eq "All" -or $Action -eq "Copy") {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Copie des identifiants MCP vers n8n..." -ForegroundColor Yellow
    try {
        $Result = Copy-McpCredentialsToN8n
        if ($Result) {
            Write-ColorOutput "  - Copie des identifiants MCP réussie" -ForegroundColor Green
        }
        else {
            Write-ColorOutput "  - Erreur lors de la copie des identifiants MCP" -ForegroundColor Red
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de la copie des identifiants MCP : $_" -ForegroundColor Red
    }
    
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Copie de la base de données MCP vers n8n..." -ForegroundColor Yellow
    try {
        $Result = Copy-McpDatabaseToN8n
        if ($Result) {
            Write-ColorOutput "  - Copie de la base de données MCP réussie" -ForegroundColor Green
        }
        else {
            Write-ColorOutput "  - Erreur lors de la copie de la base de données MCP" -ForegroundColor Red
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de la copie de la base de données MCP : $_" -ForegroundColor Red
    }
}

# Afficher le résumé
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "Test de l'intégration terminé" -ForegroundColor Cyan
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Pour utiliser l'intégration dans vos scripts :" -ForegroundColor White
Write-ColorOutput "  Import-Module '$ModuleFile'" -ForegroundColor Yellow
Write-ColorOutput "  Start-McpN8nIntegration -Action Test" -ForegroundColor Yellow
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Pour plus d'informations, consultez le fichier README.md." -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
