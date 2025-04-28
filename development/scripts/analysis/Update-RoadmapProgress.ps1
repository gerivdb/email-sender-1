#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour la progression de la section 1.1.2.1 dans la roadmap.
.DESCRIPTION
    Ce script met Ã  jour la progression de la section 1.1.2.1 dans la roadmap
    pour indiquer que la tÃ¢che est terminÃ©e.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap Ã  mettre Ã  jour.
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

# VÃ©rifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath -PathType Leaf)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu du fichier roadmap
$content = Get-Content -Path $RoadmapPath -Raw

# Mettre Ã  jour la progression de la section 1.1.2.1
$pattern = '(### 1\.1\.2\.1 SystÃ¨me d''inventaire et de classification des scripts\s+\*\*ComplexitÃ©\*\*:.*\s+\*\*Temps estimÃ©\*\*:.*\s+\*\*Progression\*\*:) \d+% - \*.*\*'
$replacement = '$1 100% - *TerminÃ©*'

$updatedContent = $content -replace $pattern, $replacement

# Sauvegarder une copie de sauvegarde du fichier roadmap original
$backupPath = "$RoadmapPath.bak3"
Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
Write-Host "Copie de sauvegarde crÃ©Ã©e: $backupPath" -ForegroundColor Green

# Ã‰crire le contenu mis Ã  jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $updatedContent -Encoding UTF8
Write-Host "Roadmap mise Ã  jour avec succÃ¨s: $RoadmapPath" -ForegroundColor Green

# Afficher un rÃ©sumÃ© des modifications
Write-Host "`nRÃ©sumÃ© des modifications:" -ForegroundColor Cyan
Write-Host "- Mise Ã  jour de la progression de la section '1.1.2.1 SystÃ¨me d'inventaire et de classification des scripts' Ã  100% - TerminÃ©" -ForegroundColor White
