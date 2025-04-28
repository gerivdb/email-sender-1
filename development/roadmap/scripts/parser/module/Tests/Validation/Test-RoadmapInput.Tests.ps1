#
# Test-RoadmapInput.Tests.ps1
#
# Tests unitaires pour la fonction Test-RoadmapInput
#

# Importer la fonction Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Test-RoadmapInput.ps1"

# Importer les fonctions de validation
$validationPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Validation"
$dataTypePath = Join-Path -Path $validationPath -ChildPath "Test-DataType.ps1"
$formatPath = Join-Path -Path $validationPath -ChildPath "Test-Format.ps1"
$rangePath = Join-Path -Path $validationPath -ChildPath "Test-Range.ps1"
$customPath = Join-Path -Path $validationPath -ChildPath "Test-Custom.ps1"

. $dataTypePath
. $formatPath
. $rangePath
. $customPath
. $functionPath

Describe "Test-RoadmapInput" {
    Context "Validation de type de donnÃ©es" {
        It "Devrait retourner True pour une chaÃ®ne de caractÃ¨res" {
            Test-RoadmapInput -Value "Hello" -Type "String" | Should -Be $true
        }

        It "Devrait retourner False pour un entier lorsque le type attendu est String" {
            Test-RoadmapInput -Value 42 -Type "String" | Should -Be $false
        }
    }

    Context "Validation de format" {
        It "Devrait retourner True pour une adresse email valide" {
            Test-RoadmapInput -Value "user@example.com" -Format "Email" | Should -Be $true
        }

        It "Devrait retourner False pour une adresse email invalide" {
            Test-RoadmapInput -Value "invalid@" -Format "Email" | Should -Be $false
        }
    }

    Context "Validation de plage" {
        It "Devrait retourner True pour une valeur dans la plage" {
            Test-RoadmapInput -Value 42 -Min 0 -Max 100 | Should -Be $true
        }

        It "Devrait retourner False pour une valeur hors de la plage" {
            Test-RoadmapInput -Value 101 -Min 0 -Max 100 | Should -Be $false
        }
    }

    Context "Validation de longueur" {
        It "Devrait retourner True pour une chaÃ®ne de longueur valide" {
            Test-RoadmapInput -Value "Hello" -MinLength 3 -MaxLength 10 | Should -Be $true
        }

        It "Devrait retourner False pour une chaÃ®ne trop courte" {
            Test-RoadmapInput -Value "Hi" -MinLength 3 -MaxLength 10 | Should -Be $false
        }
    }

    Context "Validation de nombre d'Ã©lÃ©ments" {
        It "Devrait retourner True pour un tableau avec un nombre d'Ã©lÃ©ments valide" {
            Test-RoadmapInput -Value @(1, 2, 3) -MinCount 1 -MaxCount 5 | Should -Be $true
        }

        It "Devrait retourner False pour un tableau avec trop d'Ã©lÃ©ments" {
            Test-RoadmapInput -Value @(1, 2, 3, 4, 5, 6) -MinCount 1 -MaxCount 5 | Should -Be $false
        }
    }

    Context "Validation personnalisÃ©e" {
        It "Devrait retourner True pour une valeur valide avec ValidationFunction" {
            Test-RoadmapInput -Value 42 -ValidationFunction { param($val) $val -gt 0 -and $val -lt 100 } | Should -Be $true
        }

        It "Devrait retourner False pour une valeur invalide avec ValidationFunction" {
            Test-RoadmapInput -Value -1 -ValidationFunction { param($val) $val -gt 0 -and $val -lt 100 } | Should -Be $false
        }
    }

    Context "Validation combinÃ©e" {
        It "Devrait retourner True pour une valeur valide avec plusieurs validations" {
            Test-RoadmapInput -Value "user@example.com" -Type "String" -Format "Email" -MinLength 5 -MaxLength 50 | Should -Be $true
        }

        It "Devrait retourner False si une des validations Ã©choue" {
            Test-RoadmapInput -Value "user@example.com" -Type "String" -Format "Email" -MinLength 20 -MaxLength 50 | Should -Be $false
        }
    }

    Context "Validation avec ThrowOnFailure" {
        It "Devrait lever une exception en cas d'Ã©chec avec ThrowOnFailure" {
            { Test-RoadmapInput -Value "invalid@" -Format "Email" -ThrowOnFailure } | Should -Throw
        }

        It "Ne devrait pas lever d'exception en cas de succÃ¨s avec ThrowOnFailure" {
            { Test-RoadmapInput -Value "user@example.com" -Format "Email" -ThrowOnFailure } | Should -Not -Throw
        }
    }

    Context "Validation avec message d'erreur personnalisÃ©" {
        It "Devrait utiliser le message d'erreur personnalisÃ© en cas d'Ã©chec" {
            $customErrorMessage = "Message d'erreur personnalisÃ©"
            $exceptionMessage = $null

            try {
                Test-RoadmapInput -Value "invalid@" -Format "Email" -ErrorMessage $customErrorMessage -ThrowOnFailure
            } catch {
                $exceptionMessage = $_.Exception.Message
            }

            $exceptionMessage | Should -Be $customErrorMessage
        }
    }
}
