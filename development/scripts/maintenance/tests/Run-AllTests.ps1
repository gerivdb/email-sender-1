<#
.SYNOPSIS
    Exécute tous les tests unitaires pour le mode GRAN.

.DESCRIPTION
    Ce script exécute tous les tests unitaires pour le mode GRAN, y compris les tests
    pour les fonctions d'estimation de temps et de génération de sous-tâches par IA.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-06-02
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne seront pas exécutés avec le framework Pester."
    exit 1
}

# Chemin vers les tests
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testFiles = @(
    "Test-GetTaskTimeEstimate.ps1",
    "Test-GetAIGeneratedSubTasks.ps1"
)

# Exécuter les tests
$results = @()
foreach ($testFile in $testFiles) {
    $testPath = Join-Path -Path $scriptPath -ChildPath $testFile
    if (Test-Path -Path $testPath) {
        Write-Host "Exécution des tests dans $testFile..." -ForegroundColor Cyan
        $result = Invoke-Pester -Script $testPath -PassThru
        $results += $result
    } else {
        Write-Warning "Le fichier de test $testFile est introuvable à l'emplacement : $testPath"
    }
}

# Afficher un résumé des résultats
$totalTests = ($results | Measure-Object -Property TotalCount -Sum).Sum
$passedTests = ($results | Measure-Object -Property PassedCount -Sum).Sum
$failedTests = ($results | Measure-Object -Property FailedCount -Sum).Sum
$skippedTests = ($results | Measure-Object -Property SkippedCount -Sum).Sum

Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "Total des tests : $totalTests" -ForegroundColor White
Write-Host "Tests réussis : $passedTests" -ForegroundColor Green
Write-Host "Tests échoués : $failedTests" -ForegroundColor Red
Write-Host "Tests ignorés : $skippedTests" -ForegroundColor Yellow

# Retourner un code de sortie en fonction des résultats
if ($failedTests -gt 0) {
    Write-Host "`nCertains tests ont échoué. Veuillez corriger les erreurs avant de continuer." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTous les tests ont réussi !" -ForegroundColor Green
    exit 0
}
