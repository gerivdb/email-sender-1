# path-utils.ps1
# Script d'utilitaires pour la gestion des chemins dans PowerShell

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

# Fonction pour supprimer les accents
function Remove-PathAccents {
    param (
        [string]$Path
    )
    
    # Remplacer les caracteres accentues
    $result = $Path
    $result = $result -replace "Ã©", "e"
    $result = $result -replace "Ã¨", "e"
    $result = $result -replace "Ãª", "e"
    $result = $result -replace "Ã«", "e"
    $result = $result -replace "Ã ", "a"
    $result = $result -replace "Ã¢", "a"
    $result = $result -replace "Ã¤", "a"
    $result = $result -replace "Ã®", "i"
    $result = $result -replace "Ã¯", "i"
    $result = $result -replace "Ã´", "o"
    $result = $result -replace "Ã¶", "o"
    $result = $result -replace "Ã¹", "u"
    $result = $result -replace "Ã»", "u"
    $result = $result -replace "Ã¼", "u"
    $result = $result -replace "Ã¿", "y"
    $result = $result -replace "Ã§", "c"
    $result = $result -replace "Ã‰", "E"
    $result = $result -replace "Ãˆ", "E"
    $result = $result -replace "ÃŠ", "E"
    $result = $result -replace "Ã‹", "E"
    $result = $result -replace "Ã€", "A"
    $result = $result -replace "Ã‚", "A"
    $result = $result -replace "Ã„", "A"
    $result = $result -replace "ÃŽ", "I"
    $result = $result -replace "Ã", "I"
    $result = $result -replace "Ã”", "O"
    $result = $result -replace "Ã–", "O"
    $result = $result -replace "Ã™", "U"
    $result = $result -replace "Ã›", "U"
    $result = $result -replace "Ãœ", "U"
    $result = $result -replace "Å¸", "Y"
    $result = $result -replace "Ã‡", "C"
    
    return $result
}

# Fonction pour remplacer les espaces par des underscores
function ConvertTo-PathWithoutSpaces {
    param (
        [string]$Path
    )
    
    return $Path -replace " ", "_"
}

# Fonction pour normaliser un chemin
function ConvertTo-NormalizedPath {
    param (
        [string]$Path
    )
    
    $result = $Path
    $result = Remove-PathAccents -Path $result
    $result = ConvertTo-PathWithoutSpaces -Path $result
    $result = Normalize-Path -Path $result
    
    return $result
}

# Fonction pour verifier si un chemin contient des accents
function Test-PathAccents {
    param (
        [string]$Path
    )
    
    # Utiliser une expression reguliere simple pour detecter les caracteres accentues
    return $Path -match "[Ã©Ã¨ÃªÃ«Ã Ã¢Ã¤Ã®Ã¯Ã´Ã¶Ã¹Ã»Ã¼Ã¿Ã§Ã‰ÃˆÃŠÃ‹Ã€Ã‚Ã„ÃŽÃÃ”Ã–Ã™Ã›ÃœÅ¸Ã‡]"
}

# Fonction pour verifier si un chemin contient des espaces
function Test-PathSpaces {
    param (
        [string]$Path
    )
    
    return $Path -match " "
}

# Fonction pour rechercher des fichiers
function Find-ProjectFiles {
    param (
        [string]$Directory,
        [string[]]$Pattern = @("*"),
        [switch]$Recurse,
        [string[]]$ExcludeDirectories = @(),
        [string[]]$ExcludeFiles = @(),
        [string]$IncludePattern = ""
    )
    
    # Verifier que le repertoire existe
    if (-not (Test-Path -Path $Directory -PathType Container)) {
        Write-Error "Le repertoire n'existe pas: $Directory"
        return @()
    }
    
    # Rechercher les fichiers
    $files = @()
    if ($Recurse) {
        $files = Get-ChildItem -Path $Directory -Include $Pattern -Recurse -File
    } else {
        $files = Get-ChildItem -Path $Directory -Include $Pattern -File
    }
    
    # Filtrer les resultats
    $result = @()
    foreach ($file in $files) {
        $exclude = $false
        
        # Verifier si le fichier est dans un repertoire exclu
        foreach ($dir in $ExcludeDirectories) {
            if ($file.FullName -like "*\$dir\*") {
                $exclude = $true
                break
            }
        }
        
        # Verifier si le fichier est exclu
        if (-not $exclude -and $ExcludeFiles -notcontains $file.Name) {
            # Verifier si le fichier correspond au modele d'inclusion
            if (-not $IncludePattern -or $file.Name -like "*$IncludePattern*") {
                $result += $file.FullName
            }
        }
    }
    
    return $result
}

# Exporter les fonctions
Export-ModuleMember -Function Remove-PathAccents, ConvertTo-PathWithoutSpaces, ConvertTo-NormalizedPath, Test-PathAccents, Test-PathSpaces, Find-ProjectFiles
