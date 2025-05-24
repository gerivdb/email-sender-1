#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse statistique des performances système.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser statistiquement les métriques
    de performance système collectées par le module MetricsCollector.
.NOTES
    Nom: StatisticalAnalyzer.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.3
    Date de création: 2025-05-20
    Date de mise à jour: 2025-05-13
#>

# Importer le module de collecte de métriques
$metricsCollectorPath = Join-Path -Path $PSScriptRoot -ChildPath "MetricsCollector.psm1"
if (Test-Path -Path $metricsCollectorPath) {
    Import-Module $metricsCollectorPath -Force
}

# Variables globales du module
$script:Analyzers = @{}
$script:AnalyzerCounter = 0
$script:DataPath = Join-Path -Path $PSScriptRoot -ChildPath "data"
$script:AnalysisPath = Join-Path -Path $script:DataPath -ChildPath "analysis"
$script:DefaultConfidenceLevel = 0.95
$script:DefaultTimeWindow = 3600 # secondes (1 heure)
$script:DefaultSensitivity = 0.8 # 0-1, 1 étant la sensibilité maximale

# Créer les dossiers nécessaires s'ils n'existent pas
foreach ($path in @($script:DataPath, $script:AnalysisPath)) {
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour créer un nouvel analyseur statistique
function New-StatisticalAnalyzer {
    <#
    .SYNOPSIS
        Crée un nouvel analyseur statistique pour les métriques système.
    .DESCRIPTION
        Cette fonction crée un nouvel analyseur statistique qui peut analyser
        les métriques collectées par le module MetricsCollector.
    .PARAMETER Name
        Nom de l'analyseur. Si non spécifié, un nom unique sera généré.
    .PARAMETER CollectorName
        Nom du collecteur de métriques à analyser.
    .PARAMETER MetricNames
        Noms des métriques à analyser. Si non spécifié, toutes les métriques sont analysées.
    .PARAMETER AnalysisTypes
        Types d'analyses à effectuer (Trend, Outlier, Correlation, Seasonality, etc.).
    .PARAMETER TimeWindow
        Fenêtre de temps pour l'analyse en secondes. Par défaut: 3600 secondes (1 heure).
    .PARAMETER ConfidenceLevel
        Niveau de confiance pour les analyses statistiques (0-1). Par défaut: 0.95.
    .PARAMETER Sensitivity
        Sensibilité pour la détection d'anomalies (0-1). Par défaut: 0.8.
    .PARAMETER OutputPath
        Chemin de sortie pour les résultats d'analyse. Par défaut: sous-dossier dans le dossier analysis.
    .EXAMPLE
        New-StatisticalAnalyzer -Name "SystemAnalyzer" -CollectorName "SystemMetrics" -AnalysisTypes "Trend", "Outlier"
    .OUTPUTS
        [PSCustomObject] avec les informations sur l'analyseur créé
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$CollectorName,

        [Parameter(Mandatory = $false)]
        [string[]]$MetricNames,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Trend", "Outlier", "Correlation", "Seasonality", "Distribution", "Threshold")]
        [string[]]$AnalysisTypes = @("Trend", "Outlier"),

        [Parameter(Mandatory = $false)]
        [int]$TimeWindow = $script:DefaultTimeWindow,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 1)]
        [double]$ConfidenceLevel = $script:DefaultConfidenceLevel,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 1)]
        [double]$Sensitivity = $script:DefaultSensitivity,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Générer un nom unique si non spécifié
    if ([string]::IsNullOrEmpty($Name)) {
        $script:AnalyzerCounter++
        $Name = "Analyzer_$script:AnalyzerCounter"
    }

    # Vérifier si un analyseur avec ce nom existe déjà
    if ($script:Analyzers.ContainsKey($Name)) {
        Write-Warning "Un analyseur avec le nom '$Name' existe déjà."
        return $null
    }

    # Définir le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Join-Path -Path $script:AnalysisPath -ChildPath $Name
    }

    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Créer l'objet analyseur
    $analyzer = [PSCustomObject]@{
        Name             = $Name
        CollectorName    = $CollectorName
        MetricNames      = $MetricNames
        AnalysisTypes    = $AnalysisTypes
        TimeWindow       = $TimeWindow
        ConfidenceLevel  = $ConfidenceLevel
        Sensitivity      = $Sensitivity
        OutputPath       = $OutputPath
        CreatedAt        = Get-Date
        Status           = "Created"
        Job              = $null
        LastAnalysisTime = $null
        Results          = @{}
    }

    # Enregistrer l'analyseur
    $script:Analyzers[$Name] = $analyzer

    return $analyzer
}

# Fonction pour effectuer une analyse statistique
function Invoke-StatisticalAnalysis {
    <#
    .SYNOPSIS
        Effectue une analyse statistique des métriques système.
    .DESCRIPTION
        Cette fonction effectue une analyse statistique des métriques collectées
        par le module MetricsCollector, en utilisant un analyseur précédemment
        créé avec New-StatisticalAnalyzer.
    .PARAMETER Name
        Nom de l'analyseur à utiliser.
    .PARAMETER StartTime
        Heure de début pour l'analyse. Si non spécifié, utilise la fenêtre de temps définie dans l'analyseur.
    .PARAMETER EndTime
        Heure de fin pour l'analyse. Si non spécifié, utilise l'heure actuelle.
    .PARAMETER AsJob
        Si spécifié, effectue l'analyse en tant que job PowerShell.
    .EXAMPLE
        Invoke-StatisticalAnalysis -Name "SystemAnalyzer"
    .OUTPUTS
        [PSCustomObject] avec les résultats de l'analyse
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [datetime]$StartTime,

        [Parameter(Mandatory = $false)]
        [datetime]$EndTime = (Get-Date),

        [Parameter(Mandatory = $false)]
        [switch]$AsJob
    )

    # Vérifier si l'analyseur existe
    if (-not $script:Analyzers.ContainsKey($Name)) {
        Write-Warning "L'analyseur '$Name' n'existe pas."
        return $null
    }

    # Récupérer l'analyseur
    $analyzer = $script:Analyzers[$Name]

    # Définir l'heure de début si non spécifiée
    if ($null -eq $StartTime) {
        $StartTime = $EndTime.AddSeconds(-$analyzer.TimeWindow)
    }

    # Récupérer les métriques à analyser
    $metrics = Get-CollectedMetrics -Name $analyzer.CollectorName -MetricNames $analyzer.MetricNames -StartTime $StartTime -EndTime $EndTime

    if ($null -eq $metrics) {
        Write-Warning "Aucune métrique n'a été collectée par le collecteur '$($analyzer.CollectorName)'."
        return $null
    }

    # Fonction d'analyse
    $analysisScript = {
        param($analyzer, $metrics, $startTime, $endTime)

        # Fonction pour analyser les tendances
        function Test-Trend {
            param($metricData, $metricName, $unit)

            # Convertir les données en séries temporelles
            $timeSeriesData = @()
            foreach ($dataPoint in $metricData) {
                $timestamp = if ($dataPoint.Timestamp -is [string]) { [datetime]::Parse($dataPoint.Timestamp) } else { $dataPoint.Timestamp }
                $timeSeriesData += [PSCustomObject]@{
                    Timestamp = $timestamp
                    Value     = $dataPoint.Value
                }
            }

            # Trier les données par timestamp
            $timeSeriesData = $timeSeriesData | Sort-Object -Property Timestamp

            # Calculer la tendance linéaire (régression linéaire simple)
            $n = $timeSeriesData.Count

            if ($n -lt 2) {
                return @{
                    MetricName   = $metricName
                    AnalysisType = "Trend"
                    Result       = "Insufficient data"
                    Details      = $null
                }
            }

            # Convertir les timestamps en valeurs numériques (secondes depuis le début)
            $startTimestamp = $timeSeriesData[0].Timestamp
            $xValues = @()
            $yValues = @()

            foreach ($dataPoint in $timeSeriesData) {
                $xValues += ($dataPoint.Timestamp - $startTimestamp).TotalSeconds
                $yValues += $dataPoint.Value
            }

            # Calculer les moyennes
            $xMean = ($xValues | Measure-Object -Average).Average
            $yMean = ($yValues | Measure-Object -Average).Average

            # Calculer les coefficients de régression
            $numerator = 0
            $denominator = 0

            for ($i = 0; $i -lt $n; $i++) {
                $numerator += ($xValues[$i] - $xMean) * ($yValues[$i] - $yMean)
                $denominator += [Math]::Pow($xValues[$i] - $xMean, 2)
            }

            $slope = if ($denominator -ne 0) { $numerator / $denominator } else { 0 }
            $intercept = $yMean - $slope * $xMean

            # Calculer les valeurs prédites et les résidus
            $predictedValues = @()
            $residuals = @()

            for ($i = 0; $i -lt $n; $i++) {
                $predicted = $intercept + $slope * $xValues[$i]
                $predictedValues += $predicted
                $residuals += $yValues[$i] - $predicted
            }

            # Calculer l'erreur standard de l'estimation
            $sumSquaredResiduals = ($residuals | ForEach-Object { [Math]::Pow($_, 2) } | Measure-Object -Sum).Sum
            $standardError = [Math]::Sqrt($sumSquaredResiduals / ($n - 2))

            # Calculer le coefficient de détermination (R²)
            $totalSumSquares = ($yValues | ForEach-Object { [Math]::Pow($_ - $yMean, 2) } | Measure-Object -Sum).Sum
            $rSquared = if ($totalSumSquares -ne 0) { 1 - ($sumSquaredResiduals / $totalSumSquares) } else { 0 }

            # Déterminer la direction de la tendance
            $trendDirection = if ($slope -gt 0) { "Increasing" } elseif ($slope -lt 0) { "Decreasing" } else { "Stable" }

            # Calculer le taux de changement (en pourcentage par heure)
            $hourlyChangeRate = $slope * 3600 # Convertir en changement par heure
            $hourlyChangePercent = if ($yMean -ne 0) { ($hourlyChangeRate / $yMean) * 100 } else { 0 }

            # Créer l'objet résultat
            $result = @{
                MetricName   = $metricName
                AnalysisType = "Trend"
                Result       = $trendDirection
                Details      = @{
                    Slope               = $slope
                    Intercept           = $intercept
                    RSquared            = $rSquared
                    StandardError       = $standardError
                    HourlyChangeRate    = $hourlyChangeRate
                    HourlyChangePercent = $hourlyChangePercent
                    Unit                = $unit
                    DataPoints          = $n
                    StartTime           = $startTimestamp
                    EndTime             = $timeSeriesData[-1].Timestamp
                    Duration            = ($timeSeriesData[-1].Timestamp - $startTimestamp).TotalSeconds
                }
            }

            return $result
        }

        # Fonction pour détecter les valeurs aberrantes
        function Find-Outliers {
            param($metricData, $metricName, $unit, $sensitivity)

            # Extraire les valeurs
            $values = $metricData | ForEach-Object { $_.Value }

            if ($values.Count -lt 4) {
                return @{
                    MetricName   = $metricName
                    AnalysisType = "Outlier"
                    Result       = "Insufficient data"
                    Details      = $null
                }
            }

            # Calculer les quartiles
            $sortedValues = $values | Sort-Object
            $q1Index = [Math]::Floor($sortedValues.Count * 0.25)
            $q3Index = [Math]::Floor($sortedValues.Count * 0.75)
            $q1 = $sortedValues[$q1Index]
            $q3 = $sortedValues[$q3Index]

            # Calculer l'écart interquartile (IQR)
            $iqr = $q3 - $q1

            # Définir les limites pour les valeurs aberrantes
            $lowerBound = $q1 - (1.5 + (1 - $sensitivity) * 2) * $iqr
            $upperBound = $q3 + (1.5 + (1 - $sensitivity) * 2) * $iqr

            # Identifier les valeurs aberrantes
            $outliers = @()

            for ($i = 0; $i -lt $metricData.Count; $i++) {
                $value = $metricData[$i].Value
                $timestamp = if ($metricData[$i].Timestamp -is [string]) { [datetime]::Parse($metricData[$i].Timestamp) } else { $metricData[$i].Timestamp }

                if ($value -lt $lowerBound -or $value -gt $upperBound) {
                    $outliers += [PSCustomObject]@{
                        Timestamp = $timestamp
                        Value     = $value
                        Type      = if ($value -lt $lowerBound) { "Low" } else { "High" }
                        Deviation = if ($value -lt $lowerBound) { ($lowerBound - $value) / $iqr } else { ($value - $upperBound) / $iqr }
                    }
                }
            }

            # Créer l'objet résultat
            $result = @{
                MetricName   = $metricName
                AnalysisType = "Outlier"
                Result       = if ($outliers.Count -gt 0) { "Outliers detected" } else { "No outliers" }
                Details      = @{
                    OutlierCount      = $outliers.Count
                    OutlierPercentage = ($outliers.Count / $metricData.Count) * 100
                    Outliers          = $outliers
                    Q1                = $q1
                    Q3                = $q3
                    IQR               = $iqr
                    LowerBound        = $lowerBound
                    UpperBound        = $upperBound
                    Unit              = $unit
                    DataPoints        = $metricData.Count
                    Sensitivity       = $sensitivity
                }
            }

            return $result
        }

        # Fonction pour analyser les corrélations
        function Test-Correlation {
            param($metricsData, $units)

            $metricNames = $metricsData.Keys

            if ($metricNames.Count -lt 2) {
                return @{
                    AnalysisType = "Correlation"
                    Result       = "Insufficient metrics"
                    Details      = $null
                }
            }

            # Préparer les données pour l'analyse de corrélation
            $timeSeriesData = @{}

            foreach ($metricName in $metricNames) {
                $metricData = $metricsData[$metricName]
                $timeSeriesData[$metricName] = @{}

                foreach ($dataPoint in $metricData) {
                    $timestamp = if ($dataPoint.Timestamp -is [string]) { [datetime]::Parse($dataPoint.Timestamp) } else { $dataPoint.Timestamp }
                    $timeSeriesData[$metricName][$timestamp] = $dataPoint.Value
                }
            }

            # Calculer les corrélations entre les métriques
            $correlations = @{}

            foreach ($metric1 in $metricNames) {
                $correlations[$metric1] = @{}

                foreach ($metric2 in $metricNames) {
                    if ($metric1 -eq $metric2) {
                        $correlations[$metric1][$metric2] = 1.0
                        continue
                    }

                    # Trouver les timestamps communs
                    $commonTimestamps = $timeSeriesData[$metric1].Keys | Where-Object { $timeSeriesData[$metric2].ContainsKey($_) }

                    if ($commonTimestamps.Count -lt 4) {
                        $correlations[$metric1][$metric2] = $null
                        continue
                    }

                    # Extraire les valeurs pour les timestamps communs
                    $values1 = @()
                    $values2 = @()

                    foreach ($timestamp in $commonTimestamps) {
                        $values1 += $timeSeriesData[$metric1][$timestamp]
                        $values2 += $timeSeriesData[$metric2][$timestamp]
                    }

                    # Calculer le coefficient de corrélation de Pearson
                    $mean1 = ($values1 | Measure-Object -Average).Average
                    $mean2 = ($values2 | Measure-Object -Average).Average

                    $numerator = 0
                    $denominator1 = 0
                    $denominator2 = 0

                    for ($i = 0; $i -lt $values1.Count; $i++) {
                        $diff1 = $values1[$i] - $mean1
                        $diff2 = $values2[$i] - $mean2

                        $numerator += $diff1 * $diff2
                        $denominator1 += [Math]::Pow($diff1, 2)
                        $denominator2 += [Math]::Pow($diff2, 2)
                    }

                    $correlation = if ($denominator1 -ne 0 -and $denominator2 -ne 0) {
                        $numerator / [Math]::Sqrt($denominator1 * $denominator2)
                    } else {
                        0
                    }

                    $correlations[$metric1][$metric2] = $correlation
                }
            }

            # Identifier les corrélations significatives
            $significantCorrelations = @()

            foreach ($metric1 in $metricNames) {
                foreach ($metric2 in $metricNames) {
                    if ($metric1 -ge $metric2) {
                        continue
                    }

                    $correlation = $correlations[$metric1][$metric2]

                    if ($null -eq $correlation) {
                        continue
                    }

                    $absCorrelation = [Math]::Abs($correlation)

                    if ($absCorrelation -ge 0.7) {
                        $significantCorrelations += [PSCustomObject]@{
                            Metric1     = $metric1
                            Metric2     = $metric2
                            Correlation = $correlation
                            Strength    = if ($absCorrelation -ge 0.9) { "Very Strong" } elseif ($absCorrelation -ge 0.7) { "Strong" } else { "Moderate" }
                            Direction   = if ($correlation -gt 0) { "Positive" } else { "Negative" }
                        }
                    }
                }
            }

            # Créer l'objet résultat
            $result = @{
                AnalysisType = "Correlation"
                Result       = if ($significantCorrelations.Count -gt 0) { "Correlations detected" } else { "No significant correlations" }
                Details      = @{
                    CorrelationMatrix       = $correlations
                    SignificantCorrelations = $significantCorrelations
                    Units                   = $units
                    DataPoints              = ($timeSeriesData.Values | ForEach-Object { $_.Count } | Measure-Object -Average).Average
                }
            }

            return $result
        }

        # Effectuer les analyses demandées
        $results = @{}

        foreach ($metricName in $metrics.Metrics.Keys) {
            $metricData = $metrics.Metrics[$metricName]
            $unit = $metrics.Units[$metricName]

            $results[$metricName] = @{}

            # Analyser les tendances
            if ($analyzer.AnalysisTypes -contains "Trend") {
                $results[$metricName]["Trend"] = Test-Trend -metricData $metricData -metricName $metricName -unit $unit
            }

            # Détecter les valeurs aberrantes
            if ($analyzer.AnalysisTypes -contains "Outlier") {
                $results[$metricName]["Outlier"] = Find-Outliers -metricData $metricData -metricName $metricName -unit $unit -sensitivity $analyzer.Sensitivity
            }
        }

        # Analyser les corrélations
        if ($analyzer.AnalysisTypes -contains "Correlation") {
            $results["Correlation"] = Test-Correlation -metricsData $metrics.Metrics -units $metrics.Units
        }

        # Créer l'objet résultat final
        $analysisResult = [PSCustomObject]@{
            AnalyzerName  = $analyzer.Name
            CollectorName = $analyzer.CollectorName
            StartTime     = $startTime
            EndTime       = $endTime
            AnalysisTime  = Get-Date
            Results       = $results
        }

        return $analysisResult
    }

    # Effectuer l'analyse
    if ($AsJob) {
        $job = Start-Job -ScriptBlock $analysisScript -ArgumentList $analyzer, $metrics, $StartTime, $EndTime
        $analyzer.Job = $job
        $analyzer.Status = "Running"
        return $analyzer
    } else {
        $result = & $analysisScript $analyzer $metrics $StartTime $EndTime
        $analyzer.LastAnalysisTime = Get-Date
        $analyzer.Results = $result.Results
        $analyzer.Status = "Completed"

        # Enregistrer les résultats
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $resultFilePath = Join-Path -Path $analyzer.OutputPath -ChildPath "analysis_$timestamp.json"
        $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFilePath -Encoding utf8 -Force

        return $result
    }
}

# Fonction pour obtenir les résultats d'analyse
function Get-AnalysisResults {
    <#
    .SYNOPSIS
        Récupère les résultats d'analyse statistique.
    .DESCRIPTION
        Cette fonction récupère les résultats d'analyse statistique effectuée
        par un analyseur précédemment créé avec New-StatisticalAnalyzer.
    .PARAMETER Name
        Nom de l'analyseur dont récupérer les résultats.
    .PARAMETER MetricNames
        Noms des métriques dont récupérer les résultats. Si non spécifié, tous les résultats sont retournés.
    .PARAMETER AnalysisTypes
        Types d'analyses dont récupérer les résultats. Si non spécifié, tous les types sont retournés.
    .PARAMETER Latest
        Si spécifié, récupère uniquement les résultats de la dernière analyse.
    .EXAMPLE
        Get-AnalysisResults -Name "SystemAnalyzer" -MetricNames "CPU_Usage" -AnalysisTypes "Trend"
    .OUTPUTS
        [PSCustomObject] avec les résultats d'analyse
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string[]]$MetricNames,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Trend", "Outlier", "Correlation", "Seasonality", "Distribution", "Threshold")]
        [string[]]$AnalysisTypes,

        [Parameter(Mandatory = $false)]
        [switch]$Latest
    )

    # Vérifier si l'analyseur existe
    if (-not $script:Analyzers.ContainsKey($Name)) {
        Write-Warning "L'analyseur '$Name' n'existe pas."
        return $null
    }

    # Récupérer l'analyseur
    $analyzer = $script:Analyzers[$Name]

    # Vérifier si des résultats sont disponibles
    if ($Latest) {
        if ($null -eq $analyzer.LastAnalysisTime) {
            Write-Warning "Aucune analyse n'a été effectuée par l'analyseur '$Name'."
            return $null
        }

        $results = $analyzer.Results
    } else {
        # Récupérer tous les fichiers de résultats
        $resultFiles = Get-ChildItem -Path $analyzer.OutputPath -Filter "analysis_*.json" | Sort-Object -Property LastWriteTime -Descending

        if ($resultFiles.Count -eq 0) {
            Write-Warning "Aucun fichier de résultats n'a été trouvé pour l'analyseur '$Name'."
            return $null
        }

        # Charger les résultats
        $allResults = @()

        foreach ($file in $resultFiles) {
            $result = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $allResults += $result
        }

        return $allResults
    }

    # Filtrer les résultats par métrique
    if ($null -ne $MetricNames -and $MetricNames.Count -gt 0) {
        $filteredResults = @{}

        foreach ($metricName in $MetricNames) {
            if ($results.ContainsKey($metricName)) {
                $filteredResults[$metricName] = $results[$metricName]
            }
        }

        $results = $filteredResults
    }

    # Filtrer les résultats par type d'analyse
    if ($null -ne $AnalysisTypes -and $AnalysisTypes.Count -gt 0) {
        $filteredResults = @{}

        foreach ($metricName in $results.Keys) {
            $filteredResults[$metricName] = @{}

            foreach ($analysisType in $AnalysisTypes) {
                if ($results[$metricName].ContainsKey($analysisType)) {
                    $filteredResults[$metricName][$analysisType] = $results[$metricName][$analysisType]
                }
            }

            if ($filteredResults[$metricName].Count -eq 0) {
                $filteredResults.Remove($metricName)
            }
        }

        $results = $filteredResults
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        AnalyzerName  = $analyzer.Name
        CollectorName = $analyzer.CollectorName
        AnalysisTime  = $analyzer.LastAnalysisTime
        Results       = $results
    }

    return $result
}

# Exporter les fonctions du module
Export-ModuleMember -Function New-StatisticalAnalyzer, Invoke-StatisticalAnalysis,
Get-AnalysisResults

