<#
.SYNOPSIS
    RÃ©sout un chemin en chemin absolu.

.DESCRIPTION
    La fonction Resolve-PathToAbsolute rÃ©sout un chemin en chemin absolu.
    Elle prend en charge diffÃ©rentes options de rÃ©solution et peut Ãªtre utilisÃ©e pour
    rÃ©soudre les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin Ã  rÃ©soudre.

.PARAMETER ResolutionType
    Le type de rÃ©solution Ã  effectuer. Valeurs possibles :
    - FullPath : RÃ©sout le chemin en chemin absolu complet
    - RelativePath : RÃ©sout le chemin en chemin relatif par rapport Ã  un chemin de base
    - ParentPath : RÃ©sout le chemin parent
    - FileName : RÃ©sout le nom de fichier
    - FileNameWithoutExtension : RÃ©sout le nom de fichier sans extension
    - Extension : RÃ©sout l'extension du fichier
    - DirectoryName : RÃ©sout le nom du rÃ©pertoire
    - RootPath : RÃ©sout le chemin racine
    - PathRoot : RÃ©sout la racine du chemin
    - TempPath : RÃ©sout un chemin temporaire
    - RandomPath : RÃ©sout un chemin alÃ©atoire
    - EnvironmentPath : RÃ©sout un chemin d'environnement
    - Custom : Utilise une rÃ©solution personnalisÃ©e

.PARAMETER BasePath
    Le chemin de base Ã  utiliser pour la rÃ©solution de type RelativePath.
    Par dÃ©faut, c'est le rÃ©pertoire courant.

.PARAMETER CustomResolution
    La fonction de rÃ©solution personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque ResolutionType est "Custom".

.PARAMETER EnvironmentVariable
    La variable d'environnement Ã  utiliser pour la rÃ©solution de type EnvironmentPath.

.PARAMETER CreateIfNotExists
    Indique si le chemin doit Ãªtre crÃ©Ã© s'il n'existe pas.
    Par dÃ©faut, c'est $false.

.PARAMETER Force
    Indique si la rÃ©solution doit Ãªtre forcÃ©e.
    Par dÃ©faut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la rÃ©solution.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la rÃ©solution.

.EXAMPLE
    Resolve-PathToAbsolute -Path ".\folder\file.txt"
    RÃ©sout le chemin relatif ".\folder\file.txt" en chemin absolu complet.

.EXAMPLE
    Resolve-PathToAbsolute -Path "C:\folder\file.txt" -ResolutionType FileName
    RÃ©sout le nom de fichier "file.txt" Ã  partir du chemin "C:\folder\file.txt".

.OUTPUTS
    [string] Le chemin rÃ©solu.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
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
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $resolvePath)) {
        $errorMsg = "Le fichier Resolve-RoadmapPath.ps1 est introuvable Ã  l'emplacement : $resolvePath"
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
