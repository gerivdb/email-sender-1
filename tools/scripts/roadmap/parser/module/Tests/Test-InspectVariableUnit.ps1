<#
.SYNOPSIS
    Tests unitaires pour la fonction Inspect-Variable.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Inspect-Variable
    qui ne dépendent pas du framework Pester.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable à l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Inspect-Variable importée depuis : $functionPath" -ForegroundColor Green

# Fonction pour exécuter un test
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
            Write-Host "  Réussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Échoué" -ForegroundColor Red
            Write-Host "    Résultat: $result" -ForegroundColor Red
            Write-Host "    Attendu: $expectedValue" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour exécuter un test qui vérifie une propriété
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
            Write-Host "  Réussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Échoué" -ForegroundColor Red
            Write-Host "    Résultat: $($result.$Property)" -ForegroundColor Red
            Write-Host "    Attendu: $ExpectedValue" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour exécuter un test qui vérifie si une exception est levée
function Test-Exception {
    param (
        [string]$Name,
        [scriptblock]$Test,
        [string]$ExpectedExceptionMessage
    )

    Write-Host "Test: $Name" -ForegroundColor Cyan
    try {
        $result = & $Test
        Write-Host "  Échoué: Aucune exception n'a été levée" -ForegroundColor Red
        return $false
    } catch {
        if ($_.Exception.Message -match $ExpectedExceptionMessage) {
            Write-Host "  Réussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Échoué: Exception incorrecte" -ForegroundColor Red
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
if (Test-Property -Name "Inspect-Variable devrait retourner des informations sur une chaîne" -Test {
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
if (Test-Property -Name "Inspect-Variable devrait retourner des informations sur un booléen" -Test {
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
if (Test-Property -Name "Inspect-Variable devrait limiter le nombre d'éléments affichés" -Test {
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

# Tests pour les références circulaires
$totalTests++
if (Test-Case -Name "Inspect-Variable devrait détecter une référence circulaire" -Test {
        $parent = [PSCustomObject]@{
            Name = "Parent"
        }
        $child = [PSCustomObject]@{
            Name   = "Child"
            Parent = $parent
        }
        $parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

        $result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Mark"

        # Vérifier manuellement si la référence circulaire est détectée
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
    } -ExpectedExceptionMessage "Référence circulaire détectée") {
    $passedTests++
}

# Afficher le résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests exécutés: $totalTests" -ForegroundColor Cyan
Write-Host "  Tests réussis: $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })
Write-Host "  Tests échoués: $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le résultat global
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
