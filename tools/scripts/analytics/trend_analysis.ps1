<#
.SYNOPSIS
    Script d'analyse des tendances et patterns dans les donnÃ©es de performance.
.DESCRIPTION
    Analyse les donnÃ©es historiques pour identifier tendances, cycles et patterns.
.PARAMETER DataPath
    Chemin vers les donnÃ©es prÃ©parÃ©es.
.PARAMETER OutputPath
    Chemin oÃ¹ les rÃ©sultats seront sauvegardÃ©s.
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

# Fonction pour charger les donnÃ©es
function Import-PerformanceData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    Write-Log -Message "Chargement des donnÃ©es depuis $FilePath" -Level "Info"
    
    try {
        if (Test-Path -Path $FilePath) {
            $Data = Import-Csv -Path $FilePath
            Write-Log -Message "Chargement rÃ©ussi: $($Data.Count) entrÃ©es" -Level "Info"
            return $Data
        } else {
            Write-Log -Message "Fichier non trouvÃ©: $FilePath" -Level "Error"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des donnÃ©es: $_" -Level "Error"
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
        # VÃ©rifier si les donnÃ©es sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e Ã  analyser" -Level "Warning"
            return $null
        }
        
        # Convertir les timestamps en objets DateTime
        $Data | ForEach-Object {
            $_.$TimeColumn = [DateTime]::Parse($_.$TimeColumn)
        }
        
        # Trier les donnÃ©es par timestamp
        $SortedData = $Data | Sort-Object -Property $TimeColumn
        
        # Grouper les donnÃ©es si nÃ©cessaire
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
                
                # DÃ©terminer la direction de la tendance
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
            # Calculer les statistiques de tendance pour toutes les donnÃ©es
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
            
            # DÃ©terminer la direction de la tendance
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

# Fonction pour dÃ©tecter les patterns saisonniers
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
    
    Write-Log -Message "DÃ©tection des patterns saisonniers ($Periodicity)" -Level "Info"
    
    try {
        # VÃ©rifier si les donnÃ©es sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e Ã  analyser" -Level "Warning"
            return $null
        }
        
        # Convertir les timestamps en objets DateTime
        $Data | ForEach-Object {
            $_.$TimeColumn = [DateTime]::Parse($_.$TimeColumn)
        }
        
        # Grouper les donnÃ©es selon la pÃ©riodicitÃ©
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
        Write-Log -Message "Erreur lors de la dÃ©tection des patterns saisonniers: $_" -Level "Error"
        return $null
    }
}

# Fonction pour dÃ©tecter les cycles
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
    
    Write-Log -Message "DÃ©tection des cycles (MaxLag=$MaxLag)" -Level "Info"
    
    try {
        # VÃ©rifier si les donnÃ©es sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e Ã  analyser" -Level "Warning"
            return $null
        }
        
        # Convertir les timestamps en objets DateTime et les valeurs en nombres
        $Values = $Data | ForEach-Object { [double]$_.$ValueColumn }
        
        # Calculer l'autocorrÃ©lation pour diffÃ©rents lags
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
        Write-Log -Message "Erreur lors de la dÃ©tection des cycles: $_" -Level "Error"
        return $null
    }
}

# Fonction pour exporter les rÃ©sultats
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
    
    Write-Log -Message "Exportation des rÃ©sultats au format $Format vers $OutputPath" -Level "Info"
    
    try {
        # VÃ©rifier si les rÃ©sultats sont vides
        if ($null -eq $Results) {
            Write-Log -Message "Aucun rÃ©sultat Ã  exporter" -Level "Warning"
            return $false
        }
        
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $Directory = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
        
        # Exporter les rÃ©sultats selon le format spÃ©cifiÃ©
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
        
        Write-Log -Message "Exportation rÃ©ussie vers $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des rÃ©sultats: $_" -Level "Error"
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
    
    Write-Log -Message "DÃ©but de l'analyse des tendances et patterns" -Level "Info"
    
    # 1. Charger les donnÃ©es
    $PerformanceDataPath = Join-Path -Path $DataPath -ChildPath "prepared_performance_data.csv"
    $PerformanceData = Import-PerformanceData -FilePath $PerformanceDataPath
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # 2. Analyser les tendances
    if ($PerformanceData -and $PerformanceData.Count -gt 0) {
        $Trends = Get-Trends -Data $PerformanceData -TimeColumn "Timestamp" -ValueColumn "Value" -GroupColumn "Path"
        $TrendsOutputPath = Join-Path -Path $OutputPath -ChildPath "performance_trends.csv"
        Export-AnalysisResults -Results $Trends -OutputPath $TrendsOutputPath -Format "CSV"
        
        # 3. DÃ©tecter les patterns saisonniers
        $HourlyPatterns = Get-SeasonalPatterns -Data $PerformanceData -TimeColumn "Timestamp" -ValueColumn "Value" -Periodicity "Hourly"
        $HourlyPatternsOutputPath = Join-Path -Path $OutputPath -ChildPath "hourly_patterns.csv"
        Export-AnalysisResults -Results $HourlyPatterns -OutputPath $HourlyPatternsOutputPath -Format "CSV"
        
        $DailyPatterns = Get-SeasonalPatterns -Data $PerformanceData -TimeColumn "Timestamp" -ValueColumn "Value" -Periodicity "Daily"
        $DailyPatternsOutputPath = Join-Path -Path $OutputPath -ChildPath "daily_patterns.csv"
        Export-AnalysisResults -Results $DailyPatterns -OutputPath $DailyPatternsOutputPath -Format "CSV"
        
        # 4. DÃ©tecter les cycles
        $Cycles = Get-Cycles -Data $PerformanceData -TimeColumn "Timestamp" -ValueColumn "Value" -MaxLag 10
        $CyclesOutputPath = Join-Path -Path $OutputPath -ChildPath "performance_cycles.csv"
        Export-AnalysisResults -Results $Cycles -OutputPath $CyclesOutputPath -Format "CSV"
    } else {
        Write-Log -Message "Aucune donnÃ©e de performance disponible pour l'analyse" -Level "Warning"
    }
    
    Write-Log -Message "Analyse des tendances et patterns terminÃ©e" -Level "Info"
    
    return @{
        Success = $true
        Trends = $Trends
        HourlyPatterns = $HourlyPatterns
        DailyPatterns = $DailyPatterns
        Cycles = $Cycles
    }
}

# ExÃ©cution du script
$Result = Start-TrendAnalysis -DataPath $DataPath -OutputPath $OutputPath

if ($Result.Success) {
    Write-Log -Message "Analyse des tendances rÃ©ussie" -Level "Info"
    return 0
} else {
    Write-Log -Message "Ã‰chec de l'analyse des tendances" -Level "Error"
    return 1
}
