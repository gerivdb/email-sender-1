# Script principal pour consolider les fichiers roadmap
# Ce script exécute toutes les opérations nécessaires pour consolider les fichiers roadmap

param (
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [switch]$UpdateReferences,

    [Parameter(Mandatory = $false)]
    [string]$LogFilePath = (Join-Path -Path (Get-Location) -ChildPath "logs\roadmap_consolidation.log")
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
    Write-Log "Démarrage de la consolidation des fichiers roadmap"

    # 1. Créer des sauvegardes des fichiers existants
    Write-Log "Étape 1: Création des sauvegardes des fichiers existants"

    $projectRoot = Get-Location
    $roadmapFiles = @(
        ("Roadmap\roadmap_perso.md"""),
        (Join-Path -Path $projectRoot -ChildPath ""Roadmap\roadmap_perso.md""),
        ("Roadmap\roadmap_perso.md""")
    )

    foreach ($file in $roadmapFiles) {
        if (Test-Path -Path $file -PathType Leaf) {
            $backupPath = "$file.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            if (-not $WhatIf) {
                Copy-Item -Path $file -Destination $backupPath
                Write-Log "Sauvegarde créée: $file -> $backupPath" -Level "INFO"
            } else {
                Write-Log "WhatIf: Sauvegarde créée: $file -> $backupPath" -Level "INFO"
            }
        } else {
            Write-Log "Fichier non trouvé: $file" -Level "WARNING"
        }
    }

    # 2. Créer les copies
    Write-Log "Étape 2: Création des copies"

    $createCopiesScript = Join-Path -Path $PSScriptRoot -ChildPath "Create-RoadmapCopies.ps1"
    if (Test-Path -Path $createCopiesScript -PathType Leaf) {
        if (-not $WhatIf) {
            & $createCopiesScript
        } else {
            & $createCopiesScript -WhatIf
        }
        Write-Log "Copies créées avec succès" -Level "INFO"
    } else {
        Write-Log "Script de création des copies non trouvé: $createCopiesScript" -Level "ERROR"
        exit 1
    }

    # 3. Mettre à jour les références dans les scripts existants (si demandé)
    if ($UpdateReferences) {
        Write-Log "Étape 3: Mise à jour des références dans les scripts existants"

        $updateReferencesScript = Join-Path -Path $PSScriptRoot -ChildPath "Update-RoadmapReferences.ps1"
        if (Test-Path -Path $updateReferencesScript -PathType Leaf) {
            if (-not $WhatIf) {
                & $updateReferencesScript -CreateBackup
            } else {
                & $updateReferencesScript -CreateBackup -WhatIf
            }
            Write-Log "Références mises à jour avec succès" -Level "INFO"
        } else {
            Write-Log "Script de mise à jour des références non trouvé: $updateReferencesScript" -Level "ERROR"
            exit 1
        }
    } else {
        Write-Log "Étape 3: Mise à jour des références dans les scripts existants (ignorée)" -Level "INFO"
    }

    # 4. Mettre à jour le journal de développement
    Write-Log "Étape 4: Mise à jour du journal de développement"

    $journalPath = Join-Path -Path $projectRoot -ChildPath "journal\development_log.md"
    if (Test-Path -Path $journalPath -PathType Leaf) {
        $journalEntry = @"

## $(Get-Date -Format "yyyy-MM-dd") - Consolidation des fichiers roadmap

### Actions réalisées
- Création de sauvegardes des fichiers roadmap existants
- Centralisation du fichier roadmap principal dans le répertoire Roadmap
- Création de copies pour maintenir la compatibilité
- Création d'un script centralisé pour accéder à la roadmap
$(if ($UpdateReferences) { "- Mise à jour des références à la roadmap dans les scripts existants" } else { "" })

### Problèmes résolus
- Confusion due à la présence de plusieurs fichiers roadmap dans différents répertoires
- Incohérences dans les mises à jour des différents fichiers roadmap
- Difficultés à maintenir les références à la roadmap dans les scripts

### Leçons apprises
- Importance de centraliser les ressources partagées
- Utilité des liens symboliques pour maintenir la compatibilité
- Avantages d'une approche modulaire pour l'accès aux ressources partagées

"@

        if (-not $WhatIf) {
            Add-Content -Path $journalPath -Value $journalEntry -Encoding UTF8
            Write-Log "Journal de développement mis à jour: $journalPath" -Level "INFO"
        } else {
            Write-Log "WhatIf: Journal de développement mis à jour: $journalPath" -Level "INFO"
        }
    } else {
        Write-Log "Journal de développement non trouvé: $journalPath" -Level "WARNING"
    }

    # Afficher un résumé
    Write-Host "`nRésumé de la consolidation des fichiers roadmap :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Fichier roadmap principal : $("Roadmap\roadmap_perso.md""")" -ForegroundColor White
    Write-Host "Sauvegardes créées : $($roadmapFiles.Count)" -ForegroundColor Green
    Write-Host "Copies créées : 2" -ForegroundColor Green
    if ($UpdateReferences) {
        Write-Host "Références mises à jour : Oui" -ForegroundColor Green
    } else {
        Write-Host "Références mises à jour : Non" -ForegroundColor Yellow
    }

    Write-Log "Consolidation des fichiers roadmap terminée avec succès" -Level "INFO"
}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
