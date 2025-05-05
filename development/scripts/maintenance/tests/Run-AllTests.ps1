<#
.SYNOPSIS
    ExÃ©cute tous les tests unitaires pour le mode GRAN.

.DESCRIPTION
    Ce script exÃ©cute tous les tests unitaires pour le mode GRAN, y compris les tests
    pour les fonctions d'estimation de temps et de gÃ©nÃ©ration de sous-tÃ¢ches par IA.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-06-02
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installÃ©. Les tests ne seront pas exÃ©cutÃ©s avec le framework Pester."
    exit 1
}

# Chemin vers les tests
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testFiles = @(
    "Test-GetTaskTimeEstimate.ps1",
    "Test-GetAIGeneratedSubTasks.ps1"
)

# ExÃ©cuter les tests
$results = @()
foreach ($testFile in $testFiles) {
    $testPath = Join-Path -Path $scriptPath -ChildPath $testFile
    if (Test-Path -Path $testPath) {
        Write-Host "ExÃ©cution des tests dans $testFile..." -ForegroundColor Cyan
        $result = Invoke-Pester -Script $testPath -PassThru
        $results += $result
    } else {
        Write-Warning "Le fichier de test $testFile est introuvable Ã  l'emplacement : $testPath"
    }
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
$totalTests = ($results | Measure-Object -Property TotalCount -Sum).Sum
$passedTests = ($results | Measure-Object -Property PassedCount -Sum).Sum
$failedTests = ($results | Measure-Object -Property FailedCount -Sum).Sum
$skippedTests = ($results | Measure-Object -Property SkippedCount -Sum).Sum

Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "Total des tests : $totalTests" -ForegroundColor White
Write-Host "Tests rÃ©ussis : $passedTests" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s : $failedTests" -ForegroundColor Red
Write-Host "Tests ignorÃ©s : $skippedTests" -ForegroundColor Yellow

# Retourner un code de sortie en fonction des rÃ©sultats
if ($failedTests -gt 0) {
    Write-Host "`nCertains tests ont Ã©chouÃ©. Veuillez corriger les erreurs avant de continuer." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nTous les tests ont rÃ©ussi !" -ForegroundColor Green
    exit 0
}
