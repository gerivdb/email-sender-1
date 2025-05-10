# Set-AdaptiveThresholds.ps1
# Script pour définir et ajuster les seuils de déclenchement adaptatifs
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
    [string]$ConfigType = "All",
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Thresholds,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Strict", "Normal", "Relaxed", "Custom")]
    [string]$Sensitivity = "Normal",
    
    [Parameter(Mandatory = $false)]
    [switch]$Learn,
    
    [Parameter(Mandatory = $false)]
    [int]$HistoryDays = 30,
    
    [Parameter(Mandatory = $false)]
    [switch]$Reset,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Importer le script de détection des changements significatifs
$significantChangePath = Join-Path -Path $scriptPath -ChildPath "Test-SignificantChange.ps1"

if (Test-Path -Path $significantChangePath) {
    . $significantChangePath
} else {
    Write-Log "Required script not found: $significantChangePath" -Level "Error"
    exit 1
}

# Fonction pour obtenir le chemin du fichier de configuration des seuils
function Get-ThresholdsConfigPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All"
    )
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    
    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }
    
    $thresholdsPath = Join-Path -Path $configPath -ChildPath "thresholds"
    
    if (-not (Test-Path -Path $thresholdsPath)) {
        New-Item -Path $thresholdsPath -ItemType Directory -Force | Out-Null
    }
    
    return Join-Path -Path $thresholdsPath -ChildPath "thresholds_$($ConfigType.ToLower()).json"
}

# Fonction pour charger les seuils existants
function Get-Thresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All"
    )
    
    $thresholdsPath = Get-ThresholdsConfigPath -ConfigType $ConfigType
    
    if (Test-Path -Path $thresholdsPath) {
        try {
            $thresholds = Get-Content -Path $thresholdsPath -Raw | ConvertFrom-Json
            return $thresholds
        } catch {
            Write-Log "Error loading thresholds: $_" -Level "Error"
            return $null
        }
    } else {
        return $null
    }
}

# Fonction pour sauvegarder les seuils
function Save-Thresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Thresholds,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All"
    )
    
    $thresholdsPath = Get-ThresholdsConfigPath -ConfigType $ConfigType
    
    try {
        $Thresholds | ConvertTo-Json -Depth 10 | Out-File -FilePath $thresholdsPath -Encoding UTF8
        Write-Log "Thresholds saved to: $thresholdsPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving thresholds: $_" -Level "Error"
        return $false
    }
}

# Fonction pour obtenir les seuils par défaut en fonction de la sensibilité
function Get-SensitivityThresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Strict", "Normal", "Relaxed")]
        [string]$Sensitivity,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All"
    )
    
    # Obtenir les seuils par défaut
    $defaultThresholds = Get-DefaultThresholds -ConfigType $ConfigType
    
    # Ajuster les seuils en fonction de la sensibilité
    $sensitivityFactors = @{
        "Strict" = @{
            global_change_percent = 0.7
            modified_properties_count = 0.7
            added_properties_count = 0.7
            removed_properties_count = 0.7
            size_change_percent = 0.7
            structure_change_percent = 0.7
        }
        "Normal" = @{
            global_change_percent = 1.0
            modified_properties_count = 1.0
            added_properties_count = 1.0
            removed_properties_count = 1.0
            size_change_percent = 1.0
            structure_change_percent = 1.0
        }
        "Relaxed" = @{
            global_change_percent = 1.5
            modified_properties_count = 1.5
            added_properties_count = 1.5
            removed_properties_count = 1.5
            size_change_percent = 1.5
            structure_change_percent = 1.5
        }
    }
    
    $factors = $sensitivityFactors[$Sensitivity]
    $adjustedThresholds = $defaultThresholds.Clone()
    
    # Appliquer les facteurs de sensibilité
    $adjustedThresholds.global_change_percent = [Math]::Round($defaultThresholds.global_change_percent * $factors.global_change_percent)
    $adjustedThresholds.modified_properties_count = [Math]::Round($defaultThresholds.modified_properties_count * $factors.modified_properties_count)
    $adjustedThresholds.added_properties_count = [Math]::Round($defaultThresholds.added_properties_count * $factors.added_properties_count)
    $adjustedThresholds.removed_properties_count = [Math]::Round($defaultThresholds.removed_properties_count * $factors.removed_properties_count)
    $adjustedThresholds.size_change_percent = [Math]::Round($defaultThresholds.size_change_percent * $factors.size_change_percent)
    $adjustedThresholds.structure_change_percent = [Math]::Round($defaultThresholds.structure_change_percent * $factors.structure_change_percent)
    
    # Ajouter des métadonnées
    $adjustedThresholds.sensitivity = $Sensitivity
    $adjustedThresholds.config_type = $ConfigType
    $adjustedThresholds.last_updated = (Get-Date).ToString("o")
    $adjustedThresholds.is_adaptive = $false
    
    return $adjustedThresholds
}

# Fonction pour analyser l'historique des changements
function Get-ChangeHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$HistoryDays = 30
    )
    
    # Obtenir le chemin du répertoire des journaux
    $logsPath = Join-Path -Path $parentPath -ChildPath "logs"
    
    if (-not (Test-Path -Path $logsPath)) {
        Write-Log "Logs directory not found: $logsPath" -Level "Warning"
        return @()
    }
    
    # Obtenir tous les fichiers de journal des derniers jours
    $startDate = (Get-Date).AddDays(-$HistoryDays)
    $logFiles = Get-ChildItem -Path $logsPath -Filter "*.json" | Where-Object { $_.LastWriteTime -ge $startDate }
    
    if ($logFiles.Count -eq 0) {
        Write-Log "No log files found for the last $HistoryDays days" -Level "Warning"
        return @()
    }
    
    # Analyser les journaux pour extraire les métriques de changement
    $changeMetrics = @()
    
    foreach ($logFile in $logFiles) {
        try {
            $logs = Get-Content -Path $logFile.FullName -Raw | ConvertFrom-Json
            
            foreach ($log in $logs) {
                # Vérifier si le journal contient des métriques de changement
                if ($log.PSObject.Properties.Name.Contains("event_data") -and 
                    $log.event_data.PSObject.Properties.Name.Contains("change_analysis")) {
                    
                    $changeAnalysis = $log.event_data.change_analysis
                    
                    # Filtrer par type de configuration si spécifié
                    if ($ConfigType -ne "All" -and $changeAnalysis.config_type -ne $ConfigType) {
                        continue
                    }
                    
                    # Extraire les métriques
                    $metric = @{
                        timestamp = $log.timestamp
                        config_type = $changeAnalysis.config_type
                        config_id = $changeAnalysis.config_id
                        is_significant = $changeAnalysis.is_significant
                        global_change_percent = $changeAnalysis.global_change_percent
                        added_count = $changeAnalysis.added_count
                        removed_count = $changeAnalysis.removed_count
                        modified_count = $changeAnalysis.modified_count
                        total_changes = $changeAnalysis.total_changes
                        critical_changes = $changeAnalysis.critical_changes.Count
                    }
                    
                    $changeMetrics += $metric
                }
            }
        } catch {
            Write-Log "Error processing log file $($logFile.Name): $_" -Level "Warning"
        }
    }
    
    return $changeMetrics
}

# Fonction pour calculer les seuils adaptatifs basés sur l'historique
function Get-AdaptiveThresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$HistoryDays = 30,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Strict", "Normal", "Relaxed")]
        [string]$BaseSensitivity = "Normal"
    )
    
    # Obtenir l'historique des changements
    $changeHistory = Get-ChangeHistory -ConfigType $ConfigType -HistoryDays $HistoryDays
    
    if ($changeHistory.Count -eq 0) {
        Write-Log "No change history found. Using default thresholds with $BaseSensitivity sensitivity." -Level "Warning"
        return Get-SensitivityThresholds -Sensitivity $BaseSensitivity -ConfigType $ConfigType
    }
    
    # Calculer les statistiques des métriques de changement
    $metrics = @{
        global_change_percent = @()
        added_count = @()
        removed_count = @()
        modified_count = @()
        total_changes = @()
    }
    
    foreach ($change in $changeHistory) {
        $metrics.global_change_percent += $change.global_change_percent
        $metrics.added_count += $change.added_count
        $metrics.removed_count += $change.removed_count
        $metrics.modified_count += $change.modified_count
        $metrics.total_changes += $change.total_changes
    }
    
    # Calculer les percentiles pour chaque métrique
    $percentiles = @{}
    
    foreach ($metricName in $metrics.Keys) {
        $values = $metrics[$metricName] | Sort-Object
        
        if ($values.Count -gt 0) {
            $p50Index = [Math]::Floor($values.Count * 0.5)
            $p75Index = [Math]::Floor($values.Count * 0.75)
            $p90Index = [Math]::Floor($values.Count * 0.9)
            
            $percentiles[$metricName] = @{
                p50 = $values[$p50Index]
                p75 = $values[$p75Index]
                p90 = $values[$p90Index]
                mean = ($values | Measure-Object -Average).Average
                max = ($values | Measure-Object -Maximum).Maximum
            }
        }
    }
    
    # Obtenir les seuils de base
    $baseThresholds = Get-SensitivityThresholds -Sensitivity $BaseSensitivity -ConfigType $ConfigType
    
    # Ajuster les seuils en fonction des statistiques
    $adaptiveThresholds = $baseThresholds.Clone()
    
    # Facteurs d'ajustement en fonction de la sensibilité
    $adjustmentFactors = @{
        "Strict" = @{
            percentile = "p50"
            factor = 0.8
        }
        "Normal" = @{
            percentile = "p75"
            factor = 1.0
        }
        "Relaxed" = @{
            percentile = "p90"
            factor = 1.2
        }
    }
    
    $adjustment = $adjustmentFactors[$BaseSensitivity]
    
    # Appliquer les ajustements
    if ($percentiles.ContainsKey("global_change_percent")) {
        $adaptiveThresholds.global_change_percent = [Math]::Max(
            [Math]::Round($percentiles.global_change_percent.($adjustment.percentile) * $adjustment.factor),
            $baseThresholds.global_change_percent * 0.5
        )
    }
    
    if ($percentiles.ContainsKey("modified_count")) {
        $adaptiveThresholds.modified_properties_count = [Math]::Max(
            [Math]::Round($percentiles.modified_count.($adjustment.percentile) * $adjustment.factor),
            $baseThresholds.modified_properties_count * 0.5
        )
    }
    
    if ($percentiles.ContainsKey("added_count")) {
        $adaptiveThresholds.added_properties_count = [Math]::Max(
            [Math]::Round($percentiles.added_count.($adjustment.percentile) * $adjustment.factor),
            $baseThresholds.added_properties_count * 0.5
        )
    }
    
    if ($percentiles.ContainsKey("removed_count")) {
        $adaptiveThresholds.removed_properties_count = [Math]::Max(
            [Math]::Round($percentiles.removed_count.($adjustment.percentile) * $adjustment.factor),
            $baseThresholds.removed_properties_count * 0.5
        )
    }
    
    # Ajouter des métadonnées
    $adaptiveThresholds.sensitivity = $BaseSensitivity
    $adaptiveThresholds.config_type = $ConfigType
    $adaptiveThresholds.last_updated = (Get-Date).ToString("o")
    $adaptiveThresholds.is_adaptive = $true
    $adaptiveThresholds.history_days = $HistoryDays
    $adaptiveThresholds.history_count = $changeHistory.Count
    $adaptiveThresholds.percentiles = $percentiles
    
    return $adaptiveThresholds
}

# Fonction pour définir les seuils adaptatifs
function Set-AdaptiveThresholds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Thresholds,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Strict", "Normal", "Relaxed", "Custom")]
        [string]$Sensitivity = "Normal",
        
        [Parameter(Mandatory = $false)]
        [switch]$Learn,
        
        [Parameter(Mandatory = $false)]
        [int]$HistoryDays = 30,
        
        [Parameter(Mandatory = $false)]
        [switch]$Reset,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Réinitialiser les seuils si demandé
    if ($Reset) {
        $thresholdsPath = Get-ThresholdsConfigPath -ConfigType $ConfigType
        
        if (Test-Path -Path $thresholdsPath) {
            try {
                Remove-Item -Path $thresholdsPath -Force
                Write-Log "Thresholds reset for $ConfigType" -Level "Info"
            } catch {
                Write-Log "Error resetting thresholds: $_" -Level "Error"
                return $false
            }
        }
        
        # Utiliser les seuils par défaut avec la sensibilité spécifiée
        $newThresholds = Get-SensitivityThresholds -Sensitivity $Sensitivity -ConfigType $ConfigType
        return Save-Thresholds -Thresholds $newThresholds -ConfigType $ConfigType
    }
    
    # Charger les seuils existants
    $existingThresholds = Get-Thresholds -ConfigType $ConfigType
    
    # Déterminer les nouveaux seuils
    $newThresholds = $null
    
    if ($null -ne $Thresholds -and $Thresholds.Count -gt 0) {
        # Utiliser les seuils fournis
        $newThresholds = $Thresholds.Clone()
        $newThresholds.sensitivity = "Custom"
        $newThresholds.config_type = $ConfigType
        $newThresholds.last_updated = (Get-Date).ToString("o")
        $newThresholds.is_adaptive = $false
    } elseif ($Learn) {
        # Calculer les seuils adaptatifs basés sur l'historique
        $newThresholds = Get-AdaptiveThresholds -ConfigType $ConfigType -HistoryDays $HistoryDays -BaseSensitivity $Sensitivity
    } else {
        # Utiliser les seuils prédéfinis en fonction de la sensibilité
        $newThresholds = Get-SensitivityThresholds -Sensitivity $Sensitivity -ConfigType $ConfigType
    }
    
    # Vérifier si les seuils existants doivent être remplacés
    if ($null -ne $existingThresholds -and -not $Force) {
        Write-Log "Thresholds already exist for $ConfigType. Use -Force to overwrite." -Level "Warning"
        return $false
    }
    
    # Sauvegarder les nouveaux seuils
    $result = Save-Thresholds -Thresholds $newThresholds -ConfigType $ConfigType
    
    if ($result) {
        Write-Log "Thresholds updated for $ConfigType with sensitivity: $($newThresholds.sensitivity)" -Level "Info"
        
        if ($newThresholds.is_adaptive) {
            Write-Log "Adaptive thresholds based on $($newThresholds.history_count) changes over $($newThresholds.history_days) days" -Level "Info"
        }
        
        return $newThresholds
    } else {
        Write-Log "Failed to update thresholds for $ConfigType" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Set-AdaptiveThresholds -ConfigType $ConfigType -Thresholds $Thresholds -Sensitivity $Sensitivity -Learn:$Learn -HistoryDays $HistoryDays -Reset:$Reset -Force:$Force
}
