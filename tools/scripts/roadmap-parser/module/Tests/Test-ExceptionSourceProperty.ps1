<#
.SYNOPSIS
    Tests pour valider la documentation de la propriÃ©tÃ© Source de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de la propriÃ©tÃ© Source de System.Exception.

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
Describe "Tests de la propriÃ©tÃ© Source de System.Exception" {
    Context "CaractÃ©ristiques de base de la propriÃ©tÃ© Source" {
        It "Devrait Ãªtre modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Source = "SourceTest"
            $exception.Source | Should -Be "SourceTest"
        }
        
        It "Devrait Ãªtre initialisÃ©e automatiquement dans certains cas" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $_.Exception.Source | Should -Not -BeNullOrEmpty
                $_.Exception.Source | Should -Match "System"
            }
        }
        
        It "Devrait Ãªtre de type String" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Source = "SourceTest"
            $exception.Source | Should -BeOfType [string]
        }
        
        It "Devrait Ãªtre prÃ©servÃ©e lors de la sÃ©rialisation/dÃ©sÃ©rialisation" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Source = "SourceTest"
            
            # SÃ©rialiser et dÃ©sÃ©rialiser l'exception
            $formatter = [System.Runtime.Serialization.Formatters.Binary.BinaryFormatter]::new()
            $stream = [System.IO.MemoryStream]::new()
            
            $formatter.Serialize($stream, $exception)
            $stream.Position = 0
            $deserializedException = $formatter.Deserialize($stream)
            
            $deserializedException.Source | Should -Be "SourceTest"
        }
    }
    
    Context "Exemples de la documentation" {
        It "Exemple 1: Devrait accÃ©der Ã  la propriÃ©tÃ© Source d'une exception" {
            $source = $null
            
            try {
                [int]::Parse("abc")
            }
            catch {
                $source = $_.Exception.Source
            }
            
            $source | Should -Not -BeNullOrEmpty
            $source | Should -Match "System"
        }
        
        It "Exemple 2: Devrait dÃ©finir manuellement la propriÃ©tÃ© Source" {
            $exceptionType = $null
            $message = $null
            $source = $null
            
            try {
                $exception = [System.InvalidOperationException]::new("OpÃ©ration non valide")
                $exception.Source = "MonModule.MaFonction"
                throw $exception
            }
            catch {
                $exceptionType = $_.Exception.GetType().FullName
                $message = $_.Exception.Message
                $source = $_.Exception.Source
            }
            
            $exceptionType | Should -Be "System.InvalidOperationException"
            $message | Should -Be "OpÃ©ration non valide"
            $source | Should -Be "MonModule.MaFonction"
        }
    }
    
    Context "DiffÃ©rence entre Source et autres propriÃ©tÃ©s d'identification" {
        It "Source devrait Ãªtre diffÃ©rente de StackTrace" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $_.Exception.Source | Should -Not -BeNullOrEmpty
                $_.Exception.StackTrace | Should -Not -BeNullOrEmpty
                $_.Exception.Source | Should -Not -Be $_.Exception.StackTrace
            }
        }
        
        It "Source devrait Ãªtre diffÃ©rente de TargetSite" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $_.Exception.Source | Should -Not -BeNullOrEmpty
                $_.Exception.TargetSite | Should -Not -BeNullOrEmpty
                $_.Exception.Source | Should -Not -Be $_.Exception.TargetSite.ToString()
            }
        }
    }
    
    Context "Bonnes pratiques" {
        It "Devrait permettre d'utiliser un nommage significatif" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Source = "Namespace.Classe.MÃ©thode"
            $exception.Source | Should -Be "Namespace.Classe.MÃ©thode"
        }
        
        It "Devrait prÃ©server la source lors de la capture et relance" {
            $originalSource = $null
            $preservedSource = $null
            
            try {
                try {
                    $exception = [System.ArgumentException]::new("Argument invalide")
                    $exception.Source = "SourceOriginale"
                    throw $exception
                }
                catch {
                    $originalSource = $_.Exception.Source
                    
                    # CrÃ©er une nouvelle exception qui prÃ©serve la source originale
                    $newException = [System.InvalidOperationException]::new("Nouvelle erreur", $_.Exception)
                    $newException.Source = $_.Exception.Source + ".PropagÃ©e"
                    throw $newException
                }
            }
            catch {
                $preservedSource = $_.Exception.Source
            }
            
            $originalSource | Should -Be "SourceOriginale"
            $preservedSource | Should -Be "SourceOriginale.PropagÃ©e"
        }
    }
    
    Context "Utilisation dans PowerShell" {
        It "Devrait Ãªtre accessible via l'objet ErrorRecord dans un bloc catch" {
            $source = $null
            
            try {
                [int]::Parse("abc")
            }
            catch {
                $source = $_.Exception.Source
            }
            
            $source | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait pouvoir Ãªtre utilisÃ©e avec d'autres propriÃ©tÃ©s PowerShell" {
            $source = $null
            $category = $null
            $command = $null
            $errorId = $null
            
            try {
                Get-Item "fichier_inexistant.txt" -ErrorAction Stop
            }
            catch {
                $source = $_.Exception.Source
                $category = $_.CategoryInfo.Category
                $command = $_.InvocationInfo.MyCommand
                $errorId = $_.FullyQualifiedErrorId
            }
            
            $source | Should -Not -BeNullOrEmpty
            $category | Should -Not -BeNullOrEmpty
            $errorId | Should -Not -BeNullOrEmpty
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
