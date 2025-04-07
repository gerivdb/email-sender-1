# Normalize-Path.ps1
# Script PowerShell pour normaliser les chemins dans les fichiers du projet
# Ce script recherche et normalise les chemins dans les fichiers du projet

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouvÃ©: $PathManagerModule"
    exit 1
}

# Importer le script d'utilitaires pour les chemins
$PathUtilsScript = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "scripts\utils\path-utils.ps1"
if (Test-Path -Path $PathUtilsScript) {
    . $PathUtilsScript
} else {
    Write-Error "Script path-utils.ps1 non trouvÃ©: $PathUtilsScript"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# ParamÃ¨tres du script
param (
    [Parameter(Mandatory = $false)]
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
    [switch]$FixPaths,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Fonction pour normaliser un fichier
function Normalize-FileContent {
    param (
        [string]$FilePath,
        [switch]$FixAccents,
        [switch]$FixSpaces,
        [switch]$FixPaths,
        [switch]$WhatIf
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

    # Remplacer les caractÃ¨res accentuÃ©s si demandÃ©
    if ($FixAccents) {
        $tempContent = Remove-PathAccents -Path $newContent
        if ($tempContent -ne $newContent) {
            $newContent = $tempContent
            $modified = $true
        }
    }

    # Remplacer les espaces par des underscores si demandÃ©
    if ($FixSpaces) {
        $tempContent = Replace-PathSpaces -Path $newContent
        if ($tempContent -ne $newContent) {
            $newContent = $tempContent
            $modified = $true
        }
    }

    # Normaliser les chemins si demandÃ©
    if ($FixPaths) {
        # Ancien chemin (avec espaces et accents)
        $oldPathVariants = @(
            "D:\\DO\\WEB\\N8N tests\\scripts json Ã  tester\\EMAIL SENDER 1",
            "D:/DO/WEB/N8N tests/scripts json Ã  tester/EMAIL SENDER 1",
            "D:\DO\WEB\N8N tests\scripts json Ã  tester\EMAIL SENDER 1"
        )

        # Nouveau chemin (avec underscores)
        $newPath = "D:\\DO\\WEB\\N8N_tests\\scripts_ json_a_ tester\\EMAIL_SENDER_1"

        # Remplacer les anciens chemins par le nouveau chemin
        foreach ($variant in $oldPathVariants) {
            if ($newContent -match [regex]::Escape($variant)) {
                $newContent = $newContent -replace [regex]::Escape($variant), $newPath
                $modified = $true
            }
        }
    }

    # Si le contenu a Ã©tÃ© modifiÃ©, Ã©crire le nouveau contenu dans le fichier
    if ($modified) {
        if ($WhatIf) {
            Write-Host "WhatIf: Le fichier $FilePath serait modifiÃ©" -ForegroundColor Yellow
        } else {
            Set-Content -Path $FilePath -Value $newContent -NoNewline
            Write-Host "Le fichier $FilePath a Ã©tÃ© modifiÃ©" -ForegroundColor Green
        }
        return $true
    }

    return $false
}

# Fonction principale
function Main {
    # Afficher les paramÃ¨tres
    Write-Host "=== Normalisation des chemins dans les fichiers ===" -ForegroundColor Cyan
    Write-Host "RÃ©pertoire: $Directory"
    Write-Host "Types de fichiers: $($FileTypes -join ', ')"
    Write-Host "RÃ©cursif: $Recurse"
    Write-Host "Corriger les accents: $FixAccents"
    Write-Host "Corriger les espaces: $FixSpaces"
    Write-Host "Corriger les chemins: $FixPaths"
    Write-Host "WhatIf: $WhatIf"
    Write-Host ""

    # Si aucune option de correction n'est spÃ©cifiÃ©e, activer toutes les options
    if (-not $FixAccents -and -not $FixSpaces -and -not $FixPaths) {
        $FixAccents = $true
        $FixSpaces = $true
        $FixPaths = $true
        Write-Host "Aucune option de correction spÃ©cifiÃ©e, activation de toutes les options" -ForegroundColor Yellow
    }

    # Rechercher les fichiers Ã  normaliser
    $files = @()
    foreach ($fileType in $FileTypes) {
        if ($Recurse) {
            $files += Get-ChildItem -Path $Directory -Filter $fileType -File -Recurse
        } else {
            $files += Get-ChildItem -Path $Directory -Filter $fileType -File
        }
    }

    Write-Host "Nombre de fichiers trouvÃ©s: $($files.Count)"

    # Normaliser les fichiers
    $normalizedFiles = @()
    foreach ($file in $files) {
        if (Normalize-FileContent -FilePath $file.FullName -FixAccents:$FixAccents -FixSpaces:$FixSpaces -FixPaths:$FixPaths -WhatIf:$WhatIf) {
            $normalizedFiles += $file.FullName
        }
    }

    # Afficher les rÃ©sultats
    if ($normalizedFiles.Count -eq 0) {
        Write-Host "âœ… Aucun fichier n'a eu besoin d'Ãªtre normalisÃ©." -ForegroundColor Green
    } else {
        if ($WhatIf) {
            Write-Host "âœ… Les fichiers suivants seraient normalisÃ©s :" -ForegroundColor Green
        } else {
            Write-Host "âœ… Les fichiers suivants ont Ã©tÃ© normalisÃ©s :" -ForegroundColor Green
        }
        foreach ($file in $normalizedFiles) {
            Write-Host "   - $file" -ForegroundColor Yellow
        }
    }
}

# ExÃ©cuter la fonction principale
Main
