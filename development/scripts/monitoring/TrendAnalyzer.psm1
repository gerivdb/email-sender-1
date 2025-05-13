#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse de tendances historiques pour les métriques système.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser les tendances historiques
    des métriques système collectées par le module MetricsCollector.
.NOTES
    Nom: TrendAnalyzer.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.3
    Date de création: 2025-05-13
#>

# Variables globales
$script:Analyzers = @{}

<#
.SYNOPSIS
    Extrait les données historiques des métriques système.
.DESCRIPTION
    Cette fonction extrait les données historiques des métriques système
    à partir des fichiers de métriques collectées par le module MetricsCollector.
.PARAMETER CollectorName
    Nom du collecteur de métriques.
.PARAMETER StartTime
    Heure de début de l'extraction (par défaut: 24 heures avant l'heure actuelle).
.PARAMETER EndTime
    Heure de fin de l'extraction (par défaut: heure actuelle).
.PARAMETER MetricNames
    Noms des métriques à extraire (par défaut: toutes les métriques).
.PARAMETER SamplingInterval
    Intervalle d'échantillonnage en secondes (par défaut: 60 secondes).
.EXAMPLE
    Get-HistoricalMetricsData -CollectorName "SystemMonitor" -StartTime (Get-Date).AddDays(-7)
.OUTPUTS
    System.Collections.Hashtable
#>
function Get-HistoricalMetricsData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CollectorName,

        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime = (Get-Date).AddHours(-24),

        [Parameter(Mandatory = $false)]
        [DateTime]$EndTime = (Get-Date),

        [Parameter(Mandatory = $false)]
        [string[]]$MetricNames,

        [Parameter(Mandatory = $false)]
        [int]$SamplingInterval = 60
    )

    begin {
        Write-Verbose "Extraction des données historiques pour le collecteur $CollectorName"
        $metricsPath = Join-Path -Path "$PSScriptRoot\data\metrics" -ChildPath $CollectorName

        if (-not (Test-Path -Path $metricsPath)) {
            Write-Error "Le dossier de métriques pour le collecteur $CollectorName n'existe pas."
            return $null
        }

        # Initialiser le résultat
        $result = @{
            CollectorName    = $CollectorName
            StartTime        = $StartTime
            EndTime          = $EndTime
            SamplingInterval = $SamplingInterval
            MetricsData      = @{}
        }
    }

    process {
        try {
            # Obtenir tous les fichiers de métriques dans la plage de temps spécifiée
            $metricFiles = Get-ChildItem -Path $metricsPath -Filter "metrics_*.json" |
                Where-Object {
                    $fileDate = [DateTime]::ParseExact(
                        $_.BaseName.Substring(8),
                        "yyyyMMdd_HHmmss",
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                    $fileDate -ge $StartTime -and $fileDate -le $EndTime
                } |
                Sort-Object LastWriteTime

            Write-Verbose "Nombre de fichiers de métriques trouvés: $($metricFiles.Count)"

            if ($metricFiles.Count -eq 0) {
                Write-Warning "Aucun fichier de métriques trouvé pour la période spécifiée."
                return $result
            }

            # Traiter chaque fichier de métriques
            foreach ($file in $metricFiles) {
                Write-Verbose "Traitement du fichier: $($file.FullName)"

                $metricsData = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json

                # Extraire les métriques demandées
                foreach ($metric in $metricsData.Metrics) {
                    $metricName = $metric.Name

                    # Filtrer par nom de métrique si spécifié
                    if ($MetricNames -and $metricName -notin $MetricNames) {
                        continue
                    }

                    # Initialiser le tableau pour cette métrique si nécessaire
                    if (-not $result.MetricsData.ContainsKey($metricName)) {
                        $result.MetricsData[$metricName] = @{
                            Values     = @()
                            Timestamps = @()
                            Unit       = $metric.Unit
                        }
                    }

                    # Ajouter les valeurs et timestamps
                    $result.MetricsData[$metricName].Values += $metric.Value
                    $result.MetricsData[$metricName].Timestamps += $metricsData.Timestamp
                }
            }

            # Appliquer l'échantillonnage si nécessaire
            if ($SamplingInterval -gt 0) {
                $result = ConvertTo-SampledMetrics -MetricsData $result -SamplingInterval $SamplingInterval
            }
        } catch {
            Write-Error "Erreur lors de l'extraction des données historiques: $_"
            return $null
        }
    }

    end {
        return $result
    }
}

<#
.SYNOPSIS
    Applique un intervalle d'échantillonnage aux données de métriques.
.DESCRIPTION
    Cette fonction interne applique un intervalle d'échantillonnage aux données de métriques
    pour réduire la quantité de données à analyser.
.PARAMETER MetricsData
    Données de métriques à échantillonner.
.PARAMETER SamplingInterval
    Intervalle d'échantillonnage en secondes.
.OUTPUTS
    System.Collections.Hashtable
#>
function ConvertTo-SampledMetrics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$MetricsData,

        [Parameter(Mandatory = $true)]
        [int]$SamplingInterval
    )

    $result = @{
        CollectorName    = $MetricsData.CollectorName
        StartTime        = $MetricsData.StartTime
        EndTime          = $MetricsData.EndTime
        SamplingInterval = $SamplingInterval
        MetricsData      = @{}
    }

    foreach ($metricName in $MetricsData.MetricsData.Keys) {
        $metricData = $MetricsData.MetricsData[$metricName]
        $sampledValues = @()
        $sampledTimestamps = @()

        # Regrouper par intervalle d'échantillonnage
        $currentInterval = $null
        $currentValues = @()

        for ($i = 0; $i -lt $metricData.Timestamps.Count; $i++) {
            $timestamp = [DateTime]$metricData.Timestamps[$i]
            $intervalStart = $timestamp.Date.AddSeconds([Math]::Floor($timestamp.TimeOfDay.TotalSeconds / $SamplingInterval) * $SamplingInterval)

            if ($null -eq $currentInterval) {
                $currentInterval = $intervalStart
            }

            if ($intervalStart -eq $currentInterval) {
                $currentValues += $metricData.Values[$i]
            } else {
                # Calculer la moyenne pour l'intervalle actuel
                $avgValue = ($currentValues | Measure-Object -Average).Average
                $sampledValues += $avgValue
                $sampledTimestamps += $currentInterval

                # Réinitialiser pour le nouvel intervalle
                $currentInterval = $intervalStart
                $currentValues = @($metricData.Values[$i])
            }
        }

        # Ajouter le dernier intervalle
        if ($currentValues.Count -gt 0) {
            $avgValue = ($currentValues | Measure-Object -Average).Average
            $sampledValues += $avgValue
            $sampledTimestamps += $currentInterval
        }

        $result.MetricsData[$metricName] = @{
            Values     = $sampledValues
            Timestamps = $sampledTimestamps
            Unit       = $metricData.Unit
        }
    }

    return $result
}

<#
.SYNOPSIS
    Détecte les patterns cycliques dans les données de métriques.
.DESCRIPTION
    Cette fonction analyse les données historiques pour détecter les patterns
    cycliques (journaliers, hebdomadaires, etc.) dans les métriques système.
.PARAMETER MetricsData
    Données de métriques historiques obtenues via Get-HistoricalMetricsData.
.PARAMETER MetricName
    Nom de la métrique à analyser.
.PARAMETER CycleTypes
    Types de cycles à détecter (Daily, Weekly, Monthly).
.PARAMETER MinimumDataPoints
    Nombre minimum de points de données requis pour l'analyse.
.EXAMPLE
    $historicalData = Get-HistoricalMetricsData -CollectorName "SystemMonitor"
    Find-CyclicPatterns -MetricsData $historicalData -MetricName "CPU_Usage"
.OUTPUTS
    System.Collections.Hashtable
#>
function Find-CyclicPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$MetricsData,

        [Parameter(Mandatory = $true)]
        [string]$MetricName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Daily", "Weekly", "Monthly")]
        [string[]]$CycleTypes = @("Daily", "Weekly"),

        [Parameter(Mandatory = $false)]
        [int]$MinimumDataPoints = 24
    )

    begin {
        Write-Verbose "Détection des patterns cycliques pour la métrique $MetricName"

        if (-not $MetricsData.MetricsData.ContainsKey($MetricName)) {
            Write-Error "La métrique $MetricName n'existe pas dans les données fournies."
            return $null
        }

        $metricData = $MetricsData.MetricsData[$MetricName]

        if ($metricData.Values.Count -lt $MinimumDataPoints) {
            Write-Warning "Nombre insuffisant de points de données pour détecter des patterns cycliques. Minimum requis: $MinimumDataPoints, Disponible: $($metricData.Values.Count)"
            return @{
                MetricName        = $MetricName
                HasCyclicPatterns = $false
                Reason            = "InsufficientData"
                CyclicPatterns    = @{}
            }
        }

        # Initialiser le résultat
        $result = @{
            MetricName        = $MetricName
            HasCyclicPatterns = $false
            CyclicPatterns    = @{}
        }
    }

    process {
        try {
            # Convertir les timestamps en objets DateTime
            $timestamps = $metricData.Timestamps | ForEach-Object { [DateTime]$_ }
            $values = $metricData.Values

            # Analyser chaque type de cycle
            foreach ($cycleType in $CycleTypes) {
                Write-Verbose "Analyse du cycle de type $cycleType"

                switch ($cycleType) {
                    "Daily" {
                        $result.CyclicPatterns[$cycleType] = Find-DailyCyclicPattern -Timestamps $timestamps -Values $values
                    }
                    "Weekly" {
                        $result.CyclicPatterns[$cycleType] = Find-WeeklyCyclicPattern -Timestamps $timestamps -Values $values
                    }
                    "Monthly" {
                        $result.CyclicPatterns[$cycleType] = Find-MonthlyCyclicPattern -Timestamps $timestamps -Values $values
                    }
                }

                # Vérifier si un pattern cyclique a été détecté
                if ($result.CyclicPatterns[$cycleType].IsCyclic) {
                    $result.HasCyclicPatterns = $true
                }
            }
        } catch {
            Write-Error "Erreur lors de la détection des patterns cycliques: $_"
            return $null
        }
    }

    end {
        return $result
    }
}

<#
.SYNOPSIS
    Détecte les patterns cycliques journaliers.
.DESCRIPTION
    Fonction interne qui détecte les patterns cycliques journaliers dans les données.
.PARAMETER Timestamps
    Tableau des timestamps.
.PARAMETER Values
    Tableau des valeurs correspondantes.
.OUTPUTS
    System.Collections.Hashtable
#>
function Find-DailyCyclicPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DateTime[]]$Timestamps,

        [Parameter(Mandatory = $true)]
        [double[]]$Values
    )

    # Regrouper les valeurs par heure de la journée
    $hourlyData = @{}

    for ($i = 0; $i -lt $Timestamps.Count; $i++) {
        $hour = $Timestamps[$i].Hour

        if (-not $hourlyData.ContainsKey($hour)) {
            $hourlyData[$hour] = @{
                Values = @()
                Count  = 0
                Sum    = 0
            }
        }

        $hourlyData[$hour].Values += $Values[$i]
        $hourlyData[$hour].Count++
        $hourlyData[$hour].Sum += $Values[$i]
    }

    # Calculer les moyennes par heure
    $hourlyAverages = @{}
    $globalAverage = ($Values | Measure-Object -Average).Average
    $hourlyVariance = 0

    foreach ($hour in 0..23) {
        if ($hourlyData.ContainsKey($hour) -and $hourlyData[$hour].Count -gt 0) {
            $hourlyAverages[$hour] = $hourlyData[$hour].Sum / $hourlyData[$hour].Count
            $hourlyVariance += [Math]::Pow($hourlyAverages[$hour] - $globalAverage, 2)
        } else {
            $hourlyAverages[$hour] = $globalAverage
        }
    }

    # Calculer l'écart-type des moyennes horaires
    $hourlyStdDev = [Math]::Sqrt($hourlyVariance / 24)

    # Calculer le coefficient de variation
    $coefficientOfVariation = $hourlyStdDev / $globalAverage

    # Déterminer s'il existe un pattern cyclique journalier
    $isCyclic = $coefficientOfVariation -gt 0.1

    # Trouver les heures de pic et de creux
    $peakHour = ($hourlyAverages.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    $troughHour = ($hourlyAverages.GetEnumerator() | Sort-Object Value | Select-Object -First 1).Key

    return @{
        IsCyclic               = $isCyclic
        CoefficientOfVariation = $coefficientOfVariation
        HourlyAverages         = $hourlyAverages
        PeakHour               = $peakHour
        PeakValue              = $hourlyAverages[$peakHour]
        TroughHour             = $troughHour
        TroughValue            = $hourlyAverages[$troughHour]
        Confidence             = [Math]::Min(1, $coefficientOfVariation * 5)
    }
}

<#
.SYNOPSIS
    Détecte les patterns cycliques hebdomadaires.
.DESCRIPTION
    Fonction interne qui détecte les patterns cycliques hebdomadaires dans les données.
.PARAMETER Timestamps
    Tableau des timestamps.
.PARAMETER Values
    Tableau des valeurs correspondantes.
.OUTPUTS
    System.Collections.Hashtable
#>
function Find-WeeklyCyclicPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DateTime[]]$Timestamps,

        [Parameter(Mandatory = $true)]
        [double[]]$Values
    )

    # Regrouper les valeurs par jour de la semaine
    $dailyData = @{}

    for ($i = 0; $i -lt $Timestamps.Count; $i++) {
        $dayOfWeek = [int]$Timestamps[$i].DayOfWeek

        if (-not $dailyData.ContainsKey($dayOfWeek)) {
            $dailyData[$dayOfWeek] = @{
                Values = @()
                Count  = 0
                Sum    = 0
            }
        }

        $dailyData[$dayOfWeek].Values += $Values[$i]
        $dailyData[$dayOfWeek].Count++
        $dailyData[$dayOfWeek].Sum += $Values[$i]
    }

    # Calculer les moyennes par jour
    $dailyAverages = @{}
    $globalAverage = ($Values | Measure-Object -Average).Average
    $dailyVariance = 0

    foreach ($day in 0..6) {
        if ($dailyData.ContainsKey($day) -and $dailyData[$day].Count -gt 0) {
            $dailyAverages[$day] = $dailyData[$day].Sum / $dailyData[$day].Count
            $dailyVariance += [Math]::Pow($dailyAverages[$day] - $globalAverage, 2)
        } else {
            $dailyAverages[$day] = $globalAverage
        }
    }

    # Calculer l'écart-type des moyennes journalières
    $dailyStdDev = [Math]::Sqrt($dailyVariance / 7)

    # Calculer le coefficient de variation
    $coefficientOfVariation = $dailyStdDev / $globalAverage

    # Déterminer s'il existe un pattern cyclique hebdomadaire
    $isCyclic = $coefficientOfVariation -gt 0.15

    # Trouver les jours de pic et de creux
    $peakDay = ($dailyAverages.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    $troughDay = ($dailyAverages.GetEnumerator() | Sort-Object Value | Select-Object -First 1).Key

    # Convertir les jours numériques en noms
    $dayNames = @("Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi")

    return @{
        IsCyclic               = $isCyclic
        CoefficientOfVariation = $coefficientOfVariation
        DailyAverages          = $dailyAverages
        PeakDay                = $dayNames[$peakDay]
        PeakValue              = $dailyAverages[$peakDay]
        TroughDay              = $dayNames[$troughDay]
        TroughValue            = $dailyAverages[$troughDay]
        Confidence             = [Math]::Min(1, $coefficientOfVariation * 3)
    }
}

<#
.SYNOPSIS
    Détecte les patterns cycliques mensuels.
.DESCRIPTION
    Fonction interne qui détecte les patterns cycliques mensuels dans les données.
.PARAMETER Timestamps
    Tableau des timestamps.
.PARAMETER Values
    Tableau des valeurs correspondantes.
.OUTPUTS
    System.Collections.Hashtable
#>
function Find-MonthlyCyclicPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DateTime[]]$Timestamps,

        [Parameter(Mandatory = $true)]
        [double[]]$Values
    )

    # Vérifier s'il y a suffisamment de données pour une analyse mensuelle
    if ($Timestamps.Count -lt 60) {
        return @{
            IsCyclic   = $false
            Reason     = "InsufficientData"
            Confidence = 0
        }
    }

    # Regrouper les valeurs par jour du mois
    $monthlyData = @{}

    for ($i = 0; $i -lt $Timestamps.Count; $i++) {
        $dayOfMonth = $Timestamps[$i].Day

        if (-not $monthlyData.ContainsKey($dayOfMonth)) {
            $monthlyData[$dayOfMonth] = @{
                Values = @()
                Count  = 0
                Sum    = 0
            }
        }

        $monthlyData[$dayOfMonth].Values += $Values[$i]
        $monthlyData[$dayOfMonth].Count++
        $monthlyData[$dayOfMonth].Sum += $Values[$i]
    }

    # Calculer les moyennes par jour du mois
    $monthlyAverages = @{}
    $globalAverage = ($Values | Measure-Object -Average).Average
    $monthlyVariance = 0
    $daysWithData = 0

    foreach ($day in 1..31) {
        if ($monthlyData.ContainsKey($day) -and $monthlyData[$day].Count -gt 0) {
            $monthlyAverages[$day] = $monthlyData[$day].Sum / $monthlyData[$day].Count
            $monthlyVariance += [Math]::Pow($monthlyAverages[$day] - $globalAverage, 2)
            $daysWithData++
        }
    }

    # S'il n'y a pas assez de jours avec des données
    if ($daysWithData -lt 15) {
        return @{
            IsCyclic   = $false
            Reason     = "InsufficientDaysWithData"
            Confidence = 0
        }
    }

    # Calculer l'écart-type des moyennes mensuelles
    $monthlyStdDev = [Math]::Sqrt($monthlyVariance / $daysWithData)

    # Calculer le coefficient de variation
    $coefficientOfVariation = $monthlyStdDev / $globalAverage

    # Déterminer s'il existe un pattern cyclique mensuel
    $isCyclic = $coefficientOfVariation -gt 0.2

    # Trouver les jours de pic et de creux
    $peakDay = ($monthlyAverages.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    $troughDay = ($monthlyAverages.GetEnumerator() | Sort-Object Value | Select-Object -First 1).Key

    return @{
        IsCyclic               = $isCyclic
        CoefficientOfVariation = $coefficientOfVariation
        DaysWithData           = $daysWithData
        MonthlyAverages        = $monthlyAverages
        PeakDay                = $peakDay
        PeakValue              = $monthlyAverages[$peakDay]
        TroughDay              = $troughDay
        TroughValue            = $monthlyAverages[$troughDay]
        Confidence             = [Math]::Min(1, $coefficientOfVariation * 2.5)
    }
}

<#
.SYNOPSIS
    Normalise les données de métriques pour l'analyse.
.DESCRIPTION
    Cette fonction normalise les données de métriques pour faciliter l'analyse
    et la comparaison entre différentes métriques avec des échelles différentes.
.PARAMETER MetricsData
    Données de métriques historiques obtenues via Get-HistoricalMetricsData.
.PARAMETER MetricNames
    Noms des métriques à normaliser (par défaut: toutes les métriques).
.PARAMETER Method
    Méthode de normalisation à utiliser (MinMax, ZScore, Robust).
.PARAMETER CustomRange
    Plage personnalisée pour la normalisation MinMax (par défaut: 0 à 1).
.EXAMPLE
    $historicalData = Get-HistoricalMetricsData -CollectorName "SystemMonitor"
    $normalizedData = ConvertTo-NormalizedMetrics -MetricsData $historicalData -Method "ZScore"
.OUTPUTS
    System.Collections.Hashtable
#>
function ConvertTo-NormalizedMetrics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$MetricsData,

        [Parameter(Mandatory = $false)]
        [string[]]$MetricNames,

        [Parameter(Mandatory = $false)]
        [ValidateSet("MinMax", "ZScore", "Robust")]
        [string]$Method = "MinMax",

        [Parameter(Mandatory = $false)]
        [double[]]$CustomRange = @(0, 1)
    )

    begin {
        Write-Verbose "Normalisation des données de métriques avec la méthode $Method"

        # Initialiser le résultat
        $result = @{
            CollectorName       = $MetricsData.CollectorName
            StartTime           = $MetricsData.StartTime
            EndTime             = $MetricsData.EndTime
            SamplingInterval    = $MetricsData.SamplingInterval
            NormalizationMethod = $Method
            MetricsData         = @{}
            OriginalStats       = @{}
        }

        # Si aucune métrique n'est spécifiée, utiliser toutes les métriques disponibles
        if (-not $MetricNames -or $MetricNames.Count -eq 0) {
            $MetricNames = $MetricsData.MetricsData.Keys
        }
    }

    process {
        try {
            foreach ($metricName in $MetricNames) {
                if (-not $MetricsData.MetricsData.ContainsKey($metricName)) {
                    Write-Warning "La métrique $metricName n'existe pas dans les données fournies."
                    continue
                }

                $metricData = $MetricsData.MetricsData[$metricName]
                $values = $metricData.Values

                # Calculer les statistiques de base
                $min = ($values | Measure-Object -Minimum).Minimum
                $max = ($values | Measure-Object -Maximum).Maximum
                $mean = ($values | Measure-Object -Average).Average
                $stdDev = [Math]::Sqrt(($values | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

                # Stocker les statistiques originales
                $result.OriginalStats[$metricName] = @{
                    Min    = $min
                    Max    = $max
                    Mean   = $mean
                    StdDev = $stdDev
                    Unit   = $metricData.Unit
                }

                # Normaliser les valeurs selon la méthode choisie
                $normalizedValues = @()

                switch ($Method) {
                    "MinMax" {
                        # Normalisation Min-Max: (x - min) / (max - min) * (customMax - customMin) + customMin
                        $range = $max - $min
                        $customMin = $CustomRange[0]
                        $customMax = $CustomRange[1]
                        $customRangeSize = $customMax - $customMin

                        if ($range -eq 0) {
                            # Éviter la division par zéro
                            $normalizedValues = $values | ForEach-Object { $customMin }
                        } else {
                            $normalizedValues = $values | ForEach-Object {
                                $normalized = ($_ - $min) / $range
                                $normalized = $normalized * $customRangeSize + $customMin
                                $normalized
                            }
                        }
                    }
                    "ZScore" {
                        # Normalisation Z-Score: (x - mean) / stdDev
                        if ($stdDev -eq 0) {
                            # Éviter la division par zéro
                            $normalizedValues = $values | ForEach-Object { 0 }
                        } else {
                            $normalizedValues = $values | ForEach-Object {
                                ($_ - $mean) / $stdDev
                            }
                        }
                    }
                    "Robust" {
                        # Normalisation robuste: utiliser la médiane et l'écart absolu médian (MAD)
                        $sortedValues = $values | Sort-Object
                        $median = if ($sortedValues.Count % 2 -eq 0) {
                            ($sortedValues[$sortedValues.Count / 2 - 1] + $sortedValues[$sortedValues.Count / 2]) / 2
                        } else {
                            $sortedValues[[Math]::Floor($sortedValues.Count / 2)]
                        }

                        $deviations = $values | ForEach-Object { [Math]::Abs($_ - $median) }
                        $sortedDeviations = $deviations | Sort-Object
                        $mad = if ($sortedDeviations.Count % 2 -eq 0) {
                            ($sortedDeviations[$sortedDeviations.Count / 2 - 1] + $sortedDeviations[$sortedDeviations.Count / 2]) / 2
                        } else {
                            $sortedDeviations[[Math]::Floor($sortedDeviations.Count / 2)]
                        }

                        # Facteur de mise à l'échelle pour la normalité
                        $scaleFactor = 1.4826
                        $adjustedMad = $mad * $scaleFactor

                        if ($adjustedMad -eq 0) {
                            # Éviter la division par zéro
                            $normalizedValues = $values | ForEach-Object { 0 }
                        } else {
                            $normalizedValues = $values | ForEach-Object {
                                ($_ - $median) / $adjustedMad
                            }
                        }
                    }
                }

                # Ajouter les données normalisées au résultat
                $result.MetricsData[$metricName] = @{
                    Values       = $normalizedValues
                    Timestamps   = $metricData.Timestamps
                    Unit         = "normalized"
                    OriginalUnit = $metricData.Unit
                }
            }
        } catch {
            Write-Error "Erreur lors de la normalisation des données: $_"
            return $null
        }
    }

    end {
        return $result
    }
}

<#
.SYNOPSIS
    Analyse la saisonnalité dans les données de métriques.
.DESCRIPTION
    Cette fonction analyse les données historiques pour détecter et quantifier
    les patterns saisonniers (journaliers, hebdomadaires, mensuels) dans les métriques.
.PARAMETER MetricsData
    Données de métriques historiques obtenues via Get-HistoricalMetricsData.
.PARAMETER MetricName
    Nom de la métrique à analyser.
.PARAMETER SeasonalityPeriods
    Périodes de saisonnalité à analyser en heures (par défaut: 24, 168, 720 pour journalier, hebdomadaire, mensuel).
.PARAMETER MinimumDataPoints
    Nombre minimum de points de données requis pour l'analyse.
.EXAMPLE
    $historicalData = Get-HistoricalMetricsData -CollectorName "SystemMonitor"
    $seasonality = Get-MetricsSeasonality -MetricsData $historicalData -MetricName "CPU_Usage"
.OUTPUTS
    System.Collections.Hashtable
#>
function Get-MetricsSeasonality {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$MetricsData,

        [Parameter(Mandatory = $true)]
        [string]$MetricName,

        [Parameter(Mandatory = $false)]
        [int[]]$SeasonalityPeriods = @(24, 168, 720),

        [Parameter(Mandatory = $false)]
        [int]$MinimumDataPoints = 48
    )

    begin {
        Write-Verbose "Analyse de la saisonnalité pour la métrique $MetricName"

        if (-not $MetricsData.MetricsData.ContainsKey($MetricName)) {
            Write-Error "La métrique $MetricName n'existe pas dans les données fournies."
            return $null
        }

        $metricData = $MetricsData.MetricsData[$MetricName]

        if ($metricData.Values.Count -lt $MinimumDataPoints) {
            Write-Warning "Nombre insuffisant de points de données pour analyser la saisonnalité. Minimum requis: $MinimumDataPoints, Disponible: $($metricData.Values.Count)"
            return @{
                MetricName         = $MetricName
                HasSeasonality     = $false
                Reason             = "InsufficientData"
                SeasonalityResults = @{}
            }
        }

        # Initialiser le résultat
        $result = @{
            MetricName         = $MetricName
            HasSeasonality     = $false
            SeasonalityResults = @{}
        }
    }

    process {
        try {
            # Les timestamps et valeurs sont déjà disponibles dans $metricData

            # Normaliser les valeurs pour l'analyse
            $normalizedData = @{
                CollectorName    = $MetricsData.CollectorName
                StartTime        = $MetricsData.StartTime
                EndTime          = $MetricsData.EndTime
                SamplingInterval = $MetricsData.SamplingInterval
                MetricsData      = @{
                    $MetricName = $metricData
                }
            }

            $normalizedMetrics = ConvertTo-NormalizedMetrics -MetricsData $normalizedData -MetricNames @($MetricName) -Method "ZScore"
            $normalizedValues = $normalizedMetrics.MetricsData[$MetricName].Values

            # Analyser chaque période de saisonnalité
            foreach ($period in $SeasonalityPeriods) {
                Write-Verbose "Analyse de la saisonnalité pour la période de $period heures"

                # Vérifier si nous avons suffisamment de données pour cette période
                if ($metricData.Values.Count -lt $period * 2) {
                    $result.SeasonalityResults[$period] = @{
                        Period         = $period
                        HasSeasonality = $false
                        Reason         = "InsufficientDataForPeriod"
                        Confidence     = 0
                    }
                    continue
                }

                # Calculer l'autocorrélation pour détecter la saisonnalité
                $autocorrelation = Get-Autocorrelation -Values $normalizedValues -MaxLag $period

                # Trouver les pics d'autocorrélation
                $peaks = Find-AutocorrelationPeaks -Autocorrelation $autocorrelation -Period $period

                # Déterminer si la saisonnalité est présente
                $hasSeasonality = $peaks.Count -gt 0 -and $peaks[0].Value -gt 0.3

                $result.SeasonalityResults[$period] = @{
                    Period              = $period
                    HasSeasonality      = $hasSeasonality
                    PeakLags            = $peaks | ForEach-Object { $_.Lag }
                    PeakValues          = $peaks | ForEach-Object { $_.Value }
                    Autocorrelation     = $autocorrelation
                    SeasonalityStrength = if ($peaks.Count -gt 0) { $peaks[0].Value } else { 0 }
                    Confidence          = if ($peaks.Count -gt 0) { [Math]::Min(1, $peaks[0].Value * 2) } else { 0 }
                }

                if ($hasSeasonality) {
                    $result.HasSeasonality = $true
                }
            }
        } catch {
            Write-Error "Erreur lors de l'analyse de la saisonnalité: $_"
            return $null
        }
    }

    end {
        return $result
    }
}

<#
.SYNOPSIS
    Calcule l'autocorrélation d'une série temporelle.
.DESCRIPTION
    Fonction interne qui calcule l'autocorrélation d'une série temporelle
    pour différents décalages (lags).
.PARAMETER Values
    Tableau des valeurs de la série temporelle.
.PARAMETER MaxLag
    Décalage maximum à calculer.
.OUTPUTS
    System.Collections.Hashtable
#>
function Get-Autocorrelation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Values,

        [Parameter(Mandatory = $true)]
        [int]$MaxLag
    )

    $n = $Values.Count
    $mean = ($Values | Measure-Object -Average).Average
    $variance = ($Values | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Sum).Sum / $n

    if ($variance -eq 0) {
        # Si la variance est nulle, il n'y a pas d'autocorrélation
        return @(0) * ($MaxLag + 1)
    }

    $autocorrelation = @()

    for ($lag = 0; $lag -le $MaxLag; $lag++) {
        $sum = 0

        for ($i = 0; $i -lt $n - $lag; $i++) {
            $sum += ($Values[$i] - $mean) * ($Values[$i + $lag] - $mean)
        }

        $autocorrelation += $sum / ($n * $variance)
    }

    return $autocorrelation
}

<#
.SYNOPSIS
    Trouve les pics d'autocorrélation.
.DESCRIPTION
    Fonction interne qui trouve les pics d'autocorrélation dans une série temporelle.
.PARAMETER Autocorrelation
    Tableau des valeurs d'autocorrélation.
.PARAMETER Period
    Période attendue pour la saisonnalité.
.OUTPUTS
    System.Collections.ArrayList
#>
function Find-AutocorrelationPeaks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Autocorrelation,

        [Parameter(Mandatory = $true)]
        [int]$Period
    )

    $peaks = New-Object System.Collections.ArrayList

    # Ignorer le lag 0 (toujours 1.0)
    for ($i = 1; $i -lt $Autocorrelation.Count; $i++) {
        $isPeak = $true

        # Vérifier si c'est un pic local
        for ($j = [Math]::Max(1, $i - 2); $j -le [Math]::Min($Autocorrelation.Count - 1, $i + 2); $j++) {
            if ($j -ne $i -and $Autocorrelation[$j] -gt $Autocorrelation[$i]) {
                $isPeak = $false
                break
            }
        }

        if ($isPeak -and $Autocorrelation[$i] -gt 0.2) {
            $null = $peaks.Add(@{
                    Lag   = $i
                    Value = $Autocorrelation[$i]
                })
        }
    }

    # Trier les pics par valeur décroissante
    $sortedPeaks = $peaks | Sort-Object -Property Value -Descending

    # Filtrer les pics qui sont proches de la période attendue
    $filteredPeaks = $sortedPeaks | Where-Object {
        $lag = $_.Lag
        $periodRatio = $lag / $Period
        $nearestMultiple = [Math]::Round($periodRatio)
        $deviation = [Math]::Abs($periodRatio - $nearestMultiple)
        $deviation -lt 0.2
    }

    return $filteredPeaks
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-HistoricalMetricsData, Find-CyclicPatterns, ConvertTo-NormalizedMetrics, Get-MetricsSeasonality
