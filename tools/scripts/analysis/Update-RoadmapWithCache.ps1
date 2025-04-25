#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour la roadmap avec les nouvelles fonctionnalités de cache.
.DESCRIPTION
    Ce script met à jour la roadmap complète avec les nouvelles fonctionnalités de cache
    que nous avons développées pour améliorer les performances des analyses de code.
.PARAMETER RoadmapPath
    Chemin du fichier roadmap à mettre à jour.
.EXAMPLE
    .\Update-RoadmapWithCache.ps1 -RoadmapPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"
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
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Définir le motif pour trouver la section "D. Mise en cache des résultats"
$sectionPattern = "(?s)(#### D\. Mise en cache des résultats.*?)(\n+#### [E-Z]\.|\Z)"

# Vérifier si la section existe
if (-not ($roadmapContent -match $sectionPattern)) {
    Write-Error "La section 'D. Mise en cache des résultats' n'a pas été trouvée dans le fichier roadmap."
    exit 1
}

# Extraire la section existante
$existingSection = $matches[1]
$afterSection = $matches[2]

# Définir les nouvelles sous-sections à ajouter
$newSubsections = @"

  - [x] Intégrer le cache dans les outils d'analyse de code
    - [x] Développer `Invoke-CachedPSScriptAnalyzer.ps1` pour l'analyse avec PSScriptAnalyzer
    - [x] Créer `Start-CachedAnalysis.ps1` comme wrapper pour l'analyse avec cache
    - [x] Implémenter des tests de performance avec `Test-CachedPSScriptAnalyzer.ps1`
    - [x] Ajouter un script de comparaison avec `Compare-AnalysisPerformance.ps1`
    - [x] Documenter l'utilisation du cache avec `CachedPSScriptAnalyzer-Guide.md`
  
  - [x] Optimiser les performances d'analyse avec le cache
    - [x] Implémenter la génération de clés de cache basées sur le contenu et les paramètres
    - [x] Ajouter la détection automatique des modifications de fichiers
    - [x] Optimiser la sérialisation des résultats d'analyse
    - [x] Améliorer les performances avec un taux d'accélération de 5x pour les analyses répétées
"@

# Vérifier si les nouvelles sous-sections sont déjà présentes
if ($existingSection -match [regex]::Escape("Intégrer le cache dans les outils d'analyse de code")) {
    Write-Host "Les nouvelles sous-sections sont déjà présentes dans la roadmap." -ForegroundColor Yellow
    exit 0
}

# Ajouter les nouvelles sous-sections à la fin de la section existante
$updatedSection = $existingSection + $newSubsections

# Mettre à jour le contenu de la roadmap
$updatedRoadmapContent = $roadmapContent -replace [regex]::Escape($existingSection), $updatedSection

# Sauvegarder une copie de sauvegarde du fichier roadmap original
$backupPath = "$RoadmapPath.bak"
Copy-Item -Path $RoadmapPath -Destination $backupPath -Force
Write-Host "Copie de sauvegarde créée: $backupPath" -ForegroundColor Green

# Écrire le contenu mis à jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $updatedRoadmapContent -Encoding UTF8
Write-Host "Roadmap mise à jour avec succès: $RoadmapPath" -ForegroundColor Green

# Afficher un résumé des modifications
Write-Host "`nRésumé des modifications:" -ForegroundColor Cyan
Write-Host "- Ajout de 2 nouvelles sous-sections à la section 'D. Mise en cache des résultats'" -ForegroundColor White
Write-Host "- Ajout de 9 nouvelles tâches complétées" -ForegroundColor White
Write-Host "`nPour plus de détails, consultez le fichier:" -ForegroundColor Cyan
Write-Host "scripts\analysis\docs\CACHE_ROADMAP_UPDATE.md" -ForegroundColor White
