#Requires -Version 5.1
<#
.SYNOPSIS
    Orchestre l'exécution de plusieurs suites de tests de performance PowerShell et Python.
.DESCRIPTION
    Ce script sert de point d'entrée pour exécuter une collection définie de scripts de benchmark
    (par exemple, tests généraux, optimisation de taille de lot, optimisation mémoire).
    Il collecte les résultats de chaque suite de tests, enregistre un résumé global en JSON,
    et peut générer un rapport HTML consolidé avec des liens vers les rapports individuels.

    Le script est conçu pour être configurable via la section 'Configuration des Tests'.
    Il gère la création des répertoires de sortie, la validation des dépendances (scripts de benchmark),
    et l'invocation structurée de chaque test défini.
.PARAMETER OutputPath
    Répertoire racine où tous les résultats des tests seront stockés.
    Un sous-répertoire sera créé pour chaque test individuel.
    Par défaut: '.\results' relatif au script.
.PARAMETER GenerateReport
    Si spécifié ($true), génère un rapport HTML global récapitulant tous les tests exécutés
    et fournit des liens vers les rapports HTML spécifiques de chaque test (s'ils existent).
.PARAMETER TestNameFilter
    [Optionnel] Permet d'exécuter uniquement les tests dont le nom contient cette chaîne (insensible à la casse).
    Utile pour cibler des tests spécifiques. Exemple: -TestNameFilter "BatchSize".
.PARAMETER Force
    [Optionnel] Utilisé pour forcer certaines opérations, comme la recréation de données de test
    si les scripts de benchmark sous-jacents le supportent (passé via les paramètres).
.PARAMETER TestDataPath
    [Optionnel] Chemin vers un répertoire de données de test commun à utiliser par les différents benchmarks.
    Sera injecté dans les paramètres de base des tests si le paramètre 'TestDataParameterName' est défini
    dans la configuration du test.
.PARAMETER MaxWorkersOverride
    [Optionnel] Permet de surcharger la valeur de 'MaxWorkers' (ou équivalent) dans tous les tests
    qui définissent un 'WorkerParameterName'. Utile pour tester rapidement l'impact global
    d'un changement du nombre de workers.
.EXAMPLE
    # Exécuter tous les tests définis et générer un rapport HTML global
    .\Run-AllPerformanceTests.ps1 -GenerateReport -Verbose

.EXAMPLE
    # Exécuter uniquement les tests contenant "Memory" dans leur nom, dans un répertoire spécifique
    .\Run-AllPerformanceTests.ps1 -OutputPath "C:\PerfReports\MemoryTests" -TestNameFilter "Memory" -Verbose

.EXAMPLE
    # Exécuter tous les tests en forçant la regénération des données de test (si supporté par les tests)
    .\Run-AllPerformanceTests.ps1 -GenerateReport -Force

.EXAMPLE
    # Exécuter tous les tests en utilisant un jeu de données spécifique et en limitant les workers à 2
    .\Run-AllPerformanceTests.ps1 -GenerateReport -TestDataPath "C:\Path\To\SharedTestData" -MaxWorkersOverride 2

.NOTES
    Auteur     : Votre Nom/Équipe
    Version    : 2.0
    Date       : 2023-10-27
    Dépendances: Les scripts de benchmark listés dans la section 'Configuration des Tests'
                 doivent exister aux chemins spécifiés.
                 Chart.js (via CDN pour le rapport HTML global et potentiellement les rapports individuels).

    Personnalisation: Modifiez la section '#region Configuration des Tests' pour ajouter,
                      supprimer ou modifier les tests à exécuter et leurs paramètres.
    Rapports Individuels: Ce script suppose que les scripts de benchmark (comme Optimize-*)
                          peuvent générer leurs propres rapports HTML s'ils sont appelés avec
                          -GenerateReport. Ce script tentera de lier ces rapports.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $false, HelpMessage = "Répertoire racine pour les résultats des tests.")]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "results"),

    [Parameter(Mandatory = $false, HelpMessage = "Générer un rapport HTML global consolidé.")]
    [switch]$GenerateReport,

    [Parameter(Mandatory = $false, HelpMessage = "Filtrer les tests à exécuter par nom (contient).")]
    [string]$TestNameFilter,

    [Parameter(Mandatory = $false, HelpMessage = "Forcer certaines opérations (ex: regénération de données).")]
    [switch]$Force,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers les données de test communes (optionnel).")]
    [string]$TestDataPath,

    [Parameter(Mandatory = $false, HelpMessage = "Surcharger le nombre de workers pour les tests applicables.")]
    [ValidateRange(1, 128)] # Ajuster la limite max si nécessaire
    [int]$MaxWorkersOverride
)

#region Variables et Fonctions Internes

# Horodatage pour les noms de fichiers uniques
$startTimestamp = Get-Date
$timestampSuffix = $startTimestamp.ToString('yyyyMMddHHmmss')

# --- Fonction pour valider les dépendances ---
function Test-BenchmarkDependencies {
    param(
        [Parameter(Mandatory = $true)]
        [array]$TestConfigurations
    )
    Write-Verbose "Validation des dépendances (scripts de benchmark)..."
    $missingDependencies = @()
    $uniqueScriptPaths = $TestConfigurations | Select-Object -ExpandProperty BenchmarkScriptPath -Unique

    foreach ($scriptPath in $uniqueScriptPaths) {
        $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptPath # Suppose qu'ils sont relatifs à ce script
        if (-not (Test-Path -Path $fullPath -PathType Leaf)) {
            $missingDependencies += $fullPath
        } else {
            Write-Verbose "  [OK] Dépendance trouvée : $fullPath"
        }
    }

    if ($missingDependencies.Count -gt 0) {
        Write-Error "Dépendances manquantes détectées : $($missingDependencies -join ', ')"
        Write-Error "Veuillez vous assurer que tous les scripts de benchmark référencés existent. Arrêt."
        return $false # Indique un échec
    }
    Write-Verbose "Toutes les dépendances des scripts de benchmark sont présentes."
    return $true # Indique le succès
}

# --- Fonction pour exécuter un script de benchmark individuel ---
function Invoke-BenchmarkScript {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$TestDefinition,

        [Parameter(Mandatory = $true)]
        [string]$GlobalRunOutputPath, # Le dossier racine pour *tous* les tests

        [Parameter(Mandatory = $false)]
        [switch]$EnableReportGeneration, # Si on veut que le benchmark génère son propre rapport

        [Parameter(Mandatory = $false)]
        [switch]$ForceExecution,

        [Parameter(Mandatory = $false)]
        [string]$GlobalTestDataDirectory, # Chemin fourni à l'orchestrateur

        [Parameter(Mandatory = $false)]
        [int]$WorkerOverride # Valeur fournie à l'orchestrateur
    )

    $testName = $TestDefinition.Name
    $benchmarkScriptRelativePath = $TestDefinition.BenchmarkScriptPath
    $benchmarkScriptFullPath = Join-Path -Path $PSScriptRoot -ChildPath $benchmarkScriptRelativePath
    $testParamsFromConfig = $TestDefinition.Parameters.Clone() # Cloner pour éviter modification accidentelle
    $testDataParamName = $TestDefinition.TestDataParameterName # Nom du paramètre pour les données (ex: 'ScriptsPath')
    $workerParamName = $TestDefinition.WorkerParameterName     # Nom du paramètre pour les workers (ex: 'MaxWorkers')

    Write-Host "`n=== [$(Get-Date -Format HH:mm:ss)] Démarrage Test : '$testName' ===" -ForegroundColor Cyan
    Write-Verbose "  Script de benchmark : $benchmarkScriptFullPath"

    # Créer un répertoire de sortie dédié pour ce test
    $testSpecificOutputName = "$($testName -replace '[^a-zA-Z0-9_]', '_')_$timestampSuffix"
    $testSpecificOutputPath = Join-Path -Path $GlobalRunOutputPath -ChildPath $testSpecificOutputName
    try {
        if (-not (Test-Path -Path $testSpecificOutputPath)) {
            if ($PSCmdlet.ShouldProcess($testSpecificOutputPath, "Créer le répertoire de sortie pour le test '$testName'")) {
                New-Item -Path $testSpecificOutputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Write-Verbose "  Répertoire de sortie créé : $testSpecificOutputPath"
            } else {
                Write-Warning "Création du répertoire de sortie pour '$testName' annulée. Test sauté."
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
        Write-Error "Impossible de créer le répertoire de sortie '$testSpecificOutputPath' pour le test '$testName'. Erreur: $($_.Exception.Message). Test sauté."
        # Retourner un objet indiquant l'échec
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

    # Préparer les paramètres finaux pour le script de benchmark
    $finalBenchmarkParams = @{}
    $finalBenchmarkParams.putAll($testParamsFromConfig) # Copier les paramètres de la config du test

    # Ajouter/Modifier le chemin de sortie pour le benchmark
    $finalBenchmarkParams['OutputPath'] = $testSpecificOutputPath

    # Ajouter -GenerateReport si demandé globalement
    if ($EnableReportGeneration) {
        $finalBenchmarkParams['GenerateReport'] = $true
    }

    # Ajouter -Force si demandé globalement
    if ($ForceExecution) {
        $finalBenchmarkParams['Force'] = $true
        # Certains scripts peuvent utiliser un nom différent, ex: ForceTestDataGeneration
        if ($finalBenchmarkParams.ContainsKey('ForceTestDataGeneration') -and !$finalBenchmarkParams.ContainsKey('Force')) {
             $finalBenchmarkParams['ForceTestDataGeneration'] = $true
        }
    }

    # Injecter le chemin des données de test si fourni et si le test est configuré pour l'accepter
    if (-not [string]::IsNullOrEmpty($GlobalTestDataDirectory) -and -not [string]::IsNullOrEmpty($testDataParamName)) {
        if (Test-Path $GlobalTestDataDirectory -PathType Container) {
            Write-Verbose "  Injecting TestDataPath '$GlobalTestDataDirectory' into parameter '$testDataParamName'"
            $finalBenchmarkParams[$testDataParamName] = $GlobalTestDataDirectory
            # Gérer le cas où les données sont dans BaseParameters (pour Optimize-*)
            if ($finalBenchmarkParams.ContainsKey('BaseParameters') -and $finalBenchmarkParams.BaseParameters -is [hashtable]) {
                Write-Verbose "    Injecting into BaseParameters.$testDataParamName as well."
                $finalBenchmarkParams.BaseParameters[$testDataParamName] = $GlobalTestDataDirectory
            }

        } else {
            Write-Warning "Le chemin TestDataPath global '$GlobalTestDataDirectory' n'est pas valide. Il ne sera pas injecté pour le test '$testName'."
        }
    }

    # Appliquer la surcharge du nombre de workers si fournie et applicable
    if ($PSBoundParameters.ContainsKey('WorkerOverride') -and -not [string]::IsNullOrEmpty($workerParamName)) {
         Write-Verbose "  Applying MaxWorkersOverride ($WorkerOverride) to parameter '$workerParamName'"
         $finalBenchmarkParams[$workerParamName] = $WorkerOverride
         # Gérer le cas où c'est dans BaseParameters (pour Optimize-*)
         if ($finalBenchmarkParams.ContainsKey('BaseParameters') -and $finalBenchmarkParams.BaseParameters -is [hashtable]) {
            Write-Verbose "    Applying to BaseParameters.$workerParamName as well."
            $finalBenchmarkParams.BaseParameters[$workerParamName] = $WorkerOverride
         }
    }

    Write-Verbose "  Paramètres finaux pour $benchmarkScriptRelativePath :"
    Write-Verbose ($finalBenchmarkParams | Out-String)

    # Exécuter le script de benchmark
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $testStartTime = Get-Date
    $resultSummary = $null
    $errorRecord = $null
    $status = 'Unknown'

    try {
        # Exécuter le script et capturer sa sortie (le résumé attendu)
        $resultSummary = & $benchmarkScriptFullPath @finalBenchmarkParams -ErrorAction Stop -WarningAction SilentlyContinue # Force l'erreur à être catchée
        $stopwatch.Stop()
        $status = 'Success'
        Write-Host "  Test '$testName' terminé avec succès en $($stopwatch.Elapsed.ToString('g'))" -ForegroundColor Green
    } catch {
        $stopwatch.Stop()
        $status = 'FailedExecution'
        $errorRecord = $_
        Write-Error "Erreur lors de l'exécution du test '$testName'. Durée: $($stopwatch.Elapsed.ToString('g')). Erreur : $($_.Exception.Message)"
        Write-Verbose "  StackTrace: $($_.ScriptStackTrace)"
    }

    $testEndTime = Get-Date
    $durationSec = $stopwatch.Elapsed.TotalSeconds

    # Essayer de déterminer le chemin du fichier de sortie principal (ex: JSON summary)
    $outputFile = $null
    if ($status -ne 'Skipped' -and $status -ne 'FailedSetup') {
        # Heuristique : chercher un fichier JSON ou HTML récent dans le dossier de sortie du test
        $potentialFiles = Get-ChildItem -Path $testSpecificOutputPath -Filter "*.json" -Recurse |
                          Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if(-not $potentialFiles) {
            $potentialFiles = Get-ChildItem -Path $testSpecificOutputPath -Filter "*.html" -Recurse |
                          Sort-Object LastWriteTime -Descending | Select-Object -First 1
        }
        if ($potentialFiles) {
            $outputFile = $potentialFiles.FullName
            Write-Verbose "  Fichier de résultat principal détecté : $outputFile"
        } else {
             Write-Verbose "  Impossible de détecter automatiquement un fichier de résultat principal (.json/.html)."
        }
    }


    # Retourner un objet structuré avec les informations du test
    return [PSCustomObject]@{
        Name          = $testName
        Status        = $status # Success, FailedExecution, FailedSetup, Skipped
        StartTime     = $testStartTime
        EndTime       = $testEndTime
        DurationSec   = [Math]::Round($durationSec, 3)
        ResultSummary = $resultSummary # Ce que le script de benchmark a retourné
        ErrorRecord   = $errorRecord # Contient l'exception si FailedExecution
        OutputPath    = $testSpecificOutputPath # Dossier de sortie de ce test
        OutputFile    = $outputFile # Chemin du fichier JSON/HTML principal si détecté
    }
}

# --- Fonction pour générer le rapport HTML global ---
function New-GlobalHtmlReport {
    param(
        [Parameter(Mandatory = $true)]
        [array]$TestResults, # Tableau des objets retournés par Invoke-BenchmarkScript

        [Parameter(Mandatory = $true)]
        [string]$ReportFilePath, # Chemin complet du fichier HTML à créer

        [Parameter(Mandatory = $true)]
        [string]$BaseOutputPath, # Le dossier racine des résultats pour calculer les liens relatifs

        [Parameter(Mandatory = $true)]
        [datetime]$GlobalStartTime,

        [Parameter(Mandatory = $true)]
        [datetime]$GlobalEndTime
    )

    Write-Host "`n--- Génération du Rapport HTML Global ---" -ForegroundColor Cyan
    Write-Verbose "Chemin du rapport : $ReportFilePath"

    $totalTests = $TestResults.Count
    $successCount = ($TestResults | Where-Object { $_.Status -eq 'Success' }).Count
    $failedCount = ($TestResults | Where-Object { $_.Status -match 'Failed' }).Count
    $skippedCount = ($TestResults | Where-Object { $_.Status -eq 'Skipped' }).Count
    $totalDurationSec = ($TestResults | Measure-Object -Property DurationSec -Sum).Sum

    # Préparation des données pour le graphique
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
    <p>Exécution démarrée le $($GlobalStartTime.ToString("yyyy-MM-dd 'à' HH:mm:ss")) et terminée le $($GlobalEndTime.ToString("yyyy-MM-dd 'à' HH:mm:ss")).</p>

    <h2>Résumé de l'Exécution</h2>
    <div class="summary-grid">
        <div class="summary-item"><span class="value">$totalTests</span><span class="label">Tests Exécutés</span></div>
        <div class="summary-item"><span class="value" style="color:#28a745;">$successCount</span><span class="label">Succès</span></div>
        <div class="summary-item"><span class="value" style="color:#dc3545;">$failedCount</span><span class="label">Échecs</span></div>
        <div class="summary-item"><span class="value" style="color:#6c757d;">$skippedCount</span><span class="label">Ignorés</span></div>
        <div class="summary-item"><span class="value">$([Math]::Round($totalDurationSec, 2)) s</span><span class="label">Durée Totale</span></div>
    </div>

    <h2>Résultats Détaillés par Test</h2>
    <table>
        <thead>
            <tr>
                <th>Nom du Test</th>
                <th>Statut</th>
                <th>Durée (s)</th>
                <th>Répertoire Sortie</th>
                <th>Rapport/Fichier Résultat</th>
                <th>Détails Erreur</th>
            </tr>
        </thead>
        <tbody>
"@

    # Ajouter une ligne pour chaque résultat de test
    foreach ($result in $TestResults) {
        $statusClass = "status-$($result.Status)"
        $durationStr = $result.DurationSec.ToString("F3")
        $outputPathRelative = $result.OutputPath.Replace($BaseOutputPath, '.').Replace('\', '/') # Chemin relatif
        $outputPathLink = "<a href='$outputPathRelative' title='Explorer le dossier des résultats' target='_blank'>$outputPathRelative</a>"

        $reportLink = "-"
        # Essayer de trouver un rapport HTML généré par le script de benchmark
        $individualReportPath = Join-Path -Path $result.OutputPath -ChildPath "*report*.html"
        $foundReport = Get-ChildItem -Path $individualReportPath -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundReport) {
             $reportRelativePath = $foundReport.FullName.Replace($BaseOutputPath, '.').Replace('\', '/')
             $reportLink = "<a href='$reportRelativePath' title='Ouvrir le rapport détaillé de ce test' target='_blank'>Rapport HTML</a>"
        } elseif ($result.OutputFile -and ($result.OutputFile.EndsWith(".json") -or $result.OutputFile.EndsWith(".html"))){
             # Lien vers le fichier JSON ou autre si pas de rapport HTML trouvé
             $outputFileRelativePath = $result.OutputFile.Replace($BaseOutputPath, '.').Replace('\', '/')
             $reportLink = "<a href='$outputFileRelativePath' title='Ouvrir le fichier de résultat principal' target='_blank'>Fichier Résultat</a>"
        }

        $errorDetails = "-"
        if ($result.ErrorRecord) {
            $errorMessage = $result.ErrorRecord.Exception.Message -replace '<', '<' -replace '>', '>'
            $errorDetails = "<span class='error-details'>Échec:</span><pre>$($errorMessage)</pre>"
            if($result.ErrorRecord.ScriptStackTrace){
                 $errorStackTrace = $result.ErrorRecord.ScriptStackTrace -replace '<', '<' -replace '>', '>'
                 $errorDetails += "<details><summary>Voir StackTrace</summary><pre>$($errorStackTrace)</pre></details>"
            }
        } elseif ($result.Status -match 'Failed') {
            $errorDetails = "<span class='error-details'>Échec (pas d'enregistrement d'erreur capturé)</span>"
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
                    label: 'Durée d\'exécution (secondes)',
                    data: [$chartDurations],
                    backgroundColor: [$chartBackgroundColors],
                    borderColor: [$chartBorderColors],
                    borderWidth: 1
                }]
            },
            options: {
                indexAxis: 'y', // Barres horizontales pour meilleure lisibilité des labels
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    title: { display: true, text: 'Durée d\'Exécution par Test' },
                    legend: { display: false }, // Légende pas très utile ici
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
                        title: { display: true, text: 'Durée (secondes)' }
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
        Write-Host "Rapport HTML global généré avec succès : $ReportFilePath" -ForegroundColor Green
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
# MODIFIEZ CETTE SECTION POUR DÉFINIR LES TESTS À EXÉCUTER
# ------------------------------------------------------------------------------
# Chaque élément du tableau $testDefinitions représente une suite de tests à lancer.
# Propriétés attendues pour chaque test:
#   - Name: (String) Nom unique et descriptif du test.
#   - Enabled: (Boolean) $true pour exécuter, $false pour ignorer ce test.
#   - BenchmarkScriptPath: (String) Chemin relatif (depuis ce script) vers le script de benchmark à exécuter (ex: Optimize-ParallelBatchSize.ps1).
#   - Parameters: (Hashtable) Paramètres à passer au script de benchmark via splatting.
#       - Ces paramètres DOIVENT correspondre à ceux attendus par le BenchmarkScriptPath.
#       - Si le benchmark a besoin d'appeler un *autre* script (le "script cible"), définissez ici
#         le 'ScriptBlock' et les 'BaseParameters' (params constants pour le script cible) nécessaires.
#   - TestDataParameterName: (String) [Optionnel] Nom du paramètre dans `Parameters` (ou `BaseParameters`)
#                            qui doit recevoir le chemin global `-TestDataPath` s'il est fourni. Ex: 'ScriptsPath'.
#   - WorkerParameterName: (String) [Optionnel] Nom du paramètre dans `Parameters` (ou `BaseParameters`)
#                          qui doit recevoir la valeur de `-MaxWorkersOverride` si elle est fournie. Ex: 'MaxWorkers'.
#
# Exemple de ScriptBlock pour un benchmark qui teste un script cible :
#   ScriptBlock = {
#       param($params) # Reçoit BaseParameters + params dynamiques du benchmark (ex: BatchSize)
#       # Récupérer le chemin du script cible depuis les paramètres reçus
#       $targetScriptPath = $params.TargetPath
#       # Appeler le script cible avec tous les paramètres reçus
#       & $targetScriptPath @params
#   }
#   BaseParameters = @{
#       TargetPath = "path\to\your\actual\script\to\test.ps1" # Chemin du script à tester
#       SomeOtherParamForTarget = "value"                      # Autres params constants pour le script cible
#   }
# ------------------------------------------------------------------------------

# Définir le chemin du script cible une seule fois (si utilisé par plusieurs tests)
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
            Parameters  = @{ # Paramètres pour le ScriptBlock -> donc pour le script cible
                TargetPath = $defaultTargetScript
                MaxWorkers = 4 # Exemple de paramètre par défaut pour le script cible
                # Autres params pour script-analyzer-simple.ps1 si nécessaire
            }
        }
        TestDataParameterName = "InputPath" # Si script-analyzer-simple.ps1 a un param -InputPath
        WorkerParameterName   = "MaxWorkers"  # Présent dans Parameters.Parameters
    },
    @{
        Name                  = "Optimisation BatchSize (script-analyzer-simple)"
        Enabled               = $true
        BenchmarkScriptPath   = "Optimize-ParallelBatchSize.ps1"
        Parameters            = @{
            ScriptBlock = { param($params) & $params.TargetPath @params }
            BaseParameters = @{ # Paramètres constants pour script-analyzer-simple.ps1
                TargetPath = $defaultTargetScript
                MaxWorkers = 4 # Valeur par défaut, peut être surchargée
                # Autres params constants pour script-analyzer-simple.ps1
            }
            BatchSizeParameterName = "BatchSize" # Nom du paramètre que Optimize-ParallelBatchSize va varier
            BatchSizes             = @(5, 10, 20, 50, 100, 200)
            Iterations             = 2
        }
        TestDataParameterName = "InputPath" # Ce param est dans BaseParameters
        WorkerParameterName   = "MaxWorkers"  # Ce param est dans BaseParameters
    },
    @{
        Name                  = "Optimisation Mémoire (script-analyzer-simple)"
        Enabled               = $true
        BenchmarkScriptPath   = "Optimize-ParallelMemory.ps1"
        Parameters            = @{
            ScriptBlock = { param($params) & $params.TargetPath @params }
            # Scénarios à comparer par Optimize-ParallelMemory.ps1
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
        # TestDataPath et MaxWorkers sont DANS les 'Parameters' de chaque scénario ici
        TestDataParameterName = "InputPath" # Nom attendu dans les Parameters des scenarios
        WorkerParameterName   = "MaxWorkers"  # Nom attendu dans les Parameters des scenarios
    }
    # Ajoutez d'autres définitions de test ici...
    # @{
    #     Name = "Autre Test"
    #     Enabled = $false # Ignoré pour l'instant
    #     BenchmarkScriptPath = "Path\To\AnotherBenchmark.ps1"
    #     Parameters = @{ ... }
    # }
)

#endregion

#region Exécution Principale

Write-Host "=== Démarrage de l'Orchestrateur de Tests de Performance ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Heure de début : $startTimestamp"
Write-Host "Répertoire de sortie principal : $OutputPath"
if ($TestNameFilter) { Write-Host "Filtre de test actif : '$TestNameFilter'" -ForegroundColor Yellow }
if ($Force) { Write-Host "Option -Force activée." -ForegroundColor Yellow }
if ($TestDataPath) { Write-Host "Chemin des données de test global fourni : $TestDataPath" }
if ($PSBoundParameters.ContainsKey('MaxWorkersOverride')) { Write-Host "Surcharge MaxWorkers active : $MaxWorkersOverride" -ForegroundColor Yellow }

# 1. Validation des dépendances
if (-not (Test-BenchmarkDependencies -TestConfigurations $testDefinitions)) {
    # L'erreur a déjà été écrite par la fonction
    exit 1 # Ou return, selon le contexte d'appel
}

# 2. Créer le répertoire de sortie principal
try {
    if (-not (Test-Path -Path $OutputPath)) {
        if ($PSCmdlet.ShouldProcess($OutputPath, "Créer le répertoire de sortie principal")) {
            New-Item -Path $OutputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Host "Répertoire de sortie principal créé : $OutputPath" -ForegroundColor Green
        } else {
            Write-Error "Création du répertoire de sortie principal annulée. Arrêt."
            exit 1
        }
    } else {
         Write-Verbose "Répertoire de sortie principal '$OutputPath' existe déjà."
    }
} catch {
     Write-Error "Impossible de créer le répertoire de sortie principal '$OutputPath'. Erreur: $($_.Exception.Message). Arrêt."
     exit 1
}

# 3. Filtrer les tests à exécuter
$selectedTests = $testDefinitions | Where-Object { $_.Enabled }
if ($TestNameFilter) {
    $selectedTests = $selectedTests | Where-Object { $_.Name -like "*$TestNameFilter*" }
    Write-Host "Tests filtrés correspondant à '$TestNameFilter': $($selectedTests.Count)"
}
if ($selectedTests.Count -eq 0) {
    Write-Warning "Aucun test activé ne correspond aux critères de filtrage. Aucune exécution."
    exit 0
} else {
    Write-Host "Nombre de tests à exécuter : $($selectedTests.Count)"
}

# 4. Exécuter les tests sélectionnés
$allTestResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$testCounter = 0
$totalSelectedTests = $selectedTests.Count

foreach ($testDef in $selectedTests) {
    $testCounter++
    Write-Progress -Activity "Exécution des Suites de Tests de Performance" `
                   -Status "Test $testCounter/$totalSelectedTests : $($testDef.Name)" `
                   -PercentComplete (($testCounter / $totalSelectedTests) * 100)

    # Préparer les paramètres pour Invoke-BenchmarkScript
    $invokeParams = @{
        TestDefinition        = $testDef
        GlobalRunOutputPath   = $OutputPath
        EnableReportGeneration = $GenerateReport # Passer le switch global
        ForceExecution        = $Force          # Passer le switch global
    }
    # Ajouter les paramètres optionnels seulement s'ils sont définis
    if ($TestDataPath) { $invokeParams.GlobalTestDataDirectory = $TestDataPath }
    if ($PSBoundParameters.ContainsKey('MaxWorkersOverride')) { $invokeParams.WorkerOverride = $MaxWorkersOverride }

    # Appeler la fonction pour exécuter ce test
    $singleTestResult = Invoke-BenchmarkScript @invokeParams
    $allTestResults.Add($singleTestResult)

    # Petite pause pour laisser le système respirer et éviter flood de logs
    Start-Sleep -Milliseconds 100
}
Write-Progress -Activity "Exécution des Suites de Tests de Performance" -Completed

# 5. Enregistrer le résumé global des résultats en JSON
$globalResultsPath = Join-Path -Path $OutputPath -ChildPath "GlobalPerformanceSummary_$timestampSuffix.json"
$finalResultsArray = $allTestResults.ToArray() # Convertir List en Array pour ConvertTo-Json
try {
    # Exclure ErrorRecord et ResultSummary détaillé pour un JSON plus léger (optionnel)
    $summaryForJson = $finalResultsArray | Select-Object Name, Status, StartTime, EndTime, DurationSec, OutputPath, OutputFile, @{N='ErrorMessage';E={$_.ErrorRecord.Exception.Message}}
    $summaryForJson | ConvertTo-Json -Depth 5 | Out-File -FilePath $globalResultsPath -Encoding UTF8 -Force -ErrorAction Stop
    Write-Host "`nRésumé global des tests enregistré (JSON) : $globalResultsPath" -ForegroundColor Green
} catch {
    Write-Error "Erreur lors de l'enregistrement du résumé JSON global '$globalResultsPath': $($_.Exception.Message)"
}

# 6. Générer le rapport HTML global si demandé
$endTimestamp = Get-Date
if ($GenerateReport) {
    $globalReportPath = Join-Path -Path $OutputPath -ChildPath "GlobalPerformanceReport_$timestampSuffix.html"
    New-GlobalHtmlReport -TestResults $finalResultsArray `
                              -ReportFilePath $globalReportPath `
                              -BaseOutputPath $OutputPath `
                              -GlobalStartTime $startTimestamp `
                              -GlobalEndTime $endTimestamp
}

Write-Host "`n=== Orchestrateur de Tests de Performance Terminé ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "Heure de fin : $endTimestamp"
$totalExecutionTime = $endTimestamp - $startTimestamp
Write-Host "Durée totale de l'orchestration : $($totalExecutionTime.ToString('g'))"

# 7. Retourner le tableau des résultats détaillés
return $finalResultsArray

#endregion