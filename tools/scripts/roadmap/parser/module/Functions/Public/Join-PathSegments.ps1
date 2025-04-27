<#
.SYNOPSIS
    Joint plusieurs segments de chemin en un seul chemin.

.DESCRIPTION
    La fonction Join-PathSegments joint plusieurs segments de chemin en un seul chemin.
    Elle prend en charge diffÃ©rentes options de jointure et peut Ãªtre utilisÃ©e pour
    joindre les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin de base.

.PARAMETER ChildPath
    Les chemins enfants Ã  joindre au chemin de base.

.PARAMETER JoinType
    Le type de jointure Ã  effectuer. Valeurs possibles :
    - Simple : Jointure simple (utilise [System.IO.Path]::Combine)
    - Normalized : Jointure normalisÃ©e (normalise les chemins avant de les joindre)
    - Relative : Jointure relative (crÃ©e un chemin relatif)
    - Absolute : Jointure absolue (crÃ©e un chemin absolu)
    - Unix : Jointure Unix (utilise des sÃ©parateurs Unix)
    - Windows : Jointure Windows (utilise des sÃ©parateurs Windows)
    - UNC : Jointure UNC (crÃ©e un chemin UNC)
    - URL : Jointure URL (crÃ©e un chemin URL)
    - Custom : Jointure personnalisÃ©e

.PARAMETER CustomJoin
    La fonction de jointure personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque JoinType est "Custom".

.PARAMETER Separator
    Le sÃ©parateur Ã  utiliser pour la jointure.
    Par dÃ©faut, c'est le sÃ©parateur de rÃ©pertoire du systÃ¨me.

.PARAMETER NormalizePaths
    Indique si les chemins doivent Ãªtre normalisÃ©s avant la jointure.
    Par dÃ©faut, c'est $false.

.PARAMETER ResolveRelativePaths
    Indique si les chemins relatifs doivent Ãªtre rÃ©solus.
    Par dÃ©faut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la jointure.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la jointure.

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
    Date de crÃ©ation: 2023-07-21
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
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $joinPath)) {
        $errorMsg = "Le fichier Join-RoadmapPath.ps1 est introuvable Ã  l'emplacement : $joinPath"
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
