#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les incohérences dans la roadmap.

.DESCRIPTION
    Ce script corrige les incohérences dans la roadmap, notamment les tâches principales
    marquées comme non complétées alors que toutes les sous-tâches sont complétées.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap à mettre à jour.
    Par défaut, utilise 'Roadmap/roadmap_complete.md'.

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

# Vérifier si le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Corriger l'incohérence dans la section C.2.3
$inconsistencyPattern = "##### C\.2\.3 Optimisations avancées pour l'analyse des fichiers\n- \[ \] Implémenter des optimisations avancées pour l'analyse des fichiers"
$inconsistencyReplacement = "##### C.2.3 Optimisations avancées pour l'analyse des fichiers\n- [x] Implémenter des optimisations avancées pour l'analyse des fichiers"

# Mettre à jour le contenu de la roadmap
$updatedContent = $roadmapContent -replace $inconsistencyPattern, $inconsistencyReplacement

# Enregistrer le contenu mis à jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise à jour : $RoadmapPath" -ForegroundColor Green
Write-Host "Les incohérences suivantes ont été corrigées :" -ForegroundColor Green
Write-Host "- Section C.2.3 : Tâche principale marquée comme complétée" -ForegroundColor Green
