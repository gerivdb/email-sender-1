<#
.SYNOPSIS
    Tests pour valider la documentation de la propriÃ©tÃ© Message de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de la propriÃ©tÃ© Message de System.Exception.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-16
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir les tests
Describe "Tests de la propriÃ©tÃ© Message de System.Exception" {
    Context "CaractÃ©ristiques de base de la propriÃ©tÃ© Message" {
        It "Devrait Ãªtre en lecture seule" {
            $exception = [System.Exception]::new("Message de test")
            { $exception.Message = "Nouveau message" } | Should -Throw
        }
        
        It "Devrait Ãªtre initialisÃ©e via le constructeur" {
            $testMessage = "Message de test personnalisÃ©"
            $exception = [System.Exception]::new($testMessage)
            $exception.Message | Should -Be $testMessage
        }
        
        It "Devrait Ãªtre accessible via la propriÃ©tÃ© Message" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Message | Should -Not -BeNullOrEmpty
            $exception.Message | Should -BeOfType [string]
        }
    }
    
    Context "Exemples de la documentation" {
        It "Exemple 1: AccÃ©der Ã  la propriÃ©tÃ© Message d'une exception" {
            $errorMessage = $null
            try {
                $null.ToString()
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Not -BeNullOrEmpty
            $errorMessage | Should -Match "Object reference not set to an instance of an object"
        }
        
        It "Exemple 2: CrÃ©er une exception personnalisÃ©e avec un message spÃ©cifique" {
            $exceptionType = $null
            $errorMessage = $null
            
            try {
                throw [System.ArgumentException]::new("La valeur fournie n'est pas valide.", "monParametre")
            } catch {
                $exceptionType = $_.Exception.GetType().FullName
                $errorMessage = $_.Exception.Message
            }
            
            $exceptionType | Should -Be "System.ArgumentException"
            $errorMessage | Should -Be "La valeur fournie n'est pas valide."
        }
        
        It "Exemple 3: AccÃ©der au message d'une exception interne" {
            $mainErrorMessage = $null
            $innerErrorMessage = $null
            
            try {
                try {
                    [int]::Parse("abc")
                } catch {
                    throw [System.InvalidOperationException]::new("OpÃ©ration Ã©chouÃ©e", $_.Exception)
                }
            } catch {
                $mainErrorMessage = $_.Exception.Message
                $innerErrorMessage = $_.Exception.InnerException.Message
            }
            
            $mainErrorMessage | Should -Be "OpÃ©ration Ã©chouÃ©e"
            $innerErrorMessage | Should -Match "Input string was not in a correct format"
        }
    }
    
    Context "Structure typique des messages par type d'exception" {
        It "ArgumentException devrait suivre le format documentÃ©" {
            $errorMessage = $null
            try {
                throw [System.ArgumentException]::new("Value is invalid", "testParam")
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Match "Value is invalid"
        }
        
        It "ArgumentNullException devrait suivre le format documentÃ©" {
            $errorMessage = $null
            try {
                throw [System.ArgumentNullException]::new("testParam")
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Match "Value cannot be null"
            $errorMessage | Should -Match "testParam"
        }
        
        It "FileNotFoundException devrait suivre le format documentÃ©" {
            $errorMessage = $null
            try {
                throw [System.IO.FileNotFoundException]::new("Could not find file", "C:\test.txt")
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Match "Could not find file"
        }
        
        It "NullReferenceException devrait suivre le format documentÃ©" {
            $errorMessage = $null
            try {
                $null.ToString()
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Match "Object reference not set to an instance of an object"
        }
    }
    
    Context "Utilisation dans PowerShell" {
        It "Devrait Ãªtre accessible via l'objet ErrorRecord dans un bloc catch" {
            $errorMessage = $null
            try {
                [int]::Parse("abc")
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Not -BeNullOrEmpty
            $errorMessage | Should -BeOfType [string]
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
