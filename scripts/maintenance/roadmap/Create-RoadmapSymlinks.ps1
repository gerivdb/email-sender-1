# Script pour créer des copies du fichier roadmap principal
# Ce script crée des copies pour maintenir la compatibilité avec les scripts existants

param (
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [string]$LogFilePath = (Join-Path -Path (Get-Location) -ChildPath "logs\roadmap_symlinks.log")
)

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

    # Créer le répertoire de logs si nécessaire
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    Add-Content -Path $LogFilePath -Value $logEntry -Encoding UTF8
}

try {
    # Définir le chemin absolu du fichier roadmap principal
    $projectRoot = Get-Location
    $roadmapPath = "Roadmap\roadmap_perso.md"""

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $roadmapPath -PathType Leaf)) {
        Write-Log -Level ERROR -Message "Le fichier roadmap principal n'existe pas: $roadmapPath"
        exit 1
    }

    # Définir les chemins des liens symboliques à créer
    $symlinks = @(
        ("Roadmap\roadmap_perso.md"""),
        ("Roadmap\roadmap_perso.md""")
    )

    # Créer les copies
    foreach ($copyPath in $symlinks) {
        # Vérifier si le fichier existe déjà
        if (Test-Path -Path $copyPath -PathType Leaf) {
            # Renommer le fichier existant
            $backupPath = "$copyPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            if (-not $WhatIf) {
                Move-Item -Path $copyPath -Destination $backupPath
                Write-Log "Fichier existant renommé: $copyPath -> $backupPath" -Level "INFO"
            } else {
                Write-Log "WhatIf: Fichier existant renommé: $copyPath -> $backupPath" -Level "INFO"
            }
        }

        # Créer le répertoire parent si nécessaire
        $parentDir = Split-Path -Path $copyPath -Parent
        if (-not (Test-Path -Path $parentDir -PathType Container)) {
            if (-not $WhatIf) {
                New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                Write-Log "Répertoire créé: $parentDir" -Level "INFO"
            } else {
                Write-Log "WhatIf: Répertoire créé: $parentDir" -Level "INFO"
            }
        }

        # Créer la copie
        if (-not $WhatIf) {
            Copy-Item -Path $roadmapPath -Destination $copyPath -Force
            Write-Log "Copie créée: $copyPath <- $roadmapPath" -Level "INFO"
        } else {
            Write-Log "WhatIf: Copie créée: $copyPath <- $roadmapPath" -Level "INFO"
        }
    }

    # Afficher un résumé
    Write-Host "`nRésumé de la création des copies :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Fichier roadmap principal : $roadmapPath" -ForegroundColor White
    Write-Host "Copies créées : $($symlinks.Count)" -ForegroundColor Green

    # Créer un fichier README.md dans le répertoire Roadmap
    $readmePath = Join-Path -Path (Split-Path -Path $roadmapPath -Parent) -ChildPath "README.md"
    $readmeContent = @"
# Gestion de la Roadmap

## Structure des fichiers

- `"Roadmap\roadmap_perso.md"` : Fichier principal de la roadmap
- `roadmap_perso_new.md` : Ancienne version de la roadmap (conservée pour référence)
- Les autres fichiers avec le suffixe `_backup_` sont des sauvegardes automatiques

## Accès à la Roadmap

Pour accéder à la roadmap depuis les scripts, utilisez le script centralisé :

```powershell
# Importer le module de gestion de la roadmap
`$roadmapPathScript = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\utils\roadmap\Get-RoadmapPath.ps1"
if (Test-Path -Path `$roadmapPathScript) {
    . `$roadmapPathScript
}
else {
    Write-Warning "Le module de gestion de la roadmap est introuvable: `$roadmapPathScript"
}

# Utiliser le chemin de la roadmap
`$roadmapPath = & `$roadmapPathScript
```

## Copies

Des copies ont été créées pour maintenir la compatibilité avec les scripts existants :

- `"Roadmap\roadmap_perso.md"` à la racine du projet
- `md\"Roadmap\roadmap_perso.md"`

Ces copies sont identiques au fichier principal `Roadmap\"Roadmap\roadmap_perso.md"`.

## Mise à jour des références

Pour mettre à jour les références à la roadmap dans les scripts existants, utilisez le script :

```powershell
.\scripts\maintenance\roadmap\Update-RoadmapReferences.ps1
```

Dernière mise à jour : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

    if (-not $WhatIf) {
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
        Write-Log "Fichier README.md créé: $readmePath" -Level "INFO"
    } else {
        Write-Log "WhatIf: Fichier README.md créé: $readmePath" -Level "INFO"
    }
}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
