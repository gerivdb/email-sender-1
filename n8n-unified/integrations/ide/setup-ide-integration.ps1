<#
.SYNOPSIS
    Script de configuration de l'intégration entre n8n et l'IDE.

.DESCRIPTION
    Ce script configure l'intégration entre n8n et l'IDE en créant les dossiers
    et fichiers nécessaires, et en vérifiant que n8n est accessible.
#>

#Requires -Version 5.1

# Paramètres
param (
    [string]$N8nUrl = "http://localhost:5678",
    [string]$ApiKey = "",
    [switch]$Force
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Join-Path -Path $ScriptPath -ChildPath "config"
$LogsDir = Join-Path -Path $ScriptPath -ChildPath "logs"
$WorkflowsDir = Join-Path -Path $ScriptPath -ChildPath "workflows"
$TemplatesDir = Join-Path -Path $ScriptPath -ChildPath "templates"
$ConfigFile = Join-Path -Path $ConfigDir -ChildPath "ide-n8n-config.json"
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
Write-ColorOutput "Configuration de l'intégration n8n avec l'IDE" -ForegroundColor Cyan
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput ""

# Vérifier si le module existe
if (-not (Test-Path -Path $ModuleFile)) {
    Write-ColorOutput "Erreur : Le fichier module IdeN8nIntegration.ps1 n'existe pas." -ForegroundColor Red
    Write-ColorOutput "Veuillez vous assurer que le fichier est présent dans le dossier $ScriptPath." -ForegroundColor Red
    exit 1
}

# Créer les dossiers nécessaires
Write-ColorOutput "Création des dossiers nécessaires..." -ForegroundColor Yellow

$Directories = @($ConfigDir, $LogsDir, $WorkflowsDir, $TemplatesDir)
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
    Templates = @()
    VsCodeExtension = @{
        Installed = $false
        Version = ""
    }
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
    $Config.Templates = $ExistingConfig.Templates
    $Config.VsCodeExtension = $ExistingConfig.VsCodeExtension
    
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
    $Headers = @{ "Accept" = "application/json" }
    
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

# Créer un modèle de workflow
Write-ColorOutput "Création d'un modèle de workflow..." -ForegroundColor Yellow

$SimpleTemplateFile = Join-Path -Path $TemplatesDir -ChildPath "simple-workflow.json"
$SimpleTemplate = @{
    name = "Simple Workflow Template"
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
                keepOnlySet = $true
                values = @{
                    string = @(
                        @{
                            name = "message"
                            value = "{{message}}"
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

$SimpleTemplate | ConvertTo-Json -Depth 10 | Set-Content -Path $SimpleTemplateFile -Encoding UTF8
Write-ColorOutput "  - Modèle de workflow créé : $SimpleTemplateFile" -ForegroundColor Green

# Vérifier si VS Code est installé
Write-ColorOutput "Vérification de l'installation de VS Code..." -ForegroundColor Yellow

try {
    $VsCodeVersion = & code --version
    Write-ColorOutput "  - VS Code est installé (version $($VsCodeVersion[0]))" -ForegroundColor Green
    
    # Vérifier si l'extension n8n est installée
    $Extensions = & code --list-extensions
    $N8nExtension = $Extensions | Where-Object { $_ -like "n8n-io.n8n*" }
    
    if ($N8nExtension) {
        Write-ColorOutput "  - Extension n8n est installée ($N8nExtension)" -ForegroundColor Green
        $Config.VsCodeExtension.Installed = $true
        $Config.VsCodeExtension.Version = "1.0.0" # À remplacer par la version réelle
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8
    }
    else {
        Write-ColorOutput "  - Extension n8n n'est pas installée" -ForegroundColor Yellow
        Write-ColorOutput "    Vous pouvez l'installer en exécutant : code --install-extension n8n-io.n8n-vscode" -ForegroundColor Yellow
    }
}
catch {
    Write-ColorOutput "  - VS Code n'est pas installé ou n'est pas dans le PATH" -ForegroundColor Yellow
    Write-ColorOutput "    Vous pouvez télécharger VS Code à l'adresse : https://code.visualstudio.com/" -ForegroundColor Yellow
}

# Synchroniser les workflows
Write-ColorOutput "Synchronisation des workflows..." -ForegroundColor Yellow

try {
    # Importer le module
    Import-Module $ModuleFile -Force
    
    # Synchroniser les workflows
    $Workflows = Start-IdeN8nIntegration -Action Sync
    
    if ($Workflows -and $Workflows.Count -gt 0) {
        Write-ColorOutput "  - $($Workflows.Count) workflows synchronisés" -ForegroundColor Green
    }
    else {
        Write-ColorOutput "  - Aucun workflow synchronisé" -ForegroundColor Yellow
    }
}
catch {
    Write-ColorOutput "  - Erreur lors de la synchronisation des workflows : $_" -ForegroundColor Red
}

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
Write-ColorOutput "  Start-IdeN8nIntegration -Action Test" -ForegroundColor Yellow
Write-ColorOutput "  Start-IdeN8nIntegration -Action Sync" -ForegroundColor Yellow
Write-ColorOutput "  Start-IdeN8nIntegration -Action Install" -ForegroundColor Yellow
Write-ColorOutput "  Start-IdeN8nIntegration -Action Open -WorkflowId <id>" -ForegroundColor Yellow
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "Pour plus d'informations, consultez le fichier README.md." -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
