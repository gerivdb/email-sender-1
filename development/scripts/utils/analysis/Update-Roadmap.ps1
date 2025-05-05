#Requires -Version 5.1
<#
.SYNOPSIS
    Met ÃƒÂ  jour la roadmap avec les amÃƒÂ©liorations implÃƒÂ©mentÃƒÂ©es.

.DESCRIPTION
    Ce script met ÃƒÂ  jour la roadmap avec les amÃƒÂ©liorations implÃƒÂ©mentÃƒÂ©es
    pour la dÃƒÂ©tection de format de fichiers.

.PARAMETER RoadmapPath
    Le chemin vers le fichier de roadmap ÃƒÂ  mettre ÃƒÂ  jour.
    Par dÃƒÂ©faut, utilise 'Roadmap/roadmap_perso.md'.

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

# VÃƒÂ©rifier si le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath -PathType Leaf)) {
    Write-Error "Le fichier de roadmap $RoadmapPath n'existe pas."
    return
}

# Lire le contenu du fichier de roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# DÃƒÂ©finir les motifs de recherche et de remplacement
$sectionPattern = '## 2\.1\.2 ImplÃƒÂ©mentation des amÃƒÂ©liorations\s+- \[ \] DÃƒÂ©velopper des algorithmes de dÃƒÂ©tection plus robustes\s+- \[ \] ImplÃƒÂ©menter l''analyse de contenu basÃƒÂ©e sur des expressions rÃƒÂ©guliÃƒÂ¨res avancÃƒÂ©es\s+- \[ \] Ajouter la dÃƒÂ©tection basÃƒÂ©e sur les signatures de format \(en-tÃƒÂªtes, structure\)\s+- \[ \] CrÃƒÂ©er un systÃƒÂ¨me de score pour dÃƒÂ©terminer le format le plus probable\s+- \[ \] ImplÃƒÂ©menter la dÃƒÂ©tection des encodages de caractÃƒÂ¨res'

$sectionReplacement = @"
## 2.1.2 ImplÃƒÂ©mentation des amÃƒÂ©liorations
- [x] DÃƒÂ©velopper des algorithmes de dÃƒÂ©tection plus robustes
- [x] ImplÃƒÂ©menter l'analyse de contenu basÃƒÂ©e sur des expressions rÃƒÂ©guliÃƒÂ¨res avancÃƒÂ©es
- [x] Ajouter la dÃƒÂ©tection basÃƒÂ©e sur les signatures de format (en-tÃƒÂªtes, structure)
- [x] CrÃƒÂ©er un systÃƒÂ¨me de score pour dÃƒÂ©terminer le format le plus probable
- [x] ImplÃƒÂ©menter la dÃƒÂ©tection des encodages de caractÃƒÂ¨res
"@

# Mettre ÃƒÂ  jour le contenu de la roadmap
$updatedContent = $roadmapContent -replace $sectionPattern, $sectionReplacement

# Enregistrer le contenu mis ÃƒÂ  jour
$updatedContent | Out-File -FilePath $RoadmapPath -Encoding utf8

Write-Host "Roadmap mise ÃƒÂ  jour : $RoadmapPath" -ForegroundColor Green

# Afficher les modifications
Write-Host "`nModifications apportÃƒÂ©es :" -ForegroundColor Cyan
Write-Host "  Section 2.1.2 ImplÃƒÂ©mentation des amÃƒÂ©liorations mise ÃƒÂ  jour" -ForegroundColor White
Write-Host "  Toutes les tÃƒÂ¢ches marquÃƒÂ©es comme terminÃƒÂ©es" -ForegroundColor White
