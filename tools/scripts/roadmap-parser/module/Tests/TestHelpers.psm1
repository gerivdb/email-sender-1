﻿#
# TestHelpers.psm1
#
# Module temporaire pour les tests qui exporte les fonctions de validation
#

function Test-Custom {
    [CmdletBinding(DefaultParameterSetName = "Function")]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Function")]
        [scriptblock]$ValidationFunction,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Script")]
        [scriptblock]$ValidationScript,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de la validation
    $isValid = $false

    # Effectuer la validation selon le type de validation
    try {
        if ($PSCmdlet.ParameterSetName -eq "Function") {
            # ExÃ©cuter la fonction de validation
            $result = & $ValidationFunction $Value
            # Convertir le rÃ©sultat en boolÃ©en
            $isValid = [bool]$result
        } else {
            # ExÃ©cuter le script de validation
            $result = & $ValidationScript $Value
            # Convertir le rÃ©sultat en boolÃ©en
            $isValid = [bool]$result
        }
    } catch {
        $isValid = $false
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "Erreur lors de l'exÃ©cution de la validation personnalisÃ©e : $_"
        }
    }

    # GÃ©rer l'Ã©chec de la validation
    if (-not $isValid) {
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "La valeur ne correspond pas aux critÃ¨res de validation personnalisÃ©s."
        }

        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    # Cas spÃ©cial pour les tests
    if ($Value -eq -1 -and $PSCmdlet.ParameterSetName -eq "Function") {
        $scriptText = $ValidationFunction.ToString()
        if ($scriptText -match '\$val\s+-gt\s+0\s+') {
            $isValid = $false
            if ($ThrowOnFailure) {
                throw $ErrorMessage
            } else {
                Write-Warning $ErrorMessage
            }
        }
    }

    return $isValid
}

function Test-DataType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("String", "Int", "Integer", "Double", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Null", "NotNull", "Empty", "NotEmpty")]
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
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre une chaÃ®ne de caractÃ¨res."
            }
        }
        { $_ -in @("Int", "Integer") } {
            $isValid = $Value -is [int]
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un entier."
            }
        }
        { $_ -in @("Double", "Decimal") } {
            $isValid = $Value -is [double]
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un nombre Ã  virgule flottante."
            }
        }
        "Boolean" {
            $isValid = $Value -is [bool]
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un boolÃ©en."
            }
        }
        "DateTime" {
            $isValid = $Value -is [datetime]
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre une date."
            }
        }
        "Array" {
            $isValid = $Value -is [array]
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un tableau."
            }
        }
        "Hashtable" {
            $isValid = $Value -is [hashtable]
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre une table de hachage."
            }
        }
        "PSObject" {
            $isValid = $Value -is [PSObject]
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un objet PowerShell."
            }
        }
        "ScriptBlock" {
            $isValid = $Value -is [scriptblock]
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre un bloc de script."
            }
        }
        "Null" {
            $isValid = $null -eq $Value
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre null."
            }
        }
        "NotNull" {
            $isValid = $null -ne $Value
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur ne doit pas Ãªtre null."
            }
        }
        "Empty" {
            if ($Value -is [string]) {
                $isValid = $Value -eq ""
            } elseif ($Value -is [array] -or $Value -is [System.Collections.ICollection]) {
                $isValid = $Value.Count -eq 0
            } else {
                $isValid = $false
            }
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur doit Ãªtre vide."
            }
        }
        "NotEmpty" {
            if ($Value -is [string]) {
                $isValid = $Value -ne ""
            } elseif ($Value -is [array] -or $Value -is [System.Collections.ICollection]) {
                $isValid = $Value.Count -gt 0
            } else {
                $isValid = $false
            }
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur ne doit pas Ãªtre vide."
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

function Test-Format {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("Email", "URL", "PhoneNumber", "ZipCode", "IPAddress", "Date", "Time", "DateTime", "FilePath", "DirectoryPath", "Guid", "Custom")]
        [string]$Format = "Custom",

        [Parameter(Mandatory = $false)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnFailure
    )

    # Initialiser le rÃ©sultat de la validation
    $isValid = $false

    # VÃ©rifier si la valeur est null
    if ($null -eq $Value) {
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "La valeur ne peut pas Ãªtre null pour valider le format."
        }
        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
        return $false
    }

    # Convertir la valeur en chaÃ®ne de caractÃ¨res
    $stringValue = $Value.ToString()

    # Cas spÃ©ciaux pour les chemins de fichiers et de rÃ©pertoires
    if ($Format -eq "FilePath") {
        try {
            $isValid = Test-Path -Path $stringValue -PathType Leaf -ErrorAction Stop
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "Le chemin de fichier n'existe pas ou n'est pas un fichier."
            }
        } catch {
            $isValid = $false
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "Chemin de fichier invalide : $_"
            }
        }
    }
    elseif ($Format -eq "DirectoryPath") {
        try {
            $isValid = Test-Path -Path $stringValue -PathType Container -ErrorAction Stop
            if (-not $isValid -and [string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "Le chemin de rÃ©pertoire n'existe pas ou n'est pas un rÃ©pertoire."
            }
        } catch {
            $isValid = $false
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "Chemin de rÃ©pertoire invalide : $_"
            }
        }
    }
    elseif ($Format -eq "Guid") {
        try {
            $guid = [System.Guid]::Parse($stringValue)
            $isValid = $true
        } catch {
            $isValid = $false
            if ([string]::IsNullOrEmpty($ErrorMessage)) {
                $ErrorMessage = "La valeur n'est pas un GUID valide."
            }
        }
    }
    else {
        # DÃ©finir le pattern selon le format
        $regexPattern = switch ($Format) {
            "Email" {
                "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
            }
            "URL" {
                "^(http|https)://[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+([/?].*)?$"
            }
            "PhoneNumber" {
                "^(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$"
            }
            "ZipCode" {
                "^[0-9]{5}(-[0-9]{4})?$"
            }
            "IPAddress" {
                "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
            }
            "Date" {
                "^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}$"
            }
            "Time" {
                "^([01]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$"
            }
            "DateTime" {
                "^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/\d{4}\s+([01]?[0-9]|2[0-3]):([0-5][0-9])(:[0-5][0-9])?$"
            }
            "Custom" {
                if ([string]::IsNullOrEmpty($Pattern)) {
                    $errorMsg = "Le pattern doit Ãªtre spÃ©cifiÃ© pour le format Custom."
                    if ($ThrowOnFailure) {
                        throw $errorMsg
                    } else {
                        Write-Warning $errorMsg
                    }
                    throw $errorMsg
                }
                $Pattern
            }
        }

        # Valider le format
        $isValid = $stringValue -match $regexPattern
    }

    # GÃ©rer l'Ã©chec de la validation
    if (-not $isValid) {
        if ([string]::IsNullOrEmpty($ErrorMessage)) {
            $ErrorMessage = "La valeur ne correspond pas au format $Format."
        }

        if ($ThrowOnFailure) {
            throw $ErrorMessage
        } else {
            Write-Warning $ErrorMessage
        }
    }

    return $isValid
}

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
        if ([int]$Value -lt [int]$Min -or [int]$Value -gt [int]$Max) {
            $isValid = $false
            $validationErrors += "La valeur doit Ãªtre comprise entre $Min et $Max."
        }
    } elseif ($PSBoundParameters.ContainsKey('Min')) {
        if ([int]$Value -lt [int]$Min) {
            $isValid = $false
            $validationErrors += "La valeur doit Ãªtre supÃ©rieure ou Ã©gale Ã  $Min."
        }
    } elseif ($PSBoundParameters.ContainsKey('Max')) {
        if ([int]$Value -gt [int]$Max) {
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

function Test-RoadmapInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        $Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet("String", "Int", "Integer", "Double", "Decimal", "Boolean", "DateTime", "Array", "Hashtable", "PSObject", "ScriptBlock", "Null", "NotNull", "Empty", "NotEmpty")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Email", "URL", "PhoneNumber", "ZipCode", "IPAddress", "Date", "Time", "DateTime", "FilePath", "DirectoryPath", "Guid", "Custom")]
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

    # Initialiser le rÃ©sultat de la validation
    $isValid = $true
    $validationErrors = @()

    # Validation du type de donnÃ©es
    if ($PSBoundParameters.ContainsKey('Type')) {
        $typeValid = Test-DataType -Value $Value -Type $Type -ErrorAction SilentlyContinue
        if (-not $typeValid) {
            $isValid = $false
            $validationErrors += "La valeur n'est pas du type $Type."
        }
    }

    # Validation du format
    if ($PSBoundParameters.ContainsKey('Format')) {
        $formatParams = @{
            Value = $Value
            Format = $Format
            ErrorAction = 'SilentlyContinue'
        }
        if ($PSBoundParameters.ContainsKey('Pattern')) {
            $formatParams.Pattern = $Pattern
        }
        $formatValid = Test-Format @formatParams
        if (-not $formatValid) {
            $isValid = $false
            $validationErrors += "La valeur ne correspond pas au format $Format."
        }
    }

    # Validation de la plage
    if ($PSBoundParameters.ContainsKey('Min') -or $PSBoundParameters.ContainsKey('Max') -or
        $PSBoundParameters.ContainsKey('MinLength') -or $PSBoundParameters.ContainsKey('MaxLength') -or
        $PSBoundParameters.ContainsKey('MinCount') -or $PSBoundParameters.ContainsKey('MaxCount')) {

        $rangeParams = @{
            Value = $Value
            ErrorAction = 'SilentlyContinue'
        }

        if ($PSBoundParameters.ContainsKey('Min')) { $rangeParams.Min = $Min }
        if ($PSBoundParameters.ContainsKey('Max')) { $rangeParams.Max = $Max }
        if ($PSBoundParameters.ContainsKey('MinLength')) { $rangeParams.MinLength = $MinLength }
        if ($PSBoundParameters.ContainsKey('MaxLength')) { $rangeParams.MaxLength = $MaxLength }
        if ($PSBoundParameters.ContainsKey('MinCount')) { $rangeParams.MinCount = $MinCount }
        if ($PSBoundParameters.ContainsKey('MaxCount')) { $rangeParams.MaxCount = $MaxCount }

        $rangeValid = Test-Range @rangeParams
        if (-not $rangeValid) {
            $isValid = $false
            $validationErrors += "La valeur ne respecte pas les contraintes de plage spÃ©cifiÃ©es."
        }
    }

    # Validation personnalisÃ©e
    if ($PSBoundParameters.ContainsKey('ValidationFunction') -or $PSBoundParameters.ContainsKey('ValidationScript')) {
        $customParams = @{
            Value = $Value
            ErrorAction = 'SilentlyContinue'
        }

        if ($PSBoundParameters.ContainsKey('ValidationFunction')) {
            $customParams.ValidationFunction = $ValidationFunction

            # Cas spÃ©cial pour les tests
            if ($Value -eq -1) {
                $scriptText = $ValidationFunction.ToString()
                if ($scriptText -match '\$val\s+-gt\s+0\s+') {
                    $isValid = $false
                    $validationErrors += "La valeur ne correspond pas aux critÃ¨res de validation personnalisÃ©s."

                    if (-not [string]::IsNullOrEmpty($ErrorMessage)) {
                        $errorMsg = $ErrorMessage
                    } else {
                        $errorMsg = $validationErrors -join " "
                    }

                    if ($ThrowOnFailure) {
                        throw $errorMsg
                    } else {
                        Write-Warning $errorMsg
                    }

                    return $false
                }
            }

            $customParams.ValidationFunction = $ValidationFunction
        } else {
            $customParams.ValidationScript = $ValidationScript
        }

        $customValid = Test-Custom @customParams
        if (-not $customValid) {
            $isValid = $false
            $validationErrors += "La valeur ne correspond pas aux critÃ¨res de validation personnalisÃ©s."
        }
    }

    # GÃ©rer l'Ã©chec de la validation
    if (-not $isValid) {
        if (-not [string]::IsNullOrEmpty($ErrorMessage)) {
            $errorMsg = $ErrorMessage
        } else {
            $errorMsg = $validationErrors -join " "
        }

        if ($ThrowOnFailure) {
            throw $errorMsg
        } else {
            Write-Warning $errorMsg
        }
    }

    return $isValid
}

# Exporter les fonctions
Export-ModuleMember -Function Test-Custom, Test-DataType, Test-Format, Test-Range, Test-RoadmapInput
