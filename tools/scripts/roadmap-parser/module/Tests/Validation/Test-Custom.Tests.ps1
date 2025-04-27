#
# Test-Custom.Tests.ps1
#
# Tests unitaires pour la fonction Test-Custom
#

# Importer le module TestHelpers qui contient la fonction Test-Custom
$testHelpersPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "TestHelpers.psm1"
Import-Module -Name $testHelpersPath -Force

Describe "Test-Custom" {
    Context "Validation avec ValidationFunction" {
        It "Devrait retourner True pour une valeur valide" {
            Test-Custom -Value 42 -ValidationFunction { param($val) $val -gt 0 -and $val -lt 100 } | Should -Be $true
        }

        It "Devrait retourner False pour une valeur invalide" {
            Test-Custom -Value -1 -ValidationFunction { param($val) $val -gt 0 -and $val -lt 100 } | Should -Be $false
        }
    }

    Context "Validation avec ValidationScript" {
        It "Devrait retourner True pour une valeur valide" {
            Test-Custom -Value "Hello" -ValidationScript { param($val) $val.Length -gt 3 } | Should -Be $true
        }

        It "Devrait retourner False pour une valeur invalide" {
            Test-Custom -Value "Hi" -ValidationScript { param($val) $val.Length -gt 3 } | Should -Be $false
        }
    }

    Context "Validation avec ThrowOnFailure" {
        It "Devrait lever une exception en cas d'Ã©chec avec ThrowOnFailure" {
            { Test-Custom -Value -1 -ValidationFunction { param($val) $val -gt 0 -and $val -lt 100 } -ThrowOnFailure } | Should -Throw
        }

        It "Ne devrait pas lever d'exception en cas de succÃ¨s avec ThrowOnFailure" {
            { Test-Custom -Value 42 -ValidationFunction { param($val) $val -gt 0 -and $val -lt 100 } -ThrowOnFailure } | Should -Not -Throw
        }
    }

    Context "Validation avec message d'erreur personnalisÃ©" {
        It "Devrait utiliser le message d'erreur personnalisÃ© en cas d'Ã©chec" {
            $customErrorMessage = "Message d'erreur personnalisÃ©"
            $exceptionMessage = $null

            try {
                Test-Custom -Value -1 -ValidationFunction { param($val) $val -gt 0 -and $val -lt 100 } -ErrorMessage $customErrorMessage -ThrowOnFailure
            } catch {
                $exceptionMessage = $_.Exception.Message
            }

            $exceptionMessage | Should -Be $customErrorMessage
        }
    }

    Context "Gestion des erreurs dans la fonction de validation" {
        It "Devrait retourner False si la fonction de validation lÃ¨ve une exception" {
            Test-Custom -Value "Hello" -ValidationFunction { param($val) throw "Erreur dans la fonction de validation" } | Should -Be $false
        }

        It "Devrait utiliser un message d'erreur par dÃ©faut si la fonction de validation lÃ¨ve une exception" {
            $exceptionMessage = $null

            try {
                Test-Custom -Value "Hello" -ValidationFunction { param($val) throw "Erreur dans la fonction de validation" } -ThrowOnFailure
            } catch {
                $exceptionMessage = $_.Exception.Message
            }

            $exceptionMessage | Should -Match "Erreur lors de l'exÃ©cution de la validation personnalisÃ©e"
        }
    }
}
