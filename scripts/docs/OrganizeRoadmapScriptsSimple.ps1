# Script simplifié d'organisation des scripts de roadmap
# Ce script réunit tous les scripts liés à la roadmap dans un dossier dédié

# Configuration
$roadmapFolder = "Roadmap"

# Créer le dossier roadmap s'il n'existe pas
if (-not (Test-Path -Path $roadmapFolder)) {
    New-Item -Path $roadmapFolder -ItemType Directory -Force | Out-Null
    Write-Host "Dossier '$roadmapFolder' créé." -ForegroundColor Green
}
else {
    Write-Host "Le dossier '$roadmapFolder' existe déjà." -ForegroundColor Cyan
}

# Liste des scripts à copier
$scripts = @(
    "roadmap_perso.md",
    "RoadmapAdmin.ps1",
    "AugmentExecutor.ps1",
    "RestartAugment.ps1",
    "StartRoadmapExecution.ps1",
    "RoadmapAnalyzer.ps1",
    "RoadmapGitUpdater.ps1",
    "RoadmapManager.ps1"
)

# Copier les scripts dans le dossier roadmap
foreach ($script in $scripts) {
    if (Test-Path -Path $script) {
        Copy-Item -Path $script -Destination "$roadmapFolder\" -Force
        Write-Host "Script '$script' copié dans le dossier '$roadmapFolder'." -ForegroundColor Green
    }
    else {
        Write-Host "Script '$script' non trouvé." -ForegroundColor Yellow
    }
}

# Rechercher d'autres scripts liés à la roadmap
$otherScripts = Get-ChildItem -Path "." -Filter "*.ps1" | Where-Object { 
    $_.Name -like "*roadmap*" -and 
    $_.Name -ne "OrganizeRoadmapScripts.ps1" -and
    $_.Name -ne "OrganizeRoadmapScriptsSimple.ps1" -and 
    $scripts -notcontains $_.Name 
}

foreach ($script in $otherScripts) {
    Copy-Item -Path $script.FullName -Destination "$roadmapFolder\" -Force
    Write-Host "Script supplémentaire '$($script.Name)' copié dans le dossier '$roadmapFolder'." -ForegroundColor Green
}

# Créer un fichier README simple
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
"@

Set-Content -Path "docs\README.md" -Value $readmeContent -Encoding UTF8
Write-Host "Fichier README créé : docs\README.md" -ForegroundColor Green

# Ouvrir le dossier roadmap
Invoke-Item $roadmapFolder

Write-Host "Organisation des scripts de roadmap terminée !" -ForegroundColor Green
Write-Host "Tous les scripts ont été copiés dans le dossier '$roadmapFolder'." -ForegroundColor Green

