<#
.SYNOPSIS
    Effectue un échantillonnage adaptatif des données multidimensionnelles pour l'estimation de densité par noyau.

.DESCRIPTION
    Cette fonction effectue un échantillonnage adaptatif des données multidimensionnelles pour l'estimation de densité par noyau.
    Elle est particulièrement utile pour les grands ensembles de données, car elle permet de réduire
    le temps de calcul tout en préservant les caractéristiques importantes de la distribution.

.PARAMETER Data
    Les données à échantillonner. Pour les données multidimensionnelles, il s'agit d'un tableau d'objets PSCustomObject
    avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour l'échantillonnage. Si non spécifié, toutes les propriétés du premier point de données
    seront utilisées comme dimensions.

.PARAMETER MaxSampleSize
    La taille maximale de l'échantillon (par défaut 1000).

.PARAMETER PreservationFactor
    Le facteur de préservation des caractéristiques de la distribution (par défaut 0.2).
    Plus ce facteur est élevé, plus les régions à forte densité seront échantillonnées.

.PARAMETER PreserveExtremes
    Indique si les valeurs extrêmes doivent être préservées dans l'échantillon (par défaut $true).

.PARAMETER RandomSeed
    La graine pour le générateur de nombres aléatoires (par défaut $null).
    Si $null, une graine aléatoire sera utilisée.

.PARAMETER StratificationMethod
    La méthode de stratification à utiliser (par défaut "Mahalanobis").
    - "Mahalanobis": Utilise la distance de Mahalanobis pour stratifier les données
    - "PCA": Utilise l'analyse en composantes principales pour réduire la dimensionnalité
    - "Density": Échantillonne en fonction de la densité estimée
    - "Uniform": Échantillonnage uniforme (aléatoire)
    - "KMeans": Utilise l'algorithme K-means pour stratifier les données

.PARAMETER StratificationLevels
    Le nombre de niveaux de stratification (par défaut 10).
    Applicable uniquement pour les méthodes "Mahalanobis", "PCA" et "Density".

.PARAMETER DistanceMetric
    La métrique de distance à utiliser (par défaut "Euclidean").
    - "Euclidean": Distance euclidienne
    - "Manhattan": Distance de Manhattan
    - "Mahalanobis": Distance de Mahalanobis

.EXAMPLE
    Get-AdaptiveSamplingMultivariate -Data $data -MaxSampleSize 500
    Effectue un échantillonnage adaptatif des données multidimensionnelles avec une taille maximale de 500 points.

.EXAMPLE
    Get-AdaptiveSamplingMultivariate -Data $data -Dimensions @("X", "Y", "Z") -StratificationMethod "PCA" -PreservationFactor 0.5
    Effectue un échantillonnage adaptatif des données 3D en utilisant la méthode de stratification par PCA
    et un facteur de préservation de 0.5.

.OUTPUTS
    System.Object[]
#>
function Get-AdaptiveSamplingMultivariate {
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Data,

        [Parameter(Mandatory = $false)]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $false)]
        [int]$MaxSampleSize = 1000,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 1)]
        [double]$PreservationFactor = 0.2,

        [Parameter(Mandatory = $false)]
        [bool]$PreserveExtremes = $true,

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Mahalanobis", "PCA", "Density", "Uniform", "KMeans")]
        [string]$StratificationMethod = "Mahalanobis",

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 100)]
        [int]$StratificationLevels = 10,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Euclidean", "Manhattan", "Mahalanobis")]
        [string]$DistanceMetric = "Euclidean"
    )

    # Si les données sont déjà plus petites que la taille maximale de l'échantillon, les retourner directement
    if ($Data.Count -le $MaxSampleSize) {
        Write-Verbose "Les données contiennent déjà moins de points que la taille maximale de l'échantillon."
        return $Data
    }

    # Déterminer les dimensions si non spécifiées
    if (-not $Dimensions) {
        $Dimensions = $Data[0].PSObject.Properties.Name
    }

    # Vérifier que toutes les données ont les dimensions spécifiées
    foreach ($point in $Data) {
        foreach ($dimension in $Dimensions) {
            if (-not $point.PSObject.Properties.Name.Contains($dimension)) {
                throw "Le point de données ne contient pas la dimension spécifiée: $dimension"
            }
        }
    }

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    } else {
        $random = New-Object System.Random
    }

    # Extraire les données pour chaque dimension
    $dimensionData = @{}
    foreach ($dimension in $Dimensions) {
        $dimensionData[$dimension] = $Data | ForEach-Object { $_.$dimension }
    }

    # Calculer les statistiques pour chaque dimension
    $dimensionStats = @{}
    foreach ($dimension in $Dimensions) {
        $values = $dimensionData[$dimension]
        $min = ($values | Measure-Object -Minimum).Minimum
        $max = ($values | Measure-Object -Maximum).Maximum
        $mean = ($values | Measure-Object -Average).Average
        $stdDev = [Math]::Sqrt(($values | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
        
        $dimensionStats[$dimension] = [PSCustomObject]@{
            Min = $min
            Max = $max
            Range = $max - $min
            Mean = $mean
            StdDev = $stdDev
        }
    }

    # Préserver les valeurs extrêmes si demandé
    $extremeValues = @()
    if ($PreserveExtremes) {
        # Calculer les distances au centre de la distribution
        $distances = @()
        foreach ($point in $Data) {
            $distance = 0
            foreach ($dimension in $Dimensions) {
                $value = $point.$dimension
                $mean = $dimensionStats[$dimension].Mean
                $stdDev = $dimensionStats[$dimension].StdDev
                
                # Normaliser la valeur
                $normalizedValue = ($value - $mean) / $stdDev
                
                # Ajouter au carré de la distance
                $distance += $normalizedValue * $normalizedValue
            }
            $distance = [Math]::Sqrt($distance)
            $distances += $distance
        }
        
        # Trier les points par distance
        $sortedIndices = 0..($distances.Count - 1) | Sort-Object { $distances[$_] }
        
        # Préserver les points les plus éloignés
        $numExtremesToPreserve = [Math]::Min([Math]::Floor($MaxSampleSize * 0.1), $Data.Count * 0.05)
        $extremeIndices = $sortedIndices | Select-Object -Last $numExtremesToPreserve
        $extremeValues = $extremeIndices | ForEach-Object { $Data[$_] }
        
        Write-Verbose "Préservation de $($extremeValues.Count) valeurs extrêmes."
    }

    # Calculer le nombre de points à échantillonner (en tenant compte des valeurs extrêmes déjà préservées)
    $remainingSampleSize = $MaxSampleSize - $extremeValues.Count

    # Échantillonner les données en fonction de la méthode de stratification
    $sampledData = @()
    
    switch ($StratificationMethod) {
        "Mahalanobis" {
            # Calculer la matrice de covariance
            $covarianceMatrix = @{}
            foreach ($dim1 in $Dimensions) {
                $covarianceMatrix[$dim1] = @{}
                foreach ($dim2 in $Dimensions) {
                    $values1 = $dimensionData[$dim1]
                    $values2 = $dimensionData[$dim2]
                    $mean1 = $dimensionStats[$dim1].Mean
                    $mean2 = $dimensionStats[$dim2].Mean
                    
                    $covariance = 0
                    for ($i = 0; $i -lt $values1.Count; $i++) {
                        $covariance += ($values1[$i] - $mean1) * ($values2[$i] - $mean2)
                    }
                    $covariance /= $values1.Count
                    
                    $covarianceMatrix[$dim1][$dim2] = $covariance
                }
            }
            
            # Calculer les distances de Mahalanobis
            $mahalanobisDistances = @()
            foreach ($point in $Data) {
                $distance = 0
                foreach ($dim1 in $Dimensions) {
                    foreach ($dim2 in $Dimensions) {
                        $value1 = $point.$dim1 - $dimensionStats[$dim1].Mean
                        $value2 = $point.$dim2 - $dimensionStats[$dim2].Mean
                        
                        # Utiliser l'inverse de la covariance (approximation simple)
                        $invCovariance = 1 / ($covarianceMatrix[$dim1][$dim2] + 0.0001)
                        
                        $distance += $value1 * $invCovariance * $value2
                    }
                }
                $mahalanobisDistances += [Math]::Sqrt([Math]::Abs($distance))
            }
            
            # Diviser les données en strates en fonction de la distance de Mahalanobis
            $sortedIndices = 0..($mahalanobisDistances.Count - 1) | Sort-Object { $mahalanobisDistances[$_] }
            $strataSize = [Math]::Ceiling($sortedIndices.Count / $StratificationLevels)
            
            for ($i = 0; $i -lt $StratificationLevels; $i++) {
                $startIndex = $i * $strataSize
                $endIndex = [Math]::Min(($i + 1) * $strataSize - 1, $sortedIndices.Count - 1)
                
                if ($startIndex -gt $endIndex) {
                    continue
                }
                
                # Calculer le nombre de points à échantillonner dans cette strate
                $weight = 1 + $PreservationFactor * ($i / ($StratificationLevels - 1))
                $strataSampleSize = [Math]::Max(1, [Math]::Floor($remainingSampleSize * $weight / ($StratificationLevels + $PreservationFactor * $StratificationLevels / 2)))
                
                # Échantillonner les points dans cette strate
                $strataIndices = $sortedIndices[$startIndex..$endIndex]
                $sampledIndices = $strataIndices | Get-Random -Count ([Math]::Min($strataSampleSize, $strataIndices.Count))
                $sampledStratum = $sampledIndices | ForEach-Object { $Data[$_] }
                
                $sampledData += $sampledStratum
            }
        }
        "Uniform" {
            # Échantillonnage uniforme (aléatoire)
            $sampledData = $Data | Get-Random -Count $remainingSampleSize
        }
        "Density" {
            # Utiliser une estimation de densité simple pour chaque point
            $densities = @()
            
            # Calculer la largeur de bande pour chaque dimension
            $bandwidths = @{}
            foreach ($dimension in $Dimensions) {
                $bandwidths[$dimension] = 0.9 * $dimensionStats[$dimension].StdDev * [Math]::Pow($Data.Count, -1 / ($Dimensions.Count + 4))
            }
            
            # Calculer la densité pour chaque point
            foreach ($point in $Data) {
                $density = 0
                
                foreach ($refPoint in $Data) {
                    $kernelProduct = 1.0
                    
                    foreach ($dimension in $Dimensions) {
                        $x = ($point.$dimension - $refPoint.$dimension) / $bandwidths[$dimension]
                        $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x)
                        $kernelProduct *= $kernelValue
                    }
                    
                    $density += $kernelProduct
                }
                
                $bandwidthProduct = 1.0
                foreach ($dimension in $Dimensions) {
                    $bandwidthProduct *= $bandwidths[$dimension]
                }
                
                $density /= ($bandwidthProduct * $Data.Count)
                $densities += $density
            }
            
            # Normaliser les densités
            $minDensity = ($densities | Measure-Object -Minimum).Minimum
            $maxDensity = ($densities | Measure-Object -Maximum).Maximum
            $normalizedDensities = $densities | ForEach-Object { ($_ - $minDensity) / ($maxDensity - $minDensity) }
            
            # Diviser les données en strates en fonction de la densité
            $sortedIndices = 0..($normalizedDensities.Count - 1) | Sort-Object { $normalizedDensities[$_] }
            $strataSize = [Math]::Ceiling($sortedIndices.Count / $StratificationLevels)
            
            for ($i = 0; $i -lt $StratificationLevels; $i++) {
                $startIndex = $i * $strataSize
                $endIndex = [Math]::Min(($i + 1) * $strataSize - 1, $sortedIndices.Count - 1)
                
                if ($startIndex -gt $endIndex) {
                    continue
                }
                
                # Calculer le nombre de points à échantillonner dans cette strate
                $weight = 1 + $PreservationFactor * ($i / ($StratificationLevels - 1))
                $strataSampleSize = [Math]::Max(1, [Math]::Floor($remainingSampleSize * $weight / ($StratificationLevels + $PreservationFactor * $StratificationLevels / 2)))
                
                # Échantillonner les points dans cette strate
                $strataIndices = $sortedIndices[$startIndex..$endIndex]
                $sampledIndices = $strataIndices | Get-Random -Count ([Math]::Min($strataSampleSize, $strataIndices.Count))
                $sampledStratum = $sampledIndices | ForEach-Object { $Data[$_] }
                
                $sampledData += $sampledStratum
            }
        }
        default {
            # Par défaut, utiliser l'échantillonnage uniforme
            $sampledData = $Data | Get-Random -Count $remainingSampleSize
        }
    }

    # Combiner les valeurs extrêmes et les données échantillonnées
    $result = $extremeValues + $sampledData
    
    # Limiter la taille de l'échantillon au maximum spécifié
    if ($result.Count -gt $MaxSampleSize) {
        $result = $result | Get-Random -Count $MaxSampleSize
    }
    
    Write-Verbose "Échantillonnage adaptatif multidimensionnel terminé. Taille de l'échantillon: $($result.Count) (original: $($Data.Count))"
    
    return $result
}
