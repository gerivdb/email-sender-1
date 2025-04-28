<#
.SYNOPSIS
    Script pour exécuter le mode C-BREAK du système de roadmap.
.DESCRIPTION
    Ce script exécute le mode C-BREAK du système de roadmap, qui permet de détecter et de corriger
    les dépendances circulaires dans le système.
.PARAMETER FilePath
    Chemin vers le fichier de roadmap à analyser.
.PARAMETER OutputPath
    Chemin vers le répertoire de sortie pour les rapports générés.
.PARAMETER MaxIterations
    Nombre maximum d'itérations pour la détection des cycles.
.PARAMETER WhatIf
    Si spécifié, simule les actions sans les exécuter.
.EXAMPLE
    .\c-break-mode.ps1 -FilePath "Roadmap/roadmap.md" -OutputPath "output/reports" -MaxIterations 10
    Détecte et corrige les dépendances circulaires dans le fichier de roadmap spécifié.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter()]
    [string]$FilePath = "Roadmap/roadmap_complete_converted.md",
    
    [Parameter()]
    [string]$OutputPath = "output/reports",
    
    [Parameter()]
    [int]$MaxIterations = 10
)

# Définir le chemin du script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "roadmap-parser\module\Functions"
$publicFunctionsPath = Join-Path -Path $modulePath -ChildPath "Public"

# Importer les fonctions nécessaires
$invokeRoadmapCycleBreakerPath = Join-Path -Path $publicFunctionsPath -ChildPath "Invoke-RoadmapCycleBreaker.ps1"

if (Test-Path -Path $invokeRoadmapCycleBreakerPath) {
    . $invokeRoadmapCycleBreakerPath
} else {
    Write-Error "Le fichier Invoke-RoadmapCycleBreaker.ps1 est introuvable à l'emplacement : $invokeRoadmapCycleBreakerPath"
    exit 1
}

# Afficher les informations de démarrage
Write-Host "Exécution du mode C-BREAK..." -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
Write-Host "Répertoire de sortie : $OutputPath" -ForegroundColor Cyan
Write-Host "Nombre maximum d'itérations : $MaxIterations" -ForegroundColor Cyan

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    if ($PSCmdlet.ShouldProcess($OutputPath, "Créer le répertoire de sortie")) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de sortie créé : $OutputPath" -ForegroundColor Green
    }
}

# Exécuter le mode C-BREAK
try {
    if ($PSCmdlet.ShouldProcess($FilePath, "Détecter et corriger les dépendances circulaires")) {
        $result = Invoke-RoadmapCycleBreaker -FilePath $FilePath -OutputPath $OutputPath -MaxIterations $MaxIterations
        
        if ($result) {
            Write-Host "Analyse des dépendances circulaires terminée avec succès." -ForegroundColor Green
            Write-Host "Nombre de cycles détectés : $($result.CycleCount)" -ForegroundColor Green
            Write-Host "Nombre de dépendances brisées : $($result.BrokenDependencyCount)" -ForegroundColor Green
            
            if ($result.CycleCount -gt 0) {
                Write-Host "Rapport de détection des cycles généré : $($result.ReportPath)" -ForegroundColor Yellow
            } else {
                Write-Host "Aucun cycle détecté dans le système." -ForegroundColor Green
            }
        } else {
            Write-Warning "Aucun résultat n'a été généré."
        }
    }
} catch {
    Write-Error "Erreur lors de l'exécution du mode C-BREAK : $_"
    exit 1
}

# Afficher les informations de fin
Write-Host "Mode C-BREAK terminé." -ForegroundColor Cyan
