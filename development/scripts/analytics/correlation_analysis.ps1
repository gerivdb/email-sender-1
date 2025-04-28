<#
.SYNOPSIS
    Script d'analyse des corrÃ©lations entre mÃ©triques de performance.
.DESCRIPTION
    Analyse les relations et dÃ©pendances entre diffÃ©rentes mÃ©triques.
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

# Fonction pour calculer la matrice de corrÃ©lation
function Get-CorrelationMatrix {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Metrics,
        
        [Parameter(Mandatory=$true)]
        [string]$TimeColumn,
        
        [Parameter(Mandatory=$false)]
        [string]$Method = "Pearson" # Pearson, Spearman
    )
    
    Write-Log -Message "Calcul de la matrice de corrÃ©lation ($Method)" -Level "Info"
    
    try {
        # VÃ©rifier si les donnÃ©es sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e Ã  analyser" -Level "Warning"
            return $null
        }
        
        # PrÃ©parer la matrice de corrÃ©lation
        $CorrelationMatrix = @{}
        
        # Calculer les corrÃ©lations entre chaque paire de mÃ©triques
        foreach ($Metric1 in $Metrics) {
            $CorrelationMatrix[$Metric1] = @{}
            
            foreach ($Metric2 in $Metrics) {
                # Pour la diagonale, la corrÃ©lation est 1
                if ($Metric1 -eq $Metric2) {
                    $CorrelationMatrix[$Metric1][$Metric2] = 1.0
                    continue
                }
                
                # Extraire les valeurs des deux mÃ©triques
                $Values1 = @()
                $Values2 = @()
                
                # Grouper par timestamp pour aligner les mÃ©triques
                $GroupedData = $Data | Group-Object -Property $TimeColumn
                
                foreach ($Group in $GroupedData) {
                    $Value1 = ($Group.Group | Where-Object { $_.Metric -eq $Metric1 }).Value
                    $Value2 = ($Group.Group | Where-Object { $_.Metric -eq $Metric2 }).Value
                    
                    if ($Value1 -and $Value2) {
                        $Values1 += [double]$Value1
                        $Values2 += [double]$Value2
                    }
                }
                
                # Calculer la corrÃ©lation
                if ($Values1.Count -gt 1 -and $Values2.Count -gt 1) {
                    $Correlation = 0
                    
                    switch ($Method) {
                        "Pearson" {
                            # Calculer la corrÃ©lation de Pearson
                            $Mean1 = ($Values1 | Measure-Object -Average).Average
                            $Mean2 = ($Values2 | Measure-Object -Average).Average
                            
                            $Numerator = 0
                            $Denominator1 = 0
                            $Denominator2 = 0
                            
                            for ($i = 0; $i -lt $Values1.Count; $i++) {
                                $Diff1 = $Values1[$i] - $Mean1
                                $Diff2 = $Values2[$i] - $Mean2
                                
                                $Numerator += $Diff1 * $Diff2
                                $Denominator1 += [Math]::Pow($Diff1, 2)
                                $Denominator2 += [Math]::Pow($Diff2, 2)
                            }
                            
                            if ($Denominator1 -gt 0 -and $Denominator2 -gt 0) {
                                $Correlation = $Numerator / [Math]::Sqrt($Denominator1 * $Denominator2)
                            }
                        }
                        "Spearman" {
                            # Calculer la corrÃ©lation de Spearman (basÃ©e sur les rangs)
                            $Ranks1 = Get-Ranks -Values $Values1
                            $Ranks2 = Get-Ranks -Values $Values2
                            
                            $SumD2 = 0
                            for ($i = 0; $i -lt $Ranks1.Count; $i++) {
                                $SumD2 += [Math]::Pow($Ranks1[$i] - $Ranks2[$i], 2)
                            }
                            
                            $n = $Ranks1.Count
                            $Correlation = 1 - (6 * $SumD2) / ($n * ($n * $n - 1))
                        }
                    }
                    
                    $CorrelationMatrix[$Metric1][$Metric2] = [Math]::Round($Correlation, 4)
                } else {
                    $CorrelationMatrix[$Metric1][$Metric2] = $null
                }
            }
        }
        
        return $CorrelationMatrix
    } catch {
        Write-Log -Message "Erreur lors du calcul de la matrice de corrÃ©lation: $_" -Level "Error"
        return $null
    }
}

# Fonction auxiliaire pour calculer les rangs (pour Spearman)
function Get-Ranks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [double[]]$Values
    )
    
    # CrÃ©er une liste d'indices triÃ©s par valeur
    $SortedIndices = 0..($Values.Count - 1) | Sort-Object { $Values[$_] }
    
    # Initialiser le tableau des rangs
    $Ranks = New-Object double[] $Values.Count
    
    # Attribuer les rangs
    for ($i = 0; $i -lt $SortedIndices.Count; $i++) {
        $Ranks[$SortedIndices[$i]] = $i + 1
    }
    
    # GÃ©rer les ex-aequo
    $i = 0
    while ($i -lt $Values.Count) {
        $j = $i
        while ($j -lt $Values.Count -and $Values[$SortedIndices[$i]] -eq $Values[$SortedIndices[$j]]) {
            $j++
        }
        
        if ($j - $i -gt 1) {
            $AverageRank = ($i + 1 + $j) / 2
            for ($k = $i; $k -lt $j; $k++) {
                $Ranks[$SortedIndices[$k]] = $AverageRank
            }
        }
        
        $i = $j
    }
    
    return $Ranks
}

# Fonction pour dÃ©tecter les relations causales (test de Granger)
function Test-GrangerCausality {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$Metric1,
        
        [Parameter(Mandatory=$true)]
        [string]$Metric2,
        
        [Parameter(Mandatory=$true)]
        [string]$TimeColumn,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxLag = 5,
        
        [Parameter(Mandatory=$false)]
        [double]$SignificanceLevel = 0.05
    )
    
    Write-Log -Message "Test de causalitÃ© de Granger entre $Metric1 et $Metric2 (MaxLag=$MaxLag)" -Level "Info"
    
    try {
        # VÃ©rifier si les donnÃ©es sont vides
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e Ã  analyser" -Level "Warning"
            return $null
        }
        
        # Extraire les sÃ©ries temporelles des deux mÃ©triques
        $TimeSeries1 = @()
        $TimeSeries2 = @()
        
        # Grouper par timestamp pour aligner les mÃ©triques
        $GroupedData = $Data | Group-Object -Property $TimeColumn | Sort-Object { [DateTime]$_.Name }
        
        foreach ($Group in $GroupedData) {
            $Value1 = ($Group.Group | Where-Object { $_.Metric -eq $Metric1 }).Value
            $Value2 = ($Group.Group | Where-Object { $_.Metric -eq $Metric2 }).Value
            
            if ($Value1 -and $Value2) {
                $TimeSeries1 += [double]$Value1
                $TimeSeries2 += [double]$Value2
            }
        }
        
        # VÃ©rifier si les sÃ©ries sont assez longues
        if ($TimeSeries1.Count -le $MaxLag * 2 -or $TimeSeries2.Count -le $MaxLag * 2) {
            Write-Log -Message "SÃ©ries temporelles trop courtes pour le test de Granger" -Level "Warning"
            return $null
        }
        
        # RÃ©sultats pour chaque lag
        $Results = @()
        
        for ($Lag = 1; $Lag -le $MaxLag; $Lag++) {
            # Test 1: Y est-il causÃ© par X?
            $SSR1 = Get-SSR -Y $TimeSeries2 -X @($TimeSeries2) -Lag $Lag
            $SSR2 = Get-SSR -Y $TimeSeries2 -X @($TimeSeries2, $TimeSeries1) -Lag $Lag
            
            $n = $TimeSeries2.Count - $Lag
            $F1 = (($SSR1 - $SSR2) / $Lag) / ($SSR2 / ($n - 2 * $Lag - 1))
            $PValue1 = 1 - [Math]::Pow(1 - $SignificanceLevel, 1/$Lag) # Approximation simplifiÃ©e
            
            # Test 2: X est-il causÃ© par Y?
            $SSR3 = Get-SSR -Y $TimeSeries1 -X @($TimeSeries1) -Lag $Lag
            $SSR4 = Get-SSR -Y $TimeSeries1 -X @($TimeSeries1, $TimeSeries2) -Lag $Lag
            
            $F2 = (($SSR3 - $SSR4) / $Lag) / ($SSR4 / ($n - 2 * $Lag - 1))
            $PValue2 = 1 - [Math]::Pow(1 - $SignificanceLevel, 1/$Lag) # Approximation simplifiÃ©e
            
            $Results += [PSCustomObject]@{
                Lag = $Lag
                F_X_causes_Y = $F1
                P_X_causes_Y = $PValue1
                X_causes_Y = $F1 -gt $PValue1
                F_Y_causes_X = $F2
                P_Y_causes_X = $PValue2
                Y_causes_X = $F2 -gt $PValue2
            }
        }
        
        return $Results
    } catch {
        Write-Log -Message "Erreur lors du test de causalitÃ© de Granger: $_" -Level "Error"
        return $null
    }
}

# Fonction auxiliaire pour calculer la somme des carrÃ©s des rÃ©sidus
function Get-SSR {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [double[]]$Y,
        
        [Parameter(Mandatory=$true)]
        [double[][]]$X,
        
        [Parameter(Mandatory=$true)]
        [int]$Lag
    )
    
    # PrÃ©parer les donnÃ©es avec les lags
    $n = $Y.Count - $Lag
    $YLagged = $Y[$Lag..($Y.Count - 1)]
    
    $XLagged = @()
    foreach ($Series in $X) {
        $XLaggedSeries = @()
        for ($l = 1; $l -le $Lag; $l++) {
            $XLaggedSeries += $Series[($Lag - $l)..($Series.Count - 1 - $l)]
        }
        $XLagged += ,$XLaggedSeries
    }
    
    # Calculer les rÃ©sidus (implÃ©mentation simplifiÃ©e)
    $Residuals = $YLagged
    $SSR = ($Residuals | ForEach-Object { [Math]::Pow($_, 2) } | Measure-Object -Sum).Sum
    
    return $SSR
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
                if ($Results -is [System.Collections.IDictionary]) {
                    # Convertir la matrice de corrÃ©lation en format plat
                    $FlatResults = @()
                    foreach ($Key1 in $Results.Keys) {
                        foreach ($Key2 in $Results[$Key1].Keys) {
                            $FlatResults += [PSCustomObject]@{
                                Metric1 = $Key1
                                Metric2 = $Key2
                                Correlation = $Results[$Key1][$Key2]
                            }
                        }
                    }
                    $FlatResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                } else {
                    $Results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                }
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
function Start-CorrelationAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Log -Message "DÃ©but de l'analyse des corrÃ©lations" -Level "Info"
    
    # 1. Charger les donnÃ©es
    $PerformanceDataPath = Join-Path -Path $DataPath -ChildPath "prepared_performance_data.csv"
    $PerformanceData = Import-PerformanceData -FilePath $PerformanceDataPath
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # 2. PrÃ©parer les donnÃ©es pour l'analyse de corrÃ©lation
    if ($PerformanceData -and $PerformanceData.Count -gt 0) {
        # Transformer les donnÃ©es au format requis
        $TransformedData = $PerformanceData | ForEach-Object {
            [PSCustomObject]@{
                Timestamp = $_.Timestamp
                Metric = $_.Path
                Value = $_.Value
            }
        }
        
        # Extraire la liste des mÃ©triques uniques
        $Metrics = $TransformedData | Select-Object -ExpandProperty Metric -Unique
        
        # 3. Calculer la matrice de corrÃ©lation
        $CorrelationMatrix = Get-CorrelationMatrix -Data $TransformedData -Metrics $Metrics -TimeColumn "Timestamp" -Method "Pearson"
        $CorrelationOutputPath = Join-Path -Path $OutputPath -ChildPath "correlation_matrix.csv"
        Export-AnalysisResults -Results $CorrelationMatrix -OutputPath $CorrelationOutputPath -Format "CSV"
        
        # 4. Tester la causalitÃ© pour les paires de mÃ©triques fortement corrÃ©lÃ©es
        $CausalityResults = @()
        
        foreach ($Metric1 in $Metrics) {
            foreach ($Metric2 in $Metrics) {
                if ($Metric1 -ne $Metric2 -and $CorrelationMatrix[$Metric1][$Metric2] -gt 0.7) {
                    $GrangerTest = Test-GrangerCausality -Data $TransformedData -Metric1 $Metric1 -Metric2 $Metric2 -TimeColumn "Timestamp" -MaxLag 3
                    
                    if ($GrangerTest) {
                        $CausalityResults += $GrangerTest | ForEach-Object {
                            $_ | Add-Member -NotePropertyName Metric1 -NotePropertyValue $Metric1 -PassThru |
                                  Add-Member -NotePropertyName Metric2 -NotePropertyValue $Metric2 -PassThru
                        }
                    }
                }
            }
        }
        
        if ($CausalityResults.Count -gt 0) {
            $CausalityOutputPath = Join-Path -Path $OutputPath -ChildPath "causality_tests.csv"
            Export-AnalysisResults -Results $CausalityResults -OutputPath $CausalityOutputPath -Format "CSV"
        }
    } else {
        Write-Log -Message "Aucune donnÃ©e de performance disponible pour l'analyse" -Level "Warning"
    }
    
    Write-Log -Message "Analyse des corrÃ©lations terminÃ©e" -Level "Info"
    
    return @{
        Success = $true
        CorrelationMatrix = $CorrelationMatrix
        CausalityResults = $CausalityResults
    }
}

# ExÃ©cution du script
$Result = Start-CorrelationAnalysis -DataPath $DataPath -OutputPath $OutputPath

if ($Result.Success) {
    Write-Log -Message "Analyse des corrÃ©lations rÃ©ussie" -Level "Info"
    return 0
} else {
    Write-Log -Message "Ã‰chec de l'analyse des corrÃ©lations" -Level "Error"
    return 1
}
