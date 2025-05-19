# Tests unitaires pour les fonctions de conversion ApartmentState
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force
}

Describe "ConvertTo-ApartmentState" {
    Context "Conversion de chaîne en ApartmentState" {
        It "Convertit 'STA' en System.Threading.ApartmentState.STA" {
            # Arrange
            $value = "STA"
            
            # Act
            $result = ConvertTo-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be ([System.Threading.ApartmentState]::STA)
            $result | Should -BeOfType [System.Threading.ApartmentState]
        }
        
        It "Convertit 'MTA' en System.Threading.ApartmentState.MTA" {
            # Arrange
            $value = "MTA"
            
            # Act
            $result = ConvertTo-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be ([System.Threading.ApartmentState]::MTA)
            $result | Should -BeOfType [System.Threading.ApartmentState]
        }
        
        It "Convertit 'sta' (insensible à la casse) en System.Threading.ApartmentState.STA" {
            # Arrange
            $value = "sta"
            
            # Act
            $result = ConvertTo-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be ([System.Threading.ApartmentState]::STA)
            $result | Should -BeOfType [System.Threading.ApartmentState]
        }
        
        It "Lance une exception pour une valeur invalide" {
            # Arrange
            $value = "InvalidValue"
            
            # Act & Assert
            { ConvertTo-ApartmentState -Value $value } | Should -Throw -ExceptionType ([System.ArgumentException])
        }
        
        It "Retourne la valeur par défaut pour une valeur invalide" {
            # Arrange
            $value = "InvalidValue"
            $defaultValue = [System.Threading.ApartmentState]::MTA
            
            # Act
            $result = ConvertTo-ApartmentState -Value $value -DefaultValue $defaultValue
            
            # Assert
            $result | Should -Be $defaultValue
            $result | Should -BeOfType [System.Threading.ApartmentState]
        }
    }
}

Describe "ConvertFrom-ApartmentState" {
    Context "Conversion d'ApartmentState en chaîne" {
        It "Convertit System.Threading.ApartmentState.STA en 'STA'" {
            # Arrange
            $enumValue = [System.Threading.ApartmentState]::STA
            
            # Act
            $result = ConvertFrom-ApartmentState -EnumValue $enumValue
            
            # Assert
            $result | Should -Be "STA"
            $result | Should -BeOfType [string]
        }
        
        It "Convertit System.Threading.ApartmentState.MTA en 'MTA'" {
            # Arrange
            $enumValue = [System.Threading.ApartmentState]::MTA
            
            # Act
            $result = ConvertFrom-ApartmentState -EnumValue $enumValue
            
            # Assert
            $result | Should -Be "MTA"
            $result | Should -BeOfType [string]
        }
        
        It "Lance une exception pour une valeur non ApartmentState" {
            # Arrange & Act & Assert
            { ConvertFrom-ApartmentState -EnumValue "NotAnEnum" } | Should -Throw
        }
    }
}

Describe "Test-ApartmentState" {
    Context "Validation de valeur ApartmentState" {
        It "Retourne $true pour System.Threading.ApartmentState.STA" {
            # Arrange
            $value = [System.Threading.ApartmentState]::STA
            
            # Act
            $result = Test-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $true pour la chaîne 'STA'" {
            # Arrange
            $value = "STA"
            
            # Act
            $result = Test-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $true pour la chaîne 'sta' (insensible à la casse)" {
            # Arrange
            $value = "sta"
            
            # Act
            $result = Test-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $false pour la chaîne 'sta' avec IgnoreCase=$false" {
            # Arrange
            $value = "sta"
            
            # Act
            $result = Test-ApartmentState -Value $value -IgnoreCase $false
            
            # Assert
            $result | Should -Be $false
        }
        
        It "Retourne $true pour la valeur numérique 0 (STA)" {
            # Arrange
            $value = 0
            
            # Act
            $result = Test-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $true pour la valeur numérique 1 (MTA)" {
            # Arrange
            $value = 1
            
            # Act
            $result = Test-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $false pour une valeur invalide" {
            # Arrange
            $value = "InvalidValue"
            
            # Act
            $result = Test-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be $false
        }
        
        It "Retourne $false pour une valeur numérique invalide" {
            # Arrange
            $value = 999
            
            # Act
            $result = Test-ApartmentState -Value $value
            
            # Assert
            $result | Should -Be $false
        }
    }
}
