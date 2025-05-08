<#
.SYNOPSIS
    Module pour l'estimation de densité par noyau biweight (quartic).

.DESCRIPTION
    Ce module implémente les fonctions nécessaires pour l'estimation de densité par noyau biweight (quartic).
    Le noyau biweight est défini par K(u) = (15/16)(1-u²)² pour |u| ≤ 1, 0 sinon.
    Il est souvent utilisé pour ses bonnes propriétés statistiques et sa continuité.

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-16
#>

<#
.SYNOPSIS
    Calcule la valeur du noyau biweight (quartic) pour une valeur normalisée.

.DESCRIPTION
    Cette fonction calcule la valeur du noyau biweight (quartic) pour une valeur normalisée u.
    Le noyau biweight est défini par K(u) = (15/16)(1-u²)² pour |u| ≤ 1, 0 sinon.

.PARAMETER U
    La valeur normalisée pour laquelle calculer la valeur du noyau.

.EXAMPLE
    Get-BiweightKernel -U 0
    Calcule la valeur du noyau biweight pour u = 0, ce qui donne 15/16 = 0.9375.

.EXAMPLE
    Get-BiweightKernel -U 0.5
    Calcule la valeur du noyau biweight pour u = 0.5, ce qui donne (15/16)(1-0.5²)² = (15/16)(1-0.25)² = (15/16)(0.75)² = (15/16)(0.5625) = 0.5273.

.OUTPUTS
    System.Double
#>
function Get-BiweightKernel {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$U
    )

    # Calculer la valeur du noyau biweight
    if ([Math]::Abs($U) -le 1) {
        $kernelValue = (15.0 / 16.0) * [Math]::Pow(1 - ($U * $U), 2)
    } else {
        $kernelValue = 0
    }

    return $kernelValue
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau biweight.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau biweight.
    Elle utilise la formule standard de l'estimation de densité par noyau:
    f(x) = (1/nh) * sum(K((x-x_i)/h))
    où K est le noyau biweight, h est la largeur de bande, et x_i sont les données.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau biweight.

.EXAMPLE
    Get-BiweightKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau biweight
    avec une largeur de bande optimale.

.EXAMPLE
    Get-BiweightKernelDensity -X 10 -Data $data -Bandwidth 1.5
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau biweight
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Double
#>
function Get-BiweightKernelDensity {
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

        # Règle de Silverman ajustée pour le noyau biweight
        # Le facteur 1.06 est ajusté à 1.15 pour le noyau biweight
        $Bandwidth = 1.15 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0

    foreach ($xi in $Data) {
        # Calculer la valeur normalisée
        $u = ($X - $xi) / $Bandwidth

        # Calculer la valeur du noyau
        $kernelValue = Get-BiweightKernel -U $u

        # Ajouter à la densité
        $density += $kernelValue
    }

    # Normaliser la densité
    $density = $density / ($n * $Bandwidth)

    return $density
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau biweight optimisée.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau biweight
    avec des optimisations pour améliorer les performances. Elle utilise une approche de calcul direct
    au lieu de calculer la valeur du noyau pour chaque point.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau biweight.

.EXAMPLE
    Get-OptimizedBiweightKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau biweight optimisée
    avec une largeur de bande optimale.

.EXAMPLE
    Get-OptimizedBiweightKernelDensity -X 10 -Data $data -Bandwidth 1.5
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau biweight optimisée
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Double
#>
function Get-OptimizedBiweightKernelDensity {
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

        # Règle de Silverman ajustée pour le noyau biweight
        $Bandwidth = 1.15 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Calculer la densité en utilisant une approche optimisée
    $n = $Data.Count
    $density = 0
    $factor = 15.0 / 16.0
    $invBandwidth = 1.0 / $Bandwidth

    foreach ($xi in $Data) {
        # Calculer la valeur normalisée
        $u = ($X - $xi) * $invBandwidth

        # Calculer la valeur du noyau biweight directement
        if ([Math]::Abs($u) -le 1) {
            $uSquared = $u * $u
            $kernelValue = $factor * [Math]::Pow(1 - $uSquared, 2)
            $density += $kernelValue
        }
    }

    # Normaliser la densité
    $density = $density * $invBandwidth / $n

    return $density
}

<#
.SYNOPSIS
    Calcule la densité pour plusieurs points en utilisant l'estimation de densité par noyau biweight optimisée.

.DESCRIPTION
    Cette fonction calcule la densité pour plusieurs points en utilisant l'estimation de densité par noyau biweight
    avec des optimisations pour améliorer les performances. Elle utilise une approche de calcul direct
    et évite les calculs redondants.

.PARAMETER EvaluationPoints
    Les points où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau biweight.

.EXAMPLE
    Get-OptimizedBiweightKernelDensityMultiplePoints -EvaluationPoints (0..100) -Data $data
    Calcule la densité pour les points 0 à 100 en utilisant l'estimation de densité par noyau biweight optimisée
    avec une largeur de bande optimale.

.OUTPUTS
    System.Collections.ArrayList
#>
function Get-OptimizedBiweightKernelDensityMultiplePoints {
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

        # Règle de Silverman ajustée pour le noyau biweight
        $Bandwidth = 1.15 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Initialiser les résultats
    $results = New-Object System.Collections.ArrayList

    # Constantes pour le calcul
    $n = $Data.Count
    $factor = 15.0 / 16.0
    $invBandwidth = 1.0 / $Bandwidth

    # Calculer la densité pour chaque point d'évaluation
    foreach ($x in $EvaluationPoints) {
        $density = 0

        foreach ($xi in $Data) {
            # Calculer la valeur normalisée
            $u = ($x - $xi) * $invBandwidth

            # Calculer la valeur du noyau biweight directement
            if ([Math]::Abs($u) -le 1) {
                $uSquared = $u * $u
                $kernelValue = $factor * [Math]::Pow(1 - $uSquared, 2)
                $density += $kernelValue
            }
        }

        # Normaliser la densité
        $density = $density * $invBandwidth / $n

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
    Calcule la densité en un point en utilisant l'estimation de densité par noyau biweight pour des données multidimensionnelles.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau biweight
    pour des données multidimensionnelles. Elle utilise une approche de calcul direct pour améliorer les performances.

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
    Get-BiweightKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau biweight
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-BiweightKernelDensityND {
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

            # Règle de Silverman ajustée pour le noyau biweight
            $bandwidthByDimension[$dimension] = 1.15 * $sigma * [Math]::Pow($n, -1 / ($Dimensions.Count + 4))
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

    # Calculer la densité
    $n = $Data.Count
    $density = 0
    $factor = 15.0 / 16.0

    foreach ($dataPoint in $Data) {
        # Calculer le produit des valeurs du noyau pour chaque dimension
        $kernelProduct = 1
        $allInRange = $true

        foreach ($dimension in $Dimensions) {
            # Calculer la valeur normalisée
            $u = ($Point.$dimension - $dataPoint.$dimension) / $bandwidthByDimension[$dimension]

            # Calculer la valeur du noyau biweight
            if ([Math]::Abs($u) -le 1) {
                $uSquared = $u * $u
                $kernelValue = $factor * [Math]::Pow(1 - $uSquared, 2)
                $kernelProduct *= $kernelValue
            } else {
                $allInRange = $false
                break
            }
        }

        # Ajouter à la densité si tous les points sont dans la plage
        if ($allInRange) {
            $density += $kernelProduct
        }
    }

    # Normaliser la densité
    $volumeFactor = 1
    foreach ($dimension in $Dimensions) {
        $volumeFactor *= $bandwidthByDimension[$dimension]
    }

    $density = $density / ($n * $volumeFactor)

    return $density
}

<#
.SYNOPSIS
    Teste les fonctions du noyau biweight (quartic).

.DESCRIPTION
    Cette fonction teste les fonctions du noyau biweight (quartic) pour l'estimation de densité par noyau.
    Elle vérifie que les fonctions fonctionnent correctement et que les résultats sont cohérents.

.EXAMPLE
    Test-BiweightKernel
    Teste les fonctions du noyau biweight et affiche les résultats.

.OUTPUTS
    System.Boolean
#>
function Test-BiweightKernel {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $testsPassed = 0
    $testsTotal = 0

    Write-Host "`n=== Test du noyau biweight (quartic) ===" -ForegroundColor Magenta

    # Test 1: Vérifier que la valeur du noyau biweight est correcte pour u = 0
    $testsTotal++
    $u = 0
    $expected = 15.0 / 16.0
    $result = Get-BiweightKernel -U $u
    $test1Passed = [Math]::Abs($result - $expected) -lt 0.0001

    Write-Host "Test 1: Valeur du noyau biweight pour u = 0" -ForegroundColor White
    Write-Host "  Résultat: $result" -ForegroundColor White
    Write-Host "  Attendu: $expected" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test1Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test1Passed) { "Green" } else { "Red" })

    if ($test1Passed) { $testsPassed++ }

    # Test 2: Vérifier que la valeur du noyau biweight est correcte pour u = 0.5
    $testsTotal++
    $u = 0.5
    $expected = (15.0 / 16.0) * [Math]::Pow(1 - 0.25, 2)
    $result = Get-BiweightKernel -U $u
    $test2Passed = [Math]::Abs($result - $expected) -lt 0.0001

    Write-Host "`nTest 2: Valeur du noyau biweight pour u = 0.5" -ForegroundColor White
    Write-Host "  Résultat: $result" -ForegroundColor White
    Write-Host "  Attendu: $expected" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test2Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test2Passed) { "Green" } else { "Red" })

    if ($test2Passed) { $testsPassed++ }

    # Test 3: Vérifier que la valeur du noyau biweight est 0 pour u > 1
    $testsTotal++
    $u = 1.5
    $expected = 0
    $result = Get-BiweightKernel -U $u
    $test3Passed = [Math]::Abs($result - $expected) -lt 0.0001

    Write-Host "`nTest 3: Valeur du noyau biweight pour u = 1.5" -ForegroundColor White
    Write-Host "  Résultat: $result" -ForegroundColor White
    Write-Host "  Attendu: $expected" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test3Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test3Passed) { "Green" } else { "Red" })

    if ($test3Passed) { $testsPassed++ }

    # Test 4: Vérifier que la fonction d'estimation de densité fonctionne correctement
    $testsTotal++
    $data = 1..100 | ForEach-Object { 50 + (Get-Random -Minimum -10 -Maximum 10) }
    $result = Get-BiweightKernelDensity -X 50 -Data $data -Bandwidth 5
    $test4Passed = $result -gt 0

    Write-Host "`nTest 4: Estimation de densité par noyau biweight" -ForegroundColor White
    Write-Host "  Densité au point 50: $result" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test4Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test4Passed) { "Green" } else { "Red" })

    if ($test4Passed) { $testsPassed++ }

    # Test 5: Vérifier que la fonction optimisée donne des résultats cohérents avec la fonction de base
    $testsTotal++
    $resultBase = Get-BiweightKernelDensity -X 50 -Data $data -Bandwidth 5
    $resultOptimized = Get-OptimizedBiweightKernelDensity -X 50 -Data $data -Bandwidth 5
    $test5Passed = [Math]::Abs($resultOptimized - $resultBase) -lt 0.0001

    Write-Host "`nTest 5: Cohérence entre la fonction de base et la fonction optimisée" -ForegroundColor White
    Write-Host "  Résultat de base: $resultBase" -ForegroundColor White
    Write-Host "  Résultat optimisé: $resultOptimized" -ForegroundColor White
    Write-Host "  Différence: $([Math]::Abs($resultOptimized - $resultBase))" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test5Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test5Passed) { "Green" } else { "Red" })

    if ($test5Passed) { $testsPassed++ }

    # Test 6: Vérifier que la fonction pour plusieurs points fonctionne correctement
    $testsTotal++
    $evalPoints = 45..55
    $resultMultiplePoints = Get-OptimizedBiweightKernelDensityMultiplePoints -EvaluationPoints $evalPoints -Data $data -Bandwidth 5
    $test6Passed = $resultMultiplePoints.Count -eq $evalPoints.Count -and $resultMultiplePoints[0].Density -gt 0

    Write-Host "`nTest 6: Estimation de densité pour plusieurs points" -ForegroundColor White
    Write-Host "  Nombre de points: $($resultMultiplePoints.Count)" -ForegroundColor White
    Write-Host "  Densité au premier point: $($resultMultiplePoints[0].Density)" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test6Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test6Passed) { "Green" } else { "Red" })

    if ($test6Passed) { $testsPassed++ }

    # Test 7: Vérifier que la fonction multidimensionnelle fonctionne correctement
    $testsTotal++
    $data2D = 1..20 | ForEach-Object {
        [PSCustomObject]@{
            X = 50 + (Get-Random -Minimum -10 -Maximum 10)
            Y = 50 + (Get-Random -Minimum -10 -Maximum 10)
        }
    }
    $point = [PSCustomObject]@{
        X = 50
        Y = 50
    }
    $result2D = Get-BiweightKernelDensityND -Point $point -Data $data2D -Bandwidth 5
    $test7Passed = $result2D -gt 0

    Write-Host "`nTest 7: Estimation de densité multidimensionnelle" -ForegroundColor White
    Write-Host "  Densité au point (50, 50): $result2D" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test7Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test7Passed) { "Green" } else { "Red" })

    if ($test7Passed) { $testsPassed++ }

    # Résumé des tests
    Write-Host "`n=== Résumé des tests ===" -ForegroundColor Magenta
    Write-Host "Tests réussis: $testsPassed / $testsTotal" -ForegroundColor White
    Write-Host "Résultat global: $(if ($testsPassed -eq $testsTotal) { "Tous les tests ont réussi" } else { "Certains tests ont échoué" })" -ForegroundColor $(if ($testsPassed -eq $testsTotal) { "Green" } else { "Yellow" })

    return $testsPassed -eq $testsTotal
}

# Exporter les fonctions
Export-ModuleMember -Function Get-BiweightKernel, Get-BiweightKernelDensity, Get-OptimizedBiweightKernelDensity, Get-OptimizedBiweightKernelDensityMultiplePoints, Get-BiweightKernelDensityND, Test-BiweightKernel
