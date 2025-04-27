#Requires -Version 5.1
<#
.SYNOPSIS
    Mesure la prÃ©cision de la dÃ©tection automatique de format.

.DESCRIPTION
    Ce script mesure la prÃ©cision de la dÃ©tection automatique de format en comparant
    les rÃ©sultats de dÃ©tection avec les formats attendus. Il calcule des mÃ©triques
    telles que la prÃ©cision, le rappel et le F1-score, et gÃ©nÃ¨re des rapports dÃ©taillÃ©s.

.PARAMETER TestDirectory
    Le rÃ©pertoire contenant les fichiers de test.
    Par dÃ©faut, utilise le rÃ©pertoire 'samples' dans le rÃ©pertoire du script.

.PARAMETER ExpectedFormatsPath
    Le chemin vers le fichier JSON contenant les formats attendus pour chaque fichier.
    Par dÃ©faut, utilise 'ExpectedFormats.json' dans le rÃ©pertoire de test.

.PARAMETER OutputDirectory
    Le rÃ©pertoire oÃ¹ les rapports seront enregistrÃ©s.
    Par dÃ©faut, utilise le rÃ©pertoire 'reports' dans le rÃ©pertoire du script.

.PARAMETER IncludeMalformedSamples
    Indique si les Ã©chantillons malformÃ©s doivent Ãªtre inclus dans l'Ã©valuation.

.PARAMETER GenerateHtmlReport
    Indique si un rapport HTML doit Ãªtre gÃ©nÃ©rÃ©.

.EXAMPLE
    .\Measure-DetectionAccuracy.ps1 -GenerateHtmlReport

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "samples"),
    
    [Parameter()]
    [string]$ExpectedFormatsPath = (Join-Path -Path $TestDirectory -ChildPath "ExpectedFormats.json"),
    
    [Parameter()]
    [string]$OutputDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "reports"),
    
    [Parameter()]
    [switch]$IncludeMalformedSamples,
    
    [Parameter()]
    [switch]$GenerateHtmlReport
)

# Importer les scripts nÃ©cessaires
$formatDetectionScript = "$PSScriptRoot\..\analysis\Improved-FormatDetection.ps1"
$ambiguousHandlingScript = "$PSScriptRoot\..\analysis\Handle-AmbiguousFormats.ps1"

if (-not (Test-Path -Path $formatDetectionScript)) {
    Write-Error "Le script de dÃ©tection de format '$formatDetectionScript' n'existe pas."
    exit 1
}

if (-not (Test-Path -Path $ambiguousHandlingScript)) {
    Write-Error "Le script de gestion des cas ambigus '$ambiguousHandlingScript' n'existe pas."
    exit 1
}

# Fonction pour crÃ©er un rÃ©pertoire s'il n'existe pas
function New-DirectoryIfNotExists {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path -PathType Container)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Verbose "RÃ©pertoire crÃ©Ã© : $Path"
    }
}

# Fonction pour charger les formats attendus
function Get-ExpectedFormats {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier des formats attendus '$Path' n'existe pas."
        return @{}
    }
    
    try {
        $expectedFormats = Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable
        return $expectedFormats
    }
    catch {
        Write-Error "Erreur lors du chargement des formats attendus : $_"
        return @{}
    }
}

# Fonction pour calculer les mÃ©triques
function Get-DetectionMetrics {
    param (
        [array]$Results
    )
    
    $totalFiles = $Results.Count
    $correctDetections = ($Results | Where-Object { $_.IsCorrect }).Count
    $ambiguousCases = ($Results | Where-Object { $_.IsAmbiguous }).Count
    $resolvedAmbiguousCases = ($Results | Where-Object { $_.IsAmbiguous -and $_.IsCorrect }).Count
    
    $accuracy = if ($totalFiles -gt 0) { $correctDetections / $totalFiles * 100 } else { 0 }
    $ambiguousResolutionRate = if ($ambiguousCases -gt 0) { $resolvedAmbiguousCases / $ambiguousCases * 100 } else { 0 }
    
    $formatMetrics = @{}
    $formatCounts = @{}
    
    foreach ($result in $Results) {
        $expectedFormat = $result.ExpectedFormat
        
        if (-not $formatMetrics.ContainsKey($expectedFormat)) {
            $formatMetrics[$expectedFormat] = @{
                TruePositives = 0
                FalseNegatives = 0
                FalsePositives = 0
                Precision = 0
                Recall = 0
                F1Score = 0
            }
        }
        
        if (-not $formatCounts.ContainsKey($expectedFormat)) {
            $formatCounts[$expectedFormat] = 0
        }
        
        $formatCounts[$expectedFormat]++
        
        if ($result.IsCorrect) {
            $formatMetrics[$expectedFormat].TruePositives++
        }
        else {
            $formatMetrics[$expectedFormat].FalseNegatives++
            
            $detectedFormat = $result.DetectedFormat
            
            if (-not $formatMetrics.ContainsKey($detectedFormat)) {
                $formatMetrics[$detectedFormat] = @{
                    TruePositives = 0
                    FalseNegatives = 0
                    FalsePositives = 0
                    Precision = 0
                    Recall = 0
                    F1Score = 0
                }
            }
            
            $formatMetrics[$detectedFormat].FalsePositives++
        }
    }
    
    # Calculer la prÃ©cision, le rappel et le F1-score pour chaque format
    foreach ($format in $formatMetrics.Keys) {
        $metrics = $formatMetrics[$format]
        
        $metrics.Precision = if (($metrics.TruePositives + $metrics.FalsePositives) -gt 0) {
            $metrics.TruePositives / ($metrics.TruePositives + $metrics.FalsePositives) * 100
        }
        else {
            0
        }
        
        $metrics.Recall = if (($metrics.TruePositives + $metrics.FalseNegatives) -gt 0) {
            $metrics.TruePositives / ($metrics.TruePositives + $metrics.FalseNegatives) * 100
        }
        else {
            0
        }
        
        $metrics.F1Score = if (($metrics.Precision + $metrics.Recall) -gt 0) {
            2 * ($metrics.Precision * $metrics.Recall) / ($metrics.Precision + $metrics.Recall)
        }
        else {
            0
        }
    }
    
    # Calculer les mÃ©triques globales
    $totalTruePositives = ($formatMetrics.Values | Measure-Object -Property TruePositives -Sum).Sum
    $totalFalsePositives = ($formatMetrics.Values | Measure-Object -Property FalsePositives -Sum).Sum
    $totalFalseNegatives = ($formatMetrics.Values | Measure-Object -Property FalseNegatives -Sum).Sum
    
    $globalPrecision = if (($totalTruePositives + $totalFalsePositives) -gt 0) {
        $totalTruePositives / ($totalTruePositives + $totalFalsePositives) * 100
    }
    else {
        0
    }
    
    $globalRecall = if (($totalTruePositives + $totalFalseNegatives) -gt 0) {
        $totalTruePositives / ($totalTruePositives + $totalFalseNegatives) * 100
    }
    else {
        0
    }
    
    $globalF1Score = if (($globalPrecision + $globalRecall) -gt 0) {
        2 * ($globalPrecision * $globalRecall) / ($globalPrecision + $globalRecall)
    }
    else {
        0
    }
    
    return @{
        TotalFiles = $totalFiles
        CorrectDetections = $correctDetections
        AmbiguousCases = $ambiguousCases
        ResolvedAmbiguousCases = $resolvedAmbiguousCases
        Accuracy = $accuracy
        AmbiguousResolutionRate = $ambiguousResolutionRate
        FormatMetrics = $formatMetrics
        FormatCounts = $formatCounts
        GlobalPrecision = $globalPrecision
        GlobalRecall = $globalRecall
        GlobalF1Score = $globalF1Score
    }
}

# Fonction pour gÃ©nÃ©rer un rapport JSON
function Export-ResultsToJson {
    param (
        [hashtable]$Metrics,
        [array]$DetailedResults,
        [string]$OutputPath
    )
    
    $report = @{
        Metrics = $Metrics
        DetailedResults = $DetailedResults
    }
    
    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Rapport JSON exportÃ© vers '$OutputPath'" -ForegroundColor Green
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function Export-ResultsToHtml {
    param (
        [hashtable]$Metrics,
        [array]$DetailedResults,
        [string]$OutputPath
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de prÃ©cision de dÃ©tection de format</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .metrics {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        .metric-card {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            flex: 1;
            min-width: 200px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .metric-card h3 {
            margin-top: 0;
            color: #3498db;
        }
        .metric-value {
            font-size: 24px;
            font-weight: bold;
            color: #2c3e50;
        }
        .format-metrics {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .format-metrics th, .format-metrics td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .format-metrics th {
            background-color: #3498db;
            color: white;
        }
        .format-metrics tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .format-metrics tr:hover {
            background-color: #e9e9e9;
        }
        .results-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .results-table th, .results-table td {
            padding: 8px 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .results-table th {
            background-color: #3498db;
            color: white;
        }
        .results-table tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .results-table tr:hover {
            background-color: #e9e9e9;
        }
        .correct {
            color: #27ae60;
            font-weight: bold;
        }
        .incorrect {
            color: #e74c3c;
            font-weight: bold;
        }
        .ambiguous {
            color: #f39c12;
            font-weight: bold;
        }
        .chart-container {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        .chart {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            flex: 1;
            min-width: 300px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de prÃ©cision de dÃ©tection de format</h1>
        
        <div class="summary">
            <h2>RÃ©sumÃ©</h2>
            <p><strong>Nombre de fichiers testÃ©s:</strong> $($Metrics.TotalFiles)</p>
            <p><strong>DÃ©tections correctes:</strong> $($Metrics.CorrectDetections) ($([Math]::Round($Metrics.Accuracy, 2))%)</p>
            <p><strong>Cas ambigus:</strong> $($Metrics.AmbiguousCases) (dont $($Metrics.ResolvedAmbiguousCases) rÃ©solus correctement, soit $([Math]::Round($Metrics.AmbiguousResolutionRate, 2))%)</p>
            <p><strong>Date du test:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
        
        <h2>MÃ©triques globales</h2>
        <div class="metrics">
            <div class="metric-card">
                <h3>PrÃ©cision</h3>
                <div class="metric-value">$([Math]::Round($Metrics.GlobalPrecision, 2))%</div>
                <p>Pourcentage de dÃ©tections correctes parmi toutes les dÃ©tections</p>
            </div>
            <div class="metric-card">
                <h3>Rappel</h3>
                <div class="metric-value">$([Math]::Round($Metrics.GlobalRecall, 2))%</div>
                <p>Pourcentage de formats correctement identifiÃ©s</p>
            </div>
            <div class="metric-card">
                <h3>F1-Score</h3>
                <div class="metric-value">$([Math]::Round($Metrics.GlobalF1Score, 2))%</div>
                <p>Moyenne harmonique de la prÃ©cision et du rappel</p>
            </div>
        </div>
        
        <h2>MÃ©triques par format</h2>
        <table class="format-metrics">
            <thead>
                <tr>
                    <th>Format</th>
                    <th>Nombre de fichiers</th>
                    <th>PrÃ©cision</th>
                    <th>Rappel</th>
                    <th>F1-Score</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($format in $Metrics.FormatMetrics.Keys | Sort-Object) {
        $formatMetrics = $Metrics.FormatMetrics[$format]
        $formatCount = if ($Metrics.FormatCounts.ContainsKey($format)) { $Metrics.FormatCounts[$format] } else { 0 }
        
        $html += @"
                <tr>
                    <td>$format</td>
                    <td>$formatCount</td>
                    <td>$([Math]::Round($formatMetrics.Precision, 2))%</td>
                    <td>$([Math]::Round($formatMetrics.Recall, 2))%</td>
                    <td>$([Math]::Round($formatMetrics.F1Score, 2))%</td>
                </tr>
"@
    }

    $html += @"
            </tbody>
        </table>
        
        <h2>RÃ©sultats dÃ©taillÃ©s</h2>
        <table class="results-table">
            <thead>
                <tr>
                    <th>Fichier</th>
                    <th>Format attendu</th>
                    <th>Format dÃ©tectÃ©</th>
                    <th>Score de confiance</th>
                    <th>RÃ©sultat</th>
                    <th>Ambigu</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($result in $DetailedResults | Sort-Object -Property FilePath) {
        $resultClass = if ($result.IsCorrect) { "correct" } else { "incorrect" }
        $ambiguousClass = if ($result.IsAmbiguous) { "ambiguous" } else { "" }
        
        $html += @"
                <tr>
                    <td>$($result.FilePath)</td>
                    <td>$($result.ExpectedFormat)</td>
                    <td>$($result.DetectedFormat)</td>
                    <td>$($result.ConfidenceScore)%</td>
                    <td class="$resultClass">$(if ($result.IsCorrect) { "Correct" } else { "Incorrect" })</td>
                    <td class="$ambiguousClass">$(if ($result.IsAmbiguous) { "Oui" } else { "Non" })</td>
                </tr>
"@
    }

    $html += @"
            </tbody>
        </table>
    </div>
</body>
</html>
"@

    $html | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Rapport HTML exportÃ© vers '$OutputPath'" -ForegroundColor Green
}

# Fonction principale
function Main {
    # VÃ©rifier si le rÃ©pertoire de test existe
    if (-not (Test-Path -Path $TestDirectory -PathType Container)) {
        Write-Error "Le rÃ©pertoire de test '$TestDirectory' n'existe pas."
        exit 1
    }
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    New-DirectoryIfNotExists -Path $OutputDirectory
    
    # Charger les formats attendus
    $expectedFormats = Get-ExpectedFormats -Path $ExpectedFormatsPath
    
    if ($expectedFormats.Count -eq 0) {
        Write-Error "Aucun format attendu n'a Ã©tÃ© chargÃ©."
        exit 1
    }
    
    # RÃ©cupÃ©rer les fichiers de test
    $testFiles = @()
    
    if ($IncludeMalformedSamples) {
        # Inclure les Ã©chantillons malformÃ©s
        $malformedSamplesDir = Join-Path -Path $PSScriptRoot -ChildPath "malformed_samples"
        
        if (Test-Path -Path $malformedSamplesDir -PathType Container) {
            $testFiles += Get-ChildItem -Path $malformedSamplesDir -File -Recurse
        }
        else {
            Write-Warning "Le rÃ©pertoire des Ã©chantillons malformÃ©s '$malformedSamplesDir' n'existe pas."
        }
    }
    
    # Ajouter les fichiers d'Ã©chantillon normaux
    $formatSamplesDir = Join-Path -Path $TestDirectory -ChildPath "formats"
    
    if (Test-Path -Path $formatSamplesDir -PathType Container) {
        $testFiles += Get-ChildItem -Path $formatSamplesDir -File
    }
    else {
        $testFiles += Get-ChildItem -Path $TestDirectory -File -Exclude "*.json"
    }
    
    if ($testFiles.Count -eq 0) {
        Write-Error "Aucun fichier de test n'a Ã©tÃ© trouvÃ©."
        exit 1
    }
    
    Write-Host "Ã‰valuation de la prÃ©cision de dÃ©tection sur $($testFiles.Count) fichiers..." -ForegroundColor Yellow
    
    # Tester chaque fichier
    $results = @()
    
    foreach ($file in $testFiles) {
        $filePath = $file.FullName
        $fileName = $file.Name
        
        Write-Verbose "Test du fichier : $fileName"
        
        # DÃ©terminer le format attendu
        $expectedFormat = $null
        
        foreach ($pattern in $expectedFormats.Keys) {
            if ($fileName -like $pattern) {
                $expectedFormat = $expectedFormats[$pattern]
                break
            }
        }
        
        if ($null -eq $expectedFormat) {
            Write-Warning "Aucun format attendu trouvÃ© pour le fichier '$fileName'. Ce fichier sera ignorÃ©."
            continue
        }
        
        # ExÃ©cuter la dÃ©tection de format
        $detectionResult = & $ambiguousHandlingScript -FilePath $filePath -AutoResolve
        
        # DÃ©terminer si le cas est ambigu
        $topFormats = $detectionResult.AllFormats | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2
        $isAmbiguous = ($topFormats.Count -ge 2) -and (($topFormats[0].Score - $topFormats[1].Score) -lt 20)
        
        # DÃ©terminer si la dÃ©tection est correcte
        $isCorrect = $detectionResult.DetectedFormat -eq $expectedFormat
        
        # Ajouter le rÃ©sultat Ã  la liste
        $results += [PSCustomObject]@{
            FilePath = $fileName
            ExpectedFormat = $expectedFormat
            DetectedFormat = $detectionResult.DetectedFormat
            ConfidenceScore = $detectionResult.ConfidenceScore
            IsCorrect = $isCorrect
            IsAmbiguous = $isAmbiguous
        }
    }
    
    # Calculer les mÃ©triques
    $metrics = Get-DetectionMetrics -Results $results
    
    # Afficher les rÃ©sultats
    Write-Host "`n===== RÃ‰SULTATS DE L'Ã‰VALUATION =====" -ForegroundColor Cyan
    Write-Host "Nombre de fichiers testÃ©s : $($metrics.TotalFiles)" -ForegroundColor White
    Write-Host "DÃ©tections correctes : $($metrics.CorrectDetections) ($([Math]::Round($metrics.Accuracy, 2))%)" -ForegroundColor White
    Write-Host "Cas ambigus : $($metrics.AmbiguousCases) (dont $($metrics.ResolvedAmbiguousCases) rÃ©solus correctement, soit $([Math]::Round($metrics.AmbiguousResolutionRate, 2))%)" -ForegroundColor White
    
    Write-Host "`nMÃ©triques globales :" -ForegroundColor Yellow
    Write-Host "PrÃ©cision : $([Math]::Round($metrics.GlobalPrecision, 2))%" -ForegroundColor White
    Write-Host "Rappel : $([Math]::Round($metrics.GlobalRecall, 2))%" -ForegroundColor White
    Write-Host "F1-Score : $([Math]::Round($metrics.GlobalF1Score, 2))%" -ForegroundColor White
    
    Write-Host "`nMÃ©triques par format :" -ForegroundColor Yellow
    
    foreach ($format in $metrics.FormatMetrics.Keys | Sort-Object) {
        $formatMetrics = $metrics.FormatMetrics[$format]
        $formatCount = if ($metrics.FormatCounts.ContainsKey($format)) { $metrics.FormatCounts[$format] } else { 0 }
        
        Write-Host "$format ($formatCount fichiers) :" -ForegroundColor Cyan
        Write-Host "  PrÃ©cision : $([Math]::Round($formatMetrics.Precision, 2))%" -ForegroundColor White
        Write-Host "  Rappel : $([Math]::Round($formatMetrics.Recall, 2))%" -ForegroundColor White
        Write-Host "  F1-Score : $([Math]::Round($formatMetrics.F1Score, 2))%" -ForegroundColor White
    }
    
    Write-Host "`n==========================================" -ForegroundColor Cyan
    
    # Exporter les rÃ©sultats
    $jsonOutputPath = Join-Path -Path $OutputDirectory -ChildPath "DetectionAccuracy.json"
    Export-ResultsToJson -Metrics $metrics -DetailedResults $results -OutputPath $jsonOutputPath
    
    if ($GenerateHtmlReport) {
        $htmlOutputPath = Join-Path -Path $OutputDirectory -ChildPath "DetectionAccuracy.html"
        Export-ResultsToHtml -Metrics $metrics -DetailedResults $results -OutputPath $htmlOutputPath
    }
    
    return @{
        Metrics = $metrics
        DetailedResults = $results
    }
}

# ExÃ©cuter la fonction principale
$result = Main
return $result
