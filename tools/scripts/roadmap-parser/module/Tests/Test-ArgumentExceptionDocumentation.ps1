<#
.SYNOPSIS
    Tests pour valider la documentation d'ArgumentException et ses dérivées.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation d'ArgumentException et ses dérivées.

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
Describe "Tests de la documentation d'ArgumentException et ses dérivées" {
    Context "ArgumentException" {
        It "Devrait avoir la propriété ParamName" {
            $exception = [System.ArgumentException]::new("Message de test", "TestParam")
            $exception.ParamName | Should -Be "TestParam"
        }
        
        It "Devrait permettre de spécifier un message et un nom de paramètre" {
            $exception = [System.ArgumentException]::new("Message de test", "TestParam")
            $exception.Message | Should -Match "Message de test"
            $exception.ParamName | Should -Be "TestParam"
        }
        
        It "Exemple 1: Devrait lancer une ArgumentException basique" {
            function Test-Argument {
                param (
                    [string]$Name
                )
                
                if ($Name -match '\d') {
                    throw [System.ArgumentException]::new("Le nom ne doit pas contenir de chiffres", "Name")
                }
                
                return "Nom valide: $Name"
            }
            
            { Test-Argument -Name "John123" } | Should -Throw -ExceptionType [System.ArgumentException]
            
            try {
                Test-Argument -Name "John123"
            }
            catch {
                $_.Exception.Message | Should -Match "Le nom ne doit pas contenir de chiffres"
                $_.Exception.ParamName | Should -Be "Name"
            }
        }
        
        It "Exemple 2: Devrait valider plusieurs arguments" {
            function Add-Numbers {
                param (
                    [int]$A,
                    [int]$B
                )
                
                if ($A -lt 0 -or $B -lt 0) {
                    throw [System.ArgumentException]::new("Les nombres doivent être positifs", 
                        if ($A -lt 0) { "A" } else { "B" })
                }
                
                return $A + $B
            }
            
            { Add-Numbers -A -5 -B 10 } | Should -Throw -ExceptionType [System.ArgumentException]
            
            try {
                Add-Numbers -A -5 -B 10
            }
            catch {
                $_.Exception.Message | Should -Match "Les nombres doivent être positifs"
                $_.Exception.ParamName | Should -Be "A"
            }
            
            { Add-Numbers -A 5 -B -10 } | Should -Throw -ExceptionType [System.ArgumentException]
            
            try {
                Add-Numbers -A 5 -B -10
            }
            catch {
                $_.Exception.Message | Should -Match "Les nombres doivent être positifs"
                $_.Exception.ParamName | Should -Be "B"
            }
            
            Add-Numbers -A 5 -B 10 | Should -Be 15
        }
    }
    
    Context "ArgumentNullException" {
        It "Devrait être une sous-classe d'ArgumentException" {
            [System.ArgumentNullException] | Should -BeOfType [System.Type]
            [System.ArgumentNullException].IsSubclassOf([System.ArgumentException]) | Should -Be $true
        }
        
        It "Devrait permettre de spécifier un nom de paramètre" {
            $exception = [System.ArgumentNullException]::new("TestParam")
            $exception.ParamName | Should -Be "TestParam"
        }
        
        It "Devrait permettre de spécifier un nom de paramètre et un message" {
            $exception = [System.ArgumentNullException]::new("TestParam", "Message de test")
            $exception.ParamName | Should -Be "TestParam"
            $exception.Message | Should -Match "Message de test"
        }
        
        It "Exemple 1: Devrait vérifier un paramètre null" {
            function Process-Data {
                param (
                    [object]$Data
                )
                
                if ($null -eq $Data) {
                    throw [System.ArgumentNullException]::new("Data", "Les données ne peuvent pas être nulles")
                }
                
                return "Traitement de $($Data.GetType().Name) réussi"
            }
            
            { Process-Data -Data $null } | Should -Throw -ExceptionType [System.ArgumentNullException]
            
            try {
                Process-Data -Data $null
            }
            catch {
                $_.Exception.Message | Should -Match "Les données ne peuvent pas être nulles"
                $_.Exception.ParamName | Should -Be "Data"
            }
            
            Process-Data -Data "Test" | Should -Be "Traitement de String réussi"
        }
        
        It "Exemple 2: Devrait vérifier une propriété null" {
            function Process-User {
                param (
                    [PSCustomObject]$User
                )
                
                if ($null -eq $User) {
                    throw [System.ArgumentNullException]::new("User")
                }
                
                if ($null -eq $User.Name) {
                    throw [System.ArgumentNullException]::new("User.Name", "Le nom de l'utilisateur ne peut pas être null")
                }
                
                return "Utilisateur traité: $($User.Name)"
            }
            
            $userWithNullName = [PSCustomObject]@{
                Id = 1
                Name = $null
                Email = "user@example.com"
            }
            
            { Process-User -User $userWithNullName } | Should -Throw -ExceptionType [System.ArgumentNullException]
            
            try {
                Process-User -User $userWithNullName
            }
            catch {
                $_.Exception.Message | Should -Match "Le nom de l'utilisateur ne peut pas être null"
                $_.Exception.ParamName | Should -Be "User.Name"
            }
            
            $validUser = [PSCustomObject]@{
                Id = 1
                Name = "John Doe"
                Email = "user@example.com"
            }
            
            Process-User -User $validUser | Should -Be "Utilisateur traité: John Doe"
        }
    }
    
    Context "ArgumentOutOfRangeException" {
        It "Devrait être une sous-classe d'ArgumentException" {
            [System.ArgumentOutOfRangeException] | Should -BeOfType [System.Type]
            [System.ArgumentOutOfRangeException].IsSubclassOf([System.ArgumentException]) | Should -Be $true
        }
        
        It "Devrait avoir les propriétés ParamName et ActualValue" {
            $exception = [System.ArgumentOutOfRangeException]::new("TestParam", 42, "Message de test")
            $exception.ParamName | Should -Be "TestParam"
            $exception.ActualValue | Should -Be 42
            $exception.Message | Should -Match "Message de test"
        }
        
        It "Exemple 1: Devrait vérifier une plage numérique" {
            function Set-Age {
                param (
                    [int]$Age
                )
                
                if ($Age -lt 0 -or $Age -gt 120) {
                    throw [System.ArgumentOutOfRangeException]::new("Age", $Age, "L'âge doit être compris entre 0 et 120")
                }
                
                return "Âge défini à $Age"
            }
            
            { Set-Age -Age 150 } | Should -Throw -ExceptionType [System.ArgumentOutOfRangeException]
            { Set-Age -Age -10 } | Should -Throw -ExceptionType [System.ArgumentOutOfRangeException]
            
            try {
                Set-Age -Age 150
            }
            catch {
                $_.Exception.Message | Should -Match "L'âge doit être compris entre 0 et 120"
                $_.Exception.ParamName | Should -Be "Age"
                $_.Exception.ActualValue | Should -Be 150
            }
            
            Set-Age -Age 30 | Should -Be "Âge défini à 30"
        }
        
        It "Exemple 2: Devrait vérifier un index" {
            function Get-Element {
                param (
                    [array]$Array,
                    [int]$Index
                )
                
                if ($Index -lt 0 -or $Index -ge $Array.Length) {
                    throw [System.ArgumentOutOfRangeException]::new("Index", $Index, 
                        "L'index doit être compris entre 0 et $($Array.Length - 1)")
                }
                
                return $Array[$Index]
            }
            
            $array = @(1, 2, 3, 4, 5)
            
            { Get-Element -Array $array -Index 10 } | Should -Throw -ExceptionType [System.ArgumentOutOfRangeException]
            { Get-Element -Array $array -Index -1 } | Should -Throw -ExceptionType [System.ArgumentOutOfRangeException]
            
            try {
                Get-Element -Array $array -Index 10
            }
            catch {
                $_.Exception.Message | Should -Match "L'index doit être compris entre 0 et 4"
                $_.Exception.ParamName | Should -Be "Index"
                $_.Exception.ActualValue | Should -Be 10
            }
            
            Get-Element -Array $array -Index 2 | Should -Be 3
        }
    }
    
    Context "Validation des arguments en PowerShell" {
        It "Devrait utiliser les attributs de validation de PowerShell" {
            function Test-ValidationAttributes {
                param (
                    [Parameter(Mandatory)]
                    [ValidateNotNull()]
                    [ValidateNotNullOrEmpty()]
                    [string]$NotNullParam,
                    
                    [ValidateRange(1, 100)]
                    [int]$RangeParam = 50,
                    
                    [ValidateSet("Option1", "Option2", "Option3")]
                    [string]$OptionParam,
                    
                    [ValidatePattern("^[a-zA-Z0-9]+$")]
                    [string]$PatternParam
                )
                
                return "Tous les paramètres sont valides"
            }
            
            { Test-ValidationAttributes -NotNullParam $null } | Should -Throw
            { Test-ValidationAttributes -NotNullParam "Valid" -RangeParam 101 } | Should -Throw
            { Test-ValidationAttributes -NotNullParam "Valid" -OptionParam "Option4" } | Should -Throw
            { Test-ValidationAttributes -NotNullParam "Valid" -PatternParam "Invalid!" } | Should -Throw
            
            Test-ValidationAttributes -NotNullParam "Valid" -RangeParam 50 -OptionParam "Option1" -PatternParam "Valid123" | 
                Should -Be "Tous les paramètres sont valides"
        }
    }
    
    Context "Interception et gestion en PowerShell" {
        It "Devrait intercepter spécifiquement les exceptions liées aux arguments" {
            function Test-ExceptionHandling {
                param (
                    [array]$Array,
                    [int]$Index
                )
                
                try {
                    if ($null -eq $Array) {
                        throw [System.ArgumentNullException]::new("Array")
                    }
                    
                    if ($Index -lt 0 -or $Index -ge $Array.Length) {
                        throw [System.ArgumentOutOfRangeException]::new("Index", $Index, "Index hors limites")
                    }
                    
                    return $Array[$Index]
                }
                catch [System.ArgumentNullException] {
                    return "Erreur: Tableau null"
                }
                catch [System.ArgumentOutOfRangeException] {
                    return "Erreur: Index hors limites ($Index)"
                }
                catch [System.ArgumentException] {
                    return "Erreur d'argument générique"
                }
                catch {
                    return "Erreur inconnue"
                }
            }
            
            Test-ExceptionHandling -Array $null -Index 0 | Should -Be "Erreur: Tableau null"
            Test-ExceptionHandling -Array @(1, 2, 3) -Index 5 | Should -Be "Erreur: Index hors limites (5)"
            Test-ExceptionHandling -Array @(1, 2, 3) -Index 1 | Should -Be 2
        }
    }
}

# Exécuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed
