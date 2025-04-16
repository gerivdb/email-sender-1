#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour la progression de la section 1.1.2.1 dans la roadmap.
.DESCRIPTION
    Ce script met à jour la progression de la section 1.1.2.1 dans la roadmap
    pour indiquer que la tâche est terminée.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap à mettre à jour.
.EXAMPLE
    .\Update-RoadmapProgress.ps1 -RoadmapPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"
.NOTES
    Author: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"
)

# Vérifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath -PathType Leaf)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu du fichier roadmap
$content = Get-Content -Path $RoadmapPath -Raw

# Mettre à jour la progression de la section 1.1.2.1
$pattern = '(### 1\.1\.2\.1 Système d''inventaire et de classification des scripts\s+\*\*Complexité\*\*:.*\s+\*\*Temps estimé\*\*:.*\s+\*\*Progression\*\*:) \d+% - \*.*\*'
$replacement = '$1 100% - *Terminé*'

$updatedContent = $content -replace $pattern, $replacement

# Sauvegarder une copie de sauvegarde du fichier roadmap original
$backupPath = "$RoadmapPath.bak3"
Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
Write-Host "Copie de sauvegarde créée: $backupPath" -ForegroundColor Green

# Écrire le contenu mis à jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $updatedContent -Encoding UTF8
Write-Host "Roadmap mise à jour avec succès: $RoadmapPath" -ForegroundColor Green

# Afficher un résumé des modifications
Write-Host "`nRésumé des modifications:" -ForegroundColor Cyan
Write-Host "- Mise à jour de la progression de la section '1.1.2.1 Système d'inventaire et de classification des scripts' à 100% - Terminé" -ForegroundColor White
