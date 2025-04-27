<#
.SYNOPSIS
    Initialise la structure de maintenance pour le projet EMAIL_SENDER_1.

.DESCRIPTION
    Ce script crÃ©e la structure de dossiers et les fichiers nÃ©cessaires pour la maintenance du projet.
    Il gÃ©nÃ¨re les dossiers organize, cleanup, migrate et docs, ainsi que les README correspondants.

.PARAMETER Force
    Si spÃ©cifiÃ©, le script Ã©crase les fichiers existants sans demander de confirmation.

.EXAMPLE
    .\init-maintenance.ps1

.EXAMPLE
    .\init-maintenance.ps1 -Force

.NOTES
    Auteur: Maintenance Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# DÃ©finir le rÃ©pertoire de base
$baseDir = $PSScriptRoot

# DÃ©finir les dossiers Ã  crÃ©er
$folders = @(
    "organize",
    "cleanup",
    "migrate",
    "docs",
    "backups",
    "logs"
)

# CrÃ©er les dossiers
foreach ($folder in $folders) {
    $folderPath = Join-Path -Path $baseDir -ChildPath $folder

    if (-not (Test-Path -Path $folderPath)) {
        if ($PSCmdlet.ShouldProcess($folderPath, "CrÃ©er le dossier")) {
            New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
            Write-Host "Dossier crÃ©Ã© : $folderPath" -ForegroundColor Green
        }
    } else {
        Write-Host "Le dossier existe dÃ©jÃ  : $folderPath" -ForegroundColor Gray
    }
}

# CrÃ©er le README principal
$readmePath = Join-Path -Path $baseDir -ChildPath "README.md"
$readmeContent = @'
# Scripts de maintenance pour EMAIL_SENDER_1

Ce rÃ©pertoire contient des scripts pour la maintenance du projet EMAIL_SENDER_1.

## Structure

- **organize/** - Scripts pour organiser les fichiers et dossiers
- **cleanup/** - Scripts pour nettoyer les fichiers inutiles
- **migrate/** - Scripts pour migrer des fichiers d'un rÃ©pertoire Ã  un autre
- **docs/** - Documentation sur la maintenance
- **backups/** - Sauvegardes crÃ©Ã©es avant les opÃ©rations de maintenance
- **logs/** - Journaux des opÃ©rations de maintenance

## Utilisation avec Hygen

Ce projet utilise [Hygen](https://www.hygen.io/) pour gÃ©nÃ©rer des scripts de maintenance.

### GÃ©nÃ©ration de scripts d'organisation

```bash
hygen maintenance organize
```

### GÃ©nÃ©ration de scripts de nettoyage

```bash
hygen maintenance cleanup
```

### GÃ©nÃ©ration de scripts de migration

```bash
hygen maintenance migrate
```

## Bonnes pratiques

1. Toujours exÃ©cuter les scripts en mode simulation (`-DryRun`) avant de les exÃ©cuter rÃ©ellement
2. CrÃ©er des sauvegardes avant d'effectuer des opÃ©rations potentiellement destructives
3. Journaliser toutes les actions effectuÃ©es
4. Tester les scripts dans un environnement de dÃ©veloppement avant de les utiliser en production
5. Documenter les scripts et leurs fonctionnalitÃ©s

## Auteur

Maintenance Team
'@

if (-not (Test-Path -Path $readmePath) -or $Force) {
    if ($PSCmdlet.ShouldProcess($readmePath, "CrÃ©er le README")) {
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
        Write-Host "README crÃ©Ã© : $readmePath" -ForegroundColor Green
    }
} else {
    Write-Host "Le README existe dÃ©jÃ  : $readmePath" -ForegroundColor Gray
}

# CrÃ©er les README pour chaque dossier
$folderReadmes = @{
    "organize" = @'
# Scripts d'organisation

Ce rÃ©pertoire contient des scripts pour organiser les fichiers et dossiers du projet.

## Utilisation avec Hygen

```bash
hygen maintenance organize
```

## Bonnes pratiques

1. Toujours exÃ©cuter les scripts en mode simulation (`-DryRun`) avant de les exÃ©cuter rÃ©ellement
2. CrÃ©er des sauvegardes avant d'effectuer des opÃ©rations potentiellement destructives
3. Journaliser toutes les actions effectuÃ©es
'@

    "cleanup"  = @'
# Scripts de nettoyage

Ce rÃ©pertoire contient des scripts pour nettoyer les fichiers inutiles du projet.

## Utilisation avec Hygen

```bash
hygen maintenance cleanup
```

## Types de nettoyage disponibles

- **temp** : Fichiers temporaires (*.tmp, *.temp, ~*, *.cache)
- **logs** : Fichiers de journalisation (*.log, *.log.*, *_log_*, *.trace)
- **backups** : Fichiers de sauvegarde (*.bak, *.backup, *_backup_*, *.old)
- **duplicates** : Fichiers dupliquÃ©s (*_copy*.*, *_copie*.*, * - Copy*.*, * - Copie*.*)
- **empty** : Dossiers vides
- **custom** : Motif personnalisÃ©
'@

    "migrate"  = @'
# Scripts de migration

Ce rÃ©pertoire contient des scripts pour migrer des fichiers d'un rÃ©pertoire Ã  un autre.

## Utilisation avec Hygen

```bash
hygen maintenance migrate
```

## Bonnes pratiques

1. Toujours exÃ©cuter les scripts en mode simulation (`-DryRun`) avant de les exÃ©cuter rÃ©ellement
2. CrÃ©er des sauvegardes avant d'effectuer des opÃ©rations potentiellement destructives
3. Journaliser toutes les actions effectuÃ©es
4. Tester les scripts de rollback aprÃ¨s une migration rÃ©ussie
'@

    "docs"     = @'
# Documentation de maintenance

Ce rÃ©pertoire contient la documentation sur la maintenance du projet.

## Contenu

- ProcÃ©dures de maintenance
- Guides de dÃ©pannage
- Bonnes pratiques
- Historique des opÃ©rations de maintenance
'@

    "backups"  = @'
# Sauvegardes de maintenance

Ce rÃ©pertoire contient les sauvegardes crÃ©Ã©es avant les opÃ©rations de maintenance.

## Nomenclature

Les sauvegardes suivent gÃ©nÃ©ralement le format suivant :
- `backup_<type>_<date>_<heure>.zip`

Exemple : `backup_cleanup_20230815_123045.zip`
'@

    "logs"     = @'
# Journaux de maintenance

Ce rÃ©pertoire contient les journaux des opÃ©rations de maintenance.

## Nomenclature

Les journaux suivent gÃ©nÃ©ralement le format suivant :
- `<type>_<date>_<heure>.log`

Exemple : `cleanup_20230815_123045.log`
'@
}

foreach ($folder in $folders) {
    $readmePath = Join-Path -Path (Join-Path -Path $baseDir -ChildPath $folder) -ChildPath "README.md"

    if (-not (Test-Path -Path $readmePath) -or $Force) {
        if ($PSCmdlet.ShouldProcess($readmePath, "CrÃ©er le README")) {
            Set-Content -Path $readmePath -Value $folderReadmes[$folder] -Encoding UTF8
            Write-Host "README crÃ©Ã© : $readmePath" -ForegroundColor Green
        }
    } else {
        Write-Host "Le README existe dÃ©jÃ  : $readmePath" -ForegroundColor Gray
    }
}

Write-Host "Initialisation de la structure de maintenance terminÃ©e." -ForegroundColor Cyan
