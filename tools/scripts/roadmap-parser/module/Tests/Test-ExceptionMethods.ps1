<#
.SYNOPSIS
    Tests pour valider la documentation des méthodes ToString() et GetBaseException() de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation des méthodes ToString() et GetBaseException() de System.Exception.

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
Describe "Tests des méthodes ToString() et GetBaseException() de System.Exception" {
    Context "Méthode ToString()" {
        It "Devrait retourner une représentation textuelle complète de l'exception" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $exceptionString = $_.Exception.ToString()
                
                $exceptionString | Should -Not -BeNullOrEmpty
                $exceptionString | Should -Match "System.FormatException"
                $exceptionString | Should -Match "Input string was not in a correct format"
                $exceptionString | Should -Match "at System.Number.ParseInt32"
                $exceptionString | Should -Match "at System.Int32.Parse"
            }
        }
        
        It "Devrait inclure le type d'exception, le message et la pile d'appels" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $exceptionString = $_.Exception.ToString()
                $type = $_.Exception.GetType().FullName
                $message = $_.Exception.Message
                
                $exceptionString | Should -Match $type
                $exceptionString | Should -Match $message
                $exceptionString | Should -Match "at System.Number.ParseInt32"
            }
        }
        
        It "Devrait inclure les exceptions internes dans la sortie" {
            try {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    throw [System.InvalidOperationException]::new("Opération échouée", $_.Exception)
                }
            }
            catch {
                $exceptionString = $_.Exception.ToString()
                
                $exceptionString | Should -Match "System.InvalidOperationException"
                $exceptionString | Should -Match "Opération échouée"
                $exceptionString | Should -Match "System.FormatException"
                $exceptionString | Should -Match "Input string was not in a correct format"
                $exceptionString | Should -Match "---> System.FormatException"
                $exceptionString | Should -Match "--- Fin de la trace de la pile d'exception interne ---"
            }
        }
    }
    
    Context "Méthode GetBaseException()" {
        It "Devrait retourner l'exception elle-même si elle n'a pas d'exception interne" {
            $exception = [System.ArgumentException]::new("Argument invalide")
            $baseException = $exception.GetBaseException()
            
            $baseException | Should -Be $exception
            $baseException.GetType().FullName | Should -Be "System.ArgumentException"
        }
        
        It "Devrait retourner l'exception la plus interne dans une chaîne d'exceptions" {
            $innerException = [System.FormatException]::new("Format invalide")
            $middleException = [System.IO.IOException]::new("Erreur d'IO", $innerException)
            $outerException = [System.InvalidOperationException]::new("Opération invalide", $middleException)
            
            $baseException = $outerException.GetBaseException()
            
            $baseException | Should -Be $innerException
            $baseException.GetType().FullName | Should -Be "System.FormatException"
            $baseException.Message | Should -Be "Format invalide"
        }
        
        It "Devrait parcourir récursivement la chaîne d'exceptions" {
            $level4 = [System.FormatException]::new("Niveau 4")
            $level3 = [System.IO.IOException]::new("Niveau 3", $level4)
            $level2 = [System.Security.SecurityException]::new("Niveau 2", $level3)
            $level1 = [System.InvalidOperationException]::new("Niveau 1", $level2)
            
            $baseException = $level1.GetBaseException()
            
            $baseException | Should -Be $level4
            $baseException.GetType().FullName | Should -Be "System.FormatException"
            $baseException.Message | Should -Be "Niveau 4"
        }
    }
    
    Context "Exemples de la documentation" {
        It "Exemple 1: Devrait utiliser ToString() pour obtenir des informations complètes sur une exception" {
            $exceptionString = $null
            
            try {
                [int]::Parse("abc")
            }
            catch {
                $exceptionString = $_.Exception.ToString()
            }
            
            $exceptionString | Should -Not -BeNullOrEmpty
            $exceptionString | Should -Match "System.FormatException"
            $exceptionString | Should -Match "Input string was not in a correct format"
            $exceptionString | Should -Match "at System.Number.ParseInt32"
        }
        
        It "Exemple 2: Devrait comparer ToString() avec les propriétés individuelles" {
            $type = $null
            $message = $null
            $stackTrace = $null
            $toString = $null
            
            try {
                [int]::Parse("abc")
            }
            catch {
                $type = $_.Exception.GetType().FullName
                $message = $_.Exception.Message
                $stackTrace = $_.Exception.StackTrace
                $toString = $_.Exception.ToString()
            }
            
            $type | Should -Be "System.FormatException"
            $message | Should -Be "Input string was not in a correct format."
            $stackTrace | Should -Not -BeNullOrEmpty
            $toString | Should -Not -BeNullOrEmpty
            
            $toString | Should -Match $type
            $toString | Should -Match $message
            $toString | Should -Match ([regex]::Escape($stackTrace))
        }
        
        It "Exemple 3: Devrait utiliser GetBaseException() pour accéder à l'exception racine" {
            $topException = $null
            $baseException = $null
            
            try {
                try {
                    try {
                        [int]::Parse("abc")
                    }
                    catch {
                        throw [System.IO.IOException]::new("Erreur de lecture des données", $_.Exception)
                    }
                }
                catch {
                    throw [System.InvalidOperationException]::new("Opération impossible à compléter", $_.Exception)
                }
            }
            catch {
                $topException = $_.Exception
                $baseException = $topException.GetBaseException()
            }
            
            $topException.GetType().FullName | Should -Be "System.InvalidOperationException"
            $topException.Message | Should -Be "Opération impossible à compléter"
            
            $baseException.GetType().FullName | Should -Be "System.FormatException"
            $baseException.Message | Should -Be "Input string was not in a correct format."
        }
        
        It "Exemple 4: Devrait utiliser ToString() avec des exceptions imbriquées" {
            $exceptionString = $null
            
            try {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    throw [System.InvalidOperationException]::new("Opération échouée", $_.Exception)
                }
            }
            catch {
                $exceptionString = $_.Exception.ToString()
            }
            
            $exceptionString | Should -Not -BeNullOrEmpty
            $exceptionString | Should -Match "System.InvalidOperationException"
            $exceptionString | Should -Match "Opération échouée"
            $exceptionString | Should -Match "System.FormatException"
            $exceptionString | Should -Match "Input string was not in a correct format"
            $exceptionString | Should -Match "---> System.FormatException"
            $exceptionString | Should -Match "--- Fin de la trace de la pile d'exception interne ---"
        }
    }
    
    Context "Bonnes pratiques" {
        It "Devrait combiner GetBaseException() avec ToString() pour un diagnostic complet" {
            try {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    throw [System.InvalidOperationException]::new("Opération échouée", $_.Exception)
                }
            }
            catch {
                $baseException = $_.Exception.GetBaseException()
                $baseExceptionString = $baseException.ToString()
                
                $baseException.GetType().FullName | Should -Be "System.FormatException"
                $baseExceptionString | Should -Match "System.FormatException"
                $baseExceptionString | Should -Match "Input string was not in a correct format"
                $baseExceptionString | Should -Not -Match "System.InvalidOperationException"
            }
        }
        
        It "Devrait permettre un traitement conditionnel basé sur le type de l'exception racine" {
            $result = $null
            
            function Test-ExceptionHandling {
                param (
                    [System.Exception]$Exception
                )
                
                $rootCause = $Exception.GetBaseException()
                
                switch ($rootCause.GetType().FullName) {
                    "System.IO.FileNotFoundException" {
                        return "Fichier non trouvé"
                    }
                    "System.FormatException" {
                        return "Format invalide"
                    }
                    "System.ArgumentException" {
                        return "Argument invalide"
                    }
                    default {
                        return "Erreur non spécifique"
                    }
                }
            }
            
            # Tester avec différentes exceptions
            $fileEx = [System.IO.FileNotFoundException]::new("Fichier non trouvé")
            $formatEx = [System.FormatException]::new("Format invalide")
            $argEx = [System.ArgumentException]::new("Argument invalide")
            $genericEx = [System.Exception]::new("Exception générique")
            
            # Tester avec une exception imbriquée
            $nestedEx = [System.InvalidOperationException]::new("Opération invalide", $formatEx)
            
            Test-ExceptionHandling -Exception $fileEx | Should -Be "Fichier non trouvé"
            Test-ExceptionHandling -Exception $formatEx | Should -Be "Format invalide"
            Test-ExceptionHandling -Exception $argEx | Should -Be "Argument invalide"
            Test-ExceptionHandling -Exception $genericEx | Should -Be "Erreur non spécifique"
            Test-ExceptionHandling -Exception $nestedEx | Should -Be "Format invalide"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
