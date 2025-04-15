#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte automatiquement les régressions de performance.
.DESCRIPTION
    Compare les résultats de performance actuels avec une référence et détecte les régressions.
.PARAMETER CurrentResultsPath
    Chemin vers le fichier JSON des résultats actuels.
.PARAMETER BaselineResultsPath
    Chemin vers le fichier JSON des résultats de référence.
.PARAMETER ThresholdPercent
    Pourcentage d'augmentation considéré comme une régression. Par défaut: 10%.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats de l'analyse. Si non spécifié, les résultats sont uniquement affichés.
.PARAMETER AlertLevel
    Niveau d'alerte (Info, Warning, Error). Par défaut: Warning.
.EXAMPLE
    .\Test-PerfRegression.ps1 -CurrentResultsPath "current.json" -BaselineResultsPath "baseline.json" -ThresholdPercent 5
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$CurrentResultsPath,
    
    [Parameter(Mandatory = $true)]
    [string]$BaselineResultsPath,
    
    [Parameter(Mandatory = $false)]
    [double]$ThresholdPercent = 10.0,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Info", "Warning", "Error")]
    [string]$AlertLevel = "Warning"
)

# Fonction pour analyser les métriques et détecter les régressions
function Test-MetricRegression {
    param (
        [string]$MetricName,
        [double]$CurrentValue,
        [double]$BaselineValue,
        [double]$Threshold
    )
    
    $diff = 0
    $percentChange = 0
    $isRegression = $false
    
    if ($BaselineValue -ne 0) {
        $diff = $CurrentValue - $BaselineValue
        $percentChange = $diff / $BaselineValue * 100
        
        # Pour les métriques où une augmentation est une régression (temps de réponse)
        if ($MetricName -match "ResponseMs|Latency|Duration") {
            $isRegression = $percentChange -gt $Threshold
        }
        # Pour les métriques où une diminution est une régression (RPS, throughput)
        elseif ($MetricName -match "RPS|RequestsPerSecond|Throughput") {
            $isRegression = $percentChange -lt -$Threshold
        }
    }
    
    return [PSCustomObject]@{
        MetricName = $MetricName
        CurrentValue = $CurrentValue
        BaselineValue = $BaselineValue
        Difference = $diff
        PercentChange = $percentChange
        Threshold = $Threshold
        IsRegression = $isRegression
    }
}

# Fonction pour analyser les résultats et détecter les anomalies statistiques
function Test-StatisticalAnomaly {
    param (
        [object]$CurrentResults,
        [object]$BaselineResults
    )
    
    $anomalies = @()
    
    # Vérifier si les résultats contiennent des données de performance
    if ($CurrentResults.Performance -and $BaselineResults.Performance) {
        # Calculer les statistiques de base pour les deux ensembles
        $currentCPU = $CurrentResults.Performance | ForEach-Object { $_.CPU }
        $baselineCPU = $BaselineResults.Performance | ForEach-Object { $_.CPU }
        
        $currentMemory = $CurrentResults.Performance | ForEach-Object { $_.WorkingSet / 1MB }
        $baselineMemory = $BaselineResults.Performance | ForEach-Object { $_.WorkingSet / 1MB }
        
        # Calculer les moyennes
        $currentCPUAvg = ($currentCPU | Measure-Object -Average).Average
        $baselineCPUAvg = ($baselineCPU | Measure-Object -Average).Average
        
        $currentMemoryAvg = ($currentMemory | Measure-Object -Average).Average
        $baselineMemoryAvg = ($baselineMemory | Measure-Object -Average).Average
        
        # Détecter les anomalies de CPU
        if ($baselineCPUAvg -ne 0 -and (($currentCPUAvg - $baselineCPUAvg) / $baselineCPUAvg * 100) -gt 20) {
            $anomalies += "Utilisation CPU anormalement élevée: $([Math]::Round($currentCPUAvg, 2))% vs $([Math]::Round($baselineCPUAvg, 2))% (référence)"
        }
        
        # Détecter les anomalies de mémoire
        if ($baselineMemoryAvg -ne 0 -and (($currentMemoryAvg - $baselineMemoryAvg) / $baselineMemoryAvg * 100) -gt 20) {
            $anomalies += "Utilisation mémoire anormalement élevée: $([Math]::Round($currentMemoryAvg, 2)) MB vs $([Math]::Round($baselineMemoryAvg, 2)) MB (référence)"
        }
    }
    
    return $anomalies
}

# Fonction principale
function Main {
    # Vérifier que les fichiers existent
    if (-not (Test-Path -Path $CurrentResultsPath)) {
        Write-Error "Le fichier de résultats actuels n'existe pas: $CurrentResultsPath"
        return
    }
    
    if (-not (Test-Path -Path $BaselineResultsPath)) {
        Write-Error "Le fichier de résultats de référence n'existe pas: $BaselineResultsPath"
        return
    }
    
    # Charger les résultats
    try {
        $currentResults = Get-Content -Path $CurrentResultsPath -Raw | ConvertFrom-Json
        $baselineResults = Get-Content -Path $BaselineResultsPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Erreur lors du chargement des résultats: $_"
        return
    }
    
    # Définir les métriques à analyser
    $metrics = @(
        @{ Name = "AvgResponseMs"; DisplayName = "Temps de réponse moyen" },
        @{ Name = "P95ResponseMs"; DisplayName = "P95" },
        @{ Name = "MaxResponseMs"; DisplayName = "Temps de réponse maximum" },
        @{ Name = "RequestsPerSecond"; DisplayName = "Requêtes par seconde" }
    )
    
    # Analyser chaque métrique
    $regressions = @()
    $improvements = @()
    
    foreach ($metric in $metrics) {
        # Vérifier si la métrique existe dans les deux résultats
        if ($currentResults.PSObject.Properties.Name -contains $metric.Name -and 
            $baselineResults.PSObject.Properties.Name -contains $metric.Name) {
            
            $result = Test-MetricRegression -MetricName $metric.Name `
                                           -CurrentValue $currentResults.($metric.Name) `
                                           -BaselineValue $baselineResults.($metric.Name) `
                                           -Threshold $ThresholdPercent
            
            if ($result.IsRegression) {
                $regressions += $result
            }
            elseif ([Math]::Abs($result.PercentChange) -gt 5) {
                # Considérer comme une amélioration si le changement est significatif
                $improvements += $result
            }
        }
    }
    
    # Détecter les anomalies statistiques
    $anomalies = Test-StatisticalAnomaly -CurrentResults $currentResults -BaselineResults $baselineResults
    
    # Préparer les résultats
    $analysisResults = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        CurrentResults = $CurrentResultsPath
        BaselineResults = $BaselineResultsPath
        ThresholdPercent = $ThresholdPercent
        Regressions = $regressions
        Improvements = $improvements
        Anomalies = $anomalies
        HasRegressions = $regressions.Count -gt 0
        HasAnomalies = $anomalies.Count -gt 0
        Summary = @{
            RegressionCount = $regressions.Count
            ImprovementCount = $improvements.Count
            AnomalyCount = $anomalies.Count
        }
    }
    
    # Afficher les résultats
    Write-Host "`nAnalyse de régression de performance" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "Résultats actuels: $CurrentResultsPath"
    Write-Host "Référence: $BaselineResultsPath"
    Write-Host "Seuil de régression: $ThresholdPercent%"
    
    if ($regressions.Count -gt 0) {
        Write-Host "`nRégressions détectées:" -ForegroundColor Red
        
        foreach ($regression in $regressions) {
            $message = "$($regression.MetricName): $([Math]::Round($regression.CurrentValue, 2)) vs $([Math]::Round($regression.BaselineValue, 2)) (référence), changement: $([Math]::Round($regression.PercentChange, 2))%"
            
            switch ($AlertLevel) {
                "Info" { Write-Host "  - $message" -ForegroundColor Yellow }
                "Warning" { Write-Warning "  - $message" }
                "Error" { Write-Error "  - $message" }
            }
        }
    }
    else {
        Write-Host "`nAucune régression détectée." -ForegroundColor Green
    }
    
    if ($improvements.Count -gt 0) {
        Write-Host "`nAméliorations détectées:" -ForegroundColor Green
        
        foreach ($improvement in $improvements) {
            Write-Host "  - $($improvement.MetricName): $([Math]::Round($improvement.CurrentValue, 2)) vs $([Math]::Round($improvement.BaselineValue, 2)) (référence), changement: $([Math]::Round($improvement.PercentChange, 2))%" -ForegroundColor Green
        }
    }
    
    if ($anomalies.Count -gt 0) {
        Write-Host "`nAnomalies détectées:" -ForegroundColor Yellow
        
        foreach ($anomaly in $anomalies) {
            Write-Host "  - $anomaly" -ForegroundColor Yellow
        }
    }
    
    # Enregistrer les résultats si un chemin de sortie est spécifié
    if ($OutputPath) {
        $analysisResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Host "`nRésultats de l'analyse enregistrés: $OutputPath" -ForegroundColor Cyan
    }
    
    # Retourner les résultats
    return $analysisResults
}

# Exécuter le script
Main
