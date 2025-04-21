<#
.SYNOPSIS
    Script pour créer un nouveau workflow n8n.

.DESCRIPTION
    Ce script crée un nouveau workflow n8n à partir d'un modèle ou à partir de zéro.

.PARAMETER Name
    Nom du workflow à créer.

.PARAMETER Description
    Description du workflow à créer.

.PARAMETER Template
    Nom du modèle à utiliser pour créer le workflow.

.PARAMETER Parameters
    Paramètres à remplacer dans le modèle.

.EXAMPLE
    .\new-workflow.ps1 -Name "Mon Workflow" -Description "Description du workflow"

.EXAMPLE
    .\new-workflow.ps1 -Name "Mon Workflow" -Template "simple-workflow" -Parameters @{ message = "Hello World" }
#>

#Requires -Version 5.1

# Paramètres
param (
    [Parameter(Mandatory = $true)]
    [string]$Name,
    
    [Parameter(Mandatory = $false)]
    [string]$Description = "",
    
    [Parameter(Mandatory = $false)]
    [string]$Template = "",
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{}
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleFile = Join-Path -Path $ScriptPath -ChildPath "IdeN8nIntegration.ps1"

# Importer le module
if (-not (Test-Path -Path $ModuleFile)) {
    Write-Error "Le fichier module IdeN8nIntegration.ps1 n'existe pas."
    exit 1
}

Import-Module $ModuleFile -Force

# Créer le workflow
try {
    if ([string]::IsNullOrEmpty($Template)) {
        # Créer un workflow vide
        $Workflow = New-N8nWorkflow -Name $Name -Description $Description
    }
    else {
        # Créer un workflow à partir d'un modèle
        $Workflow = New-N8nWorkflowFromTemplate -TemplateName $Template -Name $Name -Description $Description -Parameters $Parameters
    }
    
    if ($Workflow) {
        Write-Host "Workflow créé avec succès :" -ForegroundColor Green
        Write-Host "  - ID : $($Workflow.id)" -ForegroundColor White
        Write-Host "  - Nom : $($Workflow.name)" -ForegroundColor White
        Write-Host "  - URL : http://localhost:5678/workflow/$($Workflow.id)" -ForegroundColor White
        
        # Synchroniser les workflows
        $null = Sync-N8nWorkflowsWithIde
        
        # Ouvrir le workflow dans VS Code
        $null = Open-WorkflowInVsCode -WorkflowId $Workflow.id
    }
    else {
        Write-Host "Erreur lors de la création du workflow." -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur lors de la création du workflow : $_" -ForegroundColor Red
}
