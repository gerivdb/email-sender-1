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
    $result = $result -replace "é", "e"
    $result = $result -replace "è", "e"
    $result = $result -replace "ê", "e"
    $result = $result -replace "ë", "e"
    $result = $result -replace "à", "a"
    $result = $result -replace "â", "a"
    $result = $result -replace "ä", "a"
    $result = $result -replace "î", "i"
    $result = $result -replace "ï", "i"
    $result = $result -replace "ô", "o"
    $result = $result -replace "ö", "o"
    $result = $result -replace "ù", "u"
    $result = $result -replace "û", "u"
    $result = $result -replace "ü", "u"
    $result = $result -replace "ÿ", "y"
    $result = $result -replace "ç", "c"
    $result = $result -replace "É", "E"
    $result = $result -replace "È", "E"
    $result = $result -replace "Ê", "E"
    $result = $result -replace "Ë", "E"
    $result = $result -replace "À", "A"
    $result = $result -replace "Â", "A"
    $result = $result -replace "Ä", "A"
    $result = $result -replace "Î", "I"
    $result = $result -replace "Ï", "I"
    $result = $result -replace "Ô", "O"
    $result = $result -replace "Ö", "O"
    $result = $result -replace "Ù", "U"
    $result = $result -replace "Û", "U"
    $result = $result -replace "Ü", "U"
    $result = $result -replace "Ÿ", "Y"
    $result = $result -replace "Ç", "C"
    
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
    return $Path -match "[éèêëàâäîïôöùûüÿçÉÈÊËÀÂÄÎÏÔÖÙÛÜŸÇ]"
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
