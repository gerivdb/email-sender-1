<#
.SYNOPSIS
    Script de détection des anomalies dans les données historiques de performance.
.DESCRIPTION
    Identifie les valeurs aberrantes et les comportements anormaux dans les données.
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

# Fonction pour détecter les anomalies par la méthode IQR
function Get-IQROutliers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$ValueColumn,
        
        [Parameter(Mandatory=$false)]
        [string]$GroupColumn,
        
        [Parameter(Mandatory=$false)]
        [double]$Multiplier = 1.5
    )
    
    Write-Log -Message "Détection des anomalies par méthode IQR (Multiplier=$Multiplier)" -Level "Info"
    
    try {
        # Vérifier si les données sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée à analyser" -Level "Warning"
            return $null
        }
        
        $Outliers = @()
        
        # Grouper les données si nécessaire
        if ($GroupColumn) {
            $GroupedData = $Data | Group-Object -Property $GroupColumn
            
            foreach ($Group in $GroupedData) {
                $Values = $Group.Group | ForEach-Object { [double]$_.$ValueColumn }
                
                # Calculer les quartiles
                $SortedValues = $Values | Sort-Object
                $Q1Index = [math]::Floor($SortedValues.Count * 0.25)
                $Q3Index = [math]::Floor($SortedValues.Count * 0.75)
                $Q1 = $SortedValues[$Q1Index]
                $Q3 = $SortedValues[$Q3Index]
                $IQR = $Q3 - $Q1
                
                # Définir les limites pour les valeurs aberrantes
                $LowerBound = $Q1 - ($Multiplier * $IQR)
                $UpperBound = $Q3 + ($Multiplier * $IQR)
                
                # Identifier les valeurs aberrantes
                $GroupOutliers = $Group.Group | Where-Object { 
                    [double]$_.$ValueColumn -lt $LowerBound -or [double]$_.$ValueColumn -gt $UpperBound 
                }
                
                foreach ($Outlier in $GroupOutliers) {
                    $Outliers += [PSCustomObject]@{
                        Group = $Group.Name
                        Value = [double]$Outlier.$ValueColumn
                        LowerBound = $LowerBound
                        UpperBound = $UpperBound
                        Deviation = if ([double]$Outlier.$ValueColumn -lt $LowerBound) {
                            ([double]$Outlier.$ValueColumn - $LowerBound) / $IQR
                        } else {
                            ([double]$Outlier.$ValueColumn - $UpperBound) / $IQR
                        }
                        Timestamp = $Outlier.Timestamp
                    }
                }
            }
        } else {
            $Values = $Data | ForEach-Object { [double]$_.$ValueColumn }
            
            # Calculer les quartiles
            $SortedValues = $Values | Sort-Object
            $Q1Index = [math]::Floor($SortedValues.Count * 0.25)
            $Q3Index = [math]::Floor($SortedValues.Count * 0.75)
            $Q1 = $SortedValues[$Q1Index]
            $Q3 = $SortedValues[$Q3Index]
            $IQR = $Q3 - $Q1
            
            # Définir les limites pour les valeurs aberrantes
            $LowerBound = $Q1 - ($Multiplier * $IQR)
            $UpperBound = $Q3 + ($Multiplier * $IQR)
            
            # Identifier les valeurs aberrantes
            $DataOutliers = $Data | Where-Object { 
                [double]$_.$ValueColumn -lt $LowerBound -or [double]$_.$ValueColumn -gt $UpperBound 
            }
            
            foreach ($Outlier in $DataOutliers) {
                $Outliers += [PSCustomObject]@{
                    Group = "All"
                    Value = [double]$Outlier.$ValueColumn
                    LowerBound = $LowerBound
                    UpperBound = $UpperBound
                    Deviation = if ([double]$Outlier.$ValueColumn -lt $LowerBound) {
                        ([double]$Outlier.$ValueColumn - $LowerBound) / $IQR
                    } else {
                        ([double]$Outlier.$ValueColumn - $UpperBound) / $IQR
                    }
                    Timestamp = $Outlier.Timestamp
                }
            }
        }
        
        Write-Log -Message "Détection terminée: $($Outliers.Count) anomalies identifiées" -Level "Info"
        return $Outliers
    } catch {
        Write-Log -Message "Erreur lors de la détection des anomalies par IQR: $_" -Level "Error"
        return $null
    }
}

# Fonction pour détecter les anomalies par la méthode Z-Score
function Get-ZScoreOutliers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$ValueColumn,
        
        [Parameter(Mandatory=$false)]
        [string]$GroupColumn,
        
        [Parameter(Mandatory=$false)]
        [double]$Threshold = 3.0
    )
    
    Write-Log -Message "Détection des anomalies par méthode Z-Score (Threshold=$Threshold)" -Level "Info"
    
    try {
        # Vérifier si les données sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée à analyser" -Level "Warning"
            return $null
        }
        
        $Outliers = @()
        
        # Grouper les données si nécessaire
        if ($GroupColumn) {
            $GroupedData = $Data | Group-Object -Property $GroupColumn
            
            foreach ($Group in $GroupedData) {
                $Values = $Group.Group | ForEach-Object { [double]$_.$ValueColumn }
                
                # Calculer la moyenne et l'écart-type
                $Mean = ($Values | Measure-Object -Average).Average
                $StdDev = [Math]::Sqrt(($Values | ForEach-Object { [Math]::Pow($_ - $Mean, 2) } | Measure-Object -Average).Average)
                
                if ($StdDev -eq 0) {
                    continue
                }
                
                # Identifier les valeurs aberrantes
                $GroupOutliers = $Group.Group | Where-Object { 
                    $ZScore = [Math]::Abs(([double]$_.$ValueColumn - $Mean) / $StdDev)
                    $ZScore -gt $Threshold
                }
                
                foreach ($Outlier in $GroupOutliers) {
                    $ZScore = ([double]$Outlier.$ValueColumn - $Mean) / $StdDev
                    
                    $Outliers += [PSCustomObject]@{
                        Group = $Group.Name
                        Value = [double]$Outlier.$ValueColumn
                        Mean = $Mean
                        StdDev = $StdDev
                        ZScore = $ZScore
                        Timestamp = $Outlier.Timestamp
                    }
                }
            }
        } else {
            $Values = $Data | ForEach-Object { [double]$_.$ValueColumn }
            
            # Calculer la moyenne et l'écart-type
            $Mean = ($Values | Measure-Object -Average).Average
            $StdDev = [Math]::Sqrt(($Values | ForEach-Object { [Math]::Pow($_ - $Mean, 2) } | Measure-Object -Average).Average)
            
            if ($StdDev -eq 0) {
                Write-Log -Message "Écart-type nul, impossible de calculer les Z-Scores" -Level "Warning"
                return $null
            }
            
            # Identifier les valeurs aberrantes
            $DataOutliers = $Data | Where-Object { 
                $ZScore = [Math]::Abs(([double]$_.$ValueColumn - $Mean) / $StdDev)
                $ZScore -gt $Threshold
            }
            
            foreach ($Outlier in $DataOutliers) {
                $ZScore = ([double]$Outlier.$ValueColumn - $Mean) / $StdDev
                
                $Outliers += [PSCustomObject]@{
                    Group = "All"
                    Value = [double]$Outlier.$ValueColumn
                    Mean = $Mean
                    StdDev = $StdDev
                    ZScore = $ZScore
                    Timestamp = $Outlier.Timestamp
                }
            }
        }
        
        Write-Log -Message "Détection terminée: $($Outliers.Count) anomalies identifiées" -Level "Info"
        return $Outliers
    } catch {
        Write-Log -Message "Erreur lors de la détection des anomalies par Z-Score: $_" -Level "Error"
        return $null
    }
}

# Fonction pour détecter les anomalies par la méthode de la fenêtre glissante
function Get-MovingWindowOutliers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$TimeColumn,
        
        [Parameter(Mandatory=$true)]
        [string]$ValueColumn,
        
        [Parameter(Mandatory=$false)]
        [string]$GroupColumn,
        
        [Parameter(Mandatory=$false)]
        [int]$WindowSize = 10,
        
        [Parameter(Mandatory=$false)]
        [double]$Threshold = 2.0
    )
    
    Write-Log -Message "Détection des anomalies par fenêtre glissante (WindowSize=$WindowSize, Threshold=$Threshold)" -Level "Info"
    
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
        
        $Outliers = @()
        
        # Grouper les données si nécessaire
        if ($GroupColumn) {
            $GroupedData = $Data | Group-Object -Property $GroupColumn
            
            foreach ($Group in $GroupedData) {
                # Trier les données par timestamp
                $SortedData = $Group.Group | Sort-Object -Property $TimeColumn
                
                # Appliquer la fenêtre glissante
                for ($i = $WindowSize; $i -lt $SortedData.Count; $i++) {
                    $WindowData = $SortedData[($i - $WindowSize)..($i - 1)]
                    $CurrentPoint = $SortedData[$i]
                    
                    # Calculer la moyenne et l'écart-type de la fenêtre
                    $WindowValues = $WindowData | ForEach-Object { [double]$_.$ValueColumn }
                    $Mean = ($WindowValues | Measure-Object -Average).Average
                    $StdDev = [Math]::Sqrt(($WindowValues | ForEach-Object { [Math]::Pow($_ - $Mean, 2) } | Measure-Object -Average).Average)
                    
                    if ($StdDev -eq 0) {
                        continue
                    }
                    
                    # Calculer le Z-Score du point courant
                    $ZScore = [Math]::Abs(([double]$CurrentPoint.$ValueColumn - $Mean) / $StdDev)
                    
                    # Vérifier si c'est une anomalie
                    if ($ZScore -gt $Threshold) {
                        $Outliers += [PSCustomObject]@{
                            Group = $Group.Name
                            Value = [double]$CurrentPoint.$ValueColumn
                            Mean = $Mean
                            StdDev = $StdDev
                            ZScore = $ZScore
                            Timestamp = $CurrentPoint.$TimeColumn
                        }
                    }
                }
            }
        } else {
            # Trier les données par timestamp
            $SortedData = $Data | Sort-Object -Property $TimeColumn
            
            # Appliquer la fenêtre glissante
            for ($i = $WindowSize; $i -lt $SortedData.Count; $i++) {
                $WindowData = $SortedData[($i - $WindowSize)..($i - 1)]
                $CurrentPoint = $SortedData[$i]
                
                # Calculer la moyenne et l'écart-type de la fenêtre
                $WindowValues = $WindowData | ForEach-Object { [double]$_.$ValueColumn }
                $Mean = ($WindowValues | Measure-Object -Average).Average
                $StdDev = [Math]::Sqrt(($WindowValues | ForEach-Object { [Math]::Pow($_ - $Mean, 2) } | Measure-Object -Average).Average)
                
                if ($StdDev -eq 0) {
                    continue
                }
                
                # Calculer le Z-Score du point courant
                $ZScore = [Math]::Abs(([double]$CurrentPoint.$ValueColumn - $Mean) / $StdDev)
                
                # Vérifier si c'est une anomalie
                if ($ZScore -gt $Threshold) {
                    $Outliers += [PSCustomObject]@{
                        Group = "All"
                        Value = [double]$CurrentPoint.$ValueColumn
                        Mean = $Mean
                        StdDev = $StdDev
                        ZScore = $ZScore
                        Timestamp = $CurrentPoint.$TimeColumn
                    }
                }
            }
        }
        
        Write-Log -Message "Détection terminée: $($Outliers.Count) anomalies identifiées" -Level "Info"
        return $Outliers
    } catch {
        Write-Log -Message "Erreur lors de la détection des anomalies par fenêtre glissante: $_" -Level "Error"
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
        if ($null -eq $Results -or $Results.Count -eq 0) {
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
function Start-AnomalyDetection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "Début de la détection des anomalies" -Level "Info"
    
    # 1. Charger les données
    $PerformanceDataPath = Join-Path -Path $DataPath -ChildPath "prepared_performance_data.csv"
    $PerformanceData = Import-PerformanceData -FilePath $PerformanceDataPath
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # 2. Détecter les anomalies
    if ($PerformanceData -and $PerformanceData.Count -gt 0) {
        # Méthode IQR
        $IQROutliers = Get-IQROutliers -Data $PerformanceData -ValueColumn "Value" -GroupColumn "Path" -Multiplier 1.5
        if ($IQROutliers -and $IQROutliers.Count -gt 0) {
            $IQROutputPath = Join-Path -Path $OutputPath -ChildPath "iqr_outliers.csv"
            Export-AnalysisResults -Results $IQROutliers -OutputPath $IQROutputPath -Format "CSV"
        }
        
        # Méthode Z-Score
        $ZScoreOutliers = Get-ZScoreOutliers -Data $PerformanceData -ValueColumn "Value" -GroupColumn "Path" -Threshold 3.0
        if ($ZScoreOutliers -and $ZScoreOutliers.Count -gt 0) {
            $ZScoreOutputPath = Join-Path -Path $OutputPath -ChildPath "zscore_outliers.csv"
            Export-AnalysisResults -Results $ZScoreOutliers -OutputPath $ZScoreOutputPath -Format "CSV"
        }
        
        # Méthode de la fenêtre glissante
        $WindowOutliers = Get-MovingWindowOutliers -Data $PerformanceData -TimeColumn "Timestamp" -ValueColumn "Value" -GroupColumn "Path" -WindowSize 10 -Threshold 2.0
        if ($WindowOutliers -and $WindowOutliers.Count -gt 0) {
            $WindowOutputPath = Join-Path -Path $OutputPath -ChildPath "window_outliers.csv"
            Export-AnalysisResults -Results $WindowOutliers -OutputPath $WindowOutputPath -Format "CSV"
        }
        
        # Consolider les résultats
        $AllOutliers = @()
        if ($IQROutliers) { $AllOutliers += $IQROutliers | Add-Member -NotePropertyName Method -NotePropertyValue "IQR" -PassThru }
        if ($ZScoreOutliers) { $AllOutliers += $ZScoreOutliers | Add-Member -NotePropertyName Method -NotePropertyValue "Z-Score" -PassThru }
        if ($WindowOutliers) { $AllOutliers += $WindowOutliers | Add-Member -NotePropertyName Method -NotePropertyValue "Moving Window" -PassThru }
        
        if ($AllOutliers.Count -gt 0) {
            $AllOutputPath = Join-Path -Path $OutputPath -ChildPath "all_outliers.csv"
            Export-AnalysisResults -Results $AllOutliers -OutputPath $AllOutputPath -Format "CSV"
        }
    } else {
        Write-Log -Message "Aucune donnée de performance disponible pour l'analyse" -Level "Warning"
    }
    
    Write-Log -Message "Détection des anomalies terminée" -Level "Info"
    
    return @{
        Success = $true
        IQROutliers = $IQROutliers
        ZScoreOutliers = $ZScoreOutliers
        WindowOutliers = $WindowOutliers
        AllOutliers = $AllOutliers
    }
}

# Exécution du script
$Result = Start-AnomalyDetection -DataPath $DataPath -OutputPath $OutputPath

if ($Result.Success) {
    Write-Log -Message "Détection des anomalies réussie" -Level "Info"
    return 0
} else {
    Write-Log -Message "Échec de la détection des anomalies" -Level "Error"
    return 1
}
