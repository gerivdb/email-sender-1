<#
.SYNOPSIS
    Script pour tester l'intégration entre n8n et l'IDE.

.DESCRIPTION
    Ce script teste l'intégration entre n8n et l'IDE en exécutant les différentes
    fonctions du module IdeN8nIntegration.ps1.

.PARAMETER Action
    Action à exécuter : All, Test, Sync, Install, Open.

.PARAMETER Verbose
    Affiche des informations détaillées.

.EXAMPLE
    .\test-integration.ps1 -Action All
#>

#Requires -Version 5.1

# Paramètres
param (
    [ValidateSet("All", "Test", "Sync", "Install", "Open")]
    [string]$Action = "All",
    
    [switch]$Verbose
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleFile = Join-Path -Path $ScriptPath -ChildPath "IdeN8nIntegration.ps1"

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
Write-ColorOutput "Test de l'intégration n8n avec l'IDE" -ForegroundColor Cyan
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput ""

# Vérifier si le module existe
if (-not (Test-Path -Path $ModuleFile)) {
    Write-ColorOutput "Erreur : Le fichier module IdeN8nIntegration.ps1 n'existe pas." -ForegroundColor Red
    Write-ColorOutput "Veuillez vous assurer que le fichier est présent dans le dossier $ScriptPath." -ForegroundColor Red
    exit 1
}

# Importer le module
Write-ColorOutput "Importation du module IdeN8nIntegration.ps1..." -ForegroundColor Yellow
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
    Write-ColorOutput "Récupération des workflows n8n..." -ForegroundColor Yellow
    try {
        $Workflows = Get-N8nWorkflows
        Write-ColorOutput "  - $($Workflows.Count) workflows trouvés" -ForegroundColor Green
        
        if ($Verbose) {
            foreach ($Workflow in $Workflows) {
                Write-ColorOutput "    - $($Workflow.name) (ID: $($Workflow.id))" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de la récupération des workflows : $_" -ForegroundColor Red
    }
}

if ($Action -eq "All" -or $Action -eq "Sync") {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Synchronisation des workflows avec l'IDE..." -ForegroundColor Yellow
    try {
        $SyncedWorkflows = Sync-N8nWorkflowsWithIde
        Write-ColorOutput "  - $($SyncedWorkflows.Count) workflows synchronisés" -ForegroundColor Green
        
        if ($Verbose) {
            foreach ($Workflow in $SyncedWorkflows) {
                Write-ColorOutput "    - $($Workflow.name) (ID: $($Workflow.id))" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de la synchronisation des workflows : $_" -ForegroundColor Red
    }
}

if ($Action -eq "All" -or $Action -eq "Install") {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Vérification de l'extension VS Code..." -ForegroundColor Yellow
    try {
        $IsInstalled = Test-VsCodeExtension
        if ($IsInstalled) {
            Write-ColorOutput "  - Extension VS Code n8n est installée" -ForegroundColor Green
        }
        else {
            Write-ColorOutput "  - Extension VS Code n8n n'est pas installée" -ForegroundColor Yellow
            
            Write-ColorOutput "" -ForegroundColor White
            Write-ColorOutput "Installation de l'extension VS Code..." -ForegroundColor Yellow
            $Installed = Install-VsCodeExtension
            if ($Installed) {
                Write-ColorOutput "  - Extension VS Code n8n installée avec succès" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "  - Erreur lors de l'installation de l'extension VS Code n8n" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de la vérification de l'extension VS Code : $_" -ForegroundColor Red
    }
}

if ($Action -eq "All" -or $Action -eq "Open") {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Ouverture d'un workflow dans VS Code..." -ForegroundColor Yellow
    try {
        # Récupérer les workflows
        $Workflows = Get-N8nWorkflows
        
        if ($Workflows -and $Workflows.Count -gt 0) {
            # Ouvrir le premier workflow
            $WorkflowId = $Workflows[0].id
            $Result = Open-WorkflowInVsCode -WorkflowId $WorkflowId
            
            if ($Result) {
                Write-ColorOutput "  - Workflow $WorkflowId ouvert dans VS Code" -ForegroundColor Green
            }
            else {
                Write-ColorOutput "  - Erreur lors de l'ouverture du workflow $WorkflowId dans VS Code" -ForegroundColor Red
            }
        }
        else {
            Write-ColorOutput "  - Aucun workflow à ouvrir" -ForegroundColor Yellow
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de l'ouverture du workflow dans VS Code : $_" -ForegroundColor Red
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
Write-ColorOutput "  Start-IdeN8nIntegration -Action Test" -ForegroundColor Yellow
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Pour plus d'informations, consultez le fichier README.md." -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
