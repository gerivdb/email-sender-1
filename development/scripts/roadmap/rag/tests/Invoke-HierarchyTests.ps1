# Invoke-HierarchyTests.ps1
# Script pour exécuter les tests d'analyse de hiérarchie et de métadonnées
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Indentation", "Identifiers", "Relations", "InlineMetadata", "MetadataBlocks", "TaskMetadata")]
    [string]$TestType = "All",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateTestFiles
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour créer le répertoire de données de test
function New-TestDataDirectory {
    [CmdletBinding()]
    param ()
    
    $dataDir = Join-Path -Path $scriptPath -ChildPath "data"
    
    if (-not (Test-Path -Path $dataDir)) {
        try {
            New-Item -Path $dataDir -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire de données de test créé : $dataDir" -Level "Success"
        } catch {
            Write-Log "Erreur lors de la création du répertoire de données de test : $_" -Level "Error"
            return $false
        }
    }
    
    $outputDir = Join-Path -Path $dataDir -ChildPath "output"
    
    if (-not (Test-Path -Path $outputDir)) {
        try {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire de sortie créé : $outputDir" -Level "Success"
        } catch {
            Write-Log "Erreur lors de la création du répertoire de sortie : $_" -Level "Error"
            return $false
        }
    }
    
    return $true
}

# Fonction pour exécuter un test spécifique
function Invoke-Test {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateTestFile
    )
    
    $testScriptPath = Join-Path -Path $scriptPath -ChildPath "Test-$TestName.ps1"
    
    if (-not (Test-Path -Path $testScriptPath)) {
        Write-Log "Script de test introuvable : $testScriptPath" -Level "Error"
        return $false
    }
    
    $params = @{}
    
    if ($GenerateReport) {
        $params.GenerateReport = $true
    }
    
    if ($CreateTestFile) {
        # Le script de test créera un fichier de test par défaut
    } else {
        # Utiliser un fichier de test existant si disponible
        $testFilePath = Join-Path -Path $scriptPath -ChildPath "data\$TestName-test.md"
        
        if (Test-Path -Path $testFilePath) {
            $params.TestFilePath = $testFilePath
        } else {
            Write-Log "Fichier de test introuvable : $testFilePath. Un nouveau fichier sera créé." -Level "Warning"
        }
    }
    
    try {
        Write-Log "Exécution du test : $TestName" -Level "Info"
        $result = & $testScriptPath @params
        
        if ($result -eq $true) {
            Write-Log "Test $TestName terminé avec succès." -Level "Success"
            return $true
        } else {
            Write-Log "Test $TestName terminé avec des erreurs." -Level "Error"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exécution du test $TestName : $_" -Level "Error"
        return $false
    }
}

# Fonction pour générer un rapport global
function New-GlobalTestReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$TestResults
    )
    
    $dataDir = Join-Path -Path $scriptPath -ChildPath "data"
    $outputDir = Join-Path -Path $dataDir -ChildPath "output"
    $reportPath = Join-Path -Path $outputDir -ChildPath "hierarchy-test-report.html"
    
    $successCount = ($TestResults.Values | Where-Object { $_ -eq $true } | Measure-Object).Count
    $failureCount = ($TestResults.Values | Where-Object { $_ -eq $false } | Measure-Object).Count
    $totalCount = $TestResults.Count
    $successRate = [Math]::Round(($successCount / $totalCount) * 100, 2)
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de tests - Analyse de hiérarchie et de métadonnées</title>
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
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .progress-bar {
            height: 20px;
            background-color: #e9ecef;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .progress {
            height: 100%;
            border-radius: 5px;
            background-color: #4caf50;
            width: $successRate%;
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
            background-color: #f8f9fa;
        }
        .success {
            color: #4caf50;
        }
        .failure {
            color: #f44336;
        }
        .timestamp {
            color: #7f8c8d;
            font-size: 0.9em;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de tests - Analyse de hiérarchie et de métadonnées</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p>Tests réussis : $successCount / $totalCount ($successRate%)</p>
            <div class="progress-bar">
                <div class="progress"></div>
            </div>
        </div>
        
        <h2>Résultats détaillés</h2>
        <table>
            <thead>
                <tr>
                    <th>Test</th>
                    <th>Résultat</th>
                </tr>
            </thead>
            <tbody>
"@
    
    foreach ($testName in $TestResults.Keys | Sort-Object) {
        $result = $TestResults[$testName]
        $resultText = if ($result) { "Succès" } else { "Échec" }
        $resultClass = if ($result) { "success" } else { "failure" }
        
        $html += @"
                <tr>
                    <td>$testName</td>
                    <td class="$resultClass">$resultText</td>
                </tr>
"@
    }
    
    $html += @"
            </tbody>
        </table>
        
        <h2>Rapports individuels</h2>
        <ul>
"@
    
    foreach ($testName in $TestResults.Keys | Sort-Object) {
        $individualReportPath = Join-Path -Path $outputDir -ChildPath "$testName-report.md"
        
        if (Test-Path -Path $individualReportPath) {
            $html += @"
            <li><a href="$testName-report.md">Rapport détaillé - $testName</a></li>
"@
        }
    }
    
    $html += @"
        </ul>
        
        <p class="timestamp">Rapport généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    </div>
</body>
</html>
"@
    
    $html | Set-Content -Path $reportPath -Encoding UTF8
    Write-Log "Rapport global de tests généré : $reportPath" -Level "Success"
    
    return $reportPath
}

# Fonction principale
function Invoke-HierarchyTests {
    [CmdletBinding()]
    param (
        [string]$TestType,
        [switch]$GenerateReport,
        [switch]$CreateTestFiles
    )
    
    Write-Log "Démarrage des tests d'analyse de hiérarchie et de métadonnées..." -Level "Info"
    
    # Créer le répertoire de données de test si nécessaire
    if (-not (New-TestDataDirectory)) {
        return $false
    }
    
    # Définir les tests à exécuter
    $tests = @()
    
    switch ($TestType) {
        "All" {
            $tests = @(
                "IndentationAnalysis",
                "NumericIdentifiersAnalysis",
                "ContextualRelationsAnalysis",
                "InlineMetadataExtraction",
                "MetadataBlocksExtraction",
                "TaskMetadataInference"
            )
        }
        "Indentation" {
            $tests = @("IndentationAnalysis")
        }
        "Identifiers" {
            $tests = @("NumericIdentifiersAnalysis")
        }
        "Relations" {
            $tests = @("ContextualRelationsAnalysis")
        }
        "InlineMetadata" {
            $tests = @("InlineMetadataExtraction")
        }
        "MetadataBlocks" {
            $tests = @("MetadataBlocksExtraction")
        }
        "TaskMetadata" {
            $tests = @("TaskMetadataInference")
        }
    }
    
    # Exécuter les tests
    $testResults = @{}
    
    foreach ($test in $tests) {
        $testResult = Invoke-Test -TestName $test -GenerateReport:$GenerateReport -CreateTestFile:$CreateTestFiles
        $testResults[$test] = $testResult
    }
    
    # Afficher le résumé des résultats
    $successCount = ($testResults.Values | Where-Object { $_ -eq $true } | Measure-Object).Count
    $failureCount = ($testResults.Values | Where-Object { $_ -eq $false } | Measure-Object).Count
    $totalCount = $testResults.Count
    
    Write-Log "Résumé des tests :" -Level "Info"
    Write-Log "  - Tests réussis : $successCount / $totalCount" -Level "Info"
    Write-Log "  - Tests échoués : $failureCount / $totalCount" -Level "Info"
    
    # Générer un rapport global si demandé
    if ($GenerateReport -and $totalCount -gt 0) {
        $reportPath = New-GlobalTestReport -TestResults $testResults
        Write-Log "Rapport global généré : $reportPath" -Level "Success"
        
        # Ouvrir le rapport dans le navigateur par défaut
        try {
            Start-Process $reportPath
        } catch {
            Write-Log "Impossible d'ouvrir le rapport dans le navigateur : $_" -Level "Warning"
        }
    }
    
    # Retourner le résultat global
    return ($failureCount -eq 0)
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    $result = Invoke-HierarchyTests -TestType $TestType -GenerateReport:$GenerateReport -CreateTestFiles:$CreateTestFiles
    
    if ($result) {
        Write-Log "Tous les tests ont réussi." -Level "Success"
        exit 0
    } else {
        Write-Log "Certains tests ont échoué." -Level "Error"
        exit 1
    }
}
