# Module PerformancePredictor
# Ce module fournit une interface PowerShell pour les modèles prédictifs
# Author: EMAIL_SENDER_1 Team
# Version: 1.0.0

#Requires -Version 5.1

# Variables globales du module
$script:PerformancePredictorConfig = @{
    Enabled                = $true
    ConfigPath             = "$env:TEMP\PerformancePredictor\config.json"
    LogPath                = "$env:TEMP\PerformancePredictor\logs.log"
    LogLevel               = "INFO"
    PythonPath             = "python"
    PredictiveModelPath    = "$PSScriptRoot\PredictiveModel.py"
    ModelStoragePath       = "$env:TEMP\PerformancePredictor\models"
    PredictionHorizon      = 24
    AnomalySensitivity     = "Medium"
    RetrainingInterval     = 7  # Jours
    MetricsToPredictString = "CPU.Usage,Memory.Usage,Disk.Usage,Network.BandwidthUsage,ResponseTime,ErrorRate,ThroughputRate"
}

function Initialize-PerformancePredictor {
    <#
    .SYNOPSIS
        Initialise le module de prédiction des performances.
    .DESCRIPTION
        Configure et initialise le module de prédiction des performances avec les paramètres spécifiés.
    .PARAMETER Enabled
        Active ou désactive le prédicteur de performances.
    .PARAMETER ConfigPath
        Chemin du fichier de configuration.
    .PARAMETER LogPath
        Chemin du fichier de log.
    .PARAMETER LogLevel
        Niveau de log (DEBUG, INFO, WARNING, ERROR).
    .PARAMETER PythonPath
        Chemin vers l'exécutable Python.
    .PARAMETER ModelStoragePath
        Chemin de stockage des modèles prédictifs.
    .PARAMETER PredictionHorizon
        Nombre de points à prédire dans le futur.
    .PARAMETER AnomalySensitivity
        Sensibilité de la détection d'anomalies (Low, Medium, High).
    .PARAMETER RetrainingInterval
        Intervalle de réentraînement des modèles en jours.
    .PARAMETER MetricsToPredictString
        Liste des métriques à prédire, séparées par des virgules.
    .EXAMPLE
        Initialize-PerformancePredictor -ConfigPath "C:\Config\perf_config.json" -LogPath "C:\Logs\perf.log"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "$env:TEMP\PerformancePredictor\config.json",

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$env:TEMP\PerformancePredictor\logs.log",

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$LogLevel = "INFO",

        [Parameter(Mandatory = $false)]
        [string]$PythonPath = "python",

        [Parameter(Mandatory = $false)]
        [string]$ModelStoragePath = "$env:TEMP\PerformancePredictor\models",

        [Parameter(Mandatory = $false)]
        [int]$PredictionHorizon = 24,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Low", "Medium", "High")]
        [string]$AnomalySensitivity = "Medium",

        [Parameter(Mandatory = $false)]
        [int]$RetrainingInterval = 7,

        [Parameter(Mandatory = $false)]
        [string]$MetricsToPredictString = "CPU.Usage,Memory.Usage,Disk.Usage,Network.BandwidthUsage,ResponseTime,ErrorRate,ThroughputRate"
    )

    # Mettre à jour la configuration
    $script:PerformancePredictorConfig.Enabled = $Enabled
    $script:PerformancePredictorConfig.ConfigPath = $ConfigPath
    $script:PerformancePredictorConfig.LogPath = $LogPath
    $script:PerformancePredictorConfig.LogLevel = $LogLevel
    $script:PerformancePredictorConfig.PythonPath = $PythonPath
    $script:PerformancePredictorConfig.ModelStoragePath = $ModelStoragePath
    $script:PerformancePredictorConfig.PredictionHorizon = $PredictionHorizon
    $script:PerformancePredictorConfig.AnomalySensitivity = $AnomalySensitivity
    $script:PerformancePredictorConfig.RetrainingInterval = $RetrainingInterval
    $script:PerformancePredictorConfig.MetricsToPredictString = $MetricsToPredictString

    # Créer les répertoires nécessaires
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

    # Vérifier que Python est disponible
    try {
        $pythonVersion = & $PythonPath --version 2>&1
        Write-Log -Message "Python détecté: $pythonVersion" -Level "DEBUG"

        # Vérifier que le module PredictiveModel.py existe
        if (-not (Test-Path -Path $script:PerformancePredictorConfig.PredictiveModelPath)) {
            Write-Log -Message "Module d'analyse prédictive non trouvé: $($script:PerformancePredictorConfig.PredictiveModelPath)" -Level "WARNING"
            $script:PerformancePredictorConfig.Enabled = $false
        }
    } catch {
        Write-Log -Message "Python non disponible. Le prédicteur de performances sera désactivé." -Level "WARNING"
        $script:PerformancePredictorConfig.Enabled = $false
    }

    # Créer le fichier de configuration Python
    $pythonConfig = @{
        model_dir           = $ModelStoragePath
        history_size        = 24
        forecast_horizon    = $PredictionHorizon
        anomaly_sensitivity = switch ($AnomalySensitivity) {
            "Low" { 0.1 }
            "Medium" { 0.05 }
            "High" { 0.01 }
            default { 0.05 }
        }
        training_ratio      = 0.8
        metrics_to_predict  = $MetricsToPredictString -split ','
        retraining_interval = $RetrainingInterval
    }

    # Sauvegarder la configuration
    $pythonConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding utf8

    # Journaliser l'initialisation
    Write-Log -Message "PerformancePredictor initialisé avec succès." -Level "INFO"
    Write-Log -Message "Configuration: $($script:PerformancePredictorConfig | ConvertTo-Json -Compress)" -Level "DEBUG"

    return $script:PerformancePredictorConfig
}

function Write-Log {
    <#
    .SYNOPSIS
        Écrit un message dans le fichier de log.
    .DESCRIPTION
        Écrit un message dans le fichier de log avec le niveau spécifié.
    .PARAMETER Message
        Message à journaliser.
    .PARAMETER Level
        Niveau de log (DEBUG, INFO, WARNING, ERROR).
    .EXAMPLE
        Write-Log -Message "Opération réussie" -Level "INFO"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    # Vérifier si le niveau de log est suffisant
    $logLevels = @{
        "DEBUG"   = 0
        "INFO"    = 1
        "WARNING" = 2
        "ERROR"   = 3
    }

    if ($logLevels[$Level] -lt $logLevels[$script:PerformancePredictorConfig.LogLevel]) {
        return
    }

    # Formater le message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Créer le répertoire de log s'il n'existe pas
    $logDir = Split-Path -Path $script:PerformancePredictorConfig.LogPath -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # Écrire dans le fichier de log
    try {
        Add-Content -Path $script:PerformancePredictorConfig.LogPath -Value $logMessage -ErrorAction Stop
    } catch {
        Write-Warning "Impossible d'écrire dans le fichier de log: $_"
    }

    # Afficher dans la console si le niveau est WARNING ou ERROR
    if ($Level -eq "WARNING" -or $Level -eq "ERROR") {
        Write-Host $logMessage -ForegroundColor $(if ($Level -eq "WARNING") { "Yellow" } else { "Red" })
    }
}

function Invoke-PredictiveModelPython {
    <#
    .SYNOPSIS
        Invoque le module Python de prédiction des performances.
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
    .PARAMETER ConfigFile
        Fichier de configuration personnalisé.
    .EXAMPLE
        Invoke-PredictiveModelPython -Action predict -InputFile metrics.json -OutputFile predictions.json
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
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string]$ConfigFile
    )

    # Vérifier que le prédicteur est activé
    if (-not $script:PerformancePredictorConfig.Enabled) {
        Write-Warning "Le prédicteur de performances est désactivé. Utilisez Initialize-PerformancePredictor -Enabled `$true pour l'activer."
        return $null
    }

    # Vérifier que le fichier d'entrée existe
    if (-not (Test-Path -Path $InputFile)) {
        Write-Error "Le fichier d'entrée '$InputFile' n'existe pas."
        return $null
    }

    # Construire la commande Python
    $pythonArgs = @(
        "`"$($script:PerformancePredictorConfig.PredictiveModelPath)`"",
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

    if ($ConfigFile) {
        $pythonArgs += "--config", "`"$ConfigFile`""
    } elseif (Test-Path -Path $script:PerformancePredictorConfig.ConfigPath) {
        $pythonArgs += "--config", "`"$($script:PerformancePredictorConfig.ConfigPath)`""
    }

    $pythonCommand = "$($script:PerformancePredictorConfig.PythonPath) $($pythonArgs -join ' ')"
    Write-Log -Message "Exécution de la commande: $pythonCommand" -Level "DEBUG"

    try {
        # Exécuter la commande Python
        $result = & $script:PerformancePredictorConfig.PythonPath $script:PerformancePredictorConfig.PredictiveModelPath `
            --action $Action `
            --input "$InputFile" `
        $(if ($OutputFile) { "--output `"$OutputFile`"" }) `
        $(if ($Horizon) { "--horizon $Horizon" }) `
        $(if ($Force) { "--force" }) `
        $(if ($ConfigFile) { "--config `"$ConfigFile`"" } elseif (Test-Path -Path $script:PerformancePredictorConfig.ConfigPath) { "--config `"$($script:PerformancePredictorConfig.ConfigPath)`"" })

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
            Write-Warning "Aucun résultat retourné par le module de prédiction."
            return $null
        }
    } catch {
        Write-Error "Erreur lors de l'exécution du module de prédiction: $_"
        return $null
    }
}

function Export-MetricsToJson {
    <#
    .SYNOPSIS
        Exporte les métriques au format JSON pour l'analyse prédictive.
    .DESCRIPTION
        Convertit les métriques collectées en format JSON compatible avec le module de prédiction.
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
        $metric = @{
            Timestamp = if ($_.Timestamp -is [DateTime]) { $_.Timestamp.ToString('o') } else { $_.Timestamp }
        }

        # Ajouter les métriques standard si elles existent
        if ($_.CPU -and $_.CPU.PSObject.Properties.Name -contains "Usage") {
            $metric["CPU.Usage"] = $_.CPU.Usage
        }

        if ($_.Memory -and $_.Memory.PSObject.Properties.Name -contains "Physical" -and
            $_.Memory.Physical.PSObject.Properties.Name -contains "UsagePercent") {
            $metric["Memory.Usage"] = $_.Memory.Physical.UsagePercent
        }

        if ($_.Disk -and $_.Disk.PSObject.Properties.Name -contains "Usage" -and
            $_.Disk.Usage.PSObject.Properties.Name -contains "Average") {
            $metric["Disk.Usage"] = $_.Disk.Usage.Average
        }

        if ($_.Network -and $_.Network.PSObject.Properties.Name -contains "BandwidthUsage") {
            $metric["Network.BandwidthUsage"] = $_.Network.BandwidthUsage
        }

        # Ajouter les métriques avancées si elles existent
        if ($_.PSObject.Properties.Name -contains "ResponseTime") {
            $metric["ResponseTime"] = $_.ResponseTime
        }

        if ($_.PSObject.Properties.Name -contains "ErrorRate") {
            $metric["ErrorRate"] = $_.ErrorRate
        }

        if ($_.PSObject.Properties.Name -contains "ThroughputRate") {
            $metric["ThroughputRate"] = $_.ThroughputRate
        }

        return $metric
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

function Start-ModelTraining {
    <#
    .SYNOPSIS
        Entraîne les modèles prédictifs de performance.
    .DESCRIPTION
        Utilise le module de prédiction pour entraîner les modèles de prédiction des performances.
    .PARAMETER Metrics
        Métriques à utiliser pour l'entraînement.
    .PARAMETER Force
        Force le réentraînement des modèles même si l'intervalle de réentraînement n'est pas atteint.
    .PARAMETER MetricNames
        Noms des métriques spécifiques à entraîner (par défaut, toutes les métriques configurées).
    .EXAMPLE
        Start-ModelTraining -Metrics $metrics -Force
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string[]]$MetricNames
    )

    # Vérifier que le prédicteur est activé
    if (-not $script:PerformancePredictorConfig.Enabled) {
        Write-Warning "Le prédicteur de performances est désactivé. Utilisez Initialize-PerformancePredictor -Enabled `$true pour l'activer."
        return $null
    }

    # Si des métriques spécifiques sont demandées, créer une configuration personnalisée
    $configFile = $null
    if ($MetricNames -and $MetricNames.Count -gt 0) {
        $configFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
        $config = @{
            model_dir           = $script:PerformancePredictorConfig.ModelStoragePath
            history_size        = 24
            forecast_horizon    = $script:PerformancePredictorConfig.PredictionHorizon
            anomaly_sensitivity = switch ($script:PerformancePredictorConfig.AnomalySensitivity) {
                "Low" { 0.1 }
                "Medium" { 0.05 }
                "High" { 0.01 }
                default { 0.05 }
            }
            training_ratio      = 0.8
            metrics_to_predict  = $MetricNames
            retraining_interval = $script:PerformancePredictorConfig.RetrainingInterval
        }
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configFile -Encoding utf8
    }

    # Exporter les métriques au format JSON
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $jsonPath = Export-MetricsToJson -Metrics $Metrics -OutputPath $tempFile

    # Entraîner les modèles
    $result = Invoke-PredictiveModelPython -Action "train" -InputFile $jsonPath -Force:$Force -ConfigFile $configFile

    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $jsonPath) {
        Remove-Item -Path $jsonPath -Force
    }
    if ($configFile -and (Test-Path -Path $configFile)) {
        Remove-Item -Path $configFile -Force
    }

    return $result
}

function Get-PerformancePrediction {
    <#
    .SYNOPSIS
        Prédit les valeurs futures des métriques de performance.
    .DESCRIPTION
        Utilise le module de prédiction pour prédire les valeurs futures des métriques de performance.
    .PARAMETER Metrics
        Métriques historiques à utiliser pour la prédiction.
    .PARAMETER MetricName
        Nom de la métrique à prédire.
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
        [string]$MetricName,

        [Parameter(Mandatory = $false)]
        [int]$Horizon = 0
    )

    # Vérifier que le prédicteur est activé
    if (-not $script:PerformancePredictorConfig.Enabled) {
        Write-Warning "Le prédicteur de performances est désactivé. Utilisez Initialize-PerformancePredictor -Enabled `$true pour l'activer."
        return $null
    }

    # Utiliser l'horizon de configuration si non spécifié
    if ($Horizon -le 0) {
        $Horizon = $script:PerformancePredictorConfig.PredictionHorizon
    }

    # Créer une configuration personnalisée pour cette métrique
    $configFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $config = @{
        model_dir           = $script:PerformancePredictorConfig.ModelStoragePath
        history_size        = 24
        forecast_horizon    = $Horizon
        anomaly_sensitivity = switch ($script:PerformancePredictorConfig.AnomalySensitivity) {
            "Low" { 0.1 }
            "Medium" { 0.05 }
            "High" { 0.01 }
            default { 0.05 }
        }
        training_ratio      = 0.8
        metrics_to_predict  = @($MetricName)
        retraining_interval = $script:PerformancePredictorConfig.RetrainingInterval
    }
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configFile -Encoding utf8

    # Exporter les métriques au format JSON
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $jsonPath = Export-MetricsToJson -Metrics $Metrics -OutputPath $tempFile

    # Effectuer la prédiction
    $result = Invoke-PredictiveModelPython -Action "predict" -InputFile $jsonPath -Horizon $Horizon -ConfigFile $configFile

    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $jsonPath) {
        Remove-Item -Path $jsonPath -Force
    }
    if (Test-Path -Path $configFile) {
        Remove-Item -Path $configFile -Force
    }

    # Extraire les résultats pour la métrique spécifiée
    if ($result -and $result.PSObject.Properties.Name -contains $MetricName) {
        return $result.$MetricName
    } else {
        Write-Warning "Aucun résultat disponible pour la métrique $MetricName"
        return $null
    }
}

function Find-PerformanceAnomaly {
    <#
    .SYNOPSIS
        Détecte les anomalies dans les métriques de performance.
    .DESCRIPTION
        Utilise le module de prédiction pour détecter les anomalies dans les métriques de performance.
    .PARAMETER Metrics
        Métriques à analyser.
    .PARAMETER MetricName
        Nom de la métrique à analyser.
    .PARAMETER Sensitivity
        Sensibilité de la détection d'anomalies (Low, Medium, High).
    .EXAMPLE
        Find-PerformanceAnomaly -Metrics $metrics -MetricName "CPU.Usage" -Sensitivity "High"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics,

        [Parameter(Mandatory = $true)]
        [string]$MetricName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Low", "Medium", "High")]
        [string]$Sensitivity = ""
    )

    # Vérifier que le prédicteur est activé
    if (-not $script:PerformancePredictorConfig.Enabled) {
        Write-Warning "Le prédicteur de performances est désactivé. Utilisez Initialize-PerformancePredictor -Enabled `$true pour l'activer."
        return $null
    }

    # Utiliser la sensibilité de configuration si non spécifiée
    if ([string]::IsNullOrEmpty($Sensitivity)) {
        $Sensitivity = $script:PerformancePredictorConfig.AnomalySensitivity
    }

    # Créer une configuration personnalisée pour cette métrique
    $configFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $config = @{
        model_dir           = $script:PerformancePredictorConfig.ModelStoragePath
        history_size        = 24
        forecast_horizon    = $script:PerformancePredictorConfig.PredictionHorizon
        anomaly_sensitivity = switch ($Sensitivity) {
            "Low" { 0.1 }
            "Medium" { 0.05 }
            "High" { 0.01 }
            default { 0.05 }
        }
        training_ratio      = 0.8
        metrics_to_predict  = @($MetricName)
        retraining_interval = $script:PerformancePredictorConfig.RetrainingInterval
    }
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configFile -Encoding utf8

    # Exporter les métriques au format JSON
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $jsonPath = Export-MetricsToJson -Metrics $Metrics -OutputPath $tempFile

    # Détecter les anomalies
    $result = Invoke-PredictiveModelPython -Action "anomalies" -InputFile $jsonPath -ConfigFile $configFile

    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $jsonPath) {
        Remove-Item -Path $jsonPath -Force
    }
    if (Test-Path -Path $configFile) {
        Remove-Item -Path $configFile -Force
    }

    # Extraire les résultats pour la métrique spécifiée
    if ($result -and $result.PSObject.Properties.Name -contains $MetricName) {
        return $result.$MetricName
    } else {
        Write-Warning "Aucune anomalie détectée pour la métrique $MetricName"
        return $null
    }
}

function Get-PerformanceTrend {
    <#
    .SYNOPSIS
        Analyse les tendances dans les métriques de performance.
    .DESCRIPTION
        Utilise le module de prédiction pour analyser les tendances dans les métriques de performance.
    .PARAMETER Metrics
        Métriques à analyser.
    .PARAMETER MetricName
        Nom de la métrique à analyser.
    .EXAMPLE
        Get-PerformanceTrend -Metrics $metrics -MetricName "CPU.Usage"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics,

        [Parameter(Mandatory = $true)]
        [string]$MetricName
    )

    # Vérifier que le prédicteur est activé
    if (-not $script:PerformancePredictorConfig.Enabled) {
        Write-Warning "Le prédicteur de performances est désactivé. Utilisez Initialize-PerformancePredictor -Enabled `$true pour l'activer."
        return $null
    }

    # Créer une configuration personnalisée pour cette métrique
    $configFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $config = @{
        model_dir           = $script:PerformancePredictorConfig.ModelStoragePath
        history_size        = 24
        forecast_horizon    = $script:PerformancePredictorConfig.PredictionHorizon
        anomaly_sensitivity = switch ($script:PerformancePredictorConfig.AnomalySensitivity) {
            "Low" { 0.1 }
            "Medium" { 0.05 }
            "High" { 0.01 }
            default { 0.05 }
        }
        training_ratio      = 0.8
        metrics_to_predict  = @($MetricName)
        retraining_interval = $script:PerformancePredictorConfig.RetrainingInterval
    }
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configFile -Encoding utf8

    # Exporter les métriques au format JSON
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.json'
    $jsonPath = Export-MetricsToJson -Metrics $Metrics -OutputPath $tempFile

    # Analyser les tendances
    $result = Invoke-PredictiveModelPython -Action "trends" -InputFile $jsonPath -ConfigFile $configFile

    # Nettoyer les fichiers temporaires
    if (Test-Path -Path $jsonPath) {
        Remove-Item -Path $jsonPath -Force
    }
    if (Test-Path -Path $configFile) {
        Remove-Item -Path $configFile -Force
    }

    # Extraire les résultats pour la métrique spécifiée
    if ($result -and $result.PSObject.Properties.Name -contains $MetricName) {
        return $result.$MetricName
    } else {
        Write-Warning "Aucune tendance détectée pour la métrique $MetricName"
        return $null
    }
}

function Export-PredictionReport {
    <#
    .SYNOPSIS
        Exporte un rapport de prédiction complet.
    .DESCRIPTION
        Génère et exporte un rapport complet contenant les prédictions, les anomalies et les tendances.
    .PARAMETER Metrics
        Métriques à analyser.
    .PARAMETER MetricNames
        Noms des métriques à inclure dans le rapport.
    .PARAMETER OutputPath
        Chemin du fichier de sortie pour le rapport.
    .PARAMETER Format
        Format du rapport (JSON, HTML, CSV).
    .PARAMETER Horizon
        Horizon de prédiction.
    .EXAMPLE
        Export-PredictionReport -Metrics $metrics -MetricNames @("CPU.Usage", "Memory.Usage") -OutputPath "C:\Reports\prediction_report.json" -Format "JSON" -Horizon 24
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Metrics,

        [Parameter(Mandatory = $false)]
        [string[]]$MetricNames,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "HTML", "CSV")]
        [string]$Format = "JSON",

        [Parameter(Mandatory = $false)]
        [int]$Horizon = 0
    )

    # Vérifier que le prédicteur est activé
    if (-not $script:PerformancePredictorConfig.Enabled) {
        Write-Warning "Le prédicteur de performances est désactivé. Utilisez Initialize-PerformancePredictor -Enabled `$true pour l'activer."
        return $null
    }

    # Utiliser l'horizon de configuration si non spécifié
    if ($Horizon -le 0) {
        $Horizon = $script:PerformancePredictorConfig.PredictionHorizon
    }

    # Utiliser toutes les métriques configurées si non spécifiées
    if (-not $MetricNames -or $MetricNames.Count -eq 0) {
        $MetricNames = $script:PerformancePredictorConfig.MetricsToPredictString -split ','
    }

    # Générer le rapport
    $report = @{
        GeneratedAt  = Get-Date -Format "o"
        Horizon      = $Horizon
        MetricsCount = $Metrics.Count
        TimeRange    = @{
            Start = ($Metrics | Select-Object -First 1).Timestamp
            End   = ($Metrics | Select-Object -Last 1).Timestamp
        }
        Predictions  = @{}
        Anomalies    = @{}
        Trends       = @{}
    }

    # Générer les prédictions, anomalies et tendances pour chaque métrique
    foreach ($metricName in $MetricNames) {
        Write-Log -Message "Génération des prédictions pour $metricName" -Level "INFO"
        $prediction = Get-PerformancePrediction -Metrics $Metrics -MetricName $metricName -Horizon $Horizon
        if ($prediction -and $prediction.status -eq "success") {
            $report.Predictions[$metricName] = $prediction
        }

        Write-Log -Message "Détection des anomalies pour $metricName" -Level "INFO"
        $anomalies = Find-PerformanceAnomaly -Metrics $Metrics -MetricName $metricName
        if ($anomalies -and $anomalies.status -eq "success") {
            $report.Anomalies[$metricName] = $anomalies
        }

        Write-Log -Message "Analyse des tendances pour $metricName" -Level "INFO"
        $trend = Get-PerformanceTrend -Metrics $Metrics -MetricName $metricName
        if ($trend -and $trend.status -eq "success") {
            $report.Trends[$metricName] = $trend
        }
    }

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Exporter le rapport dans le format demandé
    switch ($Format) {
        "JSON" {
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        }
        "HTML" {
            # Générer un rapport HTML basique
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de prédiction des performances</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .metric-section { margin-bottom: 30px; border: 1px solid #eee; padding: 15px; border-radius: 5px; }
        .anomaly { color: red; }
        .trend-up { color: green; }
        .trend-down { color: orange; }
        .trend-stable { color: blue; }
    </style>
</head>
<body>
    <h1>Rapport de prédiction des performances</h1>
    <p><strong>Généré le:</strong> $($report.GeneratedAt)</p>
    <p><strong>Horizon de prédiction:</strong> $($report.Horizon) points</p>
    <p><strong>Nombre de métriques analysées:</strong> $($report.MetricsCount)</p>
    <p><strong>Période d'analyse:</strong> $($report.TimeRange.Start) à $($report.TimeRange.End)</p>

"@

            foreach ($metricName in $MetricNames) {
                $html += @"
    <div class="metric-section">
        <h2>Métrique: $metricName</h2>

"@

                # Ajouter les prédictions
                if ($report.Predictions.ContainsKey($metricName) -and $report.Predictions[$metricName].status -eq "success") {
                    $prediction = $report.Predictions[$metricName]
                    $html += @"
        <h3>Prédictions</h3>
        <table>
            <tr>
                <th>Timestamp</th>
                <th>Valeur prédite</th>
            </tr>
"@

                    for ($i = 0; $i -lt $prediction.predictions.Count; $i++) {
                        $html += @"
            <tr>
                <td>$($prediction.timestamps[$i])</td>
                <td>$($prediction.predictions[$i])</td>
            </tr>
"@
                    }

                    $html += @"
        </table>

"@
                }

                # Ajouter les anomalies
                if ($report.Anomalies.ContainsKey($metricName) -and $report.Anomalies[$metricName].status -eq "success") {
                    $anomalies = $report.Anomalies[$metricName]
                    $html += @"
        <h3>Anomalies</h3>
"@

                    if ($anomalies.anomalies.Count -gt 0) {
                        $html += @"
        <table>
            <tr>
                <th>Timestamp</th>
                <th>Valeur</th>
                <th>Score</th>
                <th>Sévérité</th>
            </tr>
"@

                        foreach ($anomaly in $anomalies.anomalies) {
                            $html += @"
            <tr class="anomaly">
                <td>$($anomaly.timestamp)</td>
                <td>$($anomaly.value)</td>
                <td>$($anomaly.score)</td>
                <td>$($anomaly.severity)</td>
            </tr>
"@
                        }

                        $html += @"
        </table>
"@
                    } else {
                        $html += @"
        <p>Aucune anomalie détectée.</p>
"@
                    }

                    $html += ""
                }

                # Ajouter les tendances
                if ($report.Trends.ContainsKey($metricName) -and $report.Trends[$metricName].status -eq "success") {
                    $trend = $report.Trends[$metricName]
                    $trendClass = switch ($trend.trend.direction) {
                        "croissante" { "trend-up" }
                        "décroissante" { "trend-down" }
                        default { "trend-stable" }
                    }

                    $html += @"
        <h3>Tendances</h3>
        <table>
            <tr>
                <th>Statistique</th>
                <th>Valeur</th>
            </tr>
            <tr>
                <td>Moyenne</td>
                <td>$($trend.statistics.mean)</td>
            </tr>
            <tr>
                <td>Médiane</td>
                <td>$($trend.statistics.median)</td>
            </tr>
            <tr>
                <td>Minimum</td>
                <td>$($trend.statistics.min)</td>
            </tr>
            <tr>
                <td>Maximum</td>
                <td>$($trend.statistics.max)</td>
            </tr>
            <tr>
                <td>Écart-type</td>
                <td>$($trend.statistics.std)</td>
            </tr>
            <tr>
                <td>Nombre de points</td>
                <td>$($trend.statistics.count)</td>
            </tr>
        </table>

        <h4>Analyse de tendance</h4>
        <table>
            <tr>
                <th>Caractéristique</th>
                <th>Valeur</th>
            </tr>
            <tr class="$trendClass">
                <td>Direction</td>
                <td>$($trend.trend.direction)</td>
            </tr>
            <tr>
                <td>Force</td>
                <td>$($trend.trend.strength)</td>
            </tr>
            <tr>
                <td>Pente</td>
                <td>$($trend.trend.slope)</td>
            </tr>
            <tr>
                <td>R²</td>
                <td>$($trend.trend.r2)</td>
            </tr>
        </table>
"@

                    if ($trend.PSObject.Properties.Name -contains "seasonality") {
                        $html += @"
        <p><strong>Saisonnalité:</strong> $($trend.seasonality)</p>
"@
                    }
                }

                $html += @"
    </div>

"@
            }

            $html += @"
</body>
</html>
"@

            $html | Out-File -FilePath $OutputPath -Encoding utf8
        }
        "CSV" {
            # Créer un fichier CSV pour chaque type de données
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputPath)
            $baseDir = [System.IO.Path]::GetDirectoryName($OutputPath)

            # Prédictions
            $predictionsPath = Join-Path -Path $baseDir -ChildPath "${baseName}_predictions.csv"
            $predictionsData = @()

            foreach ($metricName in $MetricNames) {
                if ($report.Predictions.ContainsKey($metricName) -and $report.Predictions[$metricName].status -eq "success") {
                    $prediction = $report.Predictions[$metricName]

                    for ($i = 0; $i -lt $prediction.predictions.Count; $i++) {
                        $predictionsData += [PSCustomObject]@{
                            Metric    = $metricName
                            Timestamp = $prediction.timestamps[$i]
                            Value     = $prediction.predictions[$i]
                        }
                    }
                }
            }

            if ($predictionsData.Count -gt 0) {
                $predictionsData | Export-Csv -Path $predictionsPath -NoTypeInformation -Encoding UTF8
            }

            # Anomalies
            $anomaliesPath = Join-Path -Path $baseDir -ChildPath "${baseName}_anomalies.csv"
            $anomaliesData = @()

            foreach ($metricName in $MetricNames) {
                if ($report.Anomalies.ContainsKey($metricName) -and $report.Anomalies[$metricName].status -eq "success") {
                    $anomalies = $report.Anomalies[$metricName]

                    foreach ($anomaly in $anomalies.anomalies) {
                        $anomaliesData += [PSCustomObject]@{
                            Metric    = $metricName
                            Timestamp = $anomaly.timestamp
                            Value     = $anomaly.value
                            Score     = $anomaly.score
                            Severity  = $anomaly.severity
                        }
                    }
                }
            }

            if ($anomaliesData.Count -gt 0) {
                $anomaliesData | Export-Csv -Path $anomaliesPath -NoTypeInformation -Encoding UTF8
            }

            # Tendances
            $trendsPath = Join-Path -Path $baseDir -ChildPath "${baseName}_trends.csv"
            $trendsData = @()

            foreach ($metricName in $MetricNames) {
                if ($report.Trends.ContainsKey($metricName) -and $report.Trends[$metricName].status -eq "success") {
                    $trend = $report.Trends[$metricName]

                    $trendsData += [PSCustomObject]@{
                        Metric      = $metricName
                        Mean        = $trend.statistics.mean
                        Median      = $trend.statistics.median
                        Min         = $trend.statistics.min
                        Max         = $trend.statistics.max
                        StdDev      = $trend.statistics.std
                        Direction   = $trend.trend.direction
                        Strength    = $trend.trend.strength
                        Slope       = $trend.trend.slope
                        R2          = $trend.trend.r2
                        Seasonality = if ($trend.PSObject.Properties.Name -contains "seasonality") { $trend.seasonality } else { "Unknown" }
                    }
                }
            }

            if ($trendsData.Count -gt 0) {
                $trendsData | Export-Csv -Path $trendsPath -NoTypeInformation -Encoding UTF8
            }

            # Créer un fichier d'index
            $indexPath = $OutputPath
            @"
Rapport de prédiction des performances
Généré le: $($report.GeneratedAt)

Fichiers générés:
- Prédictions: $predictionsPath
- Anomalies: $anomaliesPath
- Tendances: $trendsPath
"@ | Out-File -FilePath $indexPath -Encoding utf8
        }
    }

    Write-Log -Message "Rapport de prédiction exporté vers $OutputPath" -Level "INFO"
    return $OutputPath
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-PerformancePredictor, Start-ModelTraining, Get-PerformancePrediction, Find-PerformanceAnomaly, Get-PerformanceTrend, Export-PredictionReport
