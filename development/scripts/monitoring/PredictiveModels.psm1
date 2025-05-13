#Requires -Version 5.1
<#
.SYNOPSIS
    Module de modèles prédictifs pour les métriques système.
.DESCRIPTION
    Ce module fournit des fonctions pour prédire les tendances futures
    des métriques système à partir des données historiques.
.NOTES
    Nom: PredictiveModels.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.3
    Date de création: 2025-05-13
#>

# Variables globales
$script:Models = @{}

# Fonction pour accéder aux modèles
function Get-RegressionModel {
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

# Fonction pour lister tous les modèles
function Get-RegressionModels {
    [CmdletBinding()]
    param ()

    return $script:Models
}

<#
.SYNOPSIS
    Crée un modèle de régression linéaire avancée.
.DESCRIPTION
    Cette fonction crée un modèle de régression linéaire avancée pour prédire
    les valeurs futures d'une métrique à partir des données historiques.
.PARAMETER MetricsData
    Données de métriques historiques obtenues via Get-HistoricalMetricsData.
.PARAMETER MetricName
    Nom de la métrique à analyser.
.PARAMETER ModelName
    Nom du modèle à créer (par défaut: "LinearRegression_<MetricName>").
.PARAMETER PolynomialDegree
    Degré du polynôme pour la régression (par défaut: 1 pour régression linéaire simple).
.PARAMETER SeasonalityPeriod
    Période de saisonnalité à prendre en compte (en heures, par défaut: 0 pour aucune).
.PARAMETER TrendWindowSize
    Taille de la fenêtre pour la détection de tendance (en échantillons, par défaut: 24).
.EXAMPLE
    $historicalData = Get-HistoricalMetricsData -CollectorName "SystemMonitor"
    New-LinearRegressionModel -MetricsData $historicalData -MetricName "CPU_Usage"
.OUTPUTS
    System.String (ModelName)
#>
function New-LinearRegressionModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$MetricsData,

        [Parameter(Mandatory = $true)]
        [string]$MetricName,

        [Parameter(Mandatory = $false)]
        [string]$ModelName = "",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$PolynomialDegree = 1,

        [Parameter(Mandatory = $false)]
        [int]$SeasonalityPeriod = 0,

        [Parameter(Mandatory = $false)]
        [int]$TrendWindowSize = 24
    )

    begin {
        # Générer un nom de modèle par défaut si non spécifié
        if ([string]::IsNullOrEmpty($ModelName)) {
            $ModelName = "LinearRegression_$MetricName"
        }

        Write-Verbose "Création du modèle de régression linéaire '$ModelName' pour la métrique $MetricName"

        if (-not $MetricsData.MetricsData.ContainsKey($MetricName)) {
            Write-Error "La métrique $MetricName n'existe pas dans les données fournies."
            return $null
        }

        $metricData = $MetricsData.MetricsData[$MetricName]

        if ($metricData.Values.Count -lt ($PolynomialDegree * 2)) {
            Write-Error "Nombre insuffisant de points de données pour créer un modèle de régression de degré $PolynomialDegree. Minimum requis: $($PolynomialDegree * 2), Disponible: $($metricData.Values.Count)"
            return $null
        }
    }

    process {
        try {
            # Convertir les timestamps en valeurs numériques (secondes depuis l'époque)
            $timestamps = $metricData.Timestamps | ForEach-Object {
                if ($_ -is [string]) {
                    $dt = [DateTime]::Parse($_)
                    $dt.ToUniversalTime().Subtract([DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalSeconds
                } elseif ($_ -is [DateTime]) {
                    $_.ToUniversalTime().Subtract([DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalSeconds
                } else {
                    $_
                }
            }

            $values = $metricData.Values

            # Calculer l'intervalle de temps en heures
            $timestampMin = ($timestamps | Measure-Object -Minimum).Minimum
            $timestampMax = ($timestamps | Measure-Object -Maximum).Maximum
            $timestampRange = $timestampMax - $timestampMin

            if ($timestampRange -eq 0) {
                Write-Error "Toutes les données ont le même timestamp, impossible de créer un modèle de régression."
                return $null
            }

            # Convertir les timestamps en heures depuis le début (index)
            $hoursFromStart = @()
            for ($i = 0; $i -lt $timestamps.Count; $i++) {
                $hoursFromStart += $i
            }

            # Préparer les données pour la régression
            $xData = $hoursFromStart
            $yData = $values

            # Détecter et prendre en compte la saisonnalité si demandé
            $seasonalityComponent = @()
            if ($SeasonalityPeriod -gt 0) {
                # Calculer la composante saisonnière pour chaque point
                $seasonalityComponent = $xData | ForEach-Object {
                    [Math]::Sin(2 * [Math]::PI * $_ / $SeasonalityPeriod)
                }
            }

            # Créer la matrice de design pour la régression polynomiale
            $designMatrix = @()

            for ($i = 0; $i -lt $xData.Count; $i++) {
                $row = @(1) # Terme constant

                # Ajouter les termes polynomiaux
                for ($degree = 1; $degree -le $PolynomialDegree; $degree++) {
                    $row += [Math]::Pow($xData[$i], $degree)
                }

                # Ajouter la composante saisonnière si demandé
                if ($SeasonalityPeriod -gt 0) {
                    $row += $seasonalityComponent[$i]
                    $row += [Math]::Cos(2 * [Math]::PI * $xData[$i] / $normalizedPeriod)
                }

                $designMatrix += , $row
            }

            # Calculer les coefficients de régression (méthode des moindres carrés)
            Write-Verbose "Calcul des coefficients de régression..."
            Write-Verbose "Dimensions de la matrice de design: $($designMatrix.Count) lignes x $($designMatrix[0].Count) colonnes"
            Write-Verbose "Nombre de valeurs cibles: $($yData.Count)"

            $coefficients = Invoke-LeastSquaresRegression -DesignMatrix $designMatrix -YValues $yData

            if ($null -eq $coefficients) {
                Write-Error "Échec du calcul des coefficients de régression."
                return $null
            }

            Write-Verbose "Coefficients calculés: $([string]::Join(', ', $coefficients))"

            # Calculer les valeurs prédites et les résidus
            $predictedValues = @()
            $residuals = @()

            for ($i = 0; $i -lt $designMatrix.Count; $i++) {
                $predicted = 0

                for ($j = 0; $j -lt $coefficients.Count; $j++) {
                    $predicted += $coefficients[$j] * $designMatrix[$i][$j]
                }

                $predictedValues += $predicted
                $residuals += $yData[$i] - $predicted
            }

            # Calculer les métriques de qualité du modèle
            $mean = ($yData | Measure-Object -Average).Average
            $sse = ($residuals | ForEach-Object { [Math]::Pow($_, 2) } | Measure-Object -Sum).Sum
            $sst = ($yData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Sum).Sum

            # Vérifier que SST n'est pas zéro ou trop petit
            if ($sst -lt 1e-10) {
                Write-Warning "La variance totale (SST) est trop petite, impossible de calculer un R² fiable."
                $r2 = 0
            } else {
                $r2 = [Math]::Max(-1, [Math]::Min(1, 1 - ($sse / $sst)))
            }

            $rmse = [Math]::Sqrt($sse / $residuals.Count)

            # Calculer l'erreur moyenne absolue (MAE)
            $mae = ($residuals | ForEach-Object { [Math]::Abs($_) } | Measure-Object -Average).Average

            # Créer le modèle
            $model = @{
                Type              = "LinearRegression"
                Name              = $ModelName
                MetricName        = $MetricName
                PolynomialDegree  = $PolynomialDegree
                SeasonalityPeriod = $SeasonalityPeriod
                Coefficients      = $coefficients
                TimestampMin      = $timestampMin
                TimestampMax      = $timestampMax
                TimestampRange    = $timestampRange
                TimeUnit          = "Hours"
                LastIndex         = $xData.Count - 1
                LastTimestamp     = $metricData.Timestamps[-1].ToString("o")
                R2                = $r2
                RMSE              = $rmse
                MAE               = $mae
                CreatedAt         = Get-Date
                Unit              = $metricData.Unit
            }

            # Stocker le modèle
            $script:Models[$ModelName] = $model
        } catch {
            Write-Error "Erreur lors de la création du modèle de régression linéaire: $_"
            return $null
        }
    }

    end {
        return $ModelName
    }
}

<#
.SYNOPSIS
    Effectue une régression par la méthode des moindres carrés.
.DESCRIPTION
    Fonction interne qui calcule les coefficients de régression
    par la méthode des moindres carrés.
.PARAMETER DesignMatrix
    Matrice de design pour la régression.
.PARAMETER YValues
    Valeurs cibles pour la régression.
.OUTPUTS
    System.Double[]
#>
function Invoke-LeastSquaresRegression {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$DesignMatrix,

        [Parameter(Mandatory = $true)]
        [double[]]$YValues
    )

    try {
        # Vérifier que les dimensions correspondent
        if ($DesignMatrix.Count -ne $YValues.Count) {
            Write-Error "Les dimensions de la matrice de design et des valeurs cibles ne correspondent pas."
            return $null
        }

        # Nombre de lignes et de colonnes
        $n = $DesignMatrix.Count
        $p = $DesignMatrix[0].Count

        # Calculer X^T * X (produit matriciel transposée * matrice)
        $xtx = New-Object 'double[,]' $p, $p

        for ($i = 0; $i -lt $p; $i++) {
            for ($j = 0; $j -lt $p; $j++) {
                $sum = 0
                for ($k = 0; $k -lt $n; $k++) {
                    $sum += $DesignMatrix[$k][$i] * $DesignMatrix[$k][$j]
                }
                $xtx.SetValue($sum, $i, $j)
            }
        }

        # Calculer X^T * Y
        $xty = New-Object 'double[]' $p

        for ($i = 0; $i -lt $p; $i++) {
            $sum = 0
            for ($k = 0; $k -lt $n; $k++) {
                $sum += $DesignMatrix[$k][$i] * $YValues[$k]
            }
            $xty[$i] = $sum
        }

        # Résoudre le système d'équations linéaires (X^T * X) * beta = X^T * Y
        Write-Verbose "Résolution du système d'équations linéaires..."
        Write-Verbose "Dimensions de la matrice xtx: $($xtx.GetLength(0)) x $($xtx.GetLength(1))"
        Write-Verbose "Longueur du vecteur xty: $($xty.Length)"

        $coefficients = Invoke-LinearSystemSolver -A $xtx -b $xty

        if ($null -eq $coefficients) {
            Write-Verbose "La résolution du système linéaire a échoué."
        } else {
            Write-Verbose "Résolution réussie. Nombre de coefficients: $($coefficients.Length)"
        }

        return $coefficients
    } catch {
        Write-Error "Erreur lors de la régression par moindres carrés: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Résout un système d'équations linéaires.
.DESCRIPTION
    Fonction interne qui résout un système d'équations linéaires
    de la forme Ax = b en utilisant la décomposition LU.
.PARAMETER A
    Matrice des coefficients.
.PARAMETER b
    Vecteur des termes constants.
.OUTPUTS
    System.Double[]
#>
function Invoke-LinearSystemSolver {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[, ]]$A,

        [Parameter(Mandatory = $true)]
        [double[]]$b
    )

    try {
        # Vérifier que les dimensions correspondent
        $n = $A.GetLength(0)
        if ($n -ne $A.GetLength(1) -or $n -ne $b.Length) {
            Write-Error "Les dimensions de la matrice A et du vecteur b ne correspondent pas."
            return $null
        }

        # Créer une copie de A et b pour éviter de les modifier
        $A_copy = New-Object 'double[,]' $n, $n
        $b_copy = New-Object 'double[]' $n

        for ($i = 0; $i -lt $n; $i++) {
            $b_copy[$i] = $b[$i]
            for ($j = 0; $j -lt $n; $j++) {
                $A_copy.SetValue($A.GetValue($i, $j), $i, $j)
            }
        }

        # Décomposition LU avec pivotage partiel
        $perm = New-Object 'int[]' $n
        for ($i = 0; $i -lt $n; $i++) {
            $perm[$i] = $i
        }

        for ($k = 0; $k -lt $n - 1; $k++) {
            # Trouver le pivot
            $p = $k
            $max = [Math]::Abs($A_copy.GetValue($k, $k))

            for ($i = $k + 1; $i -lt $n; $i++) {
                if ([Math]::Abs($A_copy.GetValue($i, $k)) -gt $max) {
                    $max = [Math]::Abs($A_copy.GetValue($i, $k))
                    $p = $i
                }
            }

            # Échanger les lignes si nécessaire
            if ($p -ne $k) {
                for ($j = 0; $j -lt $n; $j++) {
                    $temp = $A_copy.GetValue($k, $j)
                    $A_copy.SetValue($A_copy.GetValue($p, $j), $k, $j)
                    $A_copy.SetValue($temp, $p, $j)
                }

                $temp = $b_copy[$k]
                $b_copy[$k] = $b_copy[$p]
                $b_copy[$p] = $temp

                $temp = $perm[$k]
                $perm[$k] = $perm[$p]
                $perm[$p] = $temp
            }

            # Élimination de Gauss
            for ($i = $k + 1; $i -lt $n; $i++) {
                $factor = $A_copy.GetValue($i, $k) / $A_copy.GetValue($k, $k)
                $A_copy.SetValue($factor, $i, $k)

                for ($j = $k + 1; $j -lt $n; $j++) {
                    $A_copy.SetValue($A_copy.GetValue($i, $j) - $factor * $A_copy.GetValue($k, $j), $i, $j)
                }

                $b_copy[$i] -= $factor * $b_copy[$k]
            }
        }

        # Résolution du système triangulaire inférieur Ly = b
        $y = New-Object 'double[]' $n

        for ($i = 0; $i -lt $n; $i++) {
            $sum = $b_copy[$i]

            for ($j = 0; $j -lt $i; $j++) {
                $sum -= $A_copy.GetValue($i, $j) * $y[$j]
            }

            $y[$i] = $sum
        }

        # Résolution du système triangulaire supérieur Ux = y
        $x = New-Object 'double[]' $n

        for ($i = $n - 1; $i -ge 0; $i--) {
            $sum = $y[$i]

            for ($j = $i + 1; $j -lt $n; $j++) {
                $sum -= $A_copy.GetValue($i, $j) * $x[$j]
            }

            $x[$i] = $sum / $A_copy.GetValue($i, $i)
        }

        # Réordonner la solution selon la permutation
        $result = New-Object 'double[]' $n

        for ($i = 0; $i -lt $n; $i++) {
            $result[$perm[$i]] = $x[$i]
        }

        return $result
    } catch {
        Write-Error "Erreur lors de la résolution du système linéaire: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Prédit les valeurs futures d'une métrique à partir d'un modèle de régression.
.DESCRIPTION
    Cette fonction utilise un modèle de régression pour prédire les valeurs futures
    d'une métrique à des timestamps spécifiés.
.PARAMETER ModelName
    Nom du modèle de régression à utiliser.
.PARAMETER Timestamps
    Timestamps pour lesquels prédire les valeurs.
.PARAMETER ConfidenceInterval
    Niveau de confiance pour l'intervalle de prédiction (0-1, par défaut: 0.95).
.EXAMPLE
    $futureTimestamps = @((Get-Date).AddHours(1), (Get-Date).AddHours(2))
    $predictions = Invoke-RegressionPrediction -ModelName "LinearRegression_CPU_Usage" -Timestamps $futureTimestamps
.OUTPUTS
    System.Collections.Hashtable
#>
function Invoke-RegressionPrediction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModelName,

        [Parameter(Mandatory = $true)]
        [DateTime[]]$Timestamps,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 1)]
        [double]$ConfidenceInterval = 0.95
    )

    begin {
        Write-Verbose "Prédiction des valeurs futures pour le modèle $ModelName"

        # Récupérer le modèle
        $model = Get-RegressionModel -ModelName $ModelName

        if ($null -eq $model) {
            Write-Error "Le modèle $ModelName n'existe pas."
            return $null
        }

        # Vérifier que le modèle est de type régression linéaire
        if ($model.Type -ne "LinearRegression") {
            Write-Error "Le modèle $ModelName n'est pas un modèle de régression linéaire."
            return $null
        }
    }

    process {
        try {
            $predictions = @()

            foreach ($timestamp in $Timestamps) {
                # Convertir le timestamp en valeur numérique (secondes depuis l'époque)
                $timestampValue = $timestamp.ToUniversalTime().Subtract([DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)).TotalSeconds

                # Vérifier si le timestamp est dans la plage du modèle
                $isExtrapolation = $timestampValue -lt $model.TimestampMin -or $timestampValue -gt $model.TimestampMax

                # Calculer l'index (heures depuis le début)
                # Pour les prédictions futures, nous utilisons simplement l'index suivant
                # Si le dernier point de données est à l'index 23 (24 points), alors le prochain point est à l'index 24, 25, etc.
                $hoursSinceStart = 0

                if ($model.TimeUnit -eq "Hours") {
                    # Calculer combien d'heures se sont écoulées depuis le dernier point de données
                    $lastKnownTimestamp = [DateTime]::FromBinary([DateTime]::Parse($model.LastTimestamp).ToBinary())
                    $hoursDiff = ($timestamp - $lastKnownTimestamp).TotalHours
                    $hoursSinceStart = $model.LastIndex + $hoursDiff
                } else {
                    # Fallback: utiliser l'index directement
                    $hoursSinceStart = $model.LastIndex + 1
                }

                # Créer le vecteur de caractéristiques
                $features = @(1) # Terme constant

                # Ajouter les termes polynomiaux
                for ($degree = 1; $degree -le $model.PolynomialDegree; $degree++) {
                    $features += [Math]::Pow($hoursSinceStart, $degree)
                }

                # Ajouter la composante saisonnière si présente dans le modèle
                if ($model.SeasonalityPeriod -gt 0) {
                    $features += [Math]::Sin(2 * [Math]::PI * $hoursSinceStart / $model.SeasonalityPeriod)
                    $features += [Math]::Cos(2 * [Math]::PI * $hoursSinceStart / $model.SeasonalityPeriod)
                }

                # Calculer la prédiction
                $predictedValue = 0

                for ($i = 0; $i -lt $model.Coefficients.Count; $i++) {
                    $predictedValue += $model.Coefficients[$i] * $features[$i]
                }

                # Calculer l'intervalle de confiance
                # Approximation de l'inverse de la fonction d'erreur pour les niveaux de confiance courants
                $zScore = 0.0

                if ($ConfidenceInterval -ge 0.99) { $zScore = 2.576 } # 99%
                elseif ($ConfidenceInterval -ge 0.98) { $zScore = 2.326 } # 98%
                elseif ($ConfidenceInterval -ge 0.95) { $zScore = 1.96 } # 95%
                elseif ($ConfidenceInterval -ge 0.90) { $zScore = 1.645 } # 90%
                elseif ($ConfidenceInterval -ge 0.85) { $zScore = 1.44 } # 85%
                elseif ($ConfidenceInterval -ge 0.80) { $zScore = 1.282 } # 80%
                elseif ($ConfidenceInterval -ge 0.75) { $zScore = 1.15 } # 75%
                elseif ($ConfidenceInterval -ge 0.70) { $zScore = 1.036 } # 70%
                elseif ($ConfidenceInterval -ge 0.65) { $zScore = 0.935 } # 65%
                elseif ($ConfidenceInterval -ge 0.60) { $zScore = 0.842 } # 60%
                else { $zScore = 1.0 } # Valeur par défaut

                $confidenceWidth = $model.RMSE * $zScore

                # Ajouter la prédiction au résultat
                $predictions += @{
                    Timestamp       = $timestamp
                    PredictedValue  = $predictedValue
                    LowerBound      = $predictedValue - $confidenceWidth
                    UpperBound      = $predictedValue + $confidenceWidth
                    IsExtrapolation = $isExtrapolation
                }
            }

            # Créer le résultat
            $result = @{
                ModelName          = $ModelName
                MetricName         = $model.MetricName
                Unit               = $model.Unit
                Predictions        = $predictions
                ConfidenceInterval = $ConfidenceInterval
            }

            return $result
        } catch {
            Write-Error "Erreur lors de la prédiction: $_"
            return $null
        }
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function New-LinearRegressionModel, Get-RegressionModel, Get-RegressionModels, Invoke-RegressionPrediction
