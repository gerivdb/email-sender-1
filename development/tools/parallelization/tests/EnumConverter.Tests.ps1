# Tests pour les fonctions de conversion d'énumération
# Utilise Pester 5.x

BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
    $moduleName = "UnifiedParallel"
    
    # Importer le module s'il n'est pas déjà importé
    if (-not (Get-Module -Name $moduleName)) {
        Import-Module -Name (Join-Path -Path $modulePath -ChildPath "$moduleName.psm1") -Force
    }
    
    # Définir une énumération de test
    Add-Type -TypeDefinition @"
    using System;
    
    public enum TestEnum {
        Value1 = 0,
        Value2 = 1,
        Value3 = 2
    }
    
    [Flags]
    public enum TestFlagsEnum {
        None = 0,
        Flag1 = 1,
        Flag2 = 2,
        Flag3 = 4,
        All = Flag1 | Flag2 | Flag3
    }
"@
}

Describe "Get-EnumTypeInfo" {
    Context "Récupération des informations sur un type d'énumération" {
        It "Récupère les informations sur un type d'énumération simple" {
            # Arrange
            $enumType = [TestEnum]
            
            # Act
            $result = Get-EnumTypeInfo -EnumType $enumType
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be $enumType
            $result.FullName | Should -Be $enumType.FullName
            $result.UnderlyingType | Should -Be ([Enum]::GetUnderlyingType($enumType))
            $result.IsFlags | Should -Be $false
            $result.Names | Should -Contain "Value1"
            $result.Names | Should -Contain "Value2"
            $result.Names | Should -Contain "Value3"
            $result.Values | Should -Contain ([TestEnum]::Value1)
            $result.Values | Should -Contain ([TestEnum]::Value2)
            $result.Values | Should -Contain ([TestEnum]::Value3)
            $result.NameValueMap["Value1"] | Should -Be ([TestEnum]::Value1)
            $result.NameValueMap["Value2"] | Should -Be ([TestEnum]::Value2)
            $result.NameValueMap["Value3"] | Should -Be ([TestEnum]::Value3)
            $result.ValueNameMap[[TestEnum]::Value1] | Should -Be "Value1"
            $result.ValueNameMap[[TestEnum]::Value2] | Should -Be "Value2"
            $result.ValueNameMap[[TestEnum]::Value3] | Should -Be "Value3"
        }
        
        It "Récupère les informations sur un type d'énumération avec l'attribut Flags" {
            # Arrange
            $enumType = [TestFlagsEnum]
            
            # Act
            $result = Get-EnumTypeInfo -EnumType $enumType
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Type | Should -Be $enumType
            $result.FullName | Should -Be $enumType.FullName
            $result.UnderlyingType | Should -Be ([Enum]::GetUnderlyingType($enumType))
            $result.IsFlags | Should -Be $true
            $result.Names | Should -Contain "None"
            $result.Names | Should -Contain "Flag1"
            $result.Names | Should -Contain "Flag2"
            $result.Names | Should -Contain "Flag3"
            $result.Names | Should -Contain "All"
            $result.Values | Should -Contain ([TestFlagsEnum]::None)
            $result.Values | Should -Contain ([TestFlagsEnum]::Flag1)
            $result.Values | Should -Contain ([TestFlagsEnum]::Flag2)
            $result.Values | Should -Contain ([TestFlagsEnum]::Flag3)
            $result.Values | Should -Contain ([TestFlagsEnum]::All)
            $result.NameValueMap["None"] | Should -Be ([TestFlagsEnum]::None)
            $result.NameValueMap["Flag1"] | Should -Be ([TestFlagsEnum]::Flag1)
            $result.NameValueMap["Flag2"] | Should -Be ([TestFlagsEnum]::Flag2)
            $result.NameValueMap["Flag3"] | Should -Be ([TestFlagsEnum]::Flag3)
            $result.NameValueMap["All"] | Should -Be ([TestFlagsEnum]::All)
            $result.ValueNameMap[[TestFlagsEnum]::None] | Should -Be "None"
            $result.ValueNameMap[[TestFlagsEnum]::Flag1] | Should -Be "Flag1"
            $result.ValueNameMap[[TestFlagsEnum]::Flag2] | Should -Be "Flag2"
            $result.ValueNameMap[[TestFlagsEnum]::Flag3] | Should -Be "Flag3"
            $result.ValueNameMap[[TestFlagsEnum]::All] | Should -Be "All"
        }
        
        It "Lance une exception pour un type qui n'est pas une énumération" {
            # Arrange
            $enumType = [string]
            
            # Act & Assert
            { Get-EnumTypeInfo -EnumType $enumType } | Should -Throw -ExceptionType ([System.ArgumentException])
        }
        
        It "Utilise le cache pour les appels suivants" {
            # Arrange
            $enumType = [TestEnum]
            
            # Act
            $result1 = Get-EnumTypeInfo -EnumType $enumType
            $result2 = Get-EnumTypeInfo -EnumType $enumType
            
            # Assert
            $result1 | Should -Be $result2
        }
        
        It "Ignore le cache si NoCache est spécifié" {
            # Arrange
            $enumType = [TestEnum]
            
            # Act
            $result1 = Get-EnumTypeInfo -EnumType $enumType
            $result2 = Get-EnumTypeInfo -EnumType $enumType -NoCache
            
            # Assert
            $result1 | Should -Not -Be $result2
        }
    }
}

Describe "ConvertTo-Enum" {
    Context "Conversion de chaîne en énumération" {
        It "Convertit une chaîne valide en énumération" {
            # Arrange
            $value = "Value1"
            $enumType = [TestEnum]
            
            # Act
            $result = ConvertTo-Enum -Value $value -EnumType $enumType
            
            # Assert
            $result | Should -Be ([TestEnum]::Value1)
            $result | Should -BeOfType [TestEnum]
        }
        
        It "Convertit une chaîne valide (insensible à la casse) en énumération" {
            # Arrange
            $value = "value2"
            $enumType = [TestEnum]
            
            # Act
            $result = ConvertTo-Enum -Value $value -EnumType $enumType
            
            # Assert
            $result | Should -Be ([TestEnum]::Value2)
            $result | Should -BeOfType [TestEnum]
        }
        
        It "Lance une exception pour une chaîne invalide" {
            # Arrange
            $value = "InvalidValue"
            $enumType = [TestEnum]
            
            # Act & Assert
            { ConvertTo-Enum -Value $value -EnumType $enumType } | Should -Throw -ExceptionType ([System.ArgumentException])
        }
        
        It "Lance une exception pour un type qui n'est pas une énumération" {
            # Arrange
            $value = "Value"
            $enumType = [string]
            
            # Act & Assert
            { ConvertTo-Enum -Value $value -EnumType $enumType } | Should -Throw -ExceptionType ([System.ArgumentException])
        }
        
        It "Retourne la valeur convertie pour une chaîne valide avec valeur par défaut" {
            # Arrange
            $value = "Value3"
            $enumType = [TestEnum]
            $defaultValue = [TestEnum]::Value1
            
            # Act
            $result = ConvertTo-Enum -Value $value -EnumType $enumType -DefaultValue $defaultValue
            
            # Assert
            $result | Should -Be ([TestEnum]::Value3)
            $result | Should -BeOfType [TestEnum]
        }
        
        It "Retourne la valeur par défaut pour une chaîne invalide" {
            # Arrange
            $value = "InvalidValue"
            $enumType = [TestEnum]
            $defaultValue = [TestEnum]::Value1
            
            # Act
            $result = ConvertTo-Enum -Value $value -EnumType $enumType -DefaultValue $defaultValue
            
            # Assert
            $result | Should -Be $defaultValue
            $result | Should -BeOfType [TestEnum]
        }
        
        It "Retourne la valeur par défaut pour un type qui n'est pas une énumération" {
            # Arrange
            $value = "Value"
            $enumType = [string]
            $defaultValue = "DefaultValue"
            
            # Act
            $result = ConvertTo-Enum -Value $value -EnumType $enumType -DefaultValue $defaultValue
            
            # Assert
            $result | Should -Be $defaultValue
            $result | Should -BeOfType [string]
        }
    }
}

Describe "ConvertFrom-Enum" {
    Context "Conversion d'énumération en chaîne" {
        It "Convertit une valeur d'énumération en chaîne" {
            # Arrange
            $enumValue = [TestEnum]::Value1
            
            # Act
            $result = ConvertFrom-Enum -EnumValue $enumValue
            
            # Assert
            $result | Should -Be "Value1"
            $result | Should -BeOfType [string]
        }
        
        It "Lance une exception pour une valeur null" {
            # Arrange
            $enumValue = $null
            
            # Act & Assert
            { ConvertFrom-Enum -EnumValue $enumValue } | Should -Throw -ExceptionType ([System.ArgumentNullException])
        }
        
        It "Lance une exception pour une valeur qui n'est pas une énumération" {
            # Arrange
            $enumValue = "NotAnEnum"
            
            # Act & Assert
            { ConvertFrom-Enum -EnumValue $enumValue } | Should -Throw -ExceptionType ([System.ArgumentException])
        }
    }
}

Describe "Test-EnumValue" {
    Context "Validation de valeur d'énumération" {
        It "Retourne $true pour une valeur d'énumération valide" {
            # Arrange
            $value = [TestEnum]::Value1
            $enumType = [TestEnum]
            
            # Act
            $result = Test-EnumValue -Value $value -EnumType $enumType
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $true pour une chaîne valide" {
            # Arrange
            $value = "Value1"
            $enumType = [TestEnum]
            
            # Act
            $result = Test-EnumValue -Value $value -EnumType $enumType
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $true pour une chaîne valide (insensible à la casse)" {
            # Arrange
            $value = "value1"
            $enumType = [TestEnum]
            
            # Act
            $result = Test-EnumValue -Value $value -EnumType $enumType
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $false pour une chaîne invalide" {
            # Arrange
            $value = "InvalidValue"
            $enumType = [TestEnum]
            
            # Act
            $result = Test-EnumValue -Value $value -EnumType $enumType
            
            # Assert
            $result | Should -Be $false
        }
        
        It "Retourne $true pour une valeur numérique valide" {
            # Arrange
            $value = 1
            $enumType = [TestEnum]
            
            # Act
            $result = Test-EnumValue -Value $value -EnumType $enumType
            
            # Assert
            $result | Should -Be $true
        }
        
        It "Retourne $false pour une valeur numérique invalide" {
            # Arrange
            $value = 99
            $enumType = [TestEnum]
            
            # Act
            $result = Test-EnumValue -Value $value -EnumType $enumType
            
            # Assert
            $result | Should -Be $false
        }
        
        It "Retourne $false pour une valeur null" {
            # Arrange
            $value = $null
            $enumType = [TestEnum]
            
            # Act
            $result = Test-EnumValue -Value $value -EnumType $enumType
            
            # Assert
            $result | Should -Be $false
        }
        
        It "Lance une exception pour un type qui n'est pas une énumération" {
            # Arrange
            $value = "Value"
            $enumType = [string]
            
            # Act & Assert
            { Test-EnumValue -Value $value -EnumType $enumType } | Should -Throw -ExceptionType ([System.ArgumentException])
        }
    }
}
