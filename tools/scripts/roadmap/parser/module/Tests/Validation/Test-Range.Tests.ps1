#
# Test-Range.Tests.ps1
#
# Tests unitaires pour la fonction Test-Range
#

# Importer la fonction Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Validation\Test-Range.ps1"
. $functionPath

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
