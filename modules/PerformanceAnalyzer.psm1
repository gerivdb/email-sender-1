function Invoke-PredictiveModel {
    <#
    .SYNOPSIS
        Invoque le module Python d'analyse prédictive.
    .DESCRIPTION
        Exécute le module Python PredictiveModel.py avec les paramètres spécifiés.
    .PARAMETER Action
        Action à effectuer (train, predict, anomalies, trends).
    .PARAMETER InputFile
        Fichier d'entrée contenant les métriques au format JSON.
    .PARAMETER OutputFile
        Fichier de sortie pour les résultats (facultatif).
    .PARAMETER Horizon
        Horizon de prédiction (nombre de points à prédire).
    .PARAMETER Force
        Force le réentraînement des modèles.
    .EXAMPLE
        Invoke-PredictiveModel -Action predict -InputFile metrics.json -OutputFile predictions.json
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("train", "predict", "anomalies", "trends")]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [int]$Horizon,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier que l'analyse prédictive est activée
    if (-not $script:PerformanceAnalyzerConfig.PredictiveModelEnabled) {
        Write-Warning "L'analyse prédictive est désactivée. Utilisez Initialize-PerformanceAnalyzer -PredictiveModelEnabled `$true pour l'activer."
        return $null
    }

    # Vérifier que le fichier d'entrée existe
    if (-not (Test-Path -Path $InputFile)) {
        Write-Error "Le fichier d'entrée '$InputFile' n'existe pas."
        return $null
    }

    # Construire la commande Python
    $pythonArgs = @(
        "`"$($script:PerformanceAnalyzerConfig.PredictiveModelPath)`"",
        "--action", $Action,
        "--input", "`"$InputFile`""
    )

    if ($OutputFile) {
        $pythonArgs += "--output", "`"$OutputFile`""
    }

    if ($Horizon) {
        $pythonArgs += "--horizon", $Horizon
    }

    if ($Force) {
        $pythonArgs += "--force"
    }

    $pythonCommand = "$($script:PerformanceAnalyzerConfig.PythonPath) $($pythonArgs -join ' ')"
    Write-Log -Message "Exécution de la commande: $pythonCommand" -Level "DEBUG"

    try {
        # Exécuter la commande Python
        $result = & $script:PerformanceAnalyzerConfig.PythonPath $script:PerformanceAnalyzerConfig.PredictiveModelPath `
            --action $Action `
            --input "$InputFile" `
        $(if ($OutputFile) { "--output `"$OutputFile`"" }) `
        $(if ($Horizon) { "--horizon $Horizon" }) `
        $(if ($Force) { "--force" })

        # Convertir la sortie en objet PowerShell
        if ($result) {
            try {
                $resultObj = $result | ConvertFrom-Json
                return $resultObj
            } catch {
                Write-Warning "Impossible de convertir la sortie en JSON: $_"
                return $result
            }
        } else {
            Write-Warning "Aucun résultat retourné par le module d'analyse prédictive."
            return $null
        }
    } catch {
        Write-Error "Erreur lors de l'exécution du module d'analyse prédictive: $_"
        return $null
    }
}

function Export-MetricsToJson {
    <#
    .SYNOPSIS
        Exporte les métriques au format JSON pour l'analyse prédictive.
    .DESCRIPTION
        Convertit les métriques collectées en format JSON compatible avec le module d'analyse prédictive.
    .PARAMETER Metrics
        Métriques à exporter.
    .PARAMETER OutputPath
        Chemin du fichier de sortie.
    .EXAMPLE
        Export-MetricsToJson -Metrics $metrics -OutputPath "metrics.json"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Convertir les métriques au format attendu par le module Python
    $formattedMetrics = $Metrics | ForEach-Object {
        @{
            Timestamp = if ($_.Timestamp -is [DateTime]) { $_.Timestamp.ToString('o') } else { $_.Timestamp }
            CPU       = @{
                Usage = $_.CPU.Usage
            }
            Memory    = @{
                Usage = $_.Memory.Physical.UsagePercent
            }
            Disk      = @{
                Usage = $_.Disk.Usage.Average
            }
            Network   = @{
                BandwidthUsage = $_.Network.BandwidthUsage
            }
        }
    }

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Exporter les métriques au format JSON
    $formattedMetrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Log -Message "Métriques exportées vers $OutputPath" -Level "INFO"
    return $OutputPath
}

function Get-PredictivePerformanceTrend {
    <#
    .SYNOPSIS
        Obtient les tendances prédictives des métriques de performance.
    .DESCRIPTION
        Analyse les tendances des métriques de performance en utilisant le module d'analyse prédictive.
    .PARAMETER Metrics
        Métriques à analyser.
    .PARAMETER MetricName
        Nom de la métrique à analyser (CPU.Usage, Memory.Usage, Disk.Usage, Network.BandwidthUsage).
    .EXAMPLE
        Get-PredictivePerformanceTrend -Metrics $metrics -MetricName "CPU.Usage"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics,

        [Parameter(Mandatory = $true)]
        [ValidateSet("CPU.Usage", "Memory.Usage", "Disk.Usage", "Network.BandwidthUsage")]
        [string]$MetricName
    )

    # Vérifier que l'analyse prédictive est activée
    if (-not $script:PerformanceAnalyzerConfig.PredictiveModelEnabled) {
        Write-Warning "L'analyse prédictive est désactivée. Utilisez Initialize-PerformanceAnalyzer -PredictiveModelEnabled `$true pour l'activer."
        return $null
    }

    # Exporter les métriques au format JSON
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $jsonPath = Export-MetricsToJson -Metrics $Metrics -OutputPath $tempFile

    # Analyser les tendances
    $result = Invoke-PredictiveModel -Action "trends" -InputFile $jsonPath

    # Nettoyer le fichier temporaire
    if (Test-Path -Path $jsonPath) {
        Remove-Item -Path $jsonPath -Force
    }

    # Extraire les résultats pour la métrique spécifiée
    if ($result -and $result.PSObject.Properties.Name -contains $MetricName) {
        return $result.$MetricName
    } else {
        Write-Warning "Aucun résultat disponible pour la métrique $MetricName"
        return $null
    }
}

function Get-PerformancePrediction {
    <#
    .SYNOPSIS
        Prédit les valeurs futures des métriques de performance.
    .DESCRIPTION
        Utilise le module d'analyse prédictive pour prédire les valeurs futures des métriques de performance.
    .PARAMETER Metrics
        Métriques historiques à utiliser pour la prédiction.
    .PARAMETER MetricName
        Nom de la métrique à prédire (CPU.Usage, Memory.Usage, Disk.Usage, Network.BandwidthUsage).
    .PARAMETER Horizon
        Nombre de points à prédire dans le futur.
    .EXAMPLE
        Get-PerformancePrediction -Metrics $metrics -MetricName "CPU.Usage" -Horizon 24
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics,

        [Parameter(Mandatory = $true)]
        [ValidateSet("CPU.Usage", "Memory.Usage", "Disk.Usage", "Network.BandwidthUsage")]
        [string]$MetricName,

        [Parameter(Mandatory = $false)]
        [int]$Horizon = 0
    )

    # Vérifier que l'analyse prédictive est activée
    if (-not $script:PerformanceAnalyzerConfig.PredictiveModelEnabled) {
        Write-Warning "L'analyse prédictive est désactivée. Utilisez Initialize-PerformanceAnalyzer -PredictiveModelEnabled `$true pour l'activer."
        return $null
    }

    # Utiliser l'horizon de configuration si non spécifié
    if ($Horizon -le 0) {
        $Horizon = $script:PerformanceAnalyzerConfig.PredictionHorizon
    }

    # Exporter les métriques au format JSON
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $jsonPath = Export-MetricsToJson -Metrics $Metrics -OutputPath $tempFile

    # Effectuer la prédiction
    $result = Invoke-PredictiveModel -Action "predict" -InputFile $jsonPath -Horizon $Horizon

    # Nettoyer le fichier temporaire
    if (Test-Path -Path $jsonPath) {
        Remove-Item -Path $jsonPath -Force
    }

    # Extraire les résultats pour la métrique spécifiée
    if ($result -and $result.PSObject.Properties.Name -contains $MetricName) {
        return $result.$MetricName
    } else {
        Write-Warning "Aucun résultat disponible pour la métrique $MetricName"
        return $null
    }
}

function Find-PredictivePerformanceAnomaly {
    <#
    .SYNOPSIS
        Détecte les anomalies dans les métriques de performance en utilisant l'analyse prédictive.
    .DESCRIPTION
        Utilise le module d'analyse prédictive pour détecter les anomalies dans les métriques de performance.
    .PARAMETER Metrics
        Métriques à analyser.
    .PARAMETER MetricTypes
        Types de métriques à analyser (CPU, Memory, Disk, Network, All).
    .PARAMETER Sensitivity
        Sensibilité de la détection d'anomalies (Low, Medium, High).
    .EXAMPLE
        Find-PredictivePerformanceAnomaly -Metrics $metrics -MetricTypes @("CPU", "Memory") -Sensitivity "High"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CPU", "Memory", "Disk", "Network", "All")]
        [string[]]$MetricTypes = @("All"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Low", "Medium", "High")]
        [string]$Sensitivity = ""
    )

    # Vérifier que l'analyse prédictive est activée
    if (-not $script:PerformanceAnalyzerConfig.PredictiveModelEnabled) {
        Write-Warning "L'analyse prédictive est désactivée. Utilisez Initialize-PerformanceAnalyzer -PredictiveModelEnabled `$true pour l'activer."
        return $null
    }

    # Utiliser la sensibilité de configuration si non spécifiée
    if ([string]::IsNullOrEmpty($Sensitivity)) {
        $Sensitivity = $script:PerformanceAnalyzerConfig.AnomalySensitivity
    }

    # Exporter les métriques au format JSON
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $jsonPath = Export-MetricsToJson -Metrics $Metrics -OutputPath $tempFile

    # Configurer le fichier de configuration pour la sensibilité
    $configFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $config = @{
        anomaly_sensitivity = switch ($Sensitivity) {
            "Low" { 0.1 }
            "Medium" { 0.05 }
            "High" { 0.01 }
            default { 0.05 }
        }
    }
    $config | ConvertTo-Json | Out-File -FilePath $configFile -Encoding utf8

    # Détecter les anomalies
    $result = Invoke-PredictiveModel -Action "anomalies" -InputFile $jsonPath

    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $jsonPath) {
        Remove-Item -Path $jsonPath -Force
    }
    if (Test-Path -Path $configFile) {
        Remove-Item -Path $configFile -Force
    }

    # Filtrer les résultats selon les types de métriques demandés
    if ($result) {
        if ($MetricTypes -contains "All") {
            return $result
        } else {
            $filteredResult = @{}
            foreach ($metricType in $MetricTypes) {
                $metricName = switch ($metricType) {
                    "CPU" { "CPU.Usage" }
                    "Memory" { "Memory.Usage" }
                    "Disk" { "Disk.Usage" }
                    "Network" { "Network.BandwidthUsage" }
                }
                if ($result.PSObject.Properties.Name -contains $metricName) {
                    $filteredResult[$metricName] = $result.$metricName
                }
            }
            return $filteredResult
        }
    } else {
        Write-Warning "Aucune anomalie détectée"
        return $null
    }
}

function Start-PerformanceModelTraining {
    <#
    .SYNOPSIS
        Entraîne les modèles prédictifs de performance.
    .DESCRIPTION
        Utilise le module d'analyse prédictive pour entraîner les modèles de prédiction des performances.
    .PARAMETER Metrics
        Métriques à utiliser pour l'entraînement.
    .PARAMETER Force
        Force le réentraînement des modèles même si l'intervalle de réentraînement n'est pas atteint.
    .EXAMPLE
        Train-PerformanceModel -Metrics $metrics -Force
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier que l'analyse prédictive est activée
    if (-not $script:PerformanceAnalyzerConfig.PredictiveModelEnabled) {
        Write-Warning "L'analyse prédictive est désactivée. Utilisez Initialize-PerformanceAnalyzer -PredictiveModelEnabled `$true pour l'activer."
        return $null
    }

    # Exporter les métriques au format JSON
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $jsonPath = Export-MetricsToJson -Metrics $Metrics -OutputPath $tempFile

    # Entraîner les modèles
    $result = Invoke-PredictiveModel -Action "train" -InputFile $jsonPath -Force:$Force

    # Nettoyer le fichier temporaire
    if (Test-Path -Path $jsonPath) {
        Remove-Item -Path $jsonPath -Force
    }

    return $result
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-PerformanceAnalyzer, Start-PerformanceAnalysis, Get-PerformanceReport, Measure-CPUMetrics, Measure-MemoryMetrics, Measure-DiskMetrics, Measure-NetworkMetrics, Measure-Metrics, Get-MetricTrend, Invoke-PredictiveModel, Export-MetricsToJson, Get-PredictivePerformanceTrend, Get-PerformancePrediction, Find-PredictivePerformanceAnomaly, Start-PerformanceModelTraining
# Module d'analyse des performances
# Ce module analyse les mÃ©triques de performance du systÃ¨me
# Author: EMAIL_SENDER_1 Team
# Version: 1.0.0

#Requires -Version 5.1

# Variables globales du module
$script:PerformanceAnalyzerConfig = @{
    Enabled                = $true
    ConfigPath             = "$env:TEMP\PerformanceAnalyzer\config.json"
    LogPath                = "$env:TEMP\PerformanceAnalyzer\logs.log"
    LogLevel               = "INFO"
    PythonPath             = "python"
    PredictiveModelPath    = "$PSScriptRoot\PredictiveModel.py"
    PredictiveModelEnabled = $true
    ModelStoragePath       = "$env:TEMP\PerformanceAnalyzer\models"
    PredictionHorizon      = 12
    AnomalySensitivity     = "Medium"
}

function Initialize-PerformanceAnalyzer {
    <#
    .SYNOPSIS
        Initialise le module d'analyse des performances.
    .DESCRIPTION
        Configure et initialise le module d'analyse des performances avec les paramÃ¨tres spÃ©cifiÃ©s.
    .PARAMETER Enabled
        Active ou dÃ©sactive l'analyseur de performances.
    .PARAMETER ConfigPath
        Chemin du fichier de configuration.
    .PARAMETER LogPath
        Chemin du fichier de log.
    .PARAMETER LogLevel
        Niveau de log (DEBUG, INFO, WARNING, ERROR).
    .PARAMETER PythonPath
        Chemin vers l'exÃ©cutable Python.
    .PARAMETER PredictiveModelEnabled
        Active ou dÃ©sactive l'analyse prÃ©dictive.
    .PARAMETER ModelStoragePath
        Chemin de stockage des modÃ¨les prÃ©dictifs.
    .PARAMETER PredictionHorizon
        Nombre de points Ã  prÃ©dire dans le futur.
    .PARAMETER AnomalySensitivity
        SensibilitÃ© de la dÃ©tection d'anomalies (Low, Medium, High).
    .EXAMPLE
        Initialize-PerformanceAnalyzer -ConfigPath "C:\Config\perf_config.json" -LogPath "C:\Logs\perf.log"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "$env:TEMP\PerformanceAnalyzer\config.json",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$env:TEMP\PerformanceAnalyzer\logs.log",

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$LogLevel = "INFO",

        [Parameter(Mandatory = $false)]
        [string]$PythonPath = "python",

        [Parameter(Mandatory = $false)]
        [bool]$PredictiveModelEnabled = $true,

        [Parameter(Mandatory = $false)]
        [string]$ModelStoragePath = "$env:TEMP\PerformanceAnalyzer\models",

        [Parameter(Mandatory = $false)]
        [int]$PredictionHorizon = 12,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Low", "Medium", "High")]
        [string]$AnomalySensitivity = "Medium"
    )

    # Mettre Ã  jour la configuration
    $script:PerformanceAnalyzerConfig.Enabled = $Enabled
    $script:PerformanceAnalyzerConfig.ConfigPath = $ConfigPath
    $script:PerformanceAnalyzerConfig.LogPath = $LogPath
    $script:PerformanceAnalyzerConfig.LogLevel = $LogLevel
    $script:PerformanceAnalyzerConfig.PythonPath = $PythonPath
    $script:PerformanceAnalyzerConfig.PredictiveModelEnabled = $PredictiveModelEnabled
    $script:PerformanceAnalyzerConfig.ModelStoragePath = $ModelStoragePath
    $script:PerformanceAnalyzerConfig.PredictionHorizon = $PredictionHorizon
    $script:PerformanceAnalyzerConfig.AnomalySensitivity = $AnomalySensitivity

    # CrÃ©er les rÃ©pertoires nÃ©cessaires
    $configDir = Split-Path -Path $ConfigPath -Parent
    $logDir = Split-Path -Path $LogPath -Parent
    $modelDir = $ModelStoragePath

    if (-not (Test-Path -Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path -Path $modelDir)) {
        New-Item -Path $modelDir -ItemType Directory -Force | Out-Null
    }

    # VÃ©rifier que Python est disponible si l'analyse prÃ©dictive est activÃ©e
    if ($PredictiveModelEnabled) {
        try {
            $pythonVersion = & $PythonPath --version 2>&1
            Write-Log -Message "Python dÃ©tectÃ©: $pythonVersion" -Level "DEBUG"

            # VÃ©rifier que le module PredictiveModel.py existe
            if (-not (Test-Path -Path $script:PerformanceAnalyzerConfig.PredictiveModelPath)) {
                Write-Log -Message "Module d'analyse prÃ©dictive non trouvÃ©: $($script:PerformanceAnalyzerConfig.PredictiveModelPath)" -Level "WARNING"
                $script:PerformanceAnalyzerConfig.PredictiveModelEnabled = $false
            }
        } catch {
            Write-Log -Message "Python non disponible. L'analyse prÃ©dictive sera dÃ©sactivÃ©e." -Level "WARNING"
            $script:PerformanceAnalyzerConfig.PredictiveModelEnabled = $false
        }
    }

    # Journaliser l'initialisation
    Write-Log -Message "PerformanceAnalyzer initialisÃ© avec succÃ¨s." -Level "INFO"
    Write-Log -Message "Configuration: $($script:PerformanceAnalyzerConfig | ConvertTo-Json -Compress)" -Level "DEBUG"

    return $script:PerformanceAnalyzerConfig
}

function Write-Log {
    <#
    .SYNOPSIS
        Ã‰crit un message dans le fichier de log.
    .DESCRIPTION
        Ã‰crit un message dans le fichier de log avec le niveau spÃ©cifiÃ©.
    .PARAMETER Message
        Message Ã  journaliser.
    .PARAMETER Level
        Niveau de log (DEBUG, INFO, WARNING, ERROR).
    .EXAMPLE
        Write-Log -Message "OpÃ©ration rÃ©ussie" -Level "INFO"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    # VÃ©rifier si le niveau de log est suffisant
    $logLevels = @{
        "DEBUG"   = 0
        "INFO"    = 1
        "WARNING" = 2
        "ERROR"   = 3
    }

    if ($logLevels[$Level] -lt $logLevels[$script:PerformanceAnalyzerConfig.LogLevel]) {
        return
    }

    # Formater le message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Ã‰crire dans le fichier de log
    try {
        Add-Content -Path $script:PerformanceAnalyzerConfig.LogPath -Value $logMessage -ErrorAction Stop
    } catch {
        Write-Warning "Impossible d'Ã©crire dans le fichier de log: $_"
    }

    # Afficher dans la console si le niveau est WARNING ou ERROR
    if ($Level -eq "WARNING" -or $Level -eq "ERROR") {
        Write-Host $logMessage -ForegroundColor $(if ($Level -eq "WARNING") { "Yellow" } else { "Red" })
    }
}

function Start-PerformanceAnalysis {
    <#
    .SYNOPSIS
        DÃ©marre l'analyse des performances.
    .DESCRIPTION
        Collecte et analyse les mÃ©triques de performance du systÃ¨me.
    .PARAMETER Duration
        DurÃ©e de l'analyse en secondes.
    .PARAMETER CollectionInterval
        Intervalle de collecte des mÃ©triques en secondes.
    .PARAMETER OutputPath
        Chemin de sortie pour les rÃ©sultats de l'analyse.
    .EXAMPLE
        Start-PerformanceAnalysis -Duration 60 -CollectionInterval 5 -OutputPath "C:\Results"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Duration = 60,

        [Parameter(Mandatory = $false)]
        [int]$CollectionInterval = 5,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$env:TEMP\PerformanceAnalyzer\results"
    )

    # VÃ©rifier si l'analyseur est activÃ©
    if (-not $script:PerformanceAnalyzerConfig.Enabled) {
        Write-Warning "L'analyseur de performances est dÃ©sactivÃ©. Utilisez Initialize-PerformanceAnalyzer -Enabled `$true pour l'activer."
        return
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    Write-Log -Message "DÃ©marrage de l'analyse des performances..." -Level "INFO"
    Write-Log -Message "DurÃ©e: $Duration secondes, Intervalle: $CollectionInterval secondes" -Level "DEBUG"

    # Collecter les mÃ©triques
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($Duration)
    $metrics = @()

    while ((Get-Date) -lt $endTime) {
        $currentMetrics = @{
            Timestamp = Get-Date
            CPU       = Get-CPUMetrics
            Memory    = Get-MemoryMetrics
            Disk      = Get-DiskMetrics
            Network   = Get-NetworkMetrics
        }

        $metrics += $currentMetrics
        Write-Log -Message "MÃ©triques collectÃ©es Ã  $($currentMetrics.Timestamp)" -Level "DEBUG"

        # Attendre l'intervalle de collecte
        Start-Sleep -Seconds $CollectionInterval
    }

    Write-Log -Message "Collecte des mÃ©triques terminÃ©e. $($metrics.Count) Ã©chantillons collectÃ©s." -Level "INFO"

    # Analyser les mÃ©triques
    $analysisResult = Measure-Metrics -Metrics $metrics

    # Sauvegarder les rÃ©sultats
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $resultsFile = Join-Path -Path $OutputPath -ChildPath "performance_analysis_$timestamp.json"

    $results = @{
        StartTime          = $startTime
        EndTime            = Get-Date
        Duration           = $Duration
        CollectionInterval = $CollectionInterval
        SampleCount        = $metrics.Count
        Metrics            = $metrics
        Analysis           = $analysisResult
    }

    $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding utf8

    Write-Log -Message "Analyse des performances terminÃ©e. RÃ©sultats sauvegardÃ©s dans $resultsFile" -Level "INFO"

    return $results
}

function Measure-CPUMetrics {
    <#
    .SYNOPSIS
        Analyse les mÃ©triques CPU.
    .DESCRIPTION
        Analyse les mÃ©triques CPU pour identifier les tendances, les anomalies et les problÃ¨mes de performance.
    .PARAMETER CPUMetrics
        MÃ©triques CPU Ã  analyser.
    .EXAMPLE
        Measure-CPUMetrics -CPUMetrics $metrics.CPU
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$CPUMetrics
    )

    Write-Log -Message "Analyse des mÃ©triques CPU..." -Level "INFO"

    # Calculer les statistiques de base
    $usageStats = $CPUMetrics | ForEach-Object { $_.Usage } | Measure-Object -Average -Maximum -Minimum
    $userTimeStats = $CPUMetrics | ForEach-Object { $_.UserTime } | Measure-Object -Average -Maximum -Minimum
    $systemTimeStats = $CPUMetrics | ForEach-Object { $_.SystemTime } | Measure-Object -Average -Maximum -Minimum
    $interruptTimeStats = $CPUMetrics | ForEach-Object { $_.InterruptTime } | Measure-Object -Average -Maximum -Minimum
    $queueLengthStats = $CPUMetrics | ForEach-Object { $_.QueueLength } | Measure-Object -Average -Maximum -Minimum

    # Calculer les tendances
    $usageTrend = Get-MetricTrend -Values ($CPUMetrics | ForEach-Object { $_.Usage })
    $queueLengthTrend = Get-MetricTrend -Values ($CPUMetrics | ForEach-Object { $_.QueueLength })

    # Identifier les processus les plus consommateurs
    $topProcesses = @{}
    foreach ($metric in $CPUMetrics) {
        foreach ($process in $metric.TopProcesses) {
            if (-not $topProcesses.ContainsKey($process.Name)) {
                $topProcesses[$process.Name] = @{
                    Count    = 0
                    TotalCPU = 0
                    MaxCPU   = 0
                }
            }

            $topProcesses[$process.Name].Count++
            $topProcesses[$process.Name].TotalCPU += $process.CPU
            if ($process.CPU -gt $topProcesses[$process.Name].MaxCPU) {
                $topProcesses[$process.Name].MaxCPU = $process.CPU
            }
        }
    }

    # Calculer la moyenne pour chaque processus et trier
    $topProcessesList = $topProcesses.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name       = $_.Key
            AverageCPU = [math]::Round($_.Value.TotalCPU / $_.Value.Count, 2)
            MaxCPU     = [math]::Round($_.Value.MaxCPU, 2)
            Frequency  = [math]::Round(($_.Value.Count / $CPUMetrics.Count) * 100, 2)
        }
    } | Sort-Object -Property AverageCPU -Descending | Select-Object -First 5

    # Analyser les anomalies
    $anomalies = @()
    $highCpuThreshold = 80
    $highQueueLengthThreshold = 5
    $highInterruptTimeThreshold = 10

    # DÃ©tecter les pics d'utilisation CPU
    $cpuSpikes = $CPUMetrics | Where-Object { $_.Usage -gt $highCpuThreshold }
    if ($cpuSpikes.Count -gt 0) {
        $anomalies += "Pics d'utilisation CPU dÃ©tectÃ©s: $($cpuSpikes.Count) occurrences au-dessus de $highCpuThreshold%"
    }

    # DÃ©tecter les files d'attente longues
    $longQueues = $CPUMetrics | Where-Object { $_.QueueLength -gt $highQueueLengthThreshold }
    if ($longQueues.Count -gt 0) {
        $anomalies += "Files d'attente CPU longues dÃ©tectÃ©es: $($longQueues.Count) occurrences au-dessus de $highQueueLengthThreshold"
    }

    # DÃ©tecter les temps d'interruption Ã©levÃ©s
    $highInterrupts = $CPUMetrics | Where-Object { $_.InterruptTime -gt $highInterruptTimeThreshold }
    if ($highInterrupts.Count -gt 0) {
        $anomalies += "Temps d'interruption Ã©levÃ©s dÃ©tectÃ©s: $($highInterrupts.Count) occurrences au-dessus de $highInterruptTimeThreshold%"
    }

    # Analyser l'Ã©quilibre entre temps utilisateur et systÃ¨me
    $userSystemRatio = [math]::Round($userTimeStats.Average / ($systemTimeStats.Average + 0.001), 2)
    if ($userSystemRatio -lt 1) {
        $anomalies += "Ratio temps utilisateur/systÃ¨me faible ($userSystemRatio): possible problÃ¨me de pilote ou de systÃ¨me"
    }

    # Analyser les processus problÃ©matiques
    $problematicProcesses = $topProcessesList | Where-Object { $_.MaxCPU -gt $highCpuThreshold -and $_.Frequency -gt 50 }
    foreach ($process in $problematicProcesses) {
        $anomalies += "Processus problÃ©matique dÃ©tectÃ©: $($process.Name) (CPU max: $($process.MaxCPU)%, frÃ©quence: $($process.Frequency)%)"
    }

    # Construire l'objet d'analyse
    $analysis = @{
        Usage                = @{
            Average          = [math]::Round($usageStats.Average, 2)
            Maximum          = [math]::Round($usageStats.Maximum, 2)
            Minimum          = [math]::Round($usageStats.Minimum, 2)
            Trend            = $usageTrend
            Threshold        = $highCpuThreshold
            ExceedsThreshold = $usageStats.Maximum -gt $highCpuThreshold
        }
        UserTime             = @{
            Average = [math]::Round($userTimeStats.Average, 2)
            Maximum = [math]::Round($userTimeStats.Maximum, 2)
            Minimum = [math]::Round($userTimeStats.Minimum, 2)
        }
        SystemTime           = @{
            Average = [math]::Round($systemTimeStats.Average, 2)
            Maximum = [math]::Round($systemTimeStats.Maximum, 2)
            Minimum = [math]::Round($systemTimeStats.Minimum, 2)
        }
        InterruptTime        = @{
            Average          = [math]::Round($interruptTimeStats.Average, 2)
            Maximum          = [math]::Round($interruptTimeStats.Maximum, 2)
            Minimum          = [math]::Round($interruptTimeStats.Minimum, 2)
            Threshold        = $highInterruptTimeThreshold
            ExceedsThreshold = $interruptTimeStats.Maximum -gt $highInterruptTimeThreshold
        }
        QueueLength          = @{
            Average          = [math]::Round($queueLengthStats.Average, 2)
            Maximum          = [math]::Round($queueLengthStats.Maximum, 2)
            Minimum          = [math]::Round($queueLengthStats.Minimum, 2)
            Trend            = $queueLengthTrend
            Threshold        = $highQueueLengthThreshold
            ExceedsThreshold = $queueLengthStats.Maximum -gt $highQueueLengthThreshold
        }
        UserSystemRatio      = $userSystemRatio
        TopProcesses         = $topProcessesList
        ProblematicProcesses = $problematicProcesses
        Anomalies            = $anomalies
    }

    # GÃ©nÃ©rer des recommandations
    $recommendations = @()

    if ($analysis.Usage.ExceedsThreshold) {
        $recommendations += "Optimiser l'utilisation CPU en identifiant et en ajustant les processus consommateurs"
    }

    if ($analysis.QueueLength.ExceedsThreshold) {
        $recommendations += "RÃ©duire la charge de travail ou augmenter les ressources CPU pour diminuer les files d'attente"
    }

    if ($analysis.InterruptTime.ExceedsThreshold) {
        $recommendations += "VÃ©rifier les pilotes et pÃ©riphÃ©riques qui gÃ©nÃ¨rent un nombre Ã©levÃ© d'interruptions"
    }

    if ($userSystemRatio -lt 1) {
        $recommendations += "Investiguer les processus systÃ¨me et les pilotes qui consomment trop de temps CPU"
    }

    if ($problematicProcesses.Count -gt 0) {
        $recommendations += "Optimiser ou remplacer les processus problÃ©matiques: $($problematicProcesses.Name -join ', ')"
    }

    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des mÃ©triques CPU terminÃ©e. $($anomalies.Count) anomalies identifiÃ©es." -Level "INFO"

    return $analysis
}

function Get-MetricTrend {
    <#
    .SYNOPSIS
        Calcule la tendance d'une sÃ©rie de valeurs.
    .DESCRIPTION
        Calcule la tendance (croissante, dÃ©croissante ou stable) d'une sÃ©rie de valeurs.
    .PARAMETER Values
        SÃ©rie de valeurs Ã  analyser.
    .EXAMPLE
        Get-MetricTrend -Values $cpuValues
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Values
    )

    if ($Values.Count -lt 2) {
        return "Stable"
    }

    # Calculer la pente de la tendance linÃ©aire
    $n = $Values.Count
    $sumX = 0
    $sumY = 0
    $sumXY = 0
    $sumXX = 0

    for ($i = 0; $i -lt $n; $i++) {
        $sumX += $i
        $sumY += $Values[$i]
        $sumXY += $i * $Values[$i]
        $sumXX += $i * $i
    }

    $slope = 0
    $denominator = $n * $sumXX - $sumX * $sumX

    if ($denominator -ne 0) {
        $slope = ($n * $sumXY - $sumX * $sumY) / $denominator
    }

    # DÃ©terminer la tendance
    $threshold = 0.1

    if ($slope -gt $threshold) {
        return "Croissante"
    } elseif ($slope -lt - $threshold) {
        return "DÃ©croissante"
    } else {
        return "Stable"
    }
}

function Measure-MemoryMetrics {
    <#
    .SYNOPSIS
        Analyse les mÃ©triques mÃ©moire.
    .DESCRIPTION
        Analyse les mÃ©triques mÃ©moire pour identifier les tendances, les anomalies et les problÃ¨mes de performance.
    .PARAMETER MemoryMetrics
        MÃ©triques mÃ©moire Ã  analyser.
    .EXAMPLE
        Measure-MemoryMetrics -MemoryMetrics $metrics.Memory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$MemoryMetrics
    )

    Write-Log -Message "Analyse des mÃ©triques mÃ©moire..." -Level "INFO"

    # Calculer les statistiques de base
    $usageStats = $MemoryMetrics | ForEach-Object { $_.Usage } | Measure-Object -Average -Maximum -Minimum
    $availableMBStats = $MemoryMetrics | ForEach-Object { $_.Available.MB } | Measure-Object -Average -Maximum -Minimum
    $pageFaultsStats = $MemoryMetrics | ForEach-Object { $_.Performance.PageFaultsPersec } | Measure-Object -Average -Maximum -Minimum
    $pagesInputStats = $MemoryMetrics | ForEach-Object { $_.Performance.PagesInputPersec } | Measure-Object -Average -Maximum -Minimum
    $commitPercentStats = $MemoryMetrics | ForEach-Object { $_.Performance.CommitPercent } | Measure-Object -Average -Maximum -Minimum

    # Calculer les tendances
    $usageTrend = Get-MetricTrend -Values ($MemoryMetrics | ForEach-Object { $_.Usage })
    $availableTrend = Get-MetricTrend -Values ($MemoryMetrics | ForEach-Object { $_.Available.MB })
    $pageFaultsTrend = Get-MetricTrend -Values ($MemoryMetrics | ForEach-Object { $_.Performance.PageFaultsPersec })

    # Identifier les processus les plus consommateurs
    $topProcesses = @{}
    foreach ($metric in $MemoryMetrics) {
        foreach ($process in $metric.TopProcesses) {
            if (-not $topProcesses.ContainsKey($process.Name)) {
                $topProcesses[$process.Name] = @{
                    Count       = 0
                    TotalMemory = 0
                    MaxMemory   = 0
                }
            }

            $topProcesses[$process.Name].Count++
            $topProcesses[$process.Name].TotalMemory += $process.WorkingSet
            if ($process.WorkingSet -gt $topProcesses[$process.Name].MaxMemory) {
                $topProcesses[$process.Name].MaxMemory = $process.WorkingSet
            }
        }
    }

    # Calculer la moyenne pour chaque processus et trier
    $topProcessesList = $topProcesses.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name            = $_.Key
            AverageMemoryMB = [math]::Round($_.Value.TotalMemory / $_.Value.Count, 2)
            MaxMemoryMB     = [math]::Round($_.Value.MaxMemory, 2)
            Frequency       = [math]::Round(($_.Value.Count / $MemoryMetrics.Count) * 100, 2)
        }
    } | Sort-Object -Property AverageMemoryMB -Descending | Select-Object -First 5

    # Analyser les fuites mÃ©moire potentielles
    $leakSuspects = @()
    foreach ($metric in $MemoryMetrics) {
        if ($metric.LeakDetection.LeakDetected) {
            foreach ($suspect in $metric.LeakDetection.LeakSuspects) {
                if (-not ($leakSuspects | Where-Object { $_.Name -eq $suspect.Name })) {
                    $leakSuspects += $suspect
                }
            }
        }
    }

    # Analyser les anomalies
    $anomalies = @()
    $highMemoryThreshold = 85
    $highPageFaultsThreshold = 1000
    $highCommitPercentThreshold = 90
    $lowAvailableMemoryThreshold = 500  # MB

    # DÃ©tecter les pics d'utilisation mÃ©moire
    $memorySpikes = $MemoryMetrics | Where-Object { $_.Usage -gt $highMemoryThreshold }
    if ($memorySpikes.Count -gt 0) {
        $anomalies += "Pics d'utilisation mÃ©moire dÃ©tectÃ©s: $($memorySpikes.Count) occurrences au-dessus de $highMemoryThreshold%"
    }

    # DÃ©tecter les pics de dÃ©fauts de page
    $pageFaultsSpikes = $MemoryMetrics | Where-Object { $_.Performance.PageFaultsPersec -gt $highPageFaultsThreshold }
    if ($pageFaultsSpikes.Count -gt 0) {
        $anomalies += "Pics de dÃ©fauts de page dÃ©tectÃ©s: $($pageFaultsSpikes.Count) occurrences au-dessus de $highPageFaultsThreshold/sec"
    }

    # DÃ©tecter les niveaux de mÃ©moire disponible faibles
    $lowMemoryEvents = $MemoryMetrics | Where-Object { $_.Available.MB -lt $lowAvailableMemoryThreshold }
    if ($lowMemoryEvents.Count -gt 0) {
        $anomalies += "Niveaux de mÃ©moire disponible faibles dÃ©tectÃ©s: $($lowMemoryEvents.Count) occurrences en dessous de $lowAvailableMemoryThreshold MB"
    }

    # DÃ©tecter les taux d'engagement Ã©levÃ©s
    $highCommitEvents = $MemoryMetrics | Where-Object { $_.Performance.CommitPercent -gt $highCommitPercentThreshold }
    if ($highCommitEvents.Count -gt 0) {
        $anomalies += "Taux d'engagement mÃ©moire Ã©levÃ©s dÃ©tectÃ©s: $($highCommitEvents.Count) occurrences au-dessus de $highCommitPercentThreshold%"
    }

    # Analyser les fuites mÃ©moire
    if ($leakSuspects.Count -gt 0) {
        $anomalies += "Fuites mÃ©moire potentielles dÃ©tectÃ©es dans les processus: $($leakSuspects.Name -join ', ')"
    }

    # Analyser les processus problÃ©matiques
    $problematicProcesses = $topProcessesList | Where-Object { $_.MaxMemoryMB -gt 1000 -and $_.Frequency -gt 50 }
    foreach ($process in $problematicProcesses) {
        $anomalies += "Processus Ã  haute consommation mÃ©moire dÃ©tectÃ©: $($process.Name) (MÃ©moire max: $($process.MaxMemoryMB) MB, frÃ©quence: $($process.Frequency)%)"
    }

    # Construire l'objet d'analyse
    $analysis = @{
        Usage                = @{
            Average          = [math]::Round($usageStats.Average, 2)
            Maximum          = [math]::Round($usageStats.Maximum, 2)
            Minimum          = [math]::Round($usageStats.Minimum, 2)
            Trend            = $usageTrend
            Threshold        = $highMemoryThreshold
            ExceedsThreshold = $usageStats.Maximum -gt $highMemoryThreshold
        }
        Available            = @{
            AverageMB      = [math]::Round($availableMBStats.Average, 2)
            MaximumMB      = [math]::Round($availableMBStats.Maximum, 2)
            MinimumMB      = [math]::Round($availableMBStats.Minimum, 2)
            Trend          = $availableTrend
            Threshold      = $lowAvailableMemoryThreshold
            BelowThreshold = $availableMBStats.Minimum -lt $lowAvailableMemoryThreshold
        }
        PageFaults           = @{
            Average          = [math]::Round($pageFaultsStats.Average, 2)
            Maximum          = [math]::Round($pageFaultsStats.Maximum, 2)
            Minimum          = [math]::Round($pageFaultsStats.Minimum, 2)
            Trend            = $pageFaultsTrend
            Threshold        = $highPageFaultsThreshold
            ExceedsThreshold = $pageFaultsStats.Maximum -gt $highPageFaultsThreshold
        }
        PagesInput           = @{
            Average = [math]::Round($pagesInputStats.Average, 2)
            Maximum = [math]::Round($pagesInputStats.Maximum, 2)
            Minimum = [math]::Round($pagesInputStats.Minimum, 2)
        }
        CommitPercent        = @{
            Average          = [math]::Round($commitPercentStats.Average, 2)
            Maximum          = [math]::Round($commitPercentStats.Maximum, 2)
            Minimum          = [math]::Round($commitPercentStats.Minimum, 2)
            Threshold        = $highCommitPercentThreshold
            ExceedsThreshold = $commitPercentStats.Maximum -gt $highCommitPercentThreshold
        }
        TopProcesses         = $topProcessesList
        LeakSuspects         = $leakSuspects
        ProblematicProcesses = $problematicProcesses
        Anomalies            = $anomalies
    }

    # GÃ©nÃ©rer des recommandations
    $recommendations = @()

    if ($analysis.Usage.ExceedsThreshold) {
        $recommendations += "RÃ©duire la consommation mÃ©moire en optimisant ou en fermant les applications gourmandes"
    }

    if ($analysis.Available.BelowThreshold) {
        $recommendations += "Augmenter la mÃ©moire physique ou rÃ©duire le nombre d'applications simultanÃ©es"
    }

    if ($analysis.PageFaults.ExceedsThreshold) {
        $recommendations += "Optimiser l'utilisation de la mÃ©moire pour rÃ©duire les dÃ©fauts de page"
    }

    if ($analysis.CommitPercent.ExceedsThreshold) {
        $recommendations += "Augmenter la taille du fichier d'Ã©change ou rÃ©duire la charge mÃ©moire"
    }

    if ($leakSuspects.Count -gt 0) {
        $recommendations += "Investiguer et corriger les fuites mÃ©moire dans les processus: $($leakSuspects.Name -join ', ')"
    }

    if ($problematicProcesses.Count -gt 0) {
        $recommendations += "Optimiser ou remplacer les processus Ã  haute consommation mÃ©moire: $($problematicProcesses.Name -join ', ')"
    }

    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des mÃ©triques mÃ©moire terminÃ©e. $($anomalies.Count) anomalies identifiÃ©es." -Level "INFO"

    return $analysis
}

function Measure-DiskMetrics {
    <#
    .SYNOPSIS
        Analyse les mÃ©triques disque.
    .DESCRIPTION
        Analyse les mÃ©triques disque pour identifier les tendances, les anomalies et les problÃ¨mes de performance.
    .PARAMETER DiskMetrics
        MÃ©triques disque Ã  analyser.
    .EXAMPLE
        Measure-DiskMetrics -DiskMetrics $metrics.Disk
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$DiskMetrics
    )

    Write-Log -Message "Analyse des mÃ©triques disque..." -Level "INFO"

    # Calculer les statistiques de base
    $usageStats = $DiskMetrics | ForEach-Object { $_.Usage.Average } | Measure-Object -Average -Maximum -Minimum
    $iopsStats = $DiskMetrics | ForEach-Object { $_.Performance.Total.TotalIOPS } | Measure-Object -Average -Maximum -Minimum
    $responseTimeStats = $DiskMetrics | ForEach-Object { $_.Performance.Total.ResponseTimeMS } | Measure-Object -Average -Maximum -Minimum
    $queueLengthStats = $DiskMetrics | ForEach-Object { $_.Performance.Total.QueueLength } | Measure-Object -Average -Maximum -Minimum

    # Calculer les tendances
    $usageTrend = Get-MetricTrend -Values ($DiskMetrics | ForEach-Object { $_.Usage.Average })
    $iopsTrend = Get-MetricTrend -Values ($DiskMetrics | ForEach-Object { $_.Performance.Total.TotalIOPS })
    $responseTimeTrend = Get-MetricTrend -Values ($DiskMetrics | ForEach-Object { $_.Performance.Total.ResponseTimeMS })

    # Analyser les performances par disque logique
    $drivePerformance = @{}
    foreach ($metric in $DiskMetrics) {
        foreach ($drive in $metric.Performance.LogicalDisks) {
            if (-not $drivePerformance.ContainsKey($drive.Drive)) {
                $drivePerformance[$drive.Drive] = @{
                    Count             = 0
                    TotalUsage        = 0
                    TotalReadMB       = 0
                    TotalWriteMB      = 0
                    TotalResponseTime = 0
                    MaxUsage          = 0
                    MaxResponseTime   = 0
                }
            }

            $driveUsage = ($metric.Usage.ByDrive | Where-Object { $_.Drive -eq $drive.Drive }).Usage
            $drivePerformance[$drive.Drive].Count++
            $drivePerformance[$drive.Drive].TotalUsage += $driveUsage
            $drivePerformance[$drive.Drive].TotalReadMB += $drive.DiskReadBytesPersec
            $drivePerformance[$drive.Drive].TotalWriteMB += $drive.DiskWriteBytesPersec
            $drivePerformance[$drive.Drive].TotalResponseTime += $drive.AvgDiskSecPerTransfer

            if ($driveUsage -gt $drivePerformance[$drive.Drive].MaxUsage) {
                $drivePerformance[$drive.Drive].MaxUsage = $driveUsage
            }

            if ($drive.AvgDiskSecPerTransfer -gt $drivePerformance[$drive.Drive].MaxResponseTime) {
                $drivePerformance[$drive.Drive].MaxResponseTime = $drive.AvgDiskSecPerTransfer
            }
        }
    }

    # Calculer les moyennes par disque et trier
    $drivePerformanceList = $drivePerformance.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Drive                 = $_.Key
            AverageUsage          = [math]::Round($_.Value.TotalUsage / $_.Value.Count, 2)
            MaxUsage              = [math]::Round($_.Value.MaxUsage, 2)
            AverageReadMBPerSec   = [math]::Round($_.Value.TotalReadMB / $_.Value.Count, 2)
            AverageWriteMBPerSec  = [math]::Round($_.Value.TotalWriteMB / $_.Value.Count, 2)
            AverageResponseTimeMS = [math]::Round($_.Value.TotalResponseTime / $_.Value.Count, 2)
            MaxResponseTimeMS     = [math]::Round($_.Value.MaxResponseTime, 2)
        }
    } | Sort-Object -Property AverageUsage -Descending

    # Analyser les processus les plus actifs
    $topProcesses = @{}
    foreach ($metric in $DiskMetrics) {
        foreach ($process in $metric.TopProcesses) {
            if (-not $topProcesses.ContainsKey($process.Name)) {
                $topProcesses[$process.Name] = @{
                    Count     = 0
                    TotalIOPS = 0
                    MaxIOPS   = 0
                }
            }

            $topProcesses[$process.Name].Count++
            $topProcesses[$process.Name].TotalIOPS += $process.IOPS
            if ($process.IOPS -gt $topProcesses[$process.Name].MaxIOPS) {
                $topProcesses[$process.Name].MaxIOPS = $process.IOPS
            }
        }
    }

    # Calculer la moyenne pour chaque processus et trier
    $topProcessesList = $topProcesses.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name        = $_.Key
            AverageIOPS = [math]::Round($_.Value.TotalIOPS / $_.Value.Count, 2)
            MaxIOPS     = [math]::Round($_.Value.MaxIOPS, 2)
            Frequency   = [math]::Round(($_.Value.Count / $DiskMetrics.Count) * 100, 2)
        }
    } | Sort-Object -Property AverageIOPS -Descending | Select-Object -First 5

    # Analyser les anomalies
    $anomalies = @()
    $highDiskUsageThreshold = 90
    $highIOPSThreshold = 1000
    $highResponseTimeThreshold = 20  # ms
    $highQueueLengthThreshold = 2

    # DÃ©tecter les pics d'utilisation disque
    $diskSpikes = $DiskMetrics | Where-Object { $_.Usage.Average -gt $highDiskUsageThreshold }
    if ($diskSpikes.Count -gt 0) {
        $anomalies += "Pics d'utilisation disque dÃ©tectÃ©s: $($diskSpikes.Count) occurrences au-dessus de $highDiskUsageThreshold%"
    }

    # DÃ©tecter les pics d'IOPS
    $iopsSpikes = $DiskMetrics | Where-Object { $_.Performance.Total.TotalIOPS -gt $highIOPSThreshold }
    if ($iopsSpikes.Count -gt 0) {
        $anomalies += "Pics d'IOPS dÃ©tectÃ©s: $($iopsSpikes.Count) occurrences au-dessus de $highIOPSThreshold IOPS"
    }

    # DÃ©tecter les temps de rÃ©ponse Ã©levÃ©s
    $responseTimeSpikes = $DiskMetrics | Where-Object { $_.Performance.Total.ResponseTimeMS -gt $highResponseTimeThreshold }
    if ($responseTimeSpikes.Count -gt 0) {
        $anomalies += "Temps de rÃ©ponse disque Ã©levÃ©s dÃ©tectÃ©s: $($responseTimeSpikes.Count) occurrences au-dessus de $highResponseTimeThreshold ms"
    }

    # DÃ©tecter les files d'attente longues
    $queueLengthSpikes = $DiskMetrics | Where-Object { $_.Performance.Total.QueueLength -gt $highQueueLengthThreshold }
    if ($queueLengthSpikes.Count -gt 0) {
        $anomalies += "Files d'attente disque longues dÃ©tectÃ©es: $($queueLengthSpikes.Count) occurrences au-dessus de $highQueueLengthThreshold"
    }

    # Analyser la fragmentation
    $highFragmentationThreshold = 15  # %
    $fragmentationIssues = $DiskMetrics | Where-Object {
        $_.Fragmentation | Where-Object { $_.FragmentationPercent -gt $highFragmentationThreshold }
    }
    if ($fragmentationIssues.Count -gt 0) {
        $anomalies += "Fragmentation Ã©levÃ©e dÃ©tectÃ©e sur certains volumes"
    }

    # Analyser les disques problÃ©matiques
    $problematicDrives = $drivePerformanceList | Where-Object {
        $_.MaxUsage -gt $highDiskUsageThreshold -or
        $_.MaxResponseTimeMS -gt $highResponseTimeThreshold
    }
    foreach ($drive in $problematicDrives) {
        $anomalies += "Disque problÃ©matique dÃ©tectÃ©: $($drive.Drive) (Usage max: $($drive.MaxUsage)%, Temps de rÃ©ponse max: $($drive.MaxResponseTimeMS) ms)"
    }

    # Analyser la santÃ© des disques physiques
    $diskHealthIssues = @()
    foreach ($metric in $DiskMetrics) {
        foreach ($disk in $metric.PhysicalDisks) {
            if ($disk.Health.Status -ne "OK" -and $disk.Health.Status -ne "Healthy") {
                $diskHealthIssues += "$($disk.Model) ($($disk.Index)): $($disk.Health.Status)"
            }
        }
    }

    if ($diskHealthIssues.Count -gt 0) {
        $anomalies += "ProblÃ¨mes de santÃ© dÃ©tectÃ©s sur les disques physiques: $($diskHealthIssues -join ', ')"
    }

    # Construire l'objet d'analyse
    $analysis = @{
        Usage             = @{
            Average          = [math]::Round($usageStats.Average, 2)
            Maximum          = [math]::Round($usageStats.Maximum, 2)
            Minimum          = [math]::Round($usageStats.Minimum, 2)
            Trend            = $usageTrend
            Threshold        = $highDiskUsageThreshold
            ExceedsThreshold = $usageStats.Maximum -gt $highDiskUsageThreshold
        }
        IOPS              = @{
            Average          = [math]::Round($iopsStats.Average, 2)
            Maximum          = [math]::Round($iopsStats.Maximum, 2)
            Minimum          = [math]::Round($iopsStats.Minimum, 2)
            Trend            = $iopsTrend
            Threshold        = $highIOPSThreshold
            ExceedsThreshold = $iopsStats.Maximum -gt $highIOPSThreshold
        }
        ResponseTime      = @{
            AverageMS        = [math]::Round($responseTimeStats.Average, 2)
            MaximumMS        = [math]::Round($responseTimeStats.Maximum, 2)
            MinimumMS        = [math]::Round($responseTimeStats.Minimum, 2)
            Trend            = $responseTimeTrend
            Threshold        = $highResponseTimeThreshold
            ExceedsThreshold = $responseTimeStats.Maximum -gt $highResponseTimeThreshold
        }
        QueueLength       = @{
            Average          = [math]::Round($queueLengthStats.Average, 2)
            Maximum          = [math]::Round($queueLengthStats.Maximum, 2)
            Minimum          = [math]::Round($queueLengthStats.Minimum, 2)
            Threshold        = $highQueueLengthThreshold
            ExceedsThreshold = $queueLengthStats.Maximum -gt $highQueueLengthThreshold
        }
        DrivePerformance  = $drivePerformanceList
        ProblematicDrives = $problematicDrives
        TopProcesses      = $topProcessesList
        DiskHealthIssues  = $diskHealthIssues
        Anomalies         = $anomalies
    }

    # GÃ©nÃ©rer des recommandations
    $recommendations = @()

    if ($analysis.Usage.ExceedsThreshold) {
        $recommendations += "LibÃ©rer de l'espace disque ou ajouter de la capacitÃ© de stockage"
    }

    if ($analysis.IOPS.ExceedsThreshold) {
        $recommendations += "RÃ©duire les opÃ©rations d'E/S intensives ou utiliser des disques plus performants"
    }

    if ($analysis.ResponseTime.ExceedsThreshold) {
        $recommendations += "AmÃ©liorer les performances disque en utilisant des SSD ou en optimisant les opÃ©rations d'E/S"
    }

    if ($analysis.QueueLength.ExceedsThreshold) {
        $recommendations += "RÃ©duire la charge disque ou amÃ©liorer les performances du sous-systÃ¨me de stockage"
    }

    if ($fragmentationIssues.Count -gt 0) {
        $recommendations += "DÃ©fragmenter les volumes avec une fragmentation Ã©levÃ©e"
    }

    if ($problematicDrives.Count -gt 0) {
        $recommendations += "Optimiser l'utilisation des disques problÃ©matiques: $($problematicDrives.Drive -join ', ')"
    }

    if ($diskHealthIssues.Count -gt 0) {
        $recommendations += "VÃ©rifier et remplacer les disques physiques dÃ©fectueux"
    }

    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des mÃ©triques disque terminÃ©e. $($anomalies.Count) anomalies identifiÃ©es." -Level "INFO"

    return $analysis
}

function Measure-NetworkMetrics {
    <#
    .SYNOPSIS
        Analyse les mÃ©triques rÃ©seau.
    .DESCRIPTION
        Analyse les mÃ©triques rÃ©seau pour identifier les tendances, les anomalies et les problÃ¨mes de performance.
    .PARAMETER NetworkMetrics
        MÃ©triques rÃ©seau Ã  analyser.
    .EXAMPLE
        Measure-NetworkMetrics -NetworkMetrics $metrics.Network
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$NetworkMetrics
    )

    Write-Log -Message "Analyse des mÃ©triques rÃ©seau..." -Level "INFO"

    # Calculer les statistiques de base
    $bandwidthUsageStats = $NetworkMetrics | ForEach-Object { $_.BandwidthUsage } | Measure-Object -Average -Maximum -Minimum
    $throughputInStats = $NetworkMetrics | ForEach-Object { $_.Throughput.InMbps } | Measure-Object -Average -Maximum -Minimum
    $throughputOutStats = $NetworkMetrics | ForEach-Object { $_.Throughput.OutMbps } | Measure-Object -Average -Maximum -Minimum
    $latencyStats = $NetworkMetrics | ForEach-Object { $_.Latency } | Measure-Object -Average -Maximum -Minimum
    $errorRateStats = $NetworkMetrics | ForEach-Object { $_.Performance.ErrorRate } | Measure-Object -Average -Maximum -Minimum

    # Calculer les tendances
    $bandwidthTrend = Get-MetricTrend -Values ($NetworkMetrics | ForEach-Object { $_.BandwidthUsage })
    $latencyTrend = Get-MetricTrend -Values ($NetworkMetrics | ForEach-Object { $_.Latency })
    $errorRateTrend = Get-MetricTrend -Values ($NetworkMetrics | ForEach-Object { $_.Performance.ErrorRate })

    # Analyser les connexions TCP
    $tcpConnectionStats = @{}
    foreach ($metric in $NetworkMetrics) {
        foreach ($state in $metric.Connections.TCP.ByState) {
            if (-not $tcpConnectionStats.ContainsKey($state.State)) {
                $tcpConnectionStats[$state.State] = @{
                    Count = 0
                    Total = 0
                    Max   = 0
                }
            }

            $tcpConnectionStats[$state.State].Count++
            $tcpConnectionStats[$state.State].Total += $state.Count
            if ($state.Count -gt $tcpConnectionStats[$state.State].Max) {
                $tcpConnectionStats[$state.State].Max = $state.Count
            }
        }
    }

    # Calculer la moyenne pour chaque Ã©tat de connexion et trier
    $tcpConnectionList = $tcpConnectionStats.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            State   = $_.Key
            Average = [math]::Round($_.Value.Total / $_.Value.Count, 2)
            Maximum = $_.Value.Max
        }
    } | Sort-Object -Property Average -Descending

    # Analyser les processus avec le plus de connexions
    $topProcesses = @{}
    foreach ($metric in $NetworkMetrics) {
        foreach ($process in $metric.Connections.TCP.ByProcess) {
            if (-not $topProcesses.ContainsKey($process.Process)) {
                $topProcesses[$process.Process] = @{
                    Count            = 0
                    TotalConnections = 0
                    MaxConnections   = 0
                }
            }

            $topProcesses[$process.Process].Count++
            $topProcesses[$process.Process].TotalConnections += $process.Count
            if ($process.Count -gt $topProcesses[$process.Process].MaxConnections) {
                $topProcesses[$process.Process].MaxConnections = $process.Count
            }
        }
    }

    # Calculer la moyenne pour chaque processus et trier
    $topProcessesList = $topProcesses.GetEnumerator() | ForEach-Object {
        [PSCustomObject]@{
            Name               = $_.Key
            AverageConnections = [math]::Round($_.Value.TotalConnections / $_.Value.Count, 2)
            MaxConnections     = $_.Value.MaxConnections
            Frequency          = [math]::Round(($_.Value.Count / $NetworkMetrics.Count) * 100, 2)
        }
    } | Sort-Object -Property AverageConnections -Descending | Select-Object -First 5

    # Analyser les anomalies
    $anomalies = @()
    $highBandwidthThreshold = 80
    $highLatencyThreshold = 100  # ms
    $highErrorRateThreshold = 0.1  # %
    $highTCPConnectionsThreshold = 1000
    $highTCPResetRateThreshold = 5  # %

    # DÃ©tecter les pics d'utilisation de la bande passante
    $bandwidthSpikes = $NetworkMetrics | Where-Object { $_.BandwidthUsage -gt $highBandwidthThreshold }
    if ($bandwidthSpikes.Count -gt 0) {
        $anomalies += "Pics d'utilisation de la bande passante dÃ©tectÃ©s: $($bandwidthSpikes.Count) occurrences au-dessus de $highBandwidthThreshold%"
    }

    # DÃ©tecter les pics de latence
    $latencySpikes = $NetworkMetrics | Where-Object { $_.Latency -gt $highLatencyThreshold }
    if ($latencySpikes.Count -gt 0) {
        $anomalies += "Pics de latence rÃ©seau dÃ©tectÃ©s: $($latencySpikes.Count) occurrences au-dessus de $highLatencyThreshold ms"
    }

    # DÃ©tecter les taux d'erreurs Ã©levÃ©s
    $errorRateSpikes = $NetworkMetrics | Where-Object { $_.Performance.ErrorRate -gt $highErrorRateThreshold }
    if ($errorRateSpikes.Count -gt 0) {
        $anomalies += "Taux d'erreurs rÃ©seau Ã©levÃ©s dÃ©tectÃ©s: $($errorRateSpikes.Count) occurrences au-dessus de $highErrorRateThreshold%"
    }

    # DÃ©tecter les nombres Ã©levÃ©s de connexions TCP
    $highConnectionsEvents = $NetworkMetrics | Where-Object { $_.Connections.TCP.Total -gt $highTCPConnectionsThreshold }
    if ($highConnectionsEvents.Count -gt 0) {
        $anomalies += "Nombre Ã©levÃ© de connexions TCP dÃ©tectÃ©: $($highConnectionsEvents.Count) occurrences au-dessus de $highTCPConnectionsThreshold connexions"
    }

    # DÃ©tecter les taux Ã©levÃ©s de rÃ©initialisation TCP
    $tcpResetRateEvents = $NetworkMetrics | ForEach-Object {
        if ($_.Connections.TCPStats.ConnectionsEstablished -gt 0) {
            $resetRate = ($_.Connections.TCPStats.ConnectionsReset / $_.Connections.TCPStats.ConnectionsEstablished) * 100
            if ($resetRate -gt $highTCPResetRateThreshold) {
                return $_
            }
        }
        return $null
    } | Where-Object { $_ -ne $null }

    if ($tcpResetRateEvents.Count -gt 0) {
        $anomalies += "Taux Ã©levÃ©s de rÃ©initialisation TCP dÃ©tectÃ©s: $($tcpResetRateEvents.Count) occurrences au-dessus de $highTCPResetRateThreshold%"
    }

    # Analyser les anomalies rÃ©seau dÃ©tectÃ©es par le collecteur
    $collectorAnomalies = @()
    foreach ($metric in $NetworkMetrics) {
        foreach ($anomaly in $metric.Anomalies) {
            if (-not $collectorAnomalies.Contains($anomaly)) {
                $collectorAnomalies += $anomaly
            }
        }
    }

    if ($collectorAnomalies.Count -gt 0) {
        $anomalies += $collectorAnomalies
    }

    # Construire l'objet d'analyse
    $analysis = @{
        BandwidthUsage = @{
            Average          = [math]::Round($bandwidthUsageStats.Average, 2)
            Maximum          = [math]::Round($bandwidthUsageStats.Maximum, 2)
            Minimum          = [math]::Round($bandwidthUsageStats.Minimum, 2)
            Trend            = $bandwidthTrend
            Threshold        = $highBandwidthThreshold
            ExceedsThreshold = $bandwidthUsageStats.Maximum -gt $highBandwidthThreshold
        }
        Throughput     = @{
            In    = @{
                AverageMbps = [math]::Round($throughputInStats.Average, 2)
                MaximumMbps = [math]::Round($throughputInStats.Maximum, 2)
                MinimumMbps = [math]::Round($throughputInStats.Minimum, 2)
            }
            Out   = @{
                AverageMbps = [math]::Round($throughputOutStats.Average, 2)
                MaximumMbps = [math]::Round($throughputOutStats.Maximum, 2)
                MinimumMbps = [math]::Round($throughputOutStats.Minimum, 2)
            }
            Total = @{
                AverageMbps = [math]::Round($throughputInStats.Average + $throughputOutStats.Average, 2)
                MaximumMbps = [math]::Round($throughputInStats.Maximum + $throughputOutStats.Maximum, 2)
            }
        }
        Latency        = @{
            AverageMS        = [math]::Round($latencyStats.Average, 2)
            MaximumMS        = [math]::Round($latencyStats.Maximum, 2)
            MinimumMS        = [math]::Round($latencyStats.Minimum, 2)
            Trend            = $latencyTrend
            Threshold        = $highLatencyThreshold
            ExceedsThreshold = $latencyStats.Maximum -gt $highLatencyThreshold
        }
        ErrorRate      = @{
            Average          = [math]::Round($errorRateStats.Average, 4)
            Maximum          = [math]::Round($errorRateStats.Maximum, 4)
            Minimum          = [math]::Round($errorRateStats.Minimum, 4)
            Trend            = $errorRateTrend
            Threshold        = $highErrorRateThreshold
            ExceedsThreshold = $errorRateStats.Maximum -gt $highErrorRateThreshold
        }
        TCPConnections = @{
            ByState = $tcpConnectionList
            Total   = @{
                Average          = [math]::Round(($NetworkMetrics | ForEach-Object { $_.Connections.TCP.Total } | Measure-Object -Average).Average, 2)
                Maximum          = [math]::Round(($NetworkMetrics | ForEach-Object { $_.Connections.TCP.Total } | Measure-Object -Maximum).Maximum, 2)
                Threshold        = $highTCPConnectionsThreshold
                ExceedsThreshold = [math]::Round(($NetworkMetrics | ForEach-Object { $_.Connections.TCP.Total } | Measure-Object -Maximum).Maximum, 2) -gt $highTCPConnectionsThreshold
            }
        }
        TopProcesses   = $topProcessesList
        Anomalies      = $anomalies
    }

    # GÃ©nÃ©rer des recommandations
    $recommendations = @()

    if ($analysis.BandwidthUsage.ExceedsThreshold) {
        $recommendations += "Optimiser l'utilisation de la bande passante ou augmenter la capacitÃ© rÃ©seau"
    }

    if ($analysis.Latency.ExceedsThreshold) {
        $recommendations += "Investiguer les causes de latence rÃ©seau Ã©levÃ©e (routage, congestion, matÃ©riel)"
    }

    if ($analysis.ErrorRate.ExceedsThreshold) {
        $recommendations += "VÃ©rifier les Ã©quipements rÃ©seau et les cÃ¢bles pour rÃ©duire les erreurs de transmission"
    }

    if ($analysis.TCPConnections.Total.ExceedsThreshold) {
        $recommendations += "Optimiser la gestion des connexions TCP dans les applications avec un nombre Ã©levÃ© de connexions"
    }

    if ($tcpResetRateEvents.Count -gt 0) {
        $recommendations += "Investiguer les causes des rÃ©initialisations TCP frÃ©quentes (pare-feu, timeout, problÃ¨mes d'application)"
    }

    if ($collectorAnomalies.Count -gt 0) {
        $recommendations += "RÃ©soudre les anomalies rÃ©seau dÃ©tectÃ©es par le collecteur"
    }

    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des mÃ©triques rÃ©seau terminÃ©e. $($anomalies.Count) anomalies identifiÃ©es." -Level "INFO"

    return $analysis
}

function Measure-Metrics {
    <#
    .SYNOPSIS
        Analyse les mÃ©triques de performance.
    .DESCRIPTION
        Analyse les mÃ©triques de performance pour identifier les tendances et les problÃ¨mes.
    .PARAMETER Metrics
        MÃ©triques Ã  analyser.
    .EXAMPLE
        Measure-Metrics -Metrics $metrics
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics
    )

    Write-Log -Message "Analyse des mÃ©triques..." -Level "INFO"

    # Analyser les mÃ©triques CPU avec la fonction spÃ©cialisÃ©e
    $cpuAnalysis = Measure-CPUMetrics -CPUMetrics ($Metrics | ForEach-Object { $_.CPU })

    # Analyser les mÃ©triques mÃ©moire avec la fonction spÃ©cialisÃ©e
    $memoryAnalysis = Measure-MemoryMetrics -MemoryMetrics ($Metrics | ForEach-Object { $_.Memory })

    # Analyser les mÃ©triques disque avec la fonction spÃ©cialisÃ©e
    $diskAnalysis = Measure-DiskMetrics -DiskMetrics ($Metrics | ForEach-Object { $_.Disk })

    # Analyser les mÃ©triques rÃ©seau avec la fonction spÃ©cialisÃ©e
    $networkAnalysis = Measure-NetworkMetrics -NetworkMetrics ($Metrics | ForEach-Object { $_.Network })

    $analysis = @{
        CPU     = $cpuAnalysis
        Memory  = $memoryAnalysis
        Disk    = $diskAnalysis
        Network = $networkAnalysis
    }

    # Identifier les problÃ¨mes potentiels
    $issues = @()

    # Ajouter les anomalies de tous les analyseurs
    $issues += $cpuAnalysis.Anomalies
    $issues += $memoryAnalysis.Anomalies
    $issues += $diskAnalysis.Anomalies
    $issues += $networkAnalysis.Anomalies

    $analysis.Issues = $issues

    # Combiner les recommandations
    $recommendations = @()
    $recommendations += $cpuAnalysis.Recommendations
    $recommendations += $memoryAnalysis.Recommendations
    $recommendations += $diskAnalysis.Recommendations
    $recommendations += $networkAnalysis.Recommendations
    $analysis.Recommendations = $recommendations

    Write-Log -Message "Analyse des mÃ©triques terminÃ©e. $($issues.Count) problÃ¨mes identifiÃ©s." -Level "INFO"

    return $analysis
}

function Get-PerformanceReport {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re un rapport de performance.
    .DESCRIPTION
        GÃ©nÃ¨re un rapport de performance basÃ© sur les mÃ©triques collectÃ©es.
    .PARAMETER ReportType
        Type de rapport (Summary, Detailed).
    .PARAMETER TimeRange
        Plage de temps pour le rapport (Last1Hour, Last24Hours, Last7Days).
    .PARAMETER Format
        Format du rapport (Text, HTML, JSON).
    .EXAMPLE
        Get-PerformanceReport -ReportType "Detailed" -TimeRange "Last24Hours" -Format "HTML"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Summary", "Detailed")]
        [string]$ReportType = "Summary",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Last1Hour", "Last24Hours", "Last7Days")]
        [string]$TimeRange = "Last1Hour",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "HTML", "JSON")]
        [string]$Format = "Text"
    )

    Write-Log -Message "GÃ©nÃ©ration d'un rapport de performance ($ReportType, $TimeRange, $Format)..." -Level "INFO"

    # Simuler un rapport pour l'instant
    $report = @{
        ReportType  = $ReportType
        TimeRange   = $TimeRange
        GeneratedAt = Get-Date
        CPU         = @{
            Usage        = 45.5
            TopProcesses = @(
                @{Name = "Process1"; CPU = 15.2 },
                @{Name = "Process2"; CPU = 10.5 },
                @{Name = "Process3"; CPU = 8.3 }
            )
        }
        Memory      = @{
            Usage        = 65.3
            Available    = 4096
            TopProcesses = @(
                @{Name = "Process1"; Memory = 1024 },
                @{Name = "Process2"; Memory = 512 },
                @{Name = "Process3"; Memory = 256 }
            )
        }
        Disk        = @{
            Usage        = 75.2
            IOOperations = 250
            ResponseTime = 8.5
        }
        Network     = @{
            BandwidthUsage = 35.8
            Throughput     = @{In = 25.6; Out = 10.2 }
            Latency        = 45.3
        }
    }

    # Formater le rapport
    switch ($Format) {
        "HTML" {
            # Simuler un rapport HTML
            $html = "<html><head><title>Rapport de performance</title></head><body>"
            $html += "<h1>Rapport de performance</h1>"
            $html += "<p>Type: $ReportType</p>"
            $html += "<p>Plage de temps: $TimeRange</p>"
            $html += "<p>GÃ©nÃ©rÃ© le: $($report.GeneratedAt)</p>"
            $html += "</body></html>"

            $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.html'
            $html | Out-File -FilePath $tempFile -Encoding utf8

            Write-Log -Message "Rapport HTML gÃ©nÃ©rÃ©: $tempFile" -Level "INFO"
            return $tempFile
        }
        "JSON" {
            $json = $report | ConvertTo-Json -Depth 10

            $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
            $json | Out-File -FilePath $tempFile -Encoding utf8

            Write-Log -Message "Rapport JSON gÃ©nÃ©rÃ©: $tempFile" -Level "INFO"
            return $tempFile
        }
        default {
            Write-Log -Message "Rapport texte gÃ©nÃ©rÃ©" -Level "INFO"
            return $report
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-PerformanceAnalyzer, Start-PerformanceAnalysis, Get-PerformanceReport, Measure-CPUMetrics, Measure-MemoryMetrics, Measure-DiskMetrics, Measure-NetworkMetrics, Measure-Metrics, Get-MetricTrend
