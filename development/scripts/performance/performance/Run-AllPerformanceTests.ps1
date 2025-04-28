#Requires -Version 5.1
<#
.SYNOPSIS
    Orchestre l'exÃ©cution de plusieurs suites de tests de performance PowerShell et Python.
.DESCRIPTION
    Ce script sert de point d'entrÃ©e pour exÃ©cuter une collection dÃ©finie de scripts de benchmark
    (par exemple, tests gÃ©nÃ©raux, optimisation de taille de lot, optimisation mÃ©moire).
    Il collecte les rÃ©sultats de chaque suite de tests, enregistre un rÃ©sumÃ© global en JSON,
    et peut gÃ©nÃ©rer un rapport HTML consolidÃ© avec des liens vers les rapports individuels.

    Le script est conÃ§u pour Ãªtre configurable via la section 'Configuration des Tests'.
    Il gÃ¨re la crÃ©ation des rÃ©pertoires de sortie, la validation des dÃ©pendances (scripts de benchmark),
    et l'invocation structurÃ©e de chaque test dÃ©fini.
.PARAMETER OutputPath
    RÃ©pertoire racine oÃ¹ tous les rÃ©sultats des tests seront stockÃ©s.
    Un sous-rÃ©pertoire sera crÃ©Ã© pour chaque test individuel.
    Par dÃ©faut: '.\results' relatif au script.
.PARAMETER GenerateReport
    Si spÃ©cifiÃ© ($true), gÃ©nÃ¨re un rapport HTML global rÃ©capitulant tous les tests exÃ©cutÃ©s
    et fournit des liens vers les rapports HTML spÃ©cifiques de chaque test (s'ils existent).
.PARAMETER TestNameFilter
    [Optionnel] Permet d'exÃ©cuter uniquement les tests dont le nom contient cette chaÃ®ne (insensible Ã  la casse).
    Utile pour cibler des tests spÃ©cifiques. Exemple: -TestNameFilter "BatchSize".
.PARAMETER Force
    [Optionnel] UtilisÃ© pour forcer certaines opÃ©rations, comme la recrÃ©ation de donnÃ©es de test
    si les scripts de benchmark sous-jacents le supportent (passÃ© via les paramÃ¨tres).
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un rÃ©pertoire de donnÃ©es de test commun Ã  utiliser par les diffÃ©rents benchmarks.
    Sera injectÃ© dans les paramÃ¨tres de base des tests si le paramÃ¨tre 'TestDataParameterName' est dÃ©fini
    dans la configuration du test.
.PARAMETER MaxWorkersOverride
    [Optionnel] Permet de surcharger la valeur de 'MaxWorkers' (ou Ã©quivalent) dans tous les tests
    qui dÃ©finissent un 'WorkerParameterName'. Utile pour tester rapidement l'impact global
    d'un changement du nombre de workers.
.EXAMPLE
    # ExÃ©cuter tous les tests dÃ©finis et gÃ©nÃ©rer un rapport HTML global
    .\Run-AllPerformanceTests.ps1 -GenerateReport -Verbose

.EXAMPLE
    # ExÃ©cuter uniquement les tests contenant "Memory" dans leur nom, dans un rÃ©pertoire spÃ©cifique
    .\Run-AllPerformanceTests.ps1 -OutputPath "C:\PerfReports\MemoryTests" -TestNameFilter "Memory" -Verbose

.EXAMPLE
    # ExÃ©cuter tous les tests en forÃ§ant la regÃ©nÃ©ration des donnÃ©es de test (si supportÃ© par les tests)
    .\Run-AllPerformanceTests.ps1 -GenerateReport -Force

.EXAMPLE
    # ExÃ©cuter tous les tests en utilisant un jeu de donnÃ©es spÃ©cifique et en limitant les workers Ã  2
    .\Run-AllPerformanceTests.ps1 -GenerateReport -TestDataPath "C:\Path\To\SharedTestData" -MaxWorkersOverride 2

.NOTES
    Auteur     : Votre Nom/Ã‰quipe
    Version    : 2.0
    Date       : 2023-10-27
    DÃ©pendances: Les scripts de benchmark listÃ©s dans la section 'Configuration des Tests'
                 doivent exister aux chemins spÃ©cifiÃ©s.
                 Chart.js (via CDN pour le rapport HTML global et potentiellement les rapports individuels).

    Personnalisation: Modifiez la section '#region Configuration des Tests' pour ajouter,
                      supprimer ou modifier les tests Ã  exÃ©cuter et leurs paramÃ¨tres.
    Rapports Individuels: Ce script suppose que les scripts de benchmark (comme Optimize-*)
                          peuvent gÃ©nÃ©rer leurs propres rapports HTML s'ils sont appelÃ©s avec
                          -GenerateReport. Ce script tentera de lier ces rapports.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $false, HelpMessage = "RÃ©pertoire racine pour les rÃ©sultats des tests.")]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "results"),

    [Parameter(Mandatory = $false, HelpMessage = "GÃ©nÃ©rer un rapport HTML global consolidÃ©.")]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false, HelpMessage = "Filtrer les tests Ã  exÃ©cuter par nom (contient).")]
    [string]$TestNameFilter,

    [Parameter(Mandatory = $false, HelpMessage = "Forcer certaines opÃ©rations (ex: regÃ©nÃ©ration de donnÃ©es).")]
    [switch]$Force,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers les donnÃ©es de test communes (optionnel).")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Surcharger le nombre de workers pour les tests applicables.")]
    [ValidateRange(1, 128)] # Ajuster la limite max si nÃ©cessaire
    [int]$MaxWorkersOverride
)

#region Variables et Fonctions Internes

# Horodatage pour les noms de fichiers uniques
$startTimestamp = Get-Date
$timestampSuffix = $startTimestamp.ToString('yyyyMMddHHmmss')

# --- Fonction pour valider les dÃ©pendances ---
function Test-BenchmarkDependencies {
    param(
        [Parameter(Mandatory = $true)]
        [array]$TestConfigurations
    )
    Write-Verbose "Validation des dÃ©pendances (scripts de benchmark)..."
    $missingDependencies = @()
    $uniqueScriptPaths = $TestConfigurations | Select-Object -ExpandProperty BenchmarkScriptPath -Unique

    foreach ($scriptPath in $uniqueScriptPaths) {
        $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptPath # Suppose qu'ils sont relatifs Ã  ce script
        if (-not (Test-Path -Path $fullPath -PathType Leaf)) {
            $missingDependencies += $fullPath
        } else {
            Write-Verbose "  [OK] DÃ©pendance trouvÃ©e : $fullPath"
        }
    }

    if ($missingDependencies.Count -gt 0) {
        Write-Error "DÃ©pendances manquantes dÃ©tectÃ©es : $($missingDependencies -join ', ')"
        Write-Error "Veuillez vous assurer que tous les scripts de benchmark rÃ©fÃ©rencÃ©s existent. ArrÃªt."
        return $false # Indique un Ã©chec
    }
    Write-Verbose "Toutes les dÃ©pendances des scripts de benchmark sont prÃ©sentes."
    return $true # Indique le succÃ¨s
}

# --- Fonction pour exÃ©cuter un script de benchmark individuel ---
function Invoke-BenchmarkScript {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TestDefinition,

        [Parameter(Mandatory = $true)]
        [string]$GlobalRunOutputPath, # Le dossier racine pour *tous* les tests

        [Parameter(Mandatory = $false)]
        [switch]$EnableReportGeneration, # Si on veut que le benchmark gÃ©nÃ¨re son propre rapport

        [Parameter(Mandatory = $false)]
        [switch]$ForceExecution,

        [Parameter(Mandatory = $false)]
        [string]$GlobalTestDataDirectory, # Chemin fourni Ã  l'orchestrateur

        [Parameter(Mandatory = $false)]
        [int]$WorkerOverride # Valeur fournie Ã  l'orchestrateur
    )

    $testName = $TestDefinition.Name
    $benchmarkScriptRelativePath = $TestDefinition.BenchmarkScriptPath
    $benchmarkScriptFullPath = Join-Path -Path $PSScriptRoot -ChildPath $benchmarkScriptRelativePath
    $testParamsFromConfig = $TestDefinition.Parameters.Clone() # Cloner pour Ã©viter modification accidentelle
    $testDataParamName = $TestDefinition.TestDataParameterName # Nom du paramÃ¨tre pour les donnÃ©es (ex: 'ScriptsPath')
    $workerParamName = $TestDefinition.WorkerParameterName     # Nom du paramÃ¨tre pour les workers (ex: 'MaxWorkers')

    Write-Host "`n=== [$(Get-Date -Format HH:mm:ss)] DÃ©marrage Test : '$testName' ===" -ForegroundColor Cyan
    Write-Verbose "  Script de benchmark : $benchmarkScriptFullPath"

    # CrÃ©er un rÃ©pertoire de sortie dÃ©diÃ© pour ce test
    $testSpecificOutputName = "$($testName -replace '[^a-zA-Z0-9_]', '_')_$timestampSuffix"
    $testSpecificOutputPath = Join-Path -Path $GlobalRunOutputPath -ChildPath $testSpecificOutputName
    try {
        if (-not (Test-Path -Path $testSpecificOutputPath)) {
            if ($PSCmdlet.ShouldProcess($testSpecificOutputPath, "CrÃ©er le rÃ©pertoire de sortie pour le test '$testName'")) {
                New-Item -Path $testSpecificOutputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Write-Verbose "  RÃ©pertoire de sortie crÃ©Ã© : $testSpecificOutputPath"
            } else {
                Write-Warning "CrÃ©ation du rÃ©pertoire de sortie pour '$testName' annulÃ©e. Test sautÃ©."
                return [PSCustomObject]@{
                    Name          = $testName
                    Status        = 'Skipped'
                    StartTime     = (Get-Date)
                    EndTime       = (Get-Date)
                    DurationSec   = 0
                    ResultSummary = $null
                    ErrorRecord   = $null
                    OutputPath    = $testSpecificOutputPath
                    OutputFile    = $null
                }
            }
        }
    } catch {
        Write-Error "Impossible de crÃ©er le rÃ©pertoire de sortie '$testSpecificOutputPath' pour le test '$testName'. Erreur: $($_.Exception.Message). Test sautÃ©."
        # Retourner un objet indiquant l'Ã©chec
        return [PSCustomObject]@{
            Name          = $testName
            Status        = 'FailedSetup'
            StartTime     = (Get-Date)
            EndTime       = (Get-Date)
            DurationSec   = 0
            ResultSummary = $null
            ErrorRecord   = $_
            OutputPath    = $testSpecificOutputPath
            OutputFile    = $null
        }
    }

    # PrÃ©parer les paramÃ¨tres finaux pour le script de benchmark
    $finalBenchmarkParams = @{}
    $finalBenchmarkParams.putAll($testParamsFromConfig) # Copier les paramÃ¨tres de la config du test

    # Ajouter/Modifier le chemin de sortie pour le benchmark
    $finalBenchmarkParams['OutputPath'] = $testSpecificOutputPath

    # Ajouter -GenerateReport si demandÃ© globalement
    if ($EnableReportGeneration) {
        $finalBenchmarkParams['GenerateReport'] = $true
    }

    # Ajouter -Force si demandÃ© globalement
    if ($ForceExecution) {
        $finalBenchmarkParams['Force'] = $true
        # Certains scripts peuvent utiliser un nom diffÃ©rent, ex: ForceTestDataGeneration
        if ($finalBenchmarkParams.ContainsKey('ForceTestDataGeneration') -and !$finalBenchmarkParams.ContainsKey('Force')) {
             $finalBenchmarkParams['ForceTestDataGeneration'] = $true
        }
    }

    # Injecter le chemin des donnÃ©es de test si fourni et si le test est configurÃ© pour l'accepter
    if (-not [string]::IsNullOrEmpty($GlobalTestDataDirectory) -and -not [string]::IsNullOrEmpty($testDataParamName)) {
        if (Test-Path $GlobalTestDataDirectory -PathType Container) {
            Write-Verbose "  Injecting TestDataPath '$GlobalTestDataDirectory' into parameter '$testDataParamName'"
            $finalBenchmarkParams[$testDataParamName] = $GlobalTestDataDirectory
            # GÃ©rer le cas oÃ¹ les donnÃ©es sont dans BaseParameters (pour Optimize-*)
            if ($finalBenchmarkParams.ContainsKey('BaseParameters') -and $finalBenchmarkParams.BaseParameters -is [hashtable]) {
                Write-Verbose "    Injecting into BaseParameters.$testDataParamName as well."
                $finalBenchmarkParams.BaseParameters[$testDataParamName] = $GlobalTestDataDirectory
            }

        } else {
            Write-Warning "Le chemin TestDataPath global '$GlobalTestDataDirectory' n'est pas valide. Il ne sera pas injectÃ© pour le test '$testName'."
        }
    }

    # Appliquer la surcharge du nombre de workers si fournie et applicable
    if ($PSBoundParameters.ContainsKey('WorkerOverride') -and -not [string]::IsNullOrEmpty($workerParamName)) {
         Write-Verbose "  Applying MaxWorkersOverride ($WorkerOverride) to parameter '$workerParamName'"
         $finalBenchmarkParams[$workerParamName] = $WorkerOverride
         # GÃ©rer le cas oÃ¹ c'est dans BaseParameters (pour Optimize-*)
         if ($finalBenchmarkParams.ContainsKey('BaseParameters') -and $finalBenchmarkParams.BaseParameters -is [hashtable]) {
            Write-Verbose "    Applying to BaseParameters.$workerParamName as well."
            $finalBenchmarkParams.BaseParameters[$workerParamName] = $WorkerOverride
         }
    }

    Write-Verbose "  ParamÃ¨tres finaux pour $benchmarkScriptRelativePath :"
    Write-Verbose ($finalBenchmarkParams | Out-String)

    # ExÃ©cuter le script de benchmark
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $testStartTime = Get-Date
    $resultSummary = $null
    $errorRecord = $null
    $status = 'Unknown'

    try {
        # ExÃ©cuter le script et capturer sa sortie (le rÃ©sumÃ© attendu)
        $resultSummary = & $benchmarkScriptFullPath @finalBenchmarkParams -ErrorAction Stop -WarningAction SilentlyContinue # Force l'erreur Ã  Ãªtre catchÃ©e
        $stopwatch.Stop()
        $status = 'Success'
        Write-Host "  Test '$testName' terminÃ© avec succÃ¨s en $($stopwatch.Elapsed.ToString('g'))" -ForegroundColor Green
    } catch {
        $stopwatch.Stop()
        $status = 'FailedExecution'
        $errorRecord = $_
        Write-Error "Erreur lors de l'exÃ©cution du test '$testName'. DurÃ©e: $($stopwatch.Elapsed.ToString('g')). Erreur : $($_.Exception.Message)"
        Write-Verbose "  StackTrace: $($_.ScriptStackTrace)"
    }

    $testEndTime = Get-Date
    $durationSec = $stopwatch.Elapsed.TotalSeconds

    # Essayer de dÃ©terminer le chemin du fichier de sortie principal (ex: JSON summary)
    $outputFile = $null
    if ($status -ne 'Skipped' -and $status -ne 'FailedSetup') {
        # Heuristique : chercher un fichier JSON ou HTML rÃ©cent dans le dossier de sortie du test
        $potentialFiles = Get-ChildItem -Path $testSpecificOutputPath -Filter "*.json" -Recurse |
                          Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if(-not $potentialFiles) {
            $potentialFiles = Get-ChildItem -Path $testSpecificOutputPath -Filter "*.html" -Recurse |
                          Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
        if ($potentialFiles) {
            $outputFile = $potentialFiles.FullName
            Write-Verbose "  Fichier de rÃ©sultat principal dÃ©tectÃ© : $outputFile"
        } else {
             Write-Verbose "  Impossible de dÃ©tecter automatiquement un fichier de rÃ©sultat principal (.json/.html)."
        }
    }


    # Retourner un objet structurÃ© avec les informations du test
    return [PSCustomObject]@{
        Name          = $testName
        Status        = $status # Success, FailedExecution, FailedSetup, Skipped
        StartTime     = $testStartTime
        EndTime       = $testEndTime
        DurationSec   = [Math]::Round($durationSec, 3)
        ResultSummary = $resultSummary # Ce que le script de benchmark a retournÃ©
        ErrorRecord   = $errorRecord # Contient l'exception si FailedExecution
        OutputPath    = $testSpecificOutputPath # Dossier de sortie de ce test
        OutputFile    = $outputFile # Chemin du fichier JSON/HTML principal si dÃ©tectÃ©
    }
}

# --- Fonction pour gÃ©nÃ©rer le rapport HTML global ---
function New-GlobalHtmlReport {
    param(
        [Parameter(Mandatory = $true)]
        [array]$TestResults, # Tableau des objets retournÃ©s par Invoke-BenchmarkScript

        [Parameter(Mandatory = $true)]
        [string]$ReportFilePath, # Chemin complet du fichier HTML Ã  crÃ©er

        [Parameter(Mandatory = $true)]
        [string]$BaseOutputPath, # Le dossier racine des rÃ©sultats pour calculer les liens relatifs

        [Parameter(Mandatory = $true)]
        [datetime]$GlobalStartTime,

        [Parameter(Mandatory = $true)]
        [datetime]$GlobalEndTime
    )

    Write-Host "`n--- GÃ©nÃ©ration du Rapport HTML Global ---" -ForegroundColor Cyan
    Write-Verbose "Chemin du rapport : $ReportFilePath"

    $totalTests = $TestResults.Count
    $successCount = ($TestResults | Where-Object { $_.Status -eq 'Success' }).Count
    $failedCount = ($TestResults | Where-Object { $_.Status -match 'Failed' }).Count
    $skippedCount = ($TestResults | Where-Object { $_.Status -eq 'Skipped' }).Count
    $totalDurationSec = ($TestResults | Measure-Object -Property DurationSec -Sum).Sum

    # PrÃ©paration des donnÃ©es pour le graphique
    $chartLabels = ($TestResults | ForEach-Object { "'$($_.Name -replace "'", "\'")'" }) -join ', '
    $chartDurations = ($TestResults | ForEach-Object { $_.DurationSec }) -join ', '
    $chartBackgroundColors = @()
    $chartBorderColors = @()
    foreach ($res in $TestResults) {
        switch ($res.Status) {
            'Success'         { $chartBackgroundColors += "'rgba(75, 192, 192, 0.6)'"; $chartBorderColors += "'rgba(75, 192, 192, 1)'" }
            'FailedExecution' { $chartBackgroundColors += "'rgba(255, 99, 132, 0.6)'"; $chartBorderColors += "'rgba(255, 99, 132, 1)'" }
            'FailedSetup'     { $chartBackgroundColors += "'rgba(255, 159, 64, 0.6)'"; $chartBorderColors += "'rgba(255, 159, 64, 1)'" }
            'Skipped'         { $chartBackgroundColors += "'rgba(201, 203, 207, 0.6)'"; $chartBorderColors += "'rgba(201, 203, 207, 1)'" }
            default           { $chartBackgroundColors += "'rgba(153, 102, 255, 0.6)'"; $chartBorderColors += "'rgba(153, 102, 255, 1)'" }
        }
    }
    $chartBackgroundColors = $chartBackgroundColors -join ', '
    $chartBorderColors = $chartBorderColors -join ', '


    # Construction du contenu HTML
    $htmlHead = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport Global des Tests de Performance</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.0/dist/chart.min.js"></script>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; margin: 20px; background-color: #f8f9fa; color: #343a40; }
        .container { max-width: 1200px; margin: auto; background-color: #ffffff; padding: 25px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
        h1, h2 { color: #0056b3; border-bottom: 2px solid #dee2e6; padding-bottom: 8px; margin-top: 25px; margin-bottom: 15px; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin-bottom: 20px; }
        .summary-item { background-color: #e9ecef; padding: 15px; border-radius: 5px; text-align: center; }
        .summary-item .value { font-size: 1.5em; font-weight: bold; color: #0056b3; display: block; }
        .summary-item .label { font-size: 0.9em; color: #6c757d; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 0.9em; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
        th, td { padding: 12px 15px; text-align: left; border: 1px solid #dee2e6; vertical-align: middle; }
        th { background-color: #007bff; color: white; white-space: nowrap; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #e9ecef; }
        .status { padding: 5px 10px; border-radius: 15px; color: white; font-weight: bold; text-align: center; display: inline-block; min-width: 80px; }
        .status-Success { background-color: #28a745; } /* Green */
        .status-FailedExecution, .status-FailedSetup { background-color: #dc3545; } /* Red */
        .status-Skipped { background-color: #6c757d; } /* Gray */
        .status-Unknown { background-color: #ffc107; color: #343a40; } /* Yellow */
        a { color: #0056b3; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .chart-container { width: 95%; max-width: 900px; height: 400px; margin: 30px auto; border: 1px solid #dee2e6; padding: 15px; border-radius: 5px; background: white;}
        pre { background-color: #e9ecef; padding: 10px; border-radius: 4px; font-size: 0.85em; white-space: pre-wrap; word-wrap: break-word; max-height: 200px; overflow-y: auto; border: 1px solid #ced4da; }
        .error-details { color: #dc3545; font-weight: bold; }
    </style>
</head>
<body>
<div class="container">
    <h1>Rapport Global des Tests de Performance</h1>
    <p>ExÃ©cution dÃ©marrÃ©e le $($GlobalStartTime.ToString("yyyy-MM-dd 'Ã ' HH:mm:ss")) et terminÃ©e le $($GlobalEndTime.ToString("yyyy-MM-dd 'Ã ' HH:mm:ss")).</p>

    <h2>RÃ©sumÃ© de l'ExÃ©cution</h2>
    <div class="summary-grid">
        <div class="summary-item"><span class="value">$totalTests</span><span class="label">Tests ExÃ©cutÃ©s</span></div>
        <div class="summary-item"><span class="value" style="color:#28a745;">$successCount</span><span class="label">SuccÃ¨s</span></div>
        <div class="summary-item"><span class="value" style="color:#dc3545;">$failedCount</span><span class="label">Ã‰checs</span></div>
        <div class="summary-item"><span class="value" style="color:#6c757d;">$skippedCount</span><span class="label">IgnorÃ©s</span></div>
        <div class="summary-item"><span class="value">$([Math]::Round($totalDurationSec, 2)) s</span><span class="label">DurÃ©e Totale</span></div>
    </div>

    <h2>RÃ©sultats DÃ©taillÃ©s par Test</h2>
    <table>
        <thead>
            <tr>
                <th>Nom du Test</th>
                <th>Statut</th>
                <th>DurÃ©e (s)</th>
                <th>RÃ©pertoire Sortie</th>
                <th>Rapport/Fichier RÃ©sultat</th>
                <th>DÃ©tails Erreur</th>
            </tr>
        </thead>
        <tbody>
"@

    # Ajouter une ligne pour chaque rÃ©sultat de test
    foreach ($result in $TestResults) {
        $statusClass = "status-$($result.Status)"
        $durationStr = $result.DurationSec.ToString("F3")
        $outputPathRelative = $result.OutputPath.Replace($BaseOutputPath, '.').Replace('\', '/') # Chemin relatif
        $outputPathLink = "<a href='$outputPathRelative' title='Explorer le dossier des rÃ©sultats' target='_blank'>$outputPathRelative</a>"

        $reportLink = "-"
        # Essayer de trouver un rapport HTML gÃ©nÃ©rÃ© par le script de benchmark
        $individualReportPath = Join-Path -Path $result.OutputPath -ChildPath "*report*.html"
        $foundReport = Get-ChildItem -Path $individualReportPath -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundReport) {
             $reportRelativePath = $foundReport.FullName.Replace($BaseOutputPath, '.').Replace('\', '/')
             $reportLink = "<a href='$reportRelativePath' title='Ouvrir le rapport dÃ©taillÃ© de ce test' target='_blank'>Rapport HTML</a>"
        } elseif ($result.OutputFile -and ($result.OutputFile.EndsWith(".json") -or $result.OutputFile.EndsWith(".html"))){
             # Lien vers le fichier JSON ou autre si pas de rapport HTML trouvÃ©
             $outputFileRelativePath = $result.OutputFile.Replace($BaseOutputPath, '.').Replace('\', '/')
             $reportLink = "<a href='$outputFileRelativePath' title='Ouvrir le fichier de rÃ©sultat principal' target='_blank'>Fichier RÃ©sultat</a>"
        }

        $errorDetails = "-"
        if ($result.ErrorRecord) {
            $errorMessage = $result.ErrorRecord.Exception.Message -replace '<', '<' -replace '>', '>'
            $errorDetails = "<span class='error-details'>Ã‰chec:</span><pre>$($errorMessage)</pre>"
            if($result.ErrorRecord.ScriptStackTrace){
                 $errorStackTrace = $result.ErrorRecord.ScriptStackTrace -replace '<', '<' -replace '>', '>'
                 $errorDetails += "<details><summary>Voir StackTrace</summary><pre>$($errorStackTrace)</pre></details>"
            }
        } elseif ($result.Status -match 'Failed') {
            $errorDetails = "<span class='error-details'>Ã‰chec (pas d'enregistrement d'erreur capturÃ©)</span>"
        }


        $htmlHead += @"
            <tr>
                <td>$($result.Name)</td>
                <td><span class="status $statusClass">$($result.Status)</span></td>
                <td>$durationStr</td>
                <td>$outputPathLink</td>
                <td>$reportLink</td>
                <td>$errorDetails</td>
            </tr>
"@
    }

    $htmlHead += @"
        </tbody>
    </table>

    <h2>Visualisation des Performances</h2>
    <div class="chart-container">
        <canvas id="durationChart"></canvas>
    </div>
    <script>
        const ctx = document.getElementById('durationChart').getContext('2d');
        const durationChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: [$chartLabels],
                datasets: [{
                    label: 'DurÃ©e d\'exÃ©cution (secondes)',
                    data: [$chartDurations],
                    backgroundColor: [$chartBackgroundColors],
                    borderColor: [$chartBorderColors],
                    borderWidth: 1
                }]
            },
            options: {
                indexAxis: 'y', // Barres horizontales pour meilleure lisibilitÃ© des labels
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    title: { display: true, text: 'DurÃ©e d\'ExÃ©cution par Test' },
                    legend: { display: false }, // LÃ©gende pas trÃ¨s utile ici
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                let label = context.dataset.label || '';
                                if (label) { label += ': '; }
                                if (context.parsed.x !== null) {
                                    label += context.parsed.x.toFixed(3) + ' s';
                                }
                                return label;
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        beginAtZero: true,
                        title: { display: true, text: 'DurÃ©e (secondes)' }
                    },
                    y: { beginAtZero: true }
                }
            }
        });
    </script>

</div> <!-- /container -->
</body>
</html>
"@

    # Sauvegarder le rapport
    try {
        $htmlHead | Out-File -FilePath $ReportFilePath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Host "Rapport HTML global gÃ©nÃ©rÃ© avec succÃ¨s : $ReportFilePath" -ForegroundColor Green
        # Optionnel: Ouvrir le rapport
        # if ($PSCmdlet.ShouldProcess($ReportFilePath, "Ouvrir le rapport global dans le navigateur")) {
        #     Start-Process $ReportFilePath
        # }
    } catch {
        Write-Error "Erreur lors de la sauvegarde du rapport HTML global '$ReportFilePath': $($_.Exception.Message)"
    }
}

#endregion

#region Configuration des Tests
# ------------------------------------------------------------------------------
# MODIFIEZ CETTE SECTION POUR DÃ‰FINIR LES TESTS Ã€ EXÃ‰CUTER
# ------------------------------------------------------------------------------
# Chaque Ã©lÃ©ment du tableau $testDefinitions reprÃ©sente une suite de tests Ã  lancer.
# PropriÃ©tÃ©s attendues pour chaque test:
#   - Name: (String) Nom unique et descriptif du test.
#   - Enabled: (Boolean) $true pour exÃ©cuter, $false pour ignorer ce test.
#   - BenchmarkScriptPath: (String) Chemin relatif (depuis ce script) vers le script de benchmark Ã  exÃ©cuter (ex: Optimize-ParallelBatchSize.ps1).
#   - Parameters: (Hashtable) ParamÃ¨tres Ã  passer au script de benchmark via splatting.
#       - Ces paramÃ¨tres DOIVENT correspondre Ã  ceux attendus par le BenchmarkScriptPath.
#       - Si le benchmark a besoin d'appeler un *autre* script (le "script cible"), dÃ©finissez ici
#         le 'ScriptBlock' et les 'BaseParameters' (params constants pour le script cible) nÃ©cessaires.
#   - TestDataParameterName: (String) [Optionnel] Nom du paramÃ¨tre dans `Parameters` (ou `BaseParameters`)
#                            qui doit recevoir le chemin global `-TestDataPath` s'il est fourni. Ex: 'ScriptsPath'.
#   - WorkerParameterName: (String) [Optionnel] Nom du paramÃ¨tre dans `Parameters` (ou `BaseParameters`)
#                          qui doit recevoir la valeur de `-MaxWorkersOverride` si elle est fournie. Ex: 'MaxWorkers'.
#
# Exemple de ScriptBlock pour un benchmark qui teste un script cible :
#   ScriptBlock = {
#       param($params) # ReÃ§oit BaseParameters + params dynamiques du benchmark (ex: BatchSize)
#       # RÃ©cupÃ©rer le chemin du script cible depuis les paramÃ¨tres reÃ§us
#       $targetScriptPath = $params.TargetPath
#       # Appeler le script cible avec tous les paramÃ¨tres reÃ§us
#       & $targetScriptPath @params
#   }
#   BaseParameters = @{
#       TargetPath = "path\to\your\actual\script\to\test.ps1" # Chemin du script Ã  tester
#       SomeOtherParamForTarget = "value"                      # Autres params constants pour le script cible
#   }
# ------------------------------------------------------------------------------

# DÃ©finir le chemin du script cible une seule fois (si utilisÃ© par plusieurs tests)
$defaultTargetScript = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "examples\script-analyzer-simple.ps1"

$testDefinitions = @(
    @{
        Name                  = "Benchmark Simple (script-analyzer-simple)"
        Enabled               = $true
        BenchmarkScriptPath   = "Test-ParallelPerformance.ps1"
        Parameters            = @{
            ScriptBlock = { param($params) & $params.TargetPath @params }
            TestName    = "Benchmark_Simple"
            Iterations  = 3
            Parameters  = @{ # ParamÃ¨tres pour le ScriptBlock -> donc pour le script cible
                TargetPath = $defaultTargetScript
                MaxWorkers = 4 # Exemple de paramÃ¨tre par dÃ©faut pour le script cible
                # Autres params pour script-analyzer-simple.ps1 si nÃ©cessaire
            }
        }
        TestDataParameterName = "InputPath" # Si script-analyzer-simple.ps1 a un param -InputPath
        WorkerParameterName   = "MaxWorkers"  # PrÃ©sent dans Parameters.Parameters
    },
    @{
        Name                  = "Optimisation BatchSize (script-analyzer-simple)"
        Enabled               = $true
        BenchmarkScriptPath   = "Optimize-ParallelBatchSize.ps1"
        Parameters            = @{
            ScriptBlock = { param($params) & $params.TargetPath @params }
            BaseParameters = @{ # ParamÃ¨tres constants pour script-analyzer-simple.ps1
                TargetPath = $defaultTargetScript
                MaxWorkers = 4 # Valeur par dÃ©faut, peut Ãªtre surchargÃ©e
                # Autres params constants pour script-analyzer-simple.ps1
            }
            BatchSizeParameterName = "BatchSize" # Nom du paramÃ¨tre que Optimize-ParallelBatchSize va varier
            BatchSizes             = @(5, 10, 20, 50, 100, 200)
            Iterations             = 2
        }
        TestDataParameterName = "InputPath" # Ce param est dans BaseParameters
        WorkerParameterName   = "MaxWorkers"  # Ce param est dans BaseParameters
    },
    @{
        Name                  = "Optimisation MÃ©moire (script-analyzer-simple)"
        Enabled               = $true
        BenchmarkScriptPath   = "Optimize-ParallelMemory.ps1"
        Parameters            = @{
            ScriptBlock = { param($params) & $params.TargetPath @params }
            # ScÃ©narios Ã  comparer par Optimize-ParallelMemory.ps1
            OptimizationScenarios = @(
                @{
                    Name = "Baseline_4W_B20"
                    Parameters = @{ TargetPath = $defaultTargetScript; MaxWorkers = 4; BatchSize = 20 }
                },
                @{
                    Name = "LowMem_2W_B10"
                    Parameters = @{ TargetPath = $defaultTargetScript; MaxWorkers = 2; BatchSize = 10 }
                },
                @{
                    Name = "HighConc_8W_B50"
                    Parameters = @{ TargetPath = $defaultTargetScript; MaxWorkers = 8; BatchSize = 50 }
                },
                @{
                    Name = "Baseline_ForceGC"
                    Parameters = @{ TargetPath = $defaultTargetScript; MaxWorkers = 4; BatchSize = 20; ForceGC = $true } # Assume ForceGC est un param de script-analyzer-simple
                }
            )
            Iterations = 2
            MonitorMemoryDuringRun = $true # Option pour Optimize-ParallelMemory.ps1
        }
        # TestDataPath et MaxWorkers sont DANS les 'Parameters' de chaque scÃ©nario ici
        TestDataParameterName = "InputPath" # Nom attendu dans les Parameters des scenarios
        WorkerParameterName   = "MaxWorkers"  # Nom attendu dans les Parameters des scenarios
    }
    # Ajoutez d'autres dÃ©finitions de test ici...
    # @{
    #     Name = "Autre Test"
    #     Enabled = $false # IgnorÃ© pour l'instant
    #     BenchmarkScriptPath = "Path\To\AnotherBenchmark.ps1"
    #     Parameters = @{ ... }
    # }
)

#endregion

#region ExÃ©cution Principale

Write-Host "=== DÃ©marrage de l'Orchestrateur de Tests de Performance ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Heure de dÃ©but : $startTimestamp"
Write-Host "RÃ©pertoire de sortie principal : $OutputPath"
if ($TestNameFilter) { Write-Host "Filtre de test actif : '$TestNameFilter'" -ForegroundColor Yellow }
if ($Force) { Write-Host "Option -Force activÃ©e." -ForegroundColor Yellow }
if ($TestDataPath) { Write-Host "Chemin des donnÃ©es de test global fourni : $TestDataPath" }
if ($PSBoundParameters.ContainsKey('MaxWorkersOverride')) { Write-Host "Surcharge MaxWorkers active : $MaxWorkersOverride" -ForegroundColor Yellow }

# 1. Validation des dÃ©pendances
if (-not (Test-BenchmarkDependencies -TestConfigurations $testDefinitions)) {
    # L'erreur a dÃ©jÃ  Ã©tÃ© Ã©crite par la fonction
    exit 1 # Ou return, selon le contexte d'appel
}

# 2. CrÃ©er le rÃ©pertoire de sortie principal
try {
    if (-not (Test-Path -Path $OutputPath)) {
        if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃ©er le rÃ©pertoire de sortie principal")) {
            New-Item -Path $OutputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Host "RÃ©pertoire de sortie principal crÃ©Ã© : $OutputPath" -ForegroundColor Green
        } else {
            Write-Error "CrÃ©ation du rÃ©pertoire de sortie principal annulÃ©e. ArrÃªt."
            exit 1
        }
    } else {
         Write-Verbose "RÃ©pertoire de sortie principal '$OutputPath' existe dÃ©jÃ ."
    }
} catch {
     Write-Error "Impossible de crÃ©er le rÃ©pertoire de sortie principal '$OutputPath'. Erreur: $($_.Exception.Message). ArrÃªt."
     exit 1
}

# 3. Filtrer les tests Ã  exÃ©cuter
$selectedTests = $testDefinitions | Where-Object { $_.Enabled }
if ($TestNameFilter) {
    $selectedTests = $selectedTests | Where-Object { $_.Name -like "*$TestNameFilter*" }
    Write-Host "Tests filtrÃ©s correspondant Ã  '$TestNameFilter': $($selectedTests.Count)"
}
if ($selectedTests.Count -eq 0) {
    Write-Warning "Aucun test activÃ© ne correspond aux critÃ¨res de filtrage. Aucune exÃ©cution."
    exit 0
} else {
    Write-Host "Nombre de tests Ã  exÃ©cuter : $($selectedTests.Count)"
}

# 4. ExÃ©cuter les tests sÃ©lectionnÃ©s
$allTestResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$testCounter = 0
$totalSelectedTests = $selectedTests.Count

foreach ($testDef in $selectedTests) {
    $testCounter++
    Write-Progress -Activity "ExÃ©cution des Suites de Tests de Performance" `
                   -Status "Test $testCounter/$totalSelectedTests : $($testDef.Name)" `
                   -PercentComplete (($testCounter / $totalSelectedTests) * 100)

    # PrÃ©parer les paramÃ¨tres pour Invoke-BenchmarkScript
    $invokeParams = @{
        TestDefinition        = $testDef
        GlobalRunOutputPath   = $OutputPath
        EnableReportGeneration = $GenerateReport # Passer le switch global
        ForceExecution        = $Force          # Passer le switch global
    }
    # Ajouter les paramÃ¨tres optionnels seulement s'ils sont dÃ©finis
    if ($TestDataPath) { $invokeParams.GlobalTestDataDirectory = $TestDataPath }
    if ($PSBoundParameters.ContainsKey('MaxWorkersOverride')) { $invokeParams.WorkerOverride = $MaxWorkersOverride }

    # Appeler la fonction pour exÃ©cuter ce test
    $singleTestResult = Invoke-BenchmarkScript @invokeParams
    $allTestResults.Add($singleTestResult)

    # Petite pause pour laisser le systÃ¨me respirer et Ã©viter flood de logs
    Start-Sleep -Milliseconds 100
}
Write-Progress -Activity "ExÃ©cution des Suites de Tests de Performance" -Completed

# 5. Enregistrer le rÃ©sumÃ© global des rÃ©sultats en JSON
$globalResultsPath = Join-Path -Path $OutputPath -ChildPath "GlobalPerformanceSummary_$timestampSuffix.json"
$finalResultsArray = $allTestResults.ToArray() # Convertir List en Array pour ConvertTo-Json
try {
    # Exclure ErrorRecord et ResultSummary dÃ©taillÃ© pour un JSON plus lÃ©ger (optionnel)
    $summaryForJson = $finalResultsArray | Select-Object Name, Status, StartTime, EndTime, DurationSec, OutputPath, OutputFile, @{N='ErrorMessage';E={$_.ErrorRecord.Exception.Message}}
    $summaryForJson | ConvertTo-Json -Depth 5 | Out-File -FilePath $globalResultsPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "`nRÃ©sumÃ© global des tests enregistrÃ© (JSON) : $globalResultsPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur lors de l'enregistrement du rÃ©sumÃ© JSON global '$globalResultsPath': $($_.Exception.Message)"
}

# 6. GÃ©nÃ©rer le rapport HTML global si demandÃ©
$endTimestamp = Get-Date
if ($GenerateReport) {
    $globalReportPath = Join-Path -Path $OutputPath -ChildPath "GlobalPerformanceReport_$timestampSuffix.html"
    New-GlobalHtmlReport -TestResults $finalResultsArray `
                              -ReportFilePath $globalReportPath `
                              -BaseOutputPath $OutputPath `
                              -GlobalStartTime $startTimestamp `
                              -GlobalEndTime $endTimestamp
}

Write-Host "`n=== Orchestrateur de Tests de Performance TerminÃ© ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Heure de fin : $endTimestamp"
$totalExecutionTime = $endTimestamp - $startTimestamp
Write-Host "DurÃ©e totale de l'orchestration : $($totalExecutionTime.ToString('g'))"

# 7. Retourner le tableau des rÃ©sultats dÃ©taillÃ©s
return $finalResultsArray

#endregion