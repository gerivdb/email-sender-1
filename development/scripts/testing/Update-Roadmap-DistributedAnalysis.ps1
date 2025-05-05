#Requires -Version 5.1
<#
.SYNOPSIS
    Met ÃƒÂ  jour la roadmap avec les implÃƒÂ©mentations d'analyse distribuÃƒÂ©e et en temps rÃƒÂ©el.

.DESCRIPTION
    Ce script met ÃƒÂ  jour la roadmap avec les implÃƒÂ©mentations d'analyse distribuÃƒÂ©e
    et d'analyse en temps rÃƒÂ©el.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap ÃƒÂ  mettre ÃƒÂ  jour.
    Par dÃƒÂ©faut, utilise 'Roadmap/roadmap_complete.md'.

.EXAMPLE
    .\Update-Roadmap-DistributedAnalysis.ps1 -RoadmapPath "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/Roadmap/roadmap_complete.md"

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

# VÃƒÂ©rifier si le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Section pour l'analyse distribuÃƒÂ©e et en temps rÃƒÂ©el
$analysisPattern = "    - \[ \] DÃƒÂ©velopper `Start-DistributedAnalysis.ps1` pour l'analyse multi-machine\n    - \[ \] ImplÃƒÂ©menter un systÃƒÂ¨me de coordination des tÃƒÂ¢ches\n    - \[ \] CrÃƒÂ©er un mÃƒÂ©canisme de fusion des rÃƒÂ©sultats\n    - \[ \] Optimiser la distribution des charges de travail\n  - \[ \] CrÃƒÂ©er un systÃƒÂ¨me d'analyse incrÃƒÂ©mentale en temps rÃƒÂ©el\n    - \[ \] DÃƒÂ©velopper `Start-RealTimeAnalysis.ps1` pour l'analyse pendant l'ÃƒÂ©dition\n    - \[ \] ImplÃƒÂ©menter un systÃƒÂ¨me de surveillance des fichiers\n    - \[ \] CrÃƒÂ©er un mÃƒÂ©canisme de notification en temps rÃƒÂ©el\n    - \[ \] Optimiser pour une latence minimale"

$analysisReplacement = @"
    - [x] DÃƒÂ©velopper `Start-DistributedAnalysis.ps1` pour l'analyse multi-machine
    - [x] ImplÃƒÂ©menter un systÃƒÂ¨me de coordination des tÃƒÂ¢ches
    - [x] CrÃƒÂ©er un mÃƒÂ©canisme de fusion des rÃƒÂ©sultats
    - [x] Optimiser la distribution des charges de travail
  - [x] CrÃƒÂ©er un systÃƒÂ¨me d'analyse incrÃƒÂ©mentale en temps rÃƒÂ©el
    - [x] DÃƒÂ©velopper `Start-RealTimeAnalysis.ps1` pour l'analyse pendant l'ÃƒÂ©dition
    - [x] ImplÃƒÂ©menter un systÃƒÂ¨me de surveillance des fichiers
    - [x] CrÃƒÂ©er un mÃƒÂ©canisme de notification en temps rÃƒÂ©el
    - [x] Optimiser pour une latence minimale
"@

# Mettre ÃƒÂ  jour le contenu de la roadmap
$updatedContent = $roadmapContent -replace $analysisPattern, $analysisReplacement

# Enregistrer le contenu mis ÃƒÂ  jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise ÃƒÂ  jour : $RoadmapPath" -ForegroundColor Green
Write-Host "Les sections suivantes ont ÃƒÂ©tÃƒÂ© mises ÃƒÂ  jour :" -ForegroundColor Green
Write-Host "- Analyse distribuÃƒÂ©e avec Start-DistributedAnalysis.ps1" -ForegroundColor Green
Write-Host "- Analyse en temps rÃƒÂ©el avec Start-RealTimeAnalysis.ps1" -ForegroundColor Green
