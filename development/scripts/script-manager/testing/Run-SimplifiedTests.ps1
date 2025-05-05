#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests simplifiÃ©s du script manager.
.DESCRIPTION
    Ce script exÃ©cute les tests simplifiÃ©s du script manager,
    en Ã©vitant les tests qui nÃ©cessitent des modifications.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER GenerateHTML
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.
.EXAMPLE
    .\Run-SimplifiedTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\tests",
    
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

# ExÃ©cuter le test simplifiÃ©
$testPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-ManagerStructureSimple.ps1"
$testParams = @{
    OutputPath = $OutputPath
}

if ($GenerateHTML) {
    $testParams.Add("GenerateHTML", $true)
}

Write-Log "ExÃ©cution des tests simplifiÃ©s..." -Level "INFO"
& $testPath @testParams

# VÃ©rifier le code de sortie
if ($LASTEXITCODE -eq 0) {
    Write-Log "Tous les tests simplifiÃ©s ont rÃ©ussi!" -Level "SUCCESS"
    exit 0
}
else {
    Write-Log "Des tests simplifiÃ©s ont Ã©chouÃ©. Veuillez consulter les rapports pour plus de dÃ©tails." -Level "ERROR"
    exit 1
}
