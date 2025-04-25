#Requires -Version 5.1
<#
.SYNOPSIS
    Met à jour la roadmap avec l'implémentation de TestOmnibus.
.DESCRIPTION
    Ce script met à jour la roadmap du projet avec l'implémentation de TestOmnibus.
.PARAMETER RoadmapPath
    Le chemin du fichier roadmap à mettre à jour.
.EXAMPLE
    .\Update-Roadmap.ps1 -RoadmapPath "Roadmap\roadmap_perso_fixed.md"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RoadmapPath
)

# Vérifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Le fichier roadmap n'a pas été trouvé à l'emplacement: $RoadmapPath"
    return 1
}

# Lire le contenu du fichier roadmap
$roadmapContent = Get-Content -Path $RoadmapPath -Raw

# Créer l'entrée pour TestOmnibus
$today = Get-Date -Format "dd/MM/yyyy"
$testOmnibusEntry = @"

## 2.4 Implémentation de TestOmnibus pour l'analyse des tests Python
**Complexité**: Moyenne
**Temps estimé**: 3-5 jours
**Progression**: 100% - *Terminé le $today*
**Date de début**: $today
**Date d'achèvement**: $today

### 2.4.1 Développement du script principal
- [x] Créer le script Python run_testomnibus.py
- [x] Implémenter l'exécution parallèle des tests
- [x] Développer l'analyse des erreurs
- [x] Créer la génération de rapports HTML

### 2.4.2 Développement du wrapper PowerShell
- [x] Créer le script Invoke-TestOmnibus.ps1
- [x] Implémenter la vérification des dépendances
- [x] Développer l'interface utilisateur
- [x] Créer les options avancées

### 2.4.3 Intégration avec le système d'apprentissage des erreurs
- [x] Créer le script Integrate-ErrorLearning.ps1
- [x] Implémenter la sauvegarde des erreurs
- [x] Développer l'analyse des patterns d'erreur
- [x] Créer les suggestions de correction

### 2.4.4 Documentation et exemples
- [x] Créer le fichier README.md
- [x] Documenter les options disponibles
- [x] Créer des exemples d'utilisation
- [x] Documenter l'intégration avec CI/CD
"@

# Ajouter l'entrée à la roadmap
$sectionToFind = "# 2. TÂCHES DE PRIORITÉ MOYENNE"
$updatedRoadmapContent = $roadmapContent -replace "($sectionToFind)", "`$1$testOmnibusEntry"

# Écrire le contenu mis à jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $updatedRoadmapContent

Write-Host "Roadmap mise à jour avec succès." -ForegroundColor Green
return 0
