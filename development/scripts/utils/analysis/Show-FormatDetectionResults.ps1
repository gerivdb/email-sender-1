#Requires -Version 5.1
<#
.SYNOPSIS
    Affiche les rÃ©sultats de dÃ©tection de format avec les scores de confiance.

.DESCRIPTION
    Ce script affiche les rÃ©sultats de dÃ©tection de format de fichiers avec leurs scores de confiance
    dans une interface console colorÃ©e. Il peut Ã©galement exporter les rÃ©sultats au format JSON ou HTML.

.PARAMETER FilePath
    Le chemin du fichier Ã  analyser.

.PARAMETER DetectionResult
    Le rÃ©sultat de dÃ©tection de format Ã  afficher. Si non spÃ©cifiÃ©, le script exÃ©cutera la dÃ©tection.

.PARAMETER ExportFormat
    Le format d'exportation des rÃ©sultats (JSON ou HTML). Par dÃ©faut, aucune exportation n'est effectuÃ©e.

.PARAMETER OutputPath
    Le chemin du fichier de sortie pour l'exportation. Par dÃ©faut, utilise le mÃªme nom que le fichier d'entrÃ©e
    avec l'extension appropriÃ©e.

.PARAMETER ShowAllFormats
    Indique si tous les formats dÃ©tectÃ©s doivent Ãªtre affichÃ©s, pas seulement les plus probables.
    Par dÃ©faut, cette option est activÃ©e.

.PARAMETER TopFormatsCount
    Le nombre de formats les plus probables Ã  afficher si ShowAllFormats est dÃ©sactivÃ©.
    Par dÃ©faut, la valeur est de 5.

.EXAMPLE
    .\Show-FormatDetectionResults.ps1 -FilePath "C:\path\to\file.txt"
    Analyse le fichier spÃ©cifiÃ© et affiche les rÃ©sultats de dÃ©tection de format.

.EXAMPLE
    .\Show-FormatDetectionResults.ps1 -FilePath "C:\path\to\file.txt" -ExportFormat HTML -OutputPath "C:\path\to\results.html"
    Analyse le fichier spÃ©cifiÃ©, affiche les rÃ©sultats et les exporte au format HTML.

.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [PSObject]$DetectionResult,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "HTML", "")]
    [string]$ExportFormat = "",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",

    [Parameter(Mandatory = $false)]
    [switch]$ShowAllFormats,

    [Parameter(Mandatory = $false)]
    [int]$TopFormatsCount = 5
)

# Importer le module de dÃ©tection de format
$formatDetectionScript = "$PSScriptRoot\Improved-FormatDetection.ps1"
if (-not (Test-Path -Path $formatDetectionScript)) {
    Write-Error "Le script de dÃ©tection de format '$formatDetectionScript' n'existe pas."
    exit 1
}

# Fonction pour obtenir une couleur en fonction du score
function Get-ScoreColor {
    param (
        [int]$Score
    )

    switch ($Score) {
        {$_ -ge 90} { return "Green" }
        {$_ -ge 70} { return "Yellow" }
        {$_ -ge 50} { return "White" }
        default { return "Gray" }
    }
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function Export-ResultsToHtml {
    param (
        [PSObject]$Result,
        [string]$OutputPath
    )

    $fileName = [System.IO.Path]::GetFileName($Result.FilePath)
    $extension = [System.IO.Path]::GetExtension($Result.FilePath).ToLower()

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RÃ©sultats de dÃ©tection de format - $fileName</title>
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
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .file-info {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .file-info p {
            margin: 5px 0;
        }
        .detection-result {
            background-color: #e8f4f8;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border-left: 4px solid #3498db;
        }
        .format-list {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .format-list th, .format-list td {
            padding: 12px 15px;
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
        .format-list tr:hover {
            background-color: #e9e9e9;
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
        .encoding-info {
            background-color: #f0f8ff;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
            border-left: 4px solid #9b59b6;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>RÃ©sultats de dÃ©tection de format</h1>

        <div class="file-info">
            <p><strong>Fichier:</strong> $fileName</p>
            <p><strong>Chemin:</strong> $($Result.FilePath)</p>
            <p><strong>Extension:</strong> $extension</p>
            <p><strong>Taille:</strong> $($Result.Size) octets</p>
        </div>

        <div class="detection-result">
            <h2>Format dÃ©tectÃ©: $($Result.DetectedFormat)</h2>
            <p><strong>Score de confiance:</strong>
"@

    $scoreClass = switch ($Result.ConfidenceScore) {
        {$_ -ge 90} { "score-high" }
        {$_ -ge 70} { "score-medium" }
        default { "score-low" }
    }

    $html += @"
                <span class="$scoreClass">$($Result.ConfidenceScore)%</span>
            </p>
            <p><strong>CritÃ¨res correspondants:</strong> $($Result.MatchedCriteria)</p>
        </div>

"@

    if ($Result.Encoding) {
        $html += @"
        <div class="encoding-info">
            <h2>Encodage dÃ©tectÃ©</h2>
            <p><strong>Encodage:</strong> $($Result.Encoding.Encoding)</p>
            <p><strong>BOM:</strong> $($Result.Encoding.BOM)</p>
            <p><strong>Confiance:</strong> $($Result.Encoding.Confidence)%</p>
            <p><strong>Description:</strong> $($Result.Encoding.Description)</p>
        </div>

"@
    }

    $html += @"
        <h2>Tous les formats dÃ©tectÃ©s</h2>
        <table class="format-list">
            <thead>
                <tr>
                    <th>Format</th>
                    <th>Score</th>
                    <th>PrioritÃ©</th>
                    <th>CritÃ¨res</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($format in ($Result.AllFormats | Sort-Object -Property Score, Priority -Descending)) {
        $scoreClass = switch ($format.Score) {
            {$_ -ge 90} { "score-high" }
            {$_ -ge 70} { "score-medium" }
            default { "score-low" }
        }

        $criteriaText = $format.MatchedCriteria -join ", "

        $html += @"
                <tr>
                    <td>$($format.Format)</td>
                    <td class="$scoreClass">$($format.Score)%</td>
                    <td>$($format.Priority)</td>
                    <td>$criteriaText</td>
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

# Fonction pour exporter les rÃ©sultats au format JSON
function Export-ResultsToJson {
    param (
        [PSObject]$Result,
        [string]$OutputPath
    )

    $Result | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Rapport JSON exportÃ© vers '$OutputPath'" -ForegroundColor Green
}

# Fonction principale
function Main {
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Error "Le fichier '$FilePath' n'existe pas."
        exit 1
    }

    # Obtenir les rÃ©sultats de dÃ©tection
    if (-not $DetectionResult) {
        $DetectionResult = & $formatDetectionScript -FilePath $FilePath -DetectEncoding -ReturnAllFormats
    }

    # VÃ©rifier si le rÃ©sultat contient les scores de tous les formats
    if (-not $DetectionResult.AllFormats) {
        Write-Error "Le script de dÃ©tection de format n'a pas retournÃ© les scores de tous les formats."
        exit 1
    }

    # Afficher les rÃ©sultats
    $fileName = [System.IO.Path]::GetFileName($DetectionResult.FilePath)
    $extension = [System.IO.Path]::GetExtension($DetectionResult.FilePath).ToLower()

    Write-Host "`n===== RÃ‰SULTATS DE DÃ‰TECTION DE FORMAT =====" -ForegroundColor Cyan
    Write-Host "Fichier: $fileName" -ForegroundColor White
    Write-Host "Chemin: $($DetectionResult.FilePath)" -ForegroundColor White
    Write-Host "Extension: $extension" -ForegroundColor White
    Write-Host "Taille: $($DetectionResult.Size) octets" -ForegroundColor White

    Write-Host "`nFormat dÃ©tectÃ©: " -NoNewline
    Write-Host "$($DetectionResult.DetectedFormat)" -ForegroundColor Green -NoNewline
    Write-Host " avec un score de confiance de " -NoNewline

    $scoreColor = Get-ScoreColor -Score $DetectionResult.ConfidenceScore
    Write-Host "$($DetectionResult.ConfidenceScore)%" -ForegroundColor $scoreColor

    Write-Host "CritÃ¨res correspondants: $($DetectionResult.MatchedCriteria)" -ForegroundColor White

    # Afficher l'encodage si disponible
    if ($DetectionResult.Encoding) {
        Write-Host "`n--- Encodage dÃ©tectÃ© ---" -ForegroundColor Magenta
        Write-Host "Encodage: $($DetectionResult.Encoding.Encoding)" -ForegroundColor White
        Write-Host "BOM: $($DetectionResult.Encoding.BOM)" -ForegroundColor White
        Write-Host "Confiance: $($DetectionResult.Encoding.Confidence)%" -ForegroundColor $(Get-ScoreColor -Score $DetectionResult.Encoding.Confidence)
        Write-Host "Description: $($DetectionResult.Encoding.Description)" -ForegroundColor White
    }

    # Afficher tous les formats dÃ©tectÃ©s
    Write-Host "`n--- Tous les formats dÃ©tectÃ©s ---" -ForegroundColor Yellow

    $formats = $DetectionResult.AllFormats | Sort-Object -Property Score, Priority -Descending

    if (-not $ShowAllFormats) {
        $formats = $formats | Select-Object -First $TopFormatsCount
    }

    foreach ($format in $formats) {
        $scoreColor = Get-ScoreColor -Score $format.Score
        $criteriaText = $format.MatchedCriteria -join ", "

        Write-Host "$($format.Format)" -NoNewline -ForegroundColor Cyan
        Write-Host " - Score: " -NoNewline
        Write-Host "$($format.Score)%" -NoNewline -ForegroundColor $scoreColor
        Write-Host " - PrioritÃ©: $($format.Priority) - CritÃ¨res: $criteriaText"
    }

    Write-Host "`n==========================================" -ForegroundColor Cyan

    # Exporter les rÃ©sultats si demandÃ©
    if ($ExportFormat -ne "") {
        if ($OutputPath -eq "") {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($DetectionResult.FilePath)
            $directory = [System.IO.Path]::GetDirectoryName($DetectionResult.FilePath)

            $extension = switch ($ExportFormat) {
                "JSON" { ".json" }
                "HTML" { ".html" }
                default { ".txt" }
            }

            $OutputPath = Join-Path -Path $directory -ChildPath "$baseName-format-detection$extension"
        }

        switch ($ExportFormat) {
            "JSON" { Export-ResultsToJson -Result $DetectionResult -OutputPath $OutputPath }
            "HTML" { Export-ResultsToHtml -Result $DetectionResult -OutputPath $OutputPath }
        }
    }

    return $DetectionResult
}

# ExÃ©cuter le script
$result = Main
return $result
