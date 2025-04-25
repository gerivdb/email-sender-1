<#
.SYNOPSIS
    Convertit un chemin en chemin normalisé.

.DESCRIPTION
    La fonction ConvertTo-NormalizedPath convertit un chemin en chemin normalisé.
    Elle prend en charge différentes options de normalisation et peut être utilisée pour
    normaliser les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin à normaliser.

.PARAMETER NormalizationType
    Le type de normalisation à effectuer. Valeurs possibles :
    - FullPath : Convertit le chemin en chemin absolu complet
    - RelativePath : Convertit le chemin en chemin relatif par rapport à un chemin de base
    - UnixPath : Convertit le chemin en format Unix (séparateurs /)
    - WindowsPath : Convertit le chemin en format Windows (séparateurs \)
    - UNCPath : Convertit le chemin en format UNC (\\server\share)
    - URLPath : Convertit le chemin en format URL (file:///)
    - Custom : Utilise une normalisation personnalisée

.PARAMETER BasePath
    Le chemin de base à utiliser pour la normalisation de type RelativePath.
    Par défaut, c'est le répertoire courant.

.PARAMETER CustomNormalization
    La fonction de normalisation personnalisée à utiliser.
    Utilisé uniquement lorsque NormalizationType est "Custom".

.PARAMETER ResolveRelativePaths
    Indique si les chemins relatifs doivent être résolus.
    Par défaut, c'est $true.

.PARAMETER PreserveDriveLetters
    Indique si les lettres de lecteur doivent être préservées.
    Par défaut, c'est $true.

.PARAMETER RemoveTrailingSlash
    Indique si les barres obliques finales doivent être supprimées.
    Par défaut, c'est $true.

.PARAMETER NormalizeCase
    Indique si la casse du chemin doit être normalisée.
    Par défaut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la normalisation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la normalisation.

.EXAMPLE
    ConvertTo-NormalizedPath -Path ".\folder\file.txt" -NormalizationType FullPath
    Normalise le chemin relatif ".\folder\file.txt" en chemin absolu complet.

.EXAMPLE
    ConvertTo-NormalizedPath -Path "C:\folder\file.txt" -NormalizationType UnixPath
    Convertit le chemin Windows "C:\folder\file.txt" en format Unix "/c/folder/file.txt".

.OUTPUTS
    [string] Le chemin normalisé.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
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
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $normalizePath)) {
        $errorMsg = "Le fichier Normalize-RoadmapPath.ps1 est introuvable à l'emplacement : $normalizePath"
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
