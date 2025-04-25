<#
.SYNOPSIS
    Script de calcul des indicateurs clés de performance (KPIs) métier - Partie 2.
.DESCRIPTION
    Calcule les KPIs métier à partir des données collectées.
    Cette partie contient les fonctions de calcul des KPIs.
#>

# Fonction pour calculer un KPI simple
function Get-SimpleKpi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$Source,
        
        [Parameter(Mandatory=$true)]
        [string]$Formula,
        
        [Parameter(Mandatory=$false)]
        [string]$TimeColumn = "Timestamp",
        
        [Parameter(Mandatory=$false)]
        [string]$ValueColumn = "Value",
        
        [Parameter(Mandatory=$false)]
        [string]$SourceColumn = "Metric"
    )
    
    try {
        # Filtrer les données pour la source spécifiée
        $SourceData = $Data | Where-Object { $_.$SourceColumn -eq $Source }
        
        if (-not $SourceData -or $SourceData.Count -eq 0) {
            Write-Log -Message "Aucune donnée trouvée pour la source: $Source" -Level "Warning"
            return $null
        }
        
        # Convertir les valeurs en nombres
        $Values = $SourceData | ForEach-Object { [double]$_.$ValueColumn }
        
        # Calculer le KPI selon la formule spécifiée
        switch ($Formula) {
            "AVG" {
                $Result = ($Values | Measure-Object -Average).Average
            }
            "MAX" {
                $Result = ($Values | Measure-Object -Maximum).Maximum
            }
            "MIN" {
                $Result = ($Values | Measure-Object -Minimum).Minimum
            }
            "SUM" {
                $Result = ($Values | Measure-Object -Sum).Sum
            }
            "COUNT" {
                $Result = $Values.Count
            }
            "MEDIAN" {
                $SortedValues = $Values | Sort-Object
                $Count = $SortedValues.Count
                if ($Count -eq 0) {
                    $Result = $null
                } elseif ($Count % 2 -eq 0) {
                    $Result = ($SortedValues[$Count/2 - 1] + $SortedValues[$Count/2]) / 2
                } else {
                    $Result = $SortedValues[[Math]::Floor($Count/2)]
                }
            }
            "LAST" {
                # Trier par timestamp et prendre la dernière valeur
                $SortedData = $SourceData | Sort-Object -Property $TimeColumn
                $Result = [double]($SortedData | Select-Object -Last 1).$ValueColumn
            }
            default {
                Write-Log -Message "Formule non prise en charge: $Formula" -Level "Error"
                $Result = $null
            }
        }
        
        return $Result
    } catch {
        Write-Log -Message "Erreur lors du calcul du KPI simple: $_" -Level "Error"
        return $null
    }
}

# Fonction pour calculer un KPI de pourcentage
function Get-PercentageKpi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Sources,
        
        [Parameter(Mandatory=$false)]
        [string]$TimeColumn = "Timestamp",
        
        [Parameter(Mandatory=$false)]
        [string]$ValueColumn = "Value",
        
        [Parameter(Mandatory=$false)]
        [string]$SourceColumn = "Metric"
    )
    
    try {
        if ($Sources.Count -ne 2) {
            Write-Log -Message "Le calcul de pourcentage nécessite exactement 2 sources" -Level "Error"
            return $null
        }
        
        # Calculer les valeurs pour chaque source
        $Numerator = Get-SimpleKpi -Data $Data -Source $Sources[0] -Formula "SUM" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
        $Denominator = Get-SimpleKpi -Data $Data -Source $Sources[1] -Formula "SUM" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
        
        if ($null -eq $Numerator -or $null -eq $Denominator -or $Denominator -eq 0) {
            Write-Log -Message "Impossible de calculer le pourcentage: numérateur=$Numerator, dénominateur=$Denominator" -Level "Warning"
            return $null
        }
        
        # Calculer le pourcentage
        $Percentage = ($Numerator / $Denominator) * 100
        
        return $Percentage
    } catch {
        Write-Log -Message "Erreur lors du calcul du KPI de pourcentage: $_" -Level "Error"
        return $null
    }
}

# Fonction pour calculer un KPI de ratio
function Get-RatioKpi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Sources,
        
        [Parameter(Mandatory=$false)]
        [string]$TimeColumn = "Timestamp",
        
        [Parameter(Mandatory=$false)]
        [string]$ValueColumn = "Value",
        
        [Parameter(Mandatory=$false)]
        [string]$SourceColumn = "Metric"
    )
    
    try {
        if ($Sources.Count -ne 2) {
            Write-Log -Message "Le calcul de ratio nécessite exactement 2 sources" -Level "Error"
            return $null
        }
        
        # Calculer les valeurs pour chaque source
        $Numerator = Get-SimpleKpi -Data $Data -Source $Sources[0] -Formula "SUM" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
        $Denominator = Get-SimpleKpi -Data $Data -Source $Sources[1] -Formula "SUM" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
        
        if ($null -eq $Numerator -or $null -eq $Denominator -or $Denominator -eq 0) {
            Write-Log -Message "Impossible de calculer le ratio: numérateur=$Numerator, dénominateur=$Denominator" -Level "Warning"
            return $null
        }
        
        # Calculer le ratio
        $Ratio = $Numerator / $Denominator
        
        return $Ratio
    } catch {
        Write-Log -Message "Erreur lors du calcul du KPI de ratio: $_" -Level "Error"
        return $null
    }
}

# Fonction pour calculer un KPI de croissance
function Get-GrowthKpi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Sources,
        
        [Parameter(Mandatory=$false)]
        [string]$TimeColumn = "Timestamp",
        
        [Parameter(Mandatory=$false)]
        [string]$ValueColumn = "Value",
        
        [Parameter(Mandatory=$false)]
        [string]$SourceColumn = "Metric"
    )
    
    try {
        if ($Sources.Count -ne 2) {
            Write-Log -Message "Le calcul de croissance nécessite exactement 2 sources" -Level "Error"
            return $null
        }
        
        # Calculer les valeurs pour chaque source
        $Current = Get-SimpleKpi -Data $Data -Source $Sources[0] -Formula "LAST" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
        $Previous = Get-SimpleKpi -Data $Data -Source $Sources[1] -Formula "LAST" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
        
        if ($null -eq $Current -or $null -eq $Previous -or $Previous -eq 0) {
            Write-Log -Message "Impossible de calculer la croissance: actuel=$Current, précédent=$Previous" -Level "Warning"
            return $null
        }
        
        # Calculer le taux de croissance
        $Growth = (($Current - $Previous) / $Previous) * 100
        
        return $Growth
    } catch {
        Write-Log -Message "Erreur lors du calcul du KPI de croissance: $_" -Level "Error"
        return $null
    }
}

# Fonction pour calculer un KPI personnalisé
function Get-CustomKpi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Sources,
        
        [Parameter(Mandatory=$true)]
        [string]$CustomFormula,
        
        [Parameter(Mandatory=$false)]
        [string]$TimeColumn = "Timestamp",
        
        [Parameter(Mandatory=$false)]
        [string]$ValueColumn = "Value",
        
        [Parameter(Mandatory=$false)]
        [string]$SourceColumn = "Metric"
    )
    
    try {
        # Créer un hashtable pour stocker les valeurs des sources
        $Values = @{}
        
        # Calculer les valeurs pour chaque source
        foreach ($Source in $Sources) {
            $Value = Get-SimpleKpi -Data $Data -Source $Source -Formula "SUM" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
            
            if ($null -eq $Value) {
                Write-Log -Message "Impossible de calculer la valeur pour la source: $Source" -Level "Warning"
                return $null
            }
            
            $Values[$Source] = $Value
        }
        
        # Remplacer les noms de sources par leurs valeurs dans la formule
        $EvaluableFormula = $CustomFormula
        foreach ($Source in $Sources) {
            $EvaluableFormula = $EvaluableFormula -replace $Source, $Values[$Source]
        }
        
        # Évaluer la formule
        $Result = Invoke-Expression $EvaluableFormula
        
        return $Result
    } catch {
        Write-Log -Message "Erreur lors du calcul du KPI personnalisé: $_" -Level "Error"
        return $null
    }
}

# Fonction pour calculer un KPI composite
function Get-CompositeKpi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Sources,
        
        [Parameter(Mandatory=$true)]
        [double[]]$Weights,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$KpiValues = @{},
        
        [Parameter(Mandatory=$false)]
        [string]$TimeColumn = "Timestamp",
        
        [Parameter(Mandatory=$false)]
        [string]$ValueColumn = "Value",
        
        [Parameter(Mandatory=$false)]
        [string]$SourceColumn = "Metric"
    )
    
    try {
        if ($Sources.Count -ne $Weights.Count) {
            Write-Log -Message "Le nombre de sources et de poids doit être identique" -Level "Error"
            return $null
        }
        
        $WeightSum = ($Weights | Measure-Object -Sum).Sum
        if ([Math]::Abs($WeightSum - 1) -gt 0.001) {
            Write-Log -Message "La somme des poids doit être égale à 1" -Level "Warning"
            # Normaliser les poids
            $Weights = $Weights | ForEach-Object { $_ / $WeightSum }
        }
        
        $CompositeValue = 0
        $ValidComponents = 0
        
        for ($i = 0; $i -lt $Sources.Count; $i++) {
            $Source = $Sources[$i]
            $Weight = $Weights[$i]
            
            # Utiliser la valeur précalculée si disponible
            if ($KpiValues.ContainsKey($Source)) {
                $SourceValue = $KpiValues[$Source]
            } else {
                # Sinon, calculer la valeur
                $SourceValue = Get-SimpleKpi -Data $Data -Source $Source -Formula "AVG" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
            }
            
            if ($null -ne $SourceValue) {
                # Normaliser la valeur (supposer que les valeurs sont entre 0 et 100)
                $NormalizedValue = $SourceValue / 100
                $CompositeValue += $NormalizedValue * $Weight
                $ValidComponents++
            }
        }
        
        if ($ValidComponents -eq 0) {
            Write-Log -Message "Aucune composante valide pour le calcul du KPI composite" -Level "Warning"
            return $null
        }
        
        # Ajuster le résultat en fonction du nombre de composantes valides
        $CompositeValue = $CompositeValue * ($Sources.Count / $ValidComponents)
        
        return $CompositeValue
    } catch {
        Write-Log -Message "Erreur lors du calcul du KPI composite: $_" -Level "Error"
        return $null
    }
}
