#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©tecte automatiquement les rÃ©gressions de performance.
.DESCRIPTION
    Compare les rÃ©sultats de performance actuels avec une rÃ©fÃ©rence et dÃ©tecte les rÃ©gressions.
.PARAMETER CurrentResultsPath
    Chemin vers le fichier JSON des rÃ©sultats actuels.
.PARAMETER BaselineResultsPath
    Chemin vers le fichier JSON des rÃ©sultats de rÃ©fÃ©rence.
.PARAMETER ThresholdPercent
    Pourcentage d'augmentation considÃ©rÃ© comme une rÃ©gression. Par dÃ©faut: 10%.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats de l'analyse. Si non spÃ©cifiÃ©, les rÃ©sultats sont uniquement affichÃ©s.
.PARAMETER AlertLevel
    Niveau d'alerte (Info, Warning, Error). Par dÃ©faut: Warning.
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

# Fonction pour analyser les mÃ©triques et dÃ©tecter les rÃ©gressions
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
        
        # Pour les mÃ©triques oÃ¹ une augmentation est une rÃ©gression (temps de rÃ©ponse)
        if ($MetricName -match "ResponseMs|Latency|Duration") {
            $isRegression = $percentChange -gt $Threshold
        }
        # Pour les mÃ©triques oÃ¹ une diminution est une rÃ©gression (RPS, throughput)
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

# Fonction pour analyser les rÃ©sultats et dÃ©tecter les anomalies statistiques
function Test-StatisticalAnomaly {
    param (
        [object]$CurrentResults,
        [object]$BaselineResults
    )
    
    $anomalies = @()
    
    # VÃ©rifier si les rÃ©sultats contiennent des donnÃ©es de performance
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
        
        # DÃ©tecter les anomalies de CPU
        if ($baselineCPUAvg -ne 0 -and (($currentCPUAvg - $baselineCPUAvg) / $baselineCPUAvg * 100) -gt 20) {
            $anomalies += "Utilisation CPU anormalement Ã©levÃ©e: $([Math]::Round($currentCPUAvg, 2))% vs $([Math]::Round($baselineCPUAvg, 2))% (rÃ©fÃ©rence)"
        }
        
        # DÃ©tecter les anomalies de mÃ©moire
        if ($baselineMemoryAvg -ne 0 -and (($currentMemoryAvg - $baselineMemoryAvg) / $baselineMemoryAvg * 100) -gt 20) {
            $anomalies += "Utilisation mÃ©moire anormalement Ã©levÃ©e: $([Math]::Round($currentMemoryAvg, 2)) MB vs $([Math]::Round($baselineMemoryAvg, 2)) MB (rÃ©fÃ©rence)"
        }
    }
    
    return $anomalies
}

# Fonction principale
function Main {
    # VÃ©rifier que les fichiers existent
    if (-not (Test-Path -Path $CurrentResultsPath)) {
        Write-Error "Le fichier de rÃ©sultats actuels n'existe pas: $CurrentResultsPath"
        return
    }
    
    if (-not (Test-Path -Path $BaselineResultsPath)) {
        Write-Error "Le fichier de rÃ©sultats de rÃ©fÃ©rence n'existe pas: $BaselineResultsPath"
        return
    }
    
    # Charger les rÃ©sultats
    try {
        $currentResults = Get-Content -Path $CurrentResultsPath -Raw | ConvertFrom-Json
        $baselineResults = Get-Content -Path $BaselineResultsPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Erreur lors du chargement des rÃ©sultats: $_"
        return
    }
    
    # DÃ©finir les mÃ©triques Ã  analyser
    $metrics = @(
        @{ Name = "AvgResponseMs"; DisplayName = "Temps de rÃ©ponse moyen" },
        @{ Name = "P95ResponseMs"; DisplayName = "P95" },
        @{ Name = "MaxResponseMs"; DisplayName = "Temps de rÃ©ponse maximum" },
        @{ Name = "RequestsPerSecond"; DisplayName = "RequÃªtes par seconde" }
    )
    
    # Analyser chaque mÃ©trique
    $regressions = @()
    $improvements = @()
    
    foreach ($metric in $metrics) {
        # VÃ©rifier si la mÃ©trique existe dans les deux rÃ©sultats
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
                # ConsidÃ©rer comme une amÃ©lioration si le changement est significatif
                $improvements += $result
            }
        }
    }
    
    # DÃ©tecter les anomalies statistiques
    $anomalies = Test-StatisticalAnomaly -CurrentResults $currentResults -BaselineResults $baselineResults
    
    # PrÃ©parer les rÃ©sultats
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
    
    # Afficher les rÃ©sultats
    Write-Host "`nAnalyse de rÃ©gression de performance" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "RÃ©sultats actuels: $CurrentResultsPath"
    Write-Host "RÃ©fÃ©rence: $BaselineResultsPath"
    Write-Host "Seuil de rÃ©gression: $ThresholdPercent%"
    
    if ($regressions.Count -gt 0) {
        Write-Host "`nRÃ©gressions dÃ©tectÃ©es:" -ForegroundColor Red
        
        foreach ($regression in $regressions) {
            $message = "$($regression.MetricName): $([Math]::Round($regression.CurrentValue, 2)) vs $([Math]::Round($regression.BaselineValue, 2)) (rÃ©fÃ©rence), changement: $([Math]::Round($regression.PercentChange, 2))%"
            
            switch ($AlertLevel) {
                "Info" { Write-Host "  - $message" -ForegroundColor Yellow }
                "Warning" { Write-Warning "  - $message" }
                "Error" { Write-Error "  - $message" }
            }
        }
    }
    else {
        Write-Host "`nAucune rÃ©gression dÃ©tectÃ©e." -ForegroundColor Green
    }
    
    if ($improvements.Count -gt 0) {
        Write-Host "`nAmÃ©liorations dÃ©tectÃ©es:" -ForegroundColor Green
        
        foreach ($improvement in $improvements) {
            Write-Host "  - $($improvement.MetricName): $([Math]::Round($improvement.CurrentValue, 2)) vs $([Math]::Round($improvement.BaselineValue, 2)) (rÃ©fÃ©rence), changement: $([Math]::Round($improvement.PercentChange, 2))%" -ForegroundColor Green
        }
    }
    
    if ($anomalies.Count -gt 0) {
        Write-Host "`nAnomalies dÃ©tectÃ©es:" -ForegroundColor Yellow
        
        foreach ($anomaly in $anomalies) {
            Write-Host "  - $anomaly" -ForegroundColor Yellow
        }
    }
    
    # Enregistrer les rÃ©sultats si un chemin de sortie est spÃ©cifiÃ©
    if ($OutputPath) {
        $analysisResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Host "`nRÃ©sultats de l'analyse enregistrÃ©s: $OutputPath" -ForegroundColor Cyan
    }
    
    # Retourner les rÃ©sultats
    return $analysisResults
}

# ExÃ©cuter le script
Main
