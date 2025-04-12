<#
.SYNOPSIS
    Exécute les tests du module ProactiveOptimization avec TestOmnibus.
.DESCRIPTION
    Ce script exécute les tests du module ProactiveOptimization en utilisant
    TestOmnibus et l'adaptateur spécifique.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de TestOmnibus.
.PARAMETER GenerateHtmlReport
    Génère un rapport HTML des résultats.
.PARAMETER ShowDetailedResults
    Affiche les résultats détaillés des tests.
.EXAMPLE
    .\Run-ProactiveOptimizationTests.ps1 -GenerateHtmlReport
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath "Config\testomnibus_config.json"),

    [Parameter(Mandatory = $false)]
    [switch]$GenerateHtmlReport,

    [Parameter(Mandatory = $false)]
    [switch]$ShowDetailedResults
)

# Vérifier que le fichier de configuration existe
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Error "Le fichier de configuration n'existe pas: $ConfigPath"
    return 1
}

# Chemin vers TestOmnibus
$testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

if (-not (Test-Path -Path $testOmnibusPath)) {
    Write-Error "TestOmnibus non trouvé: $testOmnibusPath"
    return 1
}

# Exécuter TestOmnibus avec la configuration spécifiée
Write-Host "Exécution des tests ProactiveOptimization avec TestOmnibus..." -ForegroundColor Cyan

# Obtenir le chemin des tests à partir de la configuration
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$testPath = $config.TestModules[0].Path

# Définir l'encodage de la console en UTF-8
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Exécuter TestOmnibus
& $testOmnibusPath -Path $testPath -ConfigPath $ConfigPath

# Vérifier les résultats dans le fichier XML
$resultsPath = Join-Path -Path $config.OutputPath -ChildPath "results.xml"
if (Test-Path -Path $resultsPath) {
    $results = Import-Clixml -Path $resultsPath
    $failedTests = $results | Where-Object { -not $_.Success }

    if ($failedTests.Count -eq 0) {
        Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
        return 0
    } else {
        Write-Host "Des tests ont échoué. Consultez le rapport pour plus de détails." -ForegroundColor Red
        return 1
    }
} else {
    Write-Warning "Fichier de résultats non trouvé: $resultsPath"
    return 1
}
