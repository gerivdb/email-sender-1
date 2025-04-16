#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse avancée de la similarité entre les scripts
.DESCRIPTION
    Ce script permet d'analyser la similarité entre les scripts du projet
    en utilisant différents algorithmes (Levenshtein, Cosinus, Combiné).
    Il génère des rapports détaillés avec visualisations.
.PARAMETER Path
    Chemin du répertoire à analyser
.PARAMETER Extensions
    Extensions de fichiers à inclure
.PARAMETER Algorithm
    Algorithme à utiliser (Levenshtein, Cosine, Combined)
.PARAMETER SimilarityThreshold
    Seuil de similarité (0-100) pour considérer deux scripts comme similaires
.PARAMETER OutputFormat
    Format de sortie du rapport (Console, CSV, JSON, HTML)
.PARAMETER OutputPath
    Chemin du fichier de sortie
.EXAMPLE
    .\Analyze-ScriptSimilarity.ps1 -Path "C:\Scripts" -Algorithm Combined -SimilarityThreshold 80 -OutputFormat HTML
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: analyse, similarité, scripts
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Extensions = @(".ps1", ".psm1", ".py", ".cmd", ".bat"),
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Levenshtein", "Cosine", "Combined")]
    [string]$Algorithm = "Combined",
    
    [Parameter(Mandatory = $false)]
    [int]$SimilarityThreshold = 80,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "CSV", "JSON", "HTML")]
    [string]$OutputFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "reports/script_similarity"
)

# Importer les modules nécessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

$textSimilarityPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\TextSimilarity.psm1"
Import-Module $textSimilarityPath -Force

# Fonction pour générer un rapport HTML
function New-HtmlReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$Algorithm,
        
        [Parameter(Mandatory = $true)]
        [int]$SimilarityThreshold
    )
    
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Générer le contenu HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de similarité des scripts</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        h1, h2, h3 {
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .summary {
            margin-bottom: 20px;
            padding: 15px;
            background-color: #f0f7ff;
            border-radius: 5px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #ddd;
        }
        .similarity-bar {
            height: 20px;
            background-color: #4CAF50;
            border-radius: 3px;
        }
        .high {
            background-color: #ff6666;
        }
        .medium {
            background-color: #ffcc66;
        }
        .low {
            background-color: #66cc66;
        }
        .chart-container {
            width: 100%;
            height: 400px;
            margin-top: 30px;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Rapport de similarité des scripts</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Date d'analyse:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
            <p><strong>Algorithme utilisé:</strong> $Algorithm</p>
            <p><strong>Seuil de similarité:</strong> $SimilarityThreshold%</p>
            <p><strong>Nombre de paires similaires trouvées:</strong> $($Results.Count)</p>
        </div>
        
        <h2>Résultats détaillés</h2>
        
        <div class="chart-container">
            <canvas id="similarityChart"></canvas>
        </div>
        
        <table>
            <tr>
                <th>Fichier A</th>
                <th>Fichier B</th>
                <th>Similarité</th>
                <th>Visualisation</th>
            </tr>
"@

    foreach ($result in $Results) {
        $fileA = Split-Path -Leaf $result.FileA
        $fileB = Split-Path -Leaf $result.FileB
        $similarity = $result.Similarity
        
        $colorClass = "low"
        if ($similarity -ge 95) {
            $colorClass = "high"
        } elseif ($similarity -ge 85) {
            $colorClass = "medium"
        }
        
        $html += @"
            <tr>
                <td>$fileA</td>
                <td>$fileB</td>
                <td>$similarity%</td>
                <td><div class="similarity-bar $colorClass" style="width: $similarity%;"></div></td>
            </tr>
"@
    }

    $html += @"
        </table>
    </div>
    
    <script>
        // Données pour le graphique
        const similarityData = [
"@

    # Générer les données pour le graphique
    $chartData = @()
    foreach ($result in $Results) {
        $fileA = Split-Path -Leaf $result.FileA
        $fileB = Split-Path -Leaf $result.FileB
        $chartData += "            { label: '$fileA - $fileB', value: $($result.Similarity) }"
    }
    
    $html += $chartData -join ",`n"

    $html += @"
        ];
        
        // Créer le graphique
        const ctx = document.getElementById('similarityChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: similarityData.map(item => item.label),
                datasets: [{
                    label: 'Similarité (%)',
                    data: similarityData.map(item => item.value),
                    backgroundColor: similarityData.map(item => {
                        if (item.value >= 95) return '#ff6666';
                        if (item.value >= 85) return '#ffcc66';
                        return '#66cc66';
                    }),
                    borderColor: 'rgba(0, 0, 0, 0.1)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

    # Écrire le fichier HTML
    Set-Content -Path $OutputPath -Value $html -Encoding UTF8
    
    return $OutputPath
}

# Analyser la similarité des scripts
Write-Host "Analyse de la similarité des scripts..." -ForegroundColor Cyan
Write-Host "Répertoire: $Path" -ForegroundColor White
Write-Host "Algorithme: $Algorithm" -ForegroundColor White
Write-Host "Seuil de similarité: $SimilarityThreshold%" -ForegroundColor White

# Utiliser le module TextSimilarity pour trouver les fichiers similaires
$results = Find-SimilarFiles -Path $Path -Extensions $Extensions -Algorithm $Algorithm -SimilarityThreshold $SimilarityThreshold

# Afficher les résultats selon le format demandé
switch ($OutputFormat) {
    "Console" {
        Write-Host "`nRésultats de l'analyse:" -ForegroundColor Cyan
        
        if ($results.Count -eq 0) {
            Write-Host "Aucun script similaire trouvé." -ForegroundColor Yellow
        } else {
            $results | Format-Table -Property @{
                Label = "Fichier A"
                Expression = { Split-Path -Leaf $_.FileA }
            }, @{
                Label = "Fichier B"
                Expression = { Split-Path -Leaf $_.FileB }
            }, @{
                Label = "Similarité"
                Expression = { "$($_.Similarity)%" }
            }, @{
                Label = "Algorithme"
                Expression = { $_.Algorithm }
            } -AutoSize
        }
    }
    "CSV" {
        $outputFilePath = if ($OutputPath -like "*.csv") { $OutputPath } else { "$OutputPath.csv" }
        $outputDir = Split-Path -Parent $outputFilePath
        
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        $results | Export-Csv -Path $outputFilePath -NoTypeInformation -Encoding UTF8
        Write-Host "Rapport CSV généré: $outputFilePath" -ForegroundColor Green
    }
    "JSON" {
        $outputFilePath = if ($OutputPath -like "*.json") { $OutputPath } else { "$OutputPath.json" }
        $outputDir = Split-Path -Parent $outputFilePath
        
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputFilePath -Encoding UTF8
        Write-Host "Rapport JSON généré: $outputFilePath" -ForegroundColor Green
    }
    "HTML" {
        $outputFilePath = if ($OutputPath -like "*.html") { $OutputPath } else { "$OutputPath.html" }
        $reportPath = New-HtmlReport -Results $results -OutputPath $outputFilePath -Algorithm $Algorithm -SimilarityThreshold $SimilarityThreshold
        Write-Host "Rapport HTML généré: $reportPath" -ForegroundColor Green
        
        # Ouvrir le rapport dans le navigateur par défaut
        Start-Process $reportPath
    }
}

# Afficher un résumé
Write-Host "`nRésumé de l'analyse:" -ForegroundColor Cyan
Write-Host "Nombre de paires de scripts similaires trouvées: $($results.Count)" -ForegroundColor White

if ($results.Count -gt 0) {
    $highSimilarity = ($results | Where-Object { $_.Similarity -ge 95 }).Count
    $mediumSimilarity = ($results | Where-Object { $_.Similarity -ge 85 -and $_.Similarity -lt 95 }).Count
    $lowSimilarity = ($results | Where-Object { $_.Similarity -lt 85 }).Count
    
    Write-Host "Similarité élevée (>= 95%): $highSimilarity" -ForegroundColor Red
    Write-Host "Similarité moyenne (85-94%): $mediumSimilarity" -ForegroundColor Yellow
    Write-Host "Similarité faible (< 85%): $lowSimilarity" -ForegroundColor Green
    
    # Afficher les recommandations
    if ($highSimilarity -gt 0) {
        Write-Host "`nRecommandations:" -ForegroundColor Cyan
        Write-Host "- Envisagez de fusionner ou de supprimer les scripts avec une similarité élevée (>= 95%)" -ForegroundColor White
        Write-Host "- Vérifiez les scripts avec une similarité moyenne (85-94%) pour identifier les parties redondantes" -ForegroundColor White
    }
}
