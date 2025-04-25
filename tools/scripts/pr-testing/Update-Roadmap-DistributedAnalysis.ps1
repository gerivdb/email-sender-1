#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour la roadmap avec les implémentations d'analyse distribuée et en temps réel.

.DESCRIPTION
    Ce script met à jour la roadmap avec les implémentations d'analyse distribuée
    et d'analyse en temps réel.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap à mettre à jour.
    Par défaut, utilise 'Roadmap/roadmap_complete.md'.

.EXAMPLE
    .\Update-Roadmap-DistributedAnalysis.ps1 -RoadmapPath "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/Roadmap/roadmap_complete.md"

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"
)

# Vérifier si le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Section pour l'analyse distribuée et en temps réel
$analysisPattern = "    - \[ \] Développer `Start-DistributedAnalysis.ps1` pour l'analyse multi-machine\n    - \[ \] Implémenter un système de coordination des tâches\n    - \[ \] Créer un mécanisme de fusion des résultats\n    - \[ \] Optimiser la distribution des charges de travail\n  - \[ \] Créer un système d'analyse incrémentale en temps réel\n    - \[ \] Développer `Start-RealTimeAnalysis.ps1` pour l'analyse pendant l'édition\n    - \[ \] Implémenter un système de surveillance des fichiers\n    - \[ \] Créer un mécanisme de notification en temps réel\n    - \[ \] Optimiser pour une latence minimale"

$analysisReplacement = @"
    - [x] Développer `Start-DistributedAnalysis.ps1` pour l'analyse multi-machine
    - [x] Implémenter un système de coordination des tâches
    - [x] Créer un mécanisme de fusion des résultats
    - [x] Optimiser la distribution des charges de travail
  - [x] Créer un système d'analyse incrémentale en temps réel
    - [x] Développer `Start-RealTimeAnalysis.ps1` pour l'analyse pendant l'édition
    - [x] Implémenter un système de surveillance des fichiers
    - [x] Créer un mécanisme de notification en temps réel
    - [x] Optimiser pour une latence minimale
"@

# Mettre à jour le contenu de la roadmap
$updatedContent = $roadmapContent -replace $analysisPattern, $analysisReplacement

# Enregistrer le contenu mis à jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise à jour : $RoadmapPath" -ForegroundColor Green
Write-Host "Les sections suivantes ont été mises à jour :" -ForegroundColor Green
Write-Host "- Analyse distribuée avec Start-DistributedAnalysis.ps1" -ForegroundColor Green
Write-Host "- Analyse en temps réel avec Start-RealTimeAnalysis.ps1" -ForegroundColor Green
