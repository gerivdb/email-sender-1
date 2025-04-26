<#
.SYNOPSIS
    Tests pour valider la documentation d'IndexOutOfRangeException et ses contextes.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation d'IndexOutOfRangeException et ses contextes.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-17
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Définir les tests
Describe "Tests de la documentation d'IndexOutOfRangeException et ses contextes" {
    Context "IndexOutOfRangeException" {
        It "Devrait être une sous-classe de SystemException" {
            [System.IndexOutOfRangeException] | Should -BeOfType [System.Type]
            [System.IndexOutOfRangeException].IsSubclassOf([System.SystemException]) | Should -Be $true
        }
        
        It "Devrait permettre de spécifier un message" {
            $exception = [System.IndexOutOfRangeException]::new("Message de test")
            $exception.Message | Should -Be "Message de test"
        }
        
        It "Exemple 1: Devrait simuler l'accès à un index négatif (style C#)" {
            function Access-NegativeIndexCSharpStyle {
                param (
                    [array]$Array,
                    [int]$Index
                )
                
                if ($Index -lt 0 -or $Index -ge $Array.Length) {
                    throw [System.IndexOutOfRangeException]::new("Index was outside the bounds of the array.")
                }
                return $Array[$Index]
            }
            
            $array = @(1, 2, 3, 4, 5)
            { Access-NegativeIndexCSharpStyle -Array $array -Index -1 } | Should -Throw -ExceptionType [System.IndexOutOfRangeException]
        }
        
        It "Exemple 2: Devrait gérer l'accès à un index trop grand" {
            function Access-TooLargeIndex {
                param (
                    [array]$Array,
                    [int]$Index
                )
                
                try {
                    return $Array[$Index]
                } catch {
                    return "Erreur: $($_.Exception.GetType().FullName)"
                }
            }
            
            $array = @(1, 2, 3, 4, 5)
            Access-TooLargeIndex -Array $array -Index 10 | Should -Be "Erreur: System.IndexOutOfRangeException"
        }
        
        It "Exemple 3: Devrait gérer une erreur de calcul d'index" {
            function Calculate-InvalidIndex {
                param (
                    [array]$Array,
                    [int]$Position
                )
                
                try {
                    $index = $Position * 2 - $Array.Length
                    return $Array[$index]
                } catch [System.IndexOutOfRangeException] {
                    return "Erreur d'index: L'index calculé ($index) est en dehors des limites du tableau (0..$($Array.Length - 1))"
                }
            }
            
            $array = @(1, 2, 3, 4, 5)
            Calculate-InvalidIndex -Array $array -Index 4 | Should -Be 4  # Position 4 donne index 3
            Calculate-InvalidIndex -Array $array -Position 5 | Should -Match "Erreur d'index: L'index calculé \(5\) est en dehors des limites du tableau \(0..4\)"
        }
        
        It "Exemple 4: Devrait gérer une boucle mal bornée" {
            function Iterate-WithInvalidBounds {
                param (
                    [array]$Array
                )
                
                $result = @()
                
                try {
                    for ($i = 0; $i <= $Array.Length; $i++) {
                        $result += "Élément à l'index $i : $($Array[$i])"
                    }
                } catch {
                    $result += "Erreur à l'itération $i : $($_.Exception.GetType().FullName)"
                }
                
                return $result
            }
            
            $array = @(1, 2, 3, 4, 5)
            $result = Iterate-WithInvalidBounds -Array $array
            
            $result.Count | Should -Be 6  # 5 éléments + 1 message d'erreur
            $result[5] | Should -Match "Erreur à l'itération 5 : System.IndexOutOfRangeException"
        }
        
        It "Exemple 5: Devrait démontrer la confusion entre longueur et index maximal" {
            function Demonstrate-LengthVsMaxIndex {
                param (
                    [array]$Array
                )
                
                $length = $Array.Length
                $maxIndex = $length - 1
                $result = @()
                
                $result += "Longueur du tableau: $length"
                $result += "Index maximal valide: $maxIndex"
                
                try {
                    $result += "Tentative d'accès à l'index $length..."
                    $value = $Array[$length]
                    $result += "Valeur: $value"  # Cette ligne ne sera jamais exécutée
                } catch {
                    $result += "Erreur: $($_.Exception.GetType().FullName)"
                }
                
                $result += "Tentative d'accès à l'index $maxIndex..."
                $value = $Array[$maxIndex]
                $result += "Valeur: $value"
                
                return $result
            }
            
            $array = @(1, 2, 3, 4, 5)
            $result = Demonstrate-LengthVsMaxIndex -Array $array
            
            $result[0] | Should -Be "Longueur du tableau: 5"
            $result[1] | Should -Be "Index maximal valide: 4"
            $result[3] | Should -Match "Erreur: System.IndexOutOfRangeException"
            $result[5] | Should -Be "Valeur: 5"
        }
    }
    
    Context "Prévention des IndexOutOfRangeException" {
        It "Technique 1: Devrait vérifier les limites avant l'accès" {
            function Access-ArraySafely {
                param (
                    [array]$Array,
                    [int]$Index
                )
                
                if ($Index -lt 0 -or $Index -ge $Array.Length) {
                    return "Index $Index hors limites (0..$($Array.Length - 1))"
                }
                
                return $Array[$Index]
            }
            
            $array = @(1, 2, 3, 4, 5)
            Access-ArraySafely -Array $array -Index 2 | Should -Be 3
            Access-ArraySafely -Array $array -Index 10 | Should -Be "Index 10 hors limites (0..4)"
            Access-ArraySafely -Array $array -Index -1 | Should -Be "Index -1 hors limites (0..4)"
        }
        
        It "Technique 2: Devrait utiliser des méthodes sécurisées pour les collections" {
            function Get-ElementSafely {
                param (
                    [System.Collections.ArrayList]$List,
                    [int]$Index
                )
                
                if ($Index -ge 0 -and $Index -lt $List.Count) {
                    return $List[$Index]
                } else {
                    return "Index $Index hors limites (0..$($List.Count - 1))"
                }
            }
            
            $list = [System.Collections.ArrayList]::new()
            $list.AddRange(@(1, 2, 3, 4, 5))
            
            Get-ElementSafely -List $list -Index 2 | Should -Be 3
            Get-ElementSafely -List $list -Index 10 | Should -Be "Index 10 hors limites (0..4)"
        }
        
        It "Technique 4: Devrait utiliser des boucles foreach au lieu de for" {
            function Iterate-Safely {
                param (
                    [array]$Array
                )
                
                $result = @()
                
                # Utiliser foreach au lieu de for pour éviter les problèmes d'index
                foreach ($item in $Array) {
                    $result += $item
                }
                
                return $result
            }
            
            $array = @(1, 2, 3, 4, 5)
            $result = Iterate-Safely -Array $array
            
            $result.Count | Should -Be 5
            $result[0] | Should -Be 1
            $result[4] | Should -Be 5
        }
        
        It "Technique 5: Devrait utiliser des méthodes équivalentes à LINQ" {
            function Get-ElementWithLinq {
                param (
                    [array]$Array,
                    [int]$Index
                )
                
                # Équivalent de LINQ FirstOrDefault en PowerShell
                if ($Index -ge 0 -and $Index -lt $Array.Length) {
                    return $Array[$Index]
                } else {
                    return $null  # Valeur par défaut
                }
            }
            
            $array = @(1, 2, 3, 4, 5)
            Get-ElementWithLinq -Array $array -Index 2 | Should -Be 3
            Get-ElementWithLinq -Array $array -Index 10 | Should -Be $null
        }
    }
    
    Context "Débogage des IndexOutOfRangeException" {
        It "Devrait fournir des informations de débogage utiles" {
            function Debug-IndexOutOfRange {
                param (
                    [array]$Array,
                    [int]$Index
                )
                
                $result = @()
                
                $result += "Débogage d'accès au tableau:"
                $result += "- Longueur du tableau: $($Array.Length)"
                $result += "- Index demandé: $Index"
                $result += "- Limites valides: 0..$($Array.Length - 1)"
                
                if ($Index -lt 0) {
                    $result += "ERREUR: Index négatif"
                    return $result
                }
                
                if ($Index -ge $Array.Length) {
                    $result += "ERREUR: Index supérieur ou égal à la longueur du tableau"
                    return $result
                }
                
                $result += "Accès valide"
                $result += "Valeur: $($Array[$Index])"
                return $result
            }
            
            $array = @(1, 2, 3, 4, 5)
            
            $result1 = Debug-IndexOutOfRange -Array $array -Index 2
            $result1 | Should -Contain "Accès valide"
            $result1 | Should -Contain "Valeur: 3"
            
            $result2 = Debug-IndexOutOfRange -Array $array -Index 5
            $result2 | Should -Contain "ERREUR: Index supérieur ou égal à la longueur du tableau"
            
            $result3 = Debug-IndexOutOfRange -Array $array -Index -1
            $result3 | Should -Contain "ERREUR: Index négatif"
        }
    }
    
    Context "Différence entre IndexOutOfRangeException et ArgumentOutOfRangeException" {
        It "Devrait montrer la différence entre les exceptions" {
            function Compare-OutOfRangeExceptions {
                param (
                    [string]$TestCase
                )
                
                $array = @(1, 2, 3, 4, 5)
                
                try {
                    switch ($TestCase) {
                        "IndexOutOfRange" {
                            # Génère IndexOutOfRangeException
                            return $array[10]
                        }
                        "ArgumentOutOfRange" {
                            # Génère ArgumentOutOfRangeException
                            if (10 -lt 0 -or 10 -ge $array.Length) {
                                throw [System.ArgumentOutOfRangeException]::new("Index", 10, 
                                    "L'index doit être compris entre 0 et $($array.Length - 1)")
                            }
                            return $array[10]
                        }
                    }
                } catch {
                    return $_.Exception.GetType().FullName
                }
            }
            
            Compare-OutOfRangeExceptions -TestCase "IndexOutOfRange" | Should -Be "System.IndexOutOfRangeException"
            Compare-OutOfRangeExceptions -TestCase "ArgumentOutOfRange" | Should -Be "System.ArgumentOutOfRangeException"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
