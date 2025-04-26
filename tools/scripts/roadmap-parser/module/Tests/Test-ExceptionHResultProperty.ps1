<#
.SYNOPSIS
    Tests pour valider la documentation de la propriété HResult de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de la propriété HResult de System.Exception.

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
Describe "Tests de la propriété HResult de System.Exception" {
    Context "Caractéristiques de base de la propriété HResult" {
        It "Devrait être modifiable" {
            $exception = [System.Exception]::new("Message de test")
            $exception.HResult = 0x80004005  # E_FAIL
            $exception.HResult | Should -Be 0x80004005
        }
        
        It "Devrait être initialisée automatiquement" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $_.Exception.HResult | Should -Not -Be 0
            }
        }
        
        It "Devrait être de type int" {
            $exception = [System.Exception]::new("Message de test")
            $exception.HResult | Should -BeOfType [int]
        }
    }
    
    Context "Structure d'un code HResult" {
        It "Devrait avoir le bit de sévérité à 1 pour les erreurs" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $hresult = $_.Exception.HResult
                $severity = ($hresult -shr 31) -band 1
                $severity | Should -Be 1
            }
        }
        
        It "Devrait avoir un code de facilité valide" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $hresult = $_.Exception.HResult
                $facility = ($hresult -shr 16) -band 0x7FF
                $facility | Should -BeGreaterOrEqual 0
                $facility | Should -BeLessOrEqual 0x7FF
            }
        }
        
        It "Devrait avoir un code d'erreur spécifique" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $hresult = $_.Exception.HResult
                $errorCode = $hresult -band 0xFFFF
                $errorCode | Should -BeGreaterThan 0
            }
        }
    }
    
    Context "Exemples de la documentation" {
        It "Exemple 1: Devrait accéder à la propriété HResult d'une exception" {
            $hresult = $null
            
            try {
                [int]::Parse("abc")
            }
            catch {
                $hresult = $_.Exception.HResult
            }
            
            $hresult | Should -Not -Be 0
            $hresultHex = "0x$($hresult.ToString('X8'))"
            $hresultHex | Should -Match "^0x8"  # Devrait commencer par 0x8 (bit de sévérité à 1)
        }
        
        It "Exemple 2: Devrait définir manuellement la propriété HResult" {
            $exceptionType = $null
            $message = $null
            $hresult = $null
            
            try {
                $exception = [System.InvalidOperationException]::new("Opération non valide")
                $exception.HResult = 0x80004005  # E_FAIL
                throw $exception
            }
            catch {
                $exceptionType = $_.Exception.GetType().FullName
                $message = $_.Exception.Message
                $hresult = $_.Exception.HResult
            }
            
            $exceptionType | Should -Be "System.InvalidOperationException"
            $message | Should -Be "Opération non valide"
            $hresult | Should -Be 0x80004005
        }
        
        It "Exemple 3: Devrait identifier le type d'exception à partir du HResult" {
            # Définir la fonction de l'exemple
            function Get-ExceptionTypeFromHResult {
                param (
                    [int]$HResult
                )
                
                $hresultMap = @{
                    -2147024894 = "System.IO.FileNotFoundException"
                    -2147024891 = "System.UnauthorizedAccessException"
                    -2147024882 = "System.OutOfMemoryException"
                    -2147024809 = "System.ArgumentException"
                    -2146233087 = "System.ArgumentNullException"
                    -2146233086 = "System.ArgumentOutOfRangeException"
                    -2146233079 = "System.InvalidOperationException"
                    -2146232969 = "System.NotSupportedException"
                    -2146232800 = "System.FormatException"
                }
                
                if ($hresultMap.ContainsKey($HResult)) {
                    return $hresultMap[$HResult]
                } else {
                    return "Unknown exception type for HResult: $HResult (0x$($HResult.ToString('X8')))"
                }
            }
            
            # Tester la fonction
            Get-ExceptionTypeFromHResult -HResult -2147024894 | Should -Be "System.IO.FileNotFoundException"
            Get-ExceptionTypeFromHResult -HResult -2146233087 | Should -Be "System.ArgumentNullException"
            Get-ExceptionTypeFromHResult -HResult -2146232800 | Should -Be "System.FormatException"
            Get-ExceptionTypeFromHResult -HResult 0 | Should -Match "Unknown exception type"
        }
    }
    
    Context "Décomposition d'un HResult" {
        It "Devrait décomposer correctement un HResult" {
            # Définir la fonction de l'exemple
            function Get-HResultComponents {
                param (
                    [int]$HResult
                )
                
                # Convertir en entier non signé pour faciliter les opérations bit à bit
                $uHResult = [uint32]$HResult
                
                # Extraire les composantes
                $severity = ($uHResult -shr 31) -band 1
                $reserved = ($uHResult -shr 30) -band 1
                $customerCode = ($uHResult -shr 29) -band 1
                $facility = ($uHResult -shr 16) -band 0x7FF
                $errorCode = $uHResult -band 0xFFFF
                
                # Créer et retourner un objet avec les composantes
                return [PSCustomObject]@{
                    HResult = $HResult
                    HResultHex = "0x$($HResult.ToString('X8'))"
                    Severity = $severity
                    Reserved = $reserved
                    CustomerCode = $customerCode
                    Facility = $facility
                    ErrorCode = $errorCode
                    ErrorCodeHex = "0x$($errorCode.ToString('X4'))"
                }
            }
            
            # Tester la fonction avec un HResult connu
            $hresult = 0x80070002  # FileNotFoundException
            $components = Get-HResultComponents -HResult $hresult
            
            $components.HResult | Should -Be $hresult
            $components.HResultHex | Should -Be "0x80070002"
            $components.Severity | Should -Be 1
            $components.Reserved | Should -Be 0
            $components.CustomerCode | Should -Be 0
            $components.Facility | Should -Be 7  # FACILITY_WIN32
            $components.ErrorCode | Should -Be 2  # ERROR_FILE_NOT_FOUND
            $components.ErrorCodeHex | Should -Be "0x0002"
        }
    }
    
    Context "Bonnes pratiques" {
        It "Devrait permettre de préserver les valeurs standard" {
            # Créer une exception standard
            $exception = [System.IO.FileNotFoundException]::new("Fichier non trouvé", "test.txt")
            $originalHResult = $exception.HResult
            
            # Vérifier que le HResult est standard
            $originalHResult | Should -Not -Be 0
            
            # Modifier et restaurer le HResult
            $exception.HResult = 0x80004005  # E_FAIL
            $exception.HResult | Should -Be 0x80004005
            
            $exception.HResult = $originalHResult
            $exception.HResult | Should -Be $originalHResult
        }
        
        It "Devrait permettre d'utiliser des valeurs personnalisées pour exceptions personnalisées" {
            # Créer une exception personnalisée
            $customHResult = 0x80040001  # Valeur personnalisée
            $exception = [System.Exception]::new("Exception personnalisée")
            $exception.HResult = $customHResult
            
            $exception.HResult | Should -Be $customHResult
        }
    }
    
    Context "Utilisation dans PowerShell" {
        It "Devrait être accessible via l'objet ErrorRecord dans un bloc catch" {
            $hresult = $null
            
            try {
                [int]::Parse("abc")
            }
            catch {
                $hresult = $_.Exception.HResult
            }
            
            $hresult | Should -Not -Be 0
        }
        
        It "Devrait permettre un traitement conditionnel basé sur le HResult" {
            $result = $null
            
            function Test-HResultSwitch {
                param (
                    [int]$HResult
                )
                
                switch ($HResult) {
                    -2147024894 { # 0x80070002 - FileNotFoundException
                        return "Fichier non trouvé"
                    }
                    -2147024891 { # 0x80070005 - UnauthorizedAccessException
                        return "Accès refusé"
                    }
                    -2146233087 { # 0x80131501 - ArgumentNullException
                        return "Argument null"
                    }
                    default {
                        return "Erreur non spécifique"
                    }
                }
            }
            
            Test-HResultSwitch -HResult -2147024894 | Should -Be "Fichier non trouvé"
            Test-HResultSwitch -HResult -2147024891 | Should -Be "Accès refusé"
            Test-HResultSwitch -HResult -2146233087 | Should -Be "Argument null"
            Test-HResultSwitch -HResult 0 | Should -Be "Erreur non spécifique"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
