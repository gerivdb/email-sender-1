# Script de nettoyage des fichiers de roadmap
# Ce script déplace tous les fichiers liés à la roadmap dans le sous-dossier Roadmap
# et supprime les doublons

# Configuration
$roadmapFolder = "Roadmap"
$mainFolder = "."

# Vérifier si le dossier Roadmap existe
if (-not (Test-Path -Path $roadmapFolder)) {
    New-Item -Path $roadmapFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier '$roadmapFolder' créé." -ForegroundColor Green
}

# Liste des fichiers liés à la roadmap
$roadmapFiles = @(
    "roadmap_perso.md",
    "RoadmapAdmin.ps1",
    "AugmentExecutor.ps1",
    "RestartAugment.ps1",
    "StartRoadmapExecution.ps1",
    "RoadmapAnalyzer.ps1",
    "RoadmapGitUpdater.ps1",
    "RoadmapManager.ps1",
    "OrganizeRoadmapScripts.ps1",
    "OrganizeRoadmapScriptsSimple.ps1",
    "OrganizeRoadmapScriptsBasic.ps1"
)

# Trouver tous les fichiers liés à la roadmap dans le dossier principal
$otherRoadmapFiles = Get-ChildItem -Path $mainFolder -File | Where-Object { 
    ($_.Name -like "*roadmap*" -or $_.Name -like "*Roadmap*") -and 
    $_.Name -ne "CleanupRoadmapFiles.ps1" -and
    -not $_.FullName.StartsWith((Resolve-Path $roadmapFolder).Path)
}

# Combiner les listes de fichiers
$allRoadmapFiles = $roadmapFiles + $otherRoadmapFiles.Name | Select-Object -Unique

# Déplacer les fichiers vers le dossier Roadmap
foreach ($file in $allRoadmapFiles) {
    $sourcePath = Join-Path -Path $mainFolder -ChildPath $file
    $destinationPath = Join-Path -Path $roadmapFolder -ChildPath $file
    
    if (Test-Path -Path $sourcePath) {
        # Vérifier si le fichier existe déjà dans le dossier Roadmap
        if (Test-Path -Path $destinationPath) {
            # Comparer les dates de modification
            $sourceFile = Get-Item -Path $sourcePath
            $destinationFile = Get-Item -Path $destinationPath
            
            if ($sourceFile.LastWriteTime -gt $destinationFile.LastWriteTime) {
                # Le fichier source est plus récent, le remplacer
                Move-Item -Path $sourcePath -Destination $destinationPath -Force
                Write-Host "Fichier '$file' remplacé dans le dossier '$roadmapFolder' (version plus récente)." -ForegroundColor Yellow
            }
            else {
                # Le fichier destination est plus récent ou identique, supprimer le fichier source
                Remove-Item -Path $sourcePath -Force
                Write-Host "Fichier '$file' supprimé du dossier principal (version plus ancienne ou identique)." -ForegroundColor Yellow
            }
        }
        else {
            # Le fichier n'existe pas dans le dossier Roadmap, le déplacer
            Move-Item -Path $sourcePath -Destination $destinationPath
            Write-Host "Fichier '$file' déplacé vers le dossier '$roadmapFolder'." -ForegroundColor Green
        }
    }
}

# Créer un fichier README si nécessaire
$readmePath = Join-Path -Path $roadmapFolder -ChildPath "README.md"
if (-not (Test-Path -Path $readmePath)) {
    $readmeContent = @"
# Roadmap - Scripts et processus

Ce dossier contient tous les scripts liés à la roadmap et à son exécution automatique.

## Fichiers principaux

- `roadmap_perso.md` - La roadmap elle-même
- `RoadmapAdmin.ps1` - Script principal d'administration de la roadmap
- `AugmentExecutor.ps1` - Script d'exécution des tâches avec Augment
- `RestartAugment.ps1` - Script de redémarrage en cas d'échec
- `StartRoadmapExecution.ps1` - Script de démarrage rapide
- `RoadmapAnalyzer.ps1` - Script d'analyse de la roadmap
- `RoadmapGitUpdater.ps1` - Script de mise à jour de la roadmap en fonction des commits Git
- `RoadmapManager.ps1` - Script de gestion de la roadmap

## Utilisation

Pour accéder à toutes les fonctionnalités, exécutez :

```powershell
.\RoadmapManager.ps1
```

## Fonctionnalités

1. **Exécution automatique de la roadmap**
   - Analyse la roadmap pour identifier les tâches à faire
   - Exécute automatiquement les tâches avec Augment
   - Met à jour la roadmap pour marquer les tâches comme terminées
   - Passe automatiquement à la tâche suivante

2. **Analyse de la roadmap**
   - Calcule la progression globale et détaillée
   - Génère des rapports HTML, JSON et des graphiques
   - Visualise l'avancement des tâches

3. **Mise à jour basée sur Git**
   - Analyse les commits Git pour identifier les tâches terminées
   - Met à jour automatiquement la roadmap en fonction des commits
   - Génère des rapports sur les correspondances trouvées

4. **Gestion des échecs**
   - Détecte les échecs d'Augment
   - Relance automatiquement les tâches en cas d'échec
   - Fournit des mécanismes de récupération robustes
"@

    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Host "Fichier README créé : $readmePath" -ForegroundColor Green
}

# Créer un script de lancement rapide si nécessaire
$startScriptPath = Join-Path -Path $roadmapFolder -ChildPath "StartRoadmap.ps1"
if (-not (Test-Path -Path $startScriptPath)) {
    $startScriptContent = @"
# Script de lancement rapide pour la roadmap
# Ce script permet de lancer rapidement le gestionnaire de roadmap

# Exécuter le gestionnaire de roadmap
& ".\RoadmapManager.ps1"
"@

    Set-Content -Path $startScriptPath -Value $startScriptContent -Encoding UTF8
    Write-Host "Script de lancement rapide créé : $startScriptPath" -ForegroundColor Green
}

# Créer un raccourci dans le dossier principal
$shortcutPath = Join-Path -Path $mainFolder -ChildPath "StartRoadmap.ps1"
if (-not (Test-Path -Path $shortcutPath)) {
    $shortcutContent = @"
# Raccourci pour lancer le gestionnaire de roadmap
# Ce script permet de lancer rapidement le gestionnaire de roadmap depuis le dossier principal

# Exécuter le gestionnaire de roadmap
& ".\Roadmap\RoadmapManager.ps1"
"@

    Set-Content -Path $shortcutPath -Value $shortcutContent -Encoding UTF8
    Write-Host "Raccourci créé dans le dossier principal : $shortcutPath" -ForegroundColor Green
}

# Ouvrir le dossier Roadmap
Invoke-Item $roadmapFolder

Write-Host "Nettoyage des fichiers de roadmap terminé !" -ForegroundColor Green
Write-Host "Tous les fichiers liés à la roadmap ont été déplacés dans le dossier '$roadmapFolder'." -ForegroundColor Green
Write-Host "Pour lancer le gestionnaire de roadmap, exécutez :" -ForegroundColor Cyan
Write-Host "  - Depuis le dossier principal : .\StartRoadmap.ps1" -ForegroundColor Cyan
Write-Host "  - Depuis le dossier Roadmap : .\RoadmapManager.ps1" -ForegroundColor Cyan
