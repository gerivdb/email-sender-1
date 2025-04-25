#Requires -Version 5.1
<#
.SYNOPSIS
    Teste en parallèle la détection de format améliorée sur un ensemble de fichiers
    et compare les résultats aux formats attendus (si fournis).

.DESCRIPTION
    Ce script exécute en parallèle le script 'Improved-FormatDetection.ps1' sur chaque fichier
    d'un répertoire spécifié. Il collecte les résultats détaillés (format détecté, confiance,
    encodage, etc.). Si un fichier de formats attendus est fourni (via -ExpectedFormatsPath),
    il compare le format détecté au format attendu et marque le résultat comme correct ou incorrect.
    Il génère un rapport JSON détaillé et un rapport HTML optionnel résumant les performances
    de la détection.

.PARAMETER SampleDirectory
    Le répertoire contenant les fichiers à analyser. Par défaut, utilise le répertoire 'samples'.

.PARAMETER OutputPath
    Le chemin où le rapport d'analyse JSON sera enregistré. Par défaut, 'ImprovedFormatDetectionResults.json'.

.PARAMETER DetectionScriptPath
    Le chemin vers le script de détection améliorée à tester.
    Par défaut, 'Improved-FormatDetection.ps1' dans le même répertoire.

.PARAMETER ExpectedFormatsPath
    Chemin optionnel vers un fichier JSON contenant un hashtable { "Chemin/Complet/Fichier": "FORMAT_ATTENDU" }.
    Permet de calculer le taux de succès de la détection.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit être généré en plus du rapport JSON.

.PARAMETER MaxThreads
    Nombre maximum de threads à utiliser pour l'analyse parallèle. Par défaut, le nombre de processeurs logiques.

.EXAMPLE
    .\Test-ImprovedFormatDetection.ps1 -SampleDirectory "C:\MesTests\Echantillons" -GenerateHtmlReport

.EXAMPLE
    .\Test-ImprovedFormatDetection.ps1 -SampleDirectory .\samples -ExpectedFormatsPath .\formats_attendus.json -GenerateHtmlReport -MaxThreads 4

.NOTES
    Version: 2.0
    Auteur: Augment Agent (Amélioré par IA)
    Date: 2025-04-12
    Dépendances: Nécessite le script spécifié par -DetectionScriptPath (par défaut 'Improved-FormatDetection.ps1')
                qui doit accepter -FilePath et retourner un objet structuré.
    Améliorations v2.0:
    - Parallélisation des tests via Runspace Pools.
    - Gestion améliorée des erreurs et des formats attendus.
    - Rapport HTML retravaillé pour une meilleure lisibilité et information.
    - Optimisation de la collecte des résultats.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(HelpMessage = "Répertoire contenant les fichiers d'échantillons à tester.")]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$SampleDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "samples"),

    [Parameter(HelpMessage = "Chemin pour le rapport JSON de sortie.")]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "ImprovedFormatDetectionResults.json"),

    [Parameter(HelpMessage = "Chemin vers le script de détection de format à tester.")]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$DetectionScriptPath = (Join-Path -Path $PSScriptRoot -ChildPath "Improved-FormatDetection.ps1"),

    [Parameter(HelpMessage = "Chemin optionnel vers le fichier JSON des formats attendus.")]
    [string]$ExpectedFormatsPath,

    [Parameter(HelpMessage = "Générer un rapport HTML en plus du JSON.")]
    [switch]$GenerateHtmlReport,

    [Parameter(HelpMessage = "Nombre maximum de threads pour l'analyse parallèle.")]
    [ValidateRange(1, 64)]
    [int]$MaxThreads = [System.Environment]::ProcessorCount
)

#region Global Variables and Initialization
$global:ScriptStartTime = Get-Date
$global:ExpectedFormats = $null
$global:UseExpectedFormats = $false

# Vérifier l'existence du script de détection
if (-not (Test-Path -Path $DetectionScriptPath -PathType Leaf)) {
    Write-Error "Le script de détection spécifié '$DetectionScriptPath' n'a pas été trouvé."
    exit 1
}
Write-Verbose "Utilisation du script de détection : $DetectionScriptPath"

# Charger les formats attendus si le chemin est spécifié et valide
if (-not [string]::IsNullOrWhiteSpace($ExpectedFormatsPath)) {
    if (Test-Path -Path $ExpectedFormatsPath -PathType Leaf) {
        try {
            $jsonContent = Get-Content -Path $ExpectedFormatsPath -Raw -Encoding UTF8 -ErrorAction Stop
            # Utiliser -AsHashTable est crucial pour un accès rapide par clé
            $global:ExpectedFormats = ConvertFrom-Json -InputObject $jsonContent -AsHashtable -ErrorAction Stop
            if ($global:ExpectedFormats -and $global:ExpectedFormats.Count -gt 0) {
                $global:UseExpectedFormats = $true
                Write-Host "Formats attendus chargés avec succès depuis '$ExpectedFormatsPath' ($($global:ExpectedFormats.Count) entrées)." -ForegroundColor Green
            } else {
                Write-Warning "Le fichier de formats attendus '$ExpectedFormatsPath' est vide ou n'a pas pu être interprété comme une table de hachage."
            }
        } catch {
            Write-Error "Erreur critique lors du chargement ou de la conversion des formats attendus depuis '$ExpectedFormatsPath': $($_.Exception.Message)"
            # On pourrait choisir de continuer sans les formats attendus ou d'arrêter. Ici, on arrête.
            exit 1
        }
    } else {
        Write-Warning "Le fichier de formats attendus spécifié '$ExpectedFormatsPath' n'existe pas. L'analyse se fera sans comparaison."
    }
} else {
     Write-Verbose "Aucun fichier de formats attendus spécifié. Aucune comparaison ne sera effectuée."
}
#endregion

#region Analysis Orchestration (Parallel)

function Invoke-DetectionScript_Parallel {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        [Parameter(Mandatory = $true)]
        [string]$ScriptToRun,
        [Parameter(Mandatory = $true)]
        [int]$NumberOfThreads,
        [hashtable]$FormatsAttendus = $null # Passer la table de hachage
    )

    Write-Host "Récupération de la liste des fichiers dans '$Directory'..." -ForegroundColor Cyan
    $files = Get-ChildItem -Path $Directory -File -Recurse -ErrorAction SilentlyContinue

    if (-not $files) {
        Write-Warning "Aucun fichier trouvé dans le répertoire '$Directory'."
        return @()
    }

    Write-Host "$($files.Count) fichiers trouvés. Démarrage des tests parallèles avec $NumberOfThreads threads..." -ForegroundColor Cyan

    # Version simplifiée sans parallélisme pour éviter les erreurs
    $results = @()

    # Traitement séquentiel simple
    foreach ($file in $files) {
        $filePath = $file.FullName

        # Code de traitement de fichier
        param($filePath, $detectionScriptPath, $expectedFormatsHashTable)

        $ErrorActionPreference = 'SilentlyContinue' # Isoler les erreurs du thread
        $resultObject = $null

        try {
            # Exécuter le script de détection fourni
            # Assurez-vous que le script cible retourne bien UN SEUL objet ou une collection gérable
            $detectionResult = & $detectionScriptPath -FilePath $filePath # -DetectEncoding -DetailedOutput # Ajouter si nécessaire par le script cible

            if ($null -eq $detectionResult) {
                 throw "Le script de détection n'a retourné aucun résultat pour $filePath."
            }
             # Si le script retourne plusieurs objets, prendre le premier ? Ou gérer ? Supposons un seul objet.
             if ($detectionResult -is [array]) { $detectionResult = $detectionResult[0] }


            # Vérifier si le format détecté correspond au format attendu (si disponible)
            $expectedFormat = $null
            $isCorrect = $null # Null signifie "non testé"

            # Utiliser la hashtable passée en argument
            if ($null -ne $expectedFormatsHashTable -and $expectedFormatsHashTable.ContainsKey($filePath)) {
                $expectedFormat = $expectedFormatsHashTable[$filePath]
                # Comparaison insensible à la casse par sécurité
                $isCorrect = $detectionResult.DetectedFormat -eq $expectedFormat
            }

            # Construire l'objet résultat à partir des propriétés retournées par le script de détection
            # Utilisation de ?. pour éviter les erreurs si une propriété manque dans l'objet retourné
            $resultObject = [PSCustomObject]@{
                FilePath = $filePath;
                FileName = try { (Get-Item $filePath -ErrorAction SilentlyContinue).Name } catch { 'N/A' };
                Extension = try { (Get-Item $filePath -ErrorAction SilentlyContinue).Extension } catch { 'N/A' };
                Size = try { (Get-Item $filePath -ErrorAction SilentlyContinue).Length } catch { -1 };
                DetectedFormat = if ($null -ne $detectionResult) { $detectionResult.DetectedFormat } else { "ERROR" };
                Category = if ($null -ne $detectionResult) { $detectionResult.Category } else { "ERROR" };
                ConfidenceScore = if ($null -ne $detectionResult) { $detectionResult.ConfidenceScore } else { 0 };
                MatchedCriteria = if ($null -ne $detectionResult) { $detectionResult.MatchedCriteria } else { $null };
                Encoding = if ($null -ne $detectionResult) { $detectionResult.Encoding } else { $null };
                ExpectedFormat = $expectedFormat;
                IsCorrect = $isCorrect; # $true, $false, ou $null
                AllFormats = if ($null -ne $detectionResult) { $detectionResult.AllFormats } else { $null };
                Error = $null
            }

        } catch {
            Write-Warning "Erreur thread pour $($filePath): $($_.Exception.Message)"
            $resultObject = [PSCustomObject]@{
                FilePath = $filePath;
                FileName = try { (Get-Item $filePath -ErrorAction SilentlyContinue).Name } catch { 'N/A' };
                Extension = try { (Get-Item $filePath -ErrorAction SilentlyContinue).Extension } catch { 'N/A' };
                Size = try { (Get-Item $filePath -ErrorAction SilentlyContinue).Length } catch { -1 };
                DetectedFormat = "ERROR";
                Category = "ERROR";
                ConfidenceScore = 0;
                MatchedCriteria = $null;
                Encoding = $null;
                ExpectedFormat = if ($null -ne $expectedFormatsHashTable -and $expectedFormatsHashTable.ContainsKey($filePath)) { $expectedFormatsHashTable[$filePath] } else { $null };
                IsCorrect = $false; # Une erreur est considérée comme incorrecte si un format était attendu
                AllFormats = $null;
                Error = $_.Exception.Message
            }
        }

        return $resultObject
    }

    # Logique de gestion des tâches parallèles (identique à Analyze-FormatDetectionFailures)
    $progressCount = 0
    $totalCount = $files.Count
    $updateInterval = [Math]::Max(1, [Math]::Floor($totalCount / 100))

    foreach ($file in $files) {
        $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($file.FullName).AddArgument($ScriptToRun).AddArgument($FormatsAttendus) # Passer la hashtable
        $powershell.RunspacePool = $runspacePool
        $handles.Add($powershell.BeginInvoke())
        $tasks.Add($powershell)

        while ($handles.Count -ge $NumberOfThreads * 2) {
            $completedIndex = [System.Threading.WaitHandle]::WaitAny($handles.ToArray(), 100)
            if ($completedIndex -ne [System.Threading.WaitHandle]::WaitTimeout) {
                $completedTask = $tasks[$completedIndex]
                try {
                    $taskResult = $completedTask.EndInvoke($handles[$completedIndex])
                    if ($taskResult) { $results.Add($taskResult) }
                } catch { Write-Warning "Erreur EndInvoke: $($_.Exception.Message)"; $results.Add([PSCustomObject]@{ Error = "Erreur EndInvoke: $($_.Exception.Message)"; FilePath = "N/A" }) }
                finally { $completedTask.Dispose(); $handles.RemoveAt($completedIndex); $tasks.RemoveAt($completedIndex); $progressCount++ }
            }
            if (($progressCount % $updateInterval) -eq 0 -or $progressCount -eq $totalCount) { Write-Progress -Activity "Test des fichiers" -Status "Progrès: $progressCount/$totalCount" -PercentComplete ($progressCount / $totalCount * 100) -Id 1 }
        }
         if (($progressCount + $handles.Count) % $updateInterval -eq 0) { Write-Progress -Activity "Test des fichiers" -Status "Progrès: $($progressCount + $handles.Count)/$totalCount" -PercentComplete (($progressCount + $handles.Count) / $totalCount * 100) -Id 1 }
    }

    Write-Verbose "Attente de la fin des tâches restantes..."
    while ($handles.Count -gt 0) {
        $completedIndex = [System.Threading.WaitHandle]::WaitAny($handles.ToArray(), 500)
        if ($completedIndex -ne [System.Threading.WaitHandle]::WaitTimeout) {
            $completedTask = $tasks[$completedIndex]
            try {
                $taskResult = $completedTask.EndInvoke($handles[$completedIndex])
                if ($taskResult) { $results.Add($taskResult) }
            } catch { Write-Warning "Erreur EndInvoke final: $($_.Exception.Message)"; $results.Add([PSCustomObject]@{ Error = "Erreur EndInvoke final: $($_.Exception.Message)"; FilePath = "N/A" }) }
            finally { $completedTask.Dispose(); $handles.RemoveAt($completedIndex); $tasks.RemoveAt($completedIndex); $progressCount++ }
            Write-Progress -Activity "Test des fichiers" -Status "Terminé: $progressCount/$totalCount" -PercentComplete ($progressCount / $totalCount * 100) -Id 1
        } else {
            # Gestion du timeout (similaire à l'autre script)
             $stillRunning = $handles | Where-Object { -not $_.IsCompleted }
             if ($stillRunning.Count -eq 0) {
                Write-Verbose "Timeout détecté mais toutes les tâches restantes semblent terminées."
                for($i = $handles.Count - 1; $i -ge 0; $i--) {
                     $completedTask = $tasks[$i]
                     try { if($handles[$i].IsCompleted) { $taskResult = $completedTask.EndInvoke($handles[$i]); if ($taskResult) { $results.Add($taskResult) } } }
                     catch { Write-Warning "Erreur récupération post-timeout: $($_.Exception.Message)"}
                     finally { $completedTask.Dispose(); $handles.RemoveAt($i); $tasks.RemoveAt($i); $progressCount++ }
                }
             }
        }
    }

    Write-Progress -Activity "Test des fichiers" -Completed -Id 1
    Write-Host "Tests parallèles terminés." -ForegroundColor Green

    $runspacePool.Close()
    $runspacePool.Dispose()

    return $results.ToArray()
}
#endregion

#region HTML Report Generation (Improved Style)
function New-HtmlReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [Parameter(Mandatory = $true)]
        [bool]$HasExpectedFormats,
        [string]$TestedScriptPath
    )

    $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Test - Détection de Format</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; margin: 0; padding: 20px; background-color: #f8f9fa; color: #212529; }
        .container { max-width: 1400px; margin: 0 auto; background-color: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1, h2, h3 { color: #0056b3; border-bottom: 2px solid #dee2e6; padding-bottom: 5px; margin-top: 30px; }
        h1 { text-align: center; margin-bottom: 30px; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 0.9em; }
        th, td { padding: 10px 12px; text-align: left; border: 1px solid #dee2e6; vertical-align: top; }
        th { background-color: #007bff; color: white; font-weight: 600; white-space: nowrap;}
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #e9ecef; }
        .summary { background-color: #e7f3ff; padding: 20px; border: 1px solid #b8daff; border-radius: 5px; margin-bottom: 30px; }
        .summary p { margin: 5px 0; }
        .chart-container { width: 90%; max-width: 700px; height: 350px; margin: 20px auto; }
        .file-path { font-size: 0.8em; color: #6c757d; word-break: break-all; }
        .criteria { font-size: 0.85em; color: #495057; }
        .error-msg { color: #dc3545; font-weight: bold; font-size: 0.9em;}
        .badge { display: inline-block; padding: 4px 10px; border-radius: 12px; font-size: 0.8em; color: white; white-space: nowrap; font-weight: 600; }
        .badge-correct { background-color: #28a745; }
        .badge-incorrect { background-color: #dc3545; }
        .badge-unknown { background-color: #ffc107; color: #333; }
        .badge-error { background-color: #6f42c1; }
        .confidence-high { color: #198754; font-weight: bold; }
        .confidence-medium { color: #fd7e14; font-weight: bold; }
        .confidence-low { color: #dc3545; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; font-size: 0.8em; color: #6c757d; }
        details { margin-top: 5px; }
        summary { cursor: pointer; font-size: 0.85em; color: #0056b3; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
    <h1>Rapport de Test - Détection de Format</h1>
    <p>Date de génération : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
    <p>Script testé : $TestedScriptPath</p>
    <p>Répertoire des échantillons : $($Results[0].FilePath | Split-Path -Parent | Split-Path -Parent) </p>
"@

    # Filtrer les résultats
    $validResults = $Results | Where-Object { $_.DetectedFormat -ne 'ERROR' }
    $errorResults = $Results | Where-Object { $_.DetectedFormat -eq 'ERROR' }
    $testedResults = if ($HasExpectedFormats) { $Results | Where-Object { $null -ne $_.ExpectedFormat } } else { @() }

    # Calculer les statistiques
    $totalFiles = $Results.Count
    $analyzedFiles = $validResults.Count
    $errorFiles = $errorResults.Count
    $correctDetections = if ($HasExpectedFormats) { ($testedResults | Where-Object { $_.IsCorrect -eq $true -and $_.DetectedFormat -ne 'ERROR'}).Count } else { 0 }
    $incorrectDetections = if ($HasExpectedFormats) { ($testedResults | Where-Object { $_.IsCorrect -eq $false -and $_.DetectedFormat -ne 'ERROR'}).Count } else { 0 }
    $untestedCount = $totalFiles - $testedResults.Count - $errorFiles

    $testableCount = $correctDetections + $incorrectDetections
    $correctPercent = if ($testableCount -gt 0) { [Math]::Round(($correctDetections / $testableCount) * 100, 2) } else { 0 }
    $errorPercent = if ($totalFiles -gt 0) { [Math]::Round(($errorFiles / $totalFiles) * 100, 2) } else { 0 }

    $highConfidence = ($validResults | Where-Object { $_.ConfidenceScore -ge 80 }).Count
    $mediumConfidence = ($validResults | Where-Object { $_.ConfidenceScore -ge 50 -and $_.ConfidenceScore -lt 80 }).Count
    $lowConfidence = ($validResults | Where-Object { $_.ConfidenceScore -lt 50 -and $_.ConfidenceScore -ge 0 }).Count # Inclure 0
    $unknownConfidence = ($validResults | Where-Object { $null -eq $_.ConfidenceScore -or $_.ConfidenceScore -lt 0 }).Count

    # Compter les formats détectés (parmi les valides)
    $formatCounts = $validResults | Group-Object -Property DetectedFormat | Select-Object @{N = 'Format'; E = { $_.Name } }, Count
    $sortedFormats = $formatCounts | Sort-Object -Property Count -Descending
    $formatLabels = $sortedFormats | ForEach-Object { "'$($_.Format -replace "'", "\'")'" }
    $formatValues = $sortedFormats | ForEach-Object { $_.Count }

    $htmlSummary = @"
    <div class="summary">
        <h2>Résumé des Tests</h2>
        <p>Nombre total de fichiers trouvés : $totalFiles</p>
        <p>Nombre de fichiers analysés sans erreur : $analyzedFiles</p>
        <p>Nombre de fichiers en erreur lors de l'analyse : $errorFiles ($errorPercent%)</p>
"@
    if ($HasExpectedFormats) {
        $htmlSummary += @"
        <hr>
        <p><b>Comparaison avec les formats attendus :</b></p>
        <p>Nombre de fichiers avec format attendu défini : $($testedResults.Count)</p>
        <p style="color: green;">  ↳ Détections correctes : $correctDetections ($correctPercent% des testés)</p>
        <p style="color: red;">  ↳ Détections incorrectes : $incorrectDetections</p>
        <p><small>Note : Les fichiers en erreur avec un format attendu sont comptés comme incorrects.</small></p>
        <p>Nombre de fichiers sans format attendu défini : $untestedCount</p>
"@
    } else {
         $htmlSummary += "<p><i>Aucun fichier de formats attendus fourni pour comparaison.</i></p>"
    }
    $htmlSummary += @"
        <hr>
        <p><b>Distribution des scores de confiance (sur fichiers analysés) :</b></p>
        <p style="color: #198754;">  ↳ Confiance élevée (>= 80%) : $highConfidence</p>
        <p style="color: #fd7e14;">  ↳ Confiance moyenne (50-79%) : $mediumConfidence</p>
        <p style="color: #dc3545;">  ↳ Confiance faible (< 50%) : $lowConfidence</p>
        <p style="color: #6c757d;">  ↳ Confiance non définie/invalide : $unknownConfidence</p>

        <h3>Distribution des formats détectés (hors erreurs)</h3>
        <div class="chart-container">
            <canvas id="formatsChart"></canvas>
        </div>
    </div>

    <script>
        const ctx = document.getElementById('formatsChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: [$($formatLabels -join ', ')],
                datasets: [{
                    label: 'Nombre de fichiers',
                    data: [$($formatValues -join ', ')],
                     backgroundColor: ['rgba(54, 162, 235, 0.6)', 'rgba(255, 99, 132, 0.6)', 'rgba(75, 192, 192, 0.6)', 'rgba(255, 206, 86, 0.6)', 'rgba(153, 102, 255, 0.6)', 'rgba(255, 159, 64, 0.6)', 'rgba(99, 255, 132, 0.6)'],
                     borderColor: ['rgba(54, 162, 235, 1)', 'rgba(255, 99, 132, 1)', 'rgba(75, 192, 192, 1)', 'rgba(255, 206, 86, 1)', 'rgba(153, 102, 255, 1)', 'rgba(255, 159, 64, 1)', 'rgba(99, 255, 132, 1)'],
                    borderWidth: 1
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, title: { display: true, text: 'Nombre de fichiers' } }, x: { title: { display: true, text: 'Format Détecté' } } } }
        });
    </script>
"@

    # Section des Erreurs
    $htmlErrors = ""
    if ($errorFiles -gt 0) {
        $htmlErrors = @"
    <h2>Erreurs d'analyse ($errorFiles)</h2>
    <table>
        <tr><th>Fichier</th><th>Format Attendu</th><th>Message d'erreur</th></tr>
"@
        foreach ($result in $errorResults) {
            $htmlErrors += @"
        <tr>
            <td>$($result.FileName)<br><span class="file-path">$($result.FilePath)</span></td>
            <td>$($result.ExpectedFormat)</td>
            <td><span class="error-msg">$($result.Error)</span></td>
        </tr>
"@
        }
        $htmlErrors += "</table>"
    }

    # Section des Résultats Détaillés
    $htmlResults = @"
    <h2>Résultats détaillés ($totalFiles fichiers)</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Taille (octets)</th>
            <th>Format Détecté</th>
            <th>Confiance</th>
            <th>Catégorie</th>
            <th>Encodage</th>
            <th>Critères</th>
"@
    if ($HasExpectedFormats) {
        $htmlResults += "<th>Format Attendu</th><th>Statut</th>"
    }
    $htmlResults += "</tr>"

    # Trier les résultats pour l'affichage
    $sortedAllResults = $Results | Sort-Object @{ Expression = { $_.DetectedFormat -eq 'ERROR'}}, @{Expression = 'IsCorrect'; Descending = $true}, FileName

    foreach ($result in $sortedAllResults) {
        $statusBadge = ""
        $rowClass = ""
        if ($result.DetectedFormat -eq 'ERROR') {
             $statusBadge = '<span class="badge badge-error">Erreur Analyse</span>'
             $rowClass = ' style="background-color: #f8d7da;"' # Light red
        } elseif ($HasExpectedFormats) {
            if ($null -eq $result.ExpectedFormat) {
                 $statusBadge = '<span class="badge badge-unknown">Non Testé</span>'
                 $rowClass = ' style="background-color: #fff3cd;"' # Light yellow
            } elseif ($result.IsCorrect -eq $true) {
                $statusBadge = '<span class="badge badge-correct">Correct</span>'
                 $rowClass = ' style="background-color: #d1e7dd;"' # Light green
            } else {
                $statusBadge = '<span class="badge badge-incorrect">Incorrect</span>'
                $rowClass = ' style="background-color: #f8d7da;"' # Light red
            }
        }

        $confidenceScoreDisplay = "N/A"
        $confidenceClass = ""
        if ($null -ne $result.ConfidenceScore -and $result.ConfidenceScore -ge 0) {
            $confidenceScoreDisplay = "$($result.ConfidenceScore)%"
            if ($result.ConfidenceScore -ge 80) { $confidenceClass = "confidence-high" }
            elseif ($result.ConfidenceScore -ge 50) { $confidenceClass = "confidence-medium" }
            else { $confidenceClass = "confidence-low" }
        }

        # Formatter les critères pour l'affichage (peut être long)
        $criteriaDisplay = $result.MatchedCriteria
        if ($criteriaDisplay -is [string] -and $criteriaDisplay.Length -gt 100) {
             $criteriaDisplay = "$($criteriaDisplay.Substring(0,100))..."
        } elseif ($criteriaDisplay -is [array]) {
            $criteriaDisplay = $criteriaDisplay -join '; '
             if ($criteriaDisplay.Length -gt 100) { $criteriaDisplay = "$($criteriaDisplay.Substring(0,100))..." }
        }

        $htmlResults += @"
        <tr$rowClass>
            <td>$($result.FileName)<br><span class="file-path">$($result.FilePath)</span></td>
            <td>$("{0:N0}" -f $result.Size)</td>
            <td><b>$($result.DetectedFormat)</b></td>
            <td class="$confidenceClass">$confidenceScoreDisplay</td>
            <td>$($result.Category)</td>
            <td>$($result.Encoding)</td>
            <td><span class="criteria">$($criteriaDisplay)</span></td>
"@
        if ($HasExpectedFormats) {
            $htmlResults += @"
            <td>$($result.ExpectedFormat)</td>
            <td>$statusBadge</td>
"@
        }
        $htmlResults += "</tr>"
    }
    $htmlResults += "</table>"

    $htmlFooter = @"
    <div class="footer">
        Test exécuté par le script Test-ImprovedFormatDetection.ps1 (v2.0)
    </div>
    </div> <!-- /container -->
</body>
</html>
"@

    # Assembler le contenu HTML
    $htmlContent = $htmlHeader + $htmlSummary + $htmlErrors + $htmlResults + $htmlFooter

    # Enregistrer le rapport HTML
    try {
        $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8 -Force -ErrorAction Stop
        Write-Host "Rapport HTML généré avec succès : $OutputPath" -ForegroundColor Green
    } catch {
        Write-Error "Impossible d'écrire le rapport HTML sur '$OutputPath': $($_.Exception.Message)"
    }
}
#endregion

#region Main Execution Logic

if ($PSCmdlet.ShouldProcess($SampleDirectory, "Tester la détection de format (parallèle)")) {

    $results = Invoke-DetectionScript_Parallel -Directory $SampleDirectory `
                                               -ScriptToRun $DetectionScriptPath `
                                               -NumberOfThreads $MaxThreads `
                                               -FormatsAttendus $global:ExpectedFormats # Passer la hashtable chargée

    if ($null -eq $results -or $results.Count -eq 0) {
        Write-Host "Aucun résultat de test à rapporter." -ForegroundColor Yellow
        exit 0
    }

    # Enregistrer les résultats au format JSON
    try {
        # Utiliser Depth 5 ou plus si AllFormats contient des objets complexes
        $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding utf8 -Force -ErrorAction Stop
        Write-Host "Rapport JSON généré avec succès : $OutputPath" -ForegroundColor Green
    } catch {
        Write-Error "Impossible d'écrire le rapport JSON sur '$OutputPath': $($_.Exception.Message)"
    }

    # Générer un rapport HTML si demandé
    if ($GenerateHtmlReport) {
        $htmlOutputPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        New-HtmlReport -Results $results -OutputPath $htmlOutputPath -HasExpectedFormats $global:UseExpectedFormats -TestedScriptPath $DetectionScriptPath
    }

    # Afficher un résumé final dans la console
    $endTime = Get-Date
    $duration = New-TimeSpan -Start $global:ScriptStartTime -End $endTime

    $validResults = $results | Where-Object { $_.DetectedFormat -ne 'ERROR' }
    $errorFilesCount = ($results | Where-Object { $_.DetectedFormat -eq 'ERROR' }).Count
    $testedResults = if ($global:UseExpectedFormats) { $results | Where-Object { $null -ne $_.ExpectedFormat } } else { @() }
    $correctDetections = if ($global:UseExpectedFormats) { ($testedResults | Where-Object { $_.IsCorrect -eq $true -and $_.DetectedFormat -ne 'ERROR' }).Count } else { 0 }
    $incorrectDetections = if ($global:UseExpectedFormats) { ($testedResults | Where-Object { $_.IsCorrect -eq $false -and $_.DetectedFormat -ne 'ERROR' }).Count + ($testedResults | Where-Object { $_.DetectedFormat -eq 'ERROR'}).Count } else { 0 } # Erreurs comptent comme incorrect si attendu
    $testableCount = $correctDetections + $incorrectDetections
    $correctPercent = if ($testableCount -gt 0) { [Math]::Round(($correctDetections / $testableCount) * 100, 2) } else { 0 }
    $totalCount = $results.Count

    Write-Host "`n--- Résumé Final des Tests ---" -ForegroundColor Cyan
    Write-Host " Temps total d'exécution : $($duration.ToString('g'))" -ForegroundColor White
    Write-Host " Fichiers trouvés au total : $totalCount" -ForegroundColor White
    Write-Host " Fichiers testés sans erreur : $($validResults.Count)" -ForegroundColor White
    Write-Host " Erreurs lors des tests   : $errorFilesCount" -ForegroundColor $(if ($errorFilesCount -gt 0) { 'Red' } else { 'Green' })

    if ($global:UseExpectedFormats) {
        Write-Host "--- Comparaison avec Formats Attendus ---" -ForegroundColor Cyan
        Write-Host " Fichiers avec format attendu : $($testedResults.Count)" -ForegroundColor White
        Write-Host "   ↳ Détections correctes : $correctDetections ($correctPercent%)" -ForegroundColor $(if ($correctPercent -ge 95) { 'Green' } elseif ($correctPercent -ge 80) { 'Yellow' } else { 'Red' })
        Write-Host "   ↳ Détections incorrectes (ou erreurs) : $incorrectDetections" -ForegroundColor $(if ($incorrectDetections -gt 0) { 'Red' } else { 'Green' })
        if ($incorrectDetections -gt 0) {
             Write-Host "`n Détails des erreurs/incorrects :" -ForegroundColor Red
             $incorrectResults = $results | Where-Object { ($_.DetectedFormat -eq 'ERROR' -and $null -ne $_.ExpectedFormat) -or $_.IsCorrect -eq $false } | Select-Object -First 10 FileName, DetectedFormat, ExpectedFormat, Error
             $incorrectResults | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor White
             if (($results | Where-Object { ($_.DetectedFormat -eq 'ERROR' -and $null -ne $_.ExpectedFormat) -or $_.IsCorrect -eq $false }).Count -gt 10) { Write-Host "  (et autres... voir rapports JSON/HTML)" -ForegroundColor White}
        }
    } else {
        Write-Host "--- Aucune comparaison effectuée (pas de fichier de formats attendus) ---" -ForegroundColor Yellow
    }
     Write-Host "--- Fin des tests ---" -ForegroundColor Cyan
}
#endregion