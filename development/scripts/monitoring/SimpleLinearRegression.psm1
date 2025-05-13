#Requires -Version 5.1
<#
.SYNOPSIS
    Module de régression linéaire simple pour les métriques système.
.DESCRIPTION
    Ce module fournit des fonctions pour créer des modèles de régression linéaire
    simple et prédire les valeurs futures des métriques système.
.NOTES
    Nom: SimpleLinearRegression.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-13
#>

# Variables globales
$script:Models = @{}

<#
.SYNOPSIS
    Crée un modèle de régression linéaire simple.
.DESCRIPTION
    Cette fonction crée un modèle de régression linéaire simple (y = mx + b)
    à partir d'une série de données.
.PARAMETER XValues
    Valeurs indépendantes (x).
.PARAMETER YValues
    Valeurs dépendantes (y).
.PARAMETER ModelName
    Nom du modèle à créer (par défaut: généré automatiquement).
.EXAMPLE
    $x = @(1, 2, 3, 4, 5)
    $y = @(2, 4, 6, 8, 10)
    New-SimpleLinearModel -XValues $x -YValues $y -ModelName "MyModel"
.OUTPUTS
    System.String (ModelName)
#>
function New-SimpleLinearModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$XValues,
        
        [Parameter(Mandatory = $true)]
        [double[]]$YValues,
        
        [Parameter(Mandatory = $false)]
        [string]$ModelName = ""
    )
    
    begin {
        # Vérifier que les dimensions correspondent
        if ($XValues.Count -ne $YValues.Count) {
            Write-Error "Les dimensions des valeurs X et Y ne correspondent pas."
            return $null
        }
        
        # Générer un nom de modèle par défaut si non spécifié
        if ([string]::IsNullOrEmpty($ModelName)) {
            $ModelName = "SimpleLinearModel_" + [Guid]::NewGuid().ToString("N").Substring(0, 8)
        }
        
        Write-Verbose "Création du modèle de régression linéaire simple '$ModelName'"
    }
    
    process {
        try {
            $n = $XValues.Count
            
            # Calculer les sommes nécessaires
            $sumX = ($XValues | Measure-Object -Sum).Sum
            $sumY = ($YValues | Measure-Object -Sum).Sum
            $sumXY = 0
            $sumX2 = 0
            
            for ($i = 0; $i -lt $n; $i++) {
                $sumXY += $XValues[$i] * $YValues[$i]
                $sumX2 += [Math]::Pow($XValues[$i], 2)
            }
            
            # Calculer la pente (m) et l'ordonnée à l'origine (b)
            $slope = ($n * $sumXY - $sumX * $sumY) / ($n * $sumX2 - [Math]::Pow($sumX, 2))
            $intercept = ($sumY - $slope * $sumX) / $n
            
            # Calculer les valeurs prédites et les résidus
            $predictedValues = @()
            $residuals = @()
            
            for ($i = 0; $i -lt $n; $i++) {
                $predicted = $intercept + $slope * $XValues[$i]
                $predictedValues += $predicted
                $residuals += $YValues[$i] - $predicted
            }
            
            # Calculer les métriques de qualité du modèle
            $yMean = ($YValues | Measure-Object -Average).Average
            $sst = ($YValues | ForEach-Object { [Math]::Pow($_ - $yMean, 2) } | Measure-Object -Sum).Sum
            $sse = ($residuals | ForEach-Object { [Math]::Pow($_, 2) } | Measure-Object -Sum).Sum
            
            $r2 = 1 - ($sse / $sst)
            $rmse = [Math]::Sqrt($sse / $n)
            $mae = ($residuals | ForEach-Object { [Math]::Abs($_) } | Measure-Object -Average).Average
            
            # Créer le modèle
            $model = @{
                Type = "SimpleLinear"
                Name = $ModelName
                Slope = $slope
                Intercept = $intercept
                R2 = $r2
                RMSE = $rmse
                MAE = $mae
                LastX = $XValues[-1]
                N = $n
                CreatedAt = Get-Date
            }
            
            # Stocker le modèle
            $script:Models[$ModelName] = $model
            
            return $ModelName
        }
        catch {
            Write-Error "Erreur lors de la création du modèle de régression linéaire simple: $_"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Récupère un modèle de régression linéaire simple.
.DESCRIPTION
    Cette fonction récupère un modèle de régression linéaire simple
    à partir de son nom.
.PARAMETER ModelName
    Nom du modèle à récupérer.
.EXAMPLE
    $model = Get-SimpleLinearModel -ModelName "MyModel"
.OUTPUTS
    System.Collections.Hashtable
#>
function Get-SimpleLinearModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelName
    )
    
    if (-not $script:Models.ContainsKey($ModelName)) {
        Write-Error "Le modèle '$ModelName' n'existe pas."
        return $null
    }
    
    return $script:Models[$ModelName]
}

<#
.SYNOPSIS
    Prédit des valeurs futures à partir d'un modèle de régression linéaire simple.
.DESCRIPTION
    Cette fonction prédit des valeurs futures à partir d'un modèle
    de régression linéaire simple.
.PARAMETER ModelName
    Nom du modèle à utiliser.
.PARAMETER XValues
    Valeurs indépendantes (x) pour lesquelles prédire les valeurs.
.PARAMETER ConfidenceLevel
    Niveau de confiance pour l'intervalle de prédiction (0-1, par défaut: 0.95).
.EXAMPLE
    $predictions = Invoke-SimpleLinearPrediction -ModelName "MyModel" -XValues @(6, 7, 8)
.OUTPUTS
    System.Collections.Hashtable
#>
function Invoke-SimpleLinearPrediction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelName,
        
        [Parameter(Mandatory = $true)]
        [double[]]$XValues,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 1)]
        [double]$ConfidenceLevel = 0.95
    )
    
    begin {
        # Récupérer le modèle
        $model = Get-SimpleLinearModel -ModelName $ModelName
        
        if ($null -eq $model) {
            return $null
        }
    }
    
    process {
        try {
            $predictions = @()
            
            # Calculer le facteur z pour l'intervalle de confiance
            $zScore = 1.96 # Pour 95% de confiance
            
            if ($ConfidenceLevel -ge 0.99) { $zScore = 2.576 } # 99%
            elseif ($ConfidenceLevel -ge 0.98) { $zScore = 2.326 } # 98%
            elseif ($ConfidenceLevel -ge 0.95) { $zScore = 1.96 } # 95%
            elseif ($ConfidenceLevel -ge 0.90) { $zScore = 1.645 } # 90%
            elseif ($ConfidenceLevel -ge 0.80) { $zScore = 1.282 } # 80%
            
            # Calculer les prédictions
            foreach ($x in $XValues) {
                $predicted = $model.Intercept + $model.Slope * $x
                $confidenceWidth = $model.RMSE * $zScore
                
                $predictions += @{
                    X = $x
                    PredictedValue = $predicted
                    LowerBound = $predicted - $confidenceWidth
                    UpperBound = $predicted + $confidenceWidth
                    IsExtrapolation = $x -gt $model.LastX
                }
            }
            
            # Créer le résultat
            $result = @{
                ModelName = $ModelName
                ModelType = $model.Type
                Predictions = $predictions
                ConfidenceLevel = $ConfidenceLevel
            }
            
            return $result
        }
        catch {
            Write-Error "Erreur lors de la prédiction: $_"
            return $null
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function New-SimpleLinearModel, Get-SimpleLinearModel, Invoke-SimpleLinearPrediction
