<#
.SYNOPSIS
    Implémente le noyau uniforme (rectangular) pour l'estimation de densité par noyau (KDE).

.DESCRIPTION
    Ce module implémente le noyau uniforme (rectangular) pour l'estimation de densité par noyau (KDE).
    Le noyau uniforme est défini par K(u) = 0.5 pour |u| ≤ 1, 0 sinon.
    Ce noyau est le plus simple à calculer mais peut produire des estimations de densité discontinues.

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-16
#>

<#
.SYNOPSIS
    Implémente le noyau uniforme pour l'estimation de densité par noyau (KDE).

.DESCRIPTION
    Cette fonction implémente le noyau uniforme (rectangular) pour l'estimation de densité par noyau (KDE).
    Le noyau uniforme est défini par K(u) = 0.5 pour |u| ≤ 1, 0 sinon.
    Ce noyau est le plus simple à calculer mais peut produire des estimations de densité discontinues.

.PARAMETER U
    La valeur normalisée (x-x_i)/h où x est le point d'évaluation, x_i est un point de données
    et h est la largeur de bande.

.EXAMPLE
    Get-UniformKernel -U 0
    Retourne la valeur du noyau uniforme au point central (0.5).

.EXAMPLE
    Get-UniformKernel -U 1.5
    Retourne la valeur du noyau uniforme à 1.5 écarts-types du centre (0).

.OUTPUTS
    System.Double
#>
function Get-UniformKernel {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [double]$U
    )

    # Noyau uniforme: K(u) = 0.5 pour |u| ≤ 1, 0 sinon
    if ([Math]::Abs($U) -le 1) {
        return 0.5
    } else {
        return 0
    }
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau uniforme.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau uniforme.
    La formule est: f(x) = (1/nh) * Σ K((x-x_i)/h) où K est le noyau uniforme, n est le nombre de points,
    h est la largeur de bande, et x_i sont les points de données.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau uniforme.

.EXAMPLE
    Get-UniformKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau uniforme
    avec une largeur de bande optimale.

.EXAMPLE
    Get-UniformKernelDensity -X 10 -Data $data -Bandwidth 1.5
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau uniforme
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Double
#>
function Get-UniformKernelDensity {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Calculer la largeur de bande optimale si non spécifiée
    if ($Bandwidth -le 0) {
        # Calculer l'écart-type des données
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)

        # Calculer l'écart interquartile
        $sortedData = $Data | Sort-Object
        $n = $Data.Count
        $q1Index = [Math]::Floor($n * 0.25)
        $q3Index = [Math]::Floor($n * 0.75)
        $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]

        # Utiliser le minimum entre l'écart-type et l'écart interquartile normalisé
        $sigma = [Math]::Min($stdDev, $iqr / 1.34)

        # Règle de Silverman ajustée pour le noyau uniforme
        # Le facteur 1.06 est ajusté à 1.3 pour le noyau uniforme
        $Bandwidth = 1.3 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Calculer la densité
    $n = $Data.Count
    $sum = 0

    foreach ($xi in $Data) {
        $u = ($X - $xi) / $Bandwidth
        $kernelValue = Get-UniformKernel -U $u
        $sum += $kernelValue
    }

    $density = $sum / ($n * $Bandwidth)
    return $density
}

<#
.SYNOPSIS
    Teste les fonctions du noyau uniforme.

.DESCRIPTION
    Cette fonction teste les fonctions du noyau uniforme en calculant les valeurs du noyau
    pour différents points et en vérifiant que les résultats sont corrects.

.EXAMPLE
    Test-UniformKernel
    Exécute les tests pour le noyau uniforme.

.OUTPUTS
    None
#>
function Test-UniformKernel {
    [CmdletBinding()]
    param ()

    # Test 1: Valeurs du noyau uniforme
    Write-Host "`n=== Test 1: Valeurs du noyau uniforme ===" -ForegroundColor Magenta
    $testPoints = @(0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5)
    Write-Host "Valeurs du noyau uniforme pour différents points:" -ForegroundColor White
    Write-Host "| Point | Valeur du noyau |" -ForegroundColor White
    Write-Host "|-------|----------------|" -ForegroundColor White
    foreach ($point in $testPoints) {
        $kernelValue = Get-UniformKernel -U $point
        Write-Host "| $point | $([Math]::Round($kernelValue, 6)) |" -ForegroundColor Green
    }

    # Vérifier que la valeur au centre (u=0) est correcte
    $centerValue = Get-UniformKernel -U 0
    $expectedCenterValue = 0.5
    $centerValueCorrect = [Math]::Abs($centerValue - $expectedCenterValue) -lt 0.0001
    Write-Host "`nValeur au centre (u=0): $([Math]::Round($centerValue, 6))" -ForegroundColor White
    Write-Host "Valeur attendue: $([Math]::Round($expectedCenterValue, 6))" -ForegroundColor White
    Write-Host "Résultat: $(if ($centerValueCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($centerValueCorrect) { "Green" } else { "Red" })

    # Vérifier que la valeur à la limite (u=1) est correcte
    $boundaryValue = Get-UniformKernel -U 1
    $expectedBoundaryValue = 0.5
    $boundaryValueCorrect = [Math]::Abs($boundaryValue - $expectedBoundaryValue) -lt 0.0001
    Write-Host "`nValeur à la limite (u=1): $([Math]::Round($boundaryValue, 6))" -ForegroundColor White
    Write-Host "Valeur attendue: $([Math]::Round($expectedBoundaryValue, 6))" -ForegroundColor White
    Write-Host "Résultat: $(if ($boundaryValueCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($boundaryValueCorrect) { "Green" } else { "Red" })

    # Vérifier que la valeur en dehors du support (u=1.5) est correcte
    $outsideValue = Get-UniformKernel -U 1.5
    $expectedOutsideValue = 0
    $outsideValueCorrect = [Math]::Abs($outsideValue - $expectedOutsideValue) -lt 0.0001
    Write-Host "`nValeur en dehors du support (u=1.5): $([Math]::Round($outsideValue, 6))" -ForegroundColor White
    Write-Host "Valeur attendue: $([Math]::Round($expectedOutsideValue, 6))" -ForegroundColor White
    Write-Host "Résultat: $(if ($outsideValueCorrect) { "Correct" } else { "Incorrect" })" -ForegroundColor $(if ($outsideValueCorrect) { "Green" } else { "Red" })

    # Test 2: Estimation de densité avec le noyau uniforme
    Write-Host "`n=== Test 2: Estimation de densité avec le noyau uniforme ===" -ForegroundColor Magenta

    # Générer des données normales
    $normalData = 1..100 | ForEach-Object {
        # Méthode Box-Muller pour générer des variables aléatoires normales
        $u1 = Get-Random -Minimum 0.0001 -Maximum 0.9999
        $u2 = Get-Random -Minimum 0.0001 -Maximum 0.9999
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)

        # Transformer pour obtenir une distribution normale avec moyenne 100 et écart-type 15
        100 + 15 * $z
    }

    # Calculer la largeur de bande optimale
    $bandwidth = 0  # Utiliser la valeur par défaut (calculée automatiquement)
    $actualBandwidth = 0

    # Calculer la densité pour différents points
    $densityPoints = 50..150
    $densities = $densityPoints | ForEach-Object {
        if ($actualBandwidth -eq 0) {
            $density = Get-UniformKernelDensity -X $_ -Data $normalData -Bandwidth $bandwidth
            # Capturer la largeur de bande calculée automatiquement
            $actualBandwidth = $bandwidth
        } else {
            $density = Get-UniformKernelDensity -X $_ -Data $normalData -Bandwidth $actualBandwidth
        }
        [PSCustomObject]@{
            Point   = $_
            Density = $density
        }
    }

    # Afficher les résultats
    Write-Host "Largeur de bande optimale calculée: $actualBandwidth" -ForegroundColor White
    Write-Host "Densités calculées pour quelques points:" -ForegroundColor White
    Write-Host "| Point | Densité |" -ForegroundColor White
    Write-Host "|-------|---------|" -ForegroundColor White
    foreach ($density in $densities | Select-Object -First 5) {
        Write-Host "| $($density.Point) | $([Math]::Round($density.Density, 6)) |" -ForegroundColor Green
    }
    Write-Host "..." -ForegroundColor White
    foreach ($density in $densities | Select-Object -Last 5) {
        Write-Host "| $($density.Point) | $([Math]::Round($density.Density, 6)) |" -ForegroundColor Green
    }

    # Vérifier que la densité est maximale au centre de la distribution
    $maxDensityPoint = ($densities | Sort-Object -Property Density -Descending)[0].Point
    $densityCorrect = [Math]::Abs($maxDensityPoint - 100) -lt 10  # Tolérance de 10 unités
    Write-Host "`nPoint de densité maximale: $maxDensityPoint" -ForegroundColor White
    Write-Host "Point attendu: environ 100" -ForegroundColor White
    Write-Host "Résultat: $(if ($densityCorrect) { "Approximativement correct" } else { "Incorrect" })" -ForegroundColor $(if ($densityCorrect) { "Green" } else { "Red" })
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau uniforme optimisée.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau uniforme
    avec des optimisations pour améliorer les performances. Elle utilise une approche de comptage direct
    au lieu de calculer la valeur du noyau pour chaque point, ce qui est plus efficace pour le noyau uniforme.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau uniforme.

.EXAMPLE
    Get-OptimizedUniformKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau uniforme optimisée
    avec une largeur de bande optimale.

.EXAMPLE
    Get-OptimizedUniformKernelDensity -X 10 -Data $data -Bandwidth 1.5
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau uniforme optimisée
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Double
#>
function Get-OptimizedUniformKernelDensity {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Calculer la largeur de bande optimale si non spécifiée
    if ($Bandwidth -le 0) {
        # Calculer l'écart-type des données
        $mean = ($Data | Measure-Object -Average).Average
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

        # Calculer l'écart interquartile
        $sortedData = $Data | Sort-Object
        $n = $Data.Count
        $q1Index = [Math]::Floor($n * 0.25)
        $q3Index = [Math]::Floor($n * 0.75)
        $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]

        # Utiliser le minimum entre l'écart-type et l'écart interquartile normalisé
        $sigma = [Math]::Min($stdDev, $iqr / 1.34)

        # Règle de Silverman ajustée pour le noyau uniforme
        # Le facteur 1.06 est ajusté à 1.3 pour le noyau uniforme
        $Bandwidth = 1.3 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Calculer la densité en utilisant une approche optimisée pour le noyau uniforme
    # Au lieu de calculer la valeur du noyau pour chaque point, nous comptons simplement
    # le nombre de points qui se trouvent dans la fenêtre [X - Bandwidth, X + Bandwidth]
    $n = $Data.Count
    $lowerBound = $X - $Bandwidth
    $upperBound = $X + $Bandwidth

    # Compter les points dans la fenêtre
    $count = 0
    foreach ($xi in $Data) {
        if ($xi -ge $lowerBound -and $xi -le $upperBound) {
            $count++
        }
    }

    # Calculer la densité
    # Pour le noyau uniforme, la densité est simplement le nombre de points dans la fenêtre
    # divisé par le nombre total de points et par la largeur de la fenêtre (2 * Bandwidth)
    $density = $count / ($n * (2 * $Bandwidth))

    return $density
}

<#
.SYNOPSIS
    Calcule la densité pour plusieurs points en utilisant l'estimation de densité par noyau uniforme optimisée.

.DESCRIPTION
    Cette fonction calcule la densité pour plusieurs points en utilisant l'estimation de densité par noyau uniforme
    avec des optimisations pour améliorer les performances. Elle utilise une approche de comptage direct
    et évite les calculs redondants.

.PARAMETER EvaluationPoints
    Les points où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau uniforme.

.EXAMPLE
    Get-OptimizedUniformKernelDensityMultiplePoints -EvaluationPoints (0..100) -Data $data
    Calcule la densité pour les points 0 à 100 en utilisant l'estimation de densité par noyau uniforme optimisée
    avec une largeur de bande optimale.

.OUTPUTS
    System.Collections.ArrayList
#>
function Get-OptimizedUniformKernelDensityMultiplePoints {
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$EvaluationPoints,

        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Calculer la largeur de bande optimale si non spécifiée
    if ($Bandwidth -le 0) {
        # Calculer l'écart-type des données
        $mean = ($Data | Measure-Object -Average).Average
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

        # Calculer l'écart interquartile
        $sortedData = $Data | Sort-Object
        $n = $Data.Count
        $q1Index = [Math]::Floor($n * 0.25)
        $q3Index = [Math]::Floor($n * 0.75)
        $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]

        # Utiliser le minimum entre l'écart-type et l'écart interquartile normalisé
        $sigma = [Math]::Min($stdDev, $iqr / 1.34)

        # Règle de Silverman ajustée pour le noyau uniforme
        # Le facteur 1.06 est ajusté à 1.3 pour le noyau uniforme
        $Bandwidth = 1.3 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Trier les données pour optimiser les calculs
    $sortedData = $Data | Sort-Object

    # Initialiser les résultats
    $results = New-Object System.Collections.ArrayList

    # Calculer la densité pour chaque point d'évaluation
    foreach ($x in $EvaluationPoints) {
        $lowerBound = $x - $Bandwidth
        $upperBound = $x + $Bandwidth

        # Trouver l'index du premier point dans la fenêtre
        $startIndex = 0
        while ($startIndex -lt $sortedData.Count -and $sortedData[$startIndex] -lt $lowerBound) {
            $startIndex++
        }

        # Trouver l'index du dernier point dans la fenêtre
        $endIndex = $startIndex
        while ($endIndex -lt $sortedData.Count -and $sortedData[$endIndex] -le $upperBound) {
            $endIndex++
        }

        # Calculer le nombre de points dans la fenêtre
        $count = $endIndex - $startIndex

        # Calculer la densité
        $density = $count / ($sortedData.Count * (2 * $Bandwidth))

        # Ajouter le résultat
        [void]$results.Add([PSCustomObject]@{
                Point   = $x
                Density = $density
            })
    }

    return $results
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau uniforme pour des données multidimensionnelles.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau uniforme
    pour des données multidimensionnelles. Elle utilise une approche de comptage direct pour améliorer les performances.

.PARAMETER Point
    Le point où calculer la densité, sous forme d'un objet PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Data
    Les données de la distribution, sous forme d'un tableau d'objets PSCustomObject avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour l'estimation de densité. Si non spécifié, toutes les propriétés du premier point de données
    seront utilisées comme dimensions.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Peut être:
    - Une valeur unique (même largeur de bande pour toutes les dimensions)
    - Un objet PSCustomObject avec des propriétés pour chaque dimension
    Si non spécifiée, une largeur de bande optimale sera calculée pour chaque dimension.

.EXAMPLE
    $point = [PSCustomObject]@{ X = 10; Y = 20 }
    $data = @(
        [PSCustomObject]@{ X = 5; Y = 15 },
        [PSCustomObject]@{ X = 15; Y = 25 }
    )
    Get-UniformKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau uniforme
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-UniformKernelDensityND {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Point,

        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,

        [Parameter(Mandatory = $false)]
        [string[]]$Dimensions,

        [Parameter(Mandatory = $false)]
        [object]$Bandwidth = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour l'estimation de densité par noyau."
    }

    # Déterminer les dimensions si non spécifiées
    if (-not $Dimensions) {
        $Dimensions = $Data[0].PSObject.Properties.Name
    }

    # Vérifier que toutes les données ont les dimensions spécifiées
    foreach ($dataPoint in $Data) {
        foreach ($dimension in $Dimensions) {
            if (-not $dataPoint.PSObject.Properties.Name.Contains($dimension)) {
                throw "Le point de données ne contient pas la dimension spécifiée: $dimension"
            }
        }
    }

    # Vérifier que le point d'évaluation a les dimensions spécifiées
    foreach ($dimension in $Dimensions) {
        if (-not $Point.PSObject.Properties.Name.Contains($dimension)) {
            throw "Le point d'évaluation ne contient pas la dimension spécifiée: $dimension"
        }
    }

    # Calculer la largeur de bande optimale si non spécifiée
    $bandwidthByDimension = @{}

    if ($null -eq $Bandwidth) {
        # Calculer la largeur de bande optimale pour chaque dimension
        foreach ($dimension in $Dimensions) {
            # Extraire les données pour cette dimension
            $dimensionData = $Data | ForEach-Object { $_.$dimension }

            # Calculer l'écart-type
            $mean = ($dimensionData | Measure-Object -Average).Average
            $stdDev = [Math]::Sqrt(($dimensionData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)

            # Calculer l'écart interquartile
            $sortedData = $dimensionData | Sort-Object
            $n = $dimensionData.Count
            $q1Index = [Math]::Floor($n * 0.25)
            $q3Index = [Math]::Floor($n * 0.75)
            $iqr = $sortedData[$q3Index] - $sortedData[$q1Index]

            # Utiliser le minimum entre l'écart-type et l'écart interquartile normalisé
            $sigma = [Math]::Min($stdDev, $iqr / 1.34)

            # Règle de Silverman ajustée pour le noyau uniforme
            $bandwidthByDimension[$dimension] = 1.3 * $sigma * [Math]::Pow($n, -1 / ($Dimensions.Count + 4))
        }
    } elseif ($Bandwidth -is [double]) {
        # Utiliser la même largeur de bande pour toutes les dimensions
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth
        }
    } elseif ($Bandwidth -is [PSCustomObject]) {
        # Utiliser les largeurs de bande spécifiées pour chaque dimension
        foreach ($dimension in $Dimensions) {
            if (-not $Bandwidth.PSObject.Properties.Name.Contains($dimension)) {
                throw "La largeur de bande ne contient pas la dimension spécifiée: $dimension"
            }
            $bandwidthByDimension[$dimension] = $Bandwidth.$dimension
        }
    } else {
        throw "Type de largeur de bande non pris en charge: $($Bandwidth.GetType().Name)"
    }

    # Calculer la densité en utilisant une approche optimisée pour le noyau uniforme
    $n = $Data.Count
    $count = 0

    # Pour chaque point de données, vérifier s'il est dans l'hypercube centré sur le point d'évaluation
    foreach ($dataPoint in $Data) {
        $inRange = $true

        foreach ($dimension in $Dimensions) {
            $distance = [Math]::Abs($Point.$dimension - $dataPoint.$dimension)
            $bandwidth = $bandwidthByDimension[$dimension]

            if ($distance -gt $bandwidth) {
                $inRange = $false
                break
            }
        }

        if ($inRange) {
            $count++
        }
    }

    # Calculer la densité
    # Pour le noyau uniforme multidimensionnel, la densité est le nombre de points dans l'hypercube
    # divisé par le nombre total de points et par le volume de l'hypercube
    $volume = 1
    foreach ($dimension in $Dimensions) {
        $volume *= (2 * $bandwidthByDimension[$dimension])
    }

    $density = $count / ($n * $volume)

    return $density
}

# Exporter les fonctions
Export-ModuleMember -Function Get-UniformKernel, Get-UniformKernelDensity, Get-OptimizedUniformKernelDensity, Get-OptimizedUniformKernelDensityMultiplePoints, Get-UniformKernelDensityND, Test-UniformKernel
