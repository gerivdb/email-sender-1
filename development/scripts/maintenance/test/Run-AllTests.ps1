#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests unitaires pour les scripts de maintenance.
.DESCRIPTION
    Ce script exécute tous les tests unitaires pour les scripts de maintenance,
    en utilisant le framework Pester.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de test.
.PARAMETER GenerateHTML
    Génère un rapport HTML en plus du rapport XML.
.EXAMPLE
    .\Run-AllTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-10
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

# Récupérer tous les fichiers de test
$testDir = $PSScriptRoot
$testFiles = Get-ChildItem -Path $testDir -Filter "*.Tests.ps1" | Where-Object { $_.Name -ne "Run-AllTests.ps1" }

Write-Log "Exécution de $($testFiles.Count) fichiers de test..." -Level "INFO"

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# Exécuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Log "`nRésumé des tests:" -Level "INFO"
Write-Log "  Tests exécutés: $($testResults.TotalCount)" -Level "INFO"
Write-Log "  Tests réussis: $($testResults.PassedCount)" -Level "SUCCESS"
Write-Log "  Tests échoués: $($testResults.FailedCount)" -Level $(if ($testResults.FailedCount -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Tests ignorés: $($testResults.SkippedCount)" -Level "WARNING"
Write-Log "  Durée totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"

# Générer un rapport HTML si demandé
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "TestResults.html"
    
    # Vérifier si ReportUnit est installé
    $reportUnitPath = Join-Path -Path $env:TEMP -ChildPath "ReportUnit.exe"
    if (-not (Test-Path -Path $reportUnitPath)) {
        Write-Log "Téléchargement de ReportUnit..." -Level "INFO"
        $reportUnitUrl = "https://github.com/reportunit/reportunit/releases/download/1.2.1/ReportUnit.exe"
        Invoke-WebRequest -Uri $reportUnitUrl -OutFile $reportUnitPath
    }
    
    # Générer le rapport HTML
    Write-Log "Génération du rapport HTML..." -Level "INFO"
    & $reportUnitPath $pesterConfig.TestResult.OutputPath $htmlPath
    
    Write-Log "Rapport HTML généré: $htmlPath" -Level "SUCCESS"
}

# Afficher le chemin du rapport XML
Write-Log "Rapport XML généré: $($pesterConfig.TestResult.OutputPath)" -Level "SUCCESS"

# Retourner le code de sortie en fonction des résultats
if ($testResults.FailedCount -gt 0) {
    Write-Log "Des tests ont échoué. Veuillez consulter les rapports pour plus de détails." -Level "ERROR"
    exit 1
}
else {
    Write-Log "Tous les tests ont réussi!" -Level "SUCCESS"
    exit 0
}
