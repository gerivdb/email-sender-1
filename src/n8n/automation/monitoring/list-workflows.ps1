<#
.SYNOPSIS
    Script pour lister les workflows n8n dans la nouvelle structure.

.DESCRIPTION
    Ce script liste tous les workflows n8n présents dans la nouvelle structure.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$workflowsPath = Join-Path -Path $n8nPath -ChildPath "core\workflows"

# Vérifier si le dossier des workflows existe
if (-not (Test-Path -Path $workflowsPath)) {
    Write-Error "Le dossier des workflows n'existe pas: $workflowsPath"
    exit 1
}

# Fonction pour lister les workflows dans un dossier
function Get-Workflows {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Environment
    )
    
    Write-Host "`n=== Workflows $Environment ===" -ForegroundColor Cyan
    
    # Vérifier si le dossier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Host "Le dossier $Environment n'existe pas: $Path" -ForegroundColor Yellow
        return
    }
    
    # Obtenir les fichiers de workflow
    $workflowFiles = Get-ChildItem -Path $Path -Filter "*.json" -File
    
    if ($workflowFiles.Count -eq 0) {
        Write-Host "Aucun workflow trouvé dans $Path" -ForegroundColor Yellow
        return
    }
    
    # Afficher les workflows
    foreach ($file in $workflowFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $name = if ($content.name) { $content.name } else { $file.BaseName }
            $active = if ($null -ne $content.active) { $content.active } else { "N/A" }
            
            Write-Host "- $name" -ForegroundColor Green
            Write-Host "  Fichier: $($file.Name)"
            Write-Host "  Actif: $active"
            Write-Host "  Dernière modification: $($file.LastWriteTime)"
            Write-Host ""
        } catch {
            Write-Host "- $($file.Name) (Erreur de parsing)" -ForegroundColor Red
            Write-Host "  Erreur: $_"
            Write-Host ""
        }
    }
    
    Write-Host "Total: $($workflowFiles.Count) workflows" -ForegroundColor Cyan
}

# Lister les workflows locaux
$localWorkflowsPath = Join-Path -Path $workflowsPath -ChildPath "local"
Get-Workflows -Path $localWorkflowsPath -Environment "locaux"

# Lister les workflows IDE
$ideWorkflowsPath = Join-Path -Path $workflowsPath -ChildPath "ide"
Get-Workflows -Path $ideWorkflowsPath -Environment "IDE"

# Afficher le total
$totalWorkflows = (Get-ChildItem -Path $workflowsPath -Filter "*.json" -File -Recurse).Count
Write-Host "`nTotal global: $totalWorkflows workflows" -ForegroundColor Cyan
