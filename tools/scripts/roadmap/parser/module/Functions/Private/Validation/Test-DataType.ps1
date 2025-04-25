<#
.SYNOPSIS
    Valide si une valeur correspond à un type de données spécifique.

.DESCRIPTION
    La fonction Test-DataType valide si une valeur correspond à un type de données spécifique.
    Elle prend en charge différents types de données courants et peut être utilisée pour
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

.PARAMETER ErrorMessage
    Le message d'erreur à afficher en cas d'échec de la validation.
    Si non spécifié, un message par défaut sera utilisé.

.PARAMETER ThrowOnFailure
    Indique si une exception doit être levée en cas d'échec de la validation.

.EXAMPLE
    Test-DataType -Value "Hello" -Type String
    Vérifie que la valeur "Hello" est une chaîne de caractères.

.EXAMPLE
    Test-DataType -Value 42 -Type Integer -ThrowOnFailure
    Vérifie que la valeur 42 est un entier, et lève une exception si ce n'est pas le cas.

.OUTPUTS
    [bool] Indique si la validation a réussi.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-20
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

    # Initialiser le résultat de la validation
    $isValid = $false

    # Effectuer la validation selon le type
    switch ($Type) {
        "String" {
            $isValid = $Value -is [string]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être une chaîne de caractères."
            }
        }
        "Integer" {
            $isValid = $Value -is [int]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être un entier."
            }
        }
        "Decimal" {
            $isValid = $Value -is [decimal] -or $Value -is [double] -or $Value -is [float]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être un nombre décimal."
            }
        }
        "Boolean" {
            $isValid = $Value -is [bool]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être un booléen."
            }
        }
        "DateTime" {
            $isValid = $Value -is [datetime]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être une date/heure."
            }
        }
        "Array" {
            $isValid = $Value -is [array]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être un tableau."
            }
        }
        "Hashtable" {
            $isValid = $Value -is [hashtable]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être une table de hachage."
            }
        }
        "PSObject" {
            $isValid = $Value -is [PSObject]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être un objet PowerShell."
            }
        }
        "ScriptBlock" {
            $isValid = $Value -is [scriptblock]
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être un bloc de script."
            }
        }
        "Null" {
            $isValid = $null -eq $Value
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit être null."
            }
        }
        "NotNull" {
            $isValid = $null -ne $Value
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur ne peut pas être null."
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
                $ErrorMessage = "La valeur doit être vide."
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
                $ErrorMessage = "La valeur ne peut pas être vide."
            }
        }
    }

    # Gérer l'échec de la validation
    if (-not $isValid) {
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    return $isValid
}
