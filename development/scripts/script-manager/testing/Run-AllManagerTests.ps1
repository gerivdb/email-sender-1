#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les tests du script manager.
.DESCRIPTION
    Ce script exÃ©cute tous les tests du script manager, y compris les tests
    originaux et les tests corrigÃ©s, et gÃ©nÃ¨re des rapports dÃ©taillÃ©s.
.PARAMETER OutputPath
    Chemin du dossier pour les rapports de tests.
.PARAMETER TestType
    Type de tests Ã  exÃ©cuter : Original, Fixed, All (par dÃ©faut).
.PARAMETER GenerateHTML
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.
.PARAMETER TestName
    Nom du test Ã  exÃ©cuter. Si non spÃ©cifiÃ©, tous les tests sont exÃ©cutÃ©s.
.PARAMETER SkipDownload
    Ignore le tÃ©lÃ©chargement de ReportUnit.
.EXAMPLE
    .\Run-AllManagerTests.ps1 -OutputPath ".\reports\tests" -GenerateHTML
.EXAMPLE
    .\Run-AllManagerTests.ps1 -TestType Fixed -TestName "Organization"
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
    [ValidateSet("Original", "Fixed", "All")]
    [string]$TestType = "All",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateHTML,
    
    [Parameter(Mandatory = $false)]
    [string]$TestName,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDownload
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

# Fonction pour exÃ©cuter les tests
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
    
    Write-Log "ExÃ©cution de la suite de tests '$TestSuiteName'..." -Level "INFO"
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
    
    # ExÃ©cuter les tests
    $testResults = Invoke-Pester -Configuration $pesterConfig
    
    # Afficher un rÃ©sumÃ© des rÃ©sultats
    Write-Log "`nRÃ©sumÃ© des tests '$TestSuiteName':" -Level "INFO"
    Write-Log "  Tests exÃ©cutÃ©s: $($testResults.TotalCount)" -Level "INFO"
    Write-Log "  Tests rÃ©ussis: $($testResults.PassedCount)" -Level "SUCCESS"
    Write-Log "  Tests Ã©chouÃ©s: $($testResults.FailedCount)" -Level $(if ($testResults.FailedCount -eq 0) { "SUCCESS" } else { "ERROR" })
    Write-Log "  Tests ignorÃ©s: $($testResults.SkippedCount)" -Level "WARNING"
    Write-Log "  DurÃ©e totale: $($testResults.Duration.TotalSeconds) secondes" -Level "INFO"
    
    return $testResults
}

# RÃ©cupÃ©rer les fichiers de test
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

# VÃ©rifier si des fichiers de test ont Ã©tÃ© trouvÃ©s
$totalTestFiles = $originalTestFiles.Count + $fixedTestFiles.Count
if ($totalTestFiles -eq 0) {
    Write-Log "Aucun fichier de test trouvÃ©." -Level "ERROR"
    exit 1
}

Write-Log "ExÃ©cution de $totalTestFiles fichier(s) de test..." -Level "INFO"

# ExÃ©cuter les tests originaux
$originalResults = $null
$originalOutputFile = Join-Path -Path $OutputPath -ChildPath "OriginalTestResults.xml"
if ($originalTestFiles.Count -gt 0) {
    $originalResults = Invoke-TestSuite -TestSuiteName "Tests originaux" -TestFiles $originalTestFiles.FullName -OutputFile $originalOutputFile
}

# ExÃ©cuter les tests corrigÃ©s
$fixedResults = $null
$fixedOutputFile = Join-Path -Path $OutputPath -ChildPath "FixedTestResults.xml"
if ($fixedTestFiles.Count -gt 0) {
    $fixedResults = Invoke-TestSuite -TestSuiteName "Tests corrigÃ©s" -TestFiles $fixedTestFiles.FullName -OutputFile $fixedOutputFile
}

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHTML) {
    $htmlPath = Join-Path -Path $OutputPath -ChildPath "AllTestResults.html"
    
    # CrÃ©er un rapport HTML simple
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
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <div class="summary">
        <h2>RÃ©sumÃ© global</h2>
        <table>
            <tr>
                <th>Suite de tests</th>
                <th>Tests exÃ©cutÃ©s</th>
                <th>Tests rÃ©ussis</th>
                <th>Tests Ã©chouÃ©s</th>
                <th>Tests ignorÃ©s</th>
                <th>DurÃ©e (s)</th>
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
                <td>Tests corrigÃ©s</td>
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
    
    <h2>DÃ©tails des tests</h2>
    <p>Pour plus de dÃ©tails, consultez les rapports XML :</p>
    <ul>
"@

    if ($originalResults) {
        $htmlContent += @"
        <li><a href="OriginalTestResults.xml">RÃ©sultats des tests originaux</a></li>
"@
    }

    if ($fixedResults) {
        $htmlContent += @"
        <li><a href="FixedTestResults.xml">RÃ©sultats des tests corrigÃ©s</a></li>
"@
    }

    $htmlContent += @"
    </ul>
    
    <h2>Recommandations</h2>
    <p>Pour amÃ©liorer les tests unitaires, il est recommandÃ© de :</p>
    <ul>
        <li>Utiliser des mocks pour Ã©viter que les tests ne modifient rÃ©ellement les fichiers</li>
        <li>Isoler les tests pour qu'ils soient indÃ©pendants les uns des autres</li>
        <li>Ajouter des tests pour les nouvelles fonctionnalitÃ©s du script manager</li>
        <li>IntÃ©grer les tests dans le processus de dÃ©veloppement continu</li>
    </ul>
</body>
</html>
"@
    
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    
    Write-Log "Rapport HTML gÃ©nÃ©rÃ©: $htmlPath" -Level "SUCCESS"
}

# TÃ©lÃ©charger et utiliser ReportUnit pour gÃ©nÃ©rer un rapport HTML plus dÃ©taillÃ©
if ($GenerateHTML -and -not $SkipDownload) {
    try {
        $reportUnitPath = Join-Path -Path $OutputPath -ChildPath "ReportUnit.exe"
        
        # TÃ©lÃ©charger ReportUnit s'il n'existe pas
        if (-not (Test-Path -Path $reportUnitPath)) {
            Write-Log "TÃ©lÃ©chargement de ReportUnit..." -Level "INFO"
            $reportUnitUrl = "https://github.com/reportunit/reportunit/releases/download/1.2.1/ReportUnit.exe"
            
            try {
                Invoke-WebRequest -Uri $reportUnitUrl -OutFile $reportUnitPath
                Write-Log "ReportUnit tÃ©lÃ©chargÃ© avec succÃ¨s." -Level "SUCCESS"
            }
            catch {
                Write-Log "Erreur lors du tÃ©lÃ©chargement de ReportUnit: $_" -Level "ERROR"
                Write-Log "Le rapport HTML dÃ©taillÃ© ne sera pas gÃ©nÃ©rÃ©." -Level "WARNING"
            }
        }
        
        # GÃ©nÃ©rer le rapport HTML dÃ©taillÃ© avec ReportUnit
        if (Test-Path -Path $reportUnitPath) {
            Write-Log "GÃ©nÃ©ration du rapport HTML dÃ©taillÃ© avec ReportUnit..." -Level "INFO"
            
            # ExÃ©cuter ReportUnit
            $reportUnitArgs = @($OutputPath, $OutputPath)
            Start-Process -FilePath $reportUnitPath -ArgumentList $reportUnitArgs -NoNewWindow -Wait
            
            Write-Log "Rapport HTML dÃ©taillÃ© gÃ©nÃ©rÃ© avec ReportUnit." -Level "SUCCESS"
        }
    }
    catch {
        Write-Log "Erreur lors de la gÃ©nÃ©ration du rapport HTML dÃ©taillÃ©: $_" -Level "ERROR"
    }
}

# Afficher un rÃ©sumÃ© global
Write-Log "`nRÃ©sumÃ© global des tests:" -Level "INFO"
Write-Log "  Fichiers de test exÃ©cutÃ©s: $totalTestFiles" -Level "INFO"

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

Write-Log "  Tests exÃ©cutÃ©s: $totalTests" -Level "INFO"
Write-Log "  Tests rÃ©ussis: $totalPassed" -Level "SUCCESS"
Write-Log "  Tests Ã©chouÃ©s: $totalFailed" -Level $(if ($totalFailed -eq 0) { "SUCCESS" } else { "ERROR" })
Write-Log "  Tests ignorÃ©s: $totalSkipped" -Level "WARNING"

# Retourner le code de sortie en fonction des rÃ©sultats
if ($totalFailed -gt 0) {
    Write-Log "Des tests ont Ã©chouÃ©. Veuillez consulter les rapports pour plus de dÃ©tails." -Level "ERROR"
    exit 1
}
else {
    Write-Log "Tous les tests ont rÃ©ussi!" -Level "SUCCESS"
    exit 0
}
