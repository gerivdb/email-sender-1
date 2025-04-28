#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour la roadmap avec les amÃ©liorations implÃ©mentÃ©es.

.DESCRIPTION
    Ce script met Ã  jour la roadmap avec les amÃ©liorations implÃ©mentÃ©es
    pour la dÃ©tection de format de fichiers.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap Ã  mettre Ã  jour.
    Par dÃ©faut, utilise 'Roadmap/roadmap_perso.md'.

.EXAMPLE
    .\Update-Roadmap.ps1 -RoadmapPath "D:/DO/WEB/N8N_development/testing/tests/PROJETS/EMAIL_SENDER_1/Roadmap/roadmap_perso.md"

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_perso.md"
)

# VÃ©rifier si le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath -PathType Leaf)) {
    Write-Error "Le fichier de roadmap $RoadmapPath n'existe pas."
    return
}

# Lire le contenu du fichier de roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# DÃ©finir les motifs de recherche et de remplacement
$sectionPattern = '## 2\.1\.2 ImplÃ©mentation des amÃ©liorations\s+- \[ \] DÃ©velopper des algorithmes de dÃ©tection plus robustes\s+- \[ \] ImplÃ©menter l''analyse de contenu basÃ©e sur des expressions rÃ©guliÃ¨res avancÃ©es\s+- \[ \] Ajouter la dÃ©tection basÃ©e sur les signatures de format \(en-tÃªtes, structure\)\s+- \[ \] CrÃ©er un systÃ¨me de score pour dÃ©terminer le format le plus probable\s+- \[ \] ImplÃ©menter la dÃ©tection des encodages de caractÃ¨res'

$sectionReplacement = @"
## 2.1.2 ImplÃ©mentation des amÃ©liorations
- [x] DÃ©velopper des algorithmes de dÃ©tection plus robustes
- [x] ImplÃ©menter l'analyse de contenu basÃ©e sur des expressions rÃ©guliÃ¨res avancÃ©es
- [x] Ajouter la dÃ©tection basÃ©e sur les signatures de format (en-tÃªtes, structure)
- [x] CrÃ©er un systÃ¨me de score pour dÃ©terminer le format le plus probable
- [x] ImplÃ©menter la dÃ©tection des encodages de caractÃ¨res
"@

# Mettre Ã  jour le contenu de la roadmap
$updatedContent = $roadmapContent -replace $sectionPattern, $sectionReplacement

# Enregistrer le contenu mis Ã  jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise Ã  jour : $RoadmapPath" -ForegroundColor Green

# Afficher les modifications
Write-Host "`nModifications apportÃ©es :" -ForegroundColor Cyan
Write-Host "  Section 2.1.2 ImplÃ©mentation des amÃ©liorations mise Ã  jour" -ForegroundColor White
Write-Host "  Toutes les tÃ¢ches marquÃ©es comme terminÃ©es" -ForegroundColor White
