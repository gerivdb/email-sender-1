# Script principal pour consolider les fichiers roadmap
# Ce script exÃ©cute toutes les opÃ©rations nÃ©cessaires pour consolider les fichiers roadmap

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

    # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    Add-Content -Path $LogFilePath -Value $logEntry -Encoding UTF8
}

try {
    Write-Log "DÃ©marrage de la consolidation des fichiers roadmap"

    # 1. CrÃ©er des sauvegardes des fichiers existants
    Write-Log "Ã‰tape 1: CrÃ©ation des sauvegardes des fichiers existants"

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
                Write-Log "Sauvegarde crÃ©Ã©e: $file -> $backupPath" -Level "INFO"
            } else {
                Write-Log "WhatIf: Sauvegarde crÃ©Ã©e: $file -> $backupPath" -Level "INFO"
            }
        } else {
            Write-Log "Fichier non trouvÃ©: $file" -Level "WARNING"
        }
    }

    # 2. CrÃ©er les copies
    Write-Log "Ã‰tape 2: CrÃ©ation des copies"

    $createCopiesScript = Join-Path -Path $PSScriptRoot -ChildPath "Create-RoadmapCopies.ps1"
    if (Test-Path -Path $createCopiesScript -PathType Leaf) {
        if (-not $WhatIf) {
            & $createCopiesScript
        } else {
            & $createCopiesScript -WhatIf
        }
        Write-Log "Copies crÃ©Ã©es avec succÃ¨s" -Level "INFO"
    } else {
        Write-Log "Script de crÃ©ation des copies non trouvÃ©: $createCopiesScript" -Level "ERROR"
        exit 1
    }

    # 3. Mettre Ã  jour les rÃ©fÃ©rences dans les scripts existants (si demandÃ©)
    if ($UpdateReferences) {
        Write-Log "Ã‰tape 3: Mise Ã  jour des rÃ©fÃ©rences dans les scripts existants"

        $updateReferencesScript = Join-Path -Path $PSScriptRoot -ChildPath "Update-RoadmapReferences.ps1"
        if (Test-Path -Path $updateReferencesScript -PathType Leaf) {
            if (-not $WhatIf) {
                & $updateReferencesScript -CreateBackup
            } else {
                & $updateReferencesScript -CreateBackup -WhatIf
            }
            Write-Log "RÃ©fÃ©rences mises Ã  jour avec succÃ¨s" -Level "INFO"
        } else {
            Write-Log "Script de mise Ã  jour des rÃ©fÃ©rences non trouvÃ©: $updateReferencesScript" -Level "ERROR"
            exit 1
        }
    } else {
        Write-Log "Ã‰tape 3: Mise Ã  jour des rÃ©fÃ©rences dans les scripts existants (ignorÃ©e)" -Level "INFO"
    }

    # 4. Mettre Ã  jour le journal de dÃ©veloppement
    Write-Log "Ã‰tape 4: Mise Ã  jour du journal de dÃ©veloppement"

    $journalPath = Join-Path -Path $projectRoot -ChildPath "journal\development_log.md"
    if (Test-Path -Path $journalPath -PathType Leaf) {
        $journalEntry = @"

## $(Get-Date -Format "yyyy-MM-dd") - Consolidation des fichiers roadmap

### Actions rÃ©alisÃ©es
- CrÃ©ation de sauvegardes des fichiers roadmap existants
- Centralisation du fichier roadmap principal dans le rÃ©pertoire Roadmap
- CrÃ©ation de copies pour maintenir la compatibilitÃ©
- CrÃ©ation d'un script centralisÃ© pour accÃ©der Ã  la roadmap
$(if ($UpdateReferences) { "- Mise Ã  jour des rÃ©fÃ©rences Ã  la roadmap dans les scripts existants" } else { "" })

### ProblÃ¨mes rÃ©solus
- Confusion due Ã  la prÃ©sence de plusieurs fichiers roadmap dans diffÃ©rents rÃ©pertoires
- IncohÃ©rences dans les mises Ã  jour des diffÃ©rents fichiers roadmap
- DifficultÃ©s Ã  maintenir les rÃ©fÃ©rences Ã  la roadmap dans les scripts

### LeÃ§ons apprises
- Importance de centraliser les ressources partagÃ©es
- UtilitÃ© des liens symboliques pour maintenir la compatibilitÃ©
- Avantages d'une approche modulaire pour l'accÃ¨s aux ressources partagÃ©es

"@

        if (-not $WhatIf) {
            Add-Content -Path $journalPath -Value $journalEntry -Encoding UTF8
            Write-Log "Journal de dÃ©veloppement mis Ã  jour: $journalPath" -Level "INFO"
        } else {
            Write-Log "WhatIf: Journal de dÃ©veloppement mis Ã  jour: $journalPath" -Level "INFO"
        }
    } else {
        Write-Log "Journal de dÃ©veloppement non trouvÃ©: $journalPath" -Level "WARNING"
    }

    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de la consolidation des fichiers roadmap :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Fichier roadmap principal : $("Roadmap\roadmap_perso.md""")" -ForegroundColor White
    Write-Host "Sauvegardes crÃ©Ã©es : $($roadmapFiles.Count)" -ForegroundColor Green
    Write-Host "Copies crÃ©Ã©es : 2" -ForegroundColor Green
    if ($UpdateReferences) {
        Write-Host "RÃ©fÃ©rences mises Ã  jour : Oui" -ForegroundColor Green
    } else {
        Write-Host "RÃ©fÃ©rences mises Ã  jour : Non" -ForegroundColor Yellow
    }

    Write-Log "Consolidation des fichiers roadmap terminÃ©e avec succÃ¨s" -Level "INFO"
}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
