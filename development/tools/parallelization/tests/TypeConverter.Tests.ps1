# Tests pour la classe TypeConverter
# Utilise Pester 5.x

# Définir une énumération de test
Add-Type -TypeDefinition @"
public enum TestEnum {
    Value1 = 0,
    Value2 = 1,
    Value3 = 2
}
"@

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -Resolve
Import-Module -Name (Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1") -Force

# Tester la méthode ToEnum
Describe "TypeConverter.ToEnum" {
    It "Convertit une chaîne valide en énumération" {
        $value = "Value1"
        $enumType = [TestEnum]

        $result = [TypeConverter]::ToEnum($value, $enumType)

        $result | Should -Be ([TestEnum]::Value1)
    }

    It "Lance une exception pour une chaîne invalide" {
        $value = "InvalidValue"
        $enumType = [TestEnum]

        { [TypeConverter]::ToEnum($value, $enumType) } | Should -Throw
    }
}

# Tester la méthode ToEnum avec valeur par défaut
Describe "TypeConverter.ToEnum avec valeur par défaut" {
    It "Retourne la valeur convertie pour une chaîne valide" {
        $value = "Value3"
        $enumType = [TestEnum]
        $defaultValue = [TestEnum]::Value1

        $result = [TypeConverter]::ToEnum($value, $enumType, $defaultValue)

        $result | Should -Be ([TestEnum]::Value3)
    }

    It "Retourne la valeur par défaut pour une chaîne invalide" {
        $value = "InvalidValue"
        $enumType = [TestEnum]
        $defaultValue = [TestEnum]::Value1

        $result = [TypeConverter]::ToEnum($value, $enumType, $defaultValue)

        $result | Should -Be $defaultValue
    }
}

# Tester la méthode FromEnum
Describe "TypeConverter.FromEnum" {
    It "Convertit une valeur d'énumération en chaîne" {
        $enumValue = [TestEnum]::Value1

        $result = [TypeConverter]::FromEnum($enumValue)

        $result | Should -Be "Value1"
    }

    It "Lance une exception pour une valeur null" {
        $enumValue = $null

        { [TypeConverter]::FromEnum($enumValue) } | Should -Throw
    }
}
