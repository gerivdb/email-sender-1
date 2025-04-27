#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour la roadmap avec les implÃ©mentations d'analyse distribuÃ©e et en temps rÃ©el.

.DESCRIPTION
    Ce script met Ã  jour la roadmap avec les implÃ©mentations d'analyse distribuÃ©e
    et d'analyse en temps rÃ©el.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap Ã  mettre Ã  jour.
    Par dÃ©faut, utilise 'Roadmap/roadmap_complete.md'.

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

# VÃ©rifier si le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Section pour l'analyse distribuÃ©e et en temps rÃ©el
$analysisPattern = "    - \[ \] DÃ©velopper `Start-DistributedAnalysis.ps1` pour l'analyse multi-machine\n    - \[ \] ImplÃ©menter un systÃ¨me de coordination des tÃ¢ches\n    - \[ \] CrÃ©er un mÃ©canisme de fusion des rÃ©sultats\n    - \[ \] Optimiser la distribution des charges de travail\n  - \[ \] CrÃ©er un systÃ¨me d'analyse incrÃ©mentale en temps rÃ©el\n    - \[ \] DÃ©velopper `Start-RealTimeAnalysis.ps1` pour l'analyse pendant l'Ã©dition\n    - \[ \] ImplÃ©menter un systÃ¨me de surveillance des fichiers\n    - \[ \] CrÃ©er un mÃ©canisme de notification en temps rÃ©el\n    - \[ \] Optimiser pour une latence minimale"

$analysisReplacement = @"
    - [x] DÃ©velopper `Start-DistributedAnalysis.ps1` pour l'analyse multi-machine
    - [x] ImplÃ©menter un systÃ¨me de coordination des tÃ¢ches
    - [x] CrÃ©er un mÃ©canisme de fusion des rÃ©sultats
    - [x] Optimiser la distribution des charges de travail
  - [x] CrÃ©er un systÃ¨me d'analyse incrÃ©mentale en temps rÃ©el
    - [x] DÃ©velopper `Start-RealTimeAnalysis.ps1` pour l'analyse pendant l'Ã©dition
    - [x] ImplÃ©menter un systÃ¨me de surveillance des fichiers
    - [x] CrÃ©er un mÃ©canisme de notification en temps rÃ©el
    - [x] Optimiser pour une latence minimale
"@

# Mettre Ã  jour le contenu de la roadmap
$updatedContent = $roadmapContent -replace $analysisPattern, $analysisReplacement

# Enregistrer le contenu mis Ã  jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise Ã  jour : $RoadmapPath" -ForegroundColor Green
Write-Host "Les sections suivantes ont Ã©tÃ© mises Ã  jour :" -ForegroundColor Green
Write-Host "- Analyse distribuÃ©e avec Start-DistributedAnalysis.ps1" -ForegroundColor Green
Write-Host "- Analyse en temps rÃ©el avec Start-RealTimeAnalysis.ps1" -ForegroundColor Green
