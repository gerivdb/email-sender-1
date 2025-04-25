#
# Test-Format.Tests.ps1
#
# Tests unitaires pour la fonction Test-Format
#

# Importer la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\Validation\Test-Format.ps1"
. $functionPath

Describe "Test-Format" {
    Context "Validation de format Email" {
        It "Devrait retourner True pour une adresse email valide" {
            Test-Format -Value "user@example.com" -Format "Email" | Should -Be $true
        }

        It "Devrait retourner False pour une adresse email invalide" {
            Test-Format -Value "invalid@" -Format "Email" | Should -Be $false
        }
    }

    Context "Validation de format URL" {
        It "Devrait retourner True pour une URL valide" {
            Test-Format -Value "https://www.example.com" -Format "URL" | Should -Be $true
        }

        It "Devrait retourner False pour une URL invalide" {
            Test-Format -Value "not a url" -Format "URL" | Should -Be $false
        }
    }

    Context "Validation de format IPAddress" {
        It "Devrait retourner True pour une adresse IP valide" {
            Test-Format -Value "192.168.1.1" -Format "IPAddress" | Should -Be $true
        }

        It "Devrait retourner False pour une adresse IP invalide" {
            Test-Format -Value "300.400.500.600" -Format "IPAddress" | Should -Be $false
        }
    }

    Context "Validation de format PhoneNumber" {
        It "Devrait retourner True pour un numéro de téléphone valide" {
            Test-Format -Value "123-456-7890" -Format "PhoneNumber" | Should -Be $true
        }

        It "Devrait retourner False pour un numéro de téléphone invalide" {
            Test-Format -Value "abc" -Format "PhoneNumber" | Should -Be $false
        }
    }

    Context "Validation de format ZipCode" {
        It "Devrait retourner True pour un code postal valide" {
            Test-Format -Value "12345" -Format "ZipCode" | Should -Be $true
        }

        It "Devrait retourner False pour un code postal invalide" {
            Test-Format -Value "abc" -Format "ZipCode" | Should -Be $false
        }
    }

    Context "Validation de format Date" {
        It "Devrait retourner True pour une date valide" {
            Test-Format -Value "01/01/2023" -Format "Date" | Should -Be $true
        }

        It "Devrait retourner False pour une date invalide" {
            Test-Format -Value "abc" -Format "Date" | Should -Be $false
        }
    }

    Context "Validation de format Time" {
        It "Devrait retourner True pour une heure valide" {
            Test-Format -Value "12:34:56" -Format "Time" | Should -Be $true
        }

        It "Devrait retourner False pour une heure invalide" {
            Test-Format -Value "abc" -Format "Time" | Should -Be $false
        }
    }

    Context "Validation de format DateTime" {
        It "Devrait retourner True pour une date/heure valide" {
            Test-Format -Value "01/01/2023 12:34:56" -Format "DateTime" | Should -Be $true
        }

        It "Devrait retourner False pour une date/heure invalide" {
            Test-Format -Value "abc" -Format "DateTime" | Should -Be $false
        }
    }

    Context "Validation de format Guid" {
        It "Devrait retourner True pour un GUID valide" {
            Test-Format -Value "123e4567-e89b-12d3-a456-426614174000" -Format "Guid" | Should -Be $true
        }

        It "Devrait retourner False pour un GUID invalide" {
            Test-Format -Value "abc" -Format "Guid" | Should -Be $false
        }
    }

    Context "Validation de format FilePath" {
        It "Devrait retourner True pour un chemin de fichier valide" {
            Test-Format -Value "C:\Windows\System32\notepad.exe" -Format "FilePath" | Should -Be $true
        }

        It "Devrait retourner False pour un chemin de fichier invalide" {
            Test-Format -Value "C:\Invalid|Path" -Format "FilePath" | Should -Be $false
        }
    }

    Context "Validation de format DirectoryPath" {
        It "Devrait retourner True pour un chemin de répertoire valide" {
            Test-Format -Value "C:\Windows\System32" -Format "DirectoryPath" | Should -Be $true
        }

        It "Devrait retourner False pour un chemin de répertoire invalide" {
            Test-Format -Value "C:\Invalid|Path" -Format "DirectoryPath" | Should -Be $false
        }
    }

    Context "Validation de format Custom" {
        It "Devrait retourner True pour une valeur correspondant au pattern personnalisé" {
            Test-Format -Value "abc123" -Format "Custom" -Pattern "^[a-z]+[0-9]+$" | Should -Be $true
        }

        It "Devrait retourner False pour une valeur ne correspondant pas au pattern personnalisé" {
            Test-Format -Value "123abc" -Format "Custom" -Pattern "^[a-z]+[0-9]+$" | Should -Be $false
        }

        It "Devrait lever une exception si le pattern n'est pas spécifié" {
            { Test-Format -Value "abc123" -Format "Custom" } | Should -Throw
        }
    }

    Context "Validation avec ThrowOnFailure" {
        It "Devrait lever une exception en cas d'échec avec ThrowOnFailure" {
            { Test-Format -Value "invalid@" -Format "Email" -ThrowOnFailure } | Should -Throw
        }

        It "Ne devrait pas lever d'exception en cas de succès avec ThrowOnFailure" {
            { Test-Format -Value "user@example.com" -Format "Email" -ThrowOnFailure } | Should -Not -Throw
        }
    }

    Context "Validation avec message d'erreur personnalisé" {
        It "Devrait utiliser le message d'erreur personnalisé en cas d'échec" {
            $customErrorMessage = "Message d'erreur personnalisé"
            $exceptionMessage = $null

            try {
                Test-Format -Value "invalid@" -Format "Email" -ErrorMessage $customErrorMessage -ThrowOnFailure
            } catch {
                $exceptionMessage = $_.Exception.Message
            }

            $exceptionMessage | Should -Be $customErrorMessage
        }
    }
}
