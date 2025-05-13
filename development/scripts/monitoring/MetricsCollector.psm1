#Requires -Version 5.1
<#
.SYNOPSIS
    Module de collecte de métriques système haute précision.
.DESCRIPTION
    Ce module fournit des fonctions pour collecter, stocker et analyser des métriques
    système avec une haute précision et une faible empreinte mémoire.
.NOTES
    Nom: MetricsCollector.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.3
    Date de création: 2025-05-20
    Date de mise à jour: 2025-05-13
#>

# Variables globales du module
$script:Collectors = @{}
$script:CollectorCounter = 0
$script:DataPath = Join-Path -Path $PSScriptRoot -ChildPath "data"
$script:MetricsPath = Join-Path -Path $script:DataPath -ChildPath "metrics"
$script:DefaultSamplingRate = 1000 # ms
$script:DefaultRetentionPeriod = 7 # jours
$script:DefaultCompressionLevel = 3 # 1-9, 9 étant la compression maximale

# Créer les dossiers nécessaires s'ils n'existent pas
foreach ($path in @($script:DataPath, $script:MetricsPath)) {
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour créer un nouveau collecteur de métriques
function New-MetricsCollector {
    <#
    .SYNOPSIS
        Crée un nouveau collecteur de métriques système.
    .DESCRIPTION
        Cette fonction crée un nouveau collecteur de métriques système qui peut
        collecter, stocker et analyser des métriques avec une haute précision.
    .PARAMETER Name
        Nom du collecteur. Si non spécifié, un nom unique sera généré.
    .PARAMETER MetricDefinitions
        Définitions des métriques à collecter. Chaque définition doit contenir:
        - Name: Nom de la métrique
        - Type: Type de métrique (Counter, Gauge, Histogram, etc.)
        - Source: Source de la métrique (WMI, Performance Counter, Custom Script)
        - Query: Requête pour obtenir la métrique
        - Unit: Unité de mesure (%, MB, ms, etc.)
        - SamplingRate: Taux d'échantillonnage en millisecondes
    .PARAMETER StoragePath
        Chemin de stockage des métriques. Par défaut: sous-dossier dans le dossier metrics.
    .PARAMETER RetentionPeriod
        Période de rétention des métriques en jours. Par défaut: 7 jours.
    .PARAMETER CompressionLevel
        Niveau de compression des données (1-9). Par défaut: 3.
    .PARAMETER EnableRealTimeAnalysis
        Si spécifié, active l'analyse en temps réel des métriques.
    .EXAMPLE
        $metricDefinitions = @(
            @{
                Name = "CPU_Usage"
                Type = "Gauge"
                Source = "PerformanceCounter"
                Query = "\Processor(_Total)\% Processor Time"
                Unit = "%"
                SamplingRate = 1000
            },
            @{
                Name = "Memory_Available"
                Type = "Gauge"
                Source = "PerformanceCounter"
                Query = "\Memory\Available MBytes"
                Unit = "MB"
                SamplingRate = 2000
            }
        )
        New-MetricsCollector -Name "SystemMetrics" -MetricDefinitions $metricDefinitions
    .OUTPUTS
        [PSCustomObject] avec les informations sur le collecteur créé
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [array]$MetricDefinitions,

        [Parameter(Mandatory = $false)]
        [string]$StoragePath,

        [Parameter(Mandatory = $false)]
        [int]$RetentionPeriod = $script:DefaultRetentionPeriod,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 9)]
        [int]$CompressionLevel = $script:DefaultCompressionLevel,

        [Parameter(Mandatory = $false)]
        [switch]$EnableRealTimeAnalysis
    )

    # Générer un nom unique si non spécifié
    if ([string]::IsNullOrEmpty($Name)) {
        $script:CollectorCounter++
        $Name = "Collector_$script:CollectorCounter"
    }

    # Vérifier si un collecteur avec ce nom existe déjà
    if ($script:Collectors.ContainsKey($Name)) {
        Write-Warning "Un collecteur avec le nom '$Name' existe déjà."
        return $null
    }

    # Définir le chemin de stockage
    if ([string]::IsNullOrEmpty($StoragePath)) {
        $StoragePath = Join-Path -Path $script:MetricsPath -ChildPath $Name
    }

    # Créer le dossier de stockage s'il n'existe pas
    if (-not (Test-Path -Path $StoragePath)) {
        New-Item -Path $StoragePath -ItemType Directory -Force | Out-Null
    }

    # Valider et préparer les définitions de métriques
    $validatedMetrics = @()
    foreach ($metric in $MetricDefinitions) {
        # Vérifier les propriétés requises
        if (-not $metric.ContainsKey("Name") -or
            -not $metric.ContainsKey("Type") -or
            -not $metric.ContainsKey("Source") -or
            -not $metric.ContainsKey("Query")) {
            Write-Warning "Définition de métrique invalide: $($metric | ConvertTo-Json -Compress)"
            continue
        }

        # Définir les valeurs par défaut si nécessaire
        if (-not $metric.ContainsKey("Unit")) {
            $metric["Unit"] = ""
        }

        if (-not $metric.ContainsKey("SamplingRate")) {
            $metric["SamplingRate"] = $script:DefaultSamplingRate
        }

        # Ajouter des propriétés supplémentaires
        $metric["LastSampleTime"] = $null
        $metric["LastValue"] = $null
        $metric["Counter"] = $null

        # Initialiser le compteur de performance si nécessaire
        if ($metric["Source"] -eq "PerformanceCounter") {
            try {
                $counter = New-Object System.Diagnostics.PerformanceCounter
                $counterPath = $metric["Query"]

                # Extraire la catégorie et le compteur
                if ($counterPath -match '\\([^\\]+)\\([^\\]+)') {
                    $category = $matches[1]
                    $counterName = $matches[2]

                    # Gérer le cas spécial pour les compteurs avec instance
                    if ($category -match '(.+)\((.+)\)') {
                        $category = $matches[1]
                        $instance = $matches[2]
                        $counter.CategoryName = $category
                        $counter.CounterName = $counterName
                        $counter.InstanceName = $instance
                    } else {
                        $counter.CategoryName = $category
                        $counter.CounterName = $counterName
                    }

                    # Initialiser le compteur
                    $counter.NextValue() | Out-Null
                    $metric["Counter"] = $counter
                } else {
                    Write-Warning "Format de chemin de compteur de performance invalide: $counterPath"
                }
            } catch {
                Write-Warning "Erreur lors de l'initialisation du compteur de performance: $_"
            }
        }

        $validatedMetrics += $metric
    }

    # Créer l'objet collecteur
    $collector = [PSCustomObject]@{
        Name                   = $Name
        MetricDefinitions      = $validatedMetrics
        StoragePath            = $StoragePath
        RetentionPeriod        = $RetentionPeriod
        CompressionLevel       = $CompressionLevel
        EnableRealTimeAnalysis = $EnableRealTimeAnalysis
        StartTime              = Get-Date
        Status                 = "Created"
        Job                    = $null
        DataFiles              = @()
        CurrentDataFile        = $null
        Statistics             = @{
            SamplesCollected    = 0
            DataPointsCollected = 0
            LastCollectionTime  = $null
            StorageUsed         = 0
        }
    }

    # Enregistrer le collecteur
    $script:Collectors[$Name] = $collector

    return $collector
}

# Fonction pour démarrer la collecte de métriques
function Start-MetricsCollection {
    <#
    .SYNOPSIS
        Démarre la collecte de métriques pour un collecteur spécifié.
    .DESCRIPTION
        Cette fonction démarre la collecte de métriques en arrière-plan pour
        un collecteur précédemment créé avec New-MetricsCollector.
    .PARAMETER Name
        Nom du collecteur à démarrer.
    .PARAMETER AsJob
        Si spécifié, démarre la collecte en tant que job PowerShell.
    .EXAMPLE
        Start-MetricsCollection -Name "SystemMetrics"
    .OUTPUTS
        [PSCustomObject] avec les informations sur le collecteur démarré
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$AsJob
    )

    # Vérifier si le collecteur existe
    if (-not $script:Collectors.ContainsKey($Name)) {
        Write-Warning "Le collecteur '$Name' n'existe pas."
        return $null
    }

    # Récupérer le collecteur
    $collector = $script:Collectors[$Name]

    # Vérifier si le collecteur est déjà en cours d'exécution
    if ($collector.Status -eq "Running" -and $null -ne $collector.Job -and $collector.Job.State -eq "Running") {
        Write-Warning "Le collecteur '$Name' est déjà en cours d'exécution."
        return $collector
    }

    # Créer un nouveau fichier de données
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $dataFilePath = Join-Path -Path $collector.StoragePath -ChildPath "metrics_$timestamp.json"
    $collector.CurrentDataFile = $dataFilePath
    $collector.DataFiles += $dataFilePath

    # Initialiser le fichier de données
    $initialData = @{
        Collector     = $collector.Name
        StartTime     = Get-Date
        Metrics       = @{}
        SamplingRates = @{}
        Units         = @{}
    }

    foreach ($metric in $collector.MetricDefinitions) {
        $initialData.Metrics[$metric.Name] = @()
        $initialData.SamplingRates[$metric.Name] = $metric.SamplingRate
        $initialData.Units[$metric.Name] = $metric.Unit
    }

    $initialData | ConvertTo-Json -Depth 10 | Out-File -FilePath $dataFilePath -Encoding utf8 -Force

    # Fonction de collecte de métriques
    $collectionScript = {
        param($collectorName, $dataFilePath, $metricDefinitions, $enableRealTimeAnalysis)

        # Fonction pour collecter une métrique
        function Get-MetricValue {
            param($metric)

            $value = $null

            try {
                switch ($metric.Source) {
                    "PerformanceCounter" {
                        if ($null -ne $metric.Counter) {
                            $value = $metric.Counter.NextValue()
                        }
                    }
                    "WMI" {
                        $query = $metric.Query
                        $result = Invoke-WmiMethod -Query $query
                        if ($result -and $result.Count -gt 0) {
                            $value = $result[0]
                        }
                    }
                    "Script" {
                        $scriptBlock = [ScriptBlock]::Create($metric.Query)
                        $value = & $scriptBlock
                    }
                    default {
                        Write-Warning "Source de métrique non prise en charge: $($metric.Source)"
                    }
                }
            } catch {
                Write-Warning "Erreur lors de la collecte de la métrique '$($metric.Name)': $_"
            }

            return $value
        }

        # Initialiser les compteurs de performance
        foreach ($metric in $metricDefinitions) {
            if ($metric.Source -eq "PerformanceCounter" -and $null -eq $metric.Counter) {
                try {
                    $counter = New-Object System.Diagnostics.PerformanceCounter
                    $counterPath = $metric.Query

                    # Extraire la catégorie et le compteur
                    if ($counterPath -match '\\([^\\]+)\\([^\\]+)') {
                        $category = $matches[1]
                        $counterName = $matches[2]

                        # Gérer le cas spécial pour les compteurs avec instance
                        if ($category -match '(.+)\((.+)\)') {
                            $category = $matches[1]
                            $instance = $matches[2]
                            $counter.CategoryName = $category
                            $counter.CounterName = $counterName
                            $counter.InstanceName = $instance
                        } else {
                            $counter.CategoryName = $category
                            $counter.CounterName = $counterName
                        }

                        # Initialiser le compteur
                        $counter.NextValue() | Out-Null
                        $metric.Counter = $counter
                    } else {
                        Write-Warning "Format de chemin de compteur de performance invalide: $counterPath"
                    }
                } catch {
                    Write-Warning "Erreur lors de l'initialisation du compteur de performance: $_"
                }
            }
        }

        # Charger les données existantes
        $data = Get-Content -Path $dataFilePath -Raw | ConvertFrom-Json

        # Convertir les collections de métriques en tableaux
        $metricsData = @{}
        foreach ($metricName in $data.Metrics.PSObject.Properties.Name) {
            $metricsData[$metricName] = @($data.Metrics.$metricName)
        }

        # Boucle de collecte
        while ($true) {
            $collectionTime = Get-Date

            # Collecter les métriques qui doivent être échantillonnées
            foreach ($metric in $metricDefinitions) {
                # Vérifier si c'est le moment d'échantillonner cette métrique
                $shouldSample = $false

                if ($null -eq $metric.LastSampleTime) {
                    $shouldSample = $true
                } else {
                    $elapsed = ($collectionTime - $metric.LastSampleTime).TotalMilliseconds
                    if ($elapsed -ge $metric.SamplingRate) {
                        $shouldSample = $true
                    }
                }

                if ($shouldSample) {
                    $value = Get-MetricValue -metric $metric

                    if ($null -ne $value) {
                        # Mettre à jour les propriétés de la métrique
                        $metric.LastSampleTime = $collectionTime
                        $metric.LastValue = $value

                        # Ajouter la valeur aux données
                        $dataPoint = @{
                            Timestamp = $collectionTime
                            Value     = $value
                        }

                        $metricsData[$metric.Name] += $dataPoint

                        # Analyse en temps réel si activée
                        if ($enableRealTimeAnalysis) {
                            # TODO: Implémenter l'analyse en temps réel
                        }
                    }
                }
            }

            # Créer un nouvel objet de données pour l'enregistrement
            $dataToSave = [PSCustomObject]@{
                Collector     = $data.Collector
                StartTime     = $data.StartTime
                Metrics       = $metricsData
                SamplingRates = $data.SamplingRates
                Units         = $data.Units
            }

            # Enregistrer les données périodiquement
            $dataToSave | ConvertTo-Json -Depth 10 | Out-File -FilePath $dataFilePath -Force

            # Attendre un court instant avant la prochaine collecte
            Start-Sleep -Milliseconds 100
        }
    }

    # Démarrer la collecte
    if ($AsJob) {
        $job = Start-Job -ScriptBlock $collectionScript -ArgumentList $collector.Name, $dataFilePath, $collector.MetricDefinitions, $collector.EnableRealTimeAnalysis
        $collector.Job = $job
    } else {
        # Démarrer un runspace pour la collecte en arrière-plan
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()

        $powershell = [powershell]::Create()
        $powershell.Runspace = $runspace
        $powershell.AddScript($collectionScript).AddArgument($collector.Name).AddArgument($dataFilePath).AddArgument($collector.MetricDefinitions).AddArgument($collector.EnableRealTimeAnalysis) | Out-Null

        $asyncResult = $powershell.BeginInvoke()

        $collector.Job = [PSCustomObject]@{
            PowerShell  = $powershell
            Runspace    = $runspace
            AsyncResult = $asyncResult
            State       = "Running"
        }
    }

    # Mettre à jour le statut du collecteur
    $collector.Status = "Running"
    $collector.StartTime = Get-Date

    return $collector
}

# Fonction pour arrêter la collecte de métriques
function Stop-MetricsCollection {
    <#
    .SYNOPSIS
        Arrête la collecte de métriques pour un collecteur spécifié.
    .DESCRIPTION
        Cette fonction arrête la collecte de métriques en arrière-plan pour
        un collecteur précédemment démarré avec Start-MetricsCollection.
    .PARAMETER Name
        Nom du collecteur à arrêter.
    .EXAMPLE
        Stop-MetricsCollection -Name "SystemMetrics"
    .OUTPUTS
        [bool] Indique si l'arrêt a réussi
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    # Vérifier si le collecteur existe
    if (-not $script:Collectors.ContainsKey($Name)) {
        Write-Warning "Le collecteur '$Name' n'existe pas."
        return $false
    }

    # Récupérer le collecteur
    $collector = $script:Collectors[$Name]

    # Vérifier si le collecteur est en cours d'exécution
    if ($collector.Status -ne "Running" -or $null -eq $collector.Job) {
        $collector.Status = "Stopped"
        return $true
    }

    # Arrêter le job
    try {
        if ($collector.Job -is [System.Management.Automation.Job]) {
            # Arrêter le job PowerShell
            Stop-Job -Job $collector.Job -Force
            Remove-Job -Job $collector.Job -Force
        } else {
            # Arrêter le runspace
            $collector.Job.PowerShell.Stop()
            $collector.Job.PowerShell.Dispose()
            $collector.Job.Runspace.Dispose()
        }

        # Mettre à jour le statut du collecteur
        $collector.Status = "Stopped"
        $collector.Job = $null

        return $true
    } catch {
        Write-Error "Erreur lors de l'arrêt du collecteur '$Name': $_"
        return $false
    }
}

# Fonction pour obtenir les métriques collectées
function Get-CollectedMetrics {
    <#
    .SYNOPSIS
        Récupère les métriques collectées par un collecteur spécifié.
    .DESCRIPTION
        Cette fonction récupère les métriques collectées par un collecteur
        précédemment créé avec New-MetricsCollector.
    .PARAMETER Name
        Nom du collecteur dont récupérer les métriques.
    .PARAMETER MetricNames
        Noms des métriques à récupérer. Si non spécifié, toutes les métriques sont retournées.
    .PARAMETER StartTime
        Heure de début pour filtrer les métriques. Si non spécifié, toutes les métriques sont retournées.
    .PARAMETER EndTime
        Heure de fin pour filtrer les métriques. Si non spécifié, toutes les métriques jusqu'à maintenant sont retournées.
    .PARAMETER AggregationType
        Type d'agrégation à appliquer (None, Average, Min, Max, Sum). Par défaut: None.
    .PARAMETER AggregationInterval
        Intervalle d'agrégation en secondes. Par défaut: 60 secondes.
    .EXAMPLE
        Get-CollectedMetrics -Name "SystemMetrics" -MetricNames "CPU_Usage", "Memory_Available" -StartTime (Get-Date).AddHours(-1)
    .OUTPUTS
        [PSCustomObject] avec les métriques collectées
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string[]]$MetricNames,

        [Parameter(Mandatory = $false)]
        [datetime]$StartTime,

        [Parameter(Mandatory = $false)]
        [datetime]$EndTime = (Get-Date),

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Average", "Min", "Max", "Sum")]
        [string]$AggregationType = "None",

        [Parameter(Mandatory = $false)]
        [int]$AggregationInterval = 60
    )

    # Vérifier si le collecteur existe
    if (-not $script:Collectors.ContainsKey($Name)) {
        Write-Warning "Le collecteur '$Name' n'existe pas."
        return $null
    }

    # Récupérer le collecteur
    $collector = $script:Collectors[$Name]

    # Vérifier si des données ont été collectées
    if ($collector.DataFiles.Count -eq 0) {
        Write-Warning "Aucune donnée n'a été collectée par le collecteur '$Name'."
        return $null
    }

    # Charger les données du fichier actuel
    $dataFilePath = $collector.CurrentDataFile
    $data = Get-Content -Path $dataFilePath -Raw | ConvertFrom-Json

    # Filtrer les métriques par nom si spécifié
    $filteredMetrics = @{}

    if ($null -ne $MetricNames -and $MetricNames.Count -gt 0) {
        foreach ($metricName in $MetricNames) {
            if ($data.Metrics.PSObject.Properties.Name -contains $metricName) {
                # Convertir en tableau pour éviter les problèmes de modification de collection
                $filteredMetrics[$metricName] = @($data.Metrics.$metricName)
            }
        }
    } else {
        foreach ($metricName in $data.Metrics.PSObject.Properties.Name) {
            # Convertir en tableau pour éviter les problèmes de modification de collection
            $filteredMetrics[$metricName] = @($data.Metrics.$metricName)
        }
    }

    # Filtrer les métriques par plage de temps
    if ($null -ne $StartTime) {
        foreach ($metricName in @($filteredMetrics.Keys)) {
            $filteredData = @($filteredMetrics[$metricName] | Where-Object {
                    if ($_.Timestamp -is [string]) {
                        $timestamp = [datetime]::Parse($_.Timestamp)
                    } else {
                        $timestamp = $_.Timestamp
                    }
                    $timestamp -ge $StartTime -and $timestamp -le $EndTime
                })
            $filteredMetrics[$metricName] = $filteredData
        }
    }

    # Appliquer l'agrégation si demandée
    if ($AggregationType -ne "None") {
        $aggregatedMetrics = @{}

        foreach ($metricName in $filteredMetrics.Keys) {
            $metricData = $filteredMetrics[$metricName]
            $aggregatedData = @()

            # Regrouper les données par intervalle de temps
            $intervalGroups = @{}

            foreach ($dataPoint in $metricData) {
                $timestamp = [datetime]::Parse($dataPoint.Timestamp)
                $intervalKey = [math]::Floor(($timestamp - $StartTime).TotalSeconds / $AggregationInterval)

                if (-not $intervalGroups.ContainsKey($intervalKey)) {
                    $intervalGroups[$intervalKey] = @()
                }

                $intervalGroups[$intervalKey] += $dataPoint
            }

            # Agréger les données pour chaque intervalle
            foreach ($intervalKey in $intervalGroups.Keys | Sort-Object) {
                $intervalData = $intervalGroups[$intervalKey]
                $intervalStartTime = $StartTime.AddSeconds($intervalKey * $AggregationInterval)
                $intervalEndTime = $intervalStartTime.AddSeconds($AggregationInterval)

                $values = $intervalData | ForEach-Object { $_.Value }

                $aggregatedValue = switch ($AggregationType) {
                    "Average" { ($values | Measure-Object -Average).Average }
                    "Min" { ($values | Measure-Object -Minimum).Minimum }
                    "Max" { ($values | Measure-Object -Maximum).Maximum }
                    "Sum" { ($values | Measure-Object -Sum).Sum }
                }

                $aggregatedData += @{
                    StartTime = $intervalStartTime
                    EndTime   = $intervalEndTime
                    Value     = $aggregatedValue
                    Count     = $values.Count
                }
            }

            $aggregatedMetrics[$metricName] = $aggregatedData
        }

        $filteredMetrics = $aggregatedMetrics
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        CollectorName       = $Name
        StartTime           = $StartTime
        EndTime             = $EndTime
        AggregationType     = $AggregationType
        AggregationInterval = $AggregationInterval
        Metrics             = $filteredMetrics
        Units               = $data.Units
    }

    return $result
}

# Exporter les fonctions du module
Export-ModuleMember -Function New-MetricsCollector, Start-MetricsCollection,
Stop-MetricsCollection, Get-CollectedMetrics

# Exporter les variables globales pour les tests
Export-ModuleMember -Variable Collectors
