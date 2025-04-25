# Script de lancement rapide pour les outils de gestion des caractÃ¨res accentuÃ©s

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("fix", "import", "remove-duplicates", "list", "delete-all")]
    [string]$Action
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

switch ($Action) {
    "fix" {
        Write-Host "Correction des caractÃ¨res accentuÃ©s dans les fichiers JSON..." -ForegroundColor Cyan
        python $scriptPath/python/fix_all_workflows.py
    }
    "import" {
        Write-Host "Importation des workflows corrigÃ©s..." -ForegroundColor Cyan
        & $scriptPath/powershell/import-fixed-all-workflows.ps1
    }
    "remove-duplicates" {
        Write-Host "Suppression des doublons et des workflows mal encodÃ©s..." -ForegroundColor Cyan
        & $scriptPath/powershell/remove-duplicate-workflows.ps1
    }
    "list" {
        Write-Host "Liste des workflows existants..." -ForegroundColor Cyan
        & $scriptPath/powershell/list-workflows.ps1
    }
    "delete-all" {
        Write-Host "Suppression de tous les workflows existants..." -ForegroundColor Cyan
        & $scriptPath/powershell/delete-all-workflows-auto.ps1
    }
}
