<#
.SYNOPSIS
    Script pour exÃ©cuter les tests d'intÃ©gration du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exÃ©cute uniquement les tests d'intÃ©gration du systÃ¨me d'apprentissage des erreurs
    en utilisant une approche simplifiÃ©e pour Ã©viter les boucles d'erreur infinies.
.EXAMPLE
    .\Run-IntegrationTests.ps1
    ExÃ©cute les tests d'intÃ©gration.
#>

[CmdletBinding()]
param ()

# VÃ©rifier que Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# DÃ©finir le chemin des tests d'intÃ©gration
$testRoot = Join-Path -Path $PSScriptRoot -ChildPath "Tests"
$integrationTestFile = Join-Path -Path $testRoot -ChildPath "ErrorLearningSystem.Integration.Tests.ps1"

# VÃ©rifier que le fichier de test existe
if (-not (Test-Path -Path $integrationTestFile)) {
    Write-Host "Le fichier de test d'intÃ©gration n'existe pas: $integrationTestFile" -ForegroundColor Red
    exit 1
}

# Afficher les tests trouvÃ©s
Write-Host "Test d'intÃ©gration trouvÃ© :" -ForegroundColor Cyan
Write-Host "  ErrorLearningSystem.Integration.Tests.ps1" -ForegroundColor Yellow

# CrÃ©er un fichier temporaire pour exÃ©cuter les tests
$tempTestFile = Join-Path -Path $env:TEMP -ChildPath "TempIntegrationTest.ps1"

# Lire le contenu du fichier de test
$testContent = Get-Content -Path $integrationTestFile -Raw

# Supprimer les appels Ã  Invoke-Pester
$testContent = $testContent -replace "Invoke-Pester.*", ""

# Ajouter le code pour exÃ©cuter les tests
$testContent += @"

# ExÃ©cuter les tests
`$pesterConfig = New-PesterConfiguration
`$pesterConfig.Run.Path = `$PSCommandPath
`$pesterConfig.Output.Verbosity = "Detailed"
Invoke-Pester -Configuration `$pesterConfig
"@

# Ã‰crire le contenu dans le fichier temporaire
Set-Content -Path $tempTestFile -Value $testContent

# ExÃ©cuter les tests
Write-Host "`nExÃ©cution des tests d'intÃ©gration..." -ForegroundColor Cyan
try {
    & $tempTestFile
}
catch {
    Write-Host "Erreur lors de l'exÃ©cution des tests d'intÃ©gration: $_" -ForegroundColor Red
}
finally {
    # Supprimer le fichier temporaire
    if (Test-Path -Path $tempTestFile) {
        Remove-Item -Path $tempTestFile -Force
    }
}
