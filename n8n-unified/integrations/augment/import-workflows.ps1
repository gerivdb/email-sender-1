<#
.SYNOPSIS
    Script pour importer les workflows d'exemple dans n8n.

.DESCRIPTION
    Ce script importe les workflows d'exemple dans n8n en utilisant l'API REST de n8n.

.NOTES
    Nom du fichier : import-workflows.ps1
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
$WorkflowsDir = Join-Path -Path $ScriptPath -ChildPath "workflows"

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
Write-ColorOutput "Importation des workflows d'exemple dans n8n" -ForegroundColor Cyan
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput ""

# Vérifier si le dossier workflows existe
if (-not (Test-Path -Path $WorkflowsDir)) {
    Write-ColorOutput "Erreur : Le dossier workflows n'existe pas." -ForegroundColor Red
    Write-ColorOutput "Veuillez exécuter setup-augment-integration.ps1 pour créer les dossiers nécessaires." -ForegroundColor Red
    exit 1
}

# Récupérer les fichiers de workflow
$WorkflowFiles = Get-ChildItem -Path $WorkflowsDir -Filter "*.json"
if ($WorkflowFiles.Count -eq 0) {
    Write-ColorOutput "Erreur : Aucun fichier de workflow trouvé dans le dossier $WorkflowsDir." -ForegroundColor Red
    exit 1
}

Write-ColorOutput "Workflows trouvés : $($WorkflowFiles.Count)" -ForegroundColor Yellow
foreach ($File in $WorkflowFiles) {
    Write-ColorOutput "  - $($File.Name)" -ForegroundColor Gray
}
Write-ColorOutput ""

# Tester la connexion à n8n
Write-ColorOutput "Test de la connexion à n8n..." -ForegroundColor Yellow

try {
    $Headers = @{
        "Accept" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $Headers["X-N8N-API-KEY"] = $ApiKey
    }
    
    $Response = Invoke-RestMethod -Uri "$N8nUrl/healthz" -Method Get -Headers $Headers -TimeoutSec 5
    
    if ($Response.status -eq "ok") {
        Write-ColorOutput "  - Connexion à n8n réussie" -ForegroundColor Green
    }
    else {
        Write-ColorOutput "  - Connexion à n8n échouée : $($Response.status)" -ForegroundColor Red
        Write-ColorOutput "    Veuillez vérifier que n8n est en cours d'exécution et accessible à l'adresse $N8nUrl." -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-ColorOutput "  - Erreur lors de la connexion à n8n : $_" -ForegroundColor Red
    Write-ColorOutput "    Veuillez vérifier que n8n est en cours d'exécution et accessible à l'adresse $N8nUrl." -ForegroundColor Red
    exit 1
}

# Récupérer les workflows existants
Write-ColorOutput "Récupération des workflows existants..." -ForegroundColor Yellow

try {
    $Headers = @{
        "Accept" = "application/json"
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $Headers["X-N8N-API-KEY"] = $ApiKey
    }
    
    $ExistingWorkflows = Invoke-RestMethod -Uri "$N8nUrl/api/v1/workflows" -Method Get -Headers $Headers
    
    Write-ColorOutput "  - $($ExistingWorkflows.Count) workflows existants trouvés" -ForegroundColor Green
}
catch {
    Write-ColorOutput "  - Erreur lors de la récupération des workflows existants : $_" -ForegroundColor Red
    $ExistingWorkflows = @()
}

# Importer les workflows
Write-ColorOutput "Importation des workflows..." -ForegroundColor Yellow

$ImportedCount = 0
$SkippedCount = 0
$ErrorCount = 0

foreach ($File in $WorkflowFiles) {
    try {
        # Charger le workflow
        $Workflow = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
        
        # Vérifier si le workflow existe déjà
        $ExistingWorkflow = $ExistingWorkflows | Where-Object { $_.name -eq $Workflow.name }
        
        if ($ExistingWorkflow -and -not $Force) {
            Write-ColorOutput "  - Workflow '$($Workflow.name)' déjà existant, ignoré" -ForegroundColor Yellow
            $SkippedCount++
            continue
        }
        
        # Préparer les en-têtes
        $Headers = @{
            "Accept" = "application/json"
            "Content-Type" = "application/json"
        }
        
        if (-not [string]::IsNullOrEmpty($ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $ApiKey
        }
        
        # Créer ou mettre à jour le workflow
        if ($ExistingWorkflow) {
            $Response = Invoke-RestMethod -Uri "$N8nUrl/api/v1/workflows/$($ExistingWorkflow.id)" -Method Put -Headers $Headers -Body $File.FullName
            Write-ColorOutput "  - Workflow '$($Workflow.name)' mis à jour (ID: $($Response.id))" -ForegroundColor Green
        }
        else {
            $Response = Invoke-RestMethod -Uri "$N8nUrl/api/v1/workflows" -Method Post -Headers $Headers -Body $File.FullName
            Write-ColorOutput "  - Workflow '$($Workflow.name)' importé (ID: $($Response.id))" -ForegroundColor Green
        }
        
        $ImportedCount++
    }
    catch {
        Write-ColorOutput "  - Erreur lors de l'importation du workflow '$($File.Name)' : $_" -ForegroundColor Red
        $ErrorCount++
    }
}

# Afficher le résumé
Write-ColorOutput "" -ForegroundColor White
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "Résumé de l'importation" -ForegroundColor Cyan
Write-ColorOutput "====================================================" -ForegroundColor Cyan
Write-ColorOutput "Workflows importés : $ImportedCount" -ForegroundColor Green
Write-ColorOutput "Workflows ignorés : $SkippedCount" -ForegroundColor Yellow
Write-ColorOutput "Erreurs : $ErrorCount" -ForegroundColor Red
Write-ColorOutput "" -ForegroundColor White

if ($ImportedCount -gt 0) {
    Write-ColorOutput "Les workflows ont été importés avec succès dans n8n." -ForegroundColor Green
    Write-ColorOutput "Vous pouvez les consulter à l'adresse $N8nUrl" -ForegroundColor Green
}
else {
    Write-ColorOutput "Aucun workflow n'a été importé dans n8n." -ForegroundColor Yellow
}

Write-ColorOutput "====================================================" -ForegroundColor Cyan
