<#
.SYNOPSIS
    Tests unitaires pour le script Enrich-DevelopmentLog.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Enrich-DevelopmentLog.ps1
    qui est utilisé par le hook post-commit Git.
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

# Chemin vers le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Enrich-DevelopmentLog.ps1"

# Tests pour le script Enrich-DevelopmentLog.ps1
$testResults = @()

# Test 1: Vérifier que le script existe
$testResults += Test-Function -Name "Le script Enrich-DevelopmentLog.ps1 existe" -Test {
    Assert-FileExists $scriptPath
}

# Test 2: Vérifier que le script génère un rapport
$testResults += Test-Function -Name "Le script génère un rapport" -Test {
    # Créer un fichier temporaire pour le rapport
    $tempReportPath = Join-Path -Path $env:TEMP -ChildPath "post-commit-test-report.md"
    
    # Exécuter le script avec le paramètre SkipJournalUpdate
    $params = @{
        ReportPath = $tempReportPath
        SkipJournalUpdate = $true
    }
    
    # Exécuter le script
    & $scriptPath @params
    
    # Vérifier que le rapport a été généré
    $result = Assert-FileExists $tempReportPath
    
    # Supprimer le fichier temporaire
    if (Test-Path -Path $tempReportPath) {
        Remove-Item -Path $tempReportPath -Force
    }
    
    return $result
}

# Test 3: Vérifier que le script met à jour le journal de développement
$testResults += Test-Function -Name "Le script met à jour le journal de développement" -Test {
    # Créer un fichier temporaire pour le journal
    $tempJournalPath = Join-Path -Path $env:TEMP -ChildPath "journal_de_bord_test.md"
    
    # Exécuter le script avec le paramètre JournalPath
    $params = @{
        JournalPath = $tempJournalPath
        ReportPath = Join-Path -Path $env:TEMP -ChildPath "post-commit-test-report.md"
    }
    
    # Exécuter le script
    & $scriptPath @params
    
    # Vérifier que le journal a été mis à jour
    $result = Assert-FileExists $tempJournalPath
    
    # Supprimer les fichiers temporaires
    if (Test-Path -Path $tempJournalPath) {
        Remove-Item -Path $tempJournalPath -Force
    }
    
    if (Test-Path -Path $params.ReportPath) {
        Remove-Item -Path $params.ReportPath -Force
    }
    
    return $result
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
