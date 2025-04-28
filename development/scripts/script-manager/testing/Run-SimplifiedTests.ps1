#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests simplifiés du script manager.
.DESCRIPTION
    Ce script exécute les tests simplifiés du script manager,
    en évitant les tests qui nécessitent des modifications.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER GenerateHTML
    Génère un rapport HTML des résultats des tests.
.EXAMPLE
    .\Run-SimplifiedTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\reports\tests",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML
)

# Fonction pour écrire dans le journal
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

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Log "Le module Pester n'est pas installé. Installation en cours..." -Level "WARNING"
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Dossier de sortie créé: $OutputPath" -Level "INFO"
}

# Exécuter le test simplifié
$testPath = Join-Path -Path $PSScriptRoot -ChildPath "Test-ManagerStructureSimple.ps1"
$testParams = @{
    OutputPath = $OutputPath
}

if ($GenerateHTML) {
    $testParams.Add("GenerateHTML", $true)
}

Write-Log "Exécution des tests simplifiés..." -Level "INFO"
& $testPath @testParams

# Vérifier le code de sortie
if ($LASTEXITCODE -eq 0) {
    Write-Log "Tous les tests simplifiés ont réussi!" -Level "SUCCESS"
    exit 0
}
else {
    Write-Log "Des tests simplifiés ont échoué. Veuillez consulter les rapports pour plus de détails." -Level "ERROR"
    exit 1
}
