<#
.SYNOPSIS
    Valide si une valeur est dans une plage spécifiée.

.DESCRIPTION
    La fonction Test-Range valide si une valeur est dans une plage spécifiée.
    Elle prend en charge différents types de plages et peut être utilisée pour
    valider les entrées des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur à valider.

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

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la validation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la validation.

.EXAMPLE
    Test-Range -Value 42 -Min 0 -Max 100
    Vérifie que la valeur 42 est comprise entre 0 et 100.

.EXAMPLE
    Test-Range -Value "Hello" -MinLength 3 -MaxLength 10 -ThrowOnFailure
    Vérifie que la chaîne "Hello" a une longueur comprise entre 3 et 10 caractères, et lève une exception si ce n'est pas le cas.

.EXAMPLE
    Test-Range -Value @(1, 2, 3) -MinCount 1 -MaxCount 5
    Vérifie que le tableau @(1, 2, 3) contient entre 1 et 5 éléments.

.OUTPUTS
    [bool] Indique si la validation a réussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-20
#>
function Test-Range {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        $Value,

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

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le résultat de la validation
    $isValid = $true
    $validationErrors = @()

    # Valider la plage de valeurs
    if ($PSBoundParameters.ContainsKey('Min') -and $PSBoundParameters.ContainsKey('Max')) {
        if ($Value -lt $Min -or $Value -gt $Max) {
            $isValid = $false
            $validationErrors += "La valeur doit être comprise entre $Min et $Max."
        }
    } elseif ($PSBoundParameters.ContainsKey('Min')) {
        if ($Value -lt $Min) {
            $isValid = $false
            $validationErrors += "La valeur doit être supérieure ou égale à $Min."
        }
    } elseif ($PSBoundParameters.ContainsKey('Max')) {
        if ($Value -gt $Max) {
            $isValid = $false
            $validationErrors += "La valeur doit être inférieure ou égale à $Max."
        }
    }

    # Valider la longueur
    if ($PSBoundParameters.ContainsKey('MinLength') -or $PSBoundParameters.ContainsKey('MaxLength')) {
        if ($null -eq $Value) {
            $isValid = $false
            $validationErrors += "La valeur ne peut pas être null pour valider la longueur."
        } else {
            $length = 0
            if ($Value -is [string]) {
                $length = $Value.Length
            } elseif ($Value -is [array] -or $Value -is [System.Collections.ICollection]) {
                $length = $Value.Count
            } else {
                $isValid = $false
                $validationErrors += "La validation de longueur n'est pas prise en charge pour ce type de valeur."
            }

            if ($PSBoundParameters.ContainsKey('MinLength') -and $length -lt $MinLength) {
                $isValid = $false
                $validationErrors += "La longueur doit être supérieure ou égale à $MinLength."
            }

            if ($PSBoundParameters.ContainsKey('MaxLength') -and $length -gt $MaxLength) {
                $isValid = $false
                $validationErrors += "La longueur doit être inférieure ou égale à $MaxLength."
            }
        }
    }

    # Valider le nombre d'éléments
    if ($PSBoundParameters.ContainsKey('MinCount') -or $PSBoundParameters.ContainsKey('MaxCount')) {
        if ($null -eq $Value) {
            $isValid = $false
            $validationErrors += "La valeur ne peut pas être null pour valider le nombre d'éléments."
        } elseif (-not ($Value -is [array] -or $Value -is [System.Collections.ICollection])) {
            $isValid = $false
            $validationErrors += "La validation du nombre d'éléments n'est prise en charge que pour les collections."
        } else {
            $count = $Value.Count

            if ($PSBoundParameters.ContainsKey('MinCount') -and $count -lt $MinCount) {
                $isValid = $false
                $validationErrors += "Le nombre d'éléments doit être supérieur ou égal à $MinCount."
            }

            if ($PSBoundParameters.ContainsKey('MaxCount') -and $count -gt $MaxCount) {
                $isValid = $false
                $validationErrors += "Le nombre d'éléments doit être inférieur ou égal à $MaxCount."
            }
        }
    }

    # Gérer l'échec de la validation
    if (-not $isValid) {
        $errorMsg = if (-not [string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage
        } else {
            $validationErrors -join " "
        }

        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
        }
    }

    return $isValid
}
