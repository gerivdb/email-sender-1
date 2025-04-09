# Normalize-Path.ps1
# Script PowerShell pour normaliser les chemins dans les fichiers du projet
# Ce script recherche et normalise les chemins dans les fichiers du projet

[CmdletBinding(SupportsShouldProcess=$true)]

# Normalize-Path.ps1
# Script PowerShell pour normaliser les chemins dans les fichiers du projet
# Ce script recherche et normalise les chemins dans les fichiers du projet

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory = $false)

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
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
    [string]$Directory = ".",

    [Parameter(Mandatory = $false)]
    [string[]]$FileTypes = @("*.json", "*.cmd", "*.ps1", "*.yaml", "*.md"),

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [switch]$FixAccents,

    [Parameter(Mandatory = $false)]
    [switch]$FixSpaces,

    [Parameter(Mandatory = $false)]
    [switch]$FixPaths
)

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) -ChildPath "tools\path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouvé: $PathManagerModule"
    exit 1
}

# Commentons cette partie car le chemin semble incorrect
# $PathUtilsScript = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "..\..\D"
# if (Test-Path -Path $PathUtilsScript) {
#     . $PathUtilsScript
# } else {
#     Write-Error "Script path-utils.ps1 non trouvé: $PathUtilsScript"
#     exit 1
# }

# Fonctions utilitaires pour les chemins
function Remove-PathAccents {
    param ([string]$Path)
    return $Path -replace 'à', 'a' -replace 'é', 'e' -replace 'è', 'e' -replace 'ê', 'e' -replace 'ù', 'u'
}

function ConvertTo-PathWithoutSpaces {
    param ([string]$Path)
    return $Path -replace ' ', '_'
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Fonction pour normaliser un fichier
function ConvertTo-NormalizedFileContent {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [switch]$FixAccents,

        [Parameter(Mandatory=$false)]
        [switch]$FixSpaces,

        [Parameter(Mandatory=$false)]
        [switch]$FixPaths
    )

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-Warning "Impossible de lire le contenu du fichier: $FilePath"
        return $false
    }

    # Initialiser le flag de modification
    $modified = $false
    $newContent = $content

    # Remplacer les caractères accentués si demandé
    if ($FixAccents) {
        $tempContent = Remove-PathAccents -Path $newContent
        if ($tempContent -ne $newContent) {
            $newContent = $tempContent
            $modified = $true
        }
    }

    # Remplacer les espaces par des underscores si demandé
    if ($FixSpaces) {
        $tempContent = ConvertTo-PathWithoutSpaces -Path $newContent
        if ($tempContent -ne $newContent) {
            $newContent = $tempContent
            $modified = $true
        }
    }

    # Normaliser les chemins si demandé
    if ($FixPaths) {
        # Ancien chemin (avec espaces et accents)
        $oldPathVariants = @(
            "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
            "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
            "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
        )

        # Nouveau chemin (avec underscores)
        $newPath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"

        # Remplacer les anciens chemins par le nouveau chemin
        foreach ($variant in $oldPathVariants) {
            if ($newContent -match [regex]::Escape($variant)) {
                $newContent = $newContent -replace [regex]::Escape($variant), $newPath
                $modified = $true
            }
        }
    }

    # Si le contenu a été modifié, écrire le nouveau contenu dans le fichier
    if ($modified) {
        if ($PSCmdlet.ShouldProcess($FilePath, "Modifier le contenu du fichier")) {
            Set-Content -Path $FilePath -Value $newContent -NoNewline
            Write-Host "Le fichier $FilePath a été modifié" -ForegroundColor Green
            return $true
        } else {
            Write-Host "WhatIf: Le fichier $FilePath serait modifié" -ForegroundColor Yellow
            return $true
        }
    }

    return $false
}

# Fonction principale
function Main {
    # Afficher les paramètres
    Write-Host "=== Normalisation des chemins dans les fichiers ===" -ForegroundColor Cyan
    Write-Host "Répertoire: $Directory"
    Write-Host "Types de fichiers: $($FileTypes -join ', ')"
    Write-Host "Récursif: $Recurse"
    Write-Host "Corriger les accents: $FixAccents"
    Write-Host "Corriger les espaces: $FixSpaces"
    Write-Host "Corriger les chemins: $FixPaths"
    Write-Host "WhatIf: $WhatIf"
    Write-Host ""

    # Si aucune option de correction n'est spécifiée, activer toutes les options
    if (-not $FixAccents -and -not $FixSpaces -and -not $FixPaths) {
        $FixAccents = $true
        $FixSpaces = $true
        $FixPaths = $true
        Write-Host "Aucune option de correction spécifiée, activation de toutes les options" -ForegroundColor Yellow
    }

    # Rechercher les fichiers à normaliser
    $files = @()
    foreach ($fileType in $FileTypes) {
        if ($Recurse) {
            $files += Get-ChildItem -Path $Directory -Filter $fileType -File -Recurse
        } else {
            $files += Get-ChildItem -Path $Directory -Filter $fileType -File
        }
    }

    Write-Host "Nombre de fichiers trouvés: $($files.Count)"

    # Normaliser les fichiers
    $normalizedFiles = @()
    foreach ($file in $files) {
        if (ConvertTo-NormalizedFileContent -FilePath $file.FullName -FixAccents:$FixAccents -FixSpaces:$FixSpaces -FixPaths:$FixPaths) {
            $normalizedFiles += $file.FullName
        }
    }

    # Afficher les résultats
    if ($normalizedFiles.Count -eq 0) {
        Write-Host "✅ Aucun fichier n'a eu besoin d'être normalisé." -ForegroundColor Green
    } else {
        if ($WhatIfPreference) {
            Write-Host "✅ Les fichiers suivants seraient normalisés :" -ForegroundColor Green
        } else {
            Write-Host "✅ Les fichiers suivants ont été normalisés :" -ForegroundColor Green
        }
        foreach ($file in $normalizedFiles) {
            Write-Host "   - $file" -ForegroundColor Yellow
        }
    }
}

# Exécuter la fonction principale
Main


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
