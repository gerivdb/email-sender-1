# Script pour exÃ©cuter les tests unitaires du module WorkflowAnalyzer
# Ce script exÃ©cute les tests unitaires et gÃ©nÃ¨re un rapport de couverture

#Requires -Version 5.1
#Requires -Modules Pester

# ParamÃ¨tres
param (
    [Parameter(Mandatory = $false)]
    [switch]$GenerateCoverageReport,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "TestResults"
)

# DÃ©finir le chemin complet du dossier de sortie
$OutputFolder = Join-Path -Path $PSScriptRoot -ChildPath $OutputFolder

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Fonction pour afficher un message
function Write-TestMessage {
    param (
        [string]$Message,
        [string]$Status = "INFO"
    )

    $color = switch ($Status) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }

    Write-Host "[$Status] $Message" -ForegroundColor $color
}

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-TestMessage "Le module Pester n'est pas installÃ©. Installation en cours..." -Status "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputFolder -ChildPath "TestResults.xml"

# Configurer la couverture de code si demandÃ©
if ($GenerateCoverageReport) {
    $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "WorkflowAnalyzer.psm1"
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = $modulePath
    $pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputFolder -ChildPath "CodeCoverage.xml"
}

# ExÃ©cuter les tests
Write-TestMessage "ExÃ©cution des tests unitaires..." -Status "INFO"
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher les rÃ©sultats
if ($testResults.FailedCount -eq 0) {
    Write-TestMessage "Tous les tests ont rÃ©ussi! ($($testResults.PassedCount) tests rÃ©ussis)" -Status "SUCCESS"
} else {
    Write-TestMessage "$($testResults.FailedCount) tests ont Ã©chouÃ© sur $($testResults.TotalCount) tests." -Status "ERROR"
}

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateCoverageReport) {
    Write-TestMessage "GÃ©nÃ©ration du rapport de couverture..." -Status "INFO"

    # VÃ©rifier si ReportGenerator est installÃ©
    if (-not (Get-Command -Name ReportGenerator -ErrorAction SilentlyContinue)) {
        Write-TestMessage "ReportGenerator n'est pas installÃ©. Installation en cours..." -Status "WARNING"
        dotnet tool install -g dotnet-reportgenerator-globaltool
    }

    # GÃ©nÃ©rer le rapport HTML
    $coverageXmlPath = Join-Path -Path $OutputFolder -ChildPath "CodeCoverage.xml"
    $coverageHtmlPath = Join-Path -Path $OutputFolder -ChildPath "CoverageReport"

    if (Test-Path -Path $coverageXmlPath) {
        ReportGenerator "-reports:$coverageXmlPath" "-targetdir:$coverageHtmlPath" "-reporttypes:Html"

        if (Test-Path -Path $coverageHtmlPath) {
            Write-TestMessage "Rapport de couverture gÃ©nÃ©rÃ© dans: $coverageHtmlPath" -Status "SUCCESS"

            # Ouvrir le rapport dans le navigateur par dÃ©faut
            Start-Process (Join-Path -Path $coverageHtmlPath -ChildPath "index.htm")
        } else {
            Write-TestMessage "Ã‰chec de la gÃ©nÃ©ration du rapport de couverture" -Status "ERROR"
        }
    } else {
        Write-TestMessage "Fichier de couverture XML non trouvÃ©" -Status "ERROR"
    }
}

# Afficher le chemin du rapport de test
Write-TestMessage "Rapport de test gÃ©nÃ©rÃ© dans: $($pesterConfig.TestResult.OutputPath)" -Status "INFO"
