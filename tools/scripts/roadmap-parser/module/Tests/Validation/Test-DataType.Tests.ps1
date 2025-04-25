#
# Test-DataType.Tests.ps1
#
# Tests unitaires pour la fonction Test-DataType
#

# Importer la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Validation\Test-DataType.ps1"
. $functionPath

Describe "Test-DataType" {
    Context "Validation de type String" {
        It "Devrait retourner True pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "String" | Should -Be $true
        }

        It "Devrait retourner False pour un entier" {
            Test-DataType -Value 42 -Type "String" | Should -Be $false
        }
    }

    Context "Validation de type Integer" {
        It "Devrait retourner True pour un entier" {
            Test-DataType -Value 42 -Type "Integer" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "Integer" | Should -Be $false
        }
    }

    Context "Validation de type Decimal" {
        It "Devrait retourner True pour un nombre décimal" {
            Test-DataType -Value 3.14 -Type "Decimal" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "Decimal" | Should -Be $false
        }
    }

    Context "Validation de type Boolean" {
        It "Devrait retourner True pour un booléen" {
            Test-DataType -Value $true -Type "Boolean" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "Boolean" | Should -Be $false
        }
    }

    Context "Validation de type DateTime" {
        It "Devrait retourner True pour une date/heure" {
            Test-DataType -Value (Get-Date) -Type "DateTime" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "DateTime" | Should -Be $false
        }
    }

    Context "Validation de type Array" {
        It "Devrait retourner True pour un tableau" {
            Test-DataType -Value @(1, 2, 3) -Type "Array" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "Array" | Should -Be $false
        }
    }

    Context "Validation de type Hashtable" {
        It "Devrait retourner True pour une table de hachage" {
            Test-DataType -Value @{ Key = "Value" } -Type "Hashtable" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "Hashtable" | Should -Be $false
        }
    }

    Context "Validation de type PSObject" {
        It "Devrait retourner True pour un objet PowerShell" {
            Test-DataType -Value ([PSCustomObject]@{ Property = "Value" }) -Type "PSObject" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "PSObject" | Should -Be $false
        }
    }

    Context "Validation de type ScriptBlock" {
        It "Devrait retourner True pour un bloc de script" {
            Test-DataType -Value { Write-Host "Test" } -Type "ScriptBlock" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "ScriptBlock" | Should -Be $false
        }
    }

    Context "Validation de type Null" {
        It "Devrait retourner True pour null" {
            Test-DataType -Value $null -Type "Null" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne de caractères" {
            Test-DataType -Value "Hello" -Type "Null" | Should -Be $false
        }
    }

    Context "Validation de type NotNull" {
        It "Devrait retourner True pour une valeur non null" {
            Test-DataType -Value "Hello" -Type "NotNull" | Should -Be $true
        }

        It "Devrait retourner False pour null" {
            Test-DataType -Value $null -Type "NotNull" | Should -Be $false
        }
    }

    Context "Validation de type Empty" {
        It "Devrait retourner True pour une chaîne vide" {
            Test-DataType -Value "" -Type "Empty" | Should -Be $true
        }

        It "Devrait retourner True pour un tableau vide" {
            Test-DataType -Value @() -Type "Empty" | Should -Be $true
        }

        It "Devrait retourner True pour une table de hachage vide" {
            Test-DataType -Value @{} -Type "Empty" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne non vide" {
            Test-DataType -Value "Hello" -Type "Empty" | Should -Be $false
        }
    }

    Context "Validation de type NotEmpty" {
        It "Devrait retourner True pour une chaîne non vide" {
            Test-DataType -Value "Hello" -Type "NotEmpty" | Should -Be $true
        }

        It "Devrait retourner True pour un tableau non vide" {
            Test-DataType -Value @(1, 2, 3) -Type "NotEmpty" | Should -Be $true
        }

        It "Devrait retourner True pour une table de hachage non vide" {
            Test-DataType -Value @{ Key = "Value" } -Type "NotEmpty" | Should -Be $true
        }

        It "Devrait retourner False pour une chaîne vide" {
            Test-DataType -Value "" -Type "NotEmpty" | Should -Be $false
        }
    }

    Context "Validation avec ThrowOnFailure" {
        It "Devrait lever une exception en cas d'échec avec ThrowOnFailure" {
            { Test-DataType -Value "Hello" -Type "Integer" -ThrowOnFailure } | Should -Throw
        }

        It "Ne devrait pas lever d'exception en cas de succès avec ThrowOnFailure" {
            { Test-DataType -Value 42 -Type "Integer" -ThrowOnFailure } | Should -Not -Throw
        }
    }

    Context "Validation avec message d'erreur personnalisé" {
        It "Devrait utiliser le message d'erreur personnalisé en cas d'échec" {
            $customErrorMessage = "Message d'erreur personnalisé"
            $exceptionMessage = $null

            try {
                Test-DataType -Value "Hello" -Type "Integer" -ErrorMessage $customErrorMessage -ThrowOnFailure
            } catch {
                $exceptionMessage = $_.Exception.Message
            }

            $exceptionMessage | Should -Be $customErrorMessage
        }
    }
}
