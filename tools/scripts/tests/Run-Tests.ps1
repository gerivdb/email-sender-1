<#
.SYNOPSIS
    Installe Pester si nécessaire et exécute les tests du projet.
.DESCRIPTION
    Ce script vérifie si Pester est installé, l'installe si nécessaire, puis exécute
    les tests Pester pour vérifier que les 4 phases du projet ont porté leurs fruits.
.PARAMETER Tags
    Tags des tests à exécuter (AllPhases, Phase1, Phase2, Phase3, Phase4).
.PARAMETER Output
    Format de sortie des tests (Normal, Detailed, Diagnostic).
.EXAMPLE
    .\Run-Tests.ps1
    Exécute tous les tests avec la sortie normale.
.EXAMPLE
    .\Run-Tests.ps1 -Tags Phase1,Phase3 -Output Detailed
    Exécute les tests des phases 1 et 3 avec une sortie détaillée.
#>

param (
    [string[]]$Tags = @('AllPhases'),
    [ValidateSet('Default', 'All', 'Fails')]
    [string]$Output = 'Default'
)

# Vérifier si Pester est installé
$PesterModule = Get-Module -Name Pester -ListAvailable | Where-Object { $_.Version -ge '5.0.0' }

if (-not $PesterModule) {
    Write-Host "Pester 5.0 ou supérieur n'est pas installé. Installation en cours..." -ForegroundColor Yellow

    try {
        Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
        Write-Host "Pester a été installé avec succès." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'installation de Pester: $_" -ForegroundColor Red
        Write-Host "Veuillez installer Pester manuellement avec la commande: Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck" -ForegroundColor Yellow
        exit 1
    }
}

# Créer le dossier de sortie des tests s'il n'existe pas
$TestOutputPath = Join-Path -Path $PSScriptRoot -ChildPath 'TestOutputs'
if (-not (Test-Path -Path $TestOutputPath)) {
    New-Item -Path $TestOutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de sortie des tests créé: $TestOutputPath" -ForegroundColor Green
}

# Exécuter les tests Pester
Write-Host "Exécution des tests Pester..." -ForegroundColor Cyan

# Utiliser une syntaxe compatible avec les versions antérieures de Pester
$TestScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'ProjectPhases.Tests.ps1'

$TestResults = Invoke-Pester -Path $TestScriptPath -Tag $Tags -PassThru

# Afficher un résumé des résultats
Write-Host ""
Write-Host "=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tests exécutés: $($TestResults.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($TestResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($TestResults.FailedCount)" -ForegroundColor $(if ($TestResults.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "Tests ignorés: $($TestResults.SkippedCount)" -ForegroundColor Yellow
Write-Host "Durée totale: $($TestResults.Duration.TotalSeconds) secondes" -ForegroundColor White

# Afficher les tests échoués
if ($TestResults.FailedCount -gt 0) {
    Write-Host ""
    Write-Host "=== Tests échoués ===" -ForegroundColor Red

    foreach ($Failed in $TestResults.Failed) {
        Write-Host "- $($Failed.Name)" -ForegroundColor Red
        Write-Host "  $($Failed.ErrorRecord.Exception.Message)" -ForegroundColor Red
    }
}

# Retourner le résultat global
if ($TestResults.FailedCount -eq 0) {
    Write-Host ""
    Write-Host "Tous les tests ont réussi! Les 4 phases du projet ont porté leurs fruits." -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "Certains tests ont échoué. Veuillez vérifier les résultats ci-dessus." -ForegroundColor Red
    exit 1
}
