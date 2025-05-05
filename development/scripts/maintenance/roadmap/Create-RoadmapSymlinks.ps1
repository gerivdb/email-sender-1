# Script pour crÃƒÂ©er des copies du fichier roadmap principal
# Ce script crÃƒÂ©e des copies pour maintenir la compatibilitÃƒÂ© avec les scripts existants

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

    # CrÃƒÂ©er le rÃƒÂ©pertoire de logs si nÃƒÂ©cessaire
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    Add-Content -Path $LogFilePath -Value $logEntry -Encoding UTF8
}

try {
    # DÃƒÂ©finir le chemin absolu du fichier roadmap principal
    $projectRoot = Get-Location
    $roadmapPath = "Roadmap\roadmap_perso.md"""

    # VÃƒÂ©rifier si le fichier existe
    if (-not (Test-Path -Path $roadmapPath -PathType Leaf)) {
        Write-Log -Level ERROR -Message "Le fichier roadmap principal n'existe pas: $roadmapPath"
        exit 1
    }

    # DÃƒÂ©finir les chemins des liens symboliques ÃƒÂ  crÃƒÂ©er
    $symlinks = @(
        ("Roadmap\roadmap_perso.md"""),
        ("Roadmap\roadmap_perso.md""")
    )

    # CrÃƒÂ©er les copies
    foreach ($copyPath in $symlinks) {
        # VÃƒÂ©rifier si le fichier existe dÃƒÂ©jÃƒÂ 
        if (Test-Path -Path $copyPath -PathType Leaf) {
            # Renommer le fichier existant
            $backupPath = "$copyPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            if (-not $WhatIf) {
                Move-Item -Path $copyPath -Destination $backupPath
                Write-Log "Fichier existant renommÃƒÂ©: $copyPath -> $backupPath" -Level "INFO"
            } else {
                Write-Log "WhatIf: Fichier existant renommÃƒÂ©: $copyPath -> $backupPath" -Level "INFO"
            }
        }

        # CrÃƒÂ©er le rÃƒÂ©pertoire parent si nÃƒÂ©cessaire
        $parentDir = Split-Path -Path $copyPath -Parent
        if (-not (Test-Path -Path $parentDir -PathType Container)) {
            if (-not $WhatIf) {
                New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                Write-Log "RÃƒÂ©pertoire crÃƒÂ©ÃƒÂ©: $parentDir" -Level "INFO"
            } else {
                Write-Log "WhatIf: RÃƒÂ©pertoire crÃƒÂ©ÃƒÂ©: $parentDir" -Level "INFO"
            }
        }

        # CrÃƒÂ©er la copie
        if (-not $WhatIf) {
            Copy-Item -Path $roadmapPath -Destination $copyPath -Force
            Write-Log "Copie crÃƒÂ©ÃƒÂ©e: $copyPath <- $roadmapPath" -Level "INFO"
        } else {
            Write-Log "WhatIf: Copie crÃƒÂ©ÃƒÂ©e: $copyPath <- $roadmapPath" -Level "INFO"
        }
    }

    # Afficher un rÃƒÂ©sumÃƒÂ©
    Write-Host "`nRÃƒÂ©sumÃƒÂ© de la crÃƒÂ©ation des copies :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Fichier roadmap principal : $roadmapPath" -ForegroundColor White
    Write-Host "Copies crÃƒÂ©ÃƒÂ©es : $($symlinks.Count)" -ForegroundColor Green

    # CrÃƒÂ©er un fichier README.md dans le rÃƒÂ©pertoire Roadmap
    $readmePath = Join-Path -Path (Split-Path -Path $roadmapPath -Parent) -ChildPath "README.md"
    $readmeContent = @"
# Gestion de la Roadmap

## Structure des fichiers

- `"Roadmap\roadmap_perso.md"` : Fichier principal de la roadmap
- `roadmap_perso_new.md` : Ancienne version de la roadmap (conservÃƒÂ©e pour rÃƒÂ©fÃƒÂ©rence)
- Les autres fichiers avec le suffixe `_backup_` sont des sauvegardes automatiques

## AccÃƒÂ¨s ÃƒÂ  la Roadmap

Pour accÃƒÂ©der ÃƒÂ  la roadmap depuis les scripts, utilisez le script centralisÃƒÂ© :

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

Des copies ont ÃƒÂ©tÃƒÂ© crÃƒÂ©ÃƒÂ©es pour maintenir la compatibilitÃƒÂ© avec les scripts existants :

- `"Roadmap\roadmap_perso.md"` ÃƒÂ  la racine du projet
- `md\"Roadmap\roadmap_perso.md"`

Ces copies sont identiques au fichier principal `Roadmap\"Roadmap\roadmap_perso.md"`.

## Mise ÃƒÂ  jour des rÃƒÂ©fÃƒÂ©rences

Pour mettre ÃƒÂ  jour les rÃƒÂ©fÃƒÂ©rences ÃƒÂ  la roadmap dans les scripts existants, utilisez le script :

```powershell
.\development\scripts\maintenance\roadmap\Update-RoadmapReferences.ps1
```

DerniÃƒÂ¨re mise ÃƒÂ  jour : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

    if (-not $WhatIf) {
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
        Write-Log "Fichier README.md crÃƒÂ©ÃƒÂ©: $readmePath" -Level "INFO"
    } else {
        Write-Log "WhatIf: Fichier README.md crÃƒÂ©ÃƒÂ©: $readmePath" -Level "INFO"
    }
}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}
