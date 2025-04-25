<#
.SYNOPSIS
    Résout un chemin en chemin absolu.

.DESCRIPTION
    La fonction Resolve-PathToAbsolute résout un chemin en chemin absolu.
    Elle prend en charge différentes options de résolution et peut être utilisée pour
    résoudre les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin à résoudre.

.PARAMETER ResolutionType
    Le type de résolution à effectuer. Valeurs possibles :
    - FullPath : Résout le chemin en chemin absolu complet
    - RelativePath : Résout le chemin en chemin relatif par rapport à un chemin de base
    - ParentPath : Résout le chemin parent
    - FileName : Résout le nom de fichier
    - FileNameWithoutExtension : Résout le nom de fichier sans extension
    - Extension : Résout l'extension du fichier
    - DirectoryName : Résout le nom du répertoire
    - RootPath : Résout le chemin racine
    - PathRoot : Résout la racine du chemin
    - TempPath : Résout un chemin temporaire
    - RandomPath : Résout un chemin aléatoire
    - EnvironmentPath : Résout un chemin d'environnement
    - Custom : Utilise une résolution personnalisée

.PARAMETER BasePath
    Le chemin de base à utiliser pour la résolution de type RelativePath.
    Par défaut, c'est le répertoire courant.

.PARAMETER CustomResolution
    La fonction de résolution personnalisée à utiliser.
    Utilisé uniquement lorsque ResolutionType est "Custom".

.PARAMETER EnvironmentVariable
    La variable d'environnement à utiliser pour la résolution de type EnvironmentPath.

.PARAMETER CreateIfNotExists
    Indique si le chemin doit être créé s'il n'existe pas.
    Par défaut, c'est $false.

.PARAMETER Force
    Indique si la résolution doit être forcée.
    Par défaut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la résolution.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la résolution.

.EXAMPLE
    Resolve-PathToAbsolute -Path ".\folder\file.txt"
    Résout le chemin relatif ".\folder\file.txt" en chemin absolu complet.

.EXAMPLE
    Resolve-PathToAbsolute -Path "C:\folder\file.txt" -ResolutionType FileName
    Résout le nom de fichier "file.txt" à partir du chemin "C:\folder\file.txt".

.OUTPUTS
    [string] Le chemin résolu.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Resolve-PathToAbsolute {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("FullPath", "RelativePath", "ParentPath", "FileName", "FileNameWithoutExtension", "Extension", "DirectoryName", "RootPath", "PathRoot", "TempPath", "RandomPath", "EnvironmentPath", "Custom")]
        [string]$ResolutionType = "FullPath",

        [Parameter(Mandatory = $false)]
        [string]$BasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomResolution,

        [Parameter(Mandatory = $false)]
        [string]$EnvironmentVariable,

        [Parameter(Mandatory = $false)]
        [switch]$CreateIfNotExists,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Importer la fonction Resolve-RoadmapPath
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $privatePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Private\PathManipulation"
    $resolvePath = Join-Path -Path $privatePath -ChildPath "Resolve-RoadmapPath.ps1"
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $resolvePath)) {
        $errorMsg = "Le fichier Resolve-RoadmapPath.ps1 est introuvable à l'emplacement : $resolvePath"
        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
            return $Path
        }
    }
    
    # Importer la fonction
    . $resolvePath

    # Appeler la fonction Resolve-RoadmapPath
    $params = @{
        Path = $Path
        ResolutionType = $ResolutionType
    }
    
    if ($PSBoundParameters.ContainsKey('BasePath')) {
        $params['BasePath'] = $BasePath
    }
    
    if ($PSBoundParameters.ContainsKey('CustomResolution')) {
        $params['CustomResolution'] = $CustomResolution
    }
    
    if ($PSBoundParameters.ContainsKey('EnvironmentVariable')) {
        $params['EnvironmentVariable'] = $EnvironmentVariable
    }
    
    if ($PSBoundParameters.ContainsKey('CreateIfNotExists')) {
        $params['CreateIfNotExists'] = $CreateIfNotExists
    }
    
    if ($PSBoundParameters.ContainsKey('Force')) {
        $params['Force'] = $Force
    }
    
    if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
        $params['ErrorMessage'] = $ErrorMessage
    }
    
    if ($PSBoundParameters.ContainsKey('ThrowOnFailure')) {
        $params['ThrowOnFailure'] = $ThrowOnFailure
    }
    
    return Resolve-RoadmapPath @params
}
