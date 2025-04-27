#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les incohÃ©rences dans la roadmap.

.DESCRIPTION
    Ce script corrige les incohÃ©rences dans la roadmap, notamment les tÃ¢ches principales
    marquÃ©es comme non complÃ©tÃ©es alors que toutes les sous-tÃ¢ches sont complÃ©tÃ©es.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap Ã  mettre Ã  jour.
    Par dÃ©faut, utilise 'Roadmap/roadmap_complete.md'.

.EXAMPLE
    .\Fix-RoadmapInconsistency.ps1 -RoadmapPath "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/Roadmap/roadmap_complete.md"

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

# Corriger l'incohÃ©rence dans la section C.2.3
$inconsistencyPattern = "##### C\.2\.3 Optimisations avancÃ©es pour l'analyse des fichiers\n- \[ \] ImplÃ©menter des optimisations avancÃ©es pour l'analyse des fichiers"
$inconsistencyReplacement = "##### C.2.3 Optimisations avancÃ©es pour l'analyse des fichiers\n- [x] ImplÃ©menter des optimisations avancÃ©es pour l'analyse des fichiers"

# Mettre Ã  jour le contenu de la roadmap
$updatedContent = $roadmapContent -replace $inconsistencyPattern, $inconsistencyReplacement

# Enregistrer le contenu mis Ã  jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise Ã  jour : $RoadmapPath" -ForegroundColor Green
Write-Host "Les incohÃ©rences suivantes ont Ã©tÃ© corrigÃ©es :" -ForegroundColor Green
Write-Host "- Section C.2.3 : TÃ¢che principale marquÃ©e comme complÃ©tÃ©e" -ForegroundColor Green
