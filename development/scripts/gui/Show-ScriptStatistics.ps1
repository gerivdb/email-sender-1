#Requires -Version 5.1
<#
.SYNOPSIS
    Affiche des statistiques sur les scripts du projet
.DESCRIPTION
    Ce script gÃ©nÃ¨re et affiche des statistiques sur les scripts du projet,
    notamment la distribution par catÃ©gorie, langage, auteur, etc.
.PARAMETER Path
    Chemin du rÃ©pertoire Ã  analyser
.PARAMETER OutputFormat
    Format de sortie du rapport (Console, HTML)
.PARAMETER OutputPath
    Chemin du fichier de sortie
.EXAMPLE
    .\Show-ScriptStatistics.ps1 -Path "C:\Scripts" -OutputFormat HTML
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: statistiques, scripts, graphiques
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "HTML")]
    [string]$OutputFormat = "HTML",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "reports/script_statistics.html"
)

# Importer les modules nÃ©cessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-HtmlReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Scripts,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Calculer les statistiques
    $totalScripts = $Scripts.Count
    $scriptsByLanguage = $Scripts | Group-Object -Property Language | Sort-Object -Property Count -Descending
    $scriptsByCategory = $Scripts | Group-Object -Property Category | Sort-Object -Property Count -Descending
    $scriptsByAuthor = $Scripts | Group-Object -Property Author | Sort-Object -Property Count -Descending
    $scriptsByMonth = $Scripts | Group-Object -Property { $_.LastModified.ToString("yyyy-MM") } | Sort-Object -Property Name
    
    # Calculer la distribution des tailles de scripts
    $smallScripts = ($Scripts | Where-Object { $_.LineCount -lt 100 }).Count
    $mediumScripts = ($Scripts | Where-Object { $_.LineCount -ge 100 -and $_.LineCount -lt 500 }).Count
    $largeScripts = ($Scripts | Where-Object { $_.LineCount -ge 500 }).Count
    
    # GÃ©nÃ©rer le contenu HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Statistiques des Scripts</title>
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
        .chart-container {
            width: 100%;
            height: 400px;
            margin-top: 30px;
            margin-bottom: 50px;
        }
        .chart-row {
            display: flex;
            flex-wrap: wrap;
            justify-content: space-between;
        }
        .chart-col {
            flex: 0 0 48%;
            margin-bottom: 30px;
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
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>Statistiques des Scripts</h1>
        
        <div class="summary">
            <h2>RÃ©sumÃ©</h2>
            <p><strong>Date d'analyse:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
            <p><strong>Nombre total de scripts:</strong> $totalScripts</p>
            <p><strong>Nombre de langages:</strong> $($scriptsByLanguage.Count)</p>
            <p><strong>Nombre de catÃ©gories:</strong> $($scriptsByCategory.Count)</p>
            <p><strong>Nombre d'auteurs:</strong> $($scriptsByAuthor.Count)</p>
        </div>
        
        <div class="chart-row">
            <div class="chart-col">
                <h2>Distribution par langage</h2>
                <div class="chart-container">
                    <canvas id="languageChart"></canvas>
                </div>
            </div>
            
            <div class="chart-col">
                <h2>Distribution par catÃ©gorie</h2>
                <div class="chart-container">
                    <canvas id="categoryChart"></canvas>
                </div>
            </div>
        </div>
        
        <div class="chart-row">
            <div class="chart-col">
                <h2>Distribution par auteur</h2>
                <div class="chart-container">
                    <canvas id="authorChart"></canvas>
                </div>
            </div>
            
            <div class="chart-col">
                <h2>Distribution par taille</h2>
                <div class="chart-container">
                    <canvas id="sizeChart"></canvas>
                </div>
            </div>
        </div>
        
        <h2>Ã‰volution dans le temps</h2>
        <div class="chart-container">
            <canvas id="timelineChart"></canvas>
        </div>
        
        <h2>Top 10 des scripts les plus grands</h2>
        <table>
            <tr>
                <th>Nom</th>
                <th>Langage</th>
                <th>CatÃ©gorie</th>
                <th>Auteur</th>
                <th>Lignes</th>
                <th>DerniÃ¨re modification</th>
            </tr>
"@

    # Ajouter les 10 plus grands scripts
    $topScripts = $Scripts | Sort-Object -Property LineCount -Descending | Select-Object -First 10
    
    foreach ($script in $topScripts) {
        $html += @"
            <tr>
                <td>$($script.FileName)</td>
                <td>$($script.Language)</td>
                <td>$($script.Category)</td>
                <td>$($script.Author)</td>
                <td>$($script.LineCount)</td>
                <td>$($script.LastModified)</td>
            </tr>
"@
    }

    $html += @"
        </table>
    </div>
    
    <script>
        // DonnÃ©es pour les graphiques
        const languageData = {
            labels: [
"@

    # GÃ©nÃ©rer les donnÃ©es pour le graphique des langages
    $languageLabels = $scriptsByLanguage | ForEach-Object { "'$($_.Name)'" }
    $html += $languageLabels -join ",`n                "

    $html += @"
            ],
            datasets: [{
                label: 'Nombre de scripts',
                data: [
"@

    $languageValues = $scriptsByLanguage | ForEach-Object { $_.Count }
    $html += $languageValues -join ",`n                    "

    $html += @"
                ],
                backgroundColor: [
                    '#4CAF50',
                    '#2196F3',
                    '#FFC107',
                    '#F44336',
                    '#9C27B0',
                    '#FF5722',
                    '#795548',
                    '#607D8B'
                ]
            }]
        };
        
        const categoryData = {
            labels: [
"@

    # GÃ©nÃ©rer les donnÃ©es pour le graphique des catÃ©gories
    $categoryLabels = $scriptsByCategory | ForEach-Object { "'$($_.Name)'" }
    $html += $categoryLabels -join ",`n                "

    $html += @"
            ],
            datasets: [{
                label: 'Nombre de scripts',
                data: [
"@

    $categoryValues = $scriptsByCategory | ForEach-Object { $_.Count }
    $html += $categoryValues -join ",`n                    "

    $html += @"
                ],
                backgroundColor: [
                    '#4CAF50',
                    '#2196F3',
                    '#FFC107',
                    '#F44336',
                    '#9C27B0',
                    '#FF5722',
                    '#795548',
                    '#607D8B'
                ]
            }]
        };
        
        const authorData = {
            labels: [
"@

    # GÃ©nÃ©rer les donnÃ©es pour le graphique des auteurs
    $authorLabels = $scriptsByAuthor | Select-Object -First 10 | ForEach-Object { "'$($_.Name)'" }
    $html += $authorLabels -join ",`n                "

    $html += @"
            ],
            datasets: [{
                label: 'Nombre de scripts',
                data: [
"@

    $authorValues = $scriptsByAuthor | Select-Object -First 10 | ForEach-Object { $_.Count }
    $html += $authorValues -join ",`n                    "

    $html += @"
                ],
                backgroundColor: [
                    '#4CAF50',
                    '#2196F3',
                    '#FFC107',
                    '#F44336',
                    '#9C27B0',
                    '#FF5722',
                    '#795548',
                    '#607D8B'
                ]
            }]
        };
        
        const sizeData = {
            labels: ['Petit (<100 lignes)', 'Moyen (100-500 lignes)', 'Grand (>500 lignes)'],
            datasets: [{
                label: 'Nombre de scripts',
                data: [$smallScripts, $mediumScripts, $largeScripts],
                backgroundColor: [
                    '#4CAF50',
                    '#FFC107',
                    '#F44336'
                ]
            }]
        };
        
        const timelineData = {
            labels: [
"@

    # GÃ©nÃ©rer les donnÃ©es pour le graphique de l'Ã©volution dans le temps
    $timelineLabels = $scriptsByMonth | ForEach-Object { "'$($_.Name)'" }
    $html += $timelineLabels -join ",`n                "

    $html += @"
            ],
            datasets: [{
                label: 'Nombre de scripts',
                data: [
"@

    $timelineValues = $scriptsByMonth | ForEach-Object { $_.Count }
    $html += $timelineValues -join ",`n                    "

    $html += @"
                ],
                backgroundColor: 'rgba(75, 192, 192, 0.2)',
                borderColor: 'rgba(75, 192, 192, 1)',
                borderWidth: 1,
                tension: 0.1
            }]
        };
        
        // CrÃ©er les graphiques
        const languageCtx = document.getElementById('languageChart').getContext('2d');
        new Chart(languageCtx, {
            type: 'pie',
            data: languageData,
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right',
                    },
                    title: {
                        display: true,
                        text: 'Distribution par langage'
                    }
                }
            }
        });
        
        const categoryCtx = document.getElementById('categoryChart').getContext('2d');
        new Chart(categoryCtx, {
            type: 'pie',
            data: categoryData,
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right',
                    },
                    title: {
                        display: true,
                        text: 'Distribution par catÃ©gorie'
                    }
                }
            }
        });
        
        const authorCtx = document.getElementById('authorChart').getContext('2d');
        new Chart(authorCtx, {
            type: 'bar',
            data: authorData,
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: false
                    },
                    title: {
                        display: true,
                        text: 'Top 10 des auteurs'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
        
        const sizeCtx = document.getElementById('sizeChart').getContext('2d');
        new Chart(sizeCtx, {
            type: 'doughnut',
            data: sizeData,
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        position: 'right',
                    },
                    title: {
                        display: true,
                        text: 'Distribution par taille'
                    }
                }
            }
        });
        
        const timelineCtx = document.getElementById('timelineChart').getContext('2d');
        new Chart(timelineCtx, {
            type: 'line',
            data: timelineData,
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: false
                    },
                    title: {
                        display: true,
                        text: 'Ã‰volution dans le temps'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    </script>
</body>
</html>
"@

    # Ã‰crire le fichier HTML
    Set-Content -Path $OutputPath -Value $html -Encoding UTF8
    
    return $OutputPath
}

# RÃ©cupÃ©rer les scripts
Write-Host "RÃ©cupÃ©ration des scripts..." -ForegroundColor Cyan
$scripts = Get-ScriptInventory -Path $Path

# VÃ©rifier qu'il y a des scripts
if (-not $scripts -or $scripts.Count -eq 0) {
    Write-Host "Aucun script trouvÃ© dans le rÃ©pertoire spÃ©cifiÃ©." -ForegroundColor Red
    exit
}

# Afficher les statistiques selon le format demandÃ©
switch ($OutputFormat) {
    "Console" {
        Write-Host "`nStatistiques des scripts:" -ForegroundColor Cyan
        Write-Host "Nombre total de scripts: $($scripts.Count)" -ForegroundColor White
        
        Write-Host "`nDistribution par langage:" -ForegroundColor Cyan
        $scripts | Group-Object -Property Language | Sort-Object -Property Count -Descending | Format-Table -Property @{
            Label = "Langage"
            Expression = { $_.Name }
        }, Count -AutoSize
        
        Write-Host "`nDistribution par catÃ©gorie:" -ForegroundColor Cyan
        $scripts | Group-Object -Property Category | Sort-Object -Property Count -Descending | Format-Table -Property @{
            Label = "CatÃ©gorie"
            Expression = { $_.Name }
        }, Count -AutoSize
        
        Write-Host "`nDistribution par auteur:" -ForegroundColor Cyan
        $scripts | Group-Object -Property Author | Sort-Object -Property Count -Descending | Format-Table -Property @{
            Label = "Auteur"
            Expression = { $_.Name }
        }, Count -AutoSize
        
        Write-Host "`nTop 10 des scripts les plus grands:" -ForegroundColor Cyan
        $scripts | Sort-Object -Property LineCount -Descending | Select-Object -First 10 | Format-Table -Property FileName, Language, Category, Author, LineCount -AutoSize
    }
    "HTML" {
        $outputFilePath = if ($OutputPath -like "*.html") { $OutputPath } else { "$OutputPath.html" }
        $reportPath = New-HtmlReport -Scripts $scripts -OutputPath $outputFilePath
        Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green
        
        # Ouvrir le rapport dans le navigateur par dÃ©faut
        Start-Process $reportPath
    }
}
