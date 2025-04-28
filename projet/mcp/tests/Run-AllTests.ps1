#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests MCP.
.DESCRIPTION
    Ce script exécute tous les tests unitaires et d'intégration pour vérifier le bon fonctionnement du système MCP.
.PARAMETER SkipUnitTests
    Ignore les tests unitaires.
.PARAMETER SkipIntegrationTests
    Ignore les tests d'intégration.
.PARAMETER SkipPerformanceTests
    Ignore les tests de performance.
.EXAMPLE
    .\Run-AllTests.ps1
    Exécute tous les tests.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipUnitTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipIntegrationTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPerformanceTests
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testsRoot = $scriptPath
$unitTestsPath = Join-Path -Path $testsRoot -ChildPath "unit"
$integrationTestsPath = Join-Path -Path $testsRoot -ChildPath "integration"
$performanceTestsPath = Join-Path -Path $testsRoot -ChildPath "performance"

# Fonctions d'aide
function Write-SectionHeader {
    param (
        [string]$Title
    )
    
    $separator = "=" * 80
    
    Write-Host "`n$separator" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$separator" -ForegroundColor Cyan
}

function Run-Tests {
    param (
        [string]$Path,
        [string]$Type
    )
    
    $testFiles = Get-ChildItem -Path $Path -Filter "Test-*.ps1"
    
    if ($testFiles.Count -eq 0) {
        Write-Host "Aucun test $Type trouvé dans $Path" -ForegroundColor Yellow
        return @{
            Total = 0
            Passed = 0
            Failed = 0
        }
    }
    
    $results = @{
        Total = $testFiles.Count
        Passed = 0
        Failed = 0
    }
    
    foreach ($testFile in $testFiles) {
        Write-Host "`nExécution du test $($testFile.Name)..." -ForegroundColor White
        
        try {
            $testResult = & $testFile.FullName
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                $results.Passed++
            }
            else {
                $results.Failed++
            }
        }
        catch {
            Write-Host "Erreur lors de l'exécution du test $($testFile.Name): $_" -ForegroundColor Red
            $results.Failed++
        }
    }
    
    return $results
}

# Exécution des tests
$totalResults = @{
    Total = 0
    Passed = 0
    Failed = 0
}

# Tests unitaires
if (-not $SkipUnitTests) {
    Write-SectionHeader "Tests unitaires"
    
    $unitResults = Run-Tests -Path $unitTestsPath -Type "unitaires"
    
    $totalResults.Total += $unitResults.Total
    $totalResults.Passed += $unitResults.Passed
    $totalResults.Failed += $unitResults.Failed
}

# Tests d'intégration
if (-not $SkipIntegrationTests) {
    Write-SectionHeader "Tests d'intégration"
    
    $integrationResults = Run-Tests -Path $integrationTestsPath -Type "d'intégration"
    
    $totalResults.Total += $integrationResults.Total
    $totalResults.Passed += $integrationResults.Passed
    $totalResults.Failed += $integrationResults.Failed
}

# Tests de performance
if (-not $SkipPerformanceTests) {
    Write-SectionHeader "Tests de performance"
    
    $performanceResults = Run-Tests -Path $performanceTestsPath -Type "de performance"
    
    $totalResults.Total += $performanceResults.Total
    $totalResults.Passed += $performanceResults.Passed
    $totalResults.Failed += $performanceResults.Failed
}

# Résumé global
Write-SectionHeader "Résumé global"

Write-Host "Total: $($totalResults.Total)" -ForegroundColor White
Write-Host "Réussis: $($totalResults.Passed)" -ForegroundColor Green
Write-Host "Échoués: $($totalResults.Failed)" -ForegroundColor Red

# Retourner un code de sortie
if ($totalResults.Failed -eq 0) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
