<#
.SYNOPSIS
    Teste la validitÃ© d'un chemin de fichier ou de rÃ©pertoire selon diffÃ©rents critÃ¨res.

.DESCRIPTION
    La fonction Test-PathValidity teste la validitÃ© d'un chemin de fichier ou de rÃ©pertoire selon diffÃ©rents critÃ¨res.
    Elle prend en charge diffÃ©rents types de tests et peut Ãªtre utilisÃ©e pour
    valider les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin Ã  tester.

.PARAMETER TestType
    Le type de test Ã  effectuer. Valeurs possibles :
    - Exists : VÃ©rifie si le chemin existe
    - IsFile : VÃ©rifie si le chemin est un fichier
    - IsDirectory : VÃ©rifie si le chemin est un rÃ©pertoire
    - IsReadable : VÃ©rifie si le chemin est lisible
    - IsWritable : VÃ©rifie si le chemin est modifiable
    - IsHidden : VÃ©rifie si le chemin est cachÃ©
    - IsRooted : VÃ©rifie si le chemin est absolu
    - IsRelative : VÃ©rifie si le chemin est relatif
    - IsValid : VÃ©rifie si le chemin est valide
    - HasExtension : VÃ©rifie si le chemin a une extension
    - HasParent : VÃ©rifie si le chemin a un parent
    - MatchesPattern : VÃ©rifie si le chemin correspond Ã  un motif
    - Custom : Utilise un test personnalisÃ©

.PARAMETER CustomTest
    La fonction de test personnalisÃ©e Ã  utiliser.
    UtilisÃ© uniquement lorsque TestType est "Custom".

.PARAMETER Pattern
    Le motif Ã  utiliser pour le test de type MatchesPattern.

.PARAMETER Extension
    L'extension Ã  vÃ©rifier pour le test de type HasExtension.
    Si non spÃ©cifiÃ©, vÃ©rifie simplement si le chemin a une extension.

.PARAMETER IgnoreCase
    Indique si la casse doit Ãªtre ignorÃ©e lors du test.
    Par dÃ©faut, c'est $false.

.PARAMETER Recurse
    Indique si le test doit Ãªtre rÃ©cursif pour les rÃ©pertoires.
    Par dÃ©faut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec du test.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec du test.

.EXAMPLE
    Test-PathValidity -Path "C:\folder\file.txt" -TestType Exists
    VÃ©rifie si le fichier "C:\folder\file.txt" existe.

.EXAMPLE
    Test-PathValidity -Path "C:\folder" -TestType IsDirectory
    VÃ©rifie si "C:\folder" est un rÃ©pertoire.

.OUTPUTS
    [bool] Le rÃ©sultat du test.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-21
#>
function Test-PathValidity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Exists", "IsFile", "IsDirectory", "IsReadable", "IsWritable", "IsHidden", "IsRooted", "IsRelative", "IsValid", "HasExtension", "HasParent", "MatchesPattern", "Custom")]
        [string]$TestType,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomTest,

        [Parameter(Mandatory = $false)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [string]$Extension,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Importer la fonction Test-RoadmapPath
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $privatePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Private\PathManipulation"
    $testPath = Join-Path -Path $privatePath -ChildPath "Test-RoadmapPath.ps1"
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $testPath)) {
        $errorMsg = "Le fichier Test-RoadmapPath.ps1 est introuvable Ã  l'emplacement : $testPath"
        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
            return $false
        }
    }
    
    # Importer la fonction
    . $testPath

    # Appeler la fonction Test-RoadmapPath
    $params = @{
        Path = $Path
        TestType = $TestType
    }
    
    if ($PSBoundParameters.ContainsKey('CustomTest')) {
        $params['CustomTest'] = $CustomTest
    }
    
    if ($PSBoundParameters.ContainsKey('Pattern')) {
        $params['Pattern'] = $Pattern
    }
    
    if ($PSBoundParameters.ContainsKey('Extension')) {
        $params['Extension'] = $Extension
    }
    
    if ($PSBoundParameters.ContainsKey('IgnoreCase')) {
        $params['IgnoreCase'] = $IgnoreCase
    }
    
    if ($PSBoundParameters.ContainsKey('Recurse')) {
        $params['Recurse'] = $Recurse
    }
    
    if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
        $params['ErrorMessage'] = $ErrorMessage
    }
    
    if ($PSBoundParameters.ContainsKey('ThrowOnFailure')) {
        $params['ThrowOnFailure'] = $ThrowOnFailure
    }
    
    return Test-RoadmapPath @params
}
