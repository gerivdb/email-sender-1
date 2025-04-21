<#
.SYNOPSIS
    Script pour créer un workflow n8n à partir d'une description Augment.

.DESCRIPTION
    Ce script crée un workflow n8n à partir d'une description fournie par Augment.

.PARAMETER Name
    Nom du workflow à créer.

.PARAMETER Description
    Description du workflow à créer.

.EXAMPLE
    .\create-workflow-from-augment.ps1 -Name "Mon Workflow" -Description "Envoyer un email quotidien avec les statistiques"
#>

#Requires -Version 5.1

# Paramètres
param (
    [Parameter(Mandatory = $true)]
    [string]$Name,
    
    [Parameter(Mandatory = $true)]
    [string]$Description
)

# Importer le module
$ModuleFile = Join-Path -Path $PSScriptRoot -ChildPath "AugmentN8nIntegration.ps1"
if (-not (Test-Path -Path $ModuleFile)) {
    Write-Error "Le fichier module AugmentN8nIntegration.ps1 n'existe pas."
    exit 1
}

# Créer le workflow
try {
    # Importer le module
    . $ModuleFile
    
    # Créer le workflow
    $Workflow = New-N8nWorkflowFromAugmentDescription -Name $Name -Description $Description
    
    if ($Workflow) {
        Write-Host "Workflow créé avec succès :" -ForegroundColor Green
        Write-Host "  - ID : $($Workflow.id)" -ForegroundColor White
        Write-Host "  - Nom : $($Workflow.name)" -ForegroundColor White
        Write-Host "  - URL : http://localhost:5678/workflow/$($Workflow.id)" -ForegroundColor White
    }
    else {
        Write-Host "Erreur lors de la création du workflow." -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur lors de la création du workflow : $_" -ForegroundColor Red
}
