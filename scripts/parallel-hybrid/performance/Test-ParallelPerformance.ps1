#Requires -Version 5.1
<#
.SYNOPSIS
    Mesure de manière fiable les performances d'un bloc de script PowerShell sur plusieurs itérations.
.DESCRIPTION
    Ce script exécute un bloc de script PowerShell spécifié (`ScriptBlock`) un nombre défini de fois (`Iterations`).
    Pour chaque itération, il mesure précisément le temps d'exécution, le temps CPU consommé, et l'utilisation
    de la mémoire (Working Set et Private Memory, y compris les deltas).
    Il collecte ces métriques, calcule des statistiques agrégées (moyenne, min, max, total, taux de succès),
    et génère un rapport JSON détaillé dans un sous-répertoire unique. Un rapport HTML visuel peut également
    être généré optionnellement. Le script inclut une gestion robuste des données de test et un nettoyage mémoire
    configurable entre les itérations pour améliorer la cohérence des mesures.
.PARAMETER ScriptBlock
    Le bloc de script PowerShell dont les performances doivent être mesurées.
    Ce bloc sera exécuté pour chaque itération. Il est recommandé d'utiliser le splatting
    si le script cible prend des paramètres : { & ".\monScript.ps1" @Parameters }
.PARAMETER Parameters
    Table de hachage contenant les paramètres à passer directement au ScriptBlock via splatting (`@Parameters`).
    Ces paramètres sont constants pour toutes les itérations.
.PARAMETER TestName
    Nom unique et descriptif pour cette session de test de performance. Utilisé pour nommer
    les fichiers de sortie, le sous-répertoire des résultats et dans les rapports.
.PARAMETER OutputPath
    Chemin du répertoire racine où les résultats seront enregistrés. Un sous-répertoire
    unique (basé sur TestName + Timestamp) sera créé dans ce chemin pour cette exécution.
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un répertoire contenant des données de test pré-existantes nécessaires
    au ScriptBlock. Si fourni et valide, il est enregistré et son utilisation dépend du ScriptBlock/Parameters.
    Si non fourni, le script peut tenter d'utiliser 'New-TestData.ps1' s'il existe.
.PARAMETER Iterations
    Nombre d'exécutions complètes du ScriptBlock à effectuer pour la mesure.
    Un nombre plus élevé donne des statistiques plus fiables mais prend plus de temps. Défaut: 5.
.PARAMETER GenerateReport
    Si spécifié ($true), génère un rapport HTML détaillé en plus du fichier JSON.
    Ce rapport inclut le contexte, des tableaux récapitulatifs, les détails de chaque itération et des graphiques.
.PARAMETER ForceTestDataGeneration
    [Optionnel] Si la génération de données de test via 'New-TestData.ps1' est déclenchée,
    ce switch force la suppression et la recréation des données même si elles existent déjà.
.PARAMETER NoGarbageCollection
    [Optionnel] Si spécifié ($true), désactive l'appel explicite à [System.GC]::Collect()
    avant chaque itération. Peut rendre les mesures plus proches des conditions réelles mais potentiellement
    moins cohérentes d'une itération à l'autre.
.EXAMPLE
    # Test simple d'une commande intégrée, 10 itérations, avec rapport HTML
    .\Test-ParallelPerformance.ps1 -ScriptBlock { Get-Process | Out-Null } `
        -TestName "GetProcess_Performance" `
        -OutputPath "C:\Temp\PerfResults" `
        -Iterations 10 `
        -GenerateReport

.EXAMPLE
    # Test d'un script externe avec paramètres et données de test existantes
    $scriptToTestPath = ".\scripts\analysis\Analyze-DataFiles.ps1"
    $analysisParams = @{
        SourcePath = "C:\InputData" # Ce chemin doit être utilisé par le script testé
        Threshold = 5
    }
    .\Test-ParallelPerformance.ps1 -ScriptBlock { & $scriptToTestPath @Parameters } `
        -Parameters $analysisParams `
        -TestName "DataAnalysis_WithCache" `
        -OutputPath "C:\Temp\PerfResults\Analysis" `
        -TestDataPath "C:\InputData" ` # Chemin informatif, Analyze-DataFiles.ps1 doit l'utiliser via $analysisParams.SourcePath
        -Iterations 5 `
        -GenerateReport -Verbose

.EXAMPLE
    # Test avec génération automatique de données et sans GC forcé
    $scriptToTestPath = ".\scripts\processing\Process-Items.ps1"
    # Suppose que Process-Items.ps1 utilise un paramètre InputDirectory pointant vers les données générées
    $processingParams = @{ MaxItems = 1000; InputDirectory = $null } # InputDirectory sera mis à jour si génération OK
    .\Test-ParallelPerformance.ps1 -ScriptBlock { & $scriptToTestPath @Parameters } `
        -Parameters $processingParams `
        -TestName "ItemProcessing_AutoData_NoGC" `
        -OutputPath "C:\Temp\PerfResults\Processing" `
        -Iterations 3 `
        -GenerateReport `
        -ForceTestDataGeneration `
        -NoGarbageCollection

.NOTES
    Auteur     : Votre Nom/Équipe
    Version    : 2.1
    Date       : 2023-10-27
    Dépendances: Chart.js (via CDN pour le rapport HTML)
                 New-TestData.ps1 (optionnel, pour la génération de données de test)

    Structure de Sortie:
    Un sous-répertoire unique sera créé dans OutputPath: `Benchmark_[TestName]_[Timestamp]`
    Ce répertoire contiendra :
      - `Benchmark_Results_[TestName].json`: Les données brutes et le résumé.
      - `Benchmark_Report_[TestName].html`: Le rapport HTML (si -GenerateReport).
      - `generated_test_data/`: Le dossier des données de test (si génération automatique).

    Mesures de Mémoire:
    - Working Set (WS): Mémoire physique totale utilisée par le processus.
    - Private Memory (PM): Mémoire non partagée allouée au processus (souvent plus pertinent).
    - Delta WS/PM: Changement de mémoire *pendant* l'exécution de l'itération.

    Garbage Collection: L'option -NoGarbageCollection permet de tester sans l'influence du GC forcé.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Bloc de script PowerShell à mesurer.")]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory = $false, HelpMessage = "Table de hachage des paramètres constants pour le ScriptBlock.")]
    [hashtable]$Parameters = @{},

    [Parameter(Mandatory = $true, HelpMessage = "Nom unique et descriptif pour ce test (utilisé pour le dossier/fichiers de sortie).")]
    [ValidateNotNullOrEmpty()]
    [string]$TestName,

    [Parameter(Mandatory = $true, HelpMessage = "Répertoire racine où le sous-dossier des résultats sera créé.")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "[Optionnel] Chemin vers les données de test pré-existantes (informatif, le ScriptBlock doit l'utiliser).")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Nombre d'exécutions du ScriptBlock à mesurer.")]
    [ValidateRange(1, 1000)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false, HelpMessage = "Générer un rapport HTML détaillé dans le dossier de sortie.")]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false, HelpMessage = "Forcer la génération de données de test via New-TestData.ps1 (si applicable).")]
    [switch]$ForceTestDataGeneration,

    [Parameter(Mandatory = $false, HelpMessage = "Désactiver le Garbage Collection explicite avant chaque itération.")]
    [switch]$NoGarbageCollection
)

#region Internal Functions

# --- Fonction pour mesurer une seule exécution du ScriptBlock ---
function Measure-SingleExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [scriptblock]$ScriptBlockToMeasure,
        [Parameter(Mandatory = $true)] [hashtable]$ScriptParameters,
        [Parameter(Mandatory = $true)] [int]$IterationNumber,
        [Parameter(Mandatory = $true)] [int]$TotalIterationsCount,
        [Parameter(Mandatory = $true)] [string]$CurrentTestName,
        [Parameter(Mandatory = $true)] [switch]$SkipGarbageCollection
    )

    $progressParams = @{
        Activity = "Test de Performance: $CurrentTestName"
        Status   = "Exécution de l'itération $IterationNumber / $TotalIterationsCount"
        PercentComplete = (($IterationNumber - 1) / $TotalIterationsCount) * 100
        CurrentOperation = "Préparation..."
    }
    Write-Progress @progressParams

    Write-Verbose "Début Itération $IterationNumber/$TotalIterationsCount"

    # Nettoyage mémoire optionnel
    if (-not $SkipGarbageCollection.IsPresent) {
        Write-Verbose "  Exécution du Garbage Collection explicite..."
        [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect()
        Write-Verbose "  Garbage Collection terminé."
    } else {
        Write-Verbose "  Garbage Collection explicite désactivé (-NoGarbageCollection)."
    }

    # Métriques AVANT exécution
    $processInfoBefore = Get-Process -Id $PID -ErrorAction SilentlyContinue
    if (-not $processInfoBefore) {
         Write-Warning "Impossible d'obtenir les informations du processus (PID: $PID) avant l'itération $IterationNumber."
         $memoryBeforeWS = 0; $memoryBeforePM = 0; $cpuBefore = [TimeSpan]::Zero
    } else {
        $memoryBeforeWS = $processInfoBefore.WorkingSet64
        $memoryBeforePM = $processInfoBefore.PrivateMemorySize64
        $cpuBefore = $processInfoBefore.TotalProcessorTime
        Write-Verbose ("  Avant exécution: WS={0:F2}MB, PM={1:F2}MB, CPU={2:F3}s" -f ($memoryBeforeWS/1MB), ($memoryBeforePM/1MB), $cpuBefore.TotalSeconds)
    }

    $errorMessage = $null; $errorRecord = $null; $success = $false; $elapsedTime = $null

    # Mesure de l'exécution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Write-Progress @progressParams -CurrentOperation "Exécution du ScriptBlock..."
        # Utilisation de Invoke-Command pour potentiellement isoler davantage,
        # mais @Parameters ne fonctionne pas directement. Utilisation de l'appel direct standardisé.
        & $ScriptBlockToMeasure @ScriptParameters
        $stopwatch.Stop()
        $elapsedTime = $stopwatch.Elapsed
        $success = $true
        Write-Verbose "  Itération $IterationNumber terminée avec succès en $($elapsedTime.TotalSeconds.ToString('F3'))s."
    } catch {
        $stopwatch.Stop()
        $elapsedTime = $stopwatch.Elapsed # Mesurer le temps même en cas d'erreur
        $errorMessage = "Erreur Itération $IterationNumber - $($_.Exception.Message)"
        $errorRecord = $_
        Write-Warning $errorMessage
        Write-Verbose "  StackTrace: $($_.ScriptStackTrace)"
        $success = $false
    } finally {
         Write-Progress @progressParams -CurrentOperation "Collecte des métriques post-exécution..."
    }

    # Métriques APRÈS exécution
    $processInfoAfter = Get-Process -Id $PID -ErrorAction SilentlyContinue
     if (-not $processInfoAfter) {
         Write-Warning "Impossible d'obtenir les informations du processus (PID: $PID) après l'itération $IterationNumber."
         $memoryAfterWS = $memoryBeforeWS; $memoryAfterPM = $memoryBeforePM; $cpuAfter = $cpuBefore
    } else {
        $memoryAfterWS = $processInfoAfter.WorkingSet64
        $memoryAfterPM = $processInfoAfter.PrivateMemorySize64
        $cpuAfter = $processInfoAfter.TotalProcessorTime
        Write-Verbose ("  Après exécution: WS={0:F2}MB, PM={1:F2}MB, CPU={2:F3}s" -f ($memoryAfterWS/1MB), ($memoryAfterPM/1MB), $cpuAfter.TotalSeconds)
    }

    # Calculs finaux
    $executionTimeS = if ($elapsedTime) { $elapsedTime.TotalSeconds } else { -1 }
    $cpuTimeS = ($cpuAfter - $cpuBefore).TotalSeconds
    if ($cpuTimeS -lt 0) { $cpuTimeS = 0 } # Correction de précision

    $workingSetMB = [Math]::Round($memoryAfterWS / 1MB, 2)
    $privateMemoryMB = [Math]::Round($memoryAfterPM / 1MB, 2)
    $deltaWorkingSetMB = [Math]::Round(($memoryAfterWS - $memoryBeforeWS) / 1MB, 2)
    $deltaPrivateMemoryMB = [Math]::Round(($memoryAfterPM - $memoryBeforePM) / 1MB, 2)

    $iterationResult = [PSCustomObject]@{
        Iteration            = $IterationNumber
        TestName             = $CurrentTestName
        Success              = $success
        ExecutionTimeS       = [Math]::Round($executionTimeS, 5)
        ProcessorTimeS       = [Math]::Round($cpuTimeS, 5)
        WorkingSetMB         = $workingSetMB
        PrivateMemoryMB      = $privateMemoryMB
        DeltaWorkingSetMB    = $deltaWorkingSetMB
        DeltaPrivateMemoryMB = $deltaPrivateMemoryMB
        ErrorMessage         = $errorMessage
        ErrorRecord          = $errorRecord # Pour analyse en mémoire, pas pour JSON simple
    }

    $statusColor = if ($success) { "Green" } else { "Red" }
    Write-Host ("  Itération {0}: Temps={1:F3}s, CPU={2:F3}s, WS={3:F2}MB ({4:+#.##;-#.##;0.00}MB), PM={5:F2}MB ({6:+#.##;-#.##;0.00}MB), Succès={7}" -f `
        $IterationNumber, $iterationResult.ExecutionTimeS, $iterationResult.ProcessorTimeS,
        $iterationResult.WorkingSetMB, $iterationResult.DeltaWorkingSetMB,
        $iterationResult.PrivateMemoryMB, $iterationResult.DeltaPrivateMemoryMB,
        $success) -ForegroundColor $statusColor

    Write-Progress @progressParams -PercentComplete ($IterationNumber / $TotalIterationsCount * 100) -CurrentOperation "Terminé"
    if ($IterationNumber -eq $TotalIterationsCount) { Write-Progress @progressParams -Completed }

    return $iterationResult
}

# --- Fonction pour générer le rapport HTML ---
function New-BenchmarkHtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [PSCustomObject]$SummaryResults,
        [Parameter(Mandatory = $true)] [array]$DetailedResults,
        [Parameter(Mandatory = $true)] [string]$ReportPath,
        [Parameter(Mandatory = $false)] [hashtable]$ParametersUsed,
        [Parameter(Mandatory = $false)] [string]$DataPathUsed,
        [Parameter(Mandatory = $false)] [boolean]$ExplicitGCDisabled
    )

    Write-Host "Génération du rapport HTML : $ReportPath" -ForegroundColor Cyan

    $validDetailedResults = $DetailedResults | Where-Object { $_ -ne $null }
    if ($validDetailedResults.Count -eq 0) {
        Write-Warning "Aucune donnée détaillée valide pour générer le rapport HTML."
        # On pourrait écrire un fichier HTML minimal ici pour indiquer l'erreur.
        return
    }

    # Helper pour formater les données JS (évite les erreurs avec des noms contenant des quotes)
    $jsData = { param($data) ($data | ConvertTo-Json -Compress -Depth 1) }
    $jsLabels = & $jsData -data ($validDetailedResults | ForEach-Object { "Itération $($_.Iteration)" })
    $jsExecTimes = & $jsData -data ($validDetailedResults | ForEach-Object { [Math]::Round($_.ExecutionTimeS, 5) })
    $jsCpuTimes = & $jsData -data ($validDetailedResults | ForEach-Object { [Math]::Round($_.ProcessorTimeS, 5) })
    $jsWsMem = & $jsData -data ($validDetailedResults | ForEach-Object { $_.WorkingSetMB })
    $jsPmMem = & $jsData -data ($validDetailedResults | ForEach-Object { $_.PrivateMemoryMB })
    $jsDeltaWs = & $jsData -data ($validDetailedResults | ForEach-Object { $_.DeltaWorkingSetMB })
    $jsDeltaPm = & $jsData -data ($validDetailedResults | ForEach-Object { $_.DeltaPrivateMemoryMB })

    $paramsHtml = "<i>Aucun paramètre spécifié</i>"
    if ($ParametersUsed -and $ParametersUsed.Count -gt 0) {
        $paramsHtml = ($ParametersUsed.GetEnumerator() | ForEach-Object { "<li><strong>$($_.Name):</strong> <span class='param-value'>$($_.Value | Out-String -Width 100)</span></li>" }) -join ""
        $paramsHtml = "<ul>$paramsHtml</ul>"
    }
    $dataPathInfo = if (-not [string]::IsNullOrEmpty($DataPathUsed)) { "<code class='param-value'>$DataPathUsed</code>" } else { "<i>Non spécifié ou non applicable</i>" }
    $gcStatus = if ($ExplicitGCDisabled) { "Désactivé (<span class='param-value'>-NoGarbageCollection</span>)" } else { "Activé (par défaut)" }

    # Utilisation de $PSStyle pour les couleurs si disponible (PS 7+) ou fallback
    $successColor = if($PSStyle) { $PSStyle.Foreground.Green } else { "#28a745" }
    $failureColor = if($PSStyle) { $PSStyle.Foreground.Red } else { "#dc3545" }

    $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Performance : $($SummaryResults.TestName)</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script> <!-- Version CDN mise à jour -->
    <style>
        :root { --success-color: $successColor; --failure-color: $failureColor; --primary-color: #0056b3; --secondary-color: #007bff; --light-gray: #f8f9fa; --medium-gray: #e9ecef; --dark-gray: #343a40; --border-color: #dee2e6; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif; line-height: 1.6; margin: 20px; background-color: var(--light-gray); color: var(--dark-gray); }
        .container { max-width: 1300px; margin: auto; background-color: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 6px 12px rgba(0,0,0,0.1); }
        h1, h2, h3 { color: var(--primary-color); border-bottom: 2px solid var(--border-color); padding-bottom: 10px; margin-top: 30px; margin-bottom: 20px; font-weight: 600; }
        h1 { font-size: 2em; } h2 { font-size: 1.6em; } h3 { font-size: 1.3em; border-bottom: none; }
        .section { background-color: var(--light-gray); padding: 20px; border: 1px solid var(--medium-gray); border-radius: 6px; margin-bottom: 25px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; font-size: 0.95em; table-layout: fixed; } /* Fixed layout */
        th, td { padding: 12px 15px; text-align: left; border: 1px solid var(--border-color); vertical-align: middle; word-wrap: break-word; } /* Added word-wrap */
        th { background-color: var(--secondary-color); color: white; font-weight: 600; white-space: normal; } /* Allow wrap in header */
        tr:nth-child(even) { background-color: #ffffff; }
        tr:hover { background-color: var(--medium-gray); }
        .metric-label { font-weight: 600; color: var(--dark-gray); }
        .summary-table td:nth-child(n+2) { text-align: right; font-variant-numeric: tabular-nums; } /* Align numbers right */
        .chart-container { width: 100%; max-width: 900px; height: 450px; margin: 40px auto; border: 1px solid var(--border-color); padding: 20px; border-radius: 6px; background: white; box-shadow: 0 4px 8px rgba(0,0,0,0.05); }
        ul { padding-left: 20px; margin-top: 5px; } li { margin-bottom: 8px; }
        .param-value, code { font-family: 'Consolas', 'Menlo', 'Courier New', monospace; background-color: var(--medium-gray); padding: 3px 6px; border-radius: 4px; font-size: 0.9em; border: 1px solid #ced4da; display: inline-block; max-width: 95%; overflow-x: auto; vertical-align: middle; }
        pre { background-color: var(--medium-gray); padding: 12px; border-radius: 4px; font-size: 0.9em; white-space: pre-wrap; word-wrap: break-word; max-height: 180px; overflow-y: auto; border: 1px solid #ced4da; margin-top: 8px; }
        .error-message { color: var(--failure-color); font-weight: 500; }
        .success-true { color: var(--success-color); font-weight: bold; }
        .success-false { color: var(--failure-color); font-weight: bold; }
        .details-table td { font-size: 0.9em; } /* Slightly smaller font for details */
        .details-table .number { text-align: right; font-variant-numeric: tabular-nums; }
        .details-table .delta { text-align: right; font-variant-numeric: tabular-nums; }
        .details-table .bool { text-align: center; }
        .details-table .error-col { max-width: 300px; } /* Limit error width */
        .notes { font-size: 0.9em; color: #555; margin-top: 10px; }
    </style>
</head>
<body>
<div class="container">
    <h1>Rapport de Performance : $($SummaryResults.TestName)</h1>
    <div class="section" id="context">
        <h2>Contexte d'Exécution</h2>
        <p><span class="metric-label">Généré le:</span> $($SummaryResults.Timestamp.ToString("yyyy-MM-dd 'à' HH:mm:ss"))</p>
        <p><span class="metric-label">Itérations:</span> $($SummaryResults.TotalIterations) (Réussies: $($SummaryResults.SuccessfulIterations))</p>
        <p><span class="metric-label">Données de Test:</span> $dataPathInfo</p>
        <p><span class="metric-label">GC Explicite:</span> $gcStatus</p>
        <h3>Paramètres du ScriptBlock :</h3>
        $paramsHtml
    </div>

    <div class="section" id="summary">
        <h2>Résumé des Performances (Basé sur $($SummaryResults.ResultsAnalyzed))</h2>
        <table class="summary-table">
            <thead><tr><th>Métrique</th><th>Moyenne</th><th>Minimum</th><th>Maximum</th><th>Total</th><th>Taux Succès</th></tr></thead>
            <tbody>
                <tr><td class='metric-label'>Temps Écoulé (s)</td><td>$($SummaryResults.AverageExecutionTimeS.ToString('F5'))</td><td>$($SummaryResults.MinExecutionTimeS.ToString('F5'))</td><td>$($SummaryResults.MaxExecutionTimeS.ToString('F5'))</td><td>$($SummaryResults.TotalExecutionTimeS.ToString('F3'))</td><td rowspan="5" style="vertical-align: middle; text-align: center; font-size: 1.4em; font-weight: bold;">$($SummaryResults.SuccessRatePercent.ToString('F1')) %</td></tr>
                <tr><td class='metric-label'>Temps CPU (s)</td><td>$($SummaryResults.AverageProcessorTimeS.ToString('F5'))</td><td>$($SummaryResults.MinProcessorTimeS.ToString('F5'))</td><td>$($SummaryResults.MaxProcessorTimeS.ToString('F5'))</td><td>$($SummaryResults.TotalProcessorTimeS.ToString('F3'))</td></tr>
                <tr><td class='metric-label'>Working Set (MB)</td><td>$($SummaryResults.AverageWorkingSetMB.ToString('F2'))</td><td>$($SummaryResults.MinWorkingSetMB.ToString('F2'))</td><td>$($SummaryResults.MaxWorkingSetMB.ToString('F2'))</td><td>-</td></tr>
                <tr><td class='metric-label'>Mémoire Privée (MB)</td><td>$($SummaryResults.AveragePrivateMemoryMB.ToString('F2'))</td><td>$($SummaryResults.MinPrivateMemoryMB.ToString('F2'))</td><td>$($SummaryResults.MaxPrivateMemoryMB.ToString('F2'))</td><td>-</td></tr>
                <tr><td class='metric-label'>Delta Mémoire Privée (MB)</td><td>$($SummaryResults.AverageDeltaPrivateMemoryMB.ToString('F2'))</td><td>$($SummaryResults.MinDeltaPrivateMemoryMB.ToString('F2'))</td><td>$($SummaryResults.MaxDeltaPrivateMemoryMB.ToString('F2'))</td><td>-</td></tr>
            </tbody>
        </table>
        <p class="notes"><i>Note: Les statistiques (Moy, Min, Max) sont calculées sur les itérations réussies si disponibles ($($SummaryResults.SuccessfulIterations)), sinon sur toutes ($($SummaryResults.TotalIterations)). Delta Mémoire Privée est le changement moyen de mémoire privée pendant une itération réussie.</i></p>
    </div>

    <div class="section" id="details">
        <h2>Résultats Détaillés par Itération</h2>
        <table class="details-table">
         <thead><tr><th>Itération</th><th>Succès</th><th>Temps Exec (s)</th><th>Temps CPU (s)</th><th>WS (MB)</th><th>PM (MB)</th><th>Delta WS (MB)</th><th>Delta PM (MB)</th><th>Message d'Erreur</th></tr></thead>
         <tbody>
         $($DetailedResults | ForEach-Object {
             $successClass = if($_.Success) { 'success-true' } else { 'success-false' }
             $errorMsgHtml = if ($_.ErrorMessage) { "<pre class='error-message'>$($_.ErrorMessage -replace '<','<' -replace '>','>')</pre>" } else { '-' }
             @"
             <tr>
                 <td class='number'>$($_.Iteration)</td>
                 <td class='bool $successClass'>$($_.Success)</td>
                 <td class='number'>$($_.ExecutionTimeS.ToString('F5'))</td>
                 <td class='number'>$($_.ProcessorTimeS.ToString('F5'))</td>
                 <td class='number'>$($_.WorkingSetMB.ToString('F2'))</td>
                 <td class='number'>$($_.PrivateMemoryMB.ToString('F2'))</td>
                 <td class='delta'>$($_.DeltaWorkingSetMB.ToString("+#.##;-#.##;0.00"))</td>
                 <td class='delta'>$($_.DeltaPrivateMemoryMB.ToString("+#.##;-#.##;0.00"))</td>
                 <td class='error-col'>$errorMsgHtml</td>
             </tr>
"@         })
         </tbody>
        </table>
    </div>

    <div class="section" id="charts">
        <h2>Graphiques</h2>
        <div class="chart-container"><canvas id="timeChart"></canvas></div>
        <div class="chart-container"><canvas id="memoryChart"></canvas></div>
        <div class="chart-container"><canvas id="deltaMemoryChart"></canvas></div>
    </div>
<script>
    const iterationLabels = $jsLabels;
    const commonOptions = {
        scales: { x: { title: { display: true, text: 'Itération', font: { size: 14 } } }, y: { beginAtZero: true, title: { display: true, font: { size: 14 } } } },
        responsive: true, maintainAspectRatio: false, interaction: { intersect: false, mode: 'index' },
        plugins: { legend: { position: 'top', labels: { font: { size: 13 } } }, title: { display: true, font: { size: 18, weight: 'bold' } } }
    };
    const createChart = (canvasId, config) => { if (document.getElementById(canvasId)) { new Chart(document.getElementById(canvasId).getContext('2d'), config); }};

    // Time Chart
    createChart('timeChart', { type: 'line', data: { labels: iterationLabels, datasets: [
        { label: 'Temps Écoulé (s)', data: $jsExecTimes, borderColor: 'rgb(220, 53, 69)', backgroundColor: 'rgba(220, 53, 69, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 },
        { label: 'Temps CPU (s)', data: $jsCpuTimes, borderColor: 'rgb(13, 110, 253)', backgroundColor: 'rgba(13, 110, 253, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonOptions, plugins: { ...commonOptions.plugins, title: { ...commonOptions.plugins.title, text: 'Temps d\'Exécution et CPU par Itération'} }, scales: { ...commonOptions.scales, yTime: { ...commonOptions.scales.y, title: { ...commonOptions.scales.y.title, text: 'Secondes'}}} }
    });

    // Memory Chart
    createChart('memoryChart', { type: 'line', data: { labels: iterationLabels, datasets: [
        { label: 'Working Set (MB)', data: $jsWsMem, borderColor: 'rgb(25, 135, 84)', backgroundColor: 'rgba(25, 135, 84, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 },
        { label: 'Mémoire Privée (MB)', data: $jsPmMem, borderColor: 'rgb(108, 117, 125)', backgroundColor: 'rgba(108, 117, 125, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonOptions, plugins: { ...commonOptions.plugins, title: { ...commonOptions.plugins.title, text: 'Utilisation Mémoire Finale par Itération'} }, scales: { ...commonOptions.scales, yMemory: { ...commonOptions.scales.y, title: { ...commonOptions.scales.y.title, text: 'MB'}}} }
    });

    // Delta Memory Chart
    createChart('deltaMemoryChart', { type: 'bar', data: { labels: iterationLabels, datasets: [
        { label: 'Delta Working Set (MB)', data: $jsDeltaWs, backgroundColor: 'rgba(255, 193, 7, 0.6)', borderColor: 'rgb(255, 193, 7)', borderWidth: 1, yAxisID: 'yDeltaMemory' },
        { label: 'Delta Mémoire Privée (MB)', data: $jsDeltaPm, backgroundColor: 'rgba(255, 159, 64, 0.6)', borderColor: 'rgb(255, 159, 64)', borderWidth: 1, yAxisID: 'yDeltaMemory' } ] },
        options: { ...commonOptions, scales: { ...commonOptions.scales, y: null, yDeltaMemory: { beginAtZero: false, position: 'left', title: { display: true, text: 'Changement de Mémoire (MB)', font: { size: 14 } }}}, plugins: { ...commonOptions.plugins, title: { ...commonOptions.plugins.title, text: 'Variation de Mémoire par Itération'} } }
    });
</script>
</div> <!-- /container -->
</body>
</html>
"@

    try {
        $htmlContent | Out-File -FilePath $ReportPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Host "Rapport HTML généré avec succès : $ReportPath" -ForegroundColor Green
    } catch {
        Write-Error "Erreur critique lors de la sauvegarde du rapport HTML '$ReportPath': $($_.Exception.Message)"
    }
}

#endregion

#region Validation and Initialization

Write-Host "=== Initialisation Test de Performance : $TestName ===" -ForegroundColor White -BackgroundColor DarkBlue
$startTimestamp = Get-Date
$global:StopRequested = $false # Variable globale pour interruption propre si nécessaire

# Nettoyer TestName pour l'utilisation dans les chemins
$safeTestNameForPath = $TestName -replace '[^a-zA-Z0-9_.-]+', '_' -replace '^[_.-]+|[_.-]+$' # Enlève non-alphanum, remplace par _, trim underscores/points/tirets début/fin
if ([string]::IsNullOrWhiteSpace($safeTestNameForPath)) { $safeTestNameForPath = "UnnamedTest" }

# Créer le répertoire de sortie unique pour cette exécution
$testSpecificSubDir = "Benchmark_$($safeTestNameForPath)_$($startTimestamp.ToString('yyyyMMddHHmmss'))"
$testOutputPath = $null
$actualTestDataPath = $null # Chemin effectif des données de test utilisées
$testDataStatus = "Non applicable"

try {
    # Résoudre le chemin de sortie de base
    $resolvedOutputPath = Resolve-Path -Path $OutputPath -ErrorAction SilentlyContinue
    if (-not $resolvedOutputPath) {
        if ($PSCmdlet.ShouldProcess($OutputPath, "Créer le répertoire de sortie principal (n'existe pas)")) {
            $createdDir = New-Item -Path $OutputPath -ItemType Directory -Force -ErrorAction Stop
            $resolvedOutputPath = $createdDir.FullName
            Write-Verbose "Répertoire de sortie principal créé : $resolvedOutputPath"
        } else {
            Write-Error "Création du répertoire de sortie principal annulée par l'utilisateur. Arrêt."
            return # Exit
        }
    } elseif ( -not (Test-Path $resolvedOutputPath -PathType Container)) {
         Write-Error "Le chemin de sortie principal '$resolvedOutputPath' existe mais n'est pas un répertoire. Arrêt."
         return # Exit
    } else {
         Write-Verbose "Répertoire de sortie principal trouvé: $resolvedOutputPath"
    }

    # Créer le sous-répertoire spécifique au test
    $testOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath $testSpecificSubDir
    if ($PSCmdlet.ShouldProcess($testOutputPath, "Créer le sous-répertoire pour les résultats du test '$TestName'")) {
        New-Item -Path $testOutputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Host "Répertoire de sortie pour ce test : $testOutputPath" -ForegroundColor Green
    } else {
        Write-Error "Création du sous-répertoire de sortie spécifique au test annulée. Arrêt."
        return # Exit
    }
} catch {
    Write-Error "Impossible de créer les répertoires de sortie. Chemin de base: '$OutputPath'. Erreur: $($_.Exception.Message). Vérifiez les permissions. Arrêt."
    return # Exit
}

# Gestion des données de test
if (-not [string]::IsNullOrEmpty($TestDataPath)) {
    $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue
    if ($resolvedTestDataPath -and (Test-Path $resolvedTestDataPath -PathType Container)) {
        $actualTestDataPath = $resolvedTestDataPath.Path
        $testDataStatus = "Utilisation des données fournies: $actualTestDataPath"
        Write-Verbose $testDataStatus
    } else {
        Write-Warning "Le chemin TestDataPath fourni ('$TestDataPath') n'existe pas ou n'est pas un répertoire. Tentative de génération si New-TestData.ps1 existe."
        # Ne pas écraser $actualTestDataPath ici, on va vérifier New-TestData.ps1
    }
}

# Tenter la génération seulement si TestDataPath n'est pas valide/fourni OU si on force
if (-not $actualTestDataPath -or $ForceTestDataGeneration) {
    $testDataScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-TestData.ps1"
    if (Test-Path $testDataScriptPath -PathType Leaf) {
        $targetGeneratedDataPath = Join-Path -Path $testOutputPath -ChildPath "generated_test_data"
        $generate = $false
        if (-not (Test-Path -Path $targetGeneratedDataPath -PathType Container)) {
            $generate = $true
            Write-Verbose "Le répertoire de données générées '$targetGeneratedDataPath' n'existe pas, génération planifiée."
        } elseif ($ForceTestDataGeneration) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Supprimer et Regénérer les données de test (option -ForceTestDataGeneration)")) {
                Write-Verbose "Forçage de la regénération des données de test."
                try { Remove-Item -Path $targetGeneratedDataPath -Recurse -Force -ErrorAction Stop } catch { Write-Warning "Impossible de supprimer l'ancien dossier de données '$targetGeneratedDataPath': $($_.Exception.Message)"}
                $generate = $true
            } else {
                Write-Warning "Regénération des données de test annulée par l'utilisateur. Utilisation des données existantes."
                $actualTestDataPath = $targetGeneratedDataPath # On utilise quand même les anciennes
                $testDataStatus = "Utilisation des données existantes (regénération annulée): $actualTestDataPath"
            }
        } else {
            # Le dossier existe et on ne force pas -> utiliser l'existant
             $actualTestDataPath = $targetGeneratedDataPath
             $testDataStatus = "Utilisation des données précédemment générées: $actualTestDataPath"
             Write-Verbose $testDataStatus
        }

        if ($generate) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Générer les données de test via New-TestData.ps1")) {
                Write-Host "Génération des données de test dans '$targetGeneratedDataPath'..." -ForegroundColor Yellow
                try {
                    $genParams = @{ OutputPath = $targetGeneratedDataPath; ErrorAction = 'Stop'}
                    if($ForceTestDataGeneration) { $genParams.Force = $true } # Passer Force à New-TestData si besoin
                    $generatedPath = & $testDataScriptPath @genParams

                    if ($generatedPath -and (Test-Path $generatedPath -PathType Container)) {
                        $actualTestDataPath = $generatedPath # Mise à jour du chemin effectif
                        $testDataStatus = "Données générées avec succès: $actualTestDataPath"
                        Write-Host $testDataStatus -ForegroundColor Green
                        # Tenter de mettre à jour $Parameters si une clé commune existe (convention)
                        $commonDataParamNames = 'InputPath', 'SourcePath', 'InputDirectory', 'DataPath', 'ScriptsPath' # Clés courantes
                        foreach ($paramName in $commonDataParamNames) {
                            if ($Parameters.ContainsKey($paramName)) {
                                Write-Verbose "Mise à jour du paramètre '$paramName' avec le chemin des données générées."
                                $Parameters[$paramName] = $actualTestDataPath
                                break # Arrêter après la première correspondance trouvée
                            }
                        }
                        if (-not $Parameters.ContainsKey($paramName)) {
                            Write-Warning "Données générées dans '$actualTestDataPath', mais aucun paramètre standard ($($commonDataParamNames -join '/')) trouvé dans -Parameters pour injecter ce chemin automatiquement. Assurez-vous que votre -ScriptBlock y accède correctement."
                        }
                    } else {
                        Write-Error "La génération des données de test via New-TestData.ps1 a échoué ou n'a pas retourné de chemin valide."
                        $testDataStatus = "Échec de la génération."
                    }
                } catch {
                    Write-Error "Erreur critique lors de l'appel à New-TestData.ps1: $($_.Exception.Message)"
                    $testDataStatus = "Échec critique de la génération."
                }
            } else {
                 Write-Warning "Génération des données de test annulée par l'utilisateur."
                 $testDataStatus = "Génération annulée."
                 # Si le dossier existait avant l'annulation, on l'utilise quand même
                 if ($actualTestDataPath -eq $targetGeneratedDataPath) {
                    $testDataStatus += " Utilisation des données pré-existantes."
                 }
            }
        }
    } elseif (-not $actualTestDataPath) { # Si pas de chemin explicite et pas de New-TestData.ps1
        $testDataStatus = "Non requis/géré (TestDataPath non fourni/valide et New-TestData.ps1 non trouvé)."
        Write-Verbose $testDataStatus
    }
}

# Afficher les paramètres finaux (après mise à jour potentielle par la génération de données)
Write-Verbose "Paramètres finaux passés au ScriptBlock pour chaque itération:"
Write-Verbose ($Parameters | Out-String)

#endregion

#region Main Execution Logic

Write-Host "`n=== Démarrage des $Iterations Itérations ($($startTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor Cyan

$allIterationResults = [System.Collections.Generic.List[PSCustomObject]]::new()

# Enregistrer l'état initial de la console pour restauration
# $initialConsoleState = $Host.UI.RawUI

# Gestion de l'interruption (Ctrl+C)
# Note: Ceci est basique et peut ne pas intercepter toutes les formes d'arrêt.
# L'utilisation de Runspaces ou Jobs offrirait un contrôle plus fin.
# $tokenSource = [System.Threading.CancellationTokenSource]::new()
# $Host.Runspace.Events.SubscribeEvent($Host, "CancelEvent", {
#    Write-Warning "Interruption demandée (Ctrl+C). Arrêt après l'itération en cours..."
#    $global:StopRequested = $true
#    # $tokenSource.Cancel() # Nécessiterait que le ScriptBlock gère le token
# }) | Out-Null

try {
    # Boucle d'exécution des itérations
    foreach ($i in 1..$Iterations) {
        if ($global:StopRequested) {
            Write-Warning "Exécution interrompue avant l'itération $i."
            break
        }
        $invokeParams = @{
            ScriptBlockToMeasure = $ScriptBlock
            ScriptParameters     = $Parameters
            IterationNumber      = $i
            TotalIterationsCount = $Iterations
            CurrentTestName      = $TestName
            SkipGarbageCollection = $NoGarbageCollection # Passer le switch
            ErrorAction          = 'Continue'
        }
        $iterationResult = Measure-SingleExecution @invokeParams
        $allIterationResults.Add($iterationResult)
    }
}
finally {
    # Nettoyage: Désabonnement de l'événement Ctrl+C si utilisé
    # $Host.Runspace.Events.UnsubscribeEvent($subscriptionId) # Nécessite de stocker l'ID
    # $tokenSource.Dispose()
    # Restaurer l'état de la console si modifié
    # $Host.UI.RawUI = $initialConsoleState
    Write-Progress -Activity "Test de Performance: $TestName" -Completed # Assurer la fermeture de la barre
}

#endregion

#region Results Aggregation and Output

Write-Host "`n=== Calcul des Statistiques Agrégées ($($allIterationResults.Count) itérations exécutées) ===" -ForegroundColor Cyan
$finalResultsArray = $allIterationResults.ToArray()

$successfulIterations = ($finalResultsArray | Where-Object { $_.Success }).Count
$failedIterations = $finalResultsArray.Count - $successfulIterations

$resultsToAnalyze = $finalResultsArray | Where-Object { $_.Success }
$analysisSource = "Itérations Réussies ($successfulIterations)"
if ($successfulIterations -eq 0 -and $finalResultsArray.Count -gt 0) {
    Write-Warning "Aucune itération n'a réussi ! Les statistiques (sauf taux de succès) seront basées sur les $($finalResultsArray.Count) tentatives."
    $resultsToAnalyze = $finalResultsArray
    $analysisSource = "Toutes les Itérations ($($finalResultsArray.Count)) - Attention: échecs inclus"
} elseif ($finalResultsArray.Count -eq 0) {
     Write-Warning "Aucune itération n'a été exécutée (ou interrompue avant la première)."
     $resultsToAnalyze = @()
     $analysisSource = "Aucune"
}

# Initialisation des stats
$metrics = @{
    ExecutionTimeS = @{ Average = -1; Minimum = -1; Maximum = -1; Sum = -1 }
    ProcessorTimeS = @{ Average = -1; Minimum = -1; Maximum = -1; Sum = -1 }
    WorkingSetMB = @{ Average = -1; Minimum = -1; Maximum = -1 }
    PrivateMemoryMB = @{ Average = -1; Minimum = -1; Maximum = -1 }
    DeltaPrivateMemoryMB = @{ Average = -1; Minimum = -1; Maximum = -1 }
}

if ($resultsToAnalyze.Count -gt 0) {
    foreach ($prop in $metrics.Keys) {
        $operations = @('Average', 'Minimum', 'Maximum')
        if ($metrics[$prop].ContainsKey('Sum')) { $operations += 'Sum' }
        $stats = $resultsToAnalyze | Measure-Object -Property $prop -Parameters $operations -ErrorAction SilentlyContinue
        if($stats){
            foreach($op in $operations){
                 $metrics[$prop].$op = $stats.$op
            }
        }
    }
    # Arrondir les moyennes mémoire
    $metrics.WorkingSetMB.Average = [Math]::Round($metrics.WorkingSetMB.Average, 2)
    $metrics.PrivateMemoryMB.Average = [Math]::Round($metrics.PrivateMemoryMB.Average, 2)
    $metrics.DeltaPrivateMemoryMB.Average = [Math]::Round($metrics.DeltaPrivateMemoryMB.Average, 2)
}

# Construire l'objet résumé final
$summaryResults = [PSCustomObject]@{
    TestName                   = $TestName
    Timestamp                  = $startTimestamp
    TotalIterationsAttempted   = $finalResultsArray.Count # Nombre réellement tenté
    TotalIterationsRequested   = $Iterations # Nombre demandé initialement
    SuccessfulIterations       = $successfulIterations
    FailedIterations           = $failedIterations
    SuccessRatePercent         = if ($finalResultsArray.Count -gt 0) { [Math]::Round(($successfulIterations / $finalResultsArray.Count * 100), 1) } else { 0 }
    ResultsAnalyzed            = $analysisSource
    # Temps Écoulé
    AverageExecutionTimeS      = $metrics.ExecutionTimeS.Average
    MinExecutionTimeS          = $metrics.ExecutionTimeS.Minimum
    MaxExecutionTimeS          = $metrics.ExecutionTimeS.Maximum
    TotalExecutionTimeS        = $metrics.ExecutionTimeS.Sum
    # Temps CPU
    AverageProcessorTimeS      = $metrics.ProcessorTimeS.Average
    MinProcessorTimeS          = $metrics.ProcessorTimeS.Minimum
    MaxProcessorTimeS          = $metrics.ProcessorTimeS.Maximum
    TotalProcessorTimeS        = $metrics.ProcessorTimeS.Sum
    # Mémoire Working Set
    AverageWorkingSetMB        = $metrics.WorkingSetMB.Average
    MinWorkingSetMB            = $metrics.WorkingSetMB.Minimum
    MaxWorkingSetMB            = $metrics.WorkingSetMB.Maximum
    # Mémoire Privée
    AveragePrivateMemoryMB     = $metrics.PrivateMemoryMB.Average
    MinPrivateMemoryMB         = $metrics.PrivateMemoryMB.Minimum
    MaxPrivateMemoryMB         = $metrics.PrivateMemoryMB.Maximum
    # Delta Mémoire Privée
    AverageDeltaPrivateMemoryMB= $metrics.DeltaPrivateMemoryMB.Average
    MinDeltaPrivateMemoryMB    = $metrics.DeltaPrivateMemoryMB.Minimum
    MaxDeltaPrivateMemoryMB    = $metrics.DeltaPrivateMemoryMB.Maximum
    # Contexte
    ParametersUsed             = $Parameters
    TestDataPathUsed           = $actualTestDataPath
    ExplicitGCDisabled         = $NoGarbageCollection.IsPresent
    OutputDirectory            = $testOutputPath # Ajouter le chemin de sortie au résumé
}

# Afficher le résumé console
Write-Host "`n--- Résumé Final : $TestName ---" -ForegroundColor White -BackgroundColor DarkMagenta
Write-Host "  Itérations Tentées/Demandées : $($summaryResults.TotalIterationsAttempted) / $($summaryResults.TotalIterationsRequested) (Succès: $successfulIterations, Échecs: $failedIterations, Taux: $($summaryResults.SuccessRatePercent)%)"
Write-Host "  Statistiques basées sur      : $($summaryResults.ResultsAnalyzed)"
Write-Host "  Temps Écoulé (s)  (Avg/Min/Max) : $($summaryResults.AverageExecutionTimeS.ToString('F5')) / $($summaryResults.MinExecutionTimeS.ToString('F5')) / $($summaryResults.MaxExecutionTimeS.ToString('F5'))"
Write-Host "  Temps CPU (s)     (Avg/Min/Max) : $($summaryResults.AverageProcessorTimeS.ToString('F5')) / $($summaryResults.MinProcessorTimeS.ToString('F5')) / $($summaryResults.MaxProcessorTimeS.ToString('F5'))"
Write-Host "  Working Set (MB)  (Avg/Min/Max) : $($summaryResults.AverageWorkingSetMB.ToString('F2')) / $($summaryResults.MinWorkingSetMB.ToString('F2')) / $($summaryResults.MaxWorkingSetMB.ToString('F2'))"
Write-Host "  Private Mem (MB)  (Avg/Min/Max) : $($summaryResults.AveragePrivateMemoryMB.ToString('F2')) / $($summaryResults.MinPrivateMemoryMB.ToString('F2')) / $($summaryResults.MaxPrivateMemoryMB.ToString('F2'))"
Write-Host "  Delta PM (MB)     (Avg/Min/Max) : $($summaryResults.AverageDeltaPrivateMemoryMB.ToString('F2')) / $($summaryResults.MinDeltaPrivateMemoryMB.ToString('F2')) / $($summaryResults.MaxDeltaPrivateMemoryMB.ToString('F2'))"
Write-Host "  Résultats sauvegardés dans     : $testOutputPath"

# Enregistrer les résultats JSON
$resultsJsonFileName = "Benchmark_Results_$($safeTestNameForPath).json"
$resultsJsonPath = Join-Path -Path $testOutputPath -ChildPath $resultsJsonFileName
$outputDataForJson = @{
    Summary = $summaryResults
    DetailedResults = $finalResultsArray | Select-Object -ExcludeProperty ErrorRecord
}
try {
    ConvertTo-Json -InputObject $outputDataForJson -Depth 5 | Out-File -FilePath $resultsJsonPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "Résultats complets enregistrés (JSON) : $resultsJsonPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur critique lors de l'enregistrement des résultats JSON '$resultsJsonPath': $($_.Exception.Message)"
}

# Générer le rapport HTML si demandé et si des résultats existent
if ($GenerateReport -and $finalResultsArray.Count -gt 0) {
    $reportHtmlFileName = "Benchmark_Report_$($safeTestNameForPath).html"
    $reportHtmlPath = Join-Path -Path $testOutputPath -ChildPath $reportHtmlFileName
    $reportParams = @{
        SummaryResults     = $summaryResults
        DetailedResults    = $finalResultsArray
        ReportPath         = $reportHtmlPath
        ParametersUsed     = $Parameters
        DataPathUsed       = $actualTestDataPath
        ExplicitGCDisabled = $NoGarbageCollection.IsPresent
        ErrorAction        = 'Continue' # Ne pas bloquer si la génération du rapport échoue
    }
    New-BenchmarkHtmlReport @reportParams
} elseif ($GenerateReport) {
    Write-Warning "Génération du rapport HTML ignorée car aucune itération n'a été exécutée."
}

$endTimestamp = Get-Date
$totalDuration = $endTimestamp - $startTimestamp
Write-Host "`n=== Test de Performance '$TestName' Terminé ($($endTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Durée totale du script de test : $($totalDuration.ToString('g'))"

# Retourner l'objet résumé final
return $summaryResults

#endregion