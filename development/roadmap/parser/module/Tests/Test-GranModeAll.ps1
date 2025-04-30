<#
.SYNOPSIS
    Exécute tous les tests unitaires pour le mode GRAN.

.DESCRIPTION
    Ce script exécute tous les tests unitaires pour le mode GRAN, y compris
    les tests de détection de complexité et de domaine, de sélection de modèle
    et de granularisation complète.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-06-02
#>

# Définir le chemin des tests
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testFiles = @(
    "Test-GranModeComplexitySimple.ps1",
    "Test-GranModeTemplateSelection.ps1",
    "Test-GranModeGranularization.ps1"
)

# Fonction pour exécuter un test
function Invoke-Test {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestFile
    )

    $testPath = Join-Path -Path $scriptPath -ChildPath $TestFile

    if (Test-Path -Path $testPath) {
        Write-Host "`n=========================================================" -ForegroundColor Cyan
        Write-Host "Exécution du test : $TestFile" -ForegroundColor Cyan
        Write-Host "=========================================================" -ForegroundColor Cyan

        try {
            & $testPath
            return $true
        } catch {
            Write-Host "Erreur lors de l'exécution du test : $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "Test introuvable : $TestFile" -ForegroundColor Red
        return $false
    }
}

# Exécuter tous les tests
$results = @{}

foreach ($testFile in $testFiles) {
    $results[$testFile] = Invoke-Test -TestFile $testFile
}

# Afficher le résultat global
Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "Résultat global des tests" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$totalTests = $testFiles.Count
$passedTests = ($results.Values | Where-Object { $_ -eq $true }).Count

foreach ($testFile in $testFiles) {
    $status = if ($results[$testFile]) { "Réussi" } else { "Échoué" }
    $color = if ($results[$testFile]) { "Green" } else { "Red" }
    Write-Host "$testFile : $status" -ForegroundColor $color
}

Write-Host "`nRésultat global : $passedTests / $totalTests" -ForegroundColor Cyan
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont réussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests ont échoué." -ForegroundColor Red
}

# Retourner le code de sortie
if ($passedTests -eq $totalTests) {
    exit 0
} else {
    exit 1
}
