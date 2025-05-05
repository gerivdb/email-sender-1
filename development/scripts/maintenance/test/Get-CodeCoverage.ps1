#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re un rapport de couverture de code pour les scripts de maintenance.
.DESCRIPTION
    Ce script gÃ©nÃ¨re un rapport de couverture de code pour les scripts de maintenance,
    en utilisant le framework Pester.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de couverture.
.PARAMETER GenerateHTML
    GÃ©nÃ¨re un rapport HTML en plus du rapport XML.
.EXAMPLE
    .\Get-CodeCoverage.ps1 -OutputPath ".\reports\coverage" -GenerateHTML
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-10
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\coverage",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML
)

# Fonction pour Ã©crire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Log "Le module Pester n'est pas installÃ©. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie crÃ©Ã©: $OutputPath" -Level "INFO"
}

# RÃ©cupÃ©rer tous les fichiers de test
$testDir = $PSScriptRoot
$testFiles = Get-ChildItem -Path $testDir -Filter "*.Tests.ps1" | Where-Object { $_.Name -ne "Run-AllTests.ps1" -and $_.Name -ne "Get-CodeCoverage.ps1" }

# RÃ©cupÃ©rer tous les scripts Ã  tester
$maintenanceDir = Split-Path -Parent $testDir
$scriptFiles = Get-ChildItem -Path $maintenanceDir -Recurse -Filter "*.ps1" | Where-Object { 
    $_.FullName -notlike "*\test\*" -and 
    $_.Name -ne "Initialize-MaintenanceEnvironment.ps1" -and
    $_.Name -ne "README.md"
}

Write-Log "GÃ©nÃ©ration de la couverture de code pour $($scriptFiles.Count) scripts..." -Level "INFO"

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "CoverageResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = $scriptFiles.FullName
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "Coverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"

# ExÃ©cuter les tests avec couverture de code
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Log "`nRÃ©sumÃ© de la couverture de code:" -Level "INFO"
Write-Log "  Scripts analysÃ©s: $($scriptFiles.Count)" -Level "INFO"
Write-Log "  Lignes analysÃ©es: $($testResults.CodeCoverage.NumberOfCommandsAnalyzed)" -Level "INFO"
Write-Log "  Lignes couvertes: $($testResults.CodeCoverage.NumberOfCommandsExecuted)" -Level "INFO"
Write-Log "  Couverture: $($testResults.CodeCoverage.CoveragePercent)%" -Level $(if ($testResults.CodeCoverage.CoveragePercent -ge 80) { "SUCCESS" } elseif ($testResults.CodeCoverage.CoveragePercent -ge 50) { "WARNING" } else { "ERROR" })

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "Coverage.html"
    
    # VÃ©rifier si ReportGenerator est installÃ©
    $reportGeneratorPath = Join-Path -Path $env:TEMP -ChildPath "ReportGenerator"
    if (-not (Test-Path -Path $reportGeneratorPath)) {
        Write-Log "Installation de ReportGenerator..." -Level "INFO"
        dotnet tool install dotnet-reportgenerator-globaltool --tool-path $reportGeneratorPath
    }
    
    # GÃ©nÃ©rer le rapport HTML
    Write-Log "GÃ©nÃ©ration du rapport HTML..." -Level "INFO"
    $reportGeneratorExe = Join-Path -Path $reportGeneratorPath -ChildPath "reportgenerator.exe"
    & $reportGeneratorExe "-reports:$($pesterConfig.CodeCoverage.OutputPath)" "-targetdir:$OutputPath" "-reporttypes:Html"
    
    Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $htmlPath" -Level "SUCCESS"
}

# Afficher le chemin du rapport XML
Write-Log "Rapport XML gÃ©nÃ©rÃ©: $($pesterConfig.CodeCoverage.OutputPath)" -Level "SUCCESS"

# Retourner le code de sortie en fonction des rÃ©sultats
if ($testResults.CodeCoverage.CoveragePercent -lt 50) {
    Write-Log "La couverture de code est infÃ©rieure Ã  50%. Veuillez amÃ©liorer les tests." -Level "ERROR"
    exit 1
}
else {
    Write-Log "Couverture de code satisfaisante!" -Level "SUCCESS"
    exit 0
}
