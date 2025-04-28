<#
.SYNOPSIS
    Valide si une valeur correspond Ã  un type de donnÃ©es spÃ©cifique.

.DESCRIPTION
    La fonction Test-DataType valide si une valeur correspond Ã  un type de donnÃ©es spÃ©cifique.
    Elle prend en charge diffÃ©rents types de donnÃ©es courants et peut Ãªtre utilisÃ©e pour
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

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la validation.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la validation.

.EXAMPLE
    Test-DataType -Value "Hello" -Type String
    VÃ©rifie que la valeur "Hello" est une chaÃ®ne de caractÃ¨res.

.EXAMPLE
    Test-DataType -Value 42 -Type Integer -ThrowOnFailure
    VÃ©rifie que la valeur 42 est un entier, et lÃ¨ve une exception si ce n'est pas le cas.

.OUTPUTS
    [bool] Indique si la validation a rÃ©ussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function Test-DataType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("String", "Integer", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Null", "NotNull", "Empty", "NotEmpty")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de la validation
    $isValid = $false

    # Effectuer la validation selon le type
    switch ($Type) {
        "String" {
            $isValid = $Value -is [string]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre une chaÃ®ne de caractÃ¨res."
            }
        }
        "Integer" {
            $isValid = $Value -is [int]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un entier."
            }
        }
        "Decimal" {
            $isValid = $Value -is [decimal] -or $Value -is [double] -or $Value -is [float]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un nombre dÃ©cimal."
            }
        }
        "Boolean" {
            $isValid = $Value -is [bool]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un boolÃ©en."
            }
        }
        "DateTime" {
            $isValid = $Value -is [datetime]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre une date/heure."
            }
        }
        "Array" {
            $isValid = $Value -is [array]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un tableau."
            }
        }
        "Hashtable" {
            $isValid = $Value -is [hashtable]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre une table de hachage."
            }
        }
        "PSObject" {
            $isValid = $Value -is [PSObject]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un objet PowerShell."
            }
        }
        "ScriptBlock" {
            $isValid = $Value -is [scriptblock]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un bloc de script."
            }
        }
        "Null" {
            $isValid = $null -eq $Value
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre null."
            }
        }
        "NotNull" {
            $isValid = $null -ne $Value
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur ne peut pas Ãªtre null."
            }
        }
        "Empty" {
            if ($null -eq $Value) {
                $isValid = $true
            } elseif ($Value -is [string]) {
                $isValid = [string]::IsNullOrEmpty($Value)
            } elseif ($Value -is [array] -or $Value -is [System.Collections.ICollection]) {
                $isValid = $Value.Count -eq 0
            } elseif ($Value -is [hashtable]) {
                $isValid = $Value.Count -eq 0
            } else {
                $isValid = $false
            }
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre vide."
            }
        }
        "NotEmpty" {
            if ($null -eq $Value) {
                $isValid = $false
            } elseif ($Value -is [string]) {
                $isValid = -not [string]::IsNullOrEmpty($Value)
            } elseif ($Value -is [array] -or $Value -is [System.Collections.ICollection]) {
                $isValid = $Value.Count -gt 0
            } elseif ($Value -is [hashtable]) {
                $isValid = $Value.Count -gt 0
            } else {
                $isValid = $true
            }
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur ne peut pas Ãªtre vide."
            }
        }
    }

    # GÃ©rer l'Ã©chec de la validation
    if (-not $isValid) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    return $isValid
}
