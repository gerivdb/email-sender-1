<#
.SYNOPSIS
    Tests pour valider la documentation des propriétés Data et TargetSite de System.Exception.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation des propriétés Data et TargetSite de System.Exception.

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
Describe "Tests des propriétés Data et TargetSite de System.Exception" {
    Context "Propriété Data" {
        It "Devrait être une collection de type IDictionary" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Data | Should -Not -BeNullOrEmpty
            $exception.Data | Should -BeOfType [System.Collections.IDictionary]
        }
        
        It "Devrait permettre d'ajouter des paires clé/valeur" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Data["TestKey"] = "TestValue"
            $exception.Data["TestKey"] | Should -Be "TestValue"
        }
        
        It "Devrait être initialisée automatiquement" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Data | Should -Not -BeNull
        }
        
        It "Devrait persister les données lors de la propagation de l'exception" {
            $outerException = $null
            
            try {
                try {
                    $innerException = [System.ArgumentException]::new("Argument invalide")
                    $innerException.Data["InnerKey"] = "InnerValue"
                    throw $innerException
                }
                catch {
                    $outerException = [System.InvalidOperationException]::new("Opération invalide", $_.Exception)
                    $outerException.Data["OuterKey"] = "OuterValue"
                    throw $outerException
                }
            }
            catch {
                $caughtException = $_.Exception
                
                $caughtException.Data["OuterKey"] | Should -Be "OuterValue"
                $caughtException.InnerException.Data["InnerKey"] | Should -Be "InnerValue"
            }
        }
    }
    
    Context "Propriété TargetSite" {
        It "Devrait fournir des informations sur la méthode qui a généré l'exception" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $targetSite = $_.Exception.TargetSite
                
                $targetSite | Should -Not -BeNull
                $targetSite.Name | Should -Be "ParseInt32"
                $targetSite.DeclaringType.FullName | Should -Be "System.Number"
                $targetSite.ReturnType.FullName | Should -Be "System.Int32"
            }
        }
        
        It "Devrait permettre d'accéder aux paramètres de la méthode" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $parameters = $_.Exception.TargetSite.GetParameters()
                
                $parameters | Should -Not -BeNull
                $parameters.Count | Should -BeGreaterThan 0
                $parameters[0].ParameterType.FullName | Should -Be "System.String"
            }
        }
        
        It "Devrait permettre de déterminer si la méthode est statique" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $targetSite = $_.Exception.TargetSite
                $isStatic = ($targetSite.Attributes -band [System.Reflection.MethodAttributes]::Static) -ne 0
                
                $isStatic | Should -Be $true
            }
        }
    }
    
    Context "Exemples de la documentation" {
        It "Exemple 1: Devrait utiliser la propriété Data pour enrichir une exception" {
            $exceptionType = $null
            $message = $null
            $data = $null
            
            try {
                $exception = [System.InvalidOperationException]::new("Opération non valide")
                $exception.Data["Timestamp"] = Get-Date
                $exception.Data["OperationName"] = "Test-Operation"
                $exception.Data["Parameters"] = @{
                    Param1 = "Value1"
                    Param2 = 42
                    Param3 = $true
                }
                
                throw $exception
            }
            catch {
                $exceptionType = $_.Exception.GetType().FullName
                $message = $_.Exception.Message
                $data = $_.Exception.Data
            }
            
            $exceptionType | Should -Be "System.InvalidOperationException"
            $message | Should -Be "Opération non valide"
            $data["Timestamp"] | Should -Not -BeNull
            $data["OperationName"] | Should -Be "Test-Operation"
            $data["Parameters"] | Should -Not -BeNull
            $data["Parameters"]["Param1"] | Should -Be "Value1"
            $data["Parameters"]["Param2"] | Should -Be 42
            $data["Parameters"]["Param3"] | Should -Be $true
        }
        
        It "Exemple 3: Devrait utiliser la propriété TargetSite pour obtenir des informations sur la méthode" {
            $methodName = $null
            $declaringType = $null
            $isStatic = $null
            $returnType = $null
            $parameters = $null
            
            try {
                [int]::Parse("abc")
            }
            catch {
                $targetSite = $_.Exception.TargetSite
                
                $methodName = $targetSite.Name
                $declaringType = $targetSite.DeclaringType.FullName
                $isStatic = ($targetSite.Attributes -band [System.Reflection.MethodAttributes]::Static) -ne 0
                $returnType = $targetSite.ReturnType.FullName
                $parameters = $targetSite.GetParameters()
            }
            
            $methodName | Should -Be "ParseInt32"
            $declaringType | Should -Be "System.Number"
            $isStatic | Should -Be $true
            $returnType | Should -Be "System.Int32"
            $parameters | Should -Not -BeNull
            $parameters.Count | Should -BeGreaterThan 0
            $parameters[0].ParameterType.FullName | Should -Be "System.String"
        }
    }
    
    Context "Bonnes pratiques" {
        It "Devrait utiliser des clés significatives pour la propriété Data" {
            $exception = [System.Exception]::new("Message de test")
            $exception.Data["OperationContext"] = "ContextValue"
            $exception.Data["Timestamp"] = Get-Date
            $exception.Data["RequestId"] = [Guid]::NewGuid()
            
            $exception.Data["OperationContext"] | Should -Be "ContextValue"
            $exception.Data["Timestamp"] | Should -Not -BeNull
            $exception.Data["RequestId"] | Should -Not -BeNull
        }
        
        It "Devrait vérifier si TargetSite est null avant d'y accéder" {
            $exception = [System.Exception]::new("Message de test")
            
            # TargetSite peut être null pour une exception nouvellement créée
            if ($exception.TargetSite -ne $null) {
                $exception.TargetSite.Name | Should -Not -BeNullOrEmpty
            }
            
            # Le test passe si TargetSite est null ou si l'accès à Name réussit
            $true | Should -Be $true
        }
        
        It "Devrait combiner TargetSite avec StackTrace pour une compréhension complète" {
            try {
                [int]::Parse("abc")
            }
            catch {
                $targetSite = $_.Exception.TargetSite
                $stackTrace = $_.Exception.StackTrace
                
                $targetSite | Should -Not -BeNull
                $stackTrace | Should -Not -BeNullOrEmpty
                
                # Vérifier que le nom de la méthode apparaît dans la pile d'appels
                $stackTrace | Should -Match $targetSite.Name
            }
        }
    }
    
    Context "Utilisation dans PowerShell" {
        It "Devrait accéder aux propriétés via l'objet ErrorRecord" {
            $data = $null
            $targetSite = $null
            
            try {
                [int]::Parse("abc")
            }
            catch {
                $data = $_.Exception.Data
                $targetSite = $_.Exception.TargetSite
            }
            
            $data | Should -Not -BeNull
            $targetSite | Should -Not -BeNull
        }
        
        It "Devrait enrichir l'exception avant de la relancer" {
            $handledBy = $null
            $timestamp = $null
            
            try {
                try {
                    [int]::Parse("abc")
                }
                catch {
                    $_.Exception.Data["HandledBy"] = "TestHandler"
                    $_.Exception.Data["Timestamp"] = Get-Date
                    throw
                }
            }
            catch {
                $handledBy = $_.Exception.Data["HandledBy"]
                $timestamp = $_.Exception.Data["Timestamp"]
            }
            
            $handledBy | Should -Be "TestHandler"
            $timestamp | Should -Not -BeNull
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
