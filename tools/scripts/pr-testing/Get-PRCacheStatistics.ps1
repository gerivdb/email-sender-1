#Requires -Version 5.1
<#
.SYNOPSIS
    Obtient les statistiques du cache d'analyse des pull requests.

.DESCRIPTION
    Ce script récupère et affiche des statistiques détaillées sur l'utilisation
    et les performances du cache d'analyse des pull requests.

.PARAMETER CachePath
    Le chemin du cache à analyser.
    Par défaut: "cache\pr-analysis"

.PARAMETER OutputFormat
    Le format de sortie des statistiques.
    Valeurs possibles: "Console", "JSON", "CSV", "HTML"
    Par défaut: "Console"

.PARAMETER OutputPath
    Le chemin où enregistrer les statistiques si un format autre que Console est spécifié.
    Par défaut: "reports\pr-analysis\cache_statistics.{extension}"

.EXAMPLE
    .\Get-PRCacheStatistics.ps1
    Affiche les statistiques du cache dans la console.

.EXAMPLE
    .\Get-PRCacheStatistics.ps1 -OutputFormat "HTML" -OutputPath "reports\cache_stats.html"
    Génère un rapport HTML des statistiques du cache.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$CachePath = "cache\pr-analysis",

    [Parameter()]
    [ValidateSet("Console", "JSON", "CSV", "HTML")]
    [string]$OutputFormat = "Console",

    [Parameter()]
    [string]$OutputPath = ""
)

# Importer le module de cache
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\PRAnalysisCache.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module PRAnalysisCache non trouvé à l'emplacement: $modulePath"
    exit 1
}

# Fonction pour collecter les statistiques du cache
function Get-CacheStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # Résoudre le chemin complet du cache
        $fullPath = $Path
        if (-not [System.IO.Path]::IsPathRooted($Path)) {
            $fullPath = Join-Path -Path $PWD -ChildPath $Path
        }

        # Vérifier si le cache existe
        if (-not (Test-Path -Path $fullPath)) {
            Write-Error "Le répertoire du cache n'existe pas: $fullPath"
            return $null
        }

        # Créer le cache
        $cache = New-PRAnalysisCache -Name "PRAnalysisCache" -CachePath $fullPath
        if ($null -eq $cache) {
            Write-Error "Impossible de créer le cache."
            return $null
        }

        # Obtenir les statistiques de base
        $baseStats = Get-PRCacheStatistics -Cache $cache

        # Collecter des informations supplémentaires
        $cacheConfigPath = Join-Path -Path $fullPath -ChildPath "cache_config.json"
        $cacheConfig = $null
        if (Test-Path -Path $cacheConfigPath) {
            $cacheConfig = Get-Content -Path $cacheConfigPath -Raw | ConvertFrom-Json
        }

        # Collecter des informations sur les fichiers du cache
        $cacheFiles = Get-ChildItem -Path $fullPath -File -Recurse
        $totalSize = ($cacheFiles | Measure-Object -Property Length -Sum).Sum
        $fileCount = $cacheFiles.Count

        # Créer l'objet de statistiques
        $stats = [PSCustomObject]@{
            Timestamp = Get-Date
            CachePath = $fullPath
            BaseStats = $baseStats
            Config = $cacheConfig
            FileStats = [PSCustomObject]@{
                FileCount = $fileCount
                TotalSizeBytes = $totalSize
                TotalSizeMB = [Math]::Round($totalSize / 1MB, 2)
                AverageFileSizeKB = if ($fileCount -gt 0) { [Math]::Round(($totalSize / $fileCount) / 1KB, 2) } else { 0 }
            }
            PerformanceMetrics = [PSCustomObject]@{
                HitRatio = $baseStats.HitRatio
                EfficiencyScore = if (($baseStats.Hits + $baseStats.Misses) -gt 0) {
                    [Math]::Round(($baseStats.Hits / ($baseStats.Hits + $baseStats.Misses)) * 100, 2)
                } else { 0 }
                MemoryUsageEfficiency = if ($baseStats.ItemCount -gt 0) {
                    [Math]::Round(($baseStats.Hits / $baseStats.ItemCount), 2)
                } else { 0 }
            }
        }

        return $stats
    } catch {
        Write-Error "Erreur lors de la collecte des statistiques du cache: $_"
        return $null
    }
}

# Fonction pour générer un rapport HTML
function New-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Stats
    )

    try {
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Statistiques du Cache - Analyse PR</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 8px 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .section {
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .metric {
            display: inline-block;
            width: 23%;
            margin: 1%;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 5px;
            text-align: center;
            box-sizing: border-box;
        }
        .metric h3 {
            margin-top: 0;
            font-size: 16px;
            color: #6c757d;
        }
        .metric p {
            font-size: 24px;
            font-weight: bold;
            margin: 10px 0 0 0;
            color: #343a40;
        }
        .good {
            color: #28a745;
        }
        .warning {
            color: #ffc107;
        }
        .danger {
            color: #dc3545;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Statistiques du Cache - Analyse PR</h1>
        
        <div class="section">
            <h2>Résumé</h2>
            <div class="summary">
                <p><strong>Chemin du cache:</strong> $($Stats.CachePath)</p>
                <p><strong>Date du rapport:</strong> $($Stats.Timestamp)</p>
                
                <div class="metrics">
                    <div class="metric">
                        <h3>Ratio de Hits</h3>
                        <p class="$(if ($Stats.PerformanceMetrics.HitRatio -ge 80) { "good" } elseif ($Stats.PerformanceMetrics.HitRatio -ge 50) { "warning" } else { "danger" })">
                            $($Stats.PerformanceMetrics.HitRatio)%
                        </p>
                    </div>
                    <div class="metric">
                        <h3>Éléments</h3>
                        <p>$($Stats.BaseStats.ItemCount)</p>
                    </div>
                    <div class="metric">
                        <h3>Taille Totale</h3>
                        <p>$($Stats.FileStats.TotalSizeMB) MB</p>
                    </div>
                    <div class="metric">
                        <h3>Efficacité</h3>
                        <p class="$(if ($Stats.PerformanceMetrics.EfficiencyScore -ge 80) { "good" } elseif ($Stats.PerformanceMetrics.EfficiencyScore -ge 50) { "warning" } else { "danger" })">
                            $($Stats.PerformanceMetrics.EfficiencyScore)%
                        </p>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>Statistiques Détaillées</h2>
            
            <h3>Statistiques de Base</h3>
            <table>
                <tr>
                    <th>Métrique</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Nom du Cache</td>
                    <td>$($Stats.BaseStats.Name)</td>
                </tr>
                <tr>
                    <td>Hits</td>
                    <td>$($Stats.BaseStats.Hits)</td>
                </tr>
                <tr>
                    <td>Misses</td>
                    <td>$($Stats.BaseStats.Misses)</td>
                </tr>
                <tr>
                    <td>Éléments en Mémoire</td>
                    <td>$($Stats.BaseStats.ItemCount)</td>
                </tr>
                <tr>
                    <td>Éléments sur Disque</td>
                    <td>$($Stats.BaseStats.DiskItemCount)</td>
                </tr>
                <tr>
                    <td>Ratio de Hits</td>
                    <td>$($Stats.BaseStats.HitRatio)%</td>
                </tr>
            </table>
            
            <h3>Statistiques des Fichiers</h3>
            <table>
                <tr>
                    <th>Métrique</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Nombre de Fichiers</td>
                    <td>$($Stats.FileStats.FileCount)</td>
                </tr>
                <tr>
                    <td>Taille Totale</td>
                    <td>$($Stats.FileStats.TotalSizeMB) MB</td>
                </tr>
                <tr>
                    <td>Taille Moyenne des Fichiers</td>
                    <td>$($Stats.FileStats.AverageFileSizeKB) KB</td>
                </tr>
            </table>
            
            <h3>Métriques de Performance</h3>
            <table>
                <tr>
                    <th>Métrique</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Ratio de Hits</td>
                    <td>$($Stats.PerformanceMetrics.HitRatio)%</td>
                </tr>
                <tr>
                    <td>Score d'Efficacité</td>
                    <td>$($Stats.PerformanceMetrics.EfficiencyScore)%</td>
                </tr>
                <tr>
                    <td>Efficacité d'Utilisation de la Mémoire</td>
                    <td>$($Stats.PerformanceMetrics.MemoryUsageEfficiency)</td>
                </tr>
            </table>
        </div>
        
        <div class="section">
            <h2>Configuration du Cache</h2>
"@

        if ($null -ne $Stats.Config) {
            $html += @"
            <table>
                <tr>
                    <th>Paramètre</th>
                    <th>Valeur</th>
                </tr>
                <tr>
                    <td>Nom</td>
                    <td>$($Stats.Config.Name)</td>
                </tr>
                <tr>
                    <td>Chemin</td>
                    <td>$($Stats.Config.CachePath)</td>
                </tr>
                <tr>
                    <td>TTL par Défaut</td>
                    <td>$($Stats.Config.DefaultTTLSeconds) secondes</td>
                </tr>
                <tr>
                    <td>Éléments Maximum en Mémoire</td>
                    <td>$($Stats.Config.MaxMemoryItems)</td>
                </tr>
                <tr>
                    <td>Politique d'Éviction</td>
                    <td>$($Stats.Config.EvictionPolicy)</td>
                </tr>
                <tr>
                    <td>Créé le</td>
                    <td>$($Stats.Config.CreatedAt)</td>
                </tr>
                <tr>
                    <td>Dernière Réinitialisation</td>
                    <td>$($Stats.Config.LastResetAt)</td>
                </tr>
            </table>
"@
        } else {
            $html += @"
            <p>Aucune information de configuration disponible.</p>
"@
        }

        $html += @"
        </div>
        
        <div class="section">
            <h2>Recommandations</h2>
"@

        # Générer des recommandations
        $recommendations = @()
        
        if ($Stats.PerformanceMetrics.HitRatio -lt 50) {
            $recommendations += "Le ratio de hits est faible. Envisagez d'ajuster la durée de vie (TTL) des éléments du cache ou d'augmenter la taille du cache."
        }
        
        if ($Stats.PerformanceMetrics.EfficiencyScore -lt 50) {
            $recommendations += "L'efficacité du cache est faible. Vérifiez les modèles d'accès et ajustez la stratégie de mise en cache."
        }
        
        if ($Stats.FileStats.TotalSizeMB -gt 1000) {
            $recommendations += "La taille du cache est importante. Envisagez de nettoyer les éléments inutilisés ou d'ajuster la politique d'éviction."
        }
        
        if ($recommendations.Count -gt 0) {
            $html += @"
            <ul>
"@
            foreach ($recommendation in $recommendations) {
                $html += @"
                <li>$recommendation</li>
"@
            }
            $html += @"
            </ul>
"@
        } else {
            $html += @"
            <p>Le cache fonctionne de manière optimale. Aucune recommandation particulière.</p>
"@
        }

        $html += @"
        </div>
    </div>
</body>
</html>
"@

        return $html
    } catch {
        Write-Error "Erreur lors de la génération du rapport HTML: $_"
        return $null
    }
}

# Point d'entrée principal
try {
    # Collecter les statistiques
    $stats = Get-CacheStats -Path $CachePath
    if ($null -eq $stats) {
        Write-Error "Impossible d'obtenir les statistiques du cache."
        exit 1
    }

    # Déterminer le chemin de sortie si nécessaire
    if ($OutputFormat -ne "Console" -and [string]::IsNullOrWhiteSpace($OutputPath)) {
        $extension = switch ($OutputFormat) {
            "JSON" { "json" }
            "CSV" { "csv" }
            "HTML" { "html" }
            default { "txt" }
        }
        $OutputPath = "reports\pr-analysis\cache_statistics.$extension"
    }

    # Créer le répertoire de sortie si nécessaire
    if ($OutputFormat -ne "Console") {
        $outputDir = Split-Path -Path $OutputPath -Parent
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
    }

    # Générer la sortie selon le format spécifié
    switch ($OutputFormat) {
        "Console" {
            # Afficher les statistiques dans la console
            Write-Host "Statistiques du Cache - Analyse PR" -ForegroundColor Cyan
            Write-Host "Chemin du cache: $($stats.CachePath)" -ForegroundColor White
            Write-Host "Date du rapport: $($stats.Timestamp)" -ForegroundColor White
            
            Write-Host "`nStatistiques de Base:" -ForegroundColor Yellow
            Write-Host "  Nom du Cache: $($stats.BaseStats.Name)" -ForegroundColor White
            Write-Host "  Hits: $($stats.BaseStats.Hits)" -ForegroundColor White
            Write-Host "  Misses: $($stats.BaseStats.Misses)" -ForegroundColor White
            Write-Host "  Éléments en Mémoire: $($stats.BaseStats.ItemCount)" -ForegroundColor White
            Write-Host "  Éléments sur Disque: $($stats.BaseStats.DiskItemCount)" -ForegroundColor White
            Write-Host "  Ratio de Hits: $($stats.BaseStats.HitRatio)%" -ForegroundColor White
            
            Write-Host "`nStatistiques des Fichiers:" -ForegroundColor Yellow
            Write-Host "  Nombre de Fichiers: $($stats.FileStats.FileCount)" -ForegroundColor White
            Write-Host "  Taille Totale: $($stats.FileStats.TotalSizeMB) MB" -ForegroundColor White
            Write-Host "  Taille Moyenne des Fichiers: $($stats.FileStats.AverageFileSizeKB) KB" -ForegroundColor White
            
            Write-Host "`nMétriques de Performance:" -ForegroundColor Yellow
            Write-Host "  Ratio de Hits: $($stats.PerformanceMetrics.HitRatio)%" -ForegroundColor White
            Write-Host "  Score d'Efficacité: $($stats.PerformanceMetrics.EfficiencyScore)%" -ForegroundColor White
            Write-Host "  Efficacité d'Utilisation de la Mémoire: $($stats.PerformanceMetrics.MemoryUsageEfficiency)" -ForegroundColor White
            
            if ($null -ne $stats.Config) {
                Write-Host "`nConfiguration du Cache:" -ForegroundColor Yellow
                Write-Host "  Nom: $($stats.Config.Name)" -ForegroundColor White
                Write-Host "  Chemin: $($stats.Config.CachePath)" -ForegroundColor White
                Write-Host "  TTL par Défaut: $($stats.Config.DefaultTTLSeconds) secondes" -ForegroundColor White
                Write-Host "  Éléments Maximum en Mémoire: $($stats.Config.MaxMemoryItems)" -ForegroundColor White
                Write-Host "  Politique d'Éviction: $($stats.Config.EvictionPolicy)" -ForegroundColor White
                Write-Host "  Créé le: $($stats.Config.CreatedAt)" -ForegroundColor White
                Write-Host "  Dernière Réinitialisation: $($stats.Config.LastResetAt)" -ForegroundColor White
            }
        }
        "JSON" {
            # Générer un fichier JSON
            $stats | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Host "Statistiques du cache exportées au format JSON: $OutputPath" -ForegroundColor Green
        }
        "CSV" {
            # Générer un fichier CSV (version simplifiée)
            $csvData = [PSCustomObject]@{
                Timestamp = $stats.Timestamp
                CachePath = $stats.CachePath
                Name = $stats.BaseStats.Name
                Hits = $stats.BaseStats.Hits
                Misses = $stats.BaseStats.Misses
                ItemCount = $stats.BaseStats.ItemCount
                DiskItemCount = $stats.BaseStats.DiskItemCount
                HitRatio = $stats.BaseStats.HitRatio
                FileCount = $stats.FileStats.FileCount
                TotalSizeMB = $stats.FileStats.TotalSizeMB
                AverageFileSizeKB = $stats.FileStats.AverageFileSizeKB
                EfficiencyScore = $stats.PerformanceMetrics.EfficiencyScore
                MemoryUsageEfficiency = $stats.PerformanceMetrics.MemoryUsageEfficiency
            }
            
            $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            Write-Host "Statistiques du cache exportées au format CSV: $OutputPath" -ForegroundColor Green
        }
        "HTML" {
            # Générer un fichier HTML
            $html = New-HtmlReport -Stats $stats
            Set-Content -Path $OutputPath -Value $html -Encoding UTF8
            Write-Host "Statistiques du cache exportées au format HTML: $OutputPath" -ForegroundColor Green
        }
    }

    # Retourner les statistiques
    return $stats
} catch {
    Write-Error "Erreur lors de l'obtention des statistiques du cache: $_"
    exit 1
}
