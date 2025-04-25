<#
.SYNOPSIS
    Tests pour valider la documentation de la propriété Message de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de la propriété Message de System.Exception.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-16
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir les tests
Describe "Tests de la propriété Message de System.Exception" {
    Context "Caractéristiques de base de la propriété Message" {
        It "Devrait être en lecture seule" {
            $exception = [System.Exception]::new("Message de test")
            { $exception.Message = "Nouveau message" } | Should -Throw
        }
        
        It "Devrait être initialisée via le constructeur" {
            $testMessage = "Message de test personnalisé"
            $exception = [System.Exception]::new($testMessage)
            $exception.Message | Should -Be $testMessage
        }
        
        It "Devrait être accessible via la propriété Message" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Message | Should -Not -BeNullOrEmpty
            $exception.Message | Should -BeOfType [string]
        }
    }
    
    Context "Exemples de la documentation" {
        It "Exemple 1: Accéder à la propriété Message d'une exception" {
            $errorMessage = $null
            try {
                $null.ToString()
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Not -BeNullOrEmpty
            $errorMessage | Should -Match "Object reference not set to an instance of an object"
        }
        
        It "Exemple 2: Créer une exception personnalisée avec un message spécifique" {
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
        
        It "Exemple 3: Accéder au message d'une exception interne" {
            $mainErrorMessage = $null
            $innerErrorMessage = $null
            
            try {
                try {
                    [int]::Parse("abc")
                } catch {
                    throw [System.InvalidOperationException]::new("Opération échouée", $_.Exception)
                }
            } catch {
                $mainErrorMessage = $_.Exception.Message
                $innerErrorMessage = $_.Exception.InnerException.Message
            }
            
            $mainErrorMessage | Should -Be "Opération échouée"
            $innerErrorMessage | Should -Match "Input string was not in a correct format"
        }
    }
    
    Context "Structure typique des messages par type d'exception" {
        It "ArgumentException devrait suivre le format documenté" {
            $errorMessage = $null
            try {
                throw [System.ArgumentException]::new("Value is invalid", "testParam")
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Match "Value is invalid"
        }
        
        It "ArgumentNullException devrait suivre le format documenté" {
            $errorMessage = $null
            try {
                throw [System.ArgumentNullException]::new("testParam")
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Match "Value cannot be null"
            $errorMessage | Should -Match "testParam"
        }
        
        It "FileNotFoundException devrait suivre le format documenté" {
            $errorMessage = $null
            try {
                throw [System.IO.FileNotFoundException]::new("Could not find file", "C:\test.txt")
            } catch {
                $errorMessage = $_.Exception.Message
            }
            
            $errorMessage | Should -Match "Could not find file"
        }
        
        It "NullReferenceException devrait suivre le format documenté" {
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
        It "Devrait être accessible via l'objet ErrorRecord dans un bloc catch" {
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

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
