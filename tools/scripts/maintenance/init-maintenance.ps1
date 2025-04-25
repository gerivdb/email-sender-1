<#
.SYNOPSIS
    Initialise la structure de maintenance pour le projet EMAIL_SENDER_1.

.DESCRIPTION
    Ce script crée la structure de dossiers et les fichiers nécessaires pour la maintenance du projet.
    Il génère les dossiers organize, cleanup, migrate et docs, ainsi que les README correspondants.

.PARAMETER Force
    Si spécifié, le script écrase les fichiers existants sans demander de confirmation.

.EXAMPLE
    .\init-maintenance.ps1

.EXAMPLE
    .\init-maintenance.ps1 -Force

.NOTES
    Auteur: Maintenance Team
    Version: 1.0
    Date de création: 2023-08-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Définir le répertoire de base
$baseDir = $PSScriptRoot

# Définir les dossiers à créer
$folders = @(
    "organize",
    "cleanup",
    "migrate",
    "docs",
    "backups",
    "logs"
)

# Créer les dossiers
foreach ($folder in $folders) {
    $folderPath = Join-Path -Path $baseDir -ChildPath $folder

    if (-not (Test-Path -Path $folderPath)) {
        if ($PSCmdlet.ShouldProcess($folderPath, "Créer le dossier")) {
            New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
            Write-Host "Dossier créé : $folderPath" -ForegroundColor Green
        }
    } else {
        Write-Host "Le dossier existe déjà : $folderPath" -ForegroundColor Gray
    }
}

# Créer le README principal
$readmePath = Join-Path -Path $baseDir -ChildPath "README.md"
$readmeContent = @'
# Scripts de maintenance pour EMAIL_SENDER_1

Ce répertoire contient des scripts pour la maintenance du projet EMAIL_SENDER_1.

## Structure

- **organize/** - Scripts pour organiser les fichiers et dossiers
- **cleanup/** - Scripts pour nettoyer les fichiers inutiles
- **migrate/** - Scripts pour migrer des fichiers d'un répertoire à un autre
- **docs/** - Documentation sur la maintenance
- **backups/** - Sauvegardes créées avant les opérations de maintenance
- **logs/** - Journaux des opérations de maintenance

## Utilisation avec Hygen

Ce projet utilise [Hygen](https://www.hygen.io/) pour générer des scripts de maintenance.

### Génération de scripts d'organisation

```bash
hygen maintenance organize
```

### Génération de scripts de nettoyage

```bash
hygen maintenance cleanup
```

### Génération de scripts de migration

```bash
hygen maintenance migrate
```

## Bonnes pratiques

1. Toujours exécuter les scripts en mode simulation (`-DryRun`) avant de les exécuter réellement
2. Créer des sauvegardes avant d'effectuer des opérations potentiellement destructives
3. Journaliser toutes les actions effectuées
4. Tester les scripts dans un environnement de développement avant de les utiliser en production
5. Documenter les scripts et leurs fonctionnalités

## Auteur

Maintenance Team
'@

if (-not (Test-Path -Path $readmePath) -or $Force) {
    if ($PSCmdlet.ShouldProcess($readmePath, "Créer le README")) {
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
        Write-Host "README créé : $readmePath" -ForegroundColor Green
    }
} else {
    Write-Host "Le README existe déjà : $readmePath" -ForegroundColor Gray
}

# Créer les README pour chaque dossier
$folderReadmes = @{
    "organize" = @'
# Scripts d'organisation

Ce répertoire contient des scripts pour organiser les fichiers et dossiers du projet.

## Utilisation avec Hygen

```bash
hygen maintenance organize
```

## Bonnes pratiques

1. Toujours exécuter les scripts en mode simulation (`-DryRun`) avant de les exécuter réellement
2. Créer des sauvegardes avant d'effectuer des opérations potentiellement destructives
3. Journaliser toutes les actions effectuées
'@

    "cleanup"  = @'
# Scripts de nettoyage

Ce répertoire contient des scripts pour nettoyer les fichiers inutiles du projet.

## Utilisation avec Hygen

```bash
hygen maintenance cleanup
```

## Types de nettoyage disponibles

- **temp** : Fichiers temporaires (*.tmp, *.temp, ~*, *.cache)
- **logs** : Fichiers de journalisation (*.log, *.log.*, *_log_*, *.trace)
- **backups** : Fichiers de sauvegarde (*.bak, *.backup, *_backup_*, *.old)
- **duplicates** : Fichiers dupliqués (*_copy*.*, *_copie*.*, * - Copy*.*, * - Copie*.*)
- **empty** : Dossiers vides
- **custom** : Motif personnalisé
'@

    "migrate"  = @'
# Scripts de migration

Ce répertoire contient des scripts pour migrer des fichiers d'un répertoire à un autre.

## Utilisation avec Hygen

```bash
hygen maintenance migrate
```

## Bonnes pratiques

1. Toujours exécuter les scripts en mode simulation (`-DryRun`) avant de les exécuter réellement
2. Créer des sauvegardes avant d'effectuer des opérations potentiellement destructives
3. Journaliser toutes les actions effectuées
4. Tester les scripts de rollback après une migration réussie
'@

    "docs"     = @'
# Documentation de maintenance

Ce répertoire contient la documentation sur la maintenance du projet.

## Contenu

- Procédures de maintenance
- Guides de dépannage
- Bonnes pratiques
- Historique des opérations de maintenance
'@

    "backups"  = @'
# Sauvegardes de maintenance

Ce répertoire contient les sauvegardes créées avant les opérations de maintenance.

## Nomenclature

Les sauvegardes suivent généralement le format suivant :
- `backup_<type>_<date>_<heure>.zip`

Exemple : `backup_cleanup_20230815_123045.zip`
'@

    "logs"     = @'
# Journaux de maintenance

Ce répertoire contient les journaux des opérations de maintenance.

## Nomenclature

Les journaux suivent généralement le format suivant :
- `<type>_<date>_<heure>.log`

Exemple : `cleanup_20230815_123045.log`
'@
}

foreach ($folder in $folders) {
    $readmePath = Join-Path -Path (Join-Path -Path $baseDir -ChildPath $folder) -ChildPath "README.md"

    if (-not (Test-Path -Path $readmePath) -or $Force) {
        if ($PSCmdlet.ShouldProcess($readmePath, "Créer le README")) {
            Set-Content -Path $readmePath -Value $folderReadmes[$folder] -Encoding UTF8
            Write-Host "README créé : $readmePath" -ForegroundColor Green
        }
    } else {
        Write-Host "Le README existe déjà : $readmePath" -ForegroundColor Gray
    }
}

Write-Host "Initialisation de la structure de maintenance terminée." -ForegroundColor Cyan
