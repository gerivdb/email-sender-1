# Script pour supprimer les fichiers redondants ou obsolètes dans Roadmap/scripts
# Ce script restaure les fichiers principaux depuis le dossier archive et supprime les fichiers redondants

# Configuration
$scriptsFolder = "Roadmap\scripts"
$archiveFolder = "Roadmap\scripts\archive"

# Liste des fichiers principaux à restaurer
$mainFiles = @(
    "RoadmapManager.ps1",
    "RoadmapAnalyzer.ps1",
    "RoadmapGitUpdater.ps1",
    "OrganizeRoadmapScripts.ps1"
)

# Liste des fichiers à conserver (en plus des fichiers principaux)
$filesToKeep = @(
    "README.md",
    "CleanupRoadmapFiles.ps1"
)

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
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
}

# Fonction pour restaurer un fichier depuis le dossier archive
function Restore-FileFromArchive {
    param (
        [string]$FileName
    )
    
    $sourcePath = Join-Path -Path $archiveFolder -ChildPath $FileName
    $destinationPath = Join-Path -Path $scriptsFolder -ChildPath $FileName
    
    if (Test-Path -Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destinationPath -Force
        Write-Log "Fichier restauré depuis l'archive: $FileName" "SUCCESS"
        return $true
    }
    else {
        Write-Log "Fichier non trouvé dans l'archive: $FileName" "WARNING"
        return $false
    }
}

# Fonction pour supprimer un fichier
function Remove-RedundantFile {
    param (
        [string]$FilePath
    )
    
    if (Test-Path -Path $FilePath) {
        Remove-Item -Path $FilePath -Force
        Write-Log "Fichier supprimé: $FilePath" "SUCCESS"
        return $true
    }
    else {
        Write-Log "Fichier non trouvé: $FilePath" "WARNING"
        return $false
    }
}

# Restaurer les fichiers principaux depuis le dossier archive
Write-Log "Restauration des fichiers principaux depuis l'archive..." "INFO"
foreach ($file in $mainFiles) {
    Restore-FileFromArchive -FileName $file
}

# Obtenir tous les fichiers dans le dossier scripts
$allFiles = Get-ChildItem -Path $scriptsFolder -File | Where-Object { $_.Name -ne "README.md" }

# Supprimer les fichiers redondants ou obsolètes
Write-Log "Suppression des fichiers redondants ou obsolètes..." "INFO"
$filesToRemove = $allFiles | Where-Object { 
    $_.Name -notin $mainFiles -and 
    $_.Name -notin $filesToKeep -and
    $_.Name -notlike "*.md"
}

foreach ($file in $filesToRemove) {
    Remove-RedundantFile -FilePath $file.FullName
}

# Mettre à jour le fichier README.md
$readmePath = Join-Path -Path $scriptsFolder -ChildPath "README.md"
$readmeContent = @"
# Scripts de gestion de la roadmap

Ce dossier contient les scripts principaux pour la gestion de la roadmap du projet.

## Fichiers principaux

- `RoadmapManager.ps1` - Script principal de gestion de la roadmap
- `RoadmapAnalyzer.ps1` - Analyse et génération de rapports
- `RoadmapGitUpdater.ps1` - Intégration avec Git pour mettre à jour la roadmap
- `CleanupRoadmapFiles.ps1` - Nettoyage et organisation des fichiers
- `OrganizeRoadmapScripts.ps1` - Organisation des scripts

## Utilisation

Pour accéder à toutes les fonctionnalités, exécutez :

```powershell
.\RoadmapManager.ps1
```

## Structure des dossiers

- `scripts/` - Scripts principaux
- `scripts/archive/` - Versions antérieures et scripts obsolètes
- `scripts/backup/` - Sauvegardes automatiques

## Fichiers de roadmap

- `roadmap_perso.md` - Fichier principal de la roadmap
- `roadmap_perso_fixed.md` - Version corrigée de la roadmap (encodage UTF-8)

## Nettoyage

Ce dossier a été nettoyé et organisé le $(Get-Date -Format "dd/MM/yyyy") pour éliminer les doublons et les fichiers obsolètes.
"@

Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
Write-Log "Fichier README.md mis à jour" "SUCCESS"

Write-Log "Nettoyage terminé" "SUCCESS"
