#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests corrigés du script manager.
.DESCRIPTION
    Ce script exécute les tests corrigés du script manager,
    en utilisant le framework Pester avec des mocks.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER GenerateHTML
    Génère un rapport HTML des résultats des tests.
.PARAMETER TestName
    Nom du test à exécuter. Si non spécifié, tous les tests sont exécutés.
.EXAMPLE
    .\Run-FixedTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
.EXAMPLE
    .\Run-FixedTests.ps1 -TestName "Organization"
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
    [switch]$GenerateHTML,
    
    [Parameter(Mandatory = $false)]
    [string]$TestName
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

# Récupérer les fichiers de test
$testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Fixed.Tests.ps1"
if ($TestName) {
    $testFiles = $testFiles | Where-Object { $_.BaseName -like "*$TestName*" }
}

if ($testFiles.Count -eq 0) {
    Write-Log "Aucun fichier de test trouvé." -Level "ERROR"
    exit 1
}

Write-Log "Exécution de $($testFiles.Count) fichier(s) de test..." -Level "INFO"
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
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "FixedTestResults.html"
    
    # Créer un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests corrigés</title>
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
    <h1>Rapport de tests corrigés</h1>
    <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests exécutés: $($testResults.TotalCount)</p>
        <p class="success">Tests réussis: $($testResults.PassedCount)</p>
        <p class="error">Tests échoués: $($testResults.FailedCount)</p>
        <p class="warning">Tests ignorés: $($testResults.SkippedCount)</p>
        <p>Durée totale: $($testResults.Duration.TotalSeconds) secondes</p>
    </div>
    
    <p>Pour plus de détails, consultez le rapport XML.</p>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
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
