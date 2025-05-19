# Script de test pour les fonctions de conversion ApartmentState
# Ce script teste manuellement les fonctions sans dépendre de Pester

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Fonction d'aide pour afficher les résultats des tests
function Write-TestResult {
    param(
        [string]$TestName,
        [scriptblock]$TestBlock,
        [ConsoleColor]$SuccessColor = [ConsoleColor]::Green,
        [ConsoleColor]$FailureColor = [ConsoleColor]::Red
    )

    $result = $false
    $errorMessage = $null

    try {
        $result = & $TestBlock
    } catch {
        $errorMessage = $_.Exception.Message
    }

    if ($result -eq $true) {
        Write-Host "✓ $TestName" -ForegroundColor $SuccessColor
        return $true
    } else {
        if ($errorMessage) {
            Write-Host "✗ $TestName - Erreur: $errorMessage" -ForegroundColor $FailureColor
        } else {
            Write-Host "✗ $TestName" -ForegroundColor $FailureColor
        }
        return $false
    }
}

# Fonction d'aide pour tester si une exception est lancée
function Test-ShouldThrow {
    param(
        [scriptblock]$ScriptBlock,
        [type]$ExceptionType = [System.Exception]
    )

    try {
        & $ScriptBlock
        return $false
    } catch {
        return $_.Exception -is $ExceptionType
    }
}

# Afficher les informations sur les fonctions exportées
Write-Host "Fonctions exportées liées à ApartmentState :" -ForegroundColor Cyan
Get-Command -Module UnifiedParallel -Name "*ApartmentState*" | Format-Table Name, CommandType

# Tester ConvertTo-ApartmentState
Write-Host "`n=== Tests pour ConvertTo-ApartmentState ===" -ForegroundColor Magenta
$totalTests = 0
$passedTests = 0

$totalTests++
if (Write-TestResult "Convertit 'STA' en System.Threading.ApartmentState.STA" {
    $result = ConvertTo-ApartmentState -Value "STA"
    return $result -eq [System.Threading.ApartmentState]::STA
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Convertit 'MTA' en System.Threading.ApartmentState.MTA" {
    $result = ConvertTo-ApartmentState -Value "MTA"
    return $result -eq [System.Threading.ApartmentState]::MTA
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Convertit 'sta' (insensible à la casse) en System.Threading.ApartmentState.STA" {
    $result = ConvertTo-ApartmentState -Value "sta"
    return $result -eq [System.Threading.ApartmentState]::STA
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Lance une exception pour une valeur invalide" {
    return Test-ShouldThrow { ConvertTo-ApartmentState -Value "InvalidValue" } ([System.ArgumentException])
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne la valeur par défaut pour une valeur invalide" {
    $result = ConvertTo-ApartmentState -Value "InvalidValue" -DefaultValue ([System.Threading.ApartmentState]::MTA)
    return $result -eq [System.Threading.ApartmentState]::MTA
}) { $passedTests++ }

# Tester ConvertFrom-ApartmentState
Write-Host "`n=== Tests pour ConvertFrom-ApartmentState ===" -ForegroundColor Magenta

$totalTests++
if (Write-TestResult "Convertit System.Threading.ApartmentState.STA en 'STA'" {
    $result = ConvertFrom-ApartmentState -EnumValue ([System.Threading.ApartmentState]::STA)
    return $result -eq "STA"
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Convertit System.Threading.ApartmentState.MTA en 'MTA'" {
    $result = ConvertFrom-ApartmentState -EnumValue ([System.Threading.ApartmentState]::MTA)
    return $result -eq "MTA"
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Lance une exception pour une valeur non ApartmentState" {
    return Test-ShouldThrow { ConvertFrom-ApartmentState -EnumValue "NotAnEnum" }
}) { $passedTests++ }

# Tester Test-ApartmentState
Write-Host "`n=== Tests pour Test-ApartmentState ===" -ForegroundColor Magenta

$totalTests++
if (Write-TestResult "Retourne True pour System.Threading.ApartmentState.STA" {
    return Test-ApartmentState -Value ([System.Threading.ApartmentState]::STA)
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne True pour la chaîne 'STA'" {
    return Test-ApartmentState -Value "STA"
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne True pour la chaîne 'sta' (insensible à la casse)" {
    return Test-ApartmentState -Value "sta"
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne False pour la chaîne 'sta' avec IgnoreCase=`$false" {
    return -not (Test-ApartmentState -Value "sta" -IgnoreCase $false)
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne True pour la valeur numérique 0 (STA)" {
    return Test-ApartmentState -Value 0
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne True pour la valeur numérique 1 (MTA)" {
    return Test-ApartmentState -Value 1
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne False pour une valeur invalide" {
    return -not (Test-ApartmentState -Value "InvalidValue")
}) { $passedTests++ }

$totalTests++
if (Write-TestResult "Retourne False pour une valeur numérique invalide" {
    return -not (Test-ApartmentState -Value 999)
}) { $passedTests++ }

# Afficher le résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tests passés: $passedTests / $totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
} else {
    Write-Host "Certains tests ont échoué." -ForegroundColor Red
}
