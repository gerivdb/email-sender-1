<#
.SYNOPSIS
    Script pour tester l'intégration entre n8n et Augment.

.DESCRIPTION
    Ce script teste l'intégration entre n8n et Augment en exécutant les différentes
    fonctions du module AugmentN8nIntegration.ps1.

.NOTES
    Nom du fichier : test-integration.ps1
    Auteur : Augment Agent
    Date de création : 21/04/2025
    Version : 1.0
#>

#Requires -Version 5.1

# Paramètres
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Test", "Sync", "Export", "Import")]
    [string]$Action = "All",
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleFile = Join-Path -Path $ScriptPath -ChildPath "AugmentN8nIntegration.ps1"

# Fonction pour écrire dans la console avec des couleurs
function Write-ColorOutput {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White
    )
    
    $OriginalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $OriginalColor
}

# Afficher l'en-tête
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "Test de l'intégration n8n avec Augment" -ForegroundColor Cyan
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput ""

# Vérifier si le module existe
if (-not (Test-Path -Path $ModuleFile)) {
    Write-ColorOutput "Erreur : Le fichier module AugmentN8nIntegration.ps1 n'existe pas." -ForegroundColor Red
    Write-ColorOutput "Veuillez vous assurer que le fichier est présent dans le dossier $ScriptPath." -ForegroundColor Red
    exit 1
}

# Importer le module
Write-ColorOutput "Importation du module AugmentN8nIntegration.ps1..." -ForegroundColor Yellow
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
    Write-ColorOutput "Synchronisation des workflows avec Augment..." -ForegroundColor Yellow
    try {
        $SyncedWorkflows = Sync-N8nWorkflowsWithAugment
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

if ($Action -eq "All" -or $Action -eq "Export") {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Exportation des données n8n vers Augment Memories..." -ForegroundColor Yellow
    try {
        $Memories = Export-N8nDataToAugmentMemories
        Write-ColorOutput "  - $($Memories.Count) workflows exportés" -ForegroundColor Green
        
        if ($Verbose) {
            foreach ($Memory in $Memories) {
                Write-ColorOutput "    - $($Memory.name) (ID: $($Memory.id))" -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de l'exportation des données : $_" -ForegroundColor Red
    }
}

if ($Action -eq "All" -or $Action -eq "Import") {
    Write-ColorOutput "" -ForegroundColor White
    Write-ColorOutput "Importation des données Augment Memories vers n8n..." -ForegroundColor Yellow
    try {
        $Result = Import-AugmentMemoriesToN8n
        if ($Result) {
            Write-ColorOutput "  - Importation réussie" -ForegroundColor Green
        }
        else {
            Write-ColorOutput "  - Aucune donnée importée" -ForegroundColor Yellow
        }
    }
    catch {
        Write-ColorOutput "  - Erreur lors de l'importation des données : $_" -ForegroundColor Red
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
Write-ColorOutput "  Start-AugmentN8nIntegration -Action Test" -ForegroundColor Yellow
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Pour plus d'informations, consultez le fichier README.md." -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
