<#
.SYNOPSIS
    Script pour exécuter les tests d'intégration du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script exécute uniquement les tests d'intégration du système d'apprentissage des erreurs
    en utilisant une approche simplifiée pour éviter les boucles d'erreur infinies.
.EXAMPLE
    .\Run-IntegrationTests.ps1
    Exécute les tests d'intégration.
#>

[CmdletBinding()]
param ()

# Vérifier que Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation du module Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin des tests d'intégration
$testRoot = Join-Path -Path $PSScriptRoot -ChildPath "Tests"
$integrationTestFile = Join-Path -Path $testRoot -ChildPath "ErrorLearningSystem.Integration.Tests.ps1"

# Vérifier que le fichier de test existe
if (-not (Test-Path -Path $integrationTestFile)) {
    Write-Host "Le fichier de test d'intégration n'existe pas: $integrationTestFile" -ForegroundColor Red
    exit 1
}

# Afficher les tests trouvés
Write-Host "Test d'intégration trouvé :" -ForegroundColor Cyan
Write-Host "  ErrorLearningSystem.Integration.Tests.ps1" -ForegroundColor Yellow

# Créer un fichier temporaire pour exécuter les tests
$tempTestFile = Join-Path -Path $env:TEMP -ChildPath "TempIntegrationTest.ps1"

# Lire le contenu du fichier de test
$testContent = Get-Content -Path $integrationTestFile -Raw

# Supprimer les appels à Invoke-Pester
$testContent = $testContent -replace "Invoke-Pester.*", ""

# Ajouter le code pour exécuter les tests
$testContent += @"

# Exécuter les tests
`$pesterConfig = New-PesterConfiguration
`$pesterConfig.Run.Path = `$PSCommandPath
`$pesterConfig.Output.Verbosity = "Detailed"
Invoke-Pester -Configuration `$pesterConfig
"@

# Écrire le contenu dans le fichier temporaire
Set-Content -Path $tempTestFile -Value $testContent

# Exécuter les tests
Write-Host "`nExécution des tests d'intégration..." -ForegroundColor Cyan
try {
    & $tempTestFile
}
catch {
    Write-Host "Erreur lors de l'exécution des tests d'intégration: $_" -ForegroundColor Red
}
finally {
    # Supprimer le fichier temporaire
    if (Test-Path -Path $tempTestFile) {
        Remove-Item -Path $tempTestFile -Force
    }
}
