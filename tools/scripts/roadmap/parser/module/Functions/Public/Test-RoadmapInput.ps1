<#
.SYNOPSIS
    Valide les entrÃ©es des fonctions du module RoadmapParser.

.DESCRIPTION
    La fonction Test-RoadmapInput valide les entrÃ©es des fonctions du module RoadmapParser.
    Elle combine les diffÃ©rentes fonctions de validation et peut Ãªtre utilisÃ©e pour
    valider les entrÃ©es des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur Ã  valider.

.PARAMETER Type
    Le type de donnÃ©es Ã  valider. Valeurs possibles :
    - String : VÃ©rifie que la valeur est une chaÃ®ne de caractÃ¨res
    - Integer : VÃ©rifie que la valeur est un entier
    - Decimal : VÃ©rifie que la valeur est un nombre dÃ©cimal
    - Boolean : VÃ©rifie que la valeur est un boolÃ©en
    - DateTime : VÃ©rifie que la valeur est une date/heure
    - Array : VÃ©rifie que la valeur est un tableau
    - Hashtable : VÃ©rifie que la valeur est une table de hachage
    - PSObject : VÃ©rifie que la valeur est un objet PowerShell
    - ScriptBlock : VÃ©rifie que la valeur est un bloc de script
    - Null : VÃ©rifie que la valeur est null
    - NotNull : VÃ©rifie que la valeur n'est pas null
    - Empty : VÃ©rifie que la valeur est vide
    - NotEmpty : VÃ©rifie que la valeur n'est pas vide

.PARAMETER Format
    Le format Ã  valider. Valeurs possibles :
    - Email : VÃ©rifie que la valeur est une adresse email valide
    - URL : VÃ©rifie que la valeur est une URL valide
    - IPAddress : VÃ©rifie que la valeur est une adresse IP valide
    - PhoneNumber : VÃ©rifie que la valeur est un numÃ©ro de tÃ©lÃ©phone valide
    - ZipCode : VÃ©rifie que la valeur est un code postal valide
    - Date : VÃ©rifie que la valeur est une date valide
    - Time : VÃ©rifie que la valeur est une heure valide
    - DateTime : VÃ©rifie que la valeur est une date/heure valide
    - Guid : VÃ©rifie que la valeur est un GUID valide
    - FilePath : VÃ©rifie que la valeur est un chemin de fichier valide
    - DirectoryPath : VÃ©rifie que la valeur est un chemin de rÃ©pertoire valide
    - Custom : Utilise une expression rÃ©guliÃ¨re personnalisÃ©e

.PARAMETER Pattern
    L'expression rÃ©guliÃ¨re personnalisÃ©e Ã  utiliser pour la validation.
    UtilisÃ© uniquement lorsque Format est "Custom".

.PARAMETER Min
    La valeur minimale de la plage.

.PARAMETER Max
    La valeur maximale de la plage.

.PARAMETER MinLength
    La longueur minimale de la valeur.

.PARAMETER MaxLength
    La longueur maximale de la valeur.

.PARAMETER MinCount
    Le nombre minimal d'Ã©lÃ©ments dans la collection.

.PARAMETER MaxCount
    Le nombre maximal d'Ã©lÃ©ments dans la collection.

.PARAMETER ValidationFunction
    La fonction de validation personnalisÃ©e Ã  utiliser.
    Cette fonction doit prendre un paramÃ¨tre (la valeur Ã  valider) et retourner un boolÃ©en.

.PARAMETER ValidationScript
    Le script de validation personnalisÃ© Ã  utiliser.
    Ce script doit prendre un paramÃ¨tre (la valeur Ã  valider) et retourner un boolÃ©en.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation.

.EXAMPLE
    Test-RoadmapInput -Value "user@example.com" -Type String -Format Email
    VÃ©rifie que la valeur "user@example.com" est une chaÃ®ne de caractÃ¨res et une adresse email valide.

.EXAMPLE
    Test-RoadmapInput -Value 42 -Type Integer -Min 0 -Max 100 -ThrowOnFailure
    VÃ©rifie que la valeur 42 est un entier compris entre 0 et 100, et lÃ¨ve une exception si ce n'est pas le cas.

.EXAMPLE
    Test-RoadmapInput -Value "Hello" -Type String -MinLength 3 -MaxLength 10 -ValidationFunction { param($val) $val -match "^[a-zA-Z]+$" }
    VÃ©rifie que la chaÃ®ne "Hello" a une longueur comprise entre 3 et 10 caractÃ¨res et ne contient que des lettres.

.OUTPUTS
    [bool] Indique si la validation a rÃ©ussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function Test-RoadmapInput {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet("String", "Integer", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Null", "NotNull", "Empty", "NotEmpty")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Email", "URL", "IPAddress", "PhoneNumber", "ZipCode", "Date", "Time", "DateTime", "Guid", "FilePath", "DirectoryPath", "Custom")]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        $Min,

        [Parameter(Mandatory = $false)]
        $Max,

        [Parameter(Mandatory = $false)]
        [int]$MinLength,

        [Parameter(Mandatory = $false)]
        [int]$MaxLength,

        [Parameter(Mandatory = $false)]
        [int]$MinCount,

        [Parameter(Mandatory = $false)]
        [int]$MaxCount,

        [Parameter(Mandatory = $false, ParameterSetName = "Function")]
        [scriptblock]$ValidationFunction,

        [Parameter(Mandatory = $false, ParameterSetName = "Script")]
        [scriptblock]$ValidationScript,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Les fonctions de validation sont dÃ©jÃ  importÃ©es par le module

    # Initialiser le rÃ©sultat de la validation
    $isValid = $true

    # Valider le type de donnÃ©es
    if ($PSBoundParameters.ContainsKey('Type')) {
        $dataTypeParams = @{
            Value          = $Value
            Type           = $Type
            ThrowOnFailure = $false
        }

        if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
            $dataTypeParams['ErrorMessage'] = $ErrorMessage
        }

        $isValid = $isValid -and (Test-DataType @dataTypeParams)

        if (-not $isValid -and $ThrowOnFailure) {
            $errorMsg = if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $ErrorMessage
            } else {
                "La valeur ne correspond pas au type de donnÃ©es $Type."
            }

            throw $errorMsg
        }
    }

    # Valider le format
    if ($PSBoundParameters.ContainsKey('Format') -and $isValid) {
        $formatParams = @{
            Value          = $Value
            Format         = $Format
            ThrowOnFailure = $false
        }

        if ($PSBoundParameters.ContainsKey('Pattern')) {
            $formatParams['Pattern'] = $Pattern
        }

        if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
            $formatParams['ErrorMessage'] = $ErrorMessage
        }

        $isValid = $isValid -and (Test-Format @formatParams)

        if (-not $isValid -and $ThrowOnFailure) {
            $errorMsg = if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $ErrorMessage
            } else {
                "La valeur ne correspond pas au format $Format."
            }

            throw $errorMsg
        }
    }

    # Valider la plage
    if (($PSBoundParameters.ContainsKey('Min') -or $PSBoundParameters.ContainsKey('Max') -or
            $PSBoundParameters.ContainsKey('MinLength') -or $PSBoundParameters.ContainsKey('MaxLength') -or
            $PSBoundParameters.ContainsKey('MinCount') -or $PSBoundParameters.ContainsKey('MaxCount')) -and $isValid) {
        $rangeParams = @{
            Value          = $Value
            ThrowOnFailure = $false
        }

        if ($PSBoundParameters.ContainsKey('Min')) {
            $rangeParams['Min'] = $Min
        }

        if ($PSBoundParameters.ContainsKey('Max')) {
            $rangeParams['Max'] = $Max
        }

        if ($PSBoundParameters.ContainsKey('MinLength')) {
            $rangeParams['MinLength'] = $MinLength
        }

        if ($PSBoundParameters.ContainsKey('MaxLength')) {
            $rangeParams['MaxLength'] = $MaxLength
        }

        if ($PSBoundParameters.ContainsKey('MinCount')) {
            $rangeParams['MinCount'] = $MinCount
        }

        if ($PSBoundParameters.ContainsKey('MaxCount')) {
            $rangeParams['MaxCount'] = $MaxCount
        }

        if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
            $rangeParams['ErrorMessage'] = $ErrorMessage
        }

        $isValid = $isValid -and (Test-Range @rangeParams)

        if (-not $isValid -and $ThrowOnFailure) {
            $errorMsg = if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $ErrorMessage
            } else {
                "La valeur ne correspond pas Ã  la plage spÃ©cifiÃ©e."
            }

            throw $errorMsg
        }
    }

    # Valider avec une fonction personnalisÃ©e
    if (($PSBoundParameters.ContainsKey('ValidationFunction') -or $PSBoundParameters.ContainsKey('ValidationScript')) -and $isValid) {
        $customParams = @{
            Value          = $Value
            ThrowOnFailure = $false
        }

        if ($PSBoundParameters.ContainsKey('ValidationFunction')) {
            $customParams['ValidationFunction'] = $ValidationFunction
        }

        if ($PSBoundParameters.ContainsKey('ValidationScript')) {
            $customParams['ValidationScript'] = $ValidationScript
        }

        if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
            $customParams['ErrorMessage'] = $ErrorMessage
        }

        $isValid = $isValid -and (Test-Custom @customParams)

        if (-not $isValid -and $ThrowOnFailure) {
            $errorMsg = if ($PSBoundParameters.ContainsKey('ErrorMessage')) {
                $ErrorMessage
            } else {
                "La valeur ne correspond pas aux critÃ¨res de validation personnalisÃ©s."
            }

            throw $errorMsg
        }
    }

    return $isValid
}
