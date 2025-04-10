#Requires -Version 5.1
<#
.SYNOPSIS
    Teste la détection d'encodage sur un ensemble de fichiers.

.DESCRIPTION
    Ce script teste la détection d'encodage sur un ensemble de fichiers
    et génère un rapport détaillé des résultats.

.PARAMETER SampleDirectory
    Le répertoire contenant les fichiers à analyser. Par défaut, utilise le répertoire 'samples'.

.PARAMETER OutputPath
    Le chemin où le rapport d'analyse sera enregistré. Par défaut, 'EncodingDetectionResults.json'.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit être généré en plus du rapport JSON.

.PARAMETER ExpectedEncodingsPath
    Le chemin vers un fichier JSON contenant les encodages attendus pour chaque fichier.
    Si spécifié, le script comparera les résultats avec les encodages attendus.

.EXAMPLE
    .\Test-EncodingDetection.ps1 -SampleDirectory "C:\Samples" -GenerateHtmlReport

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SampleDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "samples"),
    
    [Parameter()]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "EncodingDetectionResults.json"),
    
    [Parameter()]
    [switch]$GenerateHtmlReport,
    
    [Parameter()]
    [string]$ExpectedEncodingsPath
)

# Importer le script de détection d'encodage
$detectionScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Detect-FileEncoding.ps1"
if (-not (Test-Path -Path $detectionScriptPath -PathType Leaf)) {
    Write-Error "Le script de détection d'encodage $detectionScriptPath n'existe pas."
    return
}

# Vérifier si le répertoire d'échantillons existe
if (-not (Test-Path -Path $SampleDirectory -PathType Container)) {
    Write-Error "Le répertoire d'échantillons $SampleDirectory n'existe pas."
    return
}

# Charger les encodages attendus si spécifiés
$expectedEncodings = @{}
if ($ExpectedEncodingsPath -and (Test-Path -Path $ExpectedEncodingsPath -PathType Leaf)) {
    try {
        $expectedEncodings = Get-Content -Path $ExpectedEncodingsPath -Raw | ConvertFrom-Json -AsHashtable
        Write-Host "Encodages attendus chargés depuis $ExpectedEncodingsPath" -ForegroundColor Green
    } catch {
        Write-Warning "Impossible de charger les encodages attendus depuis $ExpectedEncodingsPath : $_"
    }
}

# Récupérer tous les fichiers du répertoire (récursivement)
$files = Get-ChildItem -Path $SampleDirectory -File -Recurse

Write-Host "Analyse de $($files.Count) fichiers..." -ForegroundColor Cyan

# Analyser chaque fichier
$results = @()
$i = 0
foreach ($file in $files) {
    $i++
    Write-Progress -Activity "Analyse des fichiers" -Status "Fichier $i sur $($files.Count)" -PercentComplete (($i / $files.Count) * 100)
    
    try {
        # Détecter l'encodage du fichier
        $detectionResult = & $detectionScriptPath -FilePath $file.FullName
        
        # Vérifier si l'encodage détecté correspond à l'encodage attendu
        $expectedEncoding = $null
        $isCorrect = $null
        
        if ($expectedEncodings.ContainsKey($file.FullName)) {
            $expectedEncoding = $expectedEncodings[$file.FullName]
            $isCorrect = $detectionResult.Encoding -eq $expectedEncoding
        }
        
        # Créer un objet résultat
        $result = [PSCustomObject]@{
            FilePath = $file.FullName
            FileName = $file.Name
            Extension = $file.Extension
            Size = $file.Length
            DetectedEncoding = $detectionResult.Encoding
            BOM = $detectionResult.BOM
            Confidence = $detectionResult.Confidence
            Description = $detectionResult.Description
            ExpectedEncoding = $expectedEncoding
            IsCorrect = $isCorrect
        }
        
        $results += $result
    } catch {
        Write-Warning "Erreur lors de l'analyse du fichier $($file.FullName) : $_"
        
        # Ajouter un résultat d'erreur
        $results += [PSCustomObject]@{
            FilePath = $file.FullName
            FileName = $file.Name
            Extension = $file.Extension
            Size = $file.Length
            DetectedEncoding = "ERROR"
            BOM = $false
            Confidence = 0
            Description = "Erreur: $($_.Exception.Message)"
            ExpectedEncoding = $null
            IsCorrect = $null
            Error = $_.Exception.Message
        }
    }
}

Write-Progress -Activity "Analyse des fichiers" -Completed

# Enregistrer les résultats au format JSON
$results | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Rapport JSON généré : $OutputPath" -ForegroundColor Green

# Générer un rapport HTML si demandé
if ($GenerateHtmlReport) {
    $htmlOutputPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
    
    $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de détection d'encodage</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0078D4;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #0078D4;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .incorrect {
            background-color: #FFDDDD;
        }
        .correct {
            background-color: #DDFFDD;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin-bottom: 20px;
        }
        .confidence-high {
            color: green;
            font-weight: bold;
        }
        .confidence-medium {
            color: orange;
            font-weight: bold;
        }
        .confidence-low {
            color: red;
            font-weight: bold;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport de détection d'encodage</h1>
    <p>Date de génération : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
"@
    
    # Calculer les statistiques
    $totalFiles = $results.Count
    $correctDetections = ($results | Where-Object { $_.IsCorrect -eq $true }).Count
    $incorrectDetections = ($results | Where-Object { $_.IsCorrect -eq $false }).Count
    $noExpectedEncoding = ($results | Where-Object { $null -eq $_.ExpectedEncoding }).Count
    $highConfidence = ($results | Where-Object { $_.Confidence -ge 80 }).Count
    $mediumConfidence = ($results | Where-Object { $_.Confidence -ge 50 -and $_.Confidence -lt 80 }).Count
    $lowConfidence = ($results | Where-Object { $_.Confidence -lt 50 }).Count
    $bomFiles = ($results | Where-Object { $_.BOM -eq $true }).Count
    
    $correctPercent = if ($totalFiles -gt 0 -and $correctDetections -gt 0) { [Math]::Round(($correctDetections / ($correctDetections + $incorrectDetections)) * 100, 2) } else { 0 }
    
    # Compter les encodages détectés
    $encodingCounts = @{}
    foreach ($result in $results) {
        $encoding = $result.DetectedEncoding
        if (-not $encodingCounts.ContainsKey($encoding)) {
            $encodingCounts[$encoding] = 0
        }
        $encodingCounts[$encoding]++
    }
    
    # Trier les encodages par fréquence
    $sortedEncodings = $encodingCounts.GetEnumerator() | Sort-Object -Property Value -Descending
    
    # Générer les données pour le graphique
    $encodingLabels = $sortedEncodings | ForEach-Object { "`"$($_.Key)`"" }
    $encodingValues = $sortedEncodings | ForEach-Object { $_.Value }
    
    $htmlSummary = @"
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total de fichiers analysés : $totalFiles</p>
"@
    
    if ($correctDetections -gt 0 -or $incorrectDetections -gt 0) {
        $htmlSummary += @"
        <p>Détections correctes : $correctDetections ($correctPercent%)</p>
        <p>Détections incorrectes : $incorrectDetections</p>
        <p>Fichiers sans encodage attendu : $noExpectedEncoding</p>
"@
    }
    
    $htmlSummary += @"
        <p>Fichiers avec confiance élevée (>= 80%) : $highConfidence</p>
        <p>Fichiers avec confiance moyenne (50-79%) : $mediumConfidence</p>
        <p>Fichiers avec confiance faible (< 50%) : $lowConfidence</p>
        <p>Fichiers avec BOM : $bomFiles</p>
        
        <h3>Distribution des encodages</h3>
        <div class="chart-container">
            <canvas id="encodingsChart"></canvas>
        </div>
    </div>
    
    <script>
        // Graphique de distribution des encodages
        const ctx = document.getElementById('encodingsChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: [$($encodingLabels -join ', ')],
                datasets: [{
                    label: 'Nombre de fichiers',
                    data: [$($encodingValues -join ', ')],
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Nombre de fichiers'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Encodage'
                        }
                    }
                }
            }
        });
    </script>
"@
    
    $htmlResults = @"
    <h2>Résultats de détection</h2>
    <table>
        <tr>
            <th>Nom du fichier</th>
            <th>Extension</th>
            <th>Encodage détecté</th>
            <th>BOM</th>
            <th>Confiance</th>
            <th>Description</th>
"@
    
    if ($correctDetections -gt 0 -or $incorrectDetections -gt 0) {
        $htmlResults += @"
            <th>Encodage attendu</th>
            <th>Correct</th>
"@
    }
    
    $htmlResults += @"
        </tr>
"@
    
    foreach ($result in $results) {
        $rowClass = ""
        if ($result.IsCorrect -eq $true) {
            $rowClass = " class='correct'"
        } elseif ($result.IsCorrect -eq $false) {
            $rowClass = " class='incorrect'"
        }
        
        $confidenceClass = ""
        if ($result.Confidence -ge 80) {
            $confidenceClass = "confidence-high"
        } elseif ($result.Confidence -ge 50) {
            $confidenceClass = "confidence-medium"
        } else {
            $confidenceClass = "confidence-low"
        }
        
        $htmlResults += @"
        <tr$rowClass>
            <td>$($result.FileName)</td>
            <td>$($result.Extension)</td>
            <td>$($result.DetectedEncoding)</td>
            <td>$($result.BOM)</td>
            <td class="$confidenceClass">$($result.Confidence)%</td>
            <td>$($result.Description)</td>
"@
        
        if ($correctDetections -gt 0 -or $incorrectDetections -gt 0) {
            $htmlResults += @"
            <td>$($result.ExpectedEncoding)</td>
            <td>$($result.IsCorrect)</td>
"@
        }
        
        $htmlResults += @"
        </tr>
"@
    }
    
    $htmlResults += @"
    </table>
"@
    
    $htmlFooter = @"
</body>
</html>
"@
    
    $htmlContent = $htmlHeader + $htmlSummary + $htmlResults + $htmlFooter
    
    # Enregistrer le rapport HTML
    $htmlContent | Out-File -FilePath $htmlOutputPath -Encoding utf8
    
    Write-Host "Rapport HTML généré : $htmlOutputPath" -ForegroundColor Green
}

# Afficher un résumé
$totalFiles = $results.Count
$correctDetections = ($results | Where-Object { $_.IsCorrect -eq $true }).Count
$incorrectDetections = ($results | Where-Object { $_.IsCorrect -eq $false }).Count
$noExpectedEncoding = ($results | Where-Object { $null -eq $_.ExpectedEncoding }).Count
$highConfidence = ($results | Where-Object { $_.Confidence -ge 80 }).Count
$mediumConfidence = ($results | Where-Object { $_.Confidence -ge 50 -and $_.Confidence -lt 80 }).Count
$lowConfidence = ($results | Where-Object { $_.Confidence -lt 50 }).Count
$bomFiles = ($results | Where-Object { $_.BOM -eq $true }).Count

Write-Host "`nRésumé de l'analyse :" -ForegroundColor Cyan
Write-Host "  Nombre total de fichiers analysés : $totalFiles" -ForegroundColor White

if ($correctDetections -gt 0 -or $incorrectDetections -gt 0) {
    $correctPercent = if ($totalFiles -gt 0 -and $correctDetections -gt 0) { [Math]::Round(($correctDetections / ($correctDetections + $incorrectDetections)) * 100, 2) } else { 0 }
    Write-Host "  Détections correctes : $correctDetections ($correctPercent%)" -ForegroundColor $(if ($correctPercent -ge 80) { "Green" } elseif ($correctPercent -ge 50) { "Yellow" } else { "Red" })
    Write-Host "  Détections incorrectes : $incorrectDetections" -ForegroundColor $(if ($incorrectDetections -gt 0) { "Red" } else { "Green" })
    Write-Host "  Fichiers sans encodage attendu : $noExpectedEncoding" -ForegroundColor White
}

Write-Host "  Fichiers avec confiance élevée (>= 80%) : $highConfidence" -ForegroundColor Green
Write-Host "  Fichiers avec confiance moyenne (50-79%) : $mediumConfidence" -ForegroundColor Yellow
Write-Host "  Fichiers avec confiance faible (< 50%) : $lowConfidence" -ForegroundColor Red
Write-Host "  Fichiers avec BOM : $bomFiles" -ForegroundColor Cyan

# Afficher les encodages les plus fréquents
$encodingCounts = @{}
foreach ($result in $results) {
    $encoding = $result.DetectedEncoding
    if (-not $encodingCounts.ContainsKey($encoding)) {
        $encodingCounts[$encoding] = 0
    }
    $encodingCounts[$encoding]++
}

$sortedEncodings = $encodingCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5

Write-Host "`nEncodages les plus fréquents :" -ForegroundColor Cyan
foreach ($encoding in $sortedEncodings) {
    Write-Host "  $($encoding.Key): $($encoding.Value) fichiers" -ForegroundColor White
}

# Afficher les encodages incorrectement détectés si des encodages attendus sont disponibles
if ($incorrectDetections -gt 0) {
    $incorrectResults = $results | Where-Object { $_.IsCorrect -eq $false } | Sort-Object -Property Confidence -Descending
    
    Write-Host "`nEncodages incorrectement détectés :" -ForegroundColor Red
    foreach ($result in $incorrectResults) {
        Write-Host "  $($result.FileName) - Détecté: $($result.DetectedEncoding), Attendu: $($result.ExpectedEncoding), Confiance: $($result.Confidence)%" -ForegroundColor White
    }
}
