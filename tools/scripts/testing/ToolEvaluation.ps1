# Script pour évaluer les outils d'analyse d'erreurs

# Configuration
$EvalConfig = @{
    # Dossier des résultats d'évaluation
    ResultsFolder = Join-Path -Path $env:TEMP -ChildPath "ToolEvaluation"
    
    # Fichier de configuration des métriques
    MetricsFile = Join-Path -Path $env:TEMP -ChildPath "ToolEvaluation\metrics.json"
    
    # Fichier de feedback utilisateur
    FeedbackFile = Join-Path -Path $env:TEMP -ChildPath "ToolEvaluation\feedback.json"
    
    # Dossier des tests automatisés
    TestsFolder = Join-Path -Path $env:TEMP -ChildPath "ToolEvaluation\Tests"
}

# Fonction pour initialiser l'évaluation des outils
function Initialize-ToolEvaluation {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ResultsFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$MetricsFile = "",
        
        [Parameter(Mandatory = $false)]
        [string]$FeedbackFile = "",
        
        [Parameter(Mandatory = $false)]
        [string]$TestsFolder = ""
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($ResultsFolder)) {
        $EvalConfig.ResultsFolder = $ResultsFolder
    }
    
    if (-not [string]::IsNullOrEmpty($MetricsFile)) {
        $EvalConfig.MetricsFile = $MetricsFile
    }
    
    if (-not [string]::IsNullOrEmpty($FeedbackFile)) {
        $EvalConfig.FeedbackFile = $FeedbackFile
    }
    
    if (-not [string]::IsNullOrEmpty($TestsFolder)) {
        $EvalConfig.TestsFolder = $TestsFolder
    }
    
    # Créer les dossiers s'ils n'existent pas
    foreach ($folder in @($EvalConfig.ResultsFolder, $EvalConfig.TestsFolder)) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }
    
    # Créer le fichier de métriques s'il n'existe pas
    if (-not (Test-Path -Path $EvalConfig.MetricsFile)) {
        $defaultMetrics = @{
            Metrics = @(
                @{
                    Name = "Précision"
                    Description = "Pourcentage d'erreurs correctement identifiées"
                    Weight = 0.3
                    Target = 0.9
                },
                @{
                    Name = "Rappel"
                    Description = "Pourcentage d'erreurs détectées parmi toutes les erreurs"
                    Weight = 0.3
                    Target = 0.85
                },
                @{
                    Name = "Temps d'exécution"
                    Description = "Temps moyen d'exécution de l'analyse (en secondes)"
                    Weight = 0.2
                    Target = 5
                    LowerIsBetter = $true
                },
                @{
                    Name = "Pertinence des suggestions"
                    Description = "Évaluation de la pertinence des suggestions (1-5)"
                    Weight = 0.2
                    Target = 4
                }
            )
            LastUpdate = Get-Date -Format "o"
        }
        
        $defaultMetrics | ConvertTo-Json -Depth 5 | Set-Content -Path $EvalConfig.MetricsFile
    }
    
    # Créer le fichier de feedback s'il n'existe pas
    if (-not (Test-Path -Path $EvalConfig.FeedbackFile)) {
        $defaultFeedback = @{
            Feedback = @()
            LastUpdate = Get-Date -Format "o"
        }
        
        $defaultFeedback | ConvertTo-Json -Depth 5 | Set-Content -Path $EvalConfig.FeedbackFile
    }
    
    return $EvalConfig
}

# Fonction pour définir les métriques d'évaluation
function Set-EvaluationMetrics {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics
    )
    
    # Vérifier si le fichier de métriques existe
    if (-not (Test-Path -Path $EvalConfig.MetricsFile)) {
        Initialize-ToolEvaluation
    }
    
    # Mettre à jour les métriques
    $metricsData = @{
        Metrics = $Metrics
        LastUpdate = Get-Date -Format "o"
    }
    
    $metricsData | ConvertTo-Json -Depth 5 | Set-Content -Path $EvalConfig.MetricsFile
    
    return $metricsData
}

# Fonction pour ajouter un feedback utilisateur
function Add-UserFeedback {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        
        [Parameter(Mandatory = $true)]
        [int]$Rating,
        
        [Parameter(Mandatory = $false)]
        [string]$Comments = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$MetricScores = @{}
    )
    
    # Vérifier si le fichier de feedback existe
    if (-not (Test-Path -Path $EvalConfig.FeedbackFile)) {
        Initialize-ToolEvaluation
    }
    
    # Charger les données de feedback
    $feedbackData = Get-Content -Path $EvalConfig.FeedbackFile -Raw | ConvertFrom-Json
    
    # Créer le feedback
    $feedback = @{
        ID = [Guid]::NewGuid().ToString()
        ToolName = $ToolName
        UserName = $UserName
        Rating = $Rating
        Comments = $Comments
        MetricScores = $MetricScores
        Timestamp = Get-Date -Format "o"
    }
    
    # Ajouter le feedback
    $feedbackData.Feedback += $feedback
    $feedbackData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les données
    $feedbackData | ConvertTo-Json -Depth 5 | Set-Content -Path $EvalConfig.FeedbackFile
    
    return $feedback
}

# Fonction pour créer un test automatisé
function New-AutomatedTest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,
        
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ExpectedResults = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $null
    }
    
    # Créer le dossier de test
    $testFolder = Join-Path -Path $EvalConfig.TestsFolder -ChildPath $TestName
    if (-not (Test-Path -Path $testFolder)) {
        New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
    }
    
    # Créer le fichier de configuration du test
    $testConfig = @{
        TestName = $TestName
        ToolName = $ToolName
        ScriptPath = $ScriptPath
        Parameters = $Parameters
        ExpectedResults = $ExpectedResults
        Description = $Description
        CreatedAt = Get-Date -Format "o"
        LastRun = $null
        Results = @()
    }
    
    $configPath = Join-Path -Path $testFolder -ChildPath "config.json"
    $testConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath
    
    # Créer le script de test
    $testScriptContent = @"
# Script de test automatisé pour $ToolName
# Test: $TestName
# Créé le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Charger la configuration du test
`$configPath = Join-Path -Path `$PSScriptRoot -ChildPath "config.json"
`$config = Get-Content -Path `$configPath -Raw | ConvertFrom-Json

# Vérifier si le script à tester existe
if (-not (Test-Path -Path `$config.ScriptPath)) {
    Write-Error "Le script à tester n'existe pas: `$(`$config.ScriptPath)"
    exit 1
}

# Préparer les paramètres
`$parameters = @{}
foreach (`$param in `$config.Parameters.PSObject.Properties) {
    `$parameters[`$param.Name] = `$param.Value
}

# Exécuter le script
`$startTime = Get-Date
try {
    # Charger le script
    . `$config.ScriptPath
    
    # Exécuter la fonction principale avec les paramètres
    `$scriptName = [System.IO.Path]::GetFileNameWithoutExtension(`$config.ScriptPath)
    `$mainFunction = Get-Command -Name `$scriptName -ErrorAction SilentlyContinue
    
    if (`$mainFunction) {
        `$result = & `$mainFunction @parameters
    }
    else {
        # Essayer d'exécuter le script directement
        `$result = & `$config.ScriptPath @parameters
    }
    
    `$success = `$true
    `$error = `$null
}
catch {
    `$success = `$false
    `$error = `$_.ToString()
    `$result = `$null
}
`$endTime = Get-Date
`$executionTime = (`$endTime - `$startTime).TotalSeconds

# Vérifier les résultats
`$validationResults = @{}
foreach (`$expected in `$config.ExpectedResults.PSObject.Properties) {
    `$expectedValue = `$expected.Value
    `$actualValue = if (`$result -and `$result.PSObject.Properties[`$expected.Name]) {
        `$result.(`$expected.Name)
    }
    else {
        `$null
    }
    
    `$isValid = `$expectedValue -eq `$actualValue
    `$validationResults[`$expected.Name] = @{
        Expected = `$expectedValue
        Actual = `$actualValue
        IsValid = `$isValid
    }
}

# Préparer les résultats du test
`$testResult = @{
    TestName = `$config.TestName
    ToolName = `$config.ToolName
    Timestamp = Get-Date -Format "o"
    Success = `$success
    Error = `$error
    ExecutionTime = `$executionTime
    ValidationResults = `$validationResults
}

# Enregistrer les résultats
`$resultsPath = Join-Path -Path `$PSScriptRoot -ChildPath "results.json"
`$testResult | ConvertTo-Json -Depth 5 | Set-Content -Path `$resultsPath

# Mettre à jour la configuration
`$config.LastRun = Get-Date -Format "o"
`$config.Results += `$testResult
`$config | ConvertTo-Json -Depth 5 | Set-Content -Path `$configPath

# Afficher les résultats
Write-Host "Test terminé: `$(`$config.TestName)"
Write-Host "Succès: `$(`$success)"
if (-not `$success) {
    Write-Host "Erreur: `$error"
}
Write-Host "Temps d'exécution: `$executionTime secondes"
Write-Host "Résultats de validation:"
foreach (`$key in `$validationResults.Keys) {
    `$valid = if (`$validationResults[`$key].IsValid) { "Valide" } else { "Invalide" }
    Write-Host "  `$key: `$valid (Attendu: `$(`$validationResults[`$key].Expected), Obtenu: `$(`$validationResults[`$key].Actual))"
}
"@
    
    $testScriptPath = Join-Path -Path $testFolder -ChildPath "run-test.ps1"
    $testScriptContent | Set-Content -Path $testScriptPath -Encoding UTF8
    
    return @{
        TestName = $TestName
        ConfigPath = $configPath
        ScriptPath = $testScriptPath
    }
}

# Fonction pour exécuter un test automatisé
function Invoke-AutomatedTest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName
    )
    
    # Vérifier si le test existe
    $testFolder = Join-Path -Path $EvalConfig.TestsFolder -ChildPath $TestName
    $testScriptPath = Join-Path -Path $testFolder -ChildPath "run-test.ps1"
    
    if (-not (Test-Path -Path $testScriptPath)) {
        Write-Error "Le test n'existe pas: $TestName"
        return $null
    }
    
    # Exécuter le test
    try {
        & $testScriptPath
        
        # Charger les résultats
        $resultsPath = Join-Path -Path $testFolder -ChildPath "results.json"
        if (Test-Path -Path $resultsPath) {
            $results = Get-Content -Path $resultsPath -Raw | ConvertFrom-Json
            return $results
        }
        else {
            Write-Warning "Aucun résultat trouvé pour le test: $TestName"
            return $null
        }
    }
    catch {
        Write-Error "Erreur lors de l'exécution du test: $_"
        return $null
    }
}

# Fonction pour exécuter tous les tests automatisés
function Invoke-AllAutomatedTests {
    # Obtenir tous les tests
    $testFolders = Get-ChildItem -Path $EvalConfig.TestsFolder -Directory
    
    $results = @()
    
    foreach ($testFolder in $testFolders) {
        $testName = $testFolder.Name
        $testResult = Invoke-AutomatedTest -TestName $testName
        
        if ($testResult) {
            $results += $testResult
        }
    }
    
    # Générer un rapport de résultats
    $reportPath = Join-Path -Path $EvalConfig.ResultsFolder -ChildPath "test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $reportData = @{
        Timestamp = Get-Date -Format "o"
        TestCount = $results.Count
        SuccessCount = ($results | Where-Object { $_.Success } | Measure-Object).Count
        FailureCount = ($results | Where-Object { -not $_.Success } | Measure-Object).Count
        AverageExecutionTime = ($results | Measure-Object -Property ExecutionTime -Average).Average
        Results = $results
    }
    
    $reportData | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath
    
    return $reportData
}

# Fonction pour évaluer un outil d'analyse
function Measure-AnalysisTool {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToolName,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$TestDataPath = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$MetricOverrides = @{}
    )
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $null
    }
    
    # Charger les métriques
    $metricsData = Get-Content -Path $EvalConfig.MetricsFile -Raw | ConvertFrom-Json
    
    # Préparer les résultats
    $results = @{
        ToolName = $ToolName
        ScriptPath = $ScriptPath
        Timestamp = Get-Date -Format "o"
        Metrics = @{}
        OverallScore = 0
        ExecutionTime = 0
        Success = $false
        Error = $null
    }
    
    # Exécuter l'outil
    $startTime = Get-Date
    try {
        # Charger le script
        . $ScriptPath
        
        # Exécuter la fonction principale avec les paramètres
        $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)
        $mainFunction = Get-Command -Name $scriptName -ErrorAction SilentlyContinue
        
        if ($mainFunction) {
            $toolResult = & $mainFunction @Parameters
        }
        else {
            # Essayer d'exécuter le script directement
            $toolResult = & $ScriptPath @Parameters
        }
        
        $results.Success = $true
    }
    catch {
        $results.Success = $false
        $results.Error = $_.ToString()
    }
    $endTime = Get-Date
    $results.ExecutionTime = ($endTime - $startTime).TotalSeconds
    
    # Évaluer les métriques
    $totalWeight = 0
    $weightedScore = 0
    
    foreach ($metric in $metricsData.Metrics) {
        $metricName = $metric.Name
        $metricWeight = $metric.Weight
        $metricTarget = $metric.Target
        $lowerIsBetter = if ($metric.PSObject.Properties["LowerIsBetter"]) { $metric.LowerIsBetter } else { $false }
        
        # Obtenir la valeur de la métrique
        $metricValue = if ($MetricOverrides.ContainsKey($metricName)) {
            $MetricOverrides[$metricName]
        }
        elseif ($metricName -eq "Temps d'exécution") {
            $results.ExecutionTime
        }
        else {
            # Valeur par défaut
            0
        }
        
        # Calculer le score
        $score = if ($lowerIsBetter) {
            if ($metricValue -le $metricTarget) { 1 } else { $metricTarget / $metricValue }
        }
        else {
            if ($metricTarget -eq 0) { 0 } else { $metricValue / $metricTarget }
        }
        
        # Limiter le score à 1
        $score = [Math]::Min(1, $score)
        
        # Ajouter la métrique aux résultats
        $results.Metrics[$metricName] = @{
            Value = $metricValue
            Target = $metricTarget
            Score = $score
            Weight = $metricWeight
            LowerIsBetter = $lowerIsBetter
        }
        
        # Mettre à jour le score global
        $totalWeight += $metricWeight
        $weightedScore += $score * $metricWeight
    }
    
    # Calculer le score global
    if ($totalWeight -gt 0) {
        $results.OverallScore = $weightedScore / $totalWeight
    }
    
    # Enregistrer les résultats
    $resultsPath = Join-Path -Path $EvalConfig.ResultsFolder -ChildPath "$ToolName-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $results | ConvertTo-Json -Depth 5 | Set-Content -Path $resultsPath
    
    return $results
}

# Fonction pour générer un rapport d'évaluation
function New-EvaluationReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport d'évaluation des outils d'analyse",
        
        [Parameter(Mandatory = $false)]
        [string]$ToolName = "",
        
        [Parameter(Mandatory = $false)]
        [int]$Days = 30,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Obtenir les résultats d'évaluation
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $resultFiles = Get-ChildItem -Path $EvalConfig.ResultsFolder -Filter "*.json" | Where-Object {
        $_.LastWriteTime -ge $cutoffDate -and
        ($ToolName -eq "" -or $_.Name -like "$ToolName-*")
    }
    
    $results = @()
    foreach ($file in $resultFiles) {
        $result = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        $results += $result
    }
    
    # Obtenir les feedbacks
    $feedbackData = Get-Content -Path $EvalConfig.FeedbackFile -Raw | ConvertFrom-Json
    $feedbacks = $feedbackData.Feedback | Where-Object {
        [DateTime]::Parse($_.Timestamp) -ge $cutoffDate -and
        ($ToolName -eq "" -or $_.ToolName -eq $ToolName)
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "EvaluationReport-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .summary {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .summary-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            flex: 1;
            min-width: 200px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .summary-card h3 {
            margin-top: 0;
            margin-bottom: 10px;
            font-size: 16px;
        }
        
        .summary-value {
            font-size: 24px;
            font-weight: bold;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #4caf50;
            color: white;
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .score-good {
            color: #4caf50;
            font-weight: bold;
        }
        
        .score-medium {
            color: #ff9800;
            font-weight: bold;
        }
        
        .score-bad {
            color: #f44336;
            font-weight: bold;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Outils évalués</h3>
                <div class="summary-value">$($results.Count)</div>
            </div>
            
            <div class="summary-card">
                <h3>Score moyen</h3>
                <div class="summary-value">$(if ($results.Count -gt 0) { [Math]::Round(($results | Measure-Object -Property OverallScore -Average).Average * 100, 1) } else { 0 })%</div>
            </div>
            
            <div class="summary-card">
                <h3>Feedbacks utilisateurs</h3>
                <div class="summary-value">$($feedbacks.Count)</div>
            </div>
            
            <div class="summary-card">
                <h3>Note moyenne</h3>
                <div class="summary-value">$(if ($feedbacks.Count -gt 0) { [Math]::Round(($feedbacks | Measure-Object -Property Rating -Average).Average, 1) } else { 0 })/5</div>
            </div>
        </div>
        
        <h2>Résultats d'évaluation</h2>
        
        <table>
            <thead>
                <tr>
                    <th>Outil</th>
                    <th>Date</th>
                    <th>Score global</th>
                    <th>Temps d'exécution</th>
                    <th>Statut</th>
                </tr>
            </thead>
            <tbody>
                $(foreach ($result in ($results | Sort-Object -Property Timestamp -Descending)) {
                    $timestamp = [DateTime]::Parse($result.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
                    $score = [Math]::Round($result.OverallScore * 100, 1)
                    $scoreClass = if ($score -ge 80) { "score-good" } elseif ($score -ge 60) { "score-medium" } else { "score-bad" }
                    $status = if ($result.Success) { "Succès" } else { "Échec" }
                    $statusClass = if ($result.Success) { "score-good" } else { "score-bad" }
                    
                    "<tr>
                        <td>$($result.ToolName)</td>
                        <td>$timestamp</td>
                        <td class='$scoreClass'>$score%</td>
                        <td>$([Math]::Round($result.ExecutionTime, 2)) s</td>
                        <td class='$statusClass'>$status</td>
                    </tr>"
                })
            </tbody>
        </table>
        
        <h2>Feedback utilisateur</h2>
        
        <table>
            <thead>
                <tr>
                    <th>Outil</th>
                    <th>Utilisateur</th>
                    <th>Note</th>
                    <th>Date</th>
                    <th>Commentaires</th>
                </tr>
            </thead>
            <tbody>
                $(foreach ($feedback in ($feedbacks | Sort-Object -Property Timestamp -Descending)) {
                    $timestamp = [DateTime]::Parse($feedback.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
                    $ratingClass = if ($feedback.Rating -ge 4) { "score-good" } elseif ($feedback.Rating -ge 3) { "score-medium" } else { "score-bad" }
                    
                    "<tr>
                        <td>$($feedback.ToolName)</td>
                        <td>$($feedback.UserName)</td>
                        <td class='$ratingClass'>$($feedback.Rating)/5</td>
                        <td>$timestamp</td>
                        <td>$($feedback.Comments)</td>
                    </tr>"
                })
            </tbody>
        </table>
        
        <div class="footer">
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Période: $Days jours</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ToolEvaluation, Set-EvaluationMetrics, Add-UserFeedback
Export-ModuleMember -Function New-AutomatedTest, Invoke-AutomatedTest, Invoke-AllAutomatedTests
Export-ModuleMember -Function Measure-AnalysisTool, New-EvaluationReport
