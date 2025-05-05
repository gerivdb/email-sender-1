#Requires -Version 5.1
<#
.SYNOPSIS
    Mesure de maniÃƒÂ¨re fiable les performances d'un bloc de script PowerShell sur plusieurs itÃƒÂ©rations.
.DESCRIPTION
    Ce script exÃƒÂ©cute un bloc de script PowerShell spÃƒÂ©cifiÃƒÂ© (`ScriptBlock`) un nombre dÃƒÂ©fini de fois (`Iterations`).
    Pour chaque itÃƒÂ©ration, il mesure prÃƒÂ©cisÃƒÂ©ment le temps d'exÃƒÂ©cution, le temps CPU consommÃƒÂ©, et l'utilisation
    de la mÃƒÂ©moire (Working Set et Private Memory, y compris les deltas).
    Il collecte ces mÃƒÂ©triques, calcule des statistiques agrÃƒÂ©gÃƒÂ©es (moyenne, min, max, total, taux de succÃƒÂ¨s),
    et gÃƒÂ©nÃƒÂ¨re un rapport JSON dÃƒÂ©taillÃƒÂ© dans un sous-rÃƒÂ©pertoire unique. Un rapport HTML visuel peut ÃƒÂ©galement
    ÃƒÂªtre gÃƒÂ©nÃƒÂ©rÃƒÂ© optionnellement. Le script inclut une gestion robuste des donnÃƒÂ©es de test et un nettoyage mÃƒÂ©moire
    configurable entre les itÃƒÂ©rations pour amÃƒÂ©liorer la cohÃƒÂ©rence des mesures.
.PARAMETER ScriptBlock
    Le bloc de script PowerShell dont les performances doivent ÃƒÂªtre mesurÃƒÂ©es.
    Ce bloc sera exÃƒÂ©cutÃƒÂ© pour chaque itÃƒÂ©ration. Il est recommandÃƒÂ© d'utiliser le splatting
    si le script cible prend des paramÃƒÂ¨tres : { & ".\monScript.ps1" @Parameters }
.PARAMETER Parameters
    Table de hachage contenant les paramÃƒÂ¨tres ÃƒÂ  passer directement au ScriptBlock via splatting (`@Parameters`).
    Ces paramÃƒÂ¨tres sont constants pour toutes les itÃƒÂ©rations.
.PARAMETER TestName
    Nom unique et descriptif pour cette session de test de performance. UtilisÃƒÂ© pour nommer
    les fichiers de sortie, le sous-rÃƒÂ©pertoire des rÃƒÂ©sultats et dans les rapports.
.PARAMETER OutputPath
    Chemin du rÃƒÂ©pertoire racine oÃƒÂ¹ les rÃƒÂ©sultats seront enregistrÃƒÂ©s. Un sous-rÃƒÂ©pertoire
    unique (basÃƒÂ© sur TestName + Timestamp) sera crÃƒÂ©ÃƒÂ© dans ce chemin pour cette exÃƒÂ©cution.
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un rÃƒÂ©pertoire contenant des donnÃƒÂ©es de test prÃƒÂ©-existantes nÃƒÂ©cessaires
    au ScriptBlock. Si fourni et valide, il est enregistrÃƒÂ© et son utilisation dÃƒÂ©pend du ScriptBlock/Parameters.
    Si non fourni, le script peut tenter d'utiliser 'New-TestData.ps1' s'il existe.
.PARAMETER Iterations
    Nombre d'exÃƒÂ©cutions complÃƒÂ¨tes du ScriptBlock ÃƒÂ  effectuer pour la mesure.
    Un nombre plus ÃƒÂ©levÃƒÂ© donne des statistiques plus fiables mais prend plus de temps. DÃƒÂ©faut: 5.
.PARAMETER GenerateReport
    Si spÃƒÂ©cifiÃƒÂ© ($true), gÃƒÂ©nÃƒÂ¨re un rapport HTML dÃƒÂ©taillÃƒÂ© en plus du fichier JSON.
    Ce rapport inclut le contexte, des tableaux rÃƒÂ©capitulatifs, les dÃƒÂ©tails de chaque itÃƒÂ©ration et des graphiques.
.PARAMETER ForceTestDataGeneration
    [Optionnel] Si la gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es de test via 'New-TestData.ps1' est dÃƒÂ©clenchÃƒÂ©e,
    ce switch force la suppression et la recrÃƒÂ©ation des donnÃƒÂ©es mÃƒÂªme si elles existent dÃƒÂ©jÃƒÂ .
.PARAMETER NoGarbageCollection
    [Optionnel] Si spÃƒÂ©cifiÃƒÂ© ($true), dÃƒÂ©sactive l'appel explicite ÃƒÂ  [System.GC]::Collect()
    avant chaque itÃƒÂ©ration. Peut rendre les mesures plus proches des conditions rÃƒÂ©elles mais potentiellement
    moins cohÃƒÂ©rentes d'une itÃƒÂ©ration ÃƒÂ  l'autre.
.EXAMPLE
    # Test simple d'une commande intÃƒÂ©grÃƒÂ©e, 10 itÃƒÂ©rations, avec rapport HTML
    .\Test-ParallelPerformance.ps1 -ScriptBlock { Get-Process | Out-Null } `
        -TestName "GetProcess_Performance" `
        -OutputPath "C:\Temp\PerfResults" `
        -Iterations 10 `
        -GenerateReport

.EXAMPLE
    # Test d'un script externe avec paramÃƒÂ¨tres et donnÃƒÂ©es de test existantes
    $scriptToTestPath = ".\development\scripts\analysis\Analyze-DataFiles.ps1"
    $analysisParams = @{
        SourcePath = "C:\InputData" # Ce chemin doit ÃƒÂªtre utilisÃƒÂ© par le script testÃƒÂ©
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
    # Test avec gÃƒÂ©nÃƒÂ©ration automatique de donnÃƒÂ©es et sans GC forcÃƒÂ©
    $scriptToTestPath = ".\development\scripts\processing\Process-Items.ps1"
    # Suppose que Process-Items.ps1 utilise un paramÃƒÂ¨tre InputDirectory pointant vers les donnÃƒÂ©es gÃƒÂ©nÃƒÂ©rÃƒÂ©es
    $processingParams = @{ MaxItems = 1000; InputDirectory = $null } # InputDirectory sera mis ÃƒÂ  jour si gÃƒÂ©nÃƒÂ©ration OK
    .\Test-ParallelPerformance.ps1 -ScriptBlock { & $scriptToTestPath @Parameters } `
        -Parameters $processingParams `
        -TestName "ItemProcessing_AutoData_NoGC" `
        -OutputPath "C:\Temp\PerfResults\Processing" `
        -Iterations 3 `
        -GenerateReport `
        -ForceTestDataGeneration `
        -NoGarbageCollection

.NOTES
    Auteur     : Votre Nom/Ãƒâ€°quipe
    Version    : 2.1
    Date       : 2023-10-27
    DÃƒÂ©pendances: Chart.js (via CDN pour le rapport HTML)
                 New-TestData.ps1 (optionnel, pour la gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es de test)

    Structure de Sortie:
    Un sous-rÃƒÂ©pertoire unique sera crÃƒÂ©ÃƒÂ© dans OutputPath: `Benchmark_[TestName]_[Timestamp]`
    Ce rÃƒÂ©pertoire contiendra :
      - `Benchmark_Results_[TestName].json`: Les donnÃƒÂ©es brutes et le rÃƒÂ©sumÃƒÂ©.
      - `Benchmark_Report_[TestName].html`: Le rapport HTML (si -GenerateReport).
      - `generated_test_data/`: Le dossier des donnÃƒÂ©es de test (si gÃƒÂ©nÃƒÂ©ration automatique).

    Mesures de MÃƒÂ©moire:
    - Working Set (WS): MÃƒÂ©moire physique totale utilisÃƒÂ©e par le processus.
    - Private Memory (PM): MÃƒÂ©moire non partagÃƒÂ©e allouÃƒÂ©e au processus (souvent plus pertinent).
    - Delta WS/PM: Changement de mÃƒÂ©moire *pendant* l'exÃƒÂ©cution de l'itÃƒÂ©ration.

    Garbage Collection: L'option -NoGarbageCollection permet de tester sans l'influence du GC forcÃƒÂ©.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Bloc de script PowerShell ÃƒÂ  mesurer.")]
    [ValidateNotNullOrEmpty()]
    [scriptblock]$ScriptBlock,

    [Parameter(Mandatory = $false, HelpMessage = "Table de hachage des paramÃƒÂ¨tres constants pour le ScriptBlock.")]
    [hashtable]$Parameters = @{},

    [Parameter(Mandatory = $true, HelpMessage = "Nom unique et descriptif pour ce test (utilisÃƒÂ© pour le dossier/fichiers de sortie).")]
    [ValidateNotNullOrEmpty()]
    [string]$TestName,

    [Parameter(Mandatory = $true, HelpMessage = "RÃƒÂ©pertoire racine oÃƒÂ¹ le sous-dossier des rÃƒÂ©sultats sera crÃƒÂ©ÃƒÂ©.")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter(Mandatory = $false, HelpMessage = "[Optionnel] Chemin vers les donnÃƒÂ©es de test prÃƒÂ©-existantes (informatif, le ScriptBlock doit l'utiliser).")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Nombre d'exÃƒÂ©cutions du ScriptBlock ÃƒÂ  mesurer.")]
    [ValidateRange(1, 1000)]
    [int]$Iterations = 5,

    [Parameter(Mandatory = $false, HelpMessage = "GÃƒÂ©nÃƒÂ©rer un rapport HTML dÃƒÂ©taillÃƒÂ© dans le dossier de sortie.")]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false, HelpMessage = "Forcer la gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es de test via New-TestData.ps1 (si applicable).")]
    [switch]$ForceTestDataGeneration,

    [Parameter(Mandatory = $false, HelpMessage = "DÃƒÂ©sactiver le Garbage Collection explicite avant chaque itÃƒÂ©ration.")]
    [switch]$NoGarbageCollection
)

#region Internal Functions

# --- Fonction pour mesurer une seule exÃƒÂ©cution du ScriptBlock ---
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
        Status   = "ExÃƒÂ©cution de l'itÃƒÂ©ration $IterationNumber / $TotalIterationsCount"
        PercentComplete = (($IterationNumber - 1) / $TotalIterationsCount) * 100
        CurrentOperation = "PrÃƒÂ©paration..."
    }
    Write-Progress @progressParams

    Write-Verbose "DÃƒÂ©but ItÃƒÂ©ration $IterationNumber/$TotalIterationsCount"

    # Nettoyage mÃƒÂ©moire optionnel
    if (-not $SkipGarbageCollection.IsPresent) {
        Write-Verbose "  ExÃƒÂ©cution du Garbage Collection explicite..."
        [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect()
        Write-Verbose "  Garbage Collection terminÃƒÂ©."
    } else {
        Write-Verbose "  Garbage Collection explicite dÃƒÂ©sactivÃƒÂ© (-NoGarbageCollection)."
    }

    # MÃƒÂ©triques AVANT exÃƒÂ©cution
    $processInfoBefore = Get-Process -Id $PID -ErrorAction SilentlyContinue
    if (-not $processInfoBefore) {
         Write-Warning "Impossible d'obtenir les informations du processus (PID: $PID) avant l'itÃƒÂ©ration $IterationNumber."
         $memoryBeforeWS = 0; $memoryBeforePM = 0; $cpuBefore = [TimeSpan]::Zero
    } else {
        $memoryBeforeWS = $processInfoBefore.WorkingSet64
        $memoryBeforePM = $processInfoBefore.PrivateMemorySize64
        $cpuBefore = $processInfoBefore.TotalProcessorTime
        Write-Verbose ("  Avant exÃƒÂ©cution: WS={0:F2}MB, PM={1:F2}MB, CPU={2:F3}s" -f ($memoryBeforeWS/1MB), ($memoryBeforePM/1MB), $cpuBefore.TotalSeconds)
    }

    $errorMessage = $null; $errorRecord = $null; $success = $false; $elapsedTime = $null

    # Mesure de l'exÃƒÂ©cution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        Write-Progress @progressParams -CurrentOperation "ExÃƒÂ©cution du ScriptBlock..."
        # Utilisation de Invoke-Command pour potentiellement isoler davantage,
        # mais @Parameters ne fonctionne pas directement. Utilisation de l'appel direct standardisÃƒÂ©.
        & $ScriptBlockToMeasure @ScriptParameters
        $stopwatch.Stop()
        $elapsedTime = $stopwatch.Elapsed
        $success = $true
        Write-Verbose "  ItÃƒÂ©ration $IterationNumber terminÃƒÂ©e avec succÃƒÂ¨s en $($elapsedTime.TotalSeconds.ToString('F3'))s."
    } catch {
        $stopwatch.Stop()
        $elapsedTime = $stopwatch.Elapsed # Mesurer le temps mÃƒÂªme en cas d'erreur
        $errorMessage = "Erreur ItÃƒÂ©ration $IterationNumber - $($_.Exception.Message)"
        $errorRecord = $_
        Write-Warning $errorMessage
        Write-Verbose "  StackTrace: $($_.ScriptStackTrace)"
        $success = $false
    } finally {
         Write-Progress @progressParams -CurrentOperation "Collecte des mÃƒÂ©triques post-exÃƒÂ©cution..."
    }

    # MÃƒÂ©triques APRÃƒË†S exÃƒÂ©cution
    $processInfoAfter = Get-Process -Id $PID -ErrorAction SilentlyContinue
     if (-not $processInfoAfter) {
         Write-Warning "Impossible d'obtenir les informations du processus (PID: $PID) aprÃƒÂ¨s l'itÃƒÂ©ration $IterationNumber."
         $memoryAfterWS = $memoryBeforeWS; $memoryAfterPM = $memoryBeforePM; $cpuAfter = $cpuBefore
    } else {
        $memoryAfterWS = $processInfoAfter.WorkingSet64
        $memoryAfterPM = $processInfoAfter.PrivateMemorySize64
        $cpuAfter = $processInfoAfter.TotalProcessorTime
        Write-Verbose ("  AprÃƒÂ¨s exÃƒÂ©cution: WS={0:F2}MB, PM={1:F2}MB, CPU={2:F3}s" -f ($memoryAfterWS/1MB), ($memoryAfterPM/1MB), $cpuAfter.TotalSeconds)
    }

    # Calculs finaux
    $executionTimeS = if ($elapsedTime) { $elapsedTime.TotalSeconds } else { -1 }
    $cpuTimeS = ($cpuAfter - $cpuBefore).TotalSeconds
    if ($cpuTimeS -lt 0) { $cpuTimeS = 0 } # Correction de prÃƒÂ©cision

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
        ErrorRecord          = $errorRecord # Pour analyse en mÃƒÂ©moire, pas pour JSON simple
    }

    $statusColor = if ($success) { "Green" } else { "Red" }
    Write-Host ("  ItÃƒÂ©ration {0}: Temps={1:F3}s, CPU={2:F3}s, WS={3:F2}MB ({4:+#.##;-#.##;0.00}MB), PM={5:F2}MB ({6:+#.##;-#.##;0.00}MB), SuccÃƒÂ¨s={7}" -f `
        $IterationNumber, $iterationResult.ExecutionTimeS, $iterationResult.ProcessorTimeS,
        $iterationResult.WorkingSetMB, $iterationResult.DeltaWorkingSetMB,
        $iterationResult.PrivateMemoryMB, $iterationResult.DeltaPrivateMemoryMB,
        $success) -ForegroundColor $statusColor

    Write-Progress @progressParams -PercentComplete ($IterationNumber / $TotalIterationsCount * 100) -CurrentOperation "TerminÃƒÂ©"
    if ($IterationNumber -eq $TotalIterationsCount) { Write-Progress @progressParams -Completed }

    return $iterationResult
}

# --- Fonction pour gÃƒÂ©nÃƒÂ©rer le rapport HTML ---
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

    Write-Host "GÃƒÂ©nÃƒÂ©ration du rapport HTML : $ReportPath" -ForegroundColor Cyan

    $validDetailedResults = $DetailedResults | Where-Object { $_ -ne $null }
    if ($validDetailedResults.Count -eq 0) {
        Write-Warning "Aucune donnÃƒÂ©e dÃƒÂ©taillÃƒÂ©e valide pour gÃƒÂ©nÃƒÂ©rer le rapport HTML."
        # On pourrait ÃƒÂ©crire un fichier HTML minimal ici pour indiquer l'erreur.
        return
    }

    # Helper pour formater les donnÃƒÂ©es JS (ÃƒÂ©vite les erreurs avec des noms contenant des quotes)
    $jsData = { param($data) ($data | ConvertTo-Json -Compress -Depth 1) }
    $jsLabels = & $jsData -data ($validDetailedResults | ForEach-Object { "ItÃƒÂ©ration $($_.Iteration)" })
    $jsExecTimes = & $jsData -data ($validDetailedResults | ForEach-Object { [Math]::Round($_.ExecutionTimeS, 5) })
    $jsCpuTimes = & $jsData -data ($validDetailedResults | ForEach-Object { [Math]::Round($_.ProcessorTimeS, 5) })
    $jsWsMem = & $jsData -data ($validDetailedResults | ForEach-Object { $_.WorkingSetMB })
    $jsPmMem = & $jsData -data ($validDetailedResults | ForEach-Object { $_.PrivateMemoryMB })
    $jsDeltaWs = & $jsData -data ($validDetailedResults | ForEach-Object { $_.DeltaWorkingSetMB })
    $jsDeltaPm = & $jsData -data ($validDetailedResults | ForEach-Object { $_.DeltaPrivateMemoryMB })

    $paramsHtml = "<i>Aucun paramÃƒÂ¨tre spÃƒÂ©cifiÃƒÂ©</i>"
    if ($ParametersUsed -and $ParametersUsed.Count -gt 0) {
        $paramsHtml = ($ParametersUsed.GetEnumerator() | ForEach-Object { "<li><strong>$($_.Name):</strong> <span class='param-value'>$($_.Value | Out-String -Width 100)</span></li>" }) -join ""
        $paramsHtml = "<ul>$paramsHtml</ul>"
    }
    $dataPathInfo = if (-not [string]::IsNullOrEmpty($DataPathUsed)) { "<code class='param-value'>$DataPathUsed</code>" } else { "<i>Non spÃƒÂ©cifiÃƒÂ© ou non applicable</i>" }
    $gcStatus = if ($ExplicitGCDisabled) { "DÃƒÂ©sactivÃƒÂ© (<span class='param-value'>-NoGarbageCollection</span>)" } else { "ActivÃƒÂ© (par dÃƒÂ©faut)" }

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
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script> <!-- Version CDN mise ÃƒÂ  jour -->
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
        <h2>Contexte d'ExÃƒÂ©cution</h2>
        <p><span class="metric-label">GÃƒÂ©nÃƒÂ©rÃƒÂ© le:</span> $($SummaryResults.Timestamp.ToString("yyyy-MM-dd 'ÃƒÂ ' HH:mm:ss"))</p>
        <p><span class="metric-label">ItÃƒÂ©rations:</span> $($SummaryResults.TotalIterations) (RÃƒÂ©ussies: $($SummaryResults.SuccessfulIterations))</p>
        <p><span class="metric-label">DonnÃƒÂ©es de Test:</span> $dataPathInfo</p>
        <p><span class="metric-label">GC Explicite:</span> $gcStatus</p>
        <h3>ParamÃƒÂ¨tres du ScriptBlock :</h3>
        $paramsHtml
    </div>

    <div class="section" id="summary">
        <h2>RÃƒÂ©sumÃƒÂ© des Performances (BasÃƒÂ© sur $($SummaryResults.ResultsAnalyzed))</h2>
        <table class="summary-table">
            <thead><tr><th>MÃƒÂ©trique</th><th>Moyenne</th><th>Minimum</th><th>Maximum</th><th>Total</th><th>Taux SuccÃƒÂ¨s</th></tr></thead>
            <tbody>
                <tr><td class='metric-label'>Temps Ãƒâ€°coulÃƒÂ© (s)</td><td>$($SummaryResults.AverageExecutionTimeS.ToString('F5'))</td><td>$($SummaryResults.MinExecutionTimeS.ToString('F5'))</td><td>$($SummaryResults.MaxExecutionTimeS.ToString('F5'))</td><td>$($SummaryResults.TotalExecutionTimeS.ToString('F3'))</td><td rowspan="5" style="vertical-align: middle; text-align: center; font-size: 1.4em; font-weight: bold;">$($SummaryResults.SuccessRatePercent.ToString('F1')) %</td></tr>
                <tr><td class='metric-label'>Temps CPU (s)</td><td>$($SummaryResults.AverageProcessorTimeS.ToString('F5'))</td><td>$($SummaryResults.MinProcessorTimeS.ToString('F5'))</td><td>$($SummaryResults.MaxProcessorTimeS.ToString('F5'))</td><td>$($SummaryResults.TotalProcessorTimeS.ToString('F3'))</td></tr>
                <tr><td class='metric-label'>Working Set (MB)</td><td>$($SummaryResults.AverageWorkingSetMB.ToString('F2'))</td><td>$($SummaryResults.MinWorkingSetMB.ToString('F2'))</td><td>$($SummaryResults.MaxWorkingSetMB.ToString('F2'))</td><td>-</td></tr>
                <tr><td class='metric-label'>MÃƒÂ©moire PrivÃƒÂ©e (MB)</td><td>$($SummaryResults.AveragePrivateMemoryMB.ToString('F2'))</td><td>$($SummaryResults.MinPrivateMemoryMB.ToString('F2'))</td><td>$($SummaryResults.MaxPrivateMemoryMB.ToString('F2'))</td><td>-</td></tr>
                <tr><td class='metric-label'>Delta MÃƒÂ©moire PrivÃƒÂ©e (MB)</td><td>$($SummaryResults.AverageDeltaPrivateMemoryMB.ToString('F2'))</td><td>$($SummaryResults.MinDeltaPrivateMemoryMB.ToString('F2'))</td><td>$($SummaryResults.MaxDeltaPrivateMemoryMB.ToString('F2'))</td><td>-</td></tr>
            </tbody>
        </table>
        <p class="notes"><i>Note: Les statistiques (Moy, Min, Max) sont calculÃƒÂ©es sur les itÃƒÂ©rations rÃƒÂ©ussies si disponibles ($($SummaryResults.SuccessfulIterations)), sinon sur toutes ($($SummaryResults.TotalIterations)). Delta MÃƒÂ©moire PrivÃƒÂ©e est le changement moyen de mÃƒÂ©moire privÃƒÂ©e pendant une itÃƒÂ©ration rÃƒÂ©ussie.</i></p>
    </div>

    <div class="section" id="details">
        <h2>RÃƒÂ©sultats DÃƒÂ©taillÃƒÂ©s par ItÃƒÂ©ration</h2>
        <table class="details-table">
         <thead><tr><th>ItÃƒÂ©ration</th><th>SuccÃƒÂ¨s</th><th>Temps Exec (s)</th><th>Temps CPU (s)</th><th>WS (MB)</th><th>PM (MB)</th><th>Delta WS (MB)</th><th>Delta PM (MB)</th><th>Message d'Erreur</th></tr></thead>
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
        scales: { x: { title: { display: true, text: 'ItÃƒÂ©ration', font: { size: 14 } } }, y: { beginAtZero: true, title: { display: true, font: { size: 14 } } } },
        responsive: true, maintainAspectRatio: false, interaction: { intersect: false, mode: 'index' },
        plugins: { legend: { position: 'top', labels: { font: { size: 13 } } }, title: { display: true, font: { size: 18, weight: 'bold' } } }
    };
    const createChart = (canvasId, config) => { if (document.getElementById(canvasId)) { new Chart(document.getElementById(canvasId).getContext('2d'), config); }};

    // Time Chart
    createChart('timeChart', { type: 'line', data: { labels: iterationLabels, datasets: [
        { label: 'Temps Ãƒâ€°coulÃƒÂ© (s)', data: $jsExecTimes, borderColor: 'rgb(220, 53, 69)', backgroundColor: 'rgba(220, 53, 69, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 },
        { label: 'Temps CPU (s)', data: $jsCpuTimes, borderColor: 'rgb(13, 110, 253)', backgroundColor: 'rgba(13, 110, 253, 0.1)', yAxisID: 'yTime', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonOptions, plugins: { ...commonOptions.plugins, title: { ...commonOptions.plugins.title, text: 'Temps d\'ExÃƒÂ©cution et CPU par ItÃƒÂ©ration'} }, scales: { ...commonOptions.scales, yTime: { ...commonOptions.scales.y, title: { ...commonOptions.scales.y.title, text: 'Secondes'}}} }
    });

    // Memory Chart
    createChart('memoryChart', { type: 'line', data: { labels: iterationLabels, datasets: [
        { label: 'Working Set (MB)', data: $jsWsMem, borderColor: 'rgb(25, 135, 84)', backgroundColor: 'rgba(25, 135, 84, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 },
        { label: 'MÃƒÂ©moire PrivÃƒÂ©e (MB)', data: $jsPmMem, borderColor: 'rgb(108, 117, 125)', backgroundColor: 'rgba(108, 117, 125, 0.1)', yAxisID: 'yMemory', tension: 0.1, borderWidth: 2 } ] },
        options: { ...commonOptions, plugins: { ...commonOptions.plugins, title: { ...commonOptions.plugins.title, text: 'Utilisation MÃƒÂ©moire Finale par ItÃƒÂ©ration'} }, scales: { ...commonOptions.scales, yMemory: { ...commonOptions.scales.y, title: { ...commonOptions.scales.y.title, text: 'MB'}}} }
    });

    // Delta Memory Chart
    createChart('deltaMemoryChart', { type: 'bar', data: { labels: iterationLabels, datasets: [
        { label: 'Delta Working Set (MB)', data: $jsDeltaWs, backgroundColor: 'rgba(255, 193, 7, 0.6)', borderColor: 'rgb(255, 193, 7)', borderWidth: 1, yAxisID: 'yDeltaMemory' },
        { label: 'Delta MÃƒÂ©moire PrivÃƒÂ©e (MB)', data: $jsDeltaPm, backgroundColor: 'rgba(255, 159, 64, 0.6)', borderColor: 'rgb(255, 159, 64)', borderWidth: 1, yAxisID: 'yDeltaMemory' } ] },
        options: { ...commonOptions, scales: { ...commonOptions.scales, y: null, yDeltaMemory: { beginAtZero: false, position: 'left', title: { display: true, text: 'Changement de MÃƒÂ©moire (MB)', font: { size: 14 } }}}, plugins: { ...commonOptions.plugins, title: { ...commonOptions.plugins.title, text: 'Variation de MÃƒÂ©moire par ItÃƒÂ©ration'} } }
    });
</script>
</div> <!-- /container -->
</body>
</html>
"@

    try {
        $htmlContent | Out-File -FilePath $ReportPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Host "Rapport HTML gÃƒÂ©nÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s : $ReportPath" -ForegroundColor Green
    } catch {
        Write-Error "Erreur critique lors de la sauvegarde du rapport HTML '$ReportPath': $($_.Exception.Message)"
    }
}

#endregion

#region Validation and Initialization

Write-Host "=== Initialisation Test de Performance : $TestName ===" -ForegroundColor White -BackgroundColor DarkBlue
$startTimestamp = Get-Date
$global:StopRequested = $false # Variable globale pour interruption propre si nÃƒÂ©cessaire

# Nettoyer TestName pour l'utilisation dans les chemins
$safeTestNameForPath = $TestName -replace '[^a-zA-Z0-9_.-]+', '_' -replace '^[_.-]+|[_.-]+$' # EnlÃƒÂ¨ve non-alphanum, remplace par _, trim underscores/points/tirets dÃƒÂ©but/fin
if ([string]::IsNullOrWhiteSpace($safeTestNameForPath)) { $safeTestNameForPath = "UnnamedTest" }

# CrÃƒÂ©er le rÃƒÂ©pertoire de sortie unique pour cette exÃƒÂ©cution
$testSpecificSubDir = "Benchmark_$($safeTestNameForPath)_$($startTimestamp.ToString('yyyyMMddHHmmss'))"
$testOutputPath = $null
$actualTestDataPath = $null # Chemin effectif des donnÃƒÂ©es de test utilisÃƒÂ©es
$testDataStatus = "Non applicable"

try {
    # RÃƒÂ©soudre le chemin de sortie de base
    $resolvedOutputPath = Resolve-Path -Path $OutputPath -ErrorAction SilentlyContinue
    if (-not $resolvedOutputPath) {
        if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃƒÂ©er le rÃƒÂ©pertoire de sortie principal (n'existe pas)")) {
            $createdDir = New-Item -Path $OutputPath -ItemType Directory -Force -ErrorAction Stop
            $resolvedOutputPath = $createdDir.FullName
            Write-Verbose "RÃƒÂ©pertoire de sortie principal crÃƒÂ©ÃƒÂ© : $resolvedOutputPath"
        } else {
            Write-Error "CrÃƒÂ©ation du rÃƒÂ©pertoire de sortie principal annulÃƒÂ©e par l'utilisateur. ArrÃƒÂªt."
            return # Exit
        }
    } elseif ( -not (Test-Path $resolvedOutputPath -PathType Container)) {
         Write-Error "Le chemin de sortie principal '$resolvedOutputPath' existe mais n'est pas un rÃƒÂ©pertoire. ArrÃƒÂªt."
         return # Exit
    } else {
         Write-Verbose "RÃƒÂ©pertoire de sortie principal trouvÃƒÂ©: $resolvedOutputPath"
    }

    # CrÃƒÂ©er le sous-rÃƒÂ©pertoire spÃƒÂ©cifique au test
    $testOutputPath = Join-Path -Path $resolvedOutputPath -ChildPath $testSpecificSubDir
    if ($PSCmdlet.ShouldProcess($testOutputPath, "CrÃƒÂ©er le sous-rÃƒÂ©pertoire pour les rÃƒÂ©sultats du test '$TestName'")) {
        New-Item -Path $testOutputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Host "RÃƒÂ©pertoire de sortie pour ce test : $testOutputPath" -ForegroundColor Green
    } else {
        Write-Error "CrÃƒÂ©ation du sous-rÃƒÂ©pertoire de sortie spÃƒÂ©cifique au test annulÃƒÂ©e. ArrÃƒÂªt."
        return # Exit
    }
} catch {
    Write-Error "Impossible de crÃƒÂ©er les rÃƒÂ©pertoires de sortie. Chemin de base: '$OutputPath'. Erreur: $($_.Exception.Message). VÃƒÂ©rifiez les permissions. ArrÃƒÂªt."
    return # Exit
}

# Gestion des donnÃƒÂ©es de test
if (-not [string]::IsNullOrEmpty($TestDataPath)) {
    $resolvedTestDataPath = Resolve-Path -Path $TestDataPath -ErrorAction SilentlyContinue
    if ($resolvedTestDataPath -and (Test-Path $resolvedTestDataPath -PathType Container)) {
        $actualTestDataPath = $resolvedTestDataPath.Path
        $testDataStatus = "Utilisation des donnÃƒÂ©es fournies: $actualTestDataPath"
        Write-Verbose $testDataStatus
    } else {
        Write-Warning "Le chemin TestDataPath fourni ('$TestDataPath') n'existe pas ou n'est pas un rÃƒÂ©pertoire. Tentative de gÃƒÂ©nÃƒÂ©ration si New-TestData.ps1 existe."
        # Ne pas ÃƒÂ©craser $actualTestDataPath ici, on va vÃƒÂ©rifier New-TestData.ps1
    }
}

# Tenter la gÃƒÂ©nÃƒÂ©ration seulement si TestDataPath n'est pas valide/fourni OU si on force
if (-not $actualTestDataPath -or $ForceTestDataGeneration) {
    $testDataScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-TestData.ps1"
    if (Test-Path $testDataScriptPath -PathType Leaf) {
        $targetGeneratedDataPath = Join-Path -Path $testOutputPath -ChildPath "generated_test_data"
        $generate = $false
        if (-not (Test-Path -Path $targetGeneratedDataPath -PathType Container)) {
            $generate = $true
            Write-Verbose "Le rÃƒÂ©pertoire de donnÃƒÂ©es gÃƒÂ©nÃƒÂ©rÃƒÂ©es '$targetGeneratedDataPath' n'existe pas, gÃƒÂ©nÃƒÂ©ration planifiÃƒÂ©e."
        } elseif ($ForceTestDataGeneration) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "Supprimer et RegÃƒÂ©nÃƒÂ©rer les donnÃƒÂ©es de test (option -ForceTestDataGeneration)")) {
                Write-Verbose "ForÃƒÂ§age de la regÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test."
                try { Remove-Item -Path $targetGeneratedDataPath -Recurse -Force -ErrorAction Stop } catch { Write-Warning "Impossible de supprimer l'ancien dossier de donnÃƒÂ©es '$targetGeneratedDataPath': $($_.Exception.Message)"}
                $generate = $true
            } else {
                Write-Warning "RegÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test annulÃƒÂ©e par l'utilisateur. Utilisation des donnÃƒÂ©es existantes."
                $actualTestDataPath = $targetGeneratedDataPath # On utilise quand mÃƒÂªme les anciennes
                $testDataStatus = "Utilisation des donnÃƒÂ©es existantes (regÃƒÂ©nÃƒÂ©ration annulÃƒÂ©e): $actualTestDataPath"
            }
        } else {
            # Le dossier existe et on ne force pas -> utiliser l'existant
             $actualTestDataPath = $targetGeneratedDataPath
             $testDataStatus = "Utilisation des donnÃƒÂ©es prÃƒÂ©cÃƒÂ©demment gÃƒÂ©nÃƒÂ©rÃƒÂ©es: $actualTestDataPath"
             Write-Verbose $testDataStatus
        }

        if ($generate) {
            if ($PSCmdlet.ShouldProcess($targetGeneratedDataPath, "GÃƒÂ©nÃƒÂ©rer les donnÃƒÂ©es de test via New-TestData.ps1")) {
                Write-Host "GÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test dans '$targetGeneratedDataPath'..." -ForegroundColor Yellow
                try {
                    $genParams = @{ OutputPath = $targetGeneratedDataPath; ErrorAction = 'Stop'}
                    if($ForceTestDataGeneration) { $genParams.Force = $true } # Passer Force ÃƒÂ  New-TestData si besoin
                    $generatedPath = & $testDataScriptPath @genParams

                    if ($generatedPath -and (Test-Path $generatedPath -PathType Container)) {
                        $actualTestDataPath = $generatedPath # Mise ÃƒÂ  jour du chemin effectif
                        $testDataStatus = "DonnÃƒÂ©es gÃƒÂ©nÃƒÂ©rÃƒÂ©es avec succÃƒÂ¨s: $actualTestDataPath"
                        Write-Host $testDataStatus -ForegroundColor Green
                        # Tenter de mettre ÃƒÂ  jour $Parameters si une clÃƒÂ© commune existe (convention)
                        $commonDataParamNames = 'InputPath', 'SourcePath', 'InputDirectory', 'DataPath', 'ScriptsPath' # ClÃƒÂ©s courantes
                        foreach ($paramName in $commonDataParamNames) {
                            if ($Parameters.ContainsKey($paramName)) {
                                Write-Verbose "Mise ÃƒÂ  jour du paramÃƒÂ¨tre '$paramName' avec le chemin des donnÃƒÂ©es gÃƒÂ©nÃƒÂ©rÃƒÂ©es."
                                $Parameters[$paramName] = $actualTestDataPath
                                break # ArrÃƒÂªter aprÃƒÂ¨s la premiÃƒÂ¨re correspondance trouvÃƒÂ©e
                            }
                        }
                        if (-not $Parameters.ContainsKey($paramName)) {
                            Write-Warning "DonnÃƒÂ©es gÃƒÂ©nÃƒÂ©rÃƒÂ©es dans '$actualTestDataPath', mais aucun paramÃƒÂ¨tre standard ($($commonDataParamNames -join '/')) trouvÃƒÂ© dans -Parameters pour injecter ce chemin automatiquement. Assurez-vous que votre -ScriptBlock y accÃƒÂ¨de correctement."
                        }
                    } else {
                        Write-Error "La gÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test via New-TestData.ps1 a ÃƒÂ©chouÃƒÂ© ou n'a pas retournÃƒÂ© de chemin valide."
                        $testDataStatus = "Ãƒâ€°chec de la gÃƒÂ©nÃƒÂ©ration."
                    }
                } catch {
                    Write-Error "Erreur critique lors de l'appel ÃƒÂ  New-TestData.ps1: $($_.Exception.Message)"
                    $testDataStatus = "Ãƒâ€°chec critique de la gÃƒÂ©nÃƒÂ©ration."
                }
            } else {
                 Write-Warning "GÃƒÂ©nÃƒÂ©ration des donnÃƒÂ©es de test annulÃƒÂ©e par l'utilisateur."
                 $testDataStatus = "GÃƒÂ©nÃƒÂ©ration annulÃƒÂ©e."
                 # Si le dossier existait avant l'annulation, on l'utilise quand mÃƒÂªme
                 if ($actualTestDataPath -eq $targetGeneratedDataPath) {
                    $testDataStatus += " Utilisation des donnÃƒÂ©es prÃƒÂ©-existantes."
                 }
            }
        }
    } elseif (-not $actualTestDataPath) { # Si pas de chemin explicite et pas de New-TestData.ps1
        $testDataStatus = "Non requis/gÃƒÂ©rÃƒÂ© (TestDataPath non fourni/valide et New-TestData.ps1 non trouvÃƒÂ©)."
        Write-Verbose $testDataStatus
    }
}

# Afficher les paramÃƒÂ¨tres finaux (aprÃƒÂ¨s mise ÃƒÂ  jour potentielle par la gÃƒÂ©nÃƒÂ©ration de donnÃƒÂ©es)
Write-Verbose "ParamÃƒÂ¨tres finaux passÃƒÂ©s au ScriptBlock pour chaque itÃƒÂ©ration:"
Write-Verbose ($Parameters | Out-String)

#endregion

#region Main Execution Logic

Write-Host "`n=== DÃƒÂ©marrage des $Iterations ItÃƒÂ©rations ($($startTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor Cyan

$allIterationResults = [System.Collections.Generic.List[PSCustomObject]]::new()

# Enregistrer l'ÃƒÂ©tat initial de la console pour restauration
# $initialConsoleState = $Host.UI.RawUI

# Gestion de l'interruption (Ctrl+C)
# Note: Ceci est basique et peut ne pas intercepter toutes les formes d'arrÃƒÂªt.
# L'utilisation de Runspaces ou Jobs offrirait un contrÃƒÂ´le plus fin.
# $tokenSource = [System.Threading.CancellationTokenSource]::new()
# $Host.Runspace.Events.SubscribeEvent($Host, "CancelEvent", {
#    Write-Warning "Interruption demandÃƒÂ©e (Ctrl+C). ArrÃƒÂªt aprÃƒÂ¨s l'itÃƒÂ©ration en cours..."
#    $global:StopRequested = $true
#    # $tokenSource.Cancel() # NÃƒÂ©cessiterait que le ScriptBlock gÃƒÂ¨re le token
# }) | Out-Null

try {
    # Boucle d'exÃƒÂ©cution des itÃƒÂ©rations
    foreach ($i in 1..$Iterations) {
        if ($global:StopRequested) {
            Write-Warning "ExÃƒÂ©cution interrompue avant l'itÃƒÂ©ration $i."
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
    # Nettoyage: DÃƒÂ©sabonnement de l'ÃƒÂ©vÃƒÂ©nement Ctrl+C si utilisÃƒÂ©
    # $Host.Runspace.Events.UnsubscribeEvent($subscriptionId) # NÃƒÂ©cessite de stocker l'ID
    # $tokenSource.Dispose()
    # Restaurer l'ÃƒÂ©tat de la console si modifiÃƒÂ©
    # $Host.UI.RawUI = $initialConsoleState
    Write-Progress -Activity "Test de Performance: $TestName" -Completed # Assurer la fermeture de la barre
}

#endregion

#region Results Aggregation and Output

Write-Host "`n=== Calcul des Statistiques AgrÃƒÂ©gÃƒÂ©es ($($allIterationResults.Count) itÃƒÂ©rations exÃƒÂ©cutÃƒÂ©es) ===" -ForegroundColor Cyan
$finalResultsArray = $allIterationResults.ToArray()

$successfulIterations = ($finalResultsArray | Where-Object { $_.Success }).Count
$failedIterations = $finalResultsArray.Count - $successfulIterations

$resultsToAnalyze = $finalResultsArray | Where-Object { $_.Success }
$analysisSource = "ItÃƒÂ©rations RÃƒÂ©ussies ($successfulIterations)"
if ($successfulIterations -eq 0 -and $finalResultsArray.Count -gt 0) {
    Write-Warning "Aucune itÃƒÂ©ration n'a rÃƒÂ©ussi ! Les statistiques (sauf taux de succÃƒÂ¨s) seront basÃƒÂ©es sur les $($finalResultsArray.Count) tentatives."
    $resultsToAnalyze = $finalResultsArray
    $analysisSource = "Toutes les ItÃƒÂ©rations ($($finalResultsArray.Count)) - Attention: ÃƒÂ©checs inclus"
} elseif ($finalResultsArray.Count -eq 0) {
     Write-Warning "Aucune itÃƒÂ©ration n'a ÃƒÂ©tÃƒÂ© exÃƒÂ©cutÃƒÂ©e (ou interrompue avant la premiÃƒÂ¨re)."
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
    # Arrondir les moyennes mÃƒÂ©moire
    $metrics.WorkingSetMB.Average = [Math]::Round($metrics.WorkingSetMB.Average, 2)
    $metrics.PrivateMemoryMB.Average = [Math]::Round($metrics.PrivateMemoryMB.Average, 2)
    $metrics.DeltaPrivateMemoryMB.Average = [Math]::Round($metrics.DeltaPrivateMemoryMB.Average, 2)
}

# Construire l'objet rÃƒÂ©sumÃƒÂ© final
$summaryResults = [PSCustomObject]@{
    TestName                   = $TestName
    Timestamp                  = $startTimestamp
    TotalIterationsAttempted   = $finalResultsArray.Count # Nombre rÃƒÂ©ellement tentÃƒÂ©
    TotalIterationsRequested   = $Iterations # Nombre demandÃƒÂ© initialement
    SuccessfulIterations       = $successfulIterations
    FailedIterations           = $failedIterations
    SuccessRatePercent         = if ($finalResultsArray.Count -gt 0) { [Math]::Round(($successfulIterations / $finalResultsArray.Count * 100), 1) } else { 0 }
    ResultsAnalyzed            = $analysisSource
    # Temps Ãƒâ€°coulÃƒÂ©
    AverageExecutionTimeS      = $metrics.ExecutionTimeS.Average
    MinExecutionTimeS          = $metrics.ExecutionTimeS.Minimum
    MaxExecutionTimeS          = $metrics.ExecutionTimeS.Maximum
    TotalExecutionTimeS        = $metrics.ExecutionTimeS.Sum
    # Temps CPU
    AverageProcessorTimeS      = $metrics.ProcessorTimeS.Average
    MinProcessorTimeS          = $metrics.ProcessorTimeS.Minimum
    MaxProcessorTimeS          = $metrics.ProcessorTimeS.Maximum
    TotalProcessorTimeS        = $metrics.ProcessorTimeS.Sum
    # MÃƒÂ©moire Working Set
    AverageWorkingSetMB        = $metrics.WorkingSetMB.Average
    MinWorkingSetMB            = $metrics.WorkingSetMB.Minimum
    MaxWorkingSetMB            = $metrics.WorkingSetMB.Maximum
    # MÃƒÂ©moire PrivÃƒÂ©e
    AveragePrivateMemoryMB     = $metrics.PrivateMemoryMB.Average
    MinPrivateMemoryMB         = $metrics.PrivateMemoryMB.Minimum
    MaxPrivateMemoryMB         = $metrics.PrivateMemoryMB.Maximum
    # Delta MÃƒÂ©moire PrivÃƒÂ©e
    AverageDeltaPrivateMemoryMB= $metrics.DeltaPrivateMemoryMB.Average
    MinDeltaPrivateMemoryMB    = $metrics.DeltaPrivateMemoryMB.Minimum
    MaxDeltaPrivateMemoryMB    = $metrics.DeltaPrivateMemoryMB.Maximum
    # Contexte
    ParametersUsed             = $Parameters
    TestDataPathUsed           = $actualTestDataPath
    ExplicitGCDisabled         = $NoGarbageCollection.IsPresent
    OutputDirectory            = $testOutputPath # Ajouter le chemin de sortie au rÃƒÂ©sumÃƒÂ©
}

# Afficher le rÃƒÂ©sumÃƒÂ© console
Write-Host "`n--- RÃƒÂ©sumÃƒÂ© Final : $TestName ---" -ForegroundColor White -BackgroundColor DarkMagenta
Write-Host "  ItÃƒÂ©rations TentÃƒÂ©es/DemandÃƒÂ©es : $($summaryResults.TotalIterationsAttempted) / $($summaryResults.TotalIterationsRequested) (SuccÃƒÂ¨s: $successfulIterations, Ãƒâ€°checs: $failedIterations, Taux: $($summaryResults.SuccessRatePercent)%)"
Write-Host "  Statistiques basÃƒÂ©es sur      : $($summaryResults.ResultsAnalyzed)"
Write-Host "  Temps Ãƒâ€°coulÃƒÂ© (s)  (Avg/Min/Max) : $($summaryResults.AverageExecutionTimeS.ToString('F5')) / $($summaryResults.MinExecutionTimeS.ToString('F5')) / $($summaryResults.MaxExecutionTimeS.ToString('F5'))"
Write-Host "  Temps CPU (s)     (Avg/Min/Max) : $($summaryResults.AverageProcessorTimeS.ToString('F5')) / $($summaryResults.MinProcessorTimeS.ToString('F5')) / $($summaryResults.MaxProcessorTimeS.ToString('F5'))"
Write-Host "  Working Set (MB)  (Avg/Min/Max) : $($summaryResults.AverageWorkingSetMB.ToString('F2')) / $($summaryResults.MinWorkingSetMB.ToString('F2')) / $($summaryResults.MaxWorkingSetMB.ToString('F2'))"
Write-Host "  Private Mem (MB)  (Avg/Min/Max) : $($summaryResults.AveragePrivateMemoryMB.ToString('F2')) / $($summaryResults.MinPrivateMemoryMB.ToString('F2')) / $($summaryResults.MaxPrivateMemoryMB.ToString('F2'))"
Write-Host "  Delta PM (MB)     (Avg/Min/Max) : $($summaryResults.AverageDeltaPrivateMemoryMB.ToString('F2')) / $($summaryResults.MinDeltaPrivateMemoryMB.ToString('F2')) / $($summaryResults.MaxDeltaPrivateMemoryMB.ToString('F2'))"
Write-Host "  RÃƒÂ©sultats sauvegardÃƒÂ©s dans     : $testOutputPath"

# Enregistrer les rÃƒÂ©sultats JSON
$resultsJsonFileName = "Benchmark_Results_$($safeTestNameForPath).json"
$resultsJsonPath = Join-Path -Path $testOutputPath -ChildPath $resultsJsonFileName
$outputDataForJson = @{
    Summary = $summaryResults
    DetailedResults = $finalResultsArray | Select-Object -ExcludeProperty ErrorRecord
}
try {
    ConvertTo-Json -InputObject $outputDataForJson -Depth 5 | Out-File -FilePath $resultsJsonPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "RÃƒÂ©sultats complets enregistrÃƒÂ©s (JSON) : $resultsJsonPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur critique lors de l'enregistrement des rÃƒÂ©sultats JSON '$resultsJsonPath': $($_.Exception.Message)"
}

# GÃƒÂ©nÃƒÂ©rer le rapport HTML si demandÃƒÂ© et si des rÃƒÂ©sultats existent
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
        ErrorAction        = 'Continue' # Ne pas bloquer si la gÃƒÂ©nÃƒÂ©ration du rapport ÃƒÂ©choue
    }
    New-BenchmarkHtmlReport @reportParams
} elseif ($GenerateReport) {
    Write-Warning "GÃƒÂ©nÃƒÂ©ration du rapport HTML ignorÃƒÂ©e car aucune itÃƒÂ©ration n'a ÃƒÂ©tÃƒÂ© exÃƒÂ©cutÃƒÂ©e."
}

$endTimestamp = Get-Date
$totalDuration = $endTimestamp - $startTimestamp
Write-Host "`n=== Test de Performance '$TestName' TerminÃƒÂ© ($($endTimestamp.ToString('HH:mm:ss'))) ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "DurÃƒÂ©e totale du script de test : $($totalDuration.ToString('g'))"

# Retourner l'objet rÃƒÂ©sumÃƒÂ© final
return $summaryResults

#endregion