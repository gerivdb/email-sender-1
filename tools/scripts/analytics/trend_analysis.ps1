<#
.SYNOPSIS
    Script d'analyse des tendances et patterns dans les données de performance.
.DESCRIPTION
    Analyse les données historiques pour identifier tendances, cycles et patterns.
.PARAMETER DataPath
    Chemin vers les données préparées.
.PARAMETER OutputPath
    Chemin où les résultats seront sauvegardés.
.PARAMETER LogLevel
    Niveau de journalisation (Verbose, Info, Warning, Error).
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$DataPath = "data/performance",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "data/analysis",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Verbose", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

# Fonction pour la journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Verbose", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $LogLevels = @{
        "Verbose" = 0; "Info" = 1; "Warning" = 2; "Error" = 3
    }
    
    if ($LogLevels[$Level] -ge $LogLevels[$LogLevel]) {
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $LogMessage = "[$Timestamp] [$Level] $Message"
        
        switch ($Level) {
            "Verbose" { Write-Verbose $LogMessage }
            "Info" { Write-Host $LogMessage -ForegroundColor Cyan }
            "Warning" { Write-Host $LogMessage -ForegroundColor Yellow }
            "Error" { Write-Host $LogMessage -ForegroundColor Red }
        }
    }
}

# Fonction pour charger les données
function Import-PerformanceData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    Write-Log -Message "Chargement des données depuis $FilePath" -Level "Info"
    
    try {
        if (Test-Path -Path $FilePath) {
            $Data = Import-Csv -Path $FilePath
            Write-Log -Message "Chargement réussi: $($Data.Count) entrées" -Level "Info"
            return $Data
        } else {
            Write-Log -Message "Fichier non trouvé: $FilePath" -Level "Error"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des données: $_" -Level "Error"
        return $null
    }
}

# Fonction pour analyser les tendances
function Get-Trends {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$TimeColumn,
        
        [Parameter(Mandatory=$true)]
        [string]$ValueColumn,
        
        [Parameter(Mandatory=$false)]
        [string]$GroupColumn
    )
    
    Write-Log -Message "Analyse des tendances" -Level "Info"
    
    try {
        # Vérifier si les données sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée à analyser" -Level "Warning"
            return $null
        }
        
        # Convertir les timestamps en objets DateTime
        $Data | ForEach-Object {
            $_.$TimeColumn = [DateTime]::Parse($_.$TimeColumn)
        }
        
        # Trier les données par timestamp
        $SortedData = $Data | Sort-Object -Property $TimeColumn
        
        # Grouper les données si nécessaire
        if ($GroupColumn) {
            $GroupedData = $SortedData | Group-Object -Property $GroupColumn
            $Results = @()
            
            foreach ($Group in $GroupedData) {
                $GroupValues = $Group.Group | Select-Object -Property $TimeColumn, $ValueColumn
                
                # Calculer les statistiques de tendance
                $FirstValue = [double]($GroupValues | Select-Object -First 1).$ValueColumn
                $LastValue = [double]($GroupValues | Select-Object -Last 1).$ValueColumn
                $MinValue = [double]($GroupValues | Measure-Object -Property $ValueColumn -Minimum).Minimum
                $MaxValue = [double]($GroupValues | Measure-Object -Property $ValueColumn -Maximum).Maximum
                $AvgValue = [double]($GroupValues | Measure-Object -Property $ValueColumn -Average).Average
                
                # Calculer la tendance (pente)
                $Trend = if ($GroupValues.Count -gt 1) {
                    ($LastValue - $FirstValue) / ($GroupValues.Count - 1)
                } else {
                    0
                }
                
                # Déterminer la direction de la tendance
                $Direction = if ($Trend -gt 0) {
                    "Hausse"
                } elseif ($Trend -lt 0) {
                    "Baisse"
                } else {
                    "Stable"
                }
                
                $Results += [PSCustomObject]@{
                    Group = $Group.Name
                    Count = $GroupValues.Count
                    FirstTimestamp = ($GroupValues | Select-Object -First 1).$TimeColumn
                    LastTimestamp = ($GroupValues | Select-Object -Last 1).$TimeColumn
                    FirstValue = $FirstValue
                    LastValue = $LastValue
                    MinValue = $MinValue
                    MaxValue = $MaxValue
                    AvgValue = $AvgValue
                    Trend = $Trend
                    Direction = $Direction
                }
            }
            
            return $Results
        } else {
            # Calculer les statistiques de tendance pour toutes les données
            $FirstValue = [double]($SortedData | Select-Object -First 1).$ValueColumn
            $LastValue = [double]($SortedData | Select-Object -Last 1).$ValueColumn
            $MinValue = [double]($SortedData | Measure-Object -Property $ValueColumn -Minimum).Minimum
            $MaxValue = [double]($SortedData | Measure-Object -Property $ValueColumn -Maximum).Maximum
            $AvgValue = [double]($SortedData | Measure-Object -Property $ValueColumn -Average).Average
            
            # Calculer la tendance (pente)
            $Trend = if ($SortedData.Count -gt 1) {
                ($LastValue - $FirstValue) / ($SortedData.Count - 1)
            } else {
                0
            }
            
            # Déterminer la direction de la tendance
            $Direction = if ($Trend -gt 0) {
                "Hausse"
            } elseif ($Trend -lt 0) {
                "Baisse"
            } else {
                "Stable"
            }
            
            return [PSCustomObject]@{
                Count = $SortedData.Count
                FirstTimestamp = ($SortedData | Select-Object -First 1).$TimeColumn
                LastTimestamp = ($SortedData | Select-Object -Last 1).$TimeColumn
                FirstValue = $FirstValue
                LastValue = $LastValue
                MinValue = $MinValue
                MaxValue = $MaxValue
                AvgValue = $AvgValue
                Trend = $Trend
                Direction = $Direction
            }
        }
    } catch {
        Write-Log -Message "Erreur lors de l'analyse des tendances: $_" -Level "Error"
        return $null
    }
}

# Fonction pour détecter les patterns saisonniers
function Get-SeasonalPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$TimeColumn,
        
        [Parameter(Mandatory=$true)]
        [string]$ValueColumn,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Hourly", "Daily", "Weekly", "Monthly")]
        [string]$Periodicity = "Daily"
    )
    
    Write-Log -Message "Détection des patterns saisonniers ($Periodicity)" -Level "Info"
    
    try {
        # Vérifier si les données sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée à analyser" -Level "Warning"
            return $null
        }
        
        # Convertir les timestamps en objets DateTime
        $Data | ForEach-Object {
            $_.$TimeColumn = [DateTime]::Parse($_.$TimeColumn)
        }
        
        # Grouper les données selon la périodicité
        switch ($Periodicity) {
            "Hourly" {
                $GroupedData = $Data | Group-Object -Property { $_.$TimeColumn.Hour }
            }
            "Daily" {
                $GroupedData = $Data | Group-Object -Property { $_.$TimeColumn.DayOfWeek }
            }
            "Weekly" {
                $GroupedData = $Data | Group-Object -Property { [math]::Floor(($_.$TimeColumn.DayOfYear - 1) / 7) }
            }
            "Monthly" {
                $GroupedData = $Data | Group-Object -Property { $_.$TimeColumn.Month }
            }
        }
        
        $Results = @()
        
        foreach ($Group in $GroupedData) {
            $GroupValues = $Group.Group | Select-Object -Property $TimeColumn, $ValueColumn
            
            # Calculer les statistiques pour chaque groupe
            $AvgValue = [double]($GroupValues | Measure-Object -Property $ValueColumn -Average).Average
            $StdDev = [Math]::Sqrt(($GroupValues | ForEach-Object { [Math]::Pow([double]$_.$ValueColumn - $AvgValue, 2) } | Measure-Object -Average).Average)
            
            $Results += [PSCustomObject]@{
                Period = $Group.Name
                Count = $GroupValues.Count
                AvgValue = $AvgValue
                StdDev = $StdDev
                MinValue = [double]($GroupValues | Measure-Object -Property $ValueColumn -Minimum).Minimum
                MaxValue = [double]($GroupValues | Measure-Object -Property $ValueColumn -Maximum).Maximum
            }
        }
        
        return $Results | Sort-Object -Property Period
    } catch {
        Write-Log -Message "Erreur lors de la détection des patterns saisonniers: $_" -Level "Error"
        return $null
    }
}

# Fonction pour détecter les cycles
function Get-Cycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$TimeColumn,
        
        [Parameter(Mandatory=$true)]
        [string]$ValueColumn,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxLag = 10
    )
    
    Write-Log -Message "Détection des cycles (MaxLag=$MaxLag)" -Level "Info"
    
    try {
        # Vérifier si les données sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée à analyser" -Level "Warning"
            return $null
        }
        
        # Convertir les timestamps en objets DateTime et les valeurs en nombres
        $Values = $Data | ForEach-Object { [double]$_.$ValueColumn }
        
        # Calculer l'autocorrélation pour différents lags
        $Results = @()
        
        for ($Lag = 1; $Lag -le $MaxLag; $Lag++) {
            $N = $Values.Count - $Lag
            
            if ($N -le 0) {
                continue
            }
            
            $Mean = ($Values | Measure-Object -Average).Average
            $Variance = ($Values | ForEach-Object { [Math]::Pow($_ - $Mean, 2) } | Measure-Object -Average).Average
            
            if ($Variance -eq 0) {
                $AutoCorr = 0
            } else {
                $Sum = 0
                for ($i = 0; $i -lt $N; $i++) {
                    $Sum += ($Values[$i] - $Mean) * ($Values[$i + $Lag] - $Mean)
                }
                $AutoCorr = $Sum / ($N * $Variance)
            }
            
            $Results += [PSCustomObject]@{
                Lag = $Lag
                AutoCorrelation = $AutoCorr
            }
        }
        
        return $Results
    } catch {
        Write-Log -Message "Erreur lors de la détection des cycles: $_" -Level "Error"
        return $null
    }
}

# Fonction pour exporter les résultats
function Export-AnalysisResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Results,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [string]$Format = "CSV" # CSV, JSON
    )
    
    Write-Log -Message "Exportation des résultats au format $Format vers $OutputPath" -Level "Info"
    
    try {
        # Vérifier si les résultats sont vides
        if ($null -eq $Results) {
            Write-Log -Message "Aucun résultat à exporter" -Level "Warning"
            return $false
        }
        
        # Créer le répertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # Exporter les résultats selon le format spécifié
        switch ($Format) {
            "CSV" {
                $Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            }
            "JSON" {
                $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            default {
                Write-Log -Message "Format d'exportation non pris en charge: $Format" -Level "Error"
                return $false
            }
        }
        
        Write-Log -Message "Exportation réussie vers $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des résultats: $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-TrendAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "Début de l'analyse des tendances et patterns" -Level "Info"
    
    # 1. Charger les données
    $PerformanceDataPath = Join-Path -Path $DataPath -ChildPath "prepared_performance_data.csv"
    $PerformanceData = Import-PerformanceData -FilePath $PerformanceDataPath
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # 2. Analyser les tendances
    if ($PerformanceData -and $PerformanceData.Count -gt 0) {
        $Trends = Get-Trends -Data $PerformanceData -TimeColumn "Timestamp" -ValueColumn "Value" -GroupColumn "Path"
        $TrendsOutputPath = Join-Path -Path $OutputPath -ChildPath "performance_trends.csv"
        Export-AnalysisResults -Results $Trends -OutputPath $TrendsOutputPath -Format "CSV"
        
        # 3. Détecter les patterns saisonniers
        $HourlyPatterns = Get-SeasonalPatterns -Data $PerformanceData -TimeColumn "Timestamp" -ValueColumn "Value" -Periodicity "Hourly"
        $HourlyPatternsOutputPath = Join-Path -Path $OutputPath -ChildPath "hourly_patterns.csv"
        Export-AnalysisResults -Results $HourlyPatterns -OutputPath $HourlyPatternsOutputPath -Format "CSV"
        
        $DailyPatterns = Get-SeasonalPatterns -Data $PerformanceData -TimeColumn "Timestamp" -ValueColumn "Value" -Periodicity "Daily"
        $DailyPatternsOutputPath = Join-Path -Path $OutputPath -ChildPath "daily_patterns.csv"
        Export-AnalysisResults -Results $DailyPatterns -OutputPath $DailyPatternsOutputPath -Format "CSV"
        
        # 4. Détecter les cycles
        $Cycles = Get-Cycles -Data $PerformanceData -TimeColumn "Timestamp" -ValueColumn "Value" -MaxLag 10
        $CyclesOutputPath = Join-Path -Path $OutputPath -ChildPath "performance_cycles.csv"
        Export-AnalysisResults -Results $Cycles -OutputPath $CyclesOutputPath -Format "CSV"
    } else {
        Write-Log -Message "Aucune donnée de performance disponible pour l'analyse" -Level "Warning"
    }
    
    Write-Log -Message "Analyse des tendances et patterns terminée" -Level "Info"
    
    return @{
        Success = $true
        Trends = $Trends
        HourlyPatterns = $HourlyPatterns
        DailyPatterns = $DailyPatterns
        Cycles = $Cycles
    }
}

# Exécution du script
$Result = Start-TrendAnalysis -DataPath $DataPath -OutputPath $OutputPath

if ($Result.Success) {
    Write-Log -Message "Analyse des tendances réussie" -Level "Info"
    return 0
} else {
    Write-Log -Message "Échec de l'analyse des tendances" -Level "Error"
    return 1
}
