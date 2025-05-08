<#
.SYNOPSIS
    Effectue un échantillonnage adaptatif des données pour l'estimation de densité par noyau.

.DESCRIPTION
    Cette fonction effectue un échantillonnage adaptatif des données pour l'estimation de densité par noyau.
    Elle est particulièrement utile pour les grands ensembles de données, car elle permet de réduire
    le temps de calcul tout en préservant les caractéristiques importantes de la distribution.

.PARAMETER Data
    Les données à échantillonner.

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
    La méthode de stratification à utiliser (par défaut "Quantile").
    - "Quantile": Divise les données en quantiles et échantillonne proportionnellement
    - "Density": Échantillonne en fonction de la densité estimée
    - "Uniform": Échantillonnage uniforme (aléatoire)
    - "Systematic": Échantillonnage systématique (à intervalles réguliers)

.PARAMETER StratificationLevels
    Le nombre de niveaux de stratification (par défaut 10).
    Applicable uniquement pour les méthodes "Quantile" et "Density".

.EXAMPLE
    Get-AdaptiveSampling -Data $data -MaxSampleSize 500
    Effectue un échantillonnage adaptatif des données avec une taille maximale de 500 points.

.EXAMPLE
    Get-AdaptiveSampling -Data $data -StratificationMethod "Density" -PreservationFactor 0.5
    Effectue un échantillonnage adaptatif des données en utilisant la méthode de stratification par densité
    et un facteur de préservation de 0.5.

.OUTPUTS
    System.Double[]
#>
function Get-AdaptiveSampling {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

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
        [ValidateSet("Quantile", "Density", "Uniform", "Systematic")]
        [string]$StratificationMethod = "Quantile",

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 100)]
        [int]$StratificationLevels = 10
    )

    # Si les données sont déjà plus petites que la taille maximale de l'échantillon, les retourner directement
    if ($Data.Count -le $MaxSampleSize) {
        Write-Verbose "Les données contiennent déjà moins de points que la taille maximale de l'échantillon."
        return $Data
    }

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    } else {
        $random = New-Object System.Random
    }

    # Trier les données
    $sortedData = $Data | Sort-Object

    # Préserver les valeurs extrêmes si demandé
    $extremeValues = @()
    if ($PreserveExtremes) {
        $extremeValues += $sortedData[0]  # Minimum
        $extremeValues += $sortedData[-1]  # Maximum
        
        # Calculer l'IQR (écart interquartile)
        $q1Index = [Math]::Floor($sortedData.Count * 0.25)
        $q3Index = [Math]::Floor($sortedData.Count * 0.75)
        $q1 = $sortedData[$q1Index]
        $q3 = $sortedData[$q3Index]
        $iqr = $q3 - $q1
        
        # Identifier les valeurs aberrantes
        $lowerBound = $q1 - 1.5 * $iqr
        $upperBound = $q3 + 1.5 * $iqr
        
        $outliers = $sortedData | Where-Object { $_ -lt $lowerBound -or $_ -gt $upperBound }
        $extremeValues += $outliers
        
        # Limiter le nombre de valeurs aberrantes à préserver
        if ($extremeValues.Count -gt $MaxSampleSize * 0.1) {
            $extremeValues = $extremeValues | Get-Random -Count ($MaxSampleSize * 0.1)
        }
    }

    # Calculer le nombre de points à échantillonner (en tenant compte des valeurs extrêmes déjà préservées)
    $remainingSampleSize = $MaxSampleSize - $extremeValues.Count

    # Échantillonner les données en fonction de la méthode de stratification
    $sampledData = @()
    
    switch ($StratificationMethod) {
        "Quantile" {
            # Diviser les données en quantiles et échantillonner proportionnellement
            $quantileSize = [Math]::Floor($sortedData.Count / $StratificationLevels)
            
            for ($i = 0; $i -lt $StratificationLevels; $i++) {
                $startIndex = $i * $quantileSize
                $endIndex = [Math]::Min(($i + 1) * $quantileSize - 1, $sortedData.Count - 1)
                
                # Calculer le nombre de points à échantillonner dans ce quantile
                $weight = 1 + $PreservationFactor * ($i / ($StratificationLevels - 1))
                $quantileSampleSize = [Math]::Max(1, [Math]::Floor($remainingSampleSize * $weight / ($StratificationLevels + $PreservationFactor * $StratificationLevels / 2)))
                
                # Échantillonner les points dans ce quantile
                $quantileData = $sortedData[$startIndex..$endIndex]
                $sampledQuantile = $quantileData | Get-Random -Count ([Math]::Min($quantileSampleSize, $quantileData.Count))
                
                $sampledData += $sampledQuantile
            }
        }
        "Density" {
            # Estimer la densité pour chaque point
            $bandwidth = 0.9 * (($sortedData | Measure-Object -StandardDeviation).StandardDeviation) * [Math]::Pow($sortedData.Count, -0.2)
            $densities = @()
            
            foreach ($x in $sortedData) {
                $density = 0
                foreach ($xi in $sortedData) {
                    $u = ($x - $xi) / $bandwidth
                    $kernelValue = (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-($u * $u) / 2)
                    $density += $kernelValue
                }
                $density = $density / ($sortedData.Count * $bandwidth)
                $densities += $density
            }
            
            # Normaliser les densités
            $minDensity = ($densities | Measure-Object -Minimum).Minimum
            $maxDensity = ($densities | Measure-Object -Maximum).Maximum
            $normalizedDensities = $densities | ForEach-Object { ($_ - $minDensity) / ($maxDensity - $minDensity) }
            
            # Diviser les données en strates en fonction de la densité
            $strataIndices = @()
            for ($i = 0; $i -lt $StratificationLevels; $i++) {
                $lowerBound = $i / $StratificationLevels
                $upperBound = ($i + 1) / $StratificationLevels
                
                $strataIndices += @(0..($normalizedDensities.Count - 1) | Where-Object { $normalizedDensities[$_] -ge $lowerBound -and $normalizedDensities[$_] -lt $upperBound })
            }
            
            # Échantillonner proportionnellement à la densité
            foreach ($stratum in $strataIndices) {
                if ($stratum.Count -eq 0) {
                    continue
                }
                
                $weight = 1 + $PreservationFactor * ($stratum.Count / $sortedData.Count)
                $stratumSampleSize = [Math]::Max(1, [Math]::Floor($remainingSampleSize * $weight / $StratificationLevels))
                
                $stratumData = $stratum | ForEach-Object { $sortedData[$_] }
                $sampledStratum = $stratumData | Get-Random -Count ([Math]::Min($stratumSampleSize, $stratumData.Count))
                
                $sampledData += $sampledStratum
            }
        }
        "Uniform" {
            # Échantillonnage uniforme (aléatoire)
            $sampledData = $sortedData | Get-Random -Count $remainingSampleSize
        }
        "Systematic" {
            # Échantillonnage systématique (à intervalles réguliers)
            $step = $sortedData.Count / $remainingSampleSize
            
            for ($i = 0; $i -lt $remainingSampleSize; $i++) {
                $index = [Math]::Min([Math]::Floor($i * $step), $sortedData.Count - 1)
                $sampledData += $sortedData[$index]
            }
        }
    }

    # Combiner les valeurs extrêmes et les données échantillonnées
    $result = $extremeValues + $sampledData
    
    # Limiter la taille de l'échantillon au maximum spécifié
    if ($result.Count -gt $MaxSampleSize) {
        $result = $result | Get-Random -Count $MaxSampleSize
    }
    
    Write-Verbose "Échantillonnage adaptatif terminé. Taille de l'échantillon: $($result.Count) (original: $($Data.Count))"
    
    return $result
}
