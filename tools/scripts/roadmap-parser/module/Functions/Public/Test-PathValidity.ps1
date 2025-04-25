<#
.SYNOPSIS
    Teste la validité d'un chemin de fichier ou de répertoire selon différents critères.

.DESCRIPTION
    La fonction Test-PathValidity teste la validité d'un chemin de fichier ou de répertoire selon différents critères.
    Elle prend en charge différents types de tests et peut être utilisée pour
    valider les chemins du module RoadmapParser.

.PARAMETER Path
    Le chemin à tester.

.PARAMETER TestType
    Le type de test à effectuer. Valeurs possibles :
    - Exists : Vérifie si le chemin existe
    - IsFile : Vérifie si le chemin est un fichier
    - IsDirectory : Vérifie si le chemin est un répertoire
    - IsReadable : Vérifie si le chemin est lisible
    - IsWritable : Vérifie si le chemin est modifiable
    - IsHidden : Vérifie si le chemin est caché
    - IsRooted : Vérifie si le chemin est absolu
    - IsRelative : Vérifie si le chemin est relatif
    - IsValid : Vérifie si le chemin est valide
    - HasExtension : Vérifie si le chemin a une extension
    - HasParent : Vérifie si le chemin a un parent
    - MatchesPattern : Vérifie si le chemin correspond à un motif
    - Custom : Utilise un test personnalisé

.PARAMETER CustomTest
    La fonction de test personnalisée à utiliser.
    Utilisé uniquement lorsque TestType est "Custom".

.PARAMETER Pattern
    Le motif à utiliser pour le test de type MatchesPattern.

.PARAMETER Extension
    L'extension à vérifier pour le test de type HasExtension.
    Si non spécifié, vérifie simplement si le chemin a une extension.

.PARAMETER IgnoreCase
    Indique si la casse doit être ignorée lors du test.
    Par défaut, c'est $false.

.PARAMETER Recurse
    Indique si le test doit être récursif pour les répertoires.
    Par défaut, c'est $false.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec du test.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec du test.

.EXAMPLE
    Test-PathValidity -Path "C:\folder\file.txt" -TestType Exists
    Vérifie si le fichier "C:\folder\file.txt" existe.

.EXAMPLE
    Test-PathValidity -Path "C:\folder" -TestType IsDirectory
    Vérifie si "C:\folder" est un répertoire.

.OUTPUTS
    [bool] Le résultat du test.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-21
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
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $testPath)) {
        $errorMsg = "Le fichier Test-RoadmapPath.ps1 est introuvable à l'emplacement : $testPath"
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
