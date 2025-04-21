<#
.SYNOPSIS
    Script pour synchroniser les workflows entre n8n et Augment.

.DESCRIPTION
    Ce script synchronise les workflows entre n8n et Augment, en exportant les workflows
    n8n vers Augment et en important les workflows Augment vers n8n.

.EXAMPLE
    .\sync-workflows-with-augment.ps1
#>

#Requires -Version 5.1

# Importer le module
$ModuleFile = Join-Path -Path $PSScriptRoot -ChildPath "AugmentN8nIntegration.ps1"
if (-not (Test-Path -Path $ModuleFile)) {
    Write-Error "Le fichier module AugmentN8nIntegration.ps1 n'existe pas."
    exit 1
}

# Synchroniser les workflows
try {
    # Importer le module
    . $ModuleFile
    
    # Synchroniser les workflows
    $Workflows = Sync-N8nWorkflowsWithAugment
    
    if ($Workflows -and $Workflows.Count -gt 0) {
        Write-Host "Synchronisation réussie :" -ForegroundColor Green
        Write-Host "  - $($Workflows.Count) workflows synchronisés" -ForegroundColor White
        
        # Afficher la liste des workflows
        Write-Host "  - Liste des workflows :" -ForegroundColor White
        foreach ($Workflow in $Workflows) {
            $Status = if ($Workflow.active) { "Actif" } else { "Inactif" }
            Write-Host "    - $($Workflow.name) (ID: $($Workflow.id), Statut: $Status)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "Aucun workflow à synchroniser." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Erreur lors de la synchronisation des workflows : $_" -ForegroundColor Red
}
