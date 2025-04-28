#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests du script manager avec couverture de code.
.DESCRIPTION
    Ce script exécute les tests du script manager et génère un rapport de couverture de code,
    en utilisant le framework Pester.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER TestType
    Type de tests à exécuter : Original, Fixed, All (par défaut).
.PARAMETER GenerateHTML
    Génère un rapport HTML des résultats des tests.
.PARAMETER TestName
    Nom du test à exécuter. Si non spécifié, tous les tests sont exécutés.
.EXAMPLE
    .\Run-TestsWithCoverage.ps1 -OutputPath ".\reports\tests" -GenerateHTML
.EXAMPLE
    .\Run-TestsWithCoverage.ps1 -TestType Fixed -TestName "Organization"
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
    [ValidateSet("Original", "Fixed", "All")]
    [string]$TestType = "All",
    
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
$originalTestFiles = @()
$fixedTestFiles = @()

if ($TestType -eq "Original" -or $TestType -eq "All") {
    $originalTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" | 
                         Where-Object { $_.Name -notlike "*.Fixed.Tests.ps1" }
    
    if ($TestName) {
        $originalTestFiles = $originalTestFiles | Where-Object { $_.BaseName -like "*$TestName*" }
    }
}

if ($TestType -eq "Fixed" -or $TestType -eq "All") {
    $fixedTestFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Fixed.Tests.ps1"
    
    if ($TestName) {
        $fixedTestFiles = $fixedTestFiles | Where-Object { $_.BaseName -like "*$TestName*" }
    }
}

# Vérifier si des fichiers de test ont été trouvés
$totalTestFiles = $originalTestFiles.Count + $fixedTestFiles.Count
if ($totalTestFiles -eq 0) {
    Write-Log "Aucun fichier de test trouvé." -Level "ERROR"
    exit 1
}

Write-Log "Exécution de $totalTestFiles fichier(s) de test avec couverture de code..." -Level "INFO"

# Récupérer les fichiers à tester pour la couverture de code
$scriptsToTest = @(
    "$PSScriptRoot/../organization/Organize-ManagerScripts.ps1",
    "$PSScriptRoot/../analysis/Analyze-Scripts.ps1",
    "$PSScriptRoot/../inventory/Show-ScriptInventory.ps1"
)

# Vérifier si les fichiers à tester existent
$validScriptsToTest = @()
foreach ($script in $scriptsToTest) {
    if (Test-Path -Path $script) {
        $validScriptsToTest += $script
        Write-Log "Fichier à tester trouvé: $script" -Level "INFO"
    }
    else {
        Write-Log "Fichier à tester non trouvé: $script" -Level "WARNING"
    }
}

if ($validScriptsToTest.Count -eq 0) {
    Write-Log "Aucun fichier à tester trouvé pour la couverture de code." -Level "ERROR"
    exit 1
}

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = ($originalTestFiles + $fixedTestFiles).FullName
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $OutputPath -ChildPath "TestResultsWithCoverage.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = $validScriptsToTest
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $OutputPath -ChildPath "CodeCoverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = "JaCoCo"

# Exécuter les tests
$testResults = Invoke-Pester -Configuration $pesterConfig

# Afficher un résumé des résultats
Write-Log "`nRésumé des tests:" -Level "INFO"
Write-Log "  Tests exécutés: $($testResults.TotalCount)" -Level "INFO"
Write-Log "  Tests réussis: $($testResults.PassedCount)" -Level "SUCCESS"
Write-Log "  Tests échoués: $($testResults.FailedCount)" -Level $(if ($testResults.FailedCount -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Tests ignorés: $($testResults.SkippedCount)" -Level "WARNING"
Write-Log "  Durée totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"

# Afficher un résumé de la couverture de code
$codeCoverage = $testResults.CodeCoverage
if ($codeCoverage) {
    $totalCommands = $codeCoverage.NumberOfCommandsAnalyzed
    $coveredCommands = $codeCoverage.NumberOfCommandsExecuted
    $missedCommands = $totalCommands - $coveredCommands
    $coveragePercent = if ($totalCommands -gt 0) { [math]::Round(($coveredCommands / $totalCommands) * 100, 2) } else { 0 }
    
    Write-Log "`nRésumé de la couverture de code:" -Level "INFO"
    Write-Log "  Commandes analysées: $totalCommands" -Level "INFO"
    Write-Log "  Commandes exécutées: $coveredCommands" -Level "SUCCESS"
    Write-Log "  Commandes non exécutées: $missedCommands" -Level "WARNING"
    Write-Log "  Pourcentage de couverture: $coveragePercent%" -Level $(if ($coveragePercent -ge 80) { "SUCCESS" } elseif ($coveragePercent -ge 60) { "WARNING" } else { "ERROR" })
}

# Générer un rapport HTML si demandé
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "TestResultsWithCoverage.html"
    
    # Créer un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests avec couverture de code</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        .summary { margin-bottom: 20px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .progress-bar {
            width: 100%;
            background-color: #f3f3f3;
            border-radius: 4px;
            padding: 3px;
        }
        .progress {
            height: 20px;
            border-radius: 4px;
            text-align: center;
            line-height: 20px;
            color: white;
        }
    </style>
</head>
<body>
    <h1>Rapport de tests avec couverture de code</h1>
    <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé des tests</h2>
        <table>
            <tr>
                <th>Métrique</th>
                <th>Valeur</th>
            </tr>
            <tr>
                <td>Tests exécutés</td>
                <td>$($testResults.TotalCount)</td>
            </tr>
            <tr>
                <td>Tests réussis</td>
                <td class="success">$($testResults.PassedCount)</td>
            </tr>
            <tr>
                <td>Tests échoués</td>
                <td class="error">$($testResults.FailedCount)</td>
            </tr>
            <tr>
                <td>Tests ignorés</td>
                <td class="warning">$($testResults.SkippedCount)</td>
            </tr>
            <tr>
                <td>Durée totale</td>
                <td>$($testResults.Duration.TotalSeconds) secondes</td>
            </tr>
        </table>
    </div>
"@

    if ($codeCoverage) {
        $coverageColor = if ($coveragePercent -ge 80) { "green" } elseif ($coveragePercent -ge 60) { "orange" } else { "red" }
        
        $htmlContent += @"
    <div class="summary">
        <h2>Résumé de la couverture de code</h2>
        <table>
            <tr>
                <th>Métrique</th>
                <th>Valeur</th>
            </tr>
            <tr>
                <td>Commandes analysées</td>
                <td>$totalCommands</td>
            </tr>
            <tr>
                <td>Commandes exécutées</td>
                <td class="success">$coveredCommands</td>
            </tr>
            <tr>
                <td>Commandes non exécutées</td>
                <td class="warning">$missedCommands</td>
            </tr>
            <tr>
                <td>Pourcentage de couverture</td>
                <td>
                    <div class="progress-bar">
                        <div class="progress" style="width: $coveragePercent%; background-color: $coverageColor;">
                            $coveragePercent%
                        </div>
                    </div>
                </td>
            </tr>
        </table>
    </div>
    
    <h2>Détails de la couverture de code</h2>
    <p>Pour plus de détails, consultez le rapport XML de couverture de code.</p>
"@
    }

    $htmlContent += @"
    <h2>Recommandations</h2>
    <p>Pour améliorer la couverture de code, il est recommandé de :</p>
    <ul>
        <li>Ajouter des tests pour les parties du code qui ne sont pas couvertes</li>
        <li>Utiliser des mocks pour tester les fonctions qui interagissent avec des ressources externes</li>
        <li>Tester les cas d'erreur et les cas limites</li>
        <li>Intégrer les tests de couverture de code dans le processus de CI/CD</li>
    </ul>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML généré: $htmlPath" -Level "SUCCESS"
}

# Afficher les chemins des rapports
Write-Log "Rapport XML des tests généré: $($pesterConfig.TestResult.OutputPath)" -Level "SUCCESS"
Write-Log "Rapport XML de couverture de code généré: $($pesterConfig.CodeCoverage.OutputPath)" -Level "SUCCESS"

# Retourner le code de sortie en fonction des résultats
if ($testResults.FailedCount -gt 0) {
    Write-Log "Des tests ont échoué. Veuillez consulter les rapports pour plus de détails." -Level "ERROR"
    exit 1
}
else {
    Write-Log "Tous les tests ont réussi!" -Level "SUCCESS"
    exit 0
}
