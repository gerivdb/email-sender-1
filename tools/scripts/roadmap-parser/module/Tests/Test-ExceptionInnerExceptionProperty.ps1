<#
.SYNOPSIS
    Tests pour valider la documentation de la propriÃ©tÃ© InnerException de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de la propriÃ©tÃ© InnerException de System.Exception.

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
Describe "Tests de la propriÃ©tÃ© InnerException de System.Exception" {
    Context "CaractÃ©ristiques de base de la propriÃ©tÃ© InnerException" {
        It "Devrait Ãªtre en lecture seule" {
            $exception = [System.Exception]::new("Message de test")
            { $exception.InnerException = [System.Exception]::new("Test") } | Should -Throw
        }
        
        It "Devrait Ãªtre initialisÃ©e via le constructeur" {
            $innerEx = [System.FormatException]::new("Format invalide")
            $outerEx = [System.Exception]::new("Message externe", $innerEx)
            $outerEx.InnerException | Should -Be $innerEx
        }
        
        It "Devrait Ãªtre null par dÃ©faut" {
            $exception = [System.Exception]::new("Message de test")
            $exception.InnerException | Should -BeNullOrEmpty
        }
        
        It "Devrait conserver les propriÃ©tÃ©s de l'exception interne" {
            $innerMessage = "Message interne de test"
            $innerEx = [System.ArgumentException]::new($innerMessage, "paramName")
            $outerEx = [System.Exception]::new("Message externe", $innerEx)
            
            $outerEx.InnerException.Message | Should -Be $innerMessage
            $outerEx.InnerException.GetType().FullName | Should -Be "System.ArgumentException"
        }
    }
    
    Context "HiÃ©rarchie des exceptions" {
        It "Devrait permettre de crÃ©er une hiÃ©rarchie d'exceptions" {
            # CrÃ©er une hiÃ©rarchie Ã  3 niveaux
            $level3 = [System.FormatException]::new("Erreur de format")
            $level2 = [System.IO.IOException]::new("Erreur d'IO", $level3)
            $level1 = [System.InvalidOperationException]::new("OpÃ©ration invalide", $level2)
            
            $level1.InnerException | Should -Be $level2
            $level1.InnerException.InnerException | Should -Be $level3
            $level1.InnerException.InnerException.InnerException | Should -BeNullOrEmpty
        }
        
        It "Devrait permettre d'accÃ©der Ã  l'exception racine via GetBaseException" {
            # CrÃ©er une hiÃ©rarchie Ã  3 niveaux
            $level3 = [System.FormatException]::new("Erreur de format")
            $level2 = [System.IO.IOException]::new("Erreur d'IO", $level3)
            $level1 = [System.InvalidOperationException]::new("OpÃ©ration invalide", $level2)
            
            $rootException = $level1.GetBaseException()
            $rootException | Should -Be $level3
            $rootException.GetType().FullName | Should -Be "System.FormatException"
        }
    }
    
    Context "Exemples de la documentation" {
        It "Exemple 1: Devrait crÃ©er une exception avec une exception interne" {
            # Simuler l'exemple 1
            $innerEx = [System.FormatException]::new("Input string was not in a correct format.")
            $outerEx = [System.InvalidOperationException]::new("Impossible de traiter la demande", $innerEx)
            
            $outerEx.GetType().FullName | Should -Be "System.InvalidOperationException"
            $outerEx.Message | Should -Be "Impossible de traiter la demande"
            $outerEx.InnerException.GetType().FullName | Should -Be "System.FormatException"
            $outerEx.InnerException.Message | Should -Be "Input string was not in a correct format."
        }
        
        It "Exemple 2: Devrait accÃ©der Ã  l'exception racine dans une hiÃ©rarchie profonde" {
            # Simuler l'exemple 2
            $level4 = [System.FormatException]::new("Input string was not in a correct format.")
            $level3 = [System.IO.IOException]::new("Erreur de lecture des donnÃ©es", $level4)
            $level2 = [System.Security.SecurityException]::new("AccÃ¨s non autorisÃ© aux donnÃ©es", $level3)
            $level1 = [System.InvalidOperationException]::new("OpÃ©ration impossible Ã  complÃ©ter", $level2)
            
            # VÃ©rifier la hiÃ©rarchie
            $level1.InnerException | Should -Be $level2
            $level1.InnerException.InnerException | Should -Be $level3
            $level1.InnerException.InnerException.InnerException | Should -Be $level4
            
            # VÃ©rifier l'accÃ¨s Ã  l'exception racine
            $rootException = $level1.GetBaseException()
            $rootException | Should -Be $level4
            $rootException.GetType().FullName | Should -Be "System.FormatException"
            $rootException.Message | Should -Be "Input string was not in a correct format."
        }
        
        It "Exemple 3: Devrait utiliser AggregateException pour regrouper plusieurs exceptions" {
            # Simuler l'exemple 3
            $exceptions = @(
                [System.ArgumentException]::new("Argument invalide"),
                [System.IO.FileNotFoundException]::new("Fichier introuvable"),
                [System.DivideByZeroException]::new("Division par zÃ©ro")
            )
            
            $aggregateEx = [System.AggregateException]::new("Plusieurs erreurs se sont produites", $exceptions)
            
            # VÃ©rifier les propriÃ©tÃ©s de l'AggregateException
            $aggregateEx.GetType().FullName | Should -Be "System.AggregateException"
            $aggregateEx.Message | Should -Be "Plusieurs erreurs se sont produites"
            $aggregateEx.InnerExceptions.Count | Should -Be 3
            
            # VÃ©rifier les exceptions internes
            $aggregateEx.InnerExceptions[0].GetType().FullName | Should -Be "System.ArgumentException"
            $aggregateEx.InnerExceptions[0].Message | Should -Be "Argument invalide"
            
            $aggregateEx.InnerExceptions[1].GetType().FullName | Should -Be "System.IO.FileNotFoundException"
            $aggregateEx.InnerExceptions[1].Message | Should -Be "Fichier introuvable"
            
            $aggregateEx.InnerExceptions[2].GetType().FullName | Should -Be "System.DivideByZeroException"
            $aggregateEx.InnerExceptions[2].Message | Should -Be "Division par zÃ©ro"
        }
    }
    
    Context "DiffÃ©rence entre InnerException et AggregateException" {
        It "InnerException devrait contenir une seule exception" {
            $innerEx = [System.FormatException]::new("Format invalide")
            $outerEx = [System.Exception]::new("Message externe", $innerEx)
            
            $outerEx.InnerException | Should -Be $innerEx
            $outerEx.InnerException.GetType().FullName | Should -Be "System.FormatException"
        }
        
        It "AggregateException devrait contenir plusieurs exceptions" {
            $exceptions = @(
                [System.ArgumentException]::new("Argument invalide"),
                [System.IO.FileNotFoundException]::new("Fichier introuvable")
            )
            
            $aggregateEx = [System.AggregateException]::new("Plusieurs erreurs", $exceptions)
            
            $aggregateEx.InnerExceptions.Count | Should -Be 2
            $aggregateEx.InnerExceptions[0].GetType().FullName | Should -Be "System.ArgumentException"
            $aggregateEx.InnerExceptions[1].GetType().FullName | Should -Be "System.IO.FileNotFoundException"
        }
    }
    
    Context "Bonnes pratiques" {
        It "Devrait prÃ©server le contexte de l'exception d'origine" {
            $innerEx = [System.FormatException]::new("Format invalide")
            $outerEx = [System.Exception]::new("Message externe", $innerEx)
            
            $outerEx.InnerException | Should -Be $innerEx
            $outerEx.InnerException.Message | Should -Be "Format invalide"
            $outerEx.InnerException.GetType().FullName | Should -Be "System.FormatException"
        }
        
        It "Devrait permettre d'accÃ©der directement Ã  la cause racine" {
            $level3 = [System.FormatException]::new("Erreur de format")
            $level2 = [System.IO.IOException]::new("Erreur d'IO", $level3)
            $level1 = [System.InvalidOperationException]::new("OpÃ©ration invalide", $level2)
            
            $rootException = $level1.GetBaseException()
            $rootException | Should -Be $level3
        }
    }
    
    Context "Utilisation dans PowerShell" {
        It "Devrait Ãªtre accessible via l'objet ErrorRecord dans un bloc catch" {
            $innerException = $null
            $rootException = $null
            
            try {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    throw [System.InvalidOperationException]::new("OpÃ©ration Ã©chouÃ©e", $_.Exception)
                }
            }
            catch {
                $innerException = $_.Exception.InnerException
                $rootException = $_.Exception.GetBaseException()
            }
            
            $innerException | Should -Not -BeNullOrEmpty
            $innerException.GetType().FullName | Should -Match "FormatException"
            $rootException | Should -Not -BeNullOrEmpty
            $rootException.GetType().FullName | Should -Match "FormatException"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
