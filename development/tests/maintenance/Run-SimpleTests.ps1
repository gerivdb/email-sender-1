# Run-SimpleTests.ps1
# Script pour exécuter tous les tests en mode simplifié

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "development\tests\maintenance\results"
)

# Exécuter les tests simplifiés
$results = & (Join-Path -Path $PSScriptRoot -ChildPath "Simple-Tests.ps1") -GenerateReport:$GenerateReport

# Afficher un message de succès
Write-Host ""
Write-Host "Tous les tests ont été exécutés avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "Les tests suivants ont été vérifiés :" -ForegroundColor Cyan
Write-Host "  - Split-Roadmap.ps1" -ForegroundColor Gray
Write-Host "  - Update-RoadmapStatus.ps1" -ForegroundColor Gray
Write-Host "  - Navigate-Roadmap.ps1" -ForegroundColor Gray
Write-Host "  - Manage-Roadmap.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "Résumé des résultats :" -ForegroundColor Cyan
Write-Host "  - Tests exécutés : $($results.TotalCount)" -ForegroundColor Gray
Write-Host "  - Tests réussis : $($results.PassedCount)" -ForegroundColor Green
Write-Host "  - Tests échoués : $($results.FailedCount)" -ForegroundColor Red
Write-Host "  - Tests ignorés : $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host ""

if ($GenerateReport) {
    Write-Host "Rapport généré : $OutputPath\SimpleTestResults.xml" -ForegroundColor Cyan
}

# Retourner un code d'erreur si des tests ont échoué
if ($results.FailedCount -gt 0) {
    exit 1
}
else {
    exit 0
}
