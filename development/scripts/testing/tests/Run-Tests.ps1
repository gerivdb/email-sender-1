<#
.SYNOPSIS
    Installe Pester si nÃ©cessaire et exÃ©cute les tests du projet.
.DESCRIPTION
    Ce script vÃ©rifie si Pester est installÃ©, l'installe si nÃ©cessaire, puis exÃ©cute
    les tests Pester pour vÃ©rifier que les 4 phases du projet ont portÃ© leurs fruits.
.PARAMETER Tags
    Tags des tests Ã  exÃ©cuter (AllPhases, Phase1, Phase2, Phase3, Phase4).
.PARAMETER Output
    Format de sortie des tests (Normal, Detailed, Diagnostic).
.EXAMPLE
    .\Run-Tests.ps1
    ExÃ©cute tous les tests avec la sortie normale.
.EXAMPLE
    .\Run-Tests.ps1 -Tags Phase1,Phase3 -Output Detailed
    ExÃ©cute les tests des phases 1 et 3 avec une sortie dÃ©taillÃ©e.
#>

param (
    [string[]]$Tags = @('AllPhases'),
    [ValidateSet('Default', 'All', 'Fails')]
    [string]$Output = 'Default'
)

# VÃ©rifier si Pester est installÃ©
$PesterModule = Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -ge '5.0.0' }

if (-not $PesterModule) {
    Write-Host "Pester 5.0 ou supÃ©rieur n'est pas installÃ©. Installation en cours..." -ForegroundColor Yellow

    try {
        Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
        Write-Host "Pester a Ã©tÃ© installÃ© avec succÃ¨s." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'installation de Pester: $_" -ForegroundColor Red
        Write-Host "Veuillez installer Pester manuellement avec la commande: Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck" -ForegroundColor Yellow
        exit 1
    }
}

# CrÃ©er le dossier de sortie des tests s'il n'existe pas
$TestOutputPath = Join-Path -Path $PSScriptRoot -ChildPath 'TestOutputs'
if (-not (Test-Path -Path $TestOutputPath)) {
    New-Item -Path $TestOutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de sortie des tests crÃ©Ã©: $TestOutputPath" -ForegroundColor Green
}

# ExÃ©cuter les tests Pester
Write-Host "ExÃ©cution des tests Pester..." -ForegroundColor Cyan

# Utiliser une syntaxe compatible avec les versions antÃ©rieures de Pester
$TestScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'ProjectPhases.Tests.ps1'

$TestResults = Invoke-Pester -Path $TestScriptPath -Tag $Tags -PassThru

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host ""
Write-Host "=== RÃ©sumÃ© des tests ===" -ForegroundColor Cyan
Write-Host "Tests exÃ©cutÃ©s: $($TestResults.TotalCount)" -ForegroundColor White
Write-Host "Tests rÃ©ussis: $($TestResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s: $($TestResults.FailedCount)" -ForegroundColor $(if ($TestResults.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "Tests ignorÃ©s: $($TestResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "DurÃ©e totale: $($TestResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher les tests Ã©chouÃ©s
if ($TestResults.FailedCount -gt 0) {
    Write-Host ""
    Write-Host "=== Tests Ã©chouÃ©s ===" -ForegroundColor Red

    foreach ($Failed in $TestResults.Failed) {
        Write-Host "- $($Failed.Name)" -ForegroundColor Red
        Write-Host "  $($Failed.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
}

# Retourner le rÃ©sultat global
if ($TestResults.FailedCount -eq 0) {
    Write-Host ""
    Write-Host "Tous les tests ont rÃ©ussi! Les 4 phases du projet ont portÃ© leurs fruits." -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "Certains tests ont Ã©chouÃ©. Veuillez vÃ©rifier les rÃ©sultats ci-dessus." -ForegroundColor Red
    exit 1
}
