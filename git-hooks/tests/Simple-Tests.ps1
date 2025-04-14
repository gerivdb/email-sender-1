<#
.SYNOPSIS
    Tests simples pour les hooks Git.
.DESCRIPTION
    Ce script contient des tests simples pour les hooks Git.
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

# Importer le module d'analyse des patterns d'erreurs
$modulePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent) -ChildPath "scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module non trouvé: $modulePath"
    exit 1
}

# Fonction pour exécuter un test
function Test-Function {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Test,

        [Parameter()]
        [scriptblock]$Setup,

        [Parameter()]
        [scriptblock]$Cleanup
    )

    Write-Host "Test: $Name" -ForegroundColor Cyan

    try {
        # Exécuter le setup
        if ($Setup) {
            & $Setup
        }

        # Exécuter le test
        $result = & $Test

        if ($result -eq $true) {
            Write-Host "  Résultat: Réussi" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Résultat: Échoué" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur: $_" -ForegroundColor Red
        return $false
    } finally {
        # Exécuter le cleanup
        if ($Cleanup) {
            & $Cleanup
        }
    }
}

# Fonction pour vérifier si deux valeurs sont égales
function Assert-AreEqual {
    param (
        [Parameter(Mandatory = $true)]
        $Expected,

        [Parameter(Mandatory = $true)]
        $Actual,

        [Parameter()]
        [string]$Message = "Les valeurs ne sont pas égales"
    )

    if ($Expected -eq $Actual) {
        return $true
    } else {
        Write-Host "  $Message" -ForegroundColor Red
        Write-Host "    Attendu: $Expected" -ForegroundColor Yellow
        Write-Host "    Obtenu: $Actual" -ForegroundColor Yellow
        return $false
    }
}

# Fonction pour vérifier si une valeur est vraie
function Assert-IsTrue {
    param (
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter()]
        [string]$Message = "La valeur n'est pas vraie"
    )

    if ($Value -eq $true) {
        return $true
    } else {
        Write-Host "  $Message" -ForegroundColor Red
        Write-Host "    Valeur: $Value" -ForegroundColor Yellow
        return $false
    }
}

# Fonction pour vérifier si une valeur est fausse
function Assert-IsFalse {
    param (
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter()]
        [string]$Message = "La valeur n'est pas fausse"
    )

    if ($Value -eq $false) {
        return $true
    } else {
        Write-Host "  $Message" -ForegroundColor Red
        Write-Host "    Valeur: $Value" -ForegroundColor Yellow
        return $false
    }
}

# Fonction pour vérifier si une valeur est nulle
function Assert-IsNull {
    param (
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter()]
        [string]$Message = "La valeur n'est pas nulle"
    )

    if ($null -eq $Value) {
        return $true
    } else {
        Write-Host "  $Message" -ForegroundColor Red
        Write-Host "    Valeur: $Value" -ForegroundColor Yellow
        return $false
    }
}

# Fonction pour vérifier si une valeur n'est pas nulle
function Assert-IsNotNull {
    param (
        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter()]
        [string]$Message = "La valeur est nulle"
    )

    if ($null -ne $Value) {
        return $true
    } else {
        Write-Host "  $Message" -ForegroundColor Red
        return $false
    }
}

# Fonction pour vérifier si une chaîne contient une sous-chaîne
function Assert-Contains {
    param (
        [Parameter(Mandatory = $true)]
        [string]$String,

        [Parameter(Mandatory = $true)]
        [string]$Substring,

        [Parameter()]
        [string]$Message = "La chaîne ne contient pas la sous-chaîne"
    )

    if ($String -like "*$Substring*") {
        return $true
    } else {
        Write-Host "  $Message" -ForegroundColor Red
        Write-Host "    Chaîne: $String" -ForegroundColor Yellow
        Write-Host "    Sous-chaîne: $Substring" -ForegroundColor Yellow
        return $false
    }
}

# Fonction pour vérifier si un fichier existe
function Assert-FileExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter()]
        [string]$Message = "Le fichier n'existe pas"
    )

    if (Test-Path -Path $Path) {
        return $true
    } else {
        Write-Host "  $Message" -ForegroundColor Red
        Write-Host "    Chemin: $Path" -ForegroundColor Yellow
        return $false
    }
}

# Fonction pour vérifier si un fichier n'existe pas
function Assert-FileDoesNotExist {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter()]
        [string]$Message = "Le fichier existe"
    )

    if (-not (Test-Path -Path $Path)) {
        return $true
    } else {
        Write-Host "  $Message" -ForegroundColor Red
        Write-Host "    Chemin: $Path" -ForegroundColor Yellow
        return $false
    }
}

# Tests pour le module ErrorPatternAnalyzer
$testResults = @()

# Test 1: Vérifier que la fonction Get-ErrorPatterns existe
$testResults += Test-Function -Name "La fonction Get-ErrorPatterns existe" -Test {
    Assert-IsNotNull (Get-Command -Name Get-ErrorPatterns -ErrorAction SilentlyContinue)
}

# Test 2: Vérifier que la fonction Get-ErrorPatterns détecte les références nulles
$testResults += Test-Function -Name "Get-ErrorPatterns détecte les références nulles" -Test {
    $script = '$user = $null; $name = $user.Name'
    $patterns = Get-ErrorPatterns -ScriptContent $script

    Assert-IsNotNull $patterns
    $nullRefPattern = $patterns | Where-Object { $_.Id -eq "null-reference" }
    Assert-IsNotNull $nullRefPattern
}

# Test 3: Vérifier que la fonction Get-ErrorPatterns détecte les index hors limites
$testResults += Test-Function -Name "Get-ErrorPatterns détecte les index hors limites" -Test {
    $script = '$array = @(1, 2, 3); $value = $array[5]'
    $patterns = Get-ErrorPatterns -ScriptContent $script

    Assert-IsNotNull $patterns
    $indexPattern = $patterns | Where-Object { $_.Id -eq "index-out-of-bounds" }
    Assert-IsNotNull $indexPattern
}

# Test 4: Vérifier que la fonction Get-ErrorPatterns détecte les conversions de type
$testResults += Test-Function -Name "Get-ErrorPatterns détecte les conversions de type" -Test {
    $script = '$input = "abc"; $number = [int]$input'
    $patterns = Get-ErrorPatterns -ScriptContent $script

    Assert-IsNotNull $patterns
    $typePattern = $patterns | Where-Object { $_.Id -eq "type-conversion" }
    Assert-IsNotNull $typePattern
}

# Test 5: Vérifier que la fonction Get-ErrorPatterns détecte les divisions par zéro
$testResults += Test-Function -Name "Get-ErrorPatterns détecte les divisions par zéro" -Test {
    $script = '$divisor = 0; $quotient = 10 / $divisor'
    $patterns = Get-ErrorPatterns -ScriptContent $script

    Assert-IsNotNull $patterns
    $divPattern = $patterns | Where-Object { $_.Id -eq "division-by-zero" }
    Assert-IsNotNull $divPattern
}

# Tests pour le script Analyze-StagedFiles.ps1
$analyzeScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Analyze-StagedFiles.ps1"

# Test 6: Vérifier que le script Analyze-StagedFiles.ps1 existe
$testResults += Test-Function -Name "Le script Analyze-StagedFiles.ps1 existe" -Test {
    Assert-FileExists $analyzeScriptPath
}

# Tests pour le script Test-PreCommitHook.ps1
$testScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Test-PreCommitHook.ps1"

# Test 7: Vérifier que le script Test-PreCommitHook.ps1 existe
$testResults += Test-Function -Name "Le script Test-PreCommitHook.ps1 existe" -Test {
    Assert-FileExists $testScriptPath
}

# Tests pour le script Install-GitHooks.ps1
$installScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Install-GitHooks.ps1"

# Test 8: Vérifier que le script Install-GitHooks.ps1 existe
$testResults += Test-Function -Name "Le script Install-GitHooks.ps1 existe" -Test {
    Assert-FileExists $installScriptPath
}

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
$passedCount = ($testResults | Where-Object { $_ -eq $true }).Count
$failedCount = ($testResults | Where-Object { $_ -eq $false }).Count
$totalCount = $testResults.Count

Write-Host "  Tests exécutés: $totalCount" -ForegroundColor White
Write-Host "  Tests réussis: $passedCount" -ForegroundColor Green
Write-Host "  Tests échoués: $failedCount" -ForegroundColor Red

# Retourner un code de sortie en fonction des résultats
if ($failedCount -gt 0) {
    exit 1
} else {
    exit 0
}
