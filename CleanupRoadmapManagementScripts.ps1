# Script pour nettoyer et organiser les fichiers de gestion de roadmap
# Ce script analyse les fichiers dans docs/roadmap_management, identifie les doublons
# et les fichiers obsolètes, puis les organise correctement

# Configuration
$sourceFolder = "docs\roadmap_management"
$targetFolder = "Roadmap\scripts"
$archiveFolder = "Roadmap\scripts\archive"
$backupFolder = "Roadmap\scripts\backup"

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

# Fonction pour créer un dossier s'il n'existe pas
function Ensure-FolderExists {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Log "Dossier créé: $Path" "SUCCESS"
    }
}

# Fonction pour comparer deux fichiers et déterminer lequel est le plus récent
function Compare-FileVersions {
    param (
        [string]$File1,
        [string]$File2
    )
    
    $file1Info = Get-Item -Path $File1
    $file2Info = Get-Item -Path $File2
    
    # Comparer les dates de dernière modification
    if ($file1Info.LastWriteTime -gt $file2Info.LastWriteTime) {
        return $File1
    }
    else {
        return $File2
    }
}

# Fonction pour déplacer un fichier vers un dossier cible
function Move-FileToFolder {
    param (
        [string]$FilePath,
        [string]$TargetFolder,
        [switch]$Overwrite = $false
    )
    
    $fileName = Split-Path -Path $FilePath -Leaf
    $targetPath = Join-Path -Path $TargetFolder -ChildPath $fileName
    
    if (Test-Path -Path $targetPath) {
        if ($Overwrite) {
            # Déterminer quel fichier est le plus récent
            $newerFile = Compare-FileVersions -File1 $FilePath -File2 $targetPath
            
            if ($newerFile -eq $FilePath) {
                # Le fichier source est plus récent, le remplacer
                Move-Item -Path $FilePath -Destination $targetPath -Force
                Write-Log "Fichier remplacé (version plus récente): $fileName" "SUCCESS"
            }
            else {
                # Le fichier cible est plus récent, archiver le fichier source
                $archivePath = Join-Path -Path $archiveFolder -ChildPath $fileName
                Move-Item -Path $FilePath -Destination $archivePath -Force
                Write-Log "Fichier archivé (version plus ancienne): $fileName" "INFO"
            }
        }
        else {
            # Créer une copie avec un suffixe numérique
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
            $extension = [System.IO.Path]::GetExtension($fileName)
            $counter = 1
            
            do {
                $newFileName = "$baseName-$counter$extension"
                $newTargetPath = Join-Path -Path $TargetFolder -ChildPath $newFileName
                $counter++
            } while (Test-Path -Path $newTargetPath)
            
            Move-Item -Path $FilePath -Destination $newTargetPath
            Write-Log "Fichier renommé et déplacé: $fileName -> $newFileName" "INFO"
        }
    }
    else {
        # Le fichier n'existe pas dans le dossier cible, le déplacer simplement
        Move-Item -Path $FilePath -Destination $targetPath
        Write-Log "Fichier déplacé: $fileName" "SUCCESS"
    }
}

# Fonction pour créer une sauvegarde des fichiers avant de les modifier
function Backup-Files {
    param (
        [string]$SourceFolder
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path -Path $backupFolder -ChildPath $timestamp
    
    Ensure-FolderExists -Path $backupPath
    
    # Copier tous les fichiers du dossier source vers le dossier de sauvegarde
    Copy-Item -Path "$SourceFolder\*" -Destination $backupPath -Recurse
    
    Write-Log "Sauvegarde créée: $backupPath" "SUCCESS"
    
    return $backupPath
}

# Fonction pour identifier les groupes de fichiers similaires
function Group-SimilarFiles {
    param (
        [array]$Files
    )
    
    $groups = @{}
    
    foreach ($file in $Files) {
        $fileName = Split-Path -Path $file -Leaf
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        
        # Identifier le préfixe (ex: Update-Roadmap, Fix-RoadmapAdmin, etc.)
        if ($baseName -match "^([\w-]+)-") {
            $prefix = $Matches[1]
            
            if (-not $groups.ContainsKey($prefix)) {
                $groups[$prefix] = @()
            }
            
            $groups[$prefix] += $file
        }
        else {
            # Pour les fichiers qui ne correspondent pas au modèle, les mettre dans un groupe "Autres"
            if (-not $groups.ContainsKey("Autres")) {
                $groups["Autres"] = @()
            }
            
            $groups["Autres"] += $file
        }
    }
    
    return $groups
}

# Fonction pour déterminer le fichier principal dans un groupe
function Get-MainFile {
    param (
        [array]$Files,
        [string]$GroupName
    )
    
    # Règles pour déterminer le fichier principal
    $mainFilePatterns = @{
        "Update-Roadmap" = "^Update-Roadmap\.ps1$"
        "Fix-RoadmapAdmin" = "^Fix-RoadmapAdminScript\.ps1$"
        "Format-RoadmapText" = "^Format-RoadmapText\.ps1$"
        "Roadmap-Formatter" = "^Roadmap-Formatter\.ps1$"
        "OrganizeRoadmapScripts" = "^OrganizeRoadmapScripts\.ps1$"
    }
    
    # Fichiers principaux connus
    $knownMainFiles = @(
        "RoadmapManager.ps1",
        "RoadmapAnalyzer.ps1",
        "RoadmapGitUpdater.ps1",
        "CleanupRoadmapFiles.ps1",
        "README.md"
    )
    
    # Vérifier d'abord les fichiers principaux connus
    foreach ($file in $Files) {
        $fileName = Split-Path -Path $file -Leaf
        
        if ($knownMainFiles -contains $fileName) {
            return $file
        }
    }
    
    # Ensuite, vérifier les modèles spécifiques au groupe
    if ($mainFilePatterns.ContainsKey($GroupName)) {
        $pattern = $mainFilePatterns[$GroupName]
        
        foreach ($file in $Files) {
            $fileName = Split-Path -Path $file -Leaf
            
            if ($fileName -match $pattern) {
                return $file
            }
        }
    }
    
    # Si aucun fichier principal n'est trouvé, prendre le plus récent
    $mostRecent = $null
    $mostRecentDate = [DateTime]::MinValue
    
    foreach ($file in $Files) {
        $fileInfo = Get-Item -Path $file
        
        if ($fileInfo.LastWriteTime -gt $mostRecentDate) {
            $mostRecent = $file
            $mostRecentDate = $fileInfo.LastWriteTime
        }
    }
    
    return $mostRecent
}

# Fonction principale pour nettoyer et organiser les fichiers
function Clean-RoadmapManagementFiles {
    # Vérifier si le dossier source existe
    if (-not (Test-Path -Path $sourceFolder -PathType Container)) {
        Write-Log "Le dossier source n'existe pas: $sourceFolder" "ERROR"
        return
    }
    
    # Créer les dossiers cibles s'ils n'existent pas
    Ensure-FolderExists -Path $targetFolder
    Ensure-FolderExists -Path $archiveFolder
    Ensure-FolderExists -Path $backupFolder
    
    # Créer une sauvegarde des fichiers
    $backupPath = Backup-Files -SourceFolder $sourceFolder
    
    # Obtenir tous les fichiers du dossier source
    $files = Get-ChildItem -Path $sourceFolder -File | Select-Object -ExpandProperty FullName
    
    Write-Log "Nombre total de fichiers trouvés: $($files.Count)" "INFO"
    
    # Grouper les fichiers similaires
    $groups = Group-SimilarFiles -Files $files
    
    # Traiter chaque groupe
    foreach ($groupName in $groups.Keys) {
        $groupFiles = $groups[$groupName]
        
        Write-Log "Traitement du groupe: $groupName ($($groupFiles.Count) fichiers)" "INFO"
        
        # Déterminer le fichier principal
        $mainFile = Get-MainFile -Files $groupFiles -GroupName $groupName
        
        if ($mainFile) {
            $mainFileName = Split-Path -Path $mainFile -Leaf
            Write-Log "Fichier principal identifié: $mainFileName" "SUCCESS"
            
            # Déplacer le fichier principal vers le dossier cible
            Move-FileToFolder -FilePath $mainFile -TargetFolder $targetFolder -Overwrite
            
            # Déplacer les autres fichiers du groupe vers le dossier d'archive
            foreach ($file in $groupFiles) {
                if ($file -ne $mainFile) {
                    $fileName = Split-Path -Path $file -Leaf
                    Move-FileToFolder -FilePath $file -TargetFolder $archiveFolder
                }
            }
        }
        else {
            Write-Log "Aucun fichier principal identifié pour le groupe: $groupName" "WARNING"
            
            # Déplacer tous les fichiers du groupe vers le dossier d'archive
            foreach ($file in $groupFiles) {
                $fileName = Split-Path -Path $file -Leaf
                Move-FileToFolder -FilePath $file -TargetFolder $archiveFolder
            }
        }
    }
    
    # Créer un fichier README dans le dossier cible
    $readmePath = Join-Path -Path $targetFolder -ChildPath "README.md"
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
    Write-Log "Fichier README créé: $readmePath" "SUCCESS"
    
    # Vérifier s'il reste des fichiers dans le dossier source
    $remainingFiles = Get-ChildItem -Path $sourceFolder -File
    
    if ($remainingFiles.Count -gt 0) {
        Write-Log "Il reste $($remainingFiles.Count) fichiers dans le dossier source." "WARNING"
        Write-Log "Vous pouvez les supprimer manuellement ou les déplacer vers le dossier d'archive." "INFO"
    }
    else {
        Write-Log "Tous les fichiers ont été traités avec succès." "SUCCESS"
    }
    
    Write-Log "Nettoyage terminé. Sauvegarde disponible dans: $backupPath" "SUCCESS"
}

# Exécuter la fonction principale
Clean-RoadmapManagementFiles
