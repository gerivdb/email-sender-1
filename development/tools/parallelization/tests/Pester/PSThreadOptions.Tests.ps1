# Tests unitaires pour les fonctions de conversion PSThreadOptions
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force
}

Describe "ConvertTo-PSThreadOptions" {
    Context "Conversion de chaîne en PSThreadOptions" {
        It "Convertit 'Default' en System.Management.Automation.Runspaces.PSThreadOptions.Default" {
            # Arrange
            $value = "Default"
            
            # Act
            $result = ConvertTo-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be ([System.Management.Automation.Runspaces.PSThreadOptions]::Default)
            $result | Should -BeOfType [System.Management.Automation.Runspaces.PSThreadOptions]
        }
        
        It "Convertit 'UseNewThread' en System.Management.Automation.Runspaces.PSThreadOptions.UseNewThread" {
            # Arrange
            $value = "UseNewThread"
            
            # Act
            $result = ConvertTo-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be ([System.Management.Automation.Runspaces.PSThreadOptions]::UseNewThread)
            $result | Should -BeOfType [System.Management.Automation.Runspaces.PSThreadOptions]
        }
        
        It "Convertit 'ReuseThread' en System.Management.Automation.Runspaces.PSThreadOptions.ReuseThread" {
            # Arrange
            $value = "ReuseThread"
            
            # Act
            $result = ConvertTo-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be ([System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread)
            $result | Should -BeOfType [System.Management.Automation.Runspaces.PSThreadOptions]
        }
        
        It "Convertit 'default' (insensible à la casse) en System.Management.Automation.Runspaces.PSThreadOptions.Default" {
            # Arrange
            $value = "default"
            
            # Act
            $result = ConvertTo-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be ([System.Management.Automation.Runspaces.PSThreadOptions]::Default)
            $result | Should -BeOfType [System.Management.Automation.Runspaces.PSThreadOptions]
        }
        
        It "Lance une exception pour une valeur invalide" {
            # Arrange
            $value = "InvalidValue"
            
            # Act & Assert
            { ConvertTo-PSThreadOptions -Value $value } | Should -Throw -ExceptionType ([System.ArgumentException])
        }
        
        It "Retourne la valeur par défaut pour une valeur invalide" {
            # Arrange
            $value = "InvalidValue"
            $defaultValue = [System.Management.Automation.Runspaces.PSThreadOptions]::Default
            
            # Act
            $result = ConvertTo-PSThreadOptions -Value $value -DefaultValue $defaultValue
            
            # Assert
            $result | Should -Be $defaultValue
            $result | Should -BeOfType [System.Management.Automation.Runspaces.PSThreadOptions]
        }
    }
}

Describe "ConvertFrom-PSThreadOptions" {
    Context "Conversion de PSThreadOptions en chaîne" {
        It "Convertit System.Management.Automation.Runspaces.PSThreadOptions.Default en 'Default'" {
            # Arrange
            $enumValue = [System.Management.Automation.Runspaces.PSThreadOptions]::Default
            
            # Act
            $result = ConvertFrom-PSThreadOptions -EnumValue $enumValue
            
            # Assert
            $result | Should -Be "Default"
            $result | Should -BeOfType [string]
        }
        
        It "Convertit System.Management.Automation.Runspaces.PSThreadOptions.UseNewThread en 'UseNewThread'" {
            # Arrange
            $enumValue = [System.Management.Automation.Runspaces.PSThreadOptions]::UseNewThread
            
            # Act
            $result = ConvertFrom-PSThreadOptions -EnumValue $enumValue
            
            # Assert
            $result | Should -Be "UseNewThread"
            $result | Should -BeOfType [string]
        }
        
        It "Convertit System.Management.Automation.Runspaces.PSThreadOptions.ReuseThread en 'ReuseThread'" {
            # Arrange
            $enumValue = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
            
            # Act
            $result = ConvertFrom-PSThreadOptions -EnumValue $enumValue
            
            # Assert
            $result | Should -Be "ReuseThread"
            $result | Should -BeOfType [string]
        }
        
        It "Lance une exception pour une valeur non PSThreadOptions" {
            # Arrange & Act & Assert
            { ConvertFrom-PSThreadOptions -EnumValue "NotAnEnum" } | Should -Throw
        }
    }
}

Describe "Test-PSThreadOptions" {
    Context "Validation de valeur PSThreadOptions" {
        It "Retourne $true pour System.Management.Automation.Runspaces.PSThreadOptions.Default" {
            # Arrange
            $value = [System.Management.Automation.Runspaces.PSThreadOptions]::Default
            
            # Act
            $result = Test-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $true pour la chaîne 'Default'" {
            # Arrange
            $value = "Default"
            
            # Act
            $result = Test-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $true pour la chaîne 'default' (insensible à la casse)" {
            # Arrange
            $value = "default"
            
            # Act
            $result = Test-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $false pour la chaîne 'default' avec IgnoreCase=$false" {
            # Arrange
            $value = "default"
            
            # Act
            $result = Test-PSThreadOptions -Value $value -IgnoreCase $false
            
            # Assert
            $result | Should -Be $false
        }
        
        It "Retourne $true pour la valeur numérique 0 (Default)" {
            # Arrange
            $value = 0
            
            # Act
            $result = Test-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $true pour la valeur numérique 1 (UseNewThread)" {
            # Arrange
            $value = 1
            
            # Act
            $result = Test-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $true pour la valeur numérique 2 (ReuseThread)" {
            # Arrange
            $value = 2
            
            # Act
            $result = Test-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $false pour une valeur invalide" {
            # Arrange
            $value = "InvalidValue"
            
            # Act
            $result = Test-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be $false
        }
        
        It "Retourne $false pour une valeur numérique invalide" {
            # Arrange
            $value = 999
            
            # Act
            $result = Test-PSThreadOptions -Value $value
            
            # Assert
            $result | Should -Be $false
        }
    }
}
