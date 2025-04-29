# Script de nettoyage des fichiers de roadmap
# Ce script nettoie et organise les fichiers liÃ©s Ã  la roadmap

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }

    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"

        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }

        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
    # Script de nettoyage des fichiers de roadmap
    # Ce script dÃ©place tous les fichiers liÃ©s Ã  la roadmap dans le sous-dossier Roadmap
    # et supprime les doublons

    # Configuration
    $roadmapFolder = "Roadmap"
    $mainFolder = "."

    # VÃ©rifier si le dossier Roadmap existe
    if (-not (Test-Path -Path $roadmapFolder)) {
        New-Item -Path $roadmapFolder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier '$roadmapFolder' crÃ©Ã©." -ForegroundColor Green
    }

    # Liste des fichiers liÃ©s Ã  la roadmap
    $roadmapFiles = @(
        "Roadmap\roadmap_perso.md",
        "RoadmapAdmin.ps1",
        "AugmentExecutor.ps1",
        "RestartAugment.ps1",
        "StartRoadmapExecution.ps1",
        "RoadmapAnalyzer.ps1",
        "RoadmapGitUpdater.ps1",
        "roadmap-manager.ps1",
        "OrganizeRoadmapScripts.ps1",
        "OrganizeRoadmapScriptsSimple.ps1",
        "OrganizeRoadmapScriptsBasic.ps1"
    )

    # Trouver tous les fichiers liÃ©s Ã  la roadmap dans le dossier principal
    $otherRoadmapFiles = Get-ChildItem -Path $mainFolder -File | Where-Object {
    ($_.Name -like "*roadmap*" -or $_.Name -like "*Roadmap*") -and
        $_.Name -ne "CleanupRoadmapFiles.ps1" -and
        -not $_.FullName.StartsWith((Resolve-Path $roadmapFolder).Path)
    }

    # Combiner les listes de fichiers
    $allRoadmapFiles = $roadmapFiles + $otherRoadmapFiles.Name | Select-Object -Unique

    # DÃ©placer les fichiers vers le dossier Roadmap
    foreach ($file in $allRoadmapFiles) {
        $sourcePath = Join-Path -Path $mainFolder -ChildPath $file
        $destinationPath = Join-Path -Path $roadmapFolder -ChildPath $file

        if (Test-Path -Path $sourcePath) {
            # VÃ©rifier si le fichier existe dÃ©jÃ  dans le dossier Roadmap
            if (Test-Path -Path $destinationPath) {
                # Comparer les dates de modification
                $sourceFile = Get-Item -Path $sourcePath
                $destinationFile = Get-Item -Path $destinationPath

                if ($sourceFile.LastWriteTime -gt $destinationFile.LastWriteTime) {
                    # Le fichier source est plus rÃ©cent, le remplacer
                    Move-Item -Path $sourcePath -Destination $destinationPath -Force
                    Write-Host "Fichier '$file' remplacÃ© dans le dossier '$roadmapFolder' (version plus rÃ©cente)." -ForegroundColor Yellow
                } else {
                    # Le fichier destination est plus rÃ©cent ou identique, supprimer le fichier source
                    Remove-Item -Path $sourcePath -Force
                    Write-Host "Fichier '$file' supprimÃ© du dossier principal (version plus ancienne ou identique)." -ForegroundColor Yellow
                }
            } else {
                # Le fichier n'existe pas dans le dossier Roadmap, le dÃ©placer
                Move-Item -Path $sourcePath -Destination $destinationPath
                Write-Host "Fichier '$file' dÃ©placÃ© vers le dossier '$roadmapFolder'." -ForegroundColor Green
            }
        }
    }

    # CrÃ©er un fichier README si nÃ©cessaire
    $readmePath = Join-Path -Path $roadmapFolder -ChildPath "README.md"
    if (-not (Test-Path -Path $readmePath)) {
        $readmeContent = @"
# Roadmap - Scripts et processus

Ce dossier contient tous les scripts liÃ©s Ã  la roadmap et Ã  son exÃ©cution automatique.

## Fichiers principaux

- `"Roadmap\roadmap_perso.md"` - La roadmap elle-mÃªme
- `RoadmapAdmin.ps1` - Script principal d'administration de la roadmap
- `AugmentExecutor.ps1` - Script d'exÃ©cution des tÃ¢ches avec Augment
- `RestartAugment.ps1` - Script de redÃ©marrage en cas d'Ã©chec
- `StartRoadmapExecution.ps1` - Script de dÃ©marrage rapide
- `RoadmapAnalyzer.ps1` - Script d'analyse de la roadmap
- `RoadmapGitUpdater.ps1` - Script de mise Ã  jour de la roadmap en fonction des commits Git
- `roadmap-manager.ps1` - Script de gestion de la roadmap

## Utilisation

Pour accÃ©der Ã  toutes les fonctionnalitÃ©s, exÃ©cutez :

```powershell
.\roadmap-manager.ps1
```

## FonctionnalitÃ©s

1. **ExÃ©cution automatique de la roadmap**
   - Analyse la roadmap pour identifier les tÃ¢ches Ã  faire
   - ExÃ©cute automatiquement les tÃ¢ches avec Augment
   - Met Ã  jour la roadmap pour marquer les tÃ¢ches comme terminÃ©es
   - Passe automatiquement Ã  la tÃ¢che suivante

2. **Analyse de la roadmap**
   - Calcule la progression globale et dÃ©taillÃ©e
   - GÃ©nÃ¨re des rapports HTML, JSON et des graphiques
   - Visualise l'avancement des tÃ¢ches

3. **Mise Ã  jour basÃ©e sur Git**
   - Analyse les commits Git pour identifier les tÃ¢ches terminÃ©es
   - Met Ã  jour automatiquement la roadmap en fonction des commits
   - GÃ©nÃ¨re des rapports sur les correspondances trouvÃ©es

4. **Gestion des Ã©checs**
   - DÃ©tecte les Ã©checs d'Augment
   - Relance automatiquement les tÃ¢ches en cas d'Ã©chec
   - Fournit des mÃ©canismes de rÃ©cupÃ©ration robustes
"@

        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
        Write-Host "Fichier README crÃ©Ã© : $readmePath" -ForegroundColor Green
    }

    # CrÃ©er un script de lancement rapide si nÃ©cessaire
    $startScriptPath = Join-Path -Path $roadmapFolder -ChildPath "StartRoadmap.ps1"
    if (-not (Test-Path -Path $startScriptPath)) {
        $startScriptContent = @"
# Script de lancement rapide pour la roadmap
# Ce script permet de lancer rapidement le gestionnaire de roadmap

# ExÃ©cuter le gestionnaire de roadmap
& ".\roadmap-manager.ps1"
"@

        Set-Content -Path $startScriptPath -Value $startScriptContent -Encoding UTF8
        Write-Host "Script de lancement rapide crÃ©Ã© : $startScriptPath" -ForegroundColor Green
    }

    # CrÃ©er un raccourci dans le dossier principal
    $shortcutPath = Join-Path -Path $mainFolder -ChildPath "StartRoadmap.ps1"
    if (-not (Test-Path -Path $shortcutPath)) {
        $shortcutContent = @"
# Raccourci pour lancer le gestionnaire de roadmap
# Ce script permet de lancer rapidement le gestionnaire de roadmap depuis le dossier principal

# ExÃ©cuter le gestionnaire de roadmap
& "..\D"
"@

        Set-Content -Path $shortcutPath -Value $shortcutContent -Encoding UTF8
        Write-Host "Raccourci crÃ©Ã© dans le dossier principal : $shortcutPath" -ForegroundColor Green
    }

    # Ouvrir le dossier Roadmap
    Invoke-Item $roadmapFolder

    Write-Host "Nettoyage des fichiers de roadmap terminÃ© !" -ForegroundColor Green
    Write-Host "Tous les fichiers liÃ©s Ã  la roadmap ont Ã©tÃ© dÃ©placÃ©s dans le dossier '$roadmapFolder'." -ForegroundColor Green
    Write-Host "Pour lancer le gestionnaire de roadmap, exÃ©cutez :" -ForegroundColor Cyan
    Write-Host "  - Depuis le dossier principal : .\StartRoadmap.ps1" -ForegroundColor Cyan
    Write-Host "  - Depuis le dossier Roadmap : .\roadmap-manager.ps1" -ForegroundColor Cyan


} catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
} finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}

