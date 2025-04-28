<#
.SYNOPSIS
    Script pour exÃ©cuter les tests des scripts de traitement parallÃ¨le.
.DESCRIPTION
    Ce script exÃ©cute les tests des scripts de traitement parallÃ¨le.
.EXAMPLE
    .\Run-ParallelProcessingTests.ps1
    ExÃ©cute les tests des scripts de traitement parallÃ¨le.
#>

[CmdletBinding()]
param ()

# VÃ©rifier la version de PowerShell
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "Les tests de parallÃ©lisation nÃ©cessitent PowerShell 7.0 ou supÃ©rieur. Certains tests seront ignorÃ©s."
}

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin du test des scripts de traitement parallÃ¨le
$testFile = Join-Path -Path $PSScriptRoot -ChildPath "Tests\ParallelProcessing.Tests.ps1"

# Afficher les tests trouvÃ©s
Write-Host "Test des scripts de traitement parallÃ¨le trouvÃ© :" -ForegroundColor Cyan
Write-Host "  ParallelProcessing.Tests.ps1" -ForegroundColor Yellow

# ExÃ©cuter les tests
Write-Host "`nExÃ©cution des tests des scripts de traitement parallÃ¨le..." -ForegroundColor Cyan
$results = Invoke-Pester -Path $testFile -Output Detailed -PassThru

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor Red
Write-Host "  Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host

# Retourner un code de sortie basÃ© sur les rÃ©sultats des tests
exit $results.FailedCount
