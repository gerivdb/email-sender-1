<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour le mode GRAN.

.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour le mode GRAN, y compris
    les tests de dÃ©tection de complexitÃ© et de domaine, de sÃ©lection de modÃ¨le
    et de granularisation complÃ¨te.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-06-02
#>

# DÃ©finir le chemin des tests
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testFiles = @(
    "Test-GranModeComplexitySimple.ps1",
    "Test-GranModeTemplateSelection.ps1",
    "Test-GranModeGranularization.ps1"
)

# Fonction pour exÃ©cuter un test
function Invoke-Test {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestFile
    )

    $testPath = Join-Path -Path $scriptPath -ChildPath $TestFile

    if (Test-Path -Path $testPath) {
        Write-Host "`n=========================================================" -ForegroundColor Cyan
        Write-Host "ExÃ©cution du test : $TestFile" -ForegroundColor Cyan
        Write-Host "=========================================================" -ForegroundColor Cyan

        try {
            & $testPath
            return $true
        } catch {
            Write-Host "Erreur lors de l'exÃ©cution du test : $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Test introuvable : $TestFile" -ForegroundColor Red
        return $false
    }
}

# ExÃ©cuter tous les tests
$results = @{}

foreach ($testFile in $testFiles) {
    $results[$testFile] = Invoke-Test -TestFile $testFile
}

# Afficher le rÃ©sultat global
Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "RÃ©sultat global des tests" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$totalTests = $testFiles.Count
$passedTests = ($results.Values | Where-Object { $_ -eq $true }).Count

foreach ($testFile in $testFiles) {
    $status = if ($results[$testFile]) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
    $color = if ($results[$testFile]) { "Green" } else { "Red" }
    Write-Host "$testFile : $status" -ForegroundColor $color
}

Write-Host "`nRÃ©sultat global : $passedTests / $totalTests" -ForegroundColor Cyan
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont rÃ©ussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests ont Ã©chouÃ©." -ForegroundColor Red
}

# Retourner le code de sortie
if ($passedTests -eq $totalTests) {
    exit 0
} else {
    exit 1
}
