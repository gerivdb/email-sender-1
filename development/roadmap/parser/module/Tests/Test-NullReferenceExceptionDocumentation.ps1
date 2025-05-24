<#
.SYNOPSIS
    Tests pour valider la documentation de NullReferenceException et ses causes.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider les exemples et les informations
    fournies dans la documentation de NullReferenceException et ses causes.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-17
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©finir les tests
Describe "Tests de la documentation de NullReferenceException et ses causes" {
    Context "NullReferenceException" {
        It "Devrait Ãªtre une sous-classe de SystemException" {
            [System.NullReferenceException] | Should -BeOfType [System.Type]
            [System.NullReferenceException].IsSubclassOf([System.SystemException]) | Should -Be $true
        }
        
        It "Devrait permettre de spÃ©cifier un message" {
            $exception = [System.NullReferenceException]::new("Message de test")
            $exception.Message | Should -Be "Message de test"
        }
        
        It "Exemple 1: Devrait gÃ©nÃ©rer une NullReferenceException pour une rÃ©fÃ©rence non initialisÃ©e" {
            function Test-NullReference1 {
                [PSCustomObject]$user = $null
                
                # Ceci va gÃ©nÃ©rer une NullReferenceException
                return $user.Name
            }
            
            { Test-NullReference1 } | Should -Throw -ExceptionType [System.NullReferenceException]
        }
        
        It "Exemple 2: Devrait gÃ©nÃ©rer une NullReferenceException pour un chaÃ®nage d'appels sans vÃ©rification" {
            function Test-NullReference2 {
                param (
                    [PSCustomObject]$user
                )
                
                # Ceci va gÃ©nÃ©rer une NullReferenceException si $user.Address est null
                return $user.Address.City
            }
            
            $user = [PSCustomObject]@{
                Name = "John Doe"
                Address = $null
            }
            
            { Test-NullReference2 -User $user } | Should -Throw -ExceptionType [System.NullReferenceException]
        }
        
        It "Exemple 3: Devrait gÃ©nÃ©rer une NullReferenceException pour un tableau avec Ã©lÃ©ments nuls" {
            function Test-NullReference3 {
                $array = @("Item1", $null, "Item3")
                
                # Ceci va gÃ©nÃ©rer une NullReferenceException
                return $array[1].Length
            }
            
            { Test-NullReference3 } | Should -Throw -ExceptionType [System.NullReferenceException]
        }
        
        It "Exemple 4: Devrait gÃ©nÃ©rer une NullReferenceException pour une erreur de logique conditionnelle" {
            function Test-NullReference4 {
                param (
                    [int]$id
                )
                
                $user = if ($id -eq 1) {
                    [PSCustomObject]@{
                        Id = 1
                        Name = "John Doe"
                    }
                } else {
                    $null  # Retourne null pour les autres IDs
                }
                
                # Oubli de vÃ©rifier si $user est null
                return $user.Name
            }
            
            { Test-NullReference4 -Id 2 } | Should -Throw -ExceptionType [System.NullReferenceException]
            { Test-NullReference4 -Id 1 } | Should -Not -Throw
            Test-NullReference4 -Id 1 | Should -Be "John Doe"
        }
    }
    
    Context "PrÃ©vention des NullReferenceException" {
        It "Technique 1: Devrait prÃ©venir les NullReferenceException avec une vÃ©rification de nullitÃ© explicite" {
            function Get-UserCity {
                param (
                    [PSCustomObject]$User
                )
                
                if ($null -eq $User) {
                    return $null
                }
                
                if ($null -eq $User.Address) {
                    return $null
                }
                
                return $User.Address.City
            }
            
            $nullUser = $null
            $userWithNullAddress = [PSCustomObject]@{
                Name = "John Doe"
                Address = $null
            }
            $validUser = [PSCustomObject]@{
                Name = "John Doe"
                Address = [PSCustomObject]@{
                    City = "New York"
                }
            }
            
            Get-UserCity -User $nullUser | Should -Be $null
            Get-UserCity -User $userWithNullAddress | Should -Be $null
            Get-UserCity -User $validUser | Should -Be "New York"
        }
        
        It "Technique 2: Devrait prÃ©venir les NullReferenceException avec un opÃ©rateur de coalescence nulle simulÃ©" {
            function Get-UserCity {
                param (
                    [PSCustomObject]$User
                )
                
                $address = if ($null -ne $User) { $User.Address } else { $null }
                $city = if ($null -ne $address) { $address.City } else { "Inconnu" }
                
                return $city
            }
            
            $nullUser = $null
            $userWithNullAddress = [PSCustomObject]@{
                Name = "John Doe"
                Address = $null
            }
            $validUser = [PSCustomObject]@{
                Name = "John Doe"
                Address = [PSCustomObject]@{
                    City = "New York"
                }
            }
            
            Get-UserCity -User $nullUser | Should -Be "Inconnu"
            Get-UserCity -User $userWithNullAddress | Should -Be "Inconnu"
            Get-UserCity -User $validUser | Should -Be "New York"
        }
        
        It "Technique 3: Devrait prÃ©venir les NullReferenceException avec Try-Catch" {
            function Get-UserCity {
                param (
                    [PSCustomObject]$User
                )
                
                try {
                    return $User.Address.City
                } catch [System.NullReferenceException] {
                    return "Inconnu"
                }
            }
            
            $nullUser = $null
            $userWithNullAddress = [PSCustomObject]@{
                Name = "John Doe"
                Address = $null
            }
            $validUser = [PSCustomObject]@{
                Name = "John Doe"
                Address = [PSCustomObject]@{
                    City = "New York"
                }
            }
            
            Get-UserCity -User $nullUser | Should -Be "Inconnu"
            Get-UserCity -User $userWithNullAddress | Should -Be "Inconnu"
            Get-UserCity -User $validUser | Should -Be "New York"
        }
        
        It "Technique 4: Devrait prÃ©venir les NullReferenceException avec une initialisation par dÃ©faut" {
            function Initialize-User {
                param (
                    [string]$Name
                )
                
                return [PSCustomObject]@{
                    Name = $Name
                    Address = [PSCustomObject]@{
                        Street = ""
                        City = ""
                        ZipCode = ""
                    }
                }
            }
            
            $user = Initialize-User -Name "John Doe"
            $user.Name | Should -Be "John Doe"
            $user.Address | Should -Not -BeNullOrEmpty
            $user.Address.City | Should -Be ""
            
            # Pas de NullReferenceException mÃªme si la ville est vide
            { $cityLength = $user.Address.City.Length } | Should -Not -Throw
        }
    }
    
    Context "DÃ©bogage des NullReferenceException" {
        It "Devrait fournir des informations de dÃ©bogage utiles" {
            function Debug-NullReference {
                param (
                    [PSCustomObject]$User
                )
                
                $result = [PSCustomObject]@{
                    UserIsNull = $null -eq $User
                    AddressIsNull = $false
                    Exception = $null
                    ExceptionType = $null
                    ExceptionMessage = $null
                }
                
                if ($null -ne $User) {
                    $result.AddressIsNull = $null -eq $User.Address
                }
                
                try {
                    $city = $User.Address.City
                    return $city
                } catch {
                    $result.Exception = $_
                    $result.ExceptionType = $_.Exception.GetType().FullName
                    $result.ExceptionMessage = $_.Exception.Message
                    return $result
                }
            }
            
            $nullUser = $null
            $result = Debug-NullReference -User $nullUser
            
            $result.UserIsNull | Should -Be $true
            $result.Exception | Should -Not -BeNullOrEmpty
            $result.ExceptionType | Should -Be "System.NullReferenceException"
            $result.ExceptionMessage | Should -Match "Object reference not set to an instance of an object"
        }
    }
    
    Context "DiffÃ©rence entre NullReferenceException et ArgumentNullException" {
        It "Devrait montrer la diffÃ©rence entre NullReferenceException et ArgumentNullException" {
            function Compare-NullExceptions {
                param (
                    [string]$TestCase
                )
                
                # Ceci gÃ©nÃ¨re une ArgumentNullException (validation explicite)
                function Invoke-Data {
                    param (
                        [object]$Data
                    )
                    
                    if ($null -eq $Data) {
                        throw [System.ArgumentNullException]::new("Data")
                    }
                    
                    return $Data.ToString()
                }
                
                # Ceci gÃ©nÃ¨re une NullReferenceException (erreur de runtime)
                function Invoke-DataUnsafe {
                    param (
                        [object]$Data
                    )
                    
                    # Pas de vÃ©rification de nullitÃ©
                    return $Data.ToString()
                }
                
                switch ($TestCase) {
                    "ArgumentNull" {
                        try {
                            Invoke-Data -Data $null
                        } catch {
                            return $_.Exception.GetType().FullName
                        }
                    }
                    "NullReference" {
                        try {
                            Invoke-DataUnsafe -Data $null
                        } catch {
                            return $_.Exception.GetType().FullName
                        }
                    }
                }
            }
            
            Compare-NullExceptions -TestCase "ArgumentNull" | Should -Be "System.ArgumentNullException"
            Compare-NullExceptions -TestCase "NullReference" | Should -Be "System.NullReferenceException"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $PSCommandPath -Output Detailed

