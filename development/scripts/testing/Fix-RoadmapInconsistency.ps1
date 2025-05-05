#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les incohÃƒÂ©rences dans la roadmap.

.DESCRIPTION
    Ce script corrige les incohÃƒÂ©rences dans la roadmap, notamment les tÃƒÂ¢ches principales
    marquÃƒÂ©es comme non complÃƒÂ©tÃƒÂ©es alors que toutes les sous-tÃƒÂ¢ches sont complÃƒÂ©tÃƒÂ©es.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap ÃƒÂ  mettre ÃƒÂ  jour.
    Par dÃƒÂ©faut, utilise 'Roadmap/roadmap_complete.md'.

.EXAMPLE
    .\Fix-RoadmapInconsistency.ps1 -RoadmapPath "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/Roadmap/roadmap_complete.md"

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

# Corriger l'incohÃƒÂ©rence dans la section C.2.3
$inconsistencyPattern = "##### C\.2\.3 Optimisations avancÃƒÂ©es pour l'analyse des fichiers\n- \[ \] ImplÃƒÂ©menter des optimisations avancÃƒÂ©es pour l'analyse des fichiers"
$inconsistencyReplacement = "##### C.2.3 Optimisations avancÃƒÂ©es pour l'analyse des fichiers\n- [x] ImplÃƒÂ©menter des optimisations avancÃƒÂ©es pour l'analyse des fichiers"

# Mettre ÃƒÂ  jour le contenu de la roadmap
$updatedContent = $roadmapContent -replace $inconsistencyPattern, $inconsistencyReplacement

# Enregistrer le contenu mis ÃƒÂ  jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise ÃƒÂ  jour : $RoadmapPath" -ForegroundColor Green
Write-Host "Les incohÃƒÂ©rences suivantes ont ÃƒÂ©tÃƒÂ© corrigÃƒÂ©es :" -ForegroundColor Green
Write-Host "- Section C.2.3 : TÃƒÂ¢che principale marquÃƒÂ©e comme complÃƒÂ©tÃƒÂ©e" -ForegroundColor Green
