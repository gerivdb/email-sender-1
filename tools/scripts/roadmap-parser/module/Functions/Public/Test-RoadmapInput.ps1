<#
.SYNOPSIS
    Valide les entrées des fonctions du module RoadmapParser.

.DESCRIPTION
    La fonction Test-RoadmapInput valide les entrées des fonctions du module RoadmapParser.
    Elle combine les différentes fonctions de validation et peut être utilisée pour
    valider les entrées des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur à valider.

.PARAMETER Type
    Le type de données à valider. Valeurs possibles :
    - String : Vérifie que la valeur est une chaîne de caractères
    - Integer : Vérifie que la valeur est un entier
    - Decimal : Vérifie que la valeur est un nombre décimal
    - Boolean : Vérifie que la valeur est un booléen
    - DateTime : Vérifie que la valeur est une date/heure
    - Array : Vérifie que la valeur est un tableau
    - Hashtable : Vérifie que la valeur est une table de hachage
    - PSObject : Vérifie que la valeur est un objet PowerShell
    - ScriptBlock : Vérifie que la valeur est un bloc de script
    - Null : Vérifie que la valeur est null
    - NotNull : Vérifie que la valeur n'est pas null
    - Empty : Vérifie que la valeur est vide
    - NotEmpty : Vérifie que la valeur n'est pas vide

.PARAMETER Format
    Le format à valider. Valeurs possibles :
    - Email : Vérifie que la valeur est une adresse email valide
    - URL : Vérifie que la valeur est une URL valide
    - IPAddress : Vérifie que la valeur est une adresse IP valide
    - PhoneNumber : Vérifie que la valeur est un numéro de téléphone valide
    - ZipCode : Vérifie que la valeur est un code postal valide
    - Date : Vérifie que la valeur est une date valide
    - Time : Vérifie que la valeur est une heure valide
    - DateTime : Vérifie que la valeur est une date/heure valide
    - Guid : Vérifie que la valeur est un GUID valide
    - FilePath : Vérifie que la valeur est un chemin de fichier valide
    - DirectoryPath : Vérifie que la valeur est un chemin de répertoire valide
    - Custom : Utilise une expression régulière personnalisée

.PARAMETER Pattern
    L'expression régulière personnalisée à utiliser pour la validation.
    Utilisé uniquement lorsque Format est "Custom".

.PARAMETER Min
    La valeur minimale de la plage.

.PARAMETER Max
    La valeur maximale de la plage.

.PARAMETER MinLength
    La longueur minimale de la valeur.

.PARAMETER MaxLength
    La longueur maximale de la valeur.

.PARAMETER MinCount
    Le nombre minimal d'éléments dans la collection.

.PARAMETER MaxCount
    Le nombre maximal d'éléments dans la collection.

.PARAMETER ValidationFunction
    La fonction de validation personnalisée à utiliser.
    Cette fonction doit prendre un paramètre (la valeur à valider) et retourner un booléen.

.PARAMETER ValidationScript
    Le script de validation personnalisé à utiliser.
    Ce script doit prendre un paramètre (la valeur à valider) et retourner un booléen.

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la validation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la validation.

.EXAMPLE
    Test-RoadmapInput -Value "user@example.com" -Type String -Format Email
    Vérifie que la valeur "user@example.com" est une chaîne de caractères et une adresse email valide.

.EXAMPLE
    Test-RoadmapInput -Value 42 -Type Integer -Min 0 -Max 100 -ThrowOnFailure
    Vérifie que la valeur 42 est un entier compris entre 0 et 100, et lève une exception si ce n'est pas le cas.

.EXAMPLE
    Test-RoadmapInput -Value "Hello" -Type String -MinLength 3 -MaxLength 10 -ValidationFunction { param($val) $val -match "^[a-zA-Z]+$" }
    Vérifie que la chaîne "Hello" a une longueur comprise entre 3 et 10 caractères et ne contient que des lettres.

.OUTPUTS
    [bool] Indique si la validation a réussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-20
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

    # Les fonctions de validation sont déjà importées par le module

    # Initialiser le résultat de la validation
    $isValid = $true

    # Valider le type de données
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
                "La valeur ne correspond pas au type de données $Type."
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
                "La valeur ne correspond pas à la plage spécifiée."
            }

            throw $errorMsg
        }
    }

    # Valider avec une fonction personnalisée
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
                "La valeur ne correspond pas aux critères de validation personnalisés."
            }

            throw $errorMsg
        }
    }

    return $isValid
}
