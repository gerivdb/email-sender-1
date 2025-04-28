<#
.SYNOPSIS
    ExÃ©cute les tests du module ProactiveOptimization avec TestOmnibus.
.DESCRIPTION
    Ce script exÃ©cute les tests du module ProactiveOptimization en utilisant
    TestOmnibus et l'adaptateur spÃ©cifique.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de TestOmnibus.
.PARAMETER GenerateHtmlReport
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats.
.PARAMETER ShowDetailedResults
    Affiche les rÃ©sultats dÃ©taillÃ©s des tests.
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

# VÃ©rifier que le fichier de configuration existe
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Error "Le fichier de configuration n'existe pas: $ConfigPath"
    return 1
}

# Chemin vers TestOmnibus
$testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

if (-not (Test-Path -Path $testOmnibusPath)) {
    Write-Error "TestOmnibus non trouvÃ©: $testOmnibusPath"
    return 1
}

# ExÃ©cuter TestOmnibus avec la configuration spÃ©cifiÃ©e
Write-Host "ExÃ©cution des tests ProactiveOptimization avec TestOmnibus..." -ForegroundColor Cyan

# Obtenir le chemin des tests Ã  partir de la configuration
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$testPath = $config.TestModules[0].Path

# DÃ©finir l'encodage de la console en UTF-8
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# ExÃ©cuter TestOmnibus
& $testOmnibusPath -Path $testPath -ConfigPath $ConfigPath

# VÃ©rifier les rÃ©sultats dans le fichier XML
$resultsPath = Join-Path -Path $config.OutputPath -ChildPath "results.xml"
if (Test-Path -Path $resultsPath) {
    $results = Import-Clixml -Path $resultsPath
    $failedTests = $results | Where-Object { -not $_.Success }

    if ($failedTests.Count -eq 0) {
        Write-Host "Tous les tests ont rÃ©ussi!" -ForegroundColor Green
        return 0
    } else {
        Write-Host "Des tests ont Ã©chouÃ©. Consultez le rapport pour plus de dÃ©tails." -ForegroundColor Red
        return 1
    }
} else {
    Write-Warning "Fichier de rÃ©sultats non trouvÃ©: $resultsPath"
    return 1
}
