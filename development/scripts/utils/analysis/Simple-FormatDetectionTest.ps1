#Requires -Version 5.1
<#
.SYNOPSIS
    Test simplifiÃ© de la dÃ©tection de format amÃ©liorÃ©e.

.DESCRIPTION
    Ce script teste la dÃ©tection de format amÃ©liorÃ©e sur un ensemble de fichiers
    et gÃ©nÃ¨re un rapport des rÃ©sultats. Version simplifiÃ©e sans parallÃ©lisme.

.PARAMETER SampleDirectory
    Le rÃ©pertoire contenant les fichiers Ã  analyser. Par dÃ©faut, utilise le rÃ©pertoire 'samples'.

.PARAMETER OutputPath
    Le chemin oÃ¹ le rapport d'analyse sera enregistrÃ©. Par dÃ©faut, 'SimpleFormatDetectionResults.json'.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ© en plus du rapport JSON.

.EXAMPLE
    .\Simple-FormatDetectionTest.ps1 -SampleDirectory "C:\Samples" -GenerateHtmlReport

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SampleDirectory = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\samples",
    
    [Parameter()]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "SimpleFormatDetectionResults.json"),
    
    [Parameter()]
    [switch]$GenerateHtmlReport
)

# Importer le script de dÃ©tection amÃ©liorÃ©e
$detectionScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Improved-FormatDetection.ps1"
if (-not (Test-Path -Path $detectionScriptPath -PathType Leaf)) {
    Write-Error "Le script de dÃ©tection amÃ©liorÃ©e $detectionScriptPath n'existe pas."
    return
}

# VÃ©rifier si le rÃ©pertoire d'Ã©chantillons existe
if (-not (Test-Path -Path $SampleDirectory -PathType Container)) {
    Write-Error "Le rÃ©pertoire d'Ã©chantillons $SampleDirectory n'existe pas."
    return
}

# RÃ©cupÃ©rer tous les fichiers du rÃ©pertoire (rÃ©cursivement)
$files = Get-ChildItem -Path $SampleDirectory -File -Recurse

Write-Host "Analyse de $($files.Count) fichiers..." -ForegroundColor Cyan

# Analyser chaque fichier
$results = @()
$i = 0
foreach ($file in $files) {
    $i++
    Write-Progress -Activity "Analyse des fichiers" -Status "Fichier $i sur $($files.Count)" -PercentComplete (($i / $files.Count) * 100)
    
    try {
        # DÃ©tecter le format du fichier
        $detectionResult = & $detectionScriptPath -FilePath $file.FullName -DetectEncoding -DetailedOutput
        
        # CrÃ©er un objet rÃ©sultat
        $result = [PSCustomObject]@{
            FilePath = $file.FullName;
            FileName = $file.Name;
            Extension = $file.Extension;
            Size = $file.Length;
            DetectedFormat = $detectionResult.DetectedFormat;
            Category = $detectionResult.Category;
            ConfidenceScore = $detectionResult.ConfidenceScore;
            MatchedCriteria = $detectionResult.MatchedCriteria;
            Encoding = $detectionResult.Encoding;
            AllFormats = $detectionResult.AllFormats;
        }
        
        $results += $result
    } catch {
        Write-Warning "Erreur lors de l'analyse du fichier $($file.FullName) : $_"
        
        # Ajouter un rÃ©sultat d'erreur
        $results += [PSCustomObject]@{
            FilePath = $file.FullName;
            FileName = $file.Name;
            Extension = $file.Extension;
            Size = $file.Length;
            DetectedFormat = "ERROR";
            Category = "ERROR";
            ConfidenceScore = 0;
            MatchedCriteria = "Erreur: $($_.Exception.Message)";
            Encoding = $null;
            AllFormats = $null;
            Error = $_.Exception.Message;
        }
    }
}

Write-Progress -Activity "Analyse des fichiers" -Completed

# Enregistrer les rÃ©sultats au format JSON
$results | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "Rapport JSON gÃ©nÃ©rÃ© : $OutputPath" -ForegroundColor Green

# GÃ©nÃ©rer un rapport HTML si demandÃ©
if ($GenerateHtmlReport) {
    $htmlOutputPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
    
    $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de dÃ©tection de format amÃ©liorÃ©e</title>
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
    <h1>Rapport de dÃ©tection de format amÃ©liorÃ©e</h1>
    <p>Date de gÃ©nÃ©ration : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
"@
    
    # Calculer les statistiques
    $totalFiles = $results.Count
    $highConfidence = ($results | Where-Object { $_.ConfidenceScore -ge 80 }).Count
    $mediumConfidence = ($results | Where-Object { $_.ConfidenceScore -ge 50 -and $_.ConfidenceScore -lt 80 }).Count
    $lowConfidence = ($results | Where-Object { $_.ConfidenceScore -lt 50 }).Count
    
    # Compter les formats dÃ©tectÃ©s
    $formatCounts = @{}
    foreach ($result in $results) {
        $format = $result.DetectedFormat
        if (-not $formatCounts.ContainsKey($format)) {
            $formatCounts[$format] = 0
        }
        $formatCounts[$format]++
    }
    
    # Trier les formats par frÃ©quence
    $sortedFormats = $formatCounts.GetEnumerator() | Sort-Object -Property Value -Descending
    
    # GÃ©nÃ©rer les donnÃ©es pour le graphique
    $formatLabels = $sortedFormats | ForEach-Object { "`"$($_.Key)`"" }
    $formatValues = $sortedFormats | ForEach-Object { $_.Value }
    
    $htmlSummary = @"
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Nombre total de fichiers analysÃ©s : $totalFiles</p>
        <p>Fichiers avec confiance Ã©levÃ©e (>= 80%) : $highConfidence</p>
        <p>Fichiers avec confiance moyenne (50-79%) : $mediumConfidence</p>
        <p>Fichiers avec confiance faible (< 50%) : $lowConfidence</p>
        
        <h3>Distribution des formats</h3>
        <div class="chart-container">
            <canvas id="formatsChart"></canvas>
        </div>
    </div>
    
    <script>
        // Graphique de distribution des formats
        const ctx = document.getElementById('formatsChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: [$($formatLabels -join ', ')],
                datasets: [{
                    label: 'Nombre de fichiers',
                    data: [$($formatValues -join ', ')],
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
                            text: 'Format'
                        }
                    }
                }
            }
        });
    </script>
"@
    
    $htmlResults = @"
    <h2>RÃ©sultats de dÃ©tection</h2>
    <table>
        <tr>
            <th>Nom du fichier</th>
            <th>Extension</th>
            <th>Format dÃ©tectÃ©</th>
            <th>CatÃ©gorie</th>
            <th>Confiance</th>
            <th>CritÃ¨res correspondants</th>
            <th>Encodage</th>
        </tr>
"@
    
    foreach ($result in $results) {
        $confidenceClass = ""
        if ($result.ConfidenceScore -ge 80) {
            $confidenceClass = "confidence-high"
        } elseif ($result.ConfidenceScore -ge 50) {
            $confidenceClass = "confidence-medium"
        } else {
            $confidenceClass = "confidence-low"
        }
        
        $htmlResults += @"
        <tr>
            <td>$($result.FileName)</td>
            <td>$($result.Extension)</td>
            <td>$($result.DetectedFormat)</td>
            <td>$($result.Category)</td>
            <td class="$confidenceClass">$($result.ConfidenceScore)%</td>
            <td>$($result.MatchedCriteria)</td>
            <td>$($result.Encoding)</td>
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
    
    Write-Host "Rapport HTML gÃ©nÃ©rÃ© : $htmlOutputPath" -ForegroundColor Green
}

# Afficher un rÃ©sumÃ©
$totalFiles = $results.Count
$highConfidence = ($results | Where-Object { $_.ConfidenceScore -ge 80 }).Count
$mediumConfidence = ($results | Where-Object { $_.ConfidenceScore -ge 50 -and $_.ConfidenceScore -lt 80 }).Count
$lowConfidence = ($results | Where-Object { $_.ConfidenceScore -lt 50 }).Count

Write-Host "`nRÃ©sumÃ© de l'analyse :" -ForegroundColor Cyan
Write-Host "  Nombre total de fichiers analysÃ©s : $totalFiles" -ForegroundColor White
Write-Host "  Fichiers avec confiance Ã©levÃ©e (>= 80%) : $highConfidence" -ForegroundColor Green
Write-Host "  Fichiers avec confiance moyenne (50-79%) : $mediumConfidence" -ForegroundColor Yellow
Write-Host "  Fichiers avec confiance faible (< 50%) : $lowConfidence" -ForegroundColor Red

# Afficher les formats les plus frÃ©quents
$formatCounts = @{}
foreach ($result in $results) {
    $format = $result.DetectedFormat
    if (-not $formatCounts.ContainsKey($format)) {
        $formatCounts[$format] = 0
    }
    $formatCounts[$format]++
}

$sortedFormats = $formatCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5

Write-Host "`nFormats les plus frÃ©quents :" -ForegroundColor Cyan
foreach ($format in $sortedFormats) {
    Write-Host "  $($format.Key): $($format.Value) fichiers" -ForegroundColor White
}
