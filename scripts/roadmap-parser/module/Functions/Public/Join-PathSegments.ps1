<#
.SYNOPSIS
    Joint plusieurs segments de chemin en un seul chemin.

.DESCRIPTION
    La fonction Join-PathSegments joint plusieurs segments de chemin en un seul chemin.
    Elle prend en charge différentes options de jointure et peut être utilisée pour
    joindre les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin de base.

.PARAMETER ChildPath
    Les chemins enfants à joindre au chemin de base.

.PARAMETER JoinType
    Le type de jointure à effectuer. Valeurs possibles :
    - Simple : Jointure simple (utilise [System.IO.Path]::Combine)
    - Normalized : Jointure normalisée (normalise les chemins avant de les joindre)
    - Relative : Jointure relative (crée un chemin relatif)
    - Absolute : Jointure absolue (crée un chemin absolu)
    - Unix : Jointure Unix (utilise des séparateurs Unix)
    - Windows : Jointure Windows (utilise des séparateurs Windows)
    - UNC : Jointure UNC (crée un chemin UNC)
    - URL : Jointure URL (crée un chemin URL)
    - Custom : Jointure personnalisée

.PARAMETER CustomJoin
    La fonction de jointure personnalisée à utiliser.
    Utilisé uniquement lorsque JoinType est "Custom".

.PARAMETER Separator
    Le séparateur à utiliser pour la jointure.
    Par défaut, c'est le séparateur de répertoire du système.

.PARAMETER NormalizePaths
    Indique si les chemins doivent être normalisés avant la jointure.
    Par défaut, c'est $false.

.PARAMETER ResolveRelativePaths
    Indique si les chemins relatifs doivent être résolus.
    Par défaut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la jointure.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la jointure.

.EXAMPLE
    Join-PathSegments -Path "C:\folder" -ChildPath "file.txt"
    Joint le chemin "C:\folder" avec "file.txt" pour obtenir "C:\folder\file.txt".

.EXAMPLE
    Join-PathSegments -Path "C:\folder" -ChildPath "subfolder", "file.txt" -JoinType Normalized
    Joint le chemin "C:\folder" avec "subfolder" et "file.txt" en normalisant les chemins.

.OUTPUTS
    [string] Le chemin joint.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
#>
function Join-PathSegments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyString()]
        [string[]]$ChildPath,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("Simple", "Normalized", "Relative", "Absolute", "Unix", "Windows", "UNC", "URL", "Custom")]
        [string]$JoinType = "Simple",

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomJoin,

        [Parameter(Mandatory = $false)]
        [string]$Separator = [System.IO.Path]::DirectorySeparatorChar,

        [Parameter(Mandatory = $false)]
        [switch]$NormalizePaths,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveRelativePaths,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Importer la fonction Join-RoadmapPath
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $privatePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Private\PathManipulation"
    $joinPath = Join-Path -Path $privatePath -ChildPath "Join-RoadmapPath.ps1"
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $joinPath)) {
        $errorMsg = "Le fichier Join-RoadmapPath.ps1 est introuvable à l'emplacement : $joinPath"
        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
            return $Path
        }
    }
    
    # Importer la fonction
    . $joinPath

    # Appeler la fonction Join-RoadmapPath
    $params = @{
        Path = $Path
        ChildPath = $ChildPath
        JoinType = $JoinType
    }
    
    if ($PSBoundParameters.ContainsKey('CustomJoin')) {
        $params['CustomJoin'] = $CustomJoin
    }
    
    if ($PSBoundParameters.ContainsKey('Separator')) {
        $params['Separator'] = $Separator
    }
    
    if ($PSBoundParameters.ContainsKey('NormalizePaths')) {
        $params['NormalizePaths'] = $NormalizePaths
    }
    
    if ($PSBoundParameters.ContainsKey('ResolveRelativePaths')) {
        $params['ResolveRelativePaths'] = $ResolveRelativePaths
    }
    
    if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
        $params['ErrorMessage'] = $ErrorMessage
    }
    
    if ($PSBoundParameters.ContainsKey('ThrowOnFailure')) {
        $params['ThrowOnFailure'] = $ThrowOnFailure
    }
    
    return Join-RoadmapPath @params
}
