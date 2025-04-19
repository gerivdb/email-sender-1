#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests unitaires pour les nouveaux formats.
.DESCRIPTION
    Ce script exécute les tests unitaires pour les formats CSV, YAML et la détection d'encodage.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "unit"
$reportDir = Join-Path -Path $PSScriptRoot -ChildPath "reports"

# Créer le répertoire de rapports s'il n'existe pas
if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

# Liste des fichiers de test à exécuter
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

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour les nouveaux formats..."
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Host "`nRésumé des tests :"
Write-Host "Total des tests : $($testResults.TotalCount)"
Write-Host "Tests réussis : $($testResults.PassedCount)"
Write-Host "Tests échoués : $($testResults.FailedCount)"
Write-Host "Tests ignorés : $($testResults.SkippedCount)"
Write-Host "Durée totale : $($testResults.Duration.TotalSeconds) secondes"

# Afficher les tests échoués
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nTests échoués :"
    foreach ($testResult in $testResults.Failed) {
        Write-Host "- $($testResult.Name) : $($testResult.ErrorRecord.Exception.Message)"
    }
}

# Afficher le chemin des rapports
Write-Host "`nRapport généré :"
Write-Host "- Résultats des tests : $($pesterConfig.TestResult.OutputPath)"

# Retourner le nombre de tests échoués
return $testResults.FailedCount
