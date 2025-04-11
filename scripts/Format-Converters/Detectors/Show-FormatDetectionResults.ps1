#Requires -Version 5.1
<#
.SYNOPSIS
    Affiche les résultats de détection de format.

.DESCRIPTION
    Ce script affiche les résultats de détection de format de manière conviviale.
    Il peut également exporter les résultats dans différents formats.

.PARAMETER FilePath
    Le chemin du fichier analysé.

.PARAMETER DetectionResult
    Le résultat de la détection de format.

.PARAMETER ShowAllFormats
    Indique si tous les formats détectés doivent être affichés.

.PARAMETER ExportFormat
    Le format d'exportation des résultats. Les valeurs possibles sont : "JSON", "CSV", "HTML".

.PARAMETER OutputPath
    Le chemin où exporter les résultats.

.EXAMPLE
    Show-FormatDetectionResults -FilePath "C:\path\to\file.txt" -DetectionResult $result
    Affiche les résultats de détection de format pour le fichier spécifié.

.EXAMPLE
    Show-FormatDetectionResults -FilePath "C:\path\to\file.txt" -DetectionResult $result -ShowAllFormats
    Affiche tous les formats détectés pour le fichier spécifié.

.EXAMPLE
    Show-FormatDetectionResults -FilePath "C:\path\to\file.txt" -DetectionResult $result -ExportFormat "HTML" -OutputPath "C:\path\to\results.html"
    Exporte les résultats de détection de format au format HTML.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

function Show-FormatDetectionResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DetectionResult,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowAllFormats,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "HTML")]
        [string]$ExportFormat,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    # Afficher les informations de base
    Write-Host "Résultats de détection de format pour '$FilePath'" -ForegroundColor Cyan
    Write-Host "Taille du fichier : $($DetectionResult.Size) octets" -ForegroundColor Gray
    Write-Host "Type de fichier : $(if ($DetectionResult.IsBinary) { 'Binaire' } else { 'Texte' })" -ForegroundColor Gray
    
    # Afficher le format détecté
    if ($DetectionResult.DetectedFormat) {
        Write-Host "Format détecté: $($DetectionResult.DetectedFormat)" -ForegroundColor Green
        
        # Afficher le score de confiance avec une couleur appropriée
        $confidenceColor = switch ($DetectionResult.ConfidenceScore) {
            { $_ -ge 90 } { "Green" }
            { $_ -ge 70 } { "Yellow" }
            default { "Red" }
        }
        
        Write-Host "Score de confiance: $($DetectionResult.ConfidenceScore)%" -ForegroundColor $confidenceColor
        Write-Host "Critères correspondants: $($DetectionResult.MatchedCriteria)" -ForegroundColor Gray
    }
    else {
        Write-Host "Aucun format détecté." -ForegroundColor Red
    }
    
    # Afficher tous les formats détectés si demandé
    if ($ShowAllFormats -and $DetectionResult.AllFormats) {
        Write-Host "`nTous les formats détectés:" -ForegroundColor Cyan
        
        $sortedFormats = $DetectionResult.AllFormats | Sort-Object -Property Score, Priority -Descending
        
        foreach ($format in $sortedFormats) {
            $scoreColor = switch ($format.Score) {
                { $_ -ge 90 } { "Green" }
                { $_ -ge 70 } { "Yellow" }
                default { "Gray" }
            }
            
            Write-Host "  - $($format.Format) (Score: " -NoNewline
            Write-Host "$($format.Score)%" -ForegroundColor $scoreColor -NoNewline
            Write-Host ", Priorité: $($format.Priority))"
            
            if ($format.MatchedCriteria) {
                Write-Host "    Critères: $($format.MatchedCriteria -join ", ")" -ForegroundColor Gray
            }
        }
    }
    
    # Exporter les résultats si demandé
    if ($ExportFormat) {
        if (-not $OutputPath) {
            $OutputPath = [System.IO.Path]::ChangeExtension($FilePath, "detection.$($ExportFormat.ToLower())")
        }
        
        switch ($ExportFormat) {
            "JSON" {
                $DetectionResult | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
            }
            "CSV" {
                if ($DetectionResult.AllFormats) {
                    $csvData = foreach ($format in $DetectionResult.AllFormats) {
                        [PSCustomObject]@{
                            FilePath = $FilePath
                            Format = $format.Format
                            Score = $format.Score
                            Priority = $format.Priority
                            IsDetected = ($format.Format -eq $DetectionResult.DetectedFormat)
                            IsBinary = $DetectionResult.IsBinary
                            FileSize = $DetectionResult.Size
                        }
                    }
                    
                    $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                }
                else {
                    [PSCustomObject]@{
                        FilePath = $FilePath
                        Format = $DetectionResult.DetectedFormat
                        Score = $DetectionResult.ConfidenceScore
                        Priority = 0
                        IsDetected = $true
                        IsBinary = $DetectionResult.IsBinary
                        FileSize = $DetectionResult.Size
                    } | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                }
            }
            "HTML" {
                $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Résultats de détection de format</title>
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
            max-width: 800px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2 {
            color: #2c3e50;
        }
        h1 {
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .file-info {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .detection-result {
            background-color: #e8f4f8;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 10px;
            border-left: 4px solid #3498db;
        }
        .format-list {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .format-list th, .format-list td {
            padding: 8px 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .format-list th {
            background-color: #3498db;
            color: white;
        }
        .format-list tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .score-high {
            color: #27ae60;
            font-weight: bold;
        }
        .score-medium {
            color: #f39c12;
            font-weight: bold;
        }
        .score-low {
            color: #7f8c8d;
        }
        .detected {
            background-color: #e8f8f5;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Résultats de détection de format</h1>
        
        <div class="file-info">
            <h2>Informations sur le fichier</h2>
            <p><strong>Chemin:</strong> $FilePath</p>
            <p><strong>Taille:</strong> $($DetectionResult.Size) octets</p>
            <p><strong>Type:</strong> $(if ($DetectionResult.IsBinary) { 'Binaire' } else { 'Texte' })</p>
        </div>
        
        <div class="detection-result">
            <h2>Résultat de détection</h2>
"@

                if ($DetectionResult.DetectedFormat) {
                    $scoreClass = switch ($DetectionResult.ConfidenceScore) {
                        { $_ -ge 90 } { "score-high" }
                        { $_ -ge 70 } { "score-medium" }
                        default { "score-low" }
                    }
                    
                    $html += @"
            <p><strong>Format détecté:</strong> $($DetectionResult.DetectedFormat)</p>
            <p><strong>Score de confiance:</strong> <span class="$scoreClass">$($DetectionResult.ConfidenceScore)%</span></p>
            <p><strong>Critères correspondants:</strong> $($DetectionResult.MatchedCriteria)</p>
"@
                }
                else {
                    $html += @"
            <p><strong>Aucun format détecté.</strong></p>
"@
                }
                
                $html += @"
        </div>
"@
                
                if ($DetectionResult.AllFormats) {
                    $html += @"
        <h2>Tous les formats détectés</h2>
        <table class="format-list">
            <thead>
                <tr>
                    <th>Format</th>
                    <th>Score</th>
                    <th>Priorité</th>
                    <th>Critères</th>
                </tr>
            </thead>
            <tbody>
"@
                    
                    $sortedFormats = $DetectionResult.AllFormats | Sort-Object -Property Score, Priority -Descending
                    
                    foreach ($format in $sortedFormats) {
                        $scoreClass = switch ($format.Score) {
                            { $_ -ge 90 } { "score-high" }
                            { $_ -ge 70 } { "score-medium" }
                            default { "score-low" }
                        }
                        
                        $rowClass = if ($format.Format -eq $DetectionResult.DetectedFormat) { "detected" } else { "" }
                        
                        $html += @"
                <tr class="$rowClass">
                    <td>$($format.Format)</td>
                    <td class="$scoreClass">$($format.Score)%</td>
                    <td>$($format.Priority)</td>
                    <td>$($format.MatchedCriteria -join ", ")</td>
                </tr>
"@
                    }
                    
                    $html += @"
            </tbody>
        </table>
"@
                }
                
                $html += @"
    </div>
</body>
</html>
"@
                
                $html | Set-Content -Path $OutputPath -Encoding UTF8
            }
        }
        
        Write-Host "`nRésultats exportés au format $ExportFormat : $OutputPath" -ForegroundColor Green
    }
    
    return $DetectionResult
}

# Exporter les fonctions
Export-ModuleMember -Function Show-FormatDetectionResults
