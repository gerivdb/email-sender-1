# Script de test manuel pour les fonctions de conversion d'énumération

# Définir une énumération de test
Add-Type -TypeDefinition @"
public enum TestEnum {
    Value1 = 0,
    Value2 = 1,
    Value3 = 2
}
"@

# Importer le module UnifiedParallel
$modulePath = Split-Path -Parent $PSScriptRoot
Import-Module -Name (Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1") -Force

# Afficher les informations sur les fonctions exportées
Write-Host "Fonctions exportées :"
Get-Command -Module UnifiedParallel -Name "*Enum*"

# Tester la fonction ConvertTo-Enum
Write-Host "`nTest de la fonction ConvertTo-Enum :"
try {
    $value = "Value1"
    $enumType = [TestEnum]
    $result = ConvertTo-Enum -Value $value -EnumType $enumType
    Write-Host "ConvertTo-Enum -Value '$value' -EnumType [TestEnum] = $result (Type: $($result.GetType().FullName))"
} catch {
    Write-Host "Erreur : $_"
}

# Tester la fonction ConvertTo-Enum avec une valeur invalide
Write-Host "`nTest de la fonction ConvertTo-Enum avec une valeur invalide :"
try {
    $value = "InvalidValue"
    $enumType = [TestEnum]
    $result = ConvertTo-Enum -Value $value -EnumType $enumType
    Write-Host "ConvertTo-Enum -Value '$value' -EnumType [TestEnum] = $result (Type: $($result.GetType().FullName))"
} catch {
    Write-Host "Erreur : $_"
}

# Tester la fonction ConvertTo-Enum avec valeur par défaut
Write-Host "`nTest de la fonction ConvertTo-Enum avec valeur par défaut :"
try {
    $value = "Value3"
    $enumType = [TestEnum]
    $defaultValue = [TestEnum]::Value1
    $result = ConvertTo-Enum -Value $value -EnumType $enumType -DefaultValue $defaultValue
    Write-Host "ConvertTo-Enum -Value '$value' -EnumType [TestEnum] -DefaultValue [TestEnum]::Value1 = $result (Type: $($result.GetType().FullName))"
} catch {
    Write-Host "Erreur : $_"
}

# Tester la fonction ConvertTo-Enum avec une valeur invalide et une valeur par défaut
Write-Host "`nTest de la fonction ConvertTo-Enum avec une valeur invalide et une valeur par défaut :"
try {
    $value = "InvalidValue"
    $enumType = [TestEnum]
    $defaultValue = [TestEnum]::Value1
    $result = ConvertTo-Enum -Value $value -EnumType $enumType -DefaultValue $defaultValue
    Write-Host "ConvertTo-Enum -Value '$value' -EnumType [TestEnum] -DefaultValue [TestEnum]::Value1 = $result (Type: $($result.GetType().FullName))"
} catch {
    Write-Host "Erreur : $_"
}

# Tester la fonction ConvertFrom-Enum
Write-Host "`nTest de la fonction ConvertFrom-Enum :"
try {
    $enumValue = [TestEnum]::Value1
    $result = ConvertFrom-Enum -EnumValue $enumValue
    Write-Host "ConvertFrom-Enum -EnumValue [TestEnum]::Value1 = '$result' (Type: $($result.GetType().FullName))"
} catch {
    Write-Host "Erreur : $_"
}

# Tester la fonction ConvertFrom-Enum avec une valeur null
Write-Host "`nTest de la fonction ConvertFrom-Enum avec une valeur null :"
try {
    $enumValue = $null
    $result = ConvertFrom-Enum -EnumValue $enumValue
    Write-Host "ConvertFrom-Enum -EnumValue null = '$result' (Type: $($result.GetType().FullName))"
} catch {
    Write-Host "Erreur : $_"
}

# Tester la fonction Test-EnumValue
Write-Host "`nTest de la fonction Test-EnumValue :"
try {
    $value = "Value1"
    $enumType = [TestEnum]
    $result = Test-EnumValue -Value $value -EnumType $enumType
    Write-Host "Test-EnumValue -Value '$value' -EnumType [TestEnum] = $result"
} catch {
    Write-Host "Erreur : $_"
}

# Tester la fonction Test-EnumValue avec une valeur invalide
Write-Host "`nTest de la fonction Test-EnumValue avec une valeur invalide :"
try {
    $value = "InvalidValue"
    $enumType = [TestEnum]
    $result = Test-EnumValue -Value $value -EnumType $enumType
    Write-Host "Test-EnumValue -Value '$value' -EnumType [TestEnum] = $result"
} catch {
    Write-Host "Erreur : $_"
}

# Tester la fonction Test-EnumValue avec une valeur numérique
Write-Host "`nTest de la fonction Test-EnumValue avec une valeur numérique :"
try {
    $value = 1
    $enumType = [TestEnum]
    $result = Test-EnumValue -Value $value -EnumType $enumType
    Write-Host "Test-EnumValue -Value $value -EnumType [TestEnum] = $result"
} catch {
    Write-Host "Erreur : $_"
}

Write-Host "`nTests terminés."
