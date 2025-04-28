#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests du script manager.
.DESCRIPTION
    Ce script exécute tous les tests du script manager, y compris les tests
    originaux et les tests corrigés, et génère des rapports détaillés.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER TestType
    Type de tests à exécuter : Original, Fixed, All (par défaut).
.PARAMETER GenerateHTML
    Génère un rapport HTML des résultats des tests.
.PARAMETER TestName
    Nom du test à exécuter. Si non spécifié, tous les tests sont exécutés.
.PARAMETER SkipDownload
    Ignore le téléchargement de ReportUnit.
.EXAMPLE
    .\Run-AllManagerTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
.EXAMPLE
    .\Run-AllManagerTests.ps1 -TestType Fixed -TestName "Organization"
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
    [string]$TestName,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDownload
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

# Fonction pour exécuter les tests
function Invoke-TestSuite {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestSuiteName,
        
        [Parameter(Mandatory = $true)]
        [string[]]$TestFiles,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )
    
    Write-Log "Exécution de la suite de tests '$TestSuiteName'..." -Level "INFO"
    Write-Log "Fichiers de test: $($TestFiles.Count)" -Level "INFO"
    foreach ($file in $TestFiles) {
        Write-Log "  $file" -Level "INFO"
    }
    
    # Configuration de Pester
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestFiles
    $pesterConfig.Output.Verbosity = "Detailed"
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = $OutputFile
    $pesterConfig.TestResult.OutputFormat = "NUnitXml"
    
    # Exécuter les tests
    $testResults = Invoke-Pester -Configuration $pesterConfig
    
    # Afficher un résumé des résultats
    Write-Log "`nRésumé des tests '$TestSuiteName':" -Level "INFO"
    Write-Log "  Tests exécutés: $($testResults.TotalCount)" -Level "INFO"
    Write-Log "  Tests réussis: $($testResults.PassedCount)" -Level "SUCCESS"
    Write-Log "  Tests échoués: $($testResults.FailedCount)" -Level $(if ($testResults.FailedCount -eq 0) { "SUCCESS" } else { "ERROR" })
    Write-Log "  Tests ignorés: $($testResults.SkippedCount)" -Level "WARNING"
    Write-Log "  Durée totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"
    
    return $testResults
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

Write-Log "Exécution de $totalTestFiles fichier(s) de test..." -Level "INFO"

# Exécuter les tests originaux
$originalResults = $null
$originalOutputFile = Join-Path -Path $OutputPath -ChildPath "OriginalTestResults.xml"
if ($originalTestFiles.Count -gt 0) {
    $originalResults = Invoke-TestSuite -TestSuiteName "Tests originaux" -TestFiles $originalTestFiles.FullName -OutputFile $originalOutputFile
}

# Exécuter les tests corrigés
$fixedResults = $null
$fixedOutputFile = Join-Path -Path $OutputPath -ChildPath "FixedTestResults.xml"
if ($fixedTestFiles.Count -gt 0) {
    $fixedResults = Invoke-TestSuite -TestSuiteName "Tests corrigés" -TestFiles $fixedTestFiles.FullName -OutputFile $fixedOutputFile
}

# Générer un rapport HTML si demandé
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "AllTestResults.html"
    
    # Créer un rapport HTML simple
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de tests du script manager</title>
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
    </style>
</head>
<body>
    <h1>Rapport de tests du script manager</h1>
    <p>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>Résumé global</h2>
        <table>
            <tr>
                <th>Suite de tests</th>
                <th>Tests exécutés</th>
                <th>Tests réussis</th>
                <th>Tests échoués</th>
                <th>Tests ignorés</th>
                <th>Durée (s)</th>
            </tr>
"@

    if ($originalResults) {
        $htmlContent += @"
            <tr>
                <td>Tests originaux</td>
                <td>$($originalResults.TotalCount)</td>
                <td class="success">$($originalResults.PassedCount)</td>
                <td class="error">$($originalResults.FailedCount)</td>
                <td class="warning">$($originalResults.SkippedCount)</td>
                <td>$($originalResults.Duration.TotalSeconds)</td>
            </tr>
"@
    }

    if ($fixedResults) {
        $htmlContent += @"
            <tr>
                <td>Tests corrigés</td>
                <td>$($fixedResults.TotalCount)</td>
                <td class="success">$($fixedResults.PassedCount)</td>
                <td class="error">$($fixedResults.FailedCount)</td>
                <td class="warning">$($fixedResults.SkippedCount)</td>
                <td>$($fixedResults.Duration.TotalSeconds)</td>
            </tr>
"@
    }

    $totalTests = 0
    $totalPassed = 0
    $totalFailed = 0
    $totalSkipped = 0
    $totalDuration = 0

    if ($originalResults) {
        $totalTests += $originalResults.TotalCount
        $totalPassed += $originalResults.PassedCount
        $totalFailed += $originalResults.FailedCount
        $totalSkipped += $originalResults.SkippedCount
        $totalDuration += $originalResults.Duration.TotalSeconds
    }

    if ($fixedResults) {
        $totalTests += $fixedResults.TotalCount
        $totalPassed += $fixedResults.PassedCount
        $totalFailed += $fixedResults.FailedCount
        $totalSkipped += $fixedResults.SkippedCount
        $totalDuration += $fixedResults.Duration.TotalSeconds
    }

    $htmlContent += @"
            <tr>
                <td><strong>Total</strong></td>
                <td><strong>$totalTests</strong></td>
                <td class="success"><strong>$totalPassed</strong></td>
                <td class="error"><strong>$totalFailed</strong></td>
                <td class="warning"><strong>$totalSkipped</strong></td>
                <td><strong>$totalDuration</strong></td>
            </tr>
        </table>
    </div>
    
    <h2>Détails des tests</h2>
    <p>Pour plus de détails, consultez les rapports XML :</p>
    <ul>
"@

    if ($originalResults) {
        $htmlContent += @"
        <li><a href="OriginalTestResults.xml">Résultats des tests originaux</a></li>
"@
    }

    if ($fixedResults) {
        $htmlContent += @"
        <li><a href="FixedTestResults.xml">Résultats des tests corrigés</a></li>
"@
    }

    $htmlContent += @"
    </ul>
    
    <h2>Recommandations</h2>
    <p>Pour améliorer les tests unitaires, il est recommandé de :</p>
    <ul>
        <li>Utiliser des mocks pour éviter que les tests ne modifient réellement les fichiers</li>
        <li>Isoler les tests pour qu'ils soient indépendants les uns des autres</li>
        <li>Ajouter des tests pour les nouvelles fonctionnalités du script manager</li>
        <li>Intégrer les tests dans le processus de développement continu</li>
    </ul>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML généré: $htmlPath" -Level "SUCCESS"
}

# Télécharger et utiliser ReportUnit pour générer un rapport HTML plus détaillé
if ($GenerateHTML -and -not $SkipDownload) {
    try {
        $reportUnitPath = Join-Path -Path $OutputPath -ChildPath "ReportUnit.exe"
        
        # Télécharger ReportUnit s'il n'existe pas
        if (-not (Test-Path -Path $reportUnitPath)) {
            Write-Log "Téléchargement de ReportUnit..." -Level "INFO"
            $reportUnitUrl = "https://github.com/reportunit/reportunit/releases/download/1.2.1/ReportUnit.exe"
            
            try {
                Invoke-WebRequest -Uri $reportUnitUrl -OutFile $reportUnitPath
                Write-Log "ReportUnit téléchargé avec succès." -Level "SUCCESS"
            }
            catch {
                Write-Log "Erreur lors du téléchargement de ReportUnit: $_" -Level "ERROR"
                Write-Log "Le rapport HTML détaillé ne sera pas généré." -Level "WARNING"
            }
        }
        
        # Générer le rapport HTML détaillé avec ReportUnit
        if (Test-Path -Path $reportUnitPath) {
            Write-Log "Génération du rapport HTML détaillé avec ReportUnit..." -Level "INFO"
            
            # Exécuter ReportUnit
            $reportUnitArgs = @($OutputPath, $OutputPath)
            Start-Process -FilePath $reportUnitPath -ArgumentList $reportUnitArgs -NoNewWindow -Wait
            
            Write-Log "Rapport HTML détaillé généré avec ReportUnit." -Level "SUCCESS"
        }
    }
    catch {
        Write-Log "Erreur lors de la génération du rapport HTML détaillé: $_" -Level "ERROR"
    }
}

# Afficher un résumé global
Write-Log "`nRésumé global des tests:" -Level "INFO"
Write-Log "  Fichiers de test exécutés: $totalTestFiles" -Level "INFO"

$totalTests = 0
$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0

if ($originalResults) {
    $totalTests += $originalResults.TotalCount
    $totalPassed += $originalResults.PassedCount
    $totalFailed += $originalResults.FailedCount
    $totalSkipped += $originalResults.SkippedCount
}

if ($fixedResults) {
    $totalTests += $fixedResults.TotalCount
    $totalPassed += $fixedResults.PassedCount
    $totalFailed += $fixedResults.FailedCount
    $totalSkipped += $fixedResults.SkippedCount
}

Write-Log "  Tests exécutés: $totalTests" -Level "INFO"
Write-Log "  Tests réussis: $totalPassed" -Level "SUCCESS"
Write-Log "  Tests échoués: $totalFailed" -Level $(if ($totalFailed -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Tests ignorés: $totalSkipped" -Level "WARNING"

# Retourner le code de sortie en fonction des résultats
if ($totalFailed -gt 0) {
    Write-Log "Des tests ont échoué. Veuillez consulter les rapports pour plus de détails." -Level "ERROR"
    exit 1
}
else {
    Write-Log "Tous les tests ont réussi!" -Level "SUCCESS"
    exit 0
}
