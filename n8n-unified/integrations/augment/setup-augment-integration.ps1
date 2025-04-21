<#
.SYNOPSIS
    Script de configuration de l'intégration entre n8n et Augment.

.DESCRIPTION
    Ce script configure l'intégration entre n8n et Augment en créant les dossiers
    et fichiers nécessaires, et en vérifiant que n8n est accessible.

.NOTES
    Nom du fichier : setup-augment-integration.ps1
    Auteur : Augment Agent
    Date de création : 21/04/2025
    Version : 1.0
#>

#Requires -Version 5.1

# Paramètres
param (
    [Parameter(Mandatory = $false)]
    [string]$N8nUrl = "http://localhost:5678",
    
    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Join-Path -Path $ScriptPath -ChildPath "config"
$LogsDir = Join-Path -Path $ScriptPath -ChildPath "logs"
$MemoriesDir = Join-Path -Path $ScriptPath -ChildPath "memories"
$WorkflowsDir = Join-Path -Path $ScriptPath -ChildPath "workflows"
$ConfigFile = Join-Path -Path $ConfigDir -ChildPath "augment-n8n-config.json"
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
Write-ColorOutput "Configuration de l'intégration n8n avec Augment" -ForegroundColor Cyan
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput ""

# Vérifier si le module existe
if (-not (Test-Path -Path $ModuleFile)) {
    Write-ColorOutput "Erreur : Le fichier module AugmentN8nIntegration.ps1 n'existe pas." -ForegroundColor Red
    Write-ColorOutput "Veuillez vous assurer que le fichier est présent dans le dossier $ScriptPath." -ForegroundColor Red
    exit 1
}

# Créer les dossiers nécessaires
Write-ColorOutput "Création des dossiers nécessaires..." -ForegroundColor Yellow

$Directories = @($ConfigDir, $LogsDir, $MemoriesDir, $WorkflowsDir)
foreach ($Dir in $Directories) {
    if (-not (Test-Path -Path $Dir)) {
        New-Item -Path $Dir -ItemType Directory -Force | Out-Null
        Write-ColorOutput "  - Dossier créé : $Dir" -ForegroundColor Green
    }
    else {
        Write-ColorOutput "  - Dossier existant : $Dir" -ForegroundColor Gray
    }
}

# Créer ou mettre à jour le fichier de configuration
Write-ColorOutput "Configuration de l'intégration..." -ForegroundColor Yellow

$Config = @{
    N8nUrl = $N8nUrl
    ApiKey = $ApiKey
    LastSync = $null
    Workflows = @()
}

if (Test-Path -Path $ConfigFile -and -not $Force) {
    $ExistingConfig = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
    
    # Conserver les valeurs existantes si elles ne sont pas spécifiées
    if (-not $PSBoundParameters.ContainsKey('N8nUrl')) {
        $Config.N8nUrl = $ExistingConfig.N8nUrl
    }
    
    if (-not $PSBoundParameters.ContainsKey('ApiKey')) {
        $Config.ApiKey = $ExistingConfig.ApiKey
    }
    
    $Config.LastSync = $ExistingConfig.LastSync
    $Config.Workflows = $ExistingConfig.Workflows
    
    Write-ColorOutput "  - Configuration existante mise à jour" -ForegroundColor Green
}
else {
    Write-ColorOutput "  - Nouvelle configuration créée" -ForegroundColor Green
}

# Sauvegarder la configuration
$Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8

# Tester la connexion à n8n
Write-ColorOutput "Test de la connexion à n8n..." -ForegroundColor Yellow

try {
    $Headers = @{
        "Accept" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
        $Headers["X-N8N-API-KEY"] = $Config.ApiKey
    }
    
    $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/healthz" -Method Get -Headers $Headers -TimeoutSec 5
    
    if ($Response.status -eq "ok") {
        Write-ColorOutput "  - Connexion à n8n réussie" -ForegroundColor Green
    }
    else {
        Write-ColorOutput "  - Connexion à n8n échouée : $($Response.status)" -ForegroundColor Red
        Write-ColorOutput "    Veuillez vérifier que n8n est en cours d'exécution et accessible à l'adresse $($Config.N8nUrl)." -ForegroundColor Red
    }
}
catch {
    Write-ColorOutput "  - Erreur lors de la connexion à n8n : $_" -ForegroundColor Red
    Write-ColorOutput "    Veuillez vérifier que n8n est en cours d'exécution et accessible à l'adresse $($Config.N8nUrl)." -ForegroundColor Red
}

# Créer un exemple de workflow
Write-ColorOutput "Création d'un exemple de workflow..." -ForegroundColor Yellow

$ExampleWorkflowFile = Join-Path -Path $WorkflowsDir -ChildPath "example-augment-workflow.json"
$ExampleWorkflow = @{
    name = "Example Augment Workflow"
    nodes = @(
        @{
            parameters = @{
                rule = @{
                    interval = @(
                        @{
                            field = "hours"
                            minutesInterval = 1
                            hoursInterval = 1
                        }
                    )
                }
            }
            name = "Schedule Trigger"
            type = "n8n-nodes-base.scheduleTrigger"
            typeVersion = 1
            position = @(250, 300)
        },
        @{
            parameters = @{
                keepOnlySet = true
                values = @{
                    string = @(
                        @{
                            name = "message"
                            value = "Hello from Augment!"
                        }
                    )
                }
            }
            name = "Set Message"
            type = "n8n-nodes-base.set"
            typeVersion = 1
            position = @(450, 300)
        }
    )
    connections = @{
        Schedule_Trigger = @(
            @{
                node = "Set Message"
                type = "main"
                index = 0
            }
        )
    }
}

$ExampleWorkflow | ConvertTo-Json -Depth 10 | Set-Content -Path $ExampleWorkflowFile -Encoding UTF8
Write-ColorOutput "  - Exemple de workflow créé : $ExampleWorkflowFile" -ForegroundColor Green

# Créer un exemple de mémoire Augment
Write-ColorOutput "Création d'un exemple de mémoire Augment..." -ForegroundColor Yellow

$ExampleMemoryFile = Join-Path -Path $MemoriesDir -ChildPath "example-augment-memory.json"
$ExampleMemory = @(
    @{
        id = "mem_001"
        type = "augment_memory"
        description = "Exemple de mémoire Augment pour n8n"
        content = "Créer un workflow n8n pour envoyer un email quotidien avec un résumé des tâches"
        createdAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
)

$ExampleMemory | ConvertTo-Json -Depth 10 | Set-Content -Path $ExampleMemoryFile -Encoding UTF8
Write-ColorOutput "  - Exemple de mémoire créé : $ExampleMemoryFile" -ForegroundColor Green

# Afficher les instructions finales
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "Configuration terminée avec succès !" -ForegroundColor Green
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Pour utiliser l'intégration, importez le module :" -ForegroundColor White
Write-ColorOutput "  Import-Module '$ModuleFile'" -ForegroundColor Yellow
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Puis utilisez les fonctions disponibles :" -ForegroundColor White
Write-ColorOutput "  Start-AugmentN8nIntegration -Action Test" -ForegroundColor Yellow
Write-ColorOutput "  Start-AugmentN8nIntegration -Action Sync" -ForegroundColor Yellow
Write-ColorOutput "  Start-AugmentN8nIntegration -Action Export" -ForegroundColor Yellow
Write-ColorOutput "  Start-AugmentN8nIntegration -Action Import" -ForegroundColor Yellow
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Pour plus d'informations, consultez le fichier README.md." -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
