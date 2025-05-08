<#
.SYNOPSIS
    Module pour l'estimation de densité par noyau triweight.

.DESCRIPTION
    Ce module implémente les fonctions nécessaires pour l'estimation de densité par noyau triweight.
    Le noyau triweight est défini par K(u) = (35/32)(1-u²)³ pour |u| ≤ 1, 0 sinon.
    Il est souvent utilisé pour ses bonnes propriétés statistiques, sa continuité et sa dérivabilité.

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-17
#>

<#
.SYNOPSIS
    Calcule la valeur du noyau triweight pour une valeur normalisée.

.DESCRIPTION
    Cette fonction calcule la valeur du noyau triweight pour une valeur normalisée u.
    Le noyau triweight est défini par K(u) = (35/32)(1-u²)³ pour |u| ≤ 1, 0 sinon.

.PARAMETER U
    La valeur normalisée pour laquelle calculer la valeur du noyau.

.EXAMPLE
    Get-TriweightKernel -U 0
    Calcule la valeur du noyau triweight pour u = 0, ce qui donne 35/32 = 1.09375.

.EXAMPLE
    Get-TriweightKernel -U 0.5
    Calcule la valeur du noyau triweight pour u = 0.5, ce qui donne (35/32)(1-0.5²)³ = (35/32)(1-0.25)³ = (35/32)(0.75)³ = (35/32)(0.421875) = 0.4612.

.OUTPUTS
    System.Double
#>
function Get-TriweightKernel {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double]$U
    )

    # Calculer la valeur du noyau triweight
    if ([Math]::Abs($U) -le 1) {
        $kernelValue = (35.0 / 32.0) * [Math]::Pow(1 - ($U * $U), 3)
    } else {
        $kernelValue = 0
    }

    return $kernelValue
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau triweight.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau triweight.
    La formule est: f(x) = (1/nh) * Σ K((x-x_i)/h) où K est le noyau triweight, n est le nombre de points,
    h est la largeur de bande, et x_i sont les points de données.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau triweight.

.EXAMPLE
    Get-TriweightKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau triweight
    avec une largeur de bande optimale.

.EXAMPLE
    Get-TriweightKernelDensity -X 10 -Data $data -Bandwidth 1.5
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau triweight
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Double
#>
function Get-TriweightKernelDensity {
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
        $variance = ($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
        $sigma = [Math]::Sqrt($variance)

        # Nombre de points
        $n = $Data.Count

        # Règle de Silverman ajustée pour le noyau triweight
        # Le facteur 1.06 est ajusté à 1.20 pour le noyau triweight
        $Bandwidth = 1.20 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0

    foreach ($xi in $Data) {
        # Calculer la valeur normalisée
        $u = ($X - $xi) / $Bandwidth

        # Calculer la valeur du noyau
        $kernelValue = Get-TriweightKernel -U $u

        # Ajouter à la densité
        $density += $kernelValue
    }

    # Normaliser la densité
    $density = $density / ($n * $Bandwidth)

    return $density
}

<#
.SYNOPSIS
    Calcule la densité en un point en utilisant l'estimation de densité par noyau triweight optimisée.

.DESCRIPTION
    Cette fonction calcule la densité en un point en utilisant l'estimation de densité par noyau triweight
    avec des optimisations pour améliorer les performances. Elle utilise une approche de calcul direct
    au lieu de calculer la valeur du noyau pour chaque point.

.PARAMETER X
    Le point où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau triweight.

.EXAMPLE
    Get-OptimizedTriweightKernelDensity -X 10 -Data $data
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau triweight optimisée
    avec une largeur de bande optimale.

.EXAMPLE
    Get-OptimizedTriweightKernelDensity -X 10 -Data $data -Bandwidth 1.5
    Calcule la densité au point 10 en utilisant l'estimation de densité par noyau triweight optimisée
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Double
#>
function Get-OptimizedTriweightKernelDensity {
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
        $variance = ($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
        $sigma = [Math]::Sqrt($variance)

        # Nombre de points
        $n = $Data.Count

        # Règle de Silverman ajustée pour le noyau triweight
        $Bandwidth = 1.20 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Calculer la densité en utilisant une approche optimisée
    $n = $Data.Count
    $density = 0
    $factor = 35.0 / 32.0
    $invBandwidth = 1.0 / $Bandwidth

    foreach ($xi in $Data) {
        # Calculer la valeur normalisée
        $u = ($X - $xi) * $invBandwidth

        # Calculer la valeur du noyau triweight directement
        if ([Math]::Abs($u) -le 1) {
            $uSquared = $u * $u
            $kernelValue = $factor * [Math]::Pow(1 - $uSquared, 3)
            $density += $kernelValue
        }
    }

    # Normaliser la densité
    $density = $density * $invBandwidth / $n

    return $density
}

<#
.SYNOPSIS
    Calcule la densité pour plusieurs points en utilisant l'estimation de densité par noyau triweight optimisée.

.DESCRIPTION
    Cette fonction calcule la densité pour plusieurs points en utilisant l'estimation de densité par noyau triweight
    avec des optimisations pour améliorer les performances. Elle utilise une approche de calcul direct
    et traite tous les points d'évaluation en une seule passe.

.PARAMETER EvaluationPoints
    Les points où calculer la densité.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman ajustée pour le noyau triweight.

.EXAMPLE
    Get-OptimizedTriweightKernelDensityMultiplePoints -EvaluationPoints @(10, 20, 30) -Data $data
    Calcule la densité aux points 10, 20 et 30 en utilisant l'estimation de densité par noyau triweight optimisée
    avec une largeur de bande optimale.

.EXAMPLE
    Get-OptimizedTriweightKernelDensityMultiplePoints -EvaluationPoints @(10, 20, 30) -Data $data -Bandwidth 1.5
    Calcule la densité aux points 10, 20 et 30 en utilisant l'estimation de densité par noyau triweight optimisée
    avec une largeur de bande de 1.5.

.OUTPUTS
    System.Collections.ArrayList
#>
function Get-OptimizedTriweightKernelDensityMultiplePoints {
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
        $variance = ($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
        $sigma = [Math]::Sqrt($variance)

        # Nombre de points
        $n = $Data.Count

        # Règle de Silverman ajustée pour le noyau triweight
        $Bandwidth = 1.20 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Initialiser les résultats
    $results = New-Object System.Collections.ArrayList

    # Constantes pour le calcul
    $n = $Data.Count
    $factor = 35.0 / 32.0
    $invBandwidth = 1.0 / $Bandwidth

    # Calculer la densité pour chaque point d'évaluation
    foreach ($x in $EvaluationPoints) {
        $density = 0

        foreach ($xi in $Data) {
            # Calculer la valeur normalisée
            $u = ($x - $xi) * $invBandwidth

            # Calculer la valeur du noyau triweight directement
            if ([Math]::Abs($u) -le 1) {
                $uSquared = $u * $u
                $kernelValue = $factor * [Math]::Pow(1 - $uSquared, 3)
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
    Calcule la densité pour des données multidimensionnelles en utilisant l'estimation de densité par noyau triweight.

.DESCRIPTION
    Cette fonction calcule la densité pour des données multidimensionnelles en utilisant l'estimation de densité par noyau triweight.
    Elle utilise le produit des noyaux pour chaque dimension.

.PARAMETER Point
    Le point où calculer la densité, sous forme d'un objet avec des propriétés pour chaque dimension.

.PARAMETER Data
    Les données de la distribution, sous forme d'un tableau d'objets avec des propriétés pour chaque dimension.

.PARAMETER Dimensions
    Les dimensions à utiliser pour le calcul de la densité. Si non spécifiées, toutes les propriétés du premier point de données seront utilisées.

.PARAMETER Bandwidth
    La largeur de bande (h) à utiliser. Peut être un nombre unique pour toutes les dimensions, ou un hashtable avec une largeur de bande pour chaque dimension.
    Si non spécifiée, une largeur de bande optimale sera calculée pour chaque dimension.

.EXAMPLE
    $point = [PSCustomObject]@{ X = 10; Y = 20 }
    $data = @(
        [PSCustomObject]@{ X = 5; Y = 15 },
        [PSCustomObject]@{ X = 15; Y = 25 }
    )
    Get-TriweightKernelDensityND -Point $point -Data $data
    Calcule la densité au point (10, 20) en utilisant l'estimation de densité par noyau triweight
    pour des données bidimensionnelles avec une largeur de bande optimale.

.OUTPUTS
    System.Double
#>
function Get-TriweightKernelDensityND {
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

    # Calculer la largeur de bande optimale pour chaque dimension si non spécifiée
    $bandwidthByDimension = @{}
    if ($null -eq $Bandwidth) {
        foreach ($dimension in $Dimensions) {
            # Extraire les valeurs pour cette dimension
            $dimensionData = $Data | ForEach-Object { $_.$dimension }

            # Calculer l'écart-type des données
            $mean = ($dimensionData | Measure-Object -Average).Average
            $variance = ($dimensionData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
            $sigma = [Math]::Sqrt($variance)

            # Nombre de points
            $n = $Data.Count

            # Règle de Silverman ajustée pour le noyau triweight
            $bandwidthByDimension[$dimension] = 1.20 * $sigma * [Math]::Pow($n, -0.2)
        }
    } elseif ($Bandwidth -is [double] -or $Bandwidth -is [int]) {
        # Utiliser la même largeur de bande pour toutes les dimensions
        foreach ($dimension in $Dimensions) {
            $bandwidthByDimension[$dimension] = $Bandwidth
        }
    } else {
        # Utiliser la largeur de bande spécifiée pour chaque dimension
        $bandwidthByDimension = $Bandwidth
    }

    # Calculer la densité
    $n = $Data.Count
    $density = 0
    $factor = 35.0 / 32.0

    foreach ($dataPoint in $Data) {
        # Calculer le produit des valeurs du noyau pour chaque dimension
        $kernelProduct = 1
        $allInRange = $true

        foreach ($dimension in $Dimensions) {
            # Calculer la valeur normalisée
            $u = ($Point.$dimension - $dataPoint.$dimension) / $bandwidthByDimension[$dimension]

            # Calculer la valeur du noyau triweight
            if ([Math]::Abs($u) -le 1) {
                $uSquared = $u * $u
                $kernelValue = $factor * [Math]::Pow(1 - $uSquared, 3)
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
    Teste les fonctions du noyau triweight.

.DESCRIPTION
    Cette fonction teste les fonctions du noyau triweight pour l'estimation de densité par noyau.
    Elle vérifie que les fonctions fonctionnent correctement et que les résultats sont cohérents.

.EXAMPLE
    Test-TriweightKernel
    Teste les fonctions du noyau triweight et affiche les résultats.

.OUTPUTS
    System.Boolean
#>
function Test-TriweightKernel {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $testsPassed = 0
    $testsTotal = 0

    Write-Host "`n=== Test du noyau triweight ===" -ForegroundColor Magenta

    # Test 1: Vérifier que la valeur du noyau triweight est correcte pour u = 0
    $testsTotal++
    $u = 0
    $expected = 35.0 / 32.0
    $result = Get-TriweightKernel -U $u
    $test1Passed = [Math]::Abs($result - $expected) -lt 0.0001

    Write-Host "`nTest 1: Valeur du noyau triweight pour u = 0" -ForegroundColor White
    Write-Host "  Résultat: $result" -ForegroundColor White
    Write-Host "  Attendu: $expected" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test1Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test1Passed) { "Green" } else { "Red" })

    if ($test1Passed) { $testsPassed++ }

    # Test 2: Vérifier que la valeur du noyau triweight est correcte pour u = 0.5
    $testsTotal++
    $u = 0.5
    $expected = (35.0 / 32.0) * [Math]::Pow(1 - 0.25, 3)
    $result = Get-TriweightKernel -U $u
    $test2Passed = [Math]::Abs($result - $expected) -lt 0.0001

    Write-Host "`nTest 2: Valeur du noyau triweight pour u = 0.5" -ForegroundColor White
    Write-Host "  Résultat: $result" -ForegroundColor White
    Write-Host "  Attendu: $expected" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test2Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test2Passed) { "Green" } else { "Red" })

    if ($test2Passed) { $testsPassed++ }

    # Test 3: Vérifier que la valeur du noyau triweight est 0 pour u > 1
    $testsTotal++
    $u = 1.5
    $expected = 0
    $result = Get-TriweightKernel -U $u
    $test3Passed = $result -eq $expected

    Write-Host "`nTest 3: Valeur du noyau triweight pour u = 1.5" -ForegroundColor White
    Write-Host "  Résultat: $result" -ForegroundColor White
    Write-Host "  Attendu: $expected" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test3Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test3Passed) { "Green" } else { "Red" })

    if ($test3Passed) { $testsPassed++ }

    # Test 4: Vérifier que la fonction d'estimation de densité fonctionne correctement
    $testsTotal++
    $data = 1..100 | ForEach-Object { 50 + (Get-Random -Minimum -10 -Maximum 10) }
    $result = Get-TriweightKernelDensity -X 50 -Data $data -Bandwidth 5
    $test4Passed = $result -gt 0

    Write-Host "`nTest 4: Estimation de densité par noyau triweight" -ForegroundColor White
    Write-Host "  Densité au point 50: $result" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test4Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test4Passed) { "Green" } else { "Red" })

    if ($test4Passed) { $testsPassed++ }

    # Test 5: Vérifier que la fonction optimisée donne des résultats cohérents avec la fonction de base
    $testsTotal++
    $resultBase = Get-TriweightKernelDensity -X 50 -Data $data -Bandwidth 5
    $resultOptimized = Get-OptimizedTriweightKernelDensity -X 50 -Data $data -Bandwidth 5
    $test5Passed = [Math]::Abs($resultOptimized - $resultBase) -lt 0.0001

    Write-Host "`nTest 5: Cohérence entre la fonction de base et la fonction optimisée" -ForegroundColor White
    Write-Host "  Résultat de base: $resultBase" -ForegroundColor White
    Write-Host "  Résultat optimisé: $resultOptimized" -ForegroundColor White
    Write-Host "  Différence: $([Math]::Abs($resultOptimized - $resultBase))" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test5Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test5Passed) { "Green" } else { "Red" })

    if ($test5Passed) { $testsPassed++ }

    # Test 6: Vérifier que la fonction pour plusieurs points fonctionne correctement
    $testsTotal++
    $evaluationPoints = @(40, 50, 60)
    $results = Get-OptimizedTriweightKernelDensityMultiplePoints -EvaluationPoints $evaluationPoints -Data $data -Bandwidth 5
    $test6Passed = $results.Count -eq 3 -and $results[0].Density -gt 0 -and $results[1].Density -gt 0 -and $results[2].Density -gt 0

    Write-Host "`nTest 6: Estimation de densité pour plusieurs points" -ForegroundColor White
    Write-Host "  Nombre de résultats: $($results.Count)" -ForegroundColor White
    Write-Host "  Densité au point 40: $($results[0].Density)" -ForegroundColor White
    Write-Host "  Densité au point 50: $($results[1].Density)" -ForegroundColor White
    Write-Host "  Densité au point 60: $($results[2].Density)" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test6Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test6Passed) { "Green" } else { "Red" })

    if ($test6Passed) { $testsPassed++ }

    # Test 7: Vérifier que la fonction pour les données multidimensionnelles fonctionne correctement
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
    $result2D = Get-TriweightKernelDensityND -Point $point -Data $data2D -Bandwidth 5
    $test7Passed = $result2D -gt 0

    Write-Host "`nTest 7: Estimation de densité multidimensionnelle" -ForegroundColor White
    Write-Host "  Densité au point (50, 50): $result2D" -ForegroundColor White
    Write-Host "  Test réussi: $(if ($test7Passed) { "Oui" } else { "Non" })" -ForegroundColor $(if ($test7Passed) { "Green" } else { "Red" })

    if ($test7Passed) { $testsPassed++ }

    # Résumé des tests
    Write-Host "`n=== Résumé des tests ===" -ForegroundColor Magenta
    Write-Host "  Tests réussis: $testsPassed / $testsTotal" -ForegroundColor White
    Write-Host "  Pourcentage de réussite: $([Math]::Round(100 * $testsPassed / $testsTotal, 2))%" -ForegroundColor White

    return $testsPassed -eq $testsTotal
}
