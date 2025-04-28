<#
.SYNOPSIS
    Valide si une valeur est dans une plage spÃ©cifiÃ©e.

.DESCRIPTION
    La fonction Test-Range valide si une valeur est dans une plage spÃ©cifiÃ©e.
    Elle prend en charge diffÃ©rents types de plages et peut Ãªtre utilisÃ©e pour
    valider les entrÃ©es des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur Ã  valider.

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

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation.

.EXAMPLE
    Test-Range -Value 42 -Min 0 -Max 100
    VÃ©rifie que la valeur 42 est comprise entre 0 et 100.

.EXAMPLE
    Test-Range -Value "Hello" -MinLength 3 -MaxLength 10 -ThrowOnFailure
    VÃ©rifie que la chaÃ®ne "Hello" a une longueur comprise entre 3 et 10 caractÃ¨res, et lÃ¨ve une exception si ce n'est pas le cas.

.EXAMPLE
    Test-Range -Value @(1, 2, 3) -MinCount 1 -MaxCount 5
    VÃ©rifie que le tableau @(1, 2, 3) contient entre 1 et 5 Ã©lÃ©ments.

.OUTPUTS
    [bool] Indique si la validation a rÃ©ussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
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

    # Initialiser le rÃ©sultat de la validation
    $isValid = $true
    $validationErrors = @()

    # Valider la plage de valeurs
    if ($PSBoundParameters.ContainsKey('Min') -and $PSBoundParameters.ContainsKey('Max')) {
        if ($Value -lt $Min -or $Value -gt $Max) {
            $isValid = $false
            $validationErrors += "La valeur doit Ãªtre comprise entre $Min et $Max."
        }
    } elseif ($PSBoundParameters.ContainsKey('Min')) {
        if ($Value -lt $Min) {
            $isValid = $false
            $validationErrors += "La valeur doit Ãªtre supÃ©rieure ou Ã©gale Ã  $Min."
        }
    } elseif ($PSBoundParameters.ContainsKey('Max')) {
        if ($Value -gt $Max) {
            $isValid = $false
            $validationErrors += "La valeur doit Ãªtre infÃ©rieure ou Ã©gale Ã  $Max."
        }
    }

    # Valider la longueur
    if ($PSBoundParameters.ContainsKey('MinLength') -or $PSBoundParameters.ContainsKey('MaxLength')) {
        if ($null -eq $Value) {
            $isValid = $false
            $validationErrors += "La valeur ne peut pas Ãªtre null pour valider la longueur."
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
                $validationErrors += "La longueur doit Ãªtre supÃ©rieure ou Ã©gale Ã  $MinLength."
            }

            if ($PSBoundParameters.ContainsKey('MaxLength') -and $length -gt $MaxLength) {
                $isValid = $false
                $validationErrors += "La longueur doit Ãªtre infÃ©rieure ou Ã©gale Ã  $MaxLength."
            }
        }
    }

    # Valider le nombre d'Ã©lÃ©ments
    if ($PSBoundParameters.ContainsKey('MinCount') -or $PSBoundParameters.ContainsKey('MaxCount')) {
        if ($null -eq $Value) {
            $isValid = $false
            $validationErrors += "La valeur ne peut pas Ãªtre null pour valider le nombre d'Ã©lÃ©ments."
        } elseif (-not ($Value -is [array] -or $Value -is [System.Collections.ICollection])) {
            $isValid = $false
            $validationErrors += "La validation du nombre d'Ã©lÃ©ments n'est prise en charge que pour les collections."
        } else {
            $count = $Value.Count

            if ($PSBoundParameters.ContainsKey('MinCount') -and $count -lt $MinCount) {
                $isValid = $false
                $validationErrors += "Le nombre d'Ã©lÃ©ments doit Ãªtre supÃ©rieur ou Ã©gal Ã  $MinCount."
            }

            if ($PSBoundParameters.ContainsKey('MaxCount') -and $count -gt $MaxCount) {
                $isValid = $false
                $validationErrors += "Le nombre d'Ã©lÃ©ments doit Ãªtre infÃ©rieur ou Ã©gal Ã  $MaxCount."
            }
        }
    }

    # GÃ©rer l'Ã©chec de la validation
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
