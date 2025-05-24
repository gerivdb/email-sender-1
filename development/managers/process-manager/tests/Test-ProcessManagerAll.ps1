<#
.SYNOPSIS
    Script principal de test pour le Process Manager.

.DESCRIPTION
    Ce script exÃ©cute tous les tests pour le Process Manager et gÃ©nÃ¨re un rapport complet.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER TestType
    Type de tests Ã  exÃ©cuter. Les valeurs possibles sont : All, Unit, Integration, Functional, Performance, Load.
    Par dÃ©faut, exÃ©cute tous les tests.

.PARAMETER SkipCleanup
    Ne supprime pas les fichiers de test aprÃ¨s l'exÃ©cution.

.PARAMETER GenerateReport
    GÃ©nÃ¨re un rapport HTML des rÃ©sultats des tests.

.PARAMETER ReportPath
    Chemin oÃ¹ enregistrer le rapport HTML. Par dÃ©faut, utilise le rÃ©pertoire des tests.

.EXAMPLE
    .\Test-ProcessManagerAll.ps1
    ExÃ©cute tous les tests pour le Process Manager.

.EXAMPLE
    .\Test-ProcessManagerAll.ps1 -TestType Functional -GenerateReport
    ExÃ©cute uniquement les tests fonctionnels et gÃ©nÃ¨re un rapport HTML.

.NOTES
    Auteur: EMAIL_SENDER_1
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Unit", "Integration", "Functional", "Performance", "Load")]
    [string]$TestType = "All",

    [Parameter(Mandatory = $false)]
    [switch]$SkipCleanup,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath
)

# DÃ©finir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$modulesRoot = Join-Path -Path $processManagerRoot -ChildPath "modules"
$scriptsRoot = Join-Path -Path $processManagerRoot -ChildPath "scripts"
$testsRoot = Join-Path -Path $processManagerRoot -ChildPath "tests"
$reportsDir = if ($ReportPath) { $ReportPath } else { Join-Path -Path $testsRoot -ChildPath "reports" }

# DÃ©finir les chemins des scripts de test
$unitTestScripts = @(
    (Join-Path -Path $testsRoot -ChildPath "Test-ManifestParser.ps1"),
    (Join-Path -Path $testsRoot -ChildPath "Test-ValidationService.ps1"),
    (Join-Path -Path $testsRoot -ChildPath "Test-DependencyResolver.ps1"),
    (Join-Path -Path $testsRoot -ChildPath "Test-ProcessManager.ps1")
)
$integrationTestScript = Join-Path -Path $testsRoot -ChildPath "Test-Integration.ps1"
$functionalTestScript = Join-Path -Path $testsRoot -ChildPath "Test-ProcessManagerFunctionality.ps1"
$performanceTestScript = Join-Path -Path $testsRoot -ChildPath "Test-ProcessManagerPerformance.ps1"
$loadTestScript = Join-Path -Path $testsRoot -ChildPath "Test-ProcessManagerLoad.ps1"

# Fonction pour Ã©crire des messages de journal
function Write-TestLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # DÃ©finir la couleur en fonction du niveau
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        "Debug" { "Gray" }
        default { "White" }
    }
    
    # Afficher le message dans la console
    Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour exÃ©cuter un script de test
function Invoke-TestScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    Write-TestLog -Message "ExÃ©cution du script de test : $ScriptPath" -Level Info
    
    try {
        $result = & $ScriptPath @Parameters
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-TestLog -Message "Script de test exÃ©cutÃ© avec succÃ¨s." -Level Success
            return [PSCustomObject]@{
                ScriptPath = $ScriptPath
                Success = $true
                ExitCode = $exitCode
                Result = $result
            }
        } else {
            Write-TestLog -Message "Script de test exÃ©cutÃ© avec des erreurs. Code de sortie : $exitCode" -Level Error
            return [PSCustomObject]@{
                ScriptPath = $ScriptPath
                Success = $false
                ExitCode = $exitCode
                Result = $result
            }
        }
    } catch {
        Write-TestLog -Message "Erreur lors de l'exÃ©cution du script de test : $_" -Level Error
        return [PSCustomObject]@{
            ScriptPath = $ScriptPath
            Success = $false
            ExitCode = -1
            Error = $_.Exception.Message
        }
    }
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-HtmlReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TestResults,

        [Parameter(Mandatory = $true)]
        [string]$ReportPath
    )

    Write-TestLog -Message "GÃ©nÃ©ration du rapport HTML..." -Level Info
    
    # CrÃ©er le rÃ©pertoire du rapport s'il n'existe pas
    $reportDir = Split-Path -Path $ReportPath -Parent
    if (-not (Test-Path -Path $reportDir -PathType Container)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }
    
    # GÃ©nÃ©rer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests du Process Manager</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .success {
            color: #28a745;
        }
        .error {
            color: #dc3545;
        }
        .warning {
            color: #ffc107;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .test-section {
            margin-bottom: 30px;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin-bottom: 20px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport de tests du Process Manager</h1>
        <p>Date du rapport : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        
        <div class="summary">
            <h2>RÃ©sumÃ©</h2>
            <p>Tests exÃ©cutÃ©s : $($TestResults.TotalTests)</p>
            <p>Tests rÃ©ussis : <span class="success">$($TestResults.SuccessfulTests)</span></p>
            <p>Tests Ã©chouÃ©s : <span class="error">$($TestResults.FailedTests)</span></p>
            <p>Taux de rÃ©ussite : <span class="$(if ($TestResults.SuccessRate -ge 90) { "success" } elseif ($TestResults.SuccessRate -ge 70) { "warning" } else { "error" })">$($TestResults.SuccessRate.ToString("F2"))%</span></p>
        </div>
"@

    # Ajouter les sections de test
    if ($TestResults.UnitTests) {
        $htmlContent += @"
        <div class="test-section">
            <h2>Tests unitaires</h2>
            <p>Tests exÃ©cutÃ©s : $($TestResults.UnitTests.Count)</p>
            <p>Tests rÃ©ussis : <span class="success">$($TestResults.UnitTests | Where-Object { $_.Success } | Measure-Object).Count</span></p>
            <p>Tests Ã©chouÃ©s : <span class="error">$($TestResults.UnitTests | Where-Object { -not $_.Success } | Measure-Object).Count</span></p>
            
            <h3>DÃ©tails</h3>
            <table>
                <tr>
                    <th>Module</th>
                    <th>Statut</th>
                    <th>Code de sortie</th>
                </tr>
"@

        foreach ($test in $TestResults.UnitTests) {
            $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($test.ScriptPath)
            $htmlContent += @"
                <tr>
                    <td>$moduleName</td>
                    <td class="$(if ($test.Success) { "success" } else { "error" })">$(if ($test.Success) { "RÃ©ussi" } else { "Ã‰chouÃ©" })</td>
                    <td>$($test.ExitCode)</td>
                </tr>
"@
        }

        $htmlContent += @"
            </table>
        </div>
"@
    }

    if ($TestResults.IntegrationTest) {
        $htmlContent += @"
        <div class="test-section">
            <h2>Test d'intÃ©gration</h2>
            <p>Statut : <span class="$(if ($TestResults.IntegrationTest.Success) { "success" } else { "error" })">$(if ($TestResults.IntegrationTest.Success) { "RÃ©ussi" } else { "Ã‰chouÃ©" })</span></p>
            <p>Code de sortie : $($TestResults.IntegrationTest.ExitCode)</p>
        </div>
"@
    }

    if ($TestResults.FunctionalTest) {
        $htmlContent += @"
        <div class="test-section">
            <h2>Tests fonctionnels</h2>
            <p>Statut : <span class="$(if ($TestResults.FunctionalTest.Success) { "success" } else { "error" })">$(if ($TestResults.FunctionalTest.Success) { "RÃ©ussi" } else { "Ã‰chouÃ©" })</span></p>
            <p>Code de sortie : $($TestResults.FunctionalTest.ExitCode)</p>
        </div>
"@
    }

    if ($TestResults.PerformanceTest) {
        $htmlContent += @"
        <div class="test-section">
            <h2>Tests de performance</h2>
            <p>Statut : <span class="$(if ($TestResults.PerformanceTest.Success) { "success" } else { "error" })">$(if ($TestResults.PerformanceTest.Success) { "RÃ©ussi" } else { "Ã‰chouÃ©" })</span></p>
            
            <h3>RÃ©sultats</h3>
            <div class="chart-container">
                <canvas id="performanceChart"></canvas>
            </div>
            
            <table>
                <tr>
                    <th>OpÃ©ration</th>
                    <th>Temps moyen (ms)</th>
                    <th>Temps min (ms)</th>
                    <th>Temps max (ms)</th>
                    <th>Ã‰cart-type (ms)</th>
                </tr>
"@

        foreach ($result in $TestResults.PerformanceTest.Result) {
            $htmlContent += @"
                <tr>
                    <td>$($result.Name)</td>
                    <td>$($result.AvgExecutionTime.ToString("F2"))</td>
                    <td>$($result.MinExecutionTime.ToString("F2"))</td>
                    <td>$($result.MaxExecutionTime.ToString("F2"))</td>
                    <td>$($result.StdDevExecutionTime.ToString("F2"))</td>
                </tr>
"@
        }

        $htmlContent += @"
            </table>
            
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    const ctx = document.getElementById('performanceChart').getContext('2d');
                    const performanceChart = new Chart(ctx, {
                        type: 'bar',
                        data: {
                            labels: [$(($TestResults.PerformanceTest.Result | ForEach-Object { "'$($_.Name)'" }) -join ', ')],
                            datasets: [{
                                label: 'Temps d\'exÃ©cution moyen (ms)',
                                data: [$(($TestResults.PerformanceTest.Result | ForEach-Object { $_.AvgExecutionTime.ToString("F2") }) -join ', ')],
                                backgroundColor: 'rgba(54, 162, 235, 0.5)',
                                borderColor: 'rgba(54, 162, 235, 1)',
                                borderWidth: 1
                            }]
                        },
                        options: {
                            scales: {
                                y: {
                                    beginAtZero: true,
                                    title: {
                                        display: true,
                                        text: 'Temps (ms)'
                                    }
                                }
                            }
                        }
                    });
                });
            </script>
        </div>
"@
    }

    if ($TestResults.LoadTest) {
        $htmlContent += @"
        <div class="test-section">
            <h2>Tests de charge</h2>
            <p>Statut : <span class="$(if ($TestResults.LoadTest.Success) { "success" } else { "error" })">$(if ($TestResults.LoadTest.Success) { "RÃ©ussi" } else { "Ã‰chouÃ©" })</span></p>
            
            <h3>RÃ©sultats</h3>
            <p>Nombre de gestionnaires : $($TestResults.LoadTest.Result.NumManagers)</p>
            <p>Nombre d'opÃ©rations : $($TestResults.LoadTest.Result.NumOperations)</p>
            <p>OpÃ©rations rÃ©ussies : <span class="success">$($TestResults.LoadTest.Result.SuccessfulOperations)</span></p>
            <p>OpÃ©rations Ã©chouÃ©es : <span class="error">$($TestResults.LoadTest.Result.FailedOperations)</span></p>
            <p>DurÃ©e totale : $($TestResults.LoadTest.Result.TotalDuration.ToString("F2")) secondes</p>
            <p>OpÃ©rations par seconde : $($TestResults.LoadTest.Result.OperationsPerSecond.ToString("F2"))</p>
            <p>Temps d'exÃ©cution moyen : $($TestResults.LoadTest.Result.AvgExecutionTime.ToString("F2")) ms</p>
            <p>Temps d'exÃ©cution min : $($TestResults.LoadTest.Result.MinExecutionTime.ToString("F2")) ms</p>
            <p>Temps d'exÃ©cution max : $($TestResults.LoadTest.Result.MaxExecutionTime.ToString("F2")) ms</p>
            <p>Ã‰cart-type : $($TestResults.LoadTest.Result.StdDevExecutionTime.ToString("F2")) ms</p>
        </div>
"@
    }

    $htmlContent += @"
    </div>
</body>
</html>
"@

    # Enregistrer le rapport HTML
    $htmlContent | Set-Content -Path $ReportPath -Encoding UTF8
    Write-TestLog -Message "Rapport HTML gÃ©nÃ©rÃ© : $ReportPath" -Level Success
}

# VÃ©rifier que le rÃ©pertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-TestLog -Message "Le rÃ©pertoire du projet n'existe pas : $ProjectRoot" -Level Error
    exit 1
}

# VÃ©rifier que le rÃ©pertoire du Process Manager existe
if (-not (Test-Path -Path $processManagerRoot -PathType Container)) {
    Write-TestLog -Message "Le rÃ©pertoire du Process Manager n'existe pas : $processManagerRoot" -Level Error
    exit 1
}

# CrÃ©er le rÃ©pertoire des rapports si nÃ©cessaire
if ($GenerateReport -and -not (Test-Path -Path $reportsDir -PathType Container)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# Initialiser les rÃ©sultats des tests
$testResults = [PSCustomObject]@{
    UnitTests = @()
    IntegrationTest = $null
    FunctionalTest = $null
    PerformanceTest = $null
    LoadTest = $null
    TotalTests = 0
    SuccessfulTests = 0
    FailedTests = 0
    SuccessRate = 0
}

# ExÃ©cuter les tests unitaires
if ($TestType -in @("All", "Unit")) {
    Write-TestLog -Message "ExÃ©cution des tests unitaires..." -Level Info
    
    foreach ($unitTestScript in $unitTestScripts) {
        if (Test-Path -Path $unitTestScript -PathType Leaf) {
            $result = Invoke-TestScript -ScriptPath $unitTestScript
            $testResults.UnitTests += $result
            $testResults.TotalTests++
            
            if ($result.Success) {
                $testResults.SuccessfulTests++
            } else {
                $testResults.FailedTests++
            }
        } else {
            Write-TestLog -Message "Script de test unitaire introuvable : $unitTestScript" -Level Warning
        }
    }
}

# ExÃ©cuter le test d'intÃ©gration
if ($TestType -in @("All", "Integration")) {
    Write-TestLog -Message "ExÃ©cution du test d'intÃ©gration..." -Level Info
    
    if (Test-Path -Path $integrationTestScript -PathType Leaf) {
        $parameters = @{
            ProjectRoot = $ProjectRoot
        }
        
        if ($SkipCleanup) {
            $parameters.SkipCleanup = $true
        }
        
        $result = Invoke-TestScript -ScriptPath $integrationTestScript -Parameters $parameters
        $testResults.IntegrationTest = $result
        $testResults.TotalTests++
        
        if ($result.Success) {
            $testResults.SuccessfulTests++
        } else {
            $testResults.FailedTests++
        }
    } else {
        Write-TestLog -Message "Script de test d'intÃ©gration introuvable : $integrationTestScript" -Level Warning
    }
}

# ExÃ©cuter les tests fonctionnels
if ($TestType -in @("All", "Functional")) {
    Write-TestLog -Message "ExÃ©cution des tests fonctionnels..." -Level Info
    
    if (Test-Path -Path $functionalTestScript -PathType Leaf) {
        $parameters = @{
            ProjectRoot = $ProjectRoot
        }
        
        if ($SkipCleanup) {
            $parameters.SkipCleanup = $true
        }
        
        $result = Invoke-TestScript -ScriptPath $functionalTestScript -Parameters $parameters
        $testResults.FunctionalTest = $result
        $testResults.TotalTests++
        
        if ($result.Success) {
            $testResults.SuccessfulTests++
        } else {
            $testResults.FailedTests++
        }
    } else {
        Write-TestLog -Message "Script de test fonctionnel introuvable : $functionalTestScript" -Level Warning
    }
}

# ExÃ©cuter les tests de performance
if ($TestType -in @("All", "Performance")) {
    Write-TestLog -Message "ExÃ©cution des tests de performance..." -Level Info
    
    if (Test-Path -Path $performanceTestScript -PathType Leaf) {
        $parameters = @{
            ProjectRoot = $ProjectRoot
            Iterations = 5 # RÃ©duire le nombre d'itÃ©rations pour les tests complets
        }
        
        if ($SkipCleanup) {
            $parameters.SkipCleanup = $true
        }
        
        $result = Invoke-TestScript -ScriptPath $performanceTestScript -Parameters $parameters
        $testResults.PerformanceTest = $result
        $testResults.TotalTests++
        
        if ($result.Success) {
            $testResults.SuccessfulTests++
        } else {
            $testResults.FailedTests++
        }
    } else {
        Write-TestLog -Message "Script de test de performance introuvable : $performanceTestScript" -Level Warning
    }
}

# ExÃ©cuter les tests de charge
if ($TestType -in @("All", "Load")) {
    Write-TestLog -Message "ExÃ©cution des tests de charge..." -Level Info
    
    if (Test-Path -Path $loadTestScript -PathType Leaf) {
        $parameters = @{
            ProjectRoot = $ProjectRoot
            NumManagers = 20 # RÃ©duire le nombre de gestionnaires pour les tests complets
            NumOperations = 50 # RÃ©duire le nombre d'opÃ©rations pour les tests complets
        }
        
        if ($SkipCleanup) {
            $parameters.SkipCleanup = $true
        }
        
        $result = Invoke-TestScript -ScriptPath $loadTestScript -Parameters $parameters
        $testResults.LoadTest = $result
        $testResults.TotalTests++
        
        if ($result.Success) {
            $testResults.SuccessfulTests++
        } else {
            $testResults.FailedTests++
        }
    } else {
        Write-TestLog -Message "Script de test de charge introuvable : $loadTestScript" -Level Warning
    }
}

# Calculer le taux de rÃ©ussite
if ($testResults.TotalTests -gt 0) {
    $testResults.SuccessRate = ($testResults.SuccessfulTests / $testResults.TotalTests) * 100
}

# Afficher le rÃ©sumÃ©
Write-TestLog -Message "`nRÃ©sumÃ© des tests :" -Level Info
Write-TestLog -Message "  Tests exÃ©cutÃ©s : $($testResults.TotalTests)" -Level Info
Write-TestLog -Message "  Tests rÃ©ussis  : $($testResults.SuccessfulTests)" -Level Success
Write-TestLog -Message "  Tests Ã©chouÃ©s  : $($testResults.FailedTests)" -Level Error
Write-TestLog -Message "  Taux de rÃ©ussite : $($testResults.SuccessRate.ToString("F2"))%" -Level Info

# GÃ©nÃ©rer le rapport HTML
if ($GenerateReport) {
    $reportFilePath = Join-Path -Path $reportsDir -ChildPath "process-manager-test-report-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').html"
    New-HtmlReport -TestResults $testResults -ReportPath $reportFilePath
}

# Retourner les rÃ©sultats
return $testResults

