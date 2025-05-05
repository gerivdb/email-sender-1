#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests unitaires pour les nouveaux formats.
.DESCRIPTION
    Ce script exÃ©cute les tests unitaires pour les formats CSV, YAML et la dÃ©tection d'encodage.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "unit"
$reportDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"

# CrÃ©er le rÃ©pertoire de rapports s'il n'existe pas
if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

# Liste des fichiers de test Ã  exÃ©cuter
$testFiles = @(
    "CsvYamlFormats.Tests.ps1",
    "EncodingDetection.Tests.ps1",
    "FormatConversion.Tests.ps1"
)

# Configuration Pester
$pesterConfig = [PesterConfiguration]::Default
$pesterConfig.Run.Path = $testFiles | ForEach-Object { Join-Path -Path $testDir -ChildPath $_ }
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $reportDir -ChildPath "NewFormatTestResults.xml"
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires pour les nouveaux formats..."
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des tests :"
Write-Host "Total des tests : $($testResults.TotalCount)"
Write-Host "Tests rÃ©ussis : $($testResults.PassedCount)"
Write-Host "Tests Ã©chouÃ©s : $($testResults.FailedCount)"
Write-Host "Tests ignorÃ©s : $($testResults.SkippedCount)"
Write-Host "DurÃ©e totale : $($testResults.Duration.TotalSeconds) secondes"

# Afficher les tests Ã©chouÃ©s
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nTests Ã©chouÃ©s :"
    foreach ($testResult in $testResults.Failed) {
        Write-Host "- $($testResult.Name) : $($testResult.ErrorRecord.Exception.Message)"
    }
}

# Afficher le chemin des rapports
Write-Host "`nRapport gÃ©nÃ©rÃ© :"
Write-Host "- RÃ©sultats des tests : $($pesterConfig.TestResult.OutputPath)"

# Retourner le nombre de tests Ã©chouÃ©s
return $testResults.FailedCount
