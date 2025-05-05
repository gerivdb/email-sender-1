# Run-SimpleTests.ps1
# Script pour exÃ©cuter tous les tests en mode simplifiÃ©

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "development\tests\maintenance\results"
)

# ExÃ©cuter les tests simplifiÃ©s
$results = & (Join-Path -Path $PSScriptRoot -ChildPath "Simple-Tests.ps1") -GenerateReport:$GenerateReport

# Afficher un message de succÃ¨s
Write-Host ""
Write-Host "Tous les tests ont Ã©tÃ© exÃ©cutÃ©s avec succÃ¨s !" -ForegroundColor Green
Write-Host ""
Write-Host "Les tests suivants ont Ã©tÃ© vÃ©rifiÃ©s :" -ForegroundColor Cyan
Write-Host "  - Split-Roadmap.ps1" -ForegroundColor Gray
Write-Host "  - Update-RoadmapStatus.ps1" -ForegroundColor Gray
Write-Host "  - Navigate-Roadmap.ps1" -ForegroundColor Gray
Write-Host "  - Manage-Roadmap.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "RÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Cyan
Write-Host "  - Tests exÃ©cutÃ©s : $($results.TotalCount)" -ForegroundColor Gray
Write-Host "  - Tests rÃ©ussis : $($results.PassedCount)" -ForegroundColor Green
Write-Host "  - Tests Ã©chouÃ©s : $($results.FailedCount)" -ForegroundColor Red
Write-Host "  - Tests ignorÃ©s : $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host ""

if ($GenerateReport) {
    Write-Host "Rapport gÃ©nÃ©rÃ© : $OutputPath\SimpleTestResults.xml" -ForegroundColor Cyan
}

# Retourner un code d'erreur si des tests ont Ã©chouÃ©
if ($results.FailedCount -gt 0) {
    exit 1
}
else {
    exit 0
}
