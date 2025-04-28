<#
.SYNOPSIS
    Script de calcul des indicateurs clÃ©s de performance (KPIs) applicatifs - Partie 2.
.DESCRIPTION
    Calcule les KPIs applicatifs Ã  partir des donnÃ©es de performance collectÃ©es.
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
        [string]$SourceColumn = "Path"
    )
    
    try {
        # Filtrer les donnÃ©es pour la source spÃ©cifiÃ©e
        $SourceData = $Data | Where-Object { $_.$SourceColumn -like "*$Source*" }
        
        if (-not $SourceData -or $SourceData.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e trouvÃ©e pour la source: $Source" -Level "Warning"
            return $null
        }
        
        # Convertir les valeurs en nombres
        $Values = $SourceData | ForEach-Object { [double]$_.$ValueColumn }
        
        # Calculer le KPI selon la formule spÃ©cifiÃ©e
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
            "P95" {
                $SortedValues = $Values | Sort-Object
                $Index = [Math]::Ceiling($SortedValues.Count * 0.95) - 1
                $Result = $SortedValues[$Index]
            }
            "P99" {
                $SortedValues = $Values | Sort-Object
                $Index = [Math]::Ceiling($SortedValues.Count * 0.99) - 1
                $Result = $SortedValues[$Index]
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
        [string]$SourceColumn = "Path"
    )
    
    try {
        if ($Sources.Count -ne 2) {
            Write-Log -Message "Le calcul de pourcentage nÃ©cessite exactement 2 sources" -Level "Error"
            return $null
        }
        
        # Calculer les valeurs pour chaque source
        $Numerator = Get-SimpleKpi -Data $Data -Source $Sources[0] -Formula "SUM" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
        $Denominator = Get-SimpleKpi -Data $Data -Source $Sources[1] -Formula "SUM" -TimeColumn $TimeColumn -ValueColumn $ValueColumn -SourceColumn $SourceColumn
        
        if ($null -eq $Numerator -or $null -eq $Denominator -or $Denominator -eq 0) {
            Write-Log -Message "Impossible de calculer le pourcentage: numÃ©rateur=$Numerator, dÃ©nominateur=$Denominator" -Level "Warning"
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
        [string]$SourceColumn = "Path"
    )
    
    try {
        if ($Sources.Count -ne $Weights.Count) {
            Write-Log -Message "Le nombre de sources et de poids doit Ãªtre identique" -Level "Error"
            return $null
        }
        
        $WeightSum = ($Weights | Measure-Object -Sum).Sum
        if ([Math]::Abs($WeightSum - 1) -gt 0.001) {
            Write-Log -Message "La somme des poids doit Ãªtre Ã©gale Ã  1" -Level "Warning"
            # Normaliser les poids
            $Weights = $Weights | ForEach-Object { $_ / $WeightSum }
        }
        
        $CompositeValue = 0
        $ValidComponents = 0
        
        for ($i = 0; $i -lt $Sources.Count; $i++) {
            $Source = $Sources[$i]
            $Weight = $Weights[$i]
            
            # Utiliser la valeur prÃ©calculÃ©e si disponible
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
        
        # Ajuster le rÃ©sultat en fonction du nombre de composantes valides
        $CompositeValue = $CompositeValue * ($Sources.Count / $ValidComponents)
        
        return $CompositeValue
    } catch {
        Write-Log -Message "Erreur lors du calcul du KPI composite: $_" -Level "Error"
        return $null
    }
}
