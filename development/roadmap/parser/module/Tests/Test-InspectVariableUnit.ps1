<#
.SYNOPSIS
    Tests unitaires pour la fonction Inspect-Variable.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Inspect-Variable
    qui ne dÃ©pendent pas du framework Pester.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers la fonction Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable Ã  l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Inspect-Variable importÃ©e depuis : $functionPath" -ForegroundColor Green

# Fonction pour exÃ©cuter un test
function Test-Case {
    param (
        [string]$Name,
        [scriptblock]$Test,
        [object]$Expected
    )

    Write-Host "Test: $Name" -ForegroundColor Cyan
    try {
        $result = & $Test
        $expectedValue = if ($Expected -is [scriptblock]) { & $Expected } else { $Expected }

        if ($result -eq $expectedValue) {
            Write-Host "  RÃ©ussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Ã‰chouÃ©" -ForegroundColor Red
            Write-Host "    RÃ©sultat: $result" -ForegroundColor Red
            Write-Host "    Attendu: $expectedValue" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour exÃ©cuter un test qui vÃ©rifie une propriÃ©tÃ©
function Test-Property {
    param (
        [string]$Name,
        [scriptblock]$Test,
        [string]$Property,
        [object]$ExpectedValue
    )

    Write-Host "Test: $Name" -ForegroundColor Cyan
    try {
        $result = & $Test

        if ($result.$Property -eq $ExpectedValue) {
            Write-Host "  RÃ©ussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Ã‰chouÃ©" -ForegroundColor Red
            Write-Host "    RÃ©sultat: $($result.$Property)" -ForegroundColor Red
            Write-Host "    Attendu: $ExpectedValue" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour exÃ©cuter un test qui vÃ©rifie si une exception est levÃ©e
function Test-Exception {
    param (
        [string]$Name,
        [scriptblock]$Test,
        [string]$ExpectedExceptionMessage
    )

    Write-Host "Test: $Name" -ForegroundColor Cyan
    try {
        $result = & $Test
        Write-Host "  Ã‰chouÃ©: Aucune exception n'a Ã©tÃ© levÃ©e" -ForegroundColor Red
        return $false
    } catch {
        if ($_.Exception.Message -match $ExpectedExceptionMessage) {
            Write-Host "  RÃ©ussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Ã‰chouÃ©: Exception incorrecte" -ForegroundColor Red
            Write-Host "    Exception: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "    Attendu: $ExpectedExceptionMessage" -ForegroundColor Red
            return $false
        }
    }
}

# Initialiser les compteurs de tests
$totalTests = 0
$passedTests = 0

# Tests pour les types simples
$totalTests++
if (Test-Property -Name "Inspect-Variable devrait retourner des informations sur une chaÃ®ne" -Test {
        Inspect-Variable -InputObject "Test" -Format "Object"
    } -Property "Type" -ExpectedValue "System.String") {
    $passedTests++
}

$totalTests++
if (Test-Property -Name "Inspect-Variable devrait retourner des informations sur un entier" -Test {
        Inspect-Variable -InputObject 42 -Format "Object"
    } -Property "Type" -ExpectedValue "System.Int32") {
    $passedTests++
}

$totalTests++
if (Test-Property -Name "Inspect-Variable devrait retourner des informations sur un boolÃ©en" -Test {
        Inspect-Variable -InputObject $true -Format "Object"
    } -Property "Type" -ExpectedValue "System.Boolean") {
    $passedTests++
}

$totalTests++
if (Test-Property -Name "Inspect-Variable devrait retourner des informations sur une valeur null" -Test {
        Inspect-Variable -InputObject $null -Format "Object"
    } -Property "Type" -ExpectedValue "null") {
    $passedTests++
}

# Tests pour les collections
$totalTests++
if (Test-Property -Name "Inspect-Variable devrait retourner des informations sur un tableau" -Test {
        $array = @(1, 2, 3, 4, 5)
        Inspect-Variable -InputObject $array -Format "Object"
    } -Property "Count" -ExpectedValue 5) {
    $passedTests++
}

$totalTests++
if (Test-Property -Name "Inspect-Variable devrait limiter le nombre d'Ã©lÃ©ments affichÃ©s" -Test {
        $array = 1..20
        Inspect-Variable -InputObject $array -Format "Object" -MaxArrayItems 5
    } -Property "HasMore" -ExpectedValue $true) {
    $passedTests++
}

# Tests pour les objets complexes
$totalTests++
if (Test-Property -Name "Inspect-Variable devrait retourner des informations sur un PSCustomObject" -Test {
        $obj = [PSCustomObject]@{
            Name   = "Test"
            Value  = 42
            Nested = [PSCustomObject]@{
                Property = "NestedValue"
            }
        }
        Inspect-Variable -InputObject $obj -Format "Object"
    } -Property "Type" -ExpectedValue "System.Management.Automation.PSCustomObject") {
    $passedTests++
}

# Tests pour les rÃ©fÃ©rences circulaires
$totalTests++
if (Test-Case -Name "Inspect-Variable devrait dÃ©tecter une rÃ©fÃ©rence circulaire" -Test {
        $parent = [PSCustomObject]@{
            Name = "Parent"
        }
        $child = [PSCustomObject]@{
            Name   = "Child"
            Parent = $parent
        }
        $parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

        $result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Mark"

        # VÃ©rifier manuellement si la rÃ©fÃ©rence circulaire est dÃ©tectÃ©e
        if ($result.Properties -and
            $result.Properties["Child"] -and
            $result.Properties["Child"].Properties -and
            $result.Properties["Child"].Properties["Parent"] -and
            $result.Properties["Child"].Properties["Parent"].IsCircularReference) {
            return $true
        }

        return $false
    } -Expected $true) {
    $passedTests++
}

$totalTests++
if (Test-Exception -Name "Inspect-Variable devrait lever une exception avec CircularReferenceHandling=Throw" -Test {
        $parent = [PSCustomObject]@{
            Name = "Parent"
        }
        $child = [PSCustomObject]@{
            Name   = "Child"
            Parent = $parent
        }
        $parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

        Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Throw"
    } -ExpectedExceptionMessage "RÃ©fÃ©rence circulaire dÃ©tectÃ©e") {
    $passedTests++
}

# Afficher le rÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor Cyan
Write-Host "  Tests rÃ©ussis: $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
Write-Host "  Tests Ã©chouÃ©s: $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le rÃ©sultat global
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
