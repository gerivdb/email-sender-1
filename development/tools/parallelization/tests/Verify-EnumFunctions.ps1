# Script de vérification manuelle des fonctions de conversion d'énumération
# Ce script teste chaque fonction et affiche les résultats

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

# Importer le module UnifiedParallel
$modulePath = Split-Path -Parent $PSScriptRoot
Import-Module -Name (Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1") -Force

# Fonction pour afficher les résultats des tests
function Write-TestResult {
    param (
        [string]$TestName,
        [scriptblock]$TestScript,
        [bool]$ExpectedResult = $true
    )

    Write-Host "Test: $TestName" -ForegroundColor Cyan
    try {
        $result = & $TestScript
        $success = $result -eq $ExpectedResult
        if ($success) {
            Write-Host "  Résultat: SUCCÈS" -ForegroundColor Green
        } else {
            Write-Host "  Résultat: ÉCHEC (attendu: $ExpectedResult, obtenu: $result)" -ForegroundColor Red
        }
        return $success
    } catch {
        Write-Host "  Résultat: ERREUR - $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour exécuter un test qui doit lancer une exception
function Test-ShouldThrow {
    param (
        [scriptblock]$TestScript,
        [type]$ExceptionType = [System.Exception]
    )

    try {
        & $TestScript
        return $false # Le test a échoué si aucune exception n'est lancée
    } catch {
        if ($_.Exception -is $ExceptionType) {
            return $true # Le test a réussi si l'exception est du type attendu
        } else {
            Write-Host "  Exception inattendue: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
            return $false # Le test a échoué si l'exception n'est pas du type attendu
        }
    }
}

# Initialiser les compteurs
$totalTests = 0
$passedTests = 0

# Tester Get-EnumTypeInfo
Write-Host "`n=== Tests pour Get-EnumTypeInfo ===" -ForegroundColor Magenta
$totalTests++
if (Write-TestResult "Récupère les informations sur un type d'énumération simple" {
    $enumInfo = Get-EnumTypeInfo -EnumType ([TestEnum])
    return $enumInfo -ne $null -and 
           $enumInfo.Type -eq [TestEnum] -and 
           $enumInfo.Names -contains "Value1" -and 
           $enumInfo.Values -contains ([TestEnum]::Value1)
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Récupère les informations sur un type d'énumération avec l'attribut Flags" {
    $enumInfo = Get-EnumTypeInfo -EnumType ([TestFlagsEnum])
    return $enumInfo -ne $null -and 
           $enumInfo.Type -eq [TestFlagsEnum] -and 
           $enumInfo.IsFlags -eq $true -and
           $enumInfo.Names -contains "Flag1" -and 
           $enumInfo.Values -contains ([TestFlagsEnum]::Flag1)
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Lance une exception pour un type qui n'est pas une énumération" {
    return Test-ShouldThrow { Get-EnumTypeInfo -EnumType ([string]) } ([System.ArgumentException])
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Utilise le cache pour les appels suivants" {
    $result1 = Get-EnumTypeInfo -EnumType ([TestEnum])
    $result2 = Get-EnumTypeInfo -EnumType ([TestEnum])
    return [object]::ReferenceEquals($result1, $result2)
}) { $passedTests++ }

# Tester ConvertTo-Enum
Write-Host "`n=== Tests pour ConvertTo-Enum ===" -ForegroundColor Magenta
$totalTests++
if (Write-TestResult "Convertit une chaîne valide en énumération" {
    $result = ConvertTo-Enum -Value "Value1" -EnumType ([TestEnum])
    return $result -eq ([TestEnum]::Value1)
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Convertit une chaîne valide (insensible à la casse) en énumération" {
    $result = ConvertTo-Enum -Value "value2" -EnumType ([TestEnum])
    return $result -eq ([TestEnum]::Value2)
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Lance une exception pour une chaîne invalide" {
    return Test-ShouldThrow { ConvertTo-Enum -Value "InvalidValue" -EnumType ([TestEnum]) } ([System.ArgumentException])
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Lance une exception pour un type qui n'est pas une énumération" {
    return Test-ShouldThrow { ConvertTo-Enum -Value "Value" -EnumType ([string]) } ([System.ArgumentException])
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne la valeur convertie pour une chaîne valide avec valeur par défaut" {
    $result = ConvertTo-Enum -Value "Value3" -EnumType ([TestEnum]) -DefaultValue ([TestEnum]::Value1)
    return $result -eq ([TestEnum]::Value3)
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne la valeur par défaut pour une chaîne invalide" {
    $result = ConvertTo-Enum -Value "InvalidValue" -EnumType ([TestEnum]) -DefaultValue ([TestEnum]::Value1)
    return $result -eq ([TestEnum]::Value1)
}) { $passedTests++ }

# Tester ConvertFrom-Enum
Write-Host "`n=== Tests pour ConvertFrom-Enum ===" -ForegroundColor Magenta
$totalTests++
if (Write-TestResult "Convertit une valeur d'énumération en chaîne" {
    $result = ConvertFrom-Enum -EnumValue ([TestEnum]::Value1)
    return $result -eq "Value1"
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Lance une exception pour une valeur null" {
    return Test-ShouldThrow { ConvertFrom-Enum -EnumValue $null } ([System.ArgumentNullException])
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Lance une exception pour une valeur qui n'est pas une énumération" {
    return Test-ShouldThrow { ConvertFrom-Enum -EnumValue "NotAnEnum" } ([System.ArgumentException])
}) { $passedTests++ }

# Tester Test-EnumValue
Write-Host "`n=== Tests pour Test-EnumValue ===" -ForegroundColor Magenta
$totalTests++
if (Write-TestResult "Retourne True pour une valeur d'énumération valide" {
    return Test-EnumValue -Value ([TestEnum]::Value1) -EnumType ([TestEnum])
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne True pour une chaîne valide" {
    return Test-EnumValue -Value "Value1" -EnumType ([TestEnum])
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne True pour une chaîne valide (insensible à la casse)" {
    return Test-EnumValue -Value "value1" -EnumType ([TestEnum])
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne False pour une chaîne invalide" {
    return -not (Test-EnumValue -Value "InvalidValue" -EnumType ([TestEnum]))
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne True pour une valeur numérique valide" {
    return Test-EnumValue -Value 1 -EnumType ([TestEnum])
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne False pour une valeur numérique invalide" {
    return -not (Test-EnumValue -Value 99 -EnumType ([TestEnum]))
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne False pour une valeur null" {
    return -not (Test-EnumValue -Value $null -EnumType ([TestEnum]))
}) { $passedTests++ }

# Afficher le résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Magenta
Write-Host "Tests passés: $passedTests / $totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 2)
Write-Host "Taux de réussite: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { "Green" } else { "Red" })

# Retourner le résultat global
return $passedTests -eq $totalTests
