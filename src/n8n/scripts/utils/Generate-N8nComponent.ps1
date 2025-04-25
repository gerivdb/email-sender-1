<#
.SYNOPSIS
    Script de génération de composants n8n avec Hygen.

.DESCRIPTION
    Ce script permet de générer des composants n8n standardisés en utilisant Hygen.
    Il offre une interface interactive pour choisir le type de composant à générer.

.PARAMETER ComponentType
    Type de composant à générer. Valeurs possibles: script, workflow, doc, integration.

.EXAMPLE
    .\Generate-N8nComponent.ps1
    Lance l'interface interactive pour choisir le type de composant à générer.

.EXAMPLE
    .\Generate-N8nComponent.ps1 -ComponentType script
    Génère directement un script d'automatisation n8n.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-01
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("script", "workflow", "doc", "integration")]
    [string]$ComponentType
)

function Show-Menu {
    Clear-Host
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "Générateur de composants n8n" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "Choisissez le type de composant à générer:" -ForegroundColor Yellow
    Write-Host "1. Script d'automatisation" -ForegroundColor White
    Write-Host "2. Workflow n8n" -ForegroundColor White
    Write-Host "3. Documentation" -ForegroundColor White
    Write-Host "4. Intégration" -ForegroundColor White
    Write-Host "Q. Quitter" -ForegroundColor White
    Write-Host
}

function Generate-Component {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Type
    )

    switch ($Type) {
        "script" {
            Write-Host "Génération d'un script d'automatisation n8n..." -ForegroundColor Cyan
            npx hygen n8n-script new
        }
        "workflow" {
            Write-Host "Génération d'un workflow n8n..." -ForegroundColor Cyan
            npx hygen n8n-workflow new
        }
        "doc" {
            Write-Host "Génération d'une documentation n8n..." -ForegroundColor Cyan
            npx hygen n8n-doc new
        }
        "integration" {
            Write-Host "Génération d'une intégration n8n..." -ForegroundColor Cyan
            npx hygen n8n-integration new
        }
        default {
            Write-Host "Type de composant non reconnu: $Type" -ForegroundColor Red
            return $false
        }
    }

    Write-Host
    Write-Host "Génération terminée." -ForegroundColor Green
    Write-Host
    return $true
}

# Si un type de composant est spécifié en paramètre, générer directement ce type
if ($ComponentType) {
    Generate-Component -Type $ComponentType
    exit 0
}

# Sinon, afficher le menu interactif
do {
    Show-Menu
    $choice = Read-Host "Votre choix"

    switch ($choice) {
        "1" { $result = Generate-Component -Type "script" }
        "2" { $result = Generate-Component -Type "workflow" }
        "3" { $result = Generate-Component -Type "doc" }
        "4" { $result = Generate-Component -Type "integration" }
        "q" { return }
        "Q" { return }
        default { 
            Write-Host "Choix invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $result = $false
        }
    }

    if ($result) {
        Write-Host "Appuyez sur une touche pour continuer ou Q pour quitter..." -ForegroundColor Yellow
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.Character -eq 'q' -or $key.Character -eq 'Q') {
            return
        }
    }
} while ($true)
