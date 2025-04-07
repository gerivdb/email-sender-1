# normalize-project-paths.ps1
# Script pour normaliser les chemins dans un projet
# Ce script recherche et normalise les chemins dans les fichiers du projet

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "tools\path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Parametres du script
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

    # Remplacer les caracteres accentues si demande
    if ($FixAccents) {
        $tempContent = $newContent
        # Remplacer les caracteres accentues
        $tempContent = $tempContent -replace "é", "e"
        $tempContent = $tempContent -replace "è", "e"
        $tempContent = $tempContent -replace "ê", "e"
        $tempContent = $tempContent -replace "ë", "e"
        $tempContent = $tempContent -replace "à", "a"
        $tempContent = $tempContent -replace "â", "a"
        $tempContent = $tempContent -replace "ä", "a"
        $tempContent = $tempContent -replace "î", "i"
        $tempContent = $tempContent -replace "ï", "i"
        $tempContent = $tempContent -replace "ô", "o"
        $tempContent = $tempContent -replace "ö", "o"
        $tempContent = $tempContent -replace "ù", "u"
        $tempContent = $tempContent -replace "û", "u"
        $tempContent = $tempContent -replace "ü", "u"
        $tempContent = $tempContent -replace "ÿ", "y"
        $tempContent = $tempContent -replace "ç", "c"
        $tempContent = $tempContent -replace "É", "E"
        $tempContent = $tempContent -replace "È", "E"
        $tempContent = $tempContent -replace "Ê", "E"
        $tempContent = $tempContent -replace "Ë", "E"
        $tempContent = $tempContent -replace "À", "A"
        $tempContent = $tempContent -replace "Â", "A"
        $tempContent = $tempContent -replace "Ä", "A"
        $tempContent = $tempContent -replace "Î", "I"
        $tempContent = $tempContent -replace "Ï", "I"
        $tempContent = $tempContent -replace "Ô", "O"
        $tempContent = $tempContent -replace "Ö", "O"
        $tempContent = $tempContent -replace "Ù", "U"
        $tempContent = $tempContent -replace "Û", "U"
        $tempContent = $tempContent -replace "Ü", "U"
        $tempContent = $tempContent -replace "Ÿ", "Y"
        $tempContent = $tempContent -replace "Ç", "C"
        
        if ($tempContent -ne $newContent) {
            $newContent = $tempContent
            $modified = $true
        }
    }

    # Remplacer les espaces par des underscores si demande
    if ($FixSpaces) {
        $tempContent = $newContent -replace " ", "_"
        if ($tempContent -ne $newContent) {
            $newContent = $tempContent
            $modified = $true
        }
    }

    # Normaliser les chemins si demande
    if ($FixPaths) {
        # Ancien chemin (avec espaces et accents)
        $oldPathVariants = @(
            "D:\\DO\\WEB\\N8N tests\\scripts json à tester\\EMAIL SENDER 1",
            "D:/DO/WEB/N8N tests/scripts json à tester/EMAIL SENDER 1",
            "D:\DO\WEB\N8N tests\scripts json à tester\EMAIL SENDER 1"
        )

        # Nouveau chemin (avec underscores)
        $newPath = "D:\\DO\\WEB\\N8N_tests\\scripts_json_a_tester\\EMAIL_SENDER_1"

        # Remplacer les anciens chemins par le nouveau chemin
        foreach ($variant in $oldPathVariants) {
            if ($newContent -match [regex]::Escape($variant)) {
                $newContent = $newContent -replace [regex]::Escape($variant), $newPath
                $modified = $true
            }
        }
    }

    # Si le contenu a ete modifie, ecrire le nouveau contenu dans le fichier
    if ($modified) {
        if ($WhatIf) {
            Write-Host "WhatIf: Le fichier $FilePath serait modifie" -ForegroundColor Yellow
        } else {
            Set-Content -Path $FilePath -Value $newContent -NoNewline
            Write-Host "Le fichier $FilePath a ete modifie" -ForegroundColor Green
        }
        return $true
    }

    return $false
}

# Fonction principale
function Main {
    # Afficher les parametres
    Write-Host "=== Normalisation des chemins dans les fichiers ===" -ForegroundColor Cyan
    Write-Host "Repertoire: $Directory"
    Write-Host "Types de fichiers: $($FileTypes -join ', ')"
    Write-Host "Recursif: $Recurse"
    Write-Host "Corriger les accents: $FixAccents"
    Write-Host "Corriger les espaces: $FixSpaces"
    Write-Host "Corriger les chemins: $FixPaths"
    Write-Host "WhatIf: $WhatIf"
    Write-Host ""

    # Si aucune option de correction n'est specifiee, activer toutes les options
    if (-not $FixAccents -and -not $FixSpaces -and -not $FixPaths) {
        $FixAccents = $true
        $FixSpaces = $true
        $FixPaths = $true
        Write-Host "Aucune option de correction specifiee, activation de toutes les options" -ForegroundColor Yellow
    }

    # Rechercher les fichiers a normaliser
    $files = @()
    foreach ($fileType in $FileTypes) {
        if ($Recurse) {
            $files += Get-ChildItem -Path $Directory -Filter $fileType -File -Recurse
        } else {
            $files += Get-ChildItem -Path $Directory -Filter $fileType -File
        }
    }

    Write-Host "Nombre de fichiers trouves: $($files.Count)"

    # Normaliser les fichiers
    $normalizedFiles = @()
    foreach ($file in $files) {
        if (Normalize-FileContent -FilePath $file.FullName -FixAccents:$FixAccents -FixSpaces:$FixSpaces -FixPaths:$FixPaths -WhatIf:$WhatIf) {
            $normalizedFiles += $file.FullName
        }
    }

    # Afficher les resultats
    if ($normalizedFiles.Count -eq 0) {
        Write-Host "✅ Aucun fichier n'a eu besoin d'etre normalise." -ForegroundColor Green
    } else {
        if ($WhatIf) {
            Write-Host "✅ Les fichiers suivants seraient normalises :" -ForegroundColor Green
        } else {
            Write-Host "✅ Les fichiers suivants ont ete normalises :" -ForegroundColor Green
        }
        foreach ($file in $normalizedFiles) {
            Write-Host "   - $file" -ForegroundColor Yellow
        }
    }
}

# Executer la fonction principale
Main
