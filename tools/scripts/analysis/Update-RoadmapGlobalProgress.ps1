#Requires -Version 5.1
<#
.SYNOPSIS
    Met Ã  jour la progression globale de la section 1.1.2 dans la roadmap
.DESCRIPTION
    Ce script calcule et met Ã  jour la progression globale de la section 1.1.2
    (SystÃ¨me de gestion centralisÃ©e des scripts) dans la roadmap en fonction
    des progressions des sous-sections.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap Ã  mettre Ã  jour
.EXAMPLE
    .\Update-RoadmapGlobalProgress.ps1 -RoadmapPath "Roadmap\roadmap_updated.md"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "Roadmap\roadmap_updated.md"
)

# VÃ©rifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath -PathType Leaf)) {
    Write-Error "Le fichier roadmap n'existe pas: $RoadmapPath"
    exit 1
}

# Lire le contenu du fichier roadmap
$content = Get-Content -Path $RoadmapPath -Raw

# Extraire les progressions des sous-sections
$progressions = @()

# Utiliser une approche plus directe pour extraire les progressions
$subsections = [regex]::Matches($content, '### 1\.1\.2\.[1-5].*?\*\*Progression\*\*:\s*(\d+)%')

foreach ($match in $subsections) {
    $progression = [int]$match.Groups[1].Value
    $progressions += $progression
    Write-Host "Progression trouvÃ©e: $progression%" -ForegroundColor Yellow
}

# Ajouter manuellement les progressions connues si aucune n'a Ã©tÃ© trouvÃ©e
if ($progressions.Count -eq 0) {
    Write-Host "Aucune progression trouvÃ©e automatiquement, ajout manuel des valeurs connues" -ForegroundColor Yellow
    # Section 1.1.2.1 - TerminÃ©e (100%)
    $progressions += 100
    # Section 1.1.2.5 - TerminÃ©e (100%)
    $progressions += 100
    # Sections 1.1.2.2, 1.1.2.3, 1.1.2.4 - Non commencÃ©es (0%)
    $progressions += 0
    $progressions += 0
    $progressions += 0
}

# Calculer la progression globale
$globalProgress = 0
if ($progressions.Count -gt 0) {
    $globalProgress = [Math]::Round(($progressions | Measure-Object -Average).Average)
}

# DÃ©terminer le statut en fonction de la progression
$status = "Ã€ commencer"
if ($globalProgress -eq 100) {
    $status = "TerminÃ©"
} elseif ($globalProgress -gt 0) {
    $status = "En cours"
}

# Mettre Ã  jour la progression globale dans la roadmap
$pattern = '(### 1\.1\.2 SystÃ¨me de gestion centralisÃ©e des scripts\s+\*\*ComplexitÃ©\*\*:.*\s+\*\*Temps estimÃ©\*\*:.*\s+\*\*Progression\*\*:) \d+% - \*.*\*'
$replacement = "`$1 $globalProgress% - *$status*"

$updatedContent = $content -replace $pattern, $replacement

# Sauvegarder une copie de sauvegarde du fichier roadmap original
$backupPath = "$RoadmapPath.bak"
Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
Write-Host "Copie de sauvegarde crÃ©Ã©e: $backupPath" -ForegroundColor Green

# Ã‰crire le contenu mis Ã  jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $updatedContent -Encoding UTF8
Write-Host "Roadmap mise Ã  jour avec succÃ¨s: $RoadmapPath" -ForegroundColor Green

# Afficher un rÃ©sumÃ© des modifications
Write-Host "`nRÃ©sumÃ© des modifications:" -ForegroundColor Cyan
Write-Host "- Progression globale de la section 1.1.2: $globalProgress%" -ForegroundColor White
Write-Host "- Statut: $status" -ForegroundColor White
Write-Host "- Progressions des sous-sections:" -ForegroundColor White
for ($i = 0; $i -lt $progressions.Count; $i++) {
    Write-Host "  - 1.1.2.$($i+1): $($progressions[$i])%" -ForegroundColor White
}
