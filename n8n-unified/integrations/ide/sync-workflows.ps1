<#
.SYNOPSIS
    Script pour synchroniser les workflows entre n8n et l'IDE.

.DESCRIPTION
    Ce script synchronise les workflows entre n8n et l'IDE, en récupérant les workflows
    depuis n8n et en les sauvegardant dans des fichiers JSON.

.EXAMPLE
    .\sync-workflows.ps1
#>

#Requires -Version 5.1

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleFile = Join-Path -Path $ScriptPath -ChildPath "IdeN8nIntegration.ps1"

# Importer le module
if (-not (Test-Path -Path $ModuleFile)) {
    Write-Error "Le fichier module IdeN8nIntegration.ps1 n'existe pas."
    exit 1
}

Import-Module $ModuleFile -Force

# Synchroniser les workflows
try {
    $Workflows = Sync-N8nWorkflowsWithIde
    
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
