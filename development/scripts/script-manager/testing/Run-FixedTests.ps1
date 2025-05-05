#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests corrigÃ©s du script manager.
.DESCRIPTION
    Ce script exÃ©cute les tests corrigÃ©s du script manager,
    en utilisant le framework Pester avec des mocks.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER GenerateHTML
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.
.PARAMETER TestName
    Nom du test Ã  exÃ©cuter. Si non spÃ©cifiÃ©, tous les tests sont exÃ©cutÃ©s.
.EXAMPLE
    .\Run-FixedTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
.EXAMPLE
    .\Run-FixedTests.ps1 -TestName "Organization"
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
    [switch]$GenerateHTML,
    
    [Parameter(Mandatory = $false)]
    [string]$TestName
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

# RÃ©cupÃ©rer les fichiers de test
$testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Fixed.Tests.ps1"
if ($TestName) {
    $testFiles = $testFiles | Where-Object { $_.BaseName -like "*$TestName*" }
}

if ($testFiles.Count -eq 0) {
    Write-Log "Aucun fichier de test trouvÃ©." -Level "ERROR"
    exit 1
}

Write-Log "ExÃ©cution de $($testFiles.Count) fichier(s) de test..." -Level "INFO"
foreach ($testFile in $testFiles) {
    Write-Log "  $($testFile.Name)" -Level "INFO"
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $testFiles.FullName
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "FixedTestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

# ExÃ©cuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Log "`nRÃ©sumÃ© des tests:" -Level "INFO"
Write-Log "  Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -Level "INFO"
Write-Log "  Tests rÃ©ussis: $($testResults.PassedCount)" -Level "SUCCESS"
Write-Log "  Tests Ã©chouÃ©s: $($testResults.FailedCount)" -Level $(if ($testResults.FailedCount -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Tests ignorÃ©s: $($testResults.SkippedCount)" -Level "WARNING"
Write-Log "  DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "FixedTestResults.html"
    
    # CrÃ©er un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests corrigÃ©s</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .summary { margin-bottom: 20px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>Rapport de tests corrigÃ©s</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Tests exÃ©cutÃ©s: $($testResults.TotalCount)</p>
        <p class="success">Tests rÃ©ussis: $($testResults.PassedCount)</p>
        <p class="error">Tests Ã©chouÃ©s: $($testResults.FailedCount)</p>
        <p class="warning">Tests ignorÃ©s: $($testResults.SkippedCount)</p>
        <p>DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    
    <p>Pour plus de dÃ©tails, consultez le rapport XML.</p>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $htmlPath" -Level "SUCCESS"
}

# Afficher le chemin du rapport XML
Write-Log "Rapport XML gÃ©nÃ©rÃ©: $($pesterConfig.TestResult.OutputPath)" -Level "SUCCESS"

# Retourner le code de sortie en fonction des rÃ©sultats
if ($testResults.FailedCount -gt 0) {
    Write-Log "Des tests ont Ã©chouÃ©. Veuillez consulter les rapports pour plus de dÃ©tails." -Level "ERROR"
    exit 1
}
else {
    Write-Log "Tous les tests ont rÃ©ussi!" -Level "SUCCESS"
    exit 0
}
