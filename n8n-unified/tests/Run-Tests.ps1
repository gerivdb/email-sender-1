# Vérifier si Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installation du module Pester..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Définir la configuration Pester
$config = New-PesterConfiguration
$config.Run.Path = $PSScriptRoot
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "TestResults.xml"
$config.TestResult.OutputFormat = "NUnitXml"

# Exécuter les tests
Invoke-Pester -Configuration $config
