<#
.SYNOPSIS
    Convertit un chemin en chemin normalisÃ©.

.DESCRIPTION
    La fonction ConvertTo-NormalizedPath convertit un chemin en chemin normalisÃ©.
    Elle prend en charge diffÃ©rentes options de normalisation et peut Ãªtre utilisÃ©e pour
    normaliser les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin Ã  normaliser.

.PARAMETER NormalizationType
    Le type de normalisation Ã  effectuer. Valeurs possibles :
    - FullPath : Convertit le chemin en chemin absolu complet
    - RelativePath : Convertit le chemin en chemin relatif par rapport Ã  un chemin de base
    - UnixPath : Convertit le chemin en format Unix (sÃ©parateurs /)
    - WindowsPath : Convertit le chemin en format Windows (sÃ©parateurs \)
    - UNCPath : Convertit le chemin en format UNC (\\server\share)
    - URLPath : Convertit le chemin en format URL (file:///)
    - Custom : Utilise une normalisation personnalisÃ©e

.PARAMETER BasePath
    Le chemin de base Ã  utiliser pour la normalisation de type RelativePath.
    Par dÃ©faut, c'est le rÃ©pertoire courant.

.PARAMETER CustomNormalization
    La fonction de normalisation personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque NormalizationType est "Custom".

.PARAMETER ResolveRelativePaths
    Indique si les chemins relatifs doivent Ãªtre rÃ©solus.
    Par dÃ©faut, c'est $true.

.PARAMETER PreserveDriveLetters
    Indique si les lettres de lecteur doivent Ãªtre prÃ©servÃ©es.
    Par dÃ©faut, c'est $true.

.PARAMETER RemoveTrailingSlash
    Indique si les barres obliques finales doivent Ãªtre supprimÃ©es.
    Par dÃ©faut, c'est $true.

.PARAMETER NormalizeCase
    Indique si la casse du chemin doit Ãªtre normalisÃ©e.
    Par dÃ©faut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la normalisation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la normalisation.

.EXAMPLE
    ConvertTo-NormalizedPath -Path ".\folder\file.txt" -NormalizationType FullPath
    Normalise le chemin relatif ".\folder\file.txt" en chemin absolu complet.

.EXAMPLE
    ConvertTo-NormalizedPath -Path "C:\folder\file.txt" -NormalizationType UnixPath
    Convertit le chemin Windows "C:\folder\file.txt" en format Unix "/c/folder/file.txt".

.OUTPUTS
    [string] Le chemin normalisÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function ConvertTo-NormalizedPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("FullPath", "RelativePath", "UnixPath", "WindowsPath", "UNCPath", "URLPath", "Custom")]
        [string]$NormalizationType,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomNormalization,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveRelativePaths = $true,

        [Parameter(Mandatory = $false)]
        [switch]$PreserveDriveLetters = $true,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveTrailingSlash = $true,

        [Parameter(Mandatory = $false)]
        [switch]$NormalizeCase = $false,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Importer la fonction Normalize-RoadmapPath
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $privatePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Private\PathManipulation"
    $normalizePath = Join-Path -Path $privatePath -ChildPath "Normalize-RoadmapPath.ps1"
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $normalizePath)) {
        $errorMsg = "Le fichier Normalize-RoadmapPath.ps1 est introuvable Ã  l'emplacement : $normalizePath"
        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
            return $Path
        }
    }
    
    # Importer la fonction
    . $normalizePath

    # Appeler la fonction Normalize-RoadmapPath
    $params = @{
        Path = $Path
        NormalizationType = $NormalizationType
    }
    
    if ($PSBoundParameters.ContainsKey('BasePath')) {
        $params['BasePath'] = $BasePath
    }
    
    if ($PSBoundParameters.ContainsKey('CustomNormalization')) {
        $params['CustomNormalization'] = $CustomNormalization
    }
    
    if ($PSBoundParameters.ContainsKey('ResolveRelativePaths')) {
        $params['ResolveRelativePaths'] = $ResolveRelativePaths
    }
    
    if ($PSBoundParameters.ContainsKey('PreserveDriveLetters')) {
        $params['PreserveDriveLetters'] = $PreserveDriveLetters
    }
    
    if ($PSBoundParameters.ContainsKey('RemoveTrailingSlash')) {
        $params['RemoveTrailingSlash'] = $RemoveTrailingSlash
    }
    
    if ($PSBoundParameters.ContainsKey('NormalizeCase')) {
        $params['NormalizeCase'] = $NormalizeCase
    }
    
    if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
        $params['ErrorMessage'] = $ErrorMessage
    }
    
    if ($PSBoundParameters.ContainsKey('ThrowOnFailure')) {
        $params['ThrowOnFailure'] = $ThrowOnFailure
    }
    
    return Normalize-RoadmapPath @params
}
