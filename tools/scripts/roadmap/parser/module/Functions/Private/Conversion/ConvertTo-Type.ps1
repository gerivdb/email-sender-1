<#
.SYNOPSIS
    Convertit une valeur vers un type spÃ©cifiÃ©.

.DESCRIPTION
    La fonction ConvertTo-Type convertit une valeur vers un type spÃ©cifiÃ©.
    Elle prend en charge diffÃ©rents types de donnÃ©es courants et peut Ãªtre utilisÃ©e pour
    convertir les entrÃ©es des fonctions du module RoadmapParser.

.PARAMETER Value
    La valeur Ã  convertir.

.PARAMETER Type
    Le type cible de la conversion. Valeurs possibles :
    - String : Convertit la valeur en chaÃ®ne de caractÃ¨res
    - Integer : Convertit la valeur en entier
    - Decimal : Convertit la valeur en nombre dÃ©cimal
    - Boolean : Convertit la valeur en boolÃ©en
    - DateTime : Convertit la valeur en date/heure
    - Array : Convertit la valeur en tableau
    - Hashtable : Convertit la valeur en table de hachage
    - PSObject : Convertit la valeur en objet PowerShell
    - ScriptBlock : Convertit la valeur en bloc de script
    - Guid : Convertit la valeur en GUID

.PARAMETER Format
    Le format Ã  utiliser pour la conversion (par exemple, format de date).

.PARAMETER DefaultValue
    La valeur par dÃ©faut Ã  retourner en cas d'Ã©chec de la conversion.

.PARAMETER ErrorMessage
    Le message d'erreur Ã  afficher en cas d'Ã©chec de la conversion.
    Si non spÃ©cifiÃ©, un message par dÃ©faut sera utilisÃ©.

.PARAMETER ThrowOnFailure
    Indique si une exception doit Ãªtre levÃ©e en cas d'Ã©chec de la conversion.

.EXAMPLE
    ConvertTo-Type -Value "42" -Type Integer
    Convertit la chaÃ®ne "42" en entier.

.EXAMPLE
    ConvertTo-Type -Value "2023-01-01" -Type DateTime -Format "yyyy-MM-dd" -ThrowOnFailure
    Convertit la chaÃ®ne "2023-01-01" en date/heure en utilisant le format spÃ©cifiÃ©, et lÃ¨ve une exception si la conversion Ã©choue.

.OUTPUTS
    [object] La valeur convertie vers le type spÃ©cifiÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-20
#>
function ConvertTo-Type {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("String", "Integer", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Guid")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Format,

        [Parameter(Mandatory = $false)]
        $DefaultValue,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de la conversion
    $result = $null
    $conversionSucceeded = $false

    # Effectuer la conversion selon le type
    try {
        switch ($Type) {
            "String" {
                if ($null -eq $Value) {
                    $result = [string]::Empty
                } else {
                    $result = [string]$Value
                }
                $conversionSucceeded = $true
            }
            "Integer" {
                if ($null -eq $Value) {
                    $result = 0
                } elseif ($Value -is [int]) {
                    $result = $Value
                } else {
                    $result = [int]::Parse($Value.ToString())
                }
                $conversionSucceeded = $true
            }
            "Decimal" {
                if ($null -eq $Value) {
                    $result = 0.0
                } elseif ($Value -is [decimal] -or $Value -is [double] -or $Value -is [float]) {
                    $result = [decimal]$Value
                } else {
                    # Utiliser InvariantCulture pour gÃ©rer les dÃ©cimaux avec point ou virgule
                    $result = [decimal]::Parse($Value.ToString(), [System.Globalization.CultureInfo]::InvariantCulture)
                }
                $conversionSucceeded = $true
            }
            "Boolean" {
                if ($null -eq $Value) {
                    $result = $false
                } elseif ($Value -is [bool]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    $strValue = $Value.ToLower()
                    $result = $strValue -eq "true" -or $strValue -eq "1" -or $strValue -eq "yes" -or $strValue -eq "y" -or $strValue -eq "on"
                } else {
                    $result = [bool]::Parse($Value.ToString())
                }
                $conversionSucceeded = $true
            }
            "DateTime" {
                if ($null -eq $Value) {
                    $result = [datetime]::MinValue
                } elseif ($Value -is [datetime]) {
                    $result = $Value
                } elseif ($Value -is [string] -and -not [string]::IsNullOrEmpty($Format)) {
                    $result = [datetime]::ParseExact($Value, $Format, [System.Globalization.CultureInfo]::InvariantCulture)
                } else {
                    $result = [datetime]::Parse($Value.ToString())
                }
                $conversionSucceeded = $true
            }
            "Array" {
                if ($null -eq $Value) {
                    $result = @()
                } elseif ($Value -is [array]) {
                    $result = $Value
                } elseif ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
                    $result = @($Value)
                } else {
                    $result = @($Value)
                }
                $conversionSucceeded = $true
            }
            "Hashtable" {
                if ($null -eq $Value) {
                    $result = @{}
                } elseif ($Value -is [hashtable]) {
                    $result = $Value
                } elseif ($Value -is [PSObject]) {
                    $result = @{}
                    foreach ($property in $Value.PSObject.Properties) {
                        $result[$property.Name] = $property.Value
                    }
                } else {
                    throw "Impossible de convertir la valeur en table de hachage."
                }
                $conversionSucceeded = $true
            }
            "PSObject" {
                if ($null -eq $Value) {
                    $result = [PSCustomObject]@{}
                } elseif ($Value -is [PSObject]) {
                    $result = $Value
                } elseif ($Value -is [hashtable]) {
                    $result = [PSCustomObject]$Value
                } else {
                    $result = [PSCustomObject]@{ Value = $Value }
                }
                $conversionSucceeded = $true
            }
            "ScriptBlock" {
                if ($null -eq $Value) {
                    $result = {}
                } elseif ($Value -is [scriptblock]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    $result = [scriptblock]::Create($Value)
                } else {
                    throw "Impossible de convertir la valeur en bloc de script."
                }
                $conversionSucceeded = $true
            }
            "Guid" {
                if ($null -eq $Value) {
                    $result = [guid]::Empty
                } elseif ($Value -is [guid]) {
                    $result = $Value
                } elseif ($Value -is [string]) {
                    $result = [guid]::Parse($Value)
                } else {
                    throw "Impossible de convertir la valeur en GUID."
                }
                $conversionSucceeded = $true
            }
        }
    } catch {
        $conversionSucceeded = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Impossible de convertir la valeur '$Value' en $Type : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la conversion
    if (-not $conversionSucceeded) {
        if ($PSBoundParameters.ContainsKey('DefaultValue')) {
            $result = $DefaultValue
        } elseif ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    return $result
}
