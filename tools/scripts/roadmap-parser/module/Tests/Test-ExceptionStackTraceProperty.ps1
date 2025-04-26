<#
.SYNOPSIS
    Tests pour valider la documentation de la propriété StackTrace de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de la propriété StackTrace de System.Exception.

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
Describe "Tests de la propriété StackTrace de System.Exception" {
    Context "Caractéristiques de base de la propriété StackTrace" {
        It "Devrait être en lecture seule" {
            $exception = [System.Exception]::new("Message de test")
            { $exception.StackTrace = "Nouvelle pile d'appels" } | Should -Throw
        }
        
        It "Devrait être null pour une exception nouvellement créée" {
            $exception = [System.Exception]::new("Message de test")
            $exception.StackTrace | Should -BeNullOrEmpty
        }
        
        It "Devrait être initialisée lorsque l'exception est levée" {
            $stackTrace = $null
            try {
                throw [System.Exception]::new("Message de test")
            }
            catch {
                $stackTrace = $_.Exception.StackTrace
            }
            
            $stackTrace | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait contenir des informations sur la méthode appelante" {
            $stackTrace = $null
            try {
                throw [System.Exception]::new("Message de test")
            }
            catch {
                $stackTrace = $_.Exception.StackTrace
            }
            
            $stackTrace | Should -Match "<ScriptBlock>"
        }
    }
    
    Context "Exemples de la documentation" {
        It "Exemple 1: Devrait accéder à la propriété StackTrace d'une exception" {
            $stackTrace = $null
            
            function Test-StackTraceExample {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    return $_.Exception.StackTrace
                }
            }
            
            $stackTrace = Test-StackTraceExample
            $stackTrace | Should -Not -BeNullOrEmpty
            $stackTrace | Should -Match "System.Number.ParseInt32"
            $stackTrace | Should -Match "System.Int32.Parse"
        }
        
        It "Exemple 2: Devrait préserver la pile d'appels lors de la relance d'une exception" {
            $outerStackTrace = $null
            $innerStackTrace = $null
            
            function Test-OuterFunction {
                try {
                    Test-InnerFunction
                }
                catch {
                    return $_.Exception.StackTrace
                }
            }
            
            function Test-InnerFunction {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    $innerStackTrace = $_.Exception.StackTrace
                    throw
                }
                
                return $innerStackTrace
            }
            
            $outerStackTrace = Test-OuterFunction
            
            $outerStackTrace | Should -Not -BeNullOrEmpty
            $outerStackTrace | Should -Match "System.Number.ParseInt32"
            $outerStackTrace | Should -Match "Test-InnerFunction"
        }
        
        It "Exemple 3: Devrait accéder à la pile d'appels PowerShell avec Get-PSCallStack" {
            $exceptionStackTrace = $null
            $psCallStack = $null
            
            function Test-PSCallStackExample {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    $exceptionStackTrace = $_.Exception.StackTrace
                    $psCallStack = Get-PSCallStack
                    
                    return @{
                        ExceptionStackTrace = $exceptionStackTrace
                        PSCallStack = $psCallStack
                    }
                }
            }
            
            $result = Test-PSCallStackExample
            
            $result.ExceptionStackTrace | Should -Not -BeNullOrEmpty
            $result.PSCallStack | Should -Not -BeNullOrEmpty
            $result.PSCallStack.Count | Should -BeGreaterThan 0
            $result.PSCallStack[0].Command | Should -Be "Test-PSCallStackExample"
        }
    }
    
    Context "Différences entre StackTrace et Get-PSCallStack" {
        It "StackTrace devrait contenir des informations sur les méthodes .NET" {
            $stackTrace = $null
            
            try {
                [int]::Parse("abc")
            }
            catch {
                $stackTrace = $_.Exception.StackTrace
            }
            
            $stackTrace | Should -Match "System.Number.ParseInt32"
            $stackTrace | Should -Match "System.Int32.Parse"
        }
        
        It "Get-PSCallStack devrait contenir des informations sur les appels PowerShell" {
            function Test-PSCallStackFunction {
                return Get-PSCallStack
            }
            
            $callStack = Test-PSCallStackFunction
            
            $callStack | Should -Not -BeNullOrEmpty
            $callStack.Count | Should -BeGreaterThan 0
            $callStack[0].Command | Should -Be "Test-PSCallStackFunction"
        }
    }
    
    Context "Bonnes pratiques" {
        It "Devrait préserver la pile d'appels d'origine lors de la relance sans paramètre" {
            $originalStackTrace = $null
            $rethrowStackTrace = $null
            
            function Test-RethrowPreservation {
                try {
                    Test-InnerRethrow
                }
                catch {
                    return $_.Exception.StackTrace
                }
            }
            
            function Test-InnerRethrow {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    $originalStackTrace = $_.Exception.StackTrace
                    throw
                }
            }
            
            $rethrowStackTrace = Test-RethrowPreservation
            
            $rethrowStackTrace | Should -Not -BeNullOrEmpty
            $rethrowStackTrace | Should -Match "System.Number.ParseInt32"
            $rethrowStackTrace | Should -Match "Test-InnerRethrow"
        }
        
        It "Devrait créer une nouvelle pile d'appels lors de la création d'une nouvelle exception" {
            $originalStackTrace = $null
            $newExceptionStackTrace = $null
            
            function Test-NewExceptionStackTrace {
                try {
                    Test-InnerNewException
                }
                catch {
                    return $_.Exception.StackTrace
                }
            }
            
            function Test-InnerNewException {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    $originalStackTrace = $_.Exception.StackTrace
                    throw [System.InvalidOperationException]::new("Nouvelle exception", $_.Exception)
                }
            }
            
            $newExceptionStackTrace = Test-NewExceptionStackTrace
            
            $newExceptionStackTrace | Should -Not -BeNullOrEmpty
            $newExceptionStackTrace | Should -Match "Test-InnerNewException"
            $newExceptionStackTrace | Should -Not -Match "System.Number.ParseInt32"
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
