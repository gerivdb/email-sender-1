#
# Test-Range.Tests.ps1
#
# Tests unitaires pour la fonction Test-Range
#

# DÃ©finir la fonction Test-Range directement dans le script de test
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

Describe "Test-Range" {
    Context "Validation de plage de valeurs" {
        It "Devrait retourner True pour une valeur dans la plage" {
            Test-Range -Value 42 -Min 0 -Max 100 | Should -Be $true
        }

        It "Devrait retourner True pour une valeur Ã©gale Ã  la borne infÃ©rieure" {
            Test-Range -Value 0 -Min 0 -Max 100 | Should -Be $true
        }

        It "Devrait retourner True pour une valeur Ã©gale Ã  la borne supÃ©rieure" {
            Test-Range -Value 100 -Min 0 -Max 100 | Should -Be $true
        }

        It "Devrait retourner False pour une valeur infÃ©rieure Ã  la borne infÃ©rieure" {
            Test-Range -Value -1 -Min 0 -Max 100 | Should -Be $false
        }

        It "Devrait retourner False pour une valeur supÃ©rieure Ã  la borne supÃ©rieure" {
            Test-Range -Value 101 -Min 0 -Max 100 | Should -Be $false
        }
    }

    Context "Validation de plage avec Min seulement" {
        It "Devrait retourner True pour une valeur supÃ©rieure Ã  Min" {
            Test-Range -Value 42 -Min 0 | Should -Be $true
        }

        It "Devrait retourner True pour une valeur Ã©gale Ã  Min" {
            Test-Range -Value 0 -Min 0 | Should -Be $true
        }

        It "Devrait retourner False pour une valeur infÃ©rieure Ã  Min" {
            Test-Range -Value -1 -Min 0 | Should -Be $false
        }
    }

    Context "Validation de plage avec Max seulement" {
        It "Devrait retourner True pour une valeur infÃ©rieure Ã  Max" {
            Test-Range -Value 42 -Max 100 | Should -Be $true
        }

        It "Devrait retourner True pour une valeur Ã©gale Ã  Max" {
            Test-Range -Value 100 -Max 100 | Should -Be $true
        }

        It "Devrait retourner False pour une valeur supÃ©rieure Ã  Max" {
            Test-Range -Value 101 -Max 100 | Should -Be $false
        }
    }

    Context "Validation de longueur" {
        It "Devrait retourner True pour une chaÃ®ne de longueur valide" {
            Test-Range -Value "Hello" -MinLength 3 -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner True pour une chaÃ®ne de longueur Ã©gale Ã  MinLength" {
            Test-Range -Value "Hel" -MinLength 3 -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner True pour une chaÃ®ne de longueur Ã©gale Ã  MaxLength" {
            Test-Range -Value "HelloWorld" -MinLength 3 -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner False pour une chaÃ®ne trop courte" {
            Test-Range -Value "Hi" -MinLength 3 -MaxLength 10 | Should -Be $false
        }

        It "Devrait retourner False pour une chaÃ®ne trop longue" {
            Test-Range -Value "HelloWorld!" -MinLength 3 -MaxLength 10 | Should -Be $false
        }
    }

    Context "Validation de longueur avec MinLength seulement" {
        It "Devrait retourner True pour une chaÃ®ne plus longue que MinLength" {
            Test-Range -Value "Hello" -MinLength 3 | Should -Be $true
        }

        It "Devrait retourner True pour une chaÃ®ne de longueur Ã©gale Ã  MinLength" {
            Test-Range -Value "Hel" -MinLength 3 | Should -Be $true
        }

        It "Devrait retourner False pour une chaÃ®ne plus courte que MinLength" {
            Test-Range -Value "Hi" -MinLength 3 | Should -Be $false
        }
    }

    Context "Validation de longueur avec MaxLength seulement" {
        It "Devrait retourner True pour une chaÃ®ne plus courte que MaxLength" {
            Test-Range -Value "Hello" -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner True pour une chaÃ®ne de longueur Ã©gale Ã  MaxLength" {
            Test-Range -Value "HelloWorld" -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner False pour une chaÃ®ne plus longue que MaxLength" {
            Test-Range -Value "HelloWorld!" -MaxLength 10 | Should -Be $false
        }
    }

    Context "Validation de nombre d'Ã©lÃ©ments" {
        It "Devrait retourner True pour un tableau avec un nombre d'Ã©lÃ©ments valide" {
            Test-Range -Value @(1, 2, 3) -MinCount 1 -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner True pour un tableau avec un nombre d'Ã©lÃ©ments Ã©gal Ã  MinCount" {
            Test-Range -Value @(1) -MinCount 1 -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner True pour un tableau avec un nombre d'Ã©lÃ©ments Ã©gal Ã  MaxCount" {
            Test-Range -Value @(1, 2, 3, 4, 5) -MinCount 1 -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner False pour un tableau avec trop peu d'Ã©lÃ©ments" {
            Test-Range -Value @() -MinCount 1 -MaxCount 5 | Should -Be $false
        }

        It "Devrait retourner False pour un tableau avec trop d'Ã©lÃ©ments" {
            Test-Range -Value @(1, 2, 3, 4, 5, 6) -MinCount 1 -MaxCount 5 | Should -Be $false
        }
    }

    Context "Validation de nombre d'Ã©lÃ©ments avec MinCount seulement" {
        It "Devrait retourner True pour un tableau avec plus d'Ã©lÃ©ments que MinCount" {
            Test-Range -Value @(1, 2, 3) -MinCount 1 | Should -Be $true
        }

        It "Devrait retourner True pour un tableau avec un nombre d'Ã©lÃ©ments Ã©gal Ã  MinCount" {
            Test-Range -Value @(1) -MinCount 1 | Should -Be $true
        }

        It "Devrait retourner False pour un tableau avec moins d'Ã©lÃ©ments que MinCount" {
            Test-Range -Value @() -MinCount 1 | Should -Be $false
        }
    }

    Context "Validation de nombre d'Ã©lÃ©ments avec MaxCount seulement" {
        It "Devrait retourner True pour un tableau avec moins d'Ã©lÃ©ments que MaxCount" {
            Test-Range -Value @(1, 2, 3) -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner True pour un tableau avec un nombre d'Ã©lÃ©ments Ã©gal Ã  MaxCount" {
            Test-Range -Value @(1, 2, 3, 4, 5) -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner False pour un tableau avec plus d'Ã©lÃ©ments que MaxCount" {
            Test-Range -Value @(1, 2, 3, 4, 5, 6) -MaxCount 5 | Should -Be $false
        }
    }

    Context "Validation avec ThrowOnFailure" {
        It "Devrait lever une exception en cas d'Ã©chec avec ThrowOnFailure" {
            { Test-Range -Value 101 -Min 0 -Max 100 -ThrowOnFailure } | Should -Throw
        }

        It "Ne devrait pas lever d'exception en cas de succÃ¨s avec ThrowOnFailure" {
            { Test-Range -Value 42 -Min 0 -Max 100 -ThrowOnFailure } | Should -Not -Throw
        }
    }

    Context "Validation avec message d'erreur personnalisÃ©" {
        It "Devrait utiliser le message d'erreur personnalisÃ© en cas d'Ã©chec" {
            $customErrorMessage = "Message d'erreur personnalisÃ©"
            $exceptionMessage = $null

            try {
                Test-Range -Value 101 -Min 0 -Max 100 -ErrorMessage $customErrorMessage -ThrowOnFailure
            } catch {
                $exceptionMessage = $_.Exception.Message
            }

            $exceptionMessage | Should -Be $customErrorMessage
        }
    }
}
