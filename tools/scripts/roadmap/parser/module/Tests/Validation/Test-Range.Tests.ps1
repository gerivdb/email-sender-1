#
# Test-Range.Tests.ps1
#
# Tests unitaires pour la fonction Test-Range
#

# Importer la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Validation\Test-Range.ps1"
. $functionPath

Describe "Test-Range" {
    Context "Validation de plage de valeurs" {
        It "Devrait retourner True pour une valeur dans la plage" {
            Test-Range -Value 42 -Min 0 -Max 100 | Should -Be $true
        }

        It "Devrait retourner True pour une valeur égale à la borne inférieure" {
            Test-Range -Value 0 -Min 0 -Max 100 | Should -Be $true
        }

        It "Devrait retourner True pour une valeur égale à la borne supérieure" {
            Test-Range -Value 100 -Min 0 -Max 100 | Should -Be $true
        }

        It "Devrait retourner False pour une valeur inférieure à la borne inférieure" {
            Test-Range -Value -1 -Min 0 -Max 100 | Should -Be $false
        }

        It "Devrait retourner False pour une valeur supérieure à la borne supérieure" {
            Test-Range -Value 101 -Min 0 -Max 100 | Should -Be $false
        }
    }

    Context "Validation de plage avec Min seulement" {
        It "Devrait retourner True pour une valeur supérieure à Min" {
            Test-Range -Value 42 -Min 0 | Should -Be $true
        }

        It "Devrait retourner True pour une valeur égale à Min" {
            Test-Range -Value 0 -Min 0 | Should -Be $true
        }

        It "Devrait retourner False pour une valeur inférieure à Min" {
            Test-Range -Value -1 -Min 0 | Should -Be $false
        }
    }

    Context "Validation de plage avec Max seulement" {
        It "Devrait retourner True pour une valeur inférieure à Max" {
            Test-Range -Value 42 -Max 100 | Should -Be $true
        }

        It "Devrait retourner True pour une valeur égale à Max" {
            Test-Range -Value 100 -Max 100 | Should -Be $true
        }

        It "Devrait retourner False pour une valeur supérieure à Max" {
            Test-Range -Value 101 -Max 100 | Should -Be $false
        }
    }

    Context "Validation de longueur" {
        It "Devrait retourner True pour une chaîne de longueur valide" {
            Test-Range -Value "Hello" -MinLength 3 -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner True pour une chaîne de longueur égale à MinLength" {
            Test-Range -Value "Hel" -MinLength 3 -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner True pour une chaîne de longueur égale à MaxLength" {
            Test-Range -Value "HelloWorld" -MinLength 3 -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne trop courte" {
            Test-Range -Value "Hi" -MinLength 3 -MaxLength 10 | Should -Be $false
        }

        It "Devrait retourner False pour une chaîne trop longue" {
            Test-Range -Value "HelloWorld!" -MinLength 3 -MaxLength 10 | Should -Be $false
        }
    }

    Context "Validation de longueur avec MinLength seulement" {
        It "Devrait retourner True pour une chaîne plus longue que MinLength" {
            Test-Range -Value "Hello" -MinLength 3 | Should -Be $true
        }

        It "Devrait retourner True pour une chaîne de longueur égale à MinLength" {
            Test-Range -Value "Hel" -MinLength 3 | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne plus courte que MinLength" {
            Test-Range -Value "Hi" -MinLength 3 | Should -Be $false
        }
    }

    Context "Validation de longueur avec MaxLength seulement" {
        It "Devrait retourner True pour une chaîne plus courte que MaxLength" {
            Test-Range -Value "Hello" -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner True pour une chaîne de longueur égale à MaxLength" {
            Test-Range -Value "HelloWorld" -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne plus longue que MaxLength" {
            Test-Range -Value "HelloWorld!" -MaxLength 10 | Should -Be $false
        }
    }

    Context "Validation de nombre d'éléments" {
        It "Devrait retourner True pour un tableau avec un nombre d'éléments valide" {
            Test-Range -Value @(1, 2, 3) -MinCount 1 -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner True pour un tableau avec un nombre d'éléments égal à MinCount" {
            Test-Range -Value @(1) -MinCount 1 -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner True pour un tableau avec un nombre d'éléments égal à MaxCount" {
            Test-Range -Value @(1, 2, 3, 4, 5) -MinCount 1 -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner False pour un tableau avec trop peu d'éléments" {
            Test-Range -Value @() -MinCount 1 -MaxCount 5 | Should -Be $false
        }

        It "Devrait retourner False pour un tableau avec trop d'éléments" {
            Test-Range -Value @(1, 2, 3, 4, 5, 6) -MinCount 1 -MaxCount 5 | Should -Be $false
        }
    }

    Context "Validation de nombre d'éléments avec MinCount seulement" {
        It "Devrait retourner True pour un tableau avec plus d'éléments que MinCount" {
            Test-Range -Value @(1, 2, 3) -MinCount 1 | Should -Be $true
        }

        It "Devrait retourner True pour un tableau avec un nombre d'éléments égal à MinCount" {
            Test-Range -Value @(1) -MinCount 1 | Should -Be $true
        }

        It "Devrait retourner False pour un tableau avec moins d'éléments que MinCount" {
            Test-Range -Value @() -MinCount 1 | Should -Be $false
        }
    }

    Context "Validation de nombre d'éléments avec MaxCount seulement" {
        It "Devrait retourner True pour un tableau avec moins d'éléments que MaxCount" {
            Test-Range -Value @(1, 2, 3) -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner True pour un tableau avec un nombre d'éléments égal à MaxCount" {
            Test-Range -Value @(1, 2, 3, 4, 5) -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner False pour un tableau avec plus d'éléments que MaxCount" {
            Test-Range -Value @(1, 2, 3, 4, 5, 6) -MaxCount 5 | Should -Be $false
        }
    }

    Context "Validation avec ThrowOnFailure" {
        It "Devrait lever une exception en cas d'échec avec ThrowOnFailure" {
            { Test-Range -Value 101 -Min 0 -Max 100 -ThrowOnFailure } | Should -Throw
        }

        It "Ne devrait pas lever d'exception en cas de succès avec ThrowOnFailure" {
            { Test-Range -Value 42 -Min 0 -Max 100 -ThrowOnFailure } | Should -Not -Throw
        }
    }

    Context "Validation avec message d'erreur personnalisé" {
        It "Devrait utiliser le message d'erreur personnalisé en cas d'échec" {
            $customErrorMessage = "Message d'erreur personnalisé"
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
