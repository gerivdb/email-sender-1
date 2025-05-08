<#
.SYNOPSIS
    Fonctions pour la détection des distributions à queues lourdes.

.DESCRIPTION
    Ce module implémente des fonctions pour la détection des distributions à queues lourdes,
    notamment l'indice de queue de Hill, le test de Kolmogorov-Smirnov et l'analyse QQ-plot.

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-18
#>

# Fonction d'erreur (Erf) personnalisée pour les versions de PowerShell qui ne la supportent pas
if (-not ([System.Math].GetMethods() | Where-Object { $_.Name -eq "Erf" })) {
    # Implémentation de la fonction d'erreur (Erf) basée sur l'approximation d'Abramowitz et Stegun
    function Get-Erf {
        [CmdletBinding()]
        [OutputType([double])]
        param (
            [Parameter(Mandatory = $true)]
            [double]$X
        )

        # Constantes pour l'approximation
        $a1 = 0.254829592
        $a2 = -0.284496736
        $a3 = 1.421413741
        $a4 = -1.453152027
        $a5 = 1.061405429
        $p = 0.3275911

        # Vérifier si X est NaN
        if ([double]::IsNaN($X)) {
            return [double]::NaN
        }

        # Prendre la valeur absolue de x
        $sign = [Math]::Sign($X)
        $x = [Math]::Abs($X)

        # Formule d'approximation
        $t = 1.0 / (1.0 + $p * $x)
        $y = 1.0 - (($((($a5 * $t + $a4) * $t) + $a3) * $t + $a2) * $t + $a1) * $t * [Math]::Exp(-$x * $x)

        return $sign * $y
    }

    # Ajouter la fonction Erf à la classe Math
    Add-Type -TypeDefinition @"
    using System;
    public static class MathExtensions
    {
        public static double Erf(double x)
        {
            // Constantes pour l'approximation
            double a1 = 0.254829592;
            double a2 = -0.284496736;
            double a3 = 1.421413741;
            double a4 = -1.453152027;
            double a5 = 1.061405429;
            double p = 0.3275911;

            // Prendre la valeur absolue de x
            int sign = Math.Sign(x);
            x = Math.Abs(x);

            // Formule d'approximation
            double t = 1.0 / (1.0 + p * x);
            double y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.Exp(-x * x);

            return sign * y;
        }
    }
"@ -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Calcule l'indice de queue de Hill pour un ensemble de données.

.DESCRIPTION
    Cette fonction calcule l'indice de queue de Hill pour un ensemble de données.
    L'indice de queue de Hill est un estimateur de l'indice de queue d'une distribution à queue lourde.
    Plus l'indice est petit, plus la queue est lourde.

.PARAMETER Data
    Les données pour lesquelles calculer l'indice de queue de Hill.

.PARAMETER K
    Le nombre de statistiques d'ordre à utiliser pour l'estimation.
    Si non spécifié, une valeur optimale sera calculée.

.PARAMETER Alpha
    Le niveau de confiance pour l'intervalle de confiance (par défaut 0.05).

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.EXAMPLE
    Get-HillTailIndex -Data $data -K 20
    Calcule l'indice de queue de Hill pour les données spécifiées en utilisant les 20 plus grandes valeurs.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - Index : L'indice de queue de Hill
    - LowerCI : La borne inférieure de l'intervalle de confiance
    - UpperCI : La borne supérieure de l'intervalle de confiance
    - K : Le nombre de statistiques d'ordre utilisées
    - IsHeavyTailed : Indique si la distribution est à queue lourde
#>
function Get-HillTailIndex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [int]$K = 0,

        [Parameter(Mandatory = $false)]
        [double]$Alpha = 0.05,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right"
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour calculer l'indice de queue de Hill."
    }

    # Préparer les données en fonction de la queue à analyser
    $processedData = $Data
    if ($Tail -eq "Left") {
        # Pour la queue gauche, on utilise l'opposé des données
        $processedData = $Data | ForEach-Object { - $_ }
    } elseif ($Tail -eq "Both") {
        # Pour les deux queues, on utilise la valeur absolue des données
        $processedData = $Data | ForEach-Object { [Math]::Abs($_) }
    }

    # Trier les données par ordre décroissant
    $sortedData = $processedData | Sort-Object -Descending

    # Déterminer le nombre optimal de statistiques d'ordre à utiliser si non spécifié
    if ($K -le 0) {
        $K = [Math]::Max(2, [Math]::Floor([Math]::Sqrt($sortedData.Count)))
    }

    # S'assurer que K est inférieur au nombre de données
    $K = [Math]::Min($K, $sortedData.Count - 1)

    # Calculer l'indice de queue de Hill
    $logSum = 0
    for ($i = 0; $i -lt $K; $i++) {
        $logSum += [Math]::Log($sortedData[$i] / $sortedData[$K])
    }

    $hillIndex = $K / $logSum

    # Calculer l'intervalle de confiance
    $variance = $hillIndex * $hillIndex / $K
    $z = Get-NormalQuantile -P (1 - $Alpha / 2)
    $lowerCI = $hillIndex - $z * [Math]::Sqrt($variance)
    $upperCI = $hillIndex + $z * [Math]::Sqrt($variance)

    # Déterminer si la distribution est à queue lourde
    # Une distribution est considérée à queue lourde si l'indice est inférieur à 2
    $isHeavyTailed = $hillIndex -lt 2

    # Retourner les résultats
    return [PSCustomObject]@{
        Index         = $hillIndex
        LowerCI       = $lowerCI
        UpperCI       = $upperCI
        K             = $K
        IsHeavyTailed = $isHeavyTailed
        Tail          = $Tail
    }
}

<#
.SYNOPSIS
    Calcule le quantile de la distribution normale standard.

.DESCRIPTION
    Cette fonction calcule le quantile de la distribution normale standard pour une probabilité donnée.

.PARAMETER P
    La probabilité pour laquelle calculer le quantile (entre 0 et 1).

.EXAMPLE
    Get-NormalQuantile -P 0.975
    Calcule le quantile de la distribution normale standard pour une probabilité de 0.975.

.OUTPUTS
    System.Double
#>
function Get-NormalQuantile {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 1)]
        [double]$P
    )

    # Approximation du quantile de la distribution normale standard
    # Basée sur l'algorithme de Abramowitz et Stegun

    if ($P -eq 0) {
        return [double]::NegativeInfinity
    } elseif ($P -eq 1) {
        return [double]::PositiveInfinity
    }

    $t = 0

    if ($P -lt 0.5) {
        $t = [Math]::Sqrt(-2 * [Math]::Log($P))
    } else {
        $t = [Math]::Sqrt(-2 * [Math]::Log(1 - $P))
    }

    $c0 = 2.515517
    $c1 = 0.802853
    $c2 = 0.010328
    $d1 = 1.432788
    $d2 = 0.189269
    $d3 = 0.001308

    $x = $t - ($c0 + $c1 * $t + $c2 * $t * $t) / (1 + $d1 * $t + $d2 * $t * $t + $d3 * $t * $t * $t)

    if ($P -lt 0.5) {
        return - $x
    } else {
        return $x
    }
}

<#
.SYNOPSIS
    Visualise l'indice de queue de Hill pour différentes valeurs de K.

.DESCRIPTION
    Cette fonction calcule l'indice de queue de Hill pour différentes valeurs de K
    et génère un graphique pour visualiser la stabilité de l'indice.

.PARAMETER Data
    Les données pour lesquelles calculer l'indice de queue de Hill.

.PARAMETER MinK
    La valeur minimale de K à utiliser (par défaut 2).

.PARAMETER MaxK
    La valeur maximale de K à utiliser (par défaut la moitié du nombre de données).

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.EXAMPLE
    Get-HillTailIndexPlot -Data $data -MinK 5 -MaxK 50
    Calcule l'indice de queue de Hill pour les valeurs de K de 5 à 50 et génère un graphique.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - KValues : Les valeurs de K utilisées
    - IndexValues : Les indices de queue de Hill correspondants
    - OptimalK : La valeur optimale de K
    - OptimalIndex : L'indice de queue de Hill pour la valeur optimale de K
#>
function Get-HillTailIndexPlot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [int]$MinK = 2,

        [Parameter(Mandatory = $false)]
        [int]$MaxK = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right"
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour calculer l'indice de queue de Hill."
    }

    # Déterminer la valeur maximale de K si non spécifiée
    if ($MaxK -le 0) {
        $MaxK = [Math]::Floor($Data.Count / 2)
    }

    # S'assurer que MaxK est inférieur au nombre de données
    $MaxK = [Math]::Min($MaxK, $Data.Count - 1)

    # S'assurer que MinK est inférieur à MaxK
    $MinK = [Math]::Min($MinK, $MaxK - 1)
    $MinK = [Math]::Max($MinK, 2)

    # Calculer l'indice de queue de Hill pour différentes valeurs de K
    $kValues = $MinK..$MaxK
    $indexValues = @()

    foreach ($k in $kValues) {
        $hillIndex = Get-HillTailIndex -Data $Data -K $k -Tail $Tail
        $indexValues += $hillIndex.Index
    }

    # Déterminer la valeur optimale de K
    # On cherche la région où l'indice est le plus stable
    $optimalK = $MinK
    $minVariation = [double]::MaxValue

    for ($i = 0; $i -lt ($kValues.Count - 5); $i++) {
        $variation = 0
        for ($j = 0; $j -lt 5; $j++) {
            $variation += [Math]::Abs($indexValues[$i + $j] - $indexValues[$i])
        }

        if ($variation -lt $minVariation) {
            $minVariation = $variation
            $optimalK = $kValues[$i]
        }
    }

    # Calculer l'indice de queue de Hill pour la valeur optimale de K
    $optimalIndex = Get-HillTailIndex -Data $Data -K $optimalK -Tail $Tail

    # Retourner les résultats
    return [PSCustomObject]@{
        KValues      = $kValues
        IndexValues  = $indexValues
        OptimalK     = $optimalK
        OptimalIndex = $optimalIndex
    }
}

<#
.SYNOPSIS
    Détecte si une distribution a une queue lourde en utilisant l'indice de queue de Hill.

.DESCRIPTION
    Cette fonction détecte si une distribution a une queue lourde en utilisant l'indice de queue de Hill.
    Elle calcule l'indice pour différentes valeurs de K et détermine la valeur optimale de K.

.PARAMETER Data
    Les données à analyser.

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.PARAMETER Alpha
    Le niveau de confiance pour l'intervalle de confiance (par défaut 0.05).

.EXAMPLE
    Test-HeavyTail -Data $data -Tail "Right"
    Détecte si la distribution a une queue droite lourde.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - IsHeavyTailed : Indique si la distribution est à queue lourde
    - HillIndex : L'indice de queue de Hill
    - LowerCI : La borne inférieure de l'intervalle de confiance
    - UpperCI : La borne supérieure de l'intervalle de confiance
    - K : La valeur optimale de K
    - Tail : La queue analysée
    - Interpretation : Une interprétation des résultats
#>
function Test-HeavyTail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right",

        [Parameter(Mandatory = $false)]
        [double]$Alpha = 0.05
    )

    # Calculer l'indice de queue de Hill pour différentes valeurs de K
    $hillPlot = Get-HillTailIndexPlot -Data $Data -Tail $Tail

    # Calculer l'indice de queue de Hill pour la valeur optimale de K
    $hillIndex = Get-HillTailIndex -Data $Data -K $hillPlot.OptimalK -Alpha $Alpha -Tail $Tail

    # Déterminer l'interprétation des résultats
    $interpretation = ""

    if ($hillIndex.IsHeavyTailed) {
        if ($hillIndex.Index -lt 1) {
            $interpretation = "La distribution a une queue très lourde (indice < 1). La moyenne n'existe pas."
        } elseif ($hillIndex.Index -lt 2) {
            $interpretation = "La distribution a une queue lourde (1 <= indice < 2). La moyenne existe, mais la variance est infinie."
        }
    } else {
        if ($hillIndex.Index -lt 3) {
            $interpretation = "La distribution a une queue modérément lourde (2 <= indice < 3). La moyenne et la variance existent, mais les moments d'ordre supérieur peuvent être infinis."
        } elseif ($hillIndex.Index -lt 4) {
            $interpretation = "La distribution a une queue légèrement lourde (3 <= indice < 4). Les moments jusqu'à l'ordre 3 existent, mais le kurtosis peut être infini."
        } else {
            $interpretation = "La distribution n'a pas de queue lourde (indice >= 4). Tous les moments jusqu'à l'ordre 4 existent."
        }
    }

    # Retourner les résultats
    return [PSCustomObject]@{
        IsHeavyTailed  = $hillIndex.IsHeavyTailed
        HillIndex      = $hillIndex.Index
        LowerCI        = $hillIndex.LowerCI
        UpperCI        = $hillIndex.UpperCI
        K              = $hillIndex.K
        Tail           = $hillIndex.Tail
        Interpretation = $interpretation
    }
}

<#
.SYNOPSIS
    Effectue un test de Kolmogorov-Smirnov pour détecter les queues lourdes.

.DESCRIPTION
    Cette fonction effectue un test de Kolmogorov-Smirnov pour comparer la distribution empirique
    des données avec une distribution théorique (normale, Pareto, etc.) et déterminer si les données
    ont des queues lourdes.

.PARAMETER Data
    Les données à analyser.

.PARAMETER Distribution
    La distribution théorique à utiliser pour la comparaison.
    Options : "Normal", "Pareto", "Exponential", "LogNormal", "Weibull", "Gamma".
    Par défaut, "Normal".

.PARAMETER Parameters
    Les paramètres de la distribution théorique. Si non spécifiés, ils seront estimés à partir des données.
    Pour la distribution normale, il s'agit de la moyenne et de l'écart-type.
    Pour la distribution de Pareto, il s'agit du paramètre de forme (alpha) et du paramètre d'échelle (scale).

.PARAMETER Alpha
    Le niveau de signification pour le test (par défaut 0.05).

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.EXAMPLE
    Test-KolmogorovSmirnov -Data $data -Distribution "Normal"
    Effectue un test de Kolmogorov-Smirnov pour comparer les données à une distribution normale.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - TestStatistic : La statistique de test de Kolmogorov-Smirnov
    - PValue : La p-value du test
    - CriticalValue : La valeur critique pour le niveau de signification spécifié
    - IsHeavyTailed : Indique si la distribution est à queue lourde
    - BestFitDistribution : La distribution qui s'ajuste le mieux aux données
    - Parameters : Les paramètres estimés de la distribution
    - Interpretation : Une interprétation des résultats
#>
function Test-KolmogorovSmirnov {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Pareto", "Exponential", "LogNormal", "Weibull", "Gamma")]
        [string]$Distribution = "Normal",

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = $null,

        [Parameter(Mandatory = $false)]
        [double]$Alpha = 0.05,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right"
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour effectuer le test de Kolmogorov-Smirnov."
    }

    # Préparer les données en fonction de la queue à analyser
    $processedData = $Data
    if ($Tail -eq "Left") {
        # Pour la queue gauche, on utilise l'opposé des données
        $processedData = $Data | ForEach-Object { - $_ }
    } elseif ($Tail -eq "Both") {
        # Pour les deux queues, on utilise la valeur absolue des données
        $processedData = $Data | ForEach-Object { [Math]::Abs($_) }
    }

    # Trier les données
    $sortedData = $processedData | Sort-Object

    # Estimer les paramètres de la distribution si non spécifiés
    if ($null -eq $Parameters) {
        $Parameters = @{}

        switch ($Distribution) {
            "Normal" {
                $Parameters["Mean"] = ($sortedData | Measure-Object -Average).Average
                $Parameters["StdDev"] = [Math]::Sqrt(($sortedData | ForEach-Object { [Math]::Pow($_ - $Parameters["Mean"], 2) } | Measure-Object -Average).Average)
            }
            "Pareto" {
                # Estimer le paramètre de forme (alpha) en utilisant la méthode du maximum de vraisemblance
                $minValue = ($sortedData | Measure-Object -Minimum).Minimum
                if ($minValue -le 0) {
                    $minValue = 0.001  # Éviter les valeurs négatives ou nulles
                }
                $Parameters["Scale"] = $minValue
                $logSum = 0
                foreach ($x in $sortedData) {
                    if ($x -gt $minValue) {
                        $logSum += [Math]::Log($x / $minValue)
                    }
                }
                $Parameters["Alpha"] = $sortedData.Count / $logSum
            }
            "Exponential" {
                $Parameters["Rate"] = 1 / ($sortedData | Measure-Object -Average).Average
            }
            "LogNormal" {
                $logData = $sortedData | ForEach-Object { [Math]::Log($_) }
                $Parameters["MeanLog"] = ($logData | Measure-Object -Average).Average
                $Parameters["SdLog"] = [Math]::Sqrt(($logData | ForEach-Object { [Math]::Pow($_ - $Parameters["MeanLog"], 2) } | Measure-Object -Average).Average)
            }
            "Weibull" {
                # Estimation approximative des paramètres de Weibull
                $mean = ($sortedData | Measure-Object -Average).Average
                $variance = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
                $cv = [Math]::Sqrt($variance) / $mean
                $Parameters["Shape"] = [Math]::Pow(0.9 / $cv, 1.086)
                $Parameters["Scale"] = $mean / [Math]::Gamma(1 + 1 / $Parameters["Shape"])
            }
            "Gamma" {
                # Estimation approximative des paramètres de Gamma
                $mean = ($sortedData | Measure-Object -Average).Average
                $variance = ($sortedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
                $Parameters["Shape"] = [Math]::Pow($mean, 2) / $variance
                $Parameters["Rate"] = $mean / $variance
            }
        }
    }

    # Calculer la fonction de répartition empirique
    $n = $sortedData.Count
    $ecdf = @()
    for ($i = 0; $i -lt $n; $i++) {
        $ecdf += ($i + 1) / $n
    }

    # Calculer la fonction de répartition théorique
    $tcdf = @()
    foreach ($x in $sortedData) {
        $cdf = 0

        switch ($Distribution) {
            "Normal" {
                $z = ($x - $Parameters["Mean"]) / $Parameters["StdDev"]
                $cdf = 0.5 * (1 + (Get-Erf -X ($z / [Math]::Sqrt(2))))
            }
            "Pareto" {
                if ($x -ge $Parameters["Scale"]) {
                    $cdf = 1 - [Math]::Pow($Parameters["Scale"] / $x, $Parameters["Alpha"])
                }
            }
            "Exponential" {
                $cdf = 1 - [Math]::Exp(-$Parameters["Rate"] * $x)
            }
            "LogNormal" {
                if ($x -gt 0) {
                    $z = ([Math]::Log($x) - $Parameters["MeanLog"]) / $Parameters["SdLog"]
                    $cdf = 0.5 * (1 + (Get-Erf -X ($z / [Math]::Sqrt(2))))
                }
            }
            "Weibull" {
                $cdf = 1 - [Math]::Exp( - [Math]::Pow($x / $Parameters["Scale"], $Parameters["Shape"]))
            }
            "Gamma" {
                # Approximation de la fonction de répartition de la loi Gamma
                $a = $Parameters["Shape"]
                $b = $Parameters["Rate"]
                $y = $b * $x

                if ($a -gt 1) {
                    # Utiliser l'approximation de Wilson-Hilferty pour a > 1
                    $z = ([Math]::Pow($y / $a, 1.0 / 3.0) - (1 - 2 / (9 * $a))) / [Math]::Sqrt(2 / (9 * $a))
                    $cdf = 0.5 * (1 + (Get-Erf -X ($z / [Math]::Sqrt(2))))
                } else {
                    # Utiliser une approximation simple pour a <= 1
                    $cdf = 1 - [Math]::Exp(-$y) * (1 + $y / $a)
                }
            }
        }

        $tcdf += $cdf
    }

    # Calculer la statistique de test de Kolmogorov-Smirnov
    $differences = @()
    for ($i = 0; $i -lt $n; $i++) {
        $differences += [Math]::Abs($ecdf[$i] - $tcdf[$i])
    }
    $testStatistic = ($differences | Measure-Object -Maximum).Maximum

    # Calculer la valeur critique pour le niveau de signification spécifié
    $criticalValue = 0
    if ($n -gt 35) {
        # Approximation asymptotique
        $criticalValue = [Math]::Sqrt(-0.5 * [Math]::Log($Alpha / 2)) / [Math]::Sqrt($n)
    } else {
        # Valeurs tabulées pour n <= 35
        $criticalValues = @{
            0.20 = @(0.900, 0.684, 0.565, 0.493, 0.447, 0.410, 0.381, 0.358, 0.339, 0.323, 0.308, 0.296, 0.285, 0.275, 0.266, 0.258, 0.250, 0.244, 0.237, 0.232, 0.226, 0.221, 0.216, 0.212, 0.208, 0.204, 0.200, 0.197, 0.193, 0.190, 0.187, 0.184, 0.182, 0.179, 0.177)
            0.15 = @(0.925, 0.726, 0.597, 0.525, 0.474, 0.436, 0.405, 0.381, 0.360, 0.342, 0.326, 0.313, 0.302, 0.292, 0.283, 0.274, 0.266, 0.259, 0.252, 0.246, 0.241, 0.235, 0.230, 0.226, 0.221, 0.217, 0.213, 0.209, 0.206, 0.202, 0.199, 0.196, 0.193, 0.190, 0.188)
            0.10 = @(0.950, 0.776, 0.642, 0.564, 0.510, 0.470, 0.438, 0.411, 0.388, 0.368, 0.352, 0.338, 0.325, 0.314, 0.304, 0.295, 0.286, 0.279, 0.271, 0.265, 0.259, 0.253, 0.247, 0.242, 0.238, 0.233, 0.229, 0.225, 0.221, 0.218, 0.214, 0.211, 0.208, 0.205, 0.202)
            0.05 = @(0.975, 0.842, 0.708, 0.624, 0.565, 0.521, 0.486, 0.457, 0.432, 0.410, 0.391, 0.375, 0.361, 0.349, 0.338, 0.328, 0.318, 0.309, 0.301, 0.294, 0.287, 0.281, 0.275, 0.269, 0.264, 0.259, 0.254, 0.250, 0.246, 0.242, 0.238, 0.234, 0.231, 0.227, 0.224)
            0.01 = @(0.995, 0.929, 0.828, 0.733, 0.669, 0.618, 0.577, 0.543, 0.514, 0.490, 0.468, 0.450, 0.433, 0.418, 0.404, 0.392, 0.381, 0.371, 0.361, 0.352, 0.344, 0.337, 0.330, 0.323, 0.317, 0.311, 0.305, 0.300, 0.295, 0.290, 0.285, 0.281, 0.277, 0.273, 0.269)
        }

        # Trouver la valeur critique la plus proche
        $alphaKeys = @(0.20, 0.15, 0.10, 0.05, 0.01)
        $closestAlpha = $alphaKeys | Sort-Object -Property { [Math]::Abs($_ - $Alpha) } | Select-Object -First 1

        if ($n -le 35) {
            $criticalValue = $criticalValues[$closestAlpha][$n - 1]
        } else {
            # Utiliser l'approximation asymptotique pour n > 35
            $criticalValue = [Math]::Sqrt(-0.5 * [Math]::Log($closestAlpha / 2)) / [Math]::Sqrt($n)
        }
    }

    # Calculer la p-value
    $pValue = 0
    if ($n -gt 35) {
        # Approximation asymptotique de la p-value
        $pValue = 2 * [Math]::Exp(-2 * $n * $testStatistic * $testStatistic)
    } else {
        # Approximation de la p-value pour n <= 35
        $pValue = [Math]::Exp(-2 * $n * $testStatistic * $testStatistic)
    }

    # Déterminer si la distribution est à queue lourde
    $isHeavyTailed = $false
    $interpretation = ""
    $bestFitDistribution = $Distribution

    if ($testStatistic -gt $criticalValue) {
        # Le test est significatif, la distribution n'est pas celle spécifiée
        if ($Distribution -eq "Normal") {
            # Si la distribution n'est pas normale, tester d'autres distributions
            $bestFitDistribution = "Unknown"
            $bestFitStatistic = $testStatistic
            $bestFitParameters = $Parameters

            # Tester la distribution de Pareto
            $paretoTest = Test-KolmogorovSmirnov -Data $Data -Distribution "Pareto" -Tail $Tail -Alpha $Alpha
            if ($paretoTest.TestStatistic -lt $bestFitStatistic) {
                $bestFitDistribution = "Pareto"
                $bestFitStatistic = $paretoTest.TestStatistic
                $bestFitParameters = $paretoTest.Parameters
            }

            # Tester la distribution log-normale
            $logNormalTest = Test-KolmogorovSmirnov -Data $Data -Distribution "LogNormal" -Tail $Tail -Alpha $Alpha
            if ($logNormalTest.TestStatistic -lt $bestFitStatistic) {
                $bestFitDistribution = "LogNormal"
                $bestFitStatistic = $logNormalTest.TestStatistic
                $bestFitParameters = $logNormalTest.Parameters
            }

            # Déterminer si la distribution est à queue lourde
            if ($bestFitDistribution -eq "Pareto" -or $bestFitDistribution -eq "LogNormal") {
                $isHeavyTailed = $true

                if ($bestFitDistribution -eq "Pareto") {
                    $alpha = $bestFitParameters["Alpha"]
                    if ($alpha -lt 1) {
                        $interpretation = "La distribution a une queue très lourde (Pareto avec alpha < 1). La moyenne n'existe pas."
                    } elseif ($alpha -lt 2) {
                        $interpretation = "La distribution a une queue lourde (Pareto avec 1 <= alpha < 2). La moyenne existe, mais la variance est infinie."
                    } else {
                        $interpretation = "La distribution a une queue modérément lourde (Pareto avec alpha >= 2). La moyenne et la variance existent."
                    }
                } elseif ($bestFitDistribution -eq "LogNormal") {
                    $interpretation = "La distribution a une queue lourde (log-normale). La moyenne et la variance existent, mais les moments d'ordre supérieur peuvent être très grands."
                }
            } else {
                $interpretation = "La distribution n'est pas normale, mais ne correspond pas non plus à une distribution à queue lourde connue."
            }
        } else {
            # Si on a spécifié une distribution à queue lourde et que le test est significatif,
            # cela signifie que les données ne suivent pas cette distribution
            $isHeavyTailed = $false
            $interpretation = "La distribution ne correspond pas à la distribution $Distribution spécifiée."
        }
    } else {
        # Le test n'est pas significatif, la distribution est celle spécifiée
        $bestFitDistribution = $Distribution
        $bestFitParameters = $Parameters

        if ($Distribution -eq "Normal") {
            $isHeavyTailed = $false
            $interpretation = "La distribution est normale, elle n'a pas de queue lourde."
        } elseif ($Distribution -eq "Pareto") {
            $isHeavyTailed = $true
            $alpha = $Parameters["Alpha"]
            if ($alpha -lt 1) {
                $interpretation = "La distribution a une queue très lourde (Pareto avec alpha < 1). La moyenne n'existe pas."
            } elseif ($alpha -lt 2) {
                $interpretation = "La distribution a une queue lourde (Pareto avec 1 <= alpha < 2). La moyenne existe, mais la variance est infinie."
            } else {
                $interpretation = "La distribution a une queue modérément lourde (Pareto avec alpha >= 2). La moyenne et la variance existent."
            }
        } elseif ($Distribution -eq "LogNormal") {
            $isHeavyTailed = $true
            $interpretation = "La distribution a une queue lourde (log-normale). La moyenne et la variance existent, mais les moments d'ordre supérieur peuvent être très grands."
        } elseif ($Distribution -eq "Exponential") {
            $isHeavyTailed = $false
            $interpretation = "La distribution est exponentielle, elle a une queue plus légère que les distributions à queue lourde."
        } elseif ($Distribution -eq "Weibull") {
            $shape = $Parameters["Shape"]
            if ($shape -lt 1) {
                $isHeavyTailed = $true
                $interpretation = "La distribution a une queue lourde (Weibull avec shape < 1)."
            } else {
                $isHeavyTailed = $false
                $interpretation = "La distribution est Weibull avec shape >= 1, elle n'a pas de queue lourde."
            }
        } elseif ($Distribution -eq "Gamma") {
            $shape = $Parameters["Shape"]
            if ($shape -lt 1) {
                $isHeavyTailed = $true
                $interpretation = "La distribution a une queue lourde (Gamma avec shape < 1)."
            } else {
                $isHeavyTailed = $false
                $interpretation = "La distribution est Gamma avec shape >= 1, elle n'a pas de queue lourde."
            }
        }
    }

    # Retourner les résultats
    return [PSCustomObject]@{
        TestStatistic       = $testStatistic
        PValue              = $pValue
        CriticalValue       = $criticalValue
        IsHeavyTailed       = $isHeavyTailed
        BestFitDistribution = $bestFitDistribution
        Parameters          = $bestFitParameters
        Tail                = $Tail
        Interpretation      = $interpretation
    }
}

<#
.SYNOPSIS
    Détecte si une distribution a une queue lourde en utilisant plusieurs méthodes.

.DESCRIPTION
    Cette fonction détecte si une distribution a une queue lourde en utilisant plusieurs méthodes :
    - L'indice de queue de Hill
    - Le test de Kolmogorov-Smirnov
    Elle combine les résultats pour fournir une évaluation plus robuste.

.PARAMETER Data
    Les données à analyser.

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.PARAMETER Alpha
    Le niveau de confiance pour les tests (par défaut 0.05).

.PARAMETER Methods
    Les méthodes à utiliser pour la détection. Options : "Hill", "KS", "QQPlot", "All".
    Par défaut, "All".

.EXAMPLE
    Test-HeavyTailComprehensive -Data $data -Tail "Right" -Methods "All"
    Détecte si la distribution a une queue droite lourde en utilisant toutes les méthodes disponibles.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - IsHeavyTailed : Indique si la distribution est à queue lourde
    - HillIndex : L'indice de queue de Hill
    - KSTestStatistic : La statistique de test de Kolmogorov-Smirnov
    - QQPlotSlope : La pente de la droite de régression pour les points extrêmes du QQ-plot
    - QQPlotCurvature : La courbure du QQ-plot
    - BestFitDistribution : La distribution qui s'ajuste le mieux aux données
    - Tail : La queue analysée
    - Interpretation : Une interprétation des résultats
#>
function Test-HeavyTailComprehensive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right",

        [Parameter(Mandatory = $false)]
        [double]$Alpha = 0.05,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Hill", "KS", "QQPlot", "All")]
        [string]$Methods = "All"
    )

    # Initialiser les résultats
    $hillResults = $null
    $ksResults = $null
    $qqPlotResults = $null

    # Exécuter les méthodes demandées
    if ($Methods -eq "Hill" -or $Methods -eq "All") {
        $hillResults = Test-HeavyTail -Data $Data -Tail $Tail -Alpha $Alpha
    }

    if ($Methods -eq "KS" -or $Methods -eq "All") {
        $ksResults = Test-KolmogorovSmirnov -Data $Data -Tail $Tail -Alpha $Alpha
    }

    if ($Methods -eq "QQPlot" -or $Methods -eq "All") {
        $qqPlotResults = Test-QQPlotHeavyTail -Data $Data -Tail $Tail
    }

    # Combiner les résultats
    $isHeavyTailed = $false
    $interpretation = ""

    if ($Methods -eq "All") {
        # Si toutes les méthodes sont utilisées, combiner les résultats
        $methodsCount = 0
        $heavyTailedCount = 0

        if ($hillResults) {
            $methodsCount++
            if ($hillResults.IsHeavyTailed) {
                $heavyTailedCount++
            }
        }

        if ($ksResults) {
            $methodsCount++
            if ($ksResults.IsHeavyTailed) {
                $heavyTailedCount++
            }
        }

        if ($qqPlotResults) {
            $methodsCount++
            if ($qqPlotResults.IsHeavyTailed) {
                $heavyTailedCount++
            }
        }

        # Déterminer si la distribution est à queue lourde en fonction de la majorité des méthodes
        $isHeavyTailed = $heavyTailedCount -gt ($methodsCount / 2)

        # Construire l'interprétation
        if ($isHeavyTailed) {
            $interpretation = "La majorité des méthodes ($heavyTailedCount sur $methodsCount) indique que la distribution a une queue lourde."

            if ($hillResults -and $hillResults.IsHeavyTailed) {
                $interpretation += " L'indice de queue de Hill est $([Math]::Round($hillResults.HillIndex, 2))."
            }

            if ($ksResults -and $ksResults.IsHeavyTailed) {
                if ($ksResults.BestFitDistribution -eq "Pareto") {
                    $interpretation += " La distribution semble suivre une loi de Pareto avec un paramètre de forme alpha = $([Math]::Round($ksResults.Parameters.Alpha, 2))."
                } elseif ($ksResults.BestFitDistribution -eq "LogNormal") {
                    $interpretation += " La distribution semble suivre une loi log-normale."
                }
            }

            if ($qqPlotResults -and $qqPlotResults.IsHeavyTailed) {
                $interpretation += " L'analyse du QQ-plot confirme la présence d'une queue lourde avec un indice de queue estimé à $([Math]::Round($qqPlotResults.TailIndex, 2))."
            }
        } else {
            $interpretation = "La majorité des méthodes ($($methodsCount - $heavyTailedCount) sur $methodsCount) indique que la distribution n'a pas de queue lourde."

            if ($hillResults -and -not $hillResults.IsHeavyTailed) {
                $interpretation += " L'indice de queue de Hill est $([Math]::Round($hillResults.HillIndex, 2))."
            }

            if ($ksResults -and -not $ksResults.IsHeavyTailed) {
                $interpretation += " Le test de Kolmogorov-Smirnov indique que la distribution est compatible avec une distribution $($ksResults.BestFitDistribution)."
            }

            if ($qqPlotResults -and -not $qqPlotResults.IsHeavyTailed) {
                $interpretation += " L'analyse du QQ-plot ne montre pas de déviation significative par rapport à la distribution de référence."
            }
        }
    } elseif ($Methods -eq "Hill") {
        # Si seule la méthode de Hill est utilisée
        $isHeavyTailed = $hillResults.IsHeavyTailed
        $interpretation = $hillResults.Interpretation
    } elseif ($Methods -eq "KS") {
        # Si seul le test de Kolmogorov-Smirnov est utilisé
        $isHeavyTailed = $ksResults.IsHeavyTailed
        $interpretation = $ksResults.Interpretation
    } elseif ($Methods -eq "QQPlot") {
        # Si seule l'analyse du QQ-plot est utilisée
        $isHeavyTailed = $qqPlotResults.IsHeavyTailed
        $interpretation = $qqPlotResults.Interpretation
    }

    # Retourner les résultats
    return [PSCustomObject]@{
        IsHeavyTailed          = $isHeavyTailed
        HillIndex              = if ($hillResults) { $hillResults.HillIndex } else { $null }
        HillLowerCI            = if ($hillResults) { $hillResults.LowerCI } else { $null }
        HillUpperCI            = if ($hillResults) { $hillResults.UpperCI } else { $null }
        KSTestStatistic        = if ($ksResults) { $ksResults.TestStatistic } else { $null }
        KSPValue               = if ($ksResults) { $ksResults.PValue } else { $null }
        QQPlotSlope            = if ($qqPlotResults) { $qqPlotResults.Slope } else { $null }
        QQPlotCurvature        = if ($qqPlotResults) { $qqPlotResults.Curvature } else { $null }
        BestFitDistribution    = if ($ksResults) { $ksResults.BestFitDistribution } else { $null }
        DistributionParameters = if ($ksResults) { $ksResults.Parameters } else { $null }
        Tail                   = $Tail
        Interpretation         = $interpretation
    }
}

<#
.SYNOPSIS
    Calcule les quantiles théoriques pour une distribution normale.

.DESCRIPTION
    Cette fonction calcule les quantiles théoriques pour une distribution normale
    avec une moyenne et un écart-type spécifiés.

.PARAMETER Probabilities
    Les probabilités pour lesquelles calculer les quantiles (entre 0 et 1).

.PARAMETER Mean
    La moyenne de la distribution normale (par défaut 0).

.PARAMETER StdDev
    L'écart-type de la distribution normale (par défaut 1).

.EXAMPLE
    Get-NormalQuantiles -Probabilities @(0.25, 0.5, 0.75) -Mean 0 -StdDev 1
    Calcule les quantiles de la distribution normale standard pour les probabilités 0.25, 0.5 et 0.75.

.OUTPUTS
    System.Double[]
#>
function Get-NormalQuantiles {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [double[]]$Probabilities,

        [Parameter(Position = 1)]
        [double]$Mean = 0,

        [Parameter(Position = 2)]
        [double]$StdDev = 1
    )

    $quantiles = @()

    foreach ($p in $Probabilities) {
        # Utiliser la fonction Get-NormalQuantile pour calculer le quantile de la distribution normale standard
        $z = Get-NormalQuantile -P $p

        # Transformer le quantile de la distribution normale standard en quantile de la distribution normale spécifiée
        $quantile = $Mean + $StdDev * $z

        $quantiles += $quantile
    }

    return $quantiles
}

<#
.SYNOPSIS
    Calcule les quantiles théoriques pour une distribution de Pareto.

.DESCRIPTION
    Cette fonction calcule les quantiles théoriques pour une distribution de Pareto
    avec un paramètre de forme (alpha) et un paramètre d'échelle (scale) spécifiés.

.PARAMETER Probabilities
    Les probabilités pour lesquelles calculer les quantiles (entre 0 et 1).

.PARAMETER Alpha
    Le paramètre de forme de la distribution de Pareto (par défaut 1).

.PARAMETER Scale
    Le paramètre d'échelle de la distribution de Pareto (par défaut 1).

.EXAMPLE
    Get-ParetoQuantiles -Probabilities @(0.25, 0.5, 0.75) -Alpha 1.5 -Scale 1
    Calcule les quantiles de la distribution de Pareto pour les probabilités 0.25, 0.5 et 0.75.

.OUTPUTS
    System.Double[]
#>
function Get-ParetoQuantiles {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [double[]]$Probabilities,

        [Parameter(Mandatory = $false, Position = 1)]
        [double]$Alpha = 1,

        [Parameter(Mandatory = $false, Position = 2)]
        [double]$Scale = 1
    )

    $quantiles = @()

    foreach ($p in $Probabilities) {
        # Calculer le quantile de la distribution de Pareto
        # F(x) = 1 - (scale/x)^alpha
        # x = scale / (1 - p)^(1/alpha)

        if ($p -eq 1) {
            $quantile = [double]::PositiveInfinity
        } else {
            $quantile = $Scale / [Math]::Pow(1 - $p, 1 / $Alpha)
        }

        $quantiles += $quantile
    }

    return $quantiles
}

<#
.SYNOPSIS
    Calcule les quantiles théoriques pour une distribution exponentielle.

.DESCRIPTION
    Cette fonction calcule les quantiles théoriques pour une distribution exponentielle
    avec un paramètre de taux (rate) spécifié.

.PARAMETER Probabilities
    Les probabilités pour lesquelles calculer les quantiles (entre 0 et 1).

.PARAMETER Rate
    Le paramètre de taux de la distribution exponentielle (par défaut 1).

.EXAMPLE
    Get-ExponentialQuantiles -Probabilities @(0.25, 0.5, 0.75) -Rate 1
    Calcule les quantiles de la distribution exponentielle pour les probabilités 0.25, 0.5 et 0.75.

.OUTPUTS
    System.Double[]
#>
function Get-ExponentialQuantiles {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Probabilities,

        [Parameter(Mandatory = $false)]
        [double]$Rate = 1
    )

    $quantiles = @()

    foreach ($p in $Probabilities) {
        # Calculer le quantile de la distribution exponentielle
        # F(x) = 1 - exp(-rate * x)
        # x = -ln(1 - p) / rate

        if ($p -eq 1) {
            $quantile = [double]::PositiveInfinity
        } else {
            $quantile = - [Math]::Log(1 - $p) / $Rate
        }

        $quantiles += $quantile
    }

    return $quantiles
}

<#
.SYNOPSIS
    Calcule les quantiles théoriques pour une distribution log-normale.

.DESCRIPTION
    Cette fonction calcule les quantiles théoriques pour une distribution log-normale
    avec une moyenne et un écart-type du logarithme spécifiés.

.PARAMETER Probabilities
    Les probabilités pour lesquelles calculer les quantiles (entre 0 et 1).

.PARAMETER MeanLog
    La moyenne du logarithme de la distribution log-normale (par défaut 0).

.PARAMETER SdLog
    L'écart-type du logarithme de la distribution log-normale (par défaut 1).

.EXAMPLE
    Get-LogNormalQuantiles -Probabilities @(0.25, 0.5, 0.75) -MeanLog 0 -SdLog 1
    Calcule les quantiles de la distribution log-normale pour les probabilités 0.25, 0.5 et 0.75.

.OUTPUTS
    System.Double[]
#>
function Get-LogNormalQuantiles {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Probabilities,

        [Parameter(Mandatory = $false)]
        [double]$MeanLog = 0,

        [Parameter(Mandatory = $false)]
        [double]$SdLog = 1
    )

    $quantiles = @()

    foreach ($p in $Probabilities) {
        # Calculer le quantile de la distribution log-normale
        # Si Z suit une loi normale de moyenne meanLog et d'écart-type sdLog,
        # alors X = exp(Z) suit une loi log-normale

        # Utiliser la fonction Get-NormalQuantile pour calculer le quantile de la distribution normale standard
        $z = Get-NormalQuantile -P $p

        # Transformer le quantile de la distribution normale standard en quantile de la distribution normale spécifiée
        $normalQuantile = $MeanLog + $SdLog * $z

        # Transformer le quantile de la distribution normale en quantile de la distribution log-normale
        $quantile = [Math]::Exp($normalQuantile)

        $quantiles += $quantile
    }

    return $quantiles
}

<#
.SYNOPSIS
    Calcule les quantiles théoriques pour une distribution spécifiée.

.DESCRIPTION
    Cette fonction calcule les quantiles théoriques pour une distribution spécifiée
    avec les paramètres fournis.

.PARAMETER Probabilities
    Les probabilités pour lesquelles calculer les quantiles (entre 0 et 1).

.PARAMETER Distribution
    La distribution théorique à utiliser pour le calcul des quantiles.
    Options : "Normal", "Pareto", "Exponential", "LogNormal", "Weibull", "Gamma".
    Par défaut, "Normal".

.PARAMETER Parameters
    Les paramètres de la distribution théorique. Si non spécifiés, les valeurs par défaut seront utilisées.
    Pour la distribution normale, il s'agit de la moyenne et de l'écart-type.
    Pour la distribution de Pareto, il s'agit du paramètre de forme (alpha) et du paramètre d'échelle (scale).

.EXAMPLE
    Get-TheoreticalQuantiles -Probabilities @(0.25, 0.5, 0.75) -Distribution "Normal" -Parameters @{Mean = 0; StdDev = 1}
    Calcule les quantiles de la distribution normale standard pour les probabilités 0.25, 0.5 et 0.75.

.OUTPUTS
    System.Double[]
#>
function Get-TheoreticalQuantiles {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Default')]
        [double[]]$Probabilities,

        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'Default')]
        [ValidateSet("Normal", "Pareto", "Exponential", "LogNormal", "Weibull", "Gamma")]
        [string]$Distribution = "Normal",

        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'Default')]
        [hashtable]$Parameters = @{}
    )

    # Vérifier que les probabilités sont valides
    foreach ($p in $Probabilities) {
        if ($p -lt 0 -or $p -gt 1) {
            throw "Les probabilités doivent être comprises entre 0 et 1."
        }
    }

    # Calculer les quantiles en fonction de la distribution spécifiée
    switch ($Distribution) {
        "Normal" {
            $mean = if ($Parameters.ContainsKey("Mean")) { $Parameters["Mean"] } else { 0 }
            $stdDev = if ($Parameters.ContainsKey("StdDev")) { $Parameters["StdDev"] } else { 1 }

            return Get-NormalQuantiles -Probabilities $Probabilities -Mean $mean -StdDev $stdDev
        }
        "Pareto" {
            $alpha = if ($Parameters.ContainsKey("Alpha")) { $Parameters["Alpha"] } else { 1 }
            $scale = if ($Parameters.ContainsKey("Scale")) { $Parameters["Scale"] } else { 1 }

            return Get-ParetoQuantiles -Probabilities $Probabilities -Alpha $alpha -Scale $scale
        }
        "Exponential" {
            $rate = if ($Parameters.ContainsKey("Rate")) { $Parameters["Rate"] } else { 1 }

            return Get-ExponentialQuantiles -Probabilities $Probabilities -Rate $rate
        }
        "LogNormal" {
            $meanLog = if ($Parameters.ContainsKey("MeanLog")) { $Parameters["MeanLog"] } else { 0 }
            $sdLog = if ($Parameters.ContainsKey("SdLog")) { $Parameters["SdLog"] } else { 1 }

            return Get-LogNormalQuantiles -Probabilities $Probabilities -MeanLog $meanLog -SdLog $sdLog
        }
        "Weibull" {
            $shape = if ($Parameters.ContainsKey("Shape")) { $Parameters["Shape"] } else { 1 }
            $scale = if ($Parameters.ContainsKey("Scale")) { $Parameters["Scale"] } else { 1 }

            $quantiles = @()

            foreach ($p in $Probabilities) {
                # Calculer le quantile de la distribution de Weibull
                # F(x) = 1 - exp(-(x/scale)^shape)
                # x = scale * (-ln(1 - p))^(1/shape)

                if ($p -eq 1) {
                    $quantile = [double]::PositiveInfinity
                } else {
                    $quantile = $scale * [Math]::Pow( - [Math]::Log(1 - $p), 1 / $shape)
                }

                $quantiles += $quantile
            }

            return $quantiles
        }
        "Gamma" {
            $shape = if ($Parameters.ContainsKey("Shape")) { $Parameters["Shape"] } else { 1 }
            $rate = if ($Parameters.ContainsKey("Rate")) { $Parameters["Rate"] } else { 1 }

            # Pour la distribution gamma, il n'existe pas de formule analytique simple pour les quantiles
            # On utilise une approximation basée sur la distribution normale

            $quantiles = @()

            foreach ($p in $Probabilities) {
                # Approximation du quantile de la distribution gamma
                # Basée sur l'approximation de Wilson-Hilferty

                if ($p -eq 0) {
                    $quantile = 0
                } elseif ($p -eq 1) {
                    $quantile = [double]::PositiveInfinity
                } else {
                    $z = Get-NormalQuantile -P $p

                    if ($shape -ge 1) {
                        # Approximation de Wilson-Hilferty pour shape >= 1
                        $quantile = $shape / $rate * [Math]::Pow(1 - 2 / (9 * $shape) + $z * [Math]::Sqrt(2 / (9 * $shape)), 3)
                    } else {
                        # Approximation simple pour shape < 1
                        $mean = $shape / $rate
                        $variance = $shape / ($rate * $rate)
                        $quantile = $mean + $z * [Math]::Sqrt($variance)
                        $quantile = [Math]::Max(0, $quantile)  # Les quantiles de la distribution gamma sont toujours positifs
                    }
                }

                $quantiles += $quantile
            }

            return $quantiles
        }
        default {
            throw "Distribution non prise en charge : $Distribution"
        }
    }
}

<#
.SYNOPSIS
    Calcule les quantiles empiriques à partir des données.

.DESCRIPTION
    Cette fonction calcule les quantiles empiriques à partir des données
    pour un ensemble de probabilités spécifiées.

.PARAMETER Data
    Les données pour lesquelles calculer les quantiles empiriques.

.PARAMETER Probabilities
    Les probabilités pour lesquelles calculer les quantiles (entre 0 et 1).
    Si non spécifiées, des probabilités uniformément réparties seront utilisées.

.PARAMETER NumPoints
    Le nombre de points à utiliser pour les probabilités si elles ne sont pas spécifiées.
    Par défaut, 100.

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.EXAMPLE
    Get-EmpiricalQuantiles -Data $data -Probabilities @(0.25, 0.5, 0.75)
    Calcule les quantiles empiriques pour les probabilités 0.25, 0.5 et 0.75.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - Probabilities : Les probabilités utilisées
    - Quantiles : Les quantiles empiriques correspondants
#>
function Get-EmpiricalQuantiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [double[]]$Data,

        [Parameter(Position = 1)]
        [AllowNull()]
        [double[]]$Probabilities = $null,

        [Parameter(Position = 2)]
        [int]$NumPoints = 100,

        [Parameter(Position = 3)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right"
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour calculer les quantiles empiriques."
    }

    # Préparer les données en fonction de la queue à analyser
    $processedData = $Data
    if ($Tail -eq "Left") {
        # Pour la queue gauche, on utilise l'opposé des données
        $processedData = $Data | ForEach-Object { - $_ }
    } elseif ($Tail -eq "Both") {
        # Pour les deux queues, on utilise la valeur absolue des données
        $processedData = $Data | ForEach-Object { [Math]::Abs($_) }
    }

    # Trier les données
    $sortedData = $processedData | Sort-Object

    # Générer les probabilités si non spécifiées
    if ($null -eq $Probabilities) {
        $Probabilities = @()
        for ($i = 0; $i -lt $NumPoints; $i++) {
            $Probabilities += ($i + 0.5) / $NumPoints
        }
    }

    # Vérifier que les probabilités sont valides
    foreach ($p in $Probabilities) {
        if ($p -lt 0 -or $p -gt 1) {
            throw "Les probabilités doivent être comprises entre 0 et 1."
        }
    }

    # Calculer les quantiles empiriques
    $quantiles = @()
    $n = $sortedData.Count

    foreach ($p in $Probabilities) {
        # Calculer l'indice correspondant à la probabilité p
        $index = $p * ($n - 1)
        $lowerIndex = [Math]::Floor($index)
        $upperIndex = [Math]::Ceiling($index)

        # Interpoler entre les deux valeurs les plus proches
        if ($lowerIndex -eq $upperIndex) {
            $quantile = $sortedData[$lowerIndex]
        } else {
            $weight = $index - $lowerIndex
            $quantile = (1 - $weight) * $sortedData[$lowerIndex] + $weight * $sortedData[$upperIndex]
        }

        $quantiles += $quantile
    }

    # Retourner les résultats
    return [PSCustomObject]@{
        Probabilities = $Probabilities
        Quantiles     = $quantiles
    }
}

<#
.SYNOPSIS
    Génère les données pour un QQ-plot.

.DESCRIPTION
    Cette fonction génère les données pour un QQ-plot en comparant les quantiles empiriques
    des données avec les quantiles théoriques d'une distribution spécifiée.

.PARAMETER Data
    Les données pour lesquelles générer le QQ-plot.

.PARAMETER Distribution
    La distribution théorique à utiliser pour la comparaison.
    Options : "Normal", "Pareto", "Exponential", "LogNormal", "Weibull", "Gamma".
    Par défaut, "Normal".

.PARAMETER Parameters
    Les paramètres de la distribution théorique. Si non spécifiés, ils seront estimés à partir des données.
    Pour la distribution normale, il s'agit de la moyenne et de l'écart-type.
    Pour la distribution de Pareto, il s'agit du paramètre de forme (alpha) et du paramètre d'échelle (scale).

.PARAMETER NumPoints
    Le nombre de points à utiliser pour le QQ-plot.
    Par défaut, 100.

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.EXAMPLE
    Get-QQPlotData -Data $data -Distribution "Normal"
    Génère les données pour un QQ-plot comparant les données à une distribution normale.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - TheoreticalQuantiles : Les quantiles théoriques
    - EmpiricalQuantiles : Les quantiles empiriques correspondants
    - Distribution : La distribution théorique utilisée
    - Parameters : Les paramètres de la distribution théorique
#>
function Get-QQPlotData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Pareto", "Exponential", "LogNormal", "Weibull", "Gamma")]
        [string]$Distribution = "Normal",

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = $null,

        [Parameter(Mandatory = $false)]
        [int]$NumPoints = 100,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right"
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour générer un QQ-plot."
    }

    # Préparer les données en fonction de la queue à analyser
    $processedData = $Data
    if ($Tail -eq "Left") {
        # Pour la queue gauche, on utilise l'opposé des données
        $processedData = $Data | ForEach-Object { - $_ }
    } elseif ($Tail -eq "Both") {
        # Pour les deux queues, on utilise la valeur absolue des données
        $processedData = $Data | ForEach-Object { [Math]::Abs($_) }
    }

    # Estimer les paramètres de la distribution si non spécifiés
    if ($null -eq $Parameters) {
        $Parameters = @{}

        switch ($Distribution) {
            "Normal" {
                $Parameters["Mean"] = ($processedData | Measure-Object -Average).Average
                $Parameters["StdDev"] = [Math]::Sqrt(($processedData | ForEach-Object { [Math]::Pow($_ - $Parameters["Mean"], 2) } | Measure-Object -Average).Average)
            }
            "Pareto" {
                # Estimer le paramètre de forme (alpha) en utilisant la méthode du maximum de vraisemblance
                $minValue = ($processedData | Measure-Object -Minimum).Minimum
                if ($minValue -le 0) {
                    $minValue = 0.001  # Éviter les valeurs négatives ou nulles
                }
                $Parameters["Scale"] = $minValue
                $logSum = 0
                foreach ($x in $processedData) {
                    if ($x -gt $minValue) {
                        $logSum += [Math]::Log($x / $minValue)
                    }
                }
                $Parameters["Alpha"] = $processedData.Count / $logSum
            }
            "Exponential" {
                $Parameters["Rate"] = 1 / ($processedData | Measure-Object -Average).Average
            }
            "LogNormal" {
                $logData = $processedData | Where-Object { $_ -gt 0 } | ForEach-Object { [Math]::Log($_) }
                $Parameters["MeanLog"] = ($logData | Measure-Object -Average).Average
                $Parameters["SdLog"] = [Math]::Sqrt(($logData | ForEach-Object { [Math]::Pow($_ - $Parameters["MeanLog"], 2) } | Measure-Object -Average).Average)
            }
            "Weibull" {
                # Estimation approximative des paramètres de Weibull
                $mean = ($processedData | Measure-Object -Average).Average
                $variance = ($processedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
                $cv = [Math]::Sqrt($variance) / $mean
                $Parameters["Shape"] = [Math]::Pow(0.9 / $cv, 1.086)
                $Parameters["Scale"] = $mean / [Math]::Gamma(1 + 1 / $Parameters["Shape"])
            }
            "Gamma" {
                # Estimation approximative des paramètres de Gamma
                $mean = ($processedData | Measure-Object -Average).Average
                $variance = ($processedData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
                $Parameters["Shape"] = [Math]::Pow($mean, 2) / $variance
                $Parameters["Rate"] = $mean / $variance
            }
        }
    }

    # Générer les probabilités
    $probabilities = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        $probabilities += ($i + 0.5) / $NumPoints
    }

    # Calculer les quantiles empiriques
    $empiricalQuantiles = Get-EmpiricalQuantiles -Data $processedData -Probabilities $probabilities

    # Calculer les quantiles théoriques
    $theoreticalQuantiles = Get-TheoreticalQuantiles -Probabilities $probabilities -Distribution $Distribution -Parameters $Parameters

    # Retourner les résultats
    return [PSCustomObject]@{
        TheoreticalQuantiles = $theoreticalQuantiles
        EmpiricalQuantiles   = $empiricalQuantiles.Quantiles
        Probabilities        = $probabilities
        Distribution         = $Distribution
        Parameters           = $Parameters
    }
}

<#
.SYNOPSIS
    Effectue une régression linéaire sur un ensemble de points.

.DESCRIPTION
    Cette fonction effectue une régression linéaire sur un ensemble de points
    pour déterminer la pente et l'ordonnée à l'origine de la droite qui s'ajuste le mieux aux données.

.PARAMETER X
    Les valeurs de l'axe des abscisses.

.PARAMETER Y
    Les valeurs de l'axe des ordonnées.

.EXAMPLE
    Get-LinearRegression -X @(1, 2, 3) -Y @(2, 4, 6)
    Effectue une régression linéaire sur les points (1,2), (2,4) et (3,6).

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - Slope : La pente de la droite de régression
    - Intercept : L'ordonnée à l'origine de la droite de régression
    - RSquared : Le coefficient de détermination (R²)
    - PredictedValues : Les valeurs prédites par la droite de régression
    - Residuals : Les résidus (différences entre les valeurs observées et prédites)
#>
function Get-LinearRegression {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNull()]
        [double[]]$X,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNull()]
        [double[]]$Y
    )

    # Vérifier que les tableaux X et Y ont la même longueur
    if ($X.Count -ne $Y.Count) {
        throw "Les tableaux X et Y doivent avoir la même longueur."
    }

    # Vérifier qu'il y a au moins 2 points
    if ($X.Count -lt 2) {
        throw "Il faut au moins 2 points pour effectuer une régression linéaire."
    }

    # Calculer les moyennes
    $meanX = ($X | Measure-Object -Average).Average
    $meanY = ($Y | Measure-Object -Average).Average

    # Calculer les sommes nécessaires pour la régression
    $sumXY = 0
    $sumXX = 0
    $sumYY = 0

    for ($i = 0; $i -lt $X.Count; $i++) {
        $xDiff = $X[$i] - $meanX
        $yDiff = $Y[$i] - $meanY

        $sumXY += $xDiff * $yDiff
        $sumXX += $xDiff * $xDiff
        $sumYY += $yDiff * $yDiff
    }

    # Calculer la pente et l'ordonnée à l'origine
    $slope = if ($sumXX -eq 0) { 0 } else { $sumXY / $sumXX }
    $intercept = $meanY - $slope * $meanX

    # Calculer les valeurs prédites et les résidus
    $predictedValues = @()
    $residuals = @()

    for ($i = 0; $i -lt $X.Count; $i++) {
        $predicted = $intercept + $slope * $X[$i]
        $predictedValues += $predicted
        $residuals += $Y[$i] - $predicted
    }

    # Calculer le coefficient de détermination (R²)
    $rSquared = if ($sumYY -eq 0) { 1 } else { ($sumXY * $sumXY) / ($sumXX * $sumYY) }

    # Retourner les résultats
    return [PSCustomObject]@{
        Slope           = $slope
        Intercept       = $intercept
        RSquared        = $rSquared
        PredictedValues = $predictedValues
        Residuals       = $residuals
    }
}

<#
.SYNOPSIS
    Analyse les extrémités d'un QQ-plot pour détecter les queues lourdes.

.DESCRIPTION
    Cette fonction analyse les extrémités d'un QQ-plot pour détecter les queues lourdes
    en effectuant une régression linéaire sur les points extrêmes et en analysant la pente.

.PARAMETER QQPlotData
    Les données du QQ-plot, générées par la fonction Get-QQPlotData.

.PARAMETER TailFraction
    La fraction des points à utiliser pour l'analyse des extrémités.
    Par défaut, 0.1 (10% des points).

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.EXAMPLE
    Get-QQPlotTailAnalysis -QQPlotData $qqPlotData -TailFraction 0.1 -Tail "Right"
    Analyse la queue droite d'un QQ-plot en utilisant 10% des points extrêmes.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - Slope : La pente de la droite de régression pour les points extrêmes
    - Intercept : L'ordonnée à l'origine de la droite de régression pour les points extrêmes
    - RSquared : Le coefficient de détermination (R²) pour la régression
    - IsHeavyTailed : Indique si la distribution est à queue lourde
    - TailIndex : L'indice de queue estimé à partir de la pente
    - Tail : La queue analysée
    - Interpretation : Une interprétation des résultats
#>
function Get-QQPlotTailAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$QQPlotData,

        [Parameter(Mandatory = $false)]
        [double]$TailFraction = 0.1,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right"
    )

    # Vérifier que les données du QQ-plot sont valides
    if ($null -eq $QQPlotData.TheoreticalQuantiles -or $null -eq $QQPlotData.EmpiricalQuantiles) {
        throw "Les données du QQ-plot ne sont pas valides."
    }

    # Déterminer les points à utiliser pour l'analyse des extrémités
    $n = $QQPlotData.TheoreticalQuantiles.Count
    $tailSize = [Math]::Max(2, [Math]::Floor($n * $TailFraction))

    $theoreticalQuantiles = @()
    $empiricalQuantiles = @()

    if ($Tail -eq "Right") {
        # Utiliser les points de la queue droite (les plus grands)
        $theoreticalQuantiles = $QQPlotData.TheoreticalQuantiles | Select-Object -Last $tailSize
        $empiricalQuantiles = $QQPlotData.EmpiricalQuantiles | Select-Object -Last $tailSize
    } elseif ($Tail -eq "Left") {
        # Utiliser les points de la queue gauche (les plus petits)
        $theoreticalQuantiles = $QQPlotData.TheoreticalQuantiles | Select-Object -First $tailSize
        $empiricalQuantiles = $QQPlotData.EmpiricalQuantiles | Select-Object -First $tailSize
    } elseif ($Tail -eq "Both") {
        # Utiliser les points des deux queues
        $halfTailSize = [Math]::Max(1, [Math]::Floor($tailSize / 2))

        $leftTheoreticalQuantiles = $QQPlotData.TheoreticalQuantiles | Select-Object -First $halfTailSize
        $leftEmpiricalQuantiles = $QQPlotData.EmpiricalQuantiles | Select-Object -First $halfTailSize

        $rightTheoreticalQuantiles = $QQPlotData.TheoreticalQuantiles | Select-Object -Last $halfTailSize
        $rightEmpiricalQuantiles = $QQPlotData.EmpiricalQuantiles | Select-Object -Last $halfTailSize

        $theoreticalQuantiles = $leftTheoreticalQuantiles + $rightTheoreticalQuantiles
        $empiricalQuantiles = $leftEmpiricalQuantiles + $rightEmpiricalQuantiles
    }

    # Effectuer une régression linéaire sur les points extrêmes
    $regression = Get-LinearRegression -X $theoreticalQuantiles -Y $empiricalQuantiles

    # Déterminer si la distribution est à queue lourde en fonction de la pente
    $isHeavyTailed = $false
    $tailIndex = 0
    $interpretation = ""

    # La pente du QQ-plot est liée à l'indice de queue
    # Pour une distribution normale vs une distribution à queue lourde :
    # - Si la pente est > 1, la distribution a une queue plus lourde que la normale
    # - Pour une distribution de Pareto, la pente est approximativement égale à 1/alpha

    if ($QQPlotData.Distribution -eq "Normal") {
        if ($regression.Slope -gt 1.2) {
            $isHeavyTailed = $true
            $tailIndex = 1 / $regression.Slope

            if ($tailIndex -lt 1) {
                $interpretation = "La distribution a une queue très lourde (indice < 1). La moyenne n'existe pas."
            } elseif ($tailIndex -lt 2) {
                $interpretation = "La distribution a une queue lourde (1 <= indice < 2). La moyenne existe, mais la variance est infinie."
            } else {
                $interpretation = "La distribution a une queue modérément lourde (indice >= 2). La moyenne et la variance existent."
            }
        } else {
            $isHeavyTailed = $false
            $tailIndex = [double]::PositiveInfinity
            $interpretation = "La distribution n'a pas de queue lourde. Elle est compatible avec une distribution normale."
        }
    } elseif ($QQPlotData.Distribution -eq "Pareto") {
        # Pour un QQ-plot Pareto vs Pareto, la pente est approximativement égale au rapport des indices de queue
        $alpha = $QQPlotData.Parameters["Alpha"]
        $estimatedAlpha = $alpha / $regression.Slope
        $tailIndex = $estimatedAlpha

        if ($tailIndex -lt 2) {
            $isHeavyTailed = $true

            if ($tailIndex -lt 1) {
                $interpretation = "La distribution a une queue très lourde (indice < 1). La moyenne n'existe pas."
            } else {
                $interpretation = "La distribution a une queue lourde (1 <= indice < 2). La moyenne existe, mais la variance est infinie."
            }
        } else {
            $isHeavyTailed = $false
            $interpretation = "La distribution a une queue modérément lourde (indice >= 2). La moyenne et la variance existent."
        }
    } else {
        # Pour les autres distributions, utiliser une heuristique basée sur la pente
        if ($regression.Slope -gt 1.2) {
            $isHeavyTailed = $true
            $tailIndex = 1 / $regression.Slope

            if ($tailIndex -lt 1) {
                $interpretation = "La distribution a une queue très lourde (indice < 1). La moyenne n'existe pas."
            } elseif ($tailIndex -lt 2) {
                $interpretation = "La distribution a une queue lourde (1 <= indice < 2). La moyenne existe, mais la variance est infinie."
            } else {
                $interpretation = "La distribution a une queue modérément lourde (indice >= 2). La moyenne et la variance existent."
            }
        } else {
            $isHeavyTailed = $false
            $tailIndex = [double]::PositiveInfinity
            $interpretation = "La distribution n'a pas de queue lourde."
        }
    }

    # Retourner les résultats
    return [PSCustomObject]@{
        Slope          = $regression.Slope
        Intercept      = $regression.Intercept
        RSquared       = $regression.RSquared
        IsHeavyTailed  = $isHeavyTailed
        TailIndex      = $tailIndex
        Tail           = $Tail
        Interpretation = $interpretation
    }
}

<#
.SYNOPSIS
    Calcule la courbure d'un QQ-plot pour détecter les queues lourdes.

.DESCRIPTION
    Cette fonction calcule la courbure d'un QQ-plot pour détecter les queues lourdes
    en analysant les résidus de la régression linéaire.

.PARAMETER QQPlotData
    Les données du QQ-plot, générées par la fonction Get-QQPlotData.

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.EXAMPLE
    Get-QQPlotCurvature -QQPlotData $qqPlotData -Tail "Right"
    Calcule la courbure de la queue droite d'un QQ-plot.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - Curvature : La courbure du QQ-plot
    - IsHeavyTailed : Indique si la distribution est à queue lourde
    - Tail : La queue analysée
    - Interpretation : Une interprétation des résultats
#>
function Get-QQPlotCurvature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$QQPlotData,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right"
    )

    # Vérifier que les données du QQ-plot sont valides
    if ($null -eq $QQPlotData.TheoreticalQuantiles -or $null -eq $QQPlotData.EmpiricalQuantiles) {
        throw "Les données du QQ-plot ne sont pas valides."
    }

    # Effectuer une régression linéaire sur tous les points
    $regression = Get-LinearRegression -X $QQPlotData.TheoreticalQuantiles -Y $QQPlotData.EmpiricalQuantiles

    # Calculer les résidus
    $residuals = $regression.Residuals

    # Déterminer les points à utiliser pour l'analyse de la courbure
    $n = $QQPlotData.TheoreticalQuantiles.Count
    $tailSize = [Math]::Max(2, [Math]::Floor($n * 0.2))  # Utiliser 20% des points pour l'analyse

    $tailResiduals = @()

    if ($Tail -eq "Right") {
        # Utiliser les résidus de la queue droite (les plus grands)
        $tailResiduals = $residuals | Select-Object -Last $tailSize
    } elseif ($Tail -eq "Left") {
        # Utiliser les résidus de la queue gauche (les plus petits)
        $tailResiduals = $residuals | Select-Object -First $tailSize
    } elseif ($Tail -eq "Both") {
        # Utiliser les résidus des deux queues
        $halfTailSize = [Math]::Max(1, [Math]::Floor($tailSize / 2))

        $leftResiduals = $residuals | Select-Object -First $halfTailSize
        $rightResiduals = $residuals | Select-Object -Last $halfTailSize

        $tailResiduals = $leftResiduals + $rightResiduals
    }

    # Calculer la courbure comme la moyenne des résidus
    $curvature = ($tailResiduals | Measure-Object -Average).Average

    # Déterminer si la distribution est à queue lourde en fonction de la courbure
    $isHeavyTailed = $false
    $interpretation = ""

    if ($Tail -eq "Right") {
        if ($curvature -gt 0.1) {
            $isHeavyTailed = $true
            $interpretation = "La queue droite est plus lourde que celle de la distribution de référence (courbure positive)."
        } elseif ($curvature -lt -0.1) {
            $isHeavyTailed = $false
            $interpretation = "La queue droite est plus légère que celle de la distribution de référence (courbure négative)."
        } else {
            $isHeavyTailed = $false
            $interpretation = "La queue droite est similaire à celle de la distribution de référence (courbure proche de zéro)."
        }
    } elseif ($Tail -eq "Left") {
        if ($curvature -lt -0.1) {
            $isHeavyTailed = $true
            $interpretation = "La queue gauche est plus lourde que celle de la distribution de référence (courbure négative)."
        } elseif ($curvature -gt 0.1) {
            $isHeavyTailed = $false
            $interpretation = "La queue gauche est plus légère que celle de la distribution de référence (courbure positive)."
        } else {
            $isHeavyTailed = $false
            $interpretation = "La queue gauche est similaire à celle de la distribution de référence (courbure proche de zéro)."
        }
    } elseif ($Tail -eq "Both") {
        if ([Math]::Abs($curvature) -gt 0.1) {
            $isHeavyTailed = $true
            $interpretation = "Les queues sont différentes de celles de la distribution de référence (courbure non nulle)."
        } else {
            $isHeavyTailed = $false
            $interpretation = "Les queues sont similaires à celles de la distribution de référence (courbure proche de zéro)."
        }
    }

    # Retourner les résultats
    return [PSCustomObject]@{
        Curvature      = $curvature
        IsHeavyTailed  = $isHeavyTailed
        Tail           = $Tail
        Interpretation = $interpretation
    }
}

<#
.SYNOPSIS
    Détecte si une distribution a une queue lourde en utilisant un QQ-plot.

.DESCRIPTION
    Cette fonction détecte si une distribution a une queue lourde en utilisant un QQ-plot.
    Elle combine l'analyse de la pente et de la courbure pour fournir une évaluation robuste.

.PARAMETER Data
    Les données à analyser.

.PARAMETER Distribution
    La distribution théorique à utiliser pour la comparaison.
    Options : "Normal", "Pareto", "Exponential", "LogNormal", "Weibull", "Gamma".
    Par défaut, "Normal".

.PARAMETER Parameters
    Les paramètres de la distribution théorique. Si non spécifiés, ils seront estimés à partir des données.
    Pour la distribution normale, il s'agit de la moyenne et de l'écart-type.
    Pour la distribution de Pareto, il s'agit du paramètre de forme (alpha) et du paramètre d'échelle (scale).

.PARAMETER NumPoints
    Le nombre de points à utiliser pour le QQ-plot.
    Par défaut, 100.

.PARAMETER Tail
    La queue à analyser : "Right" (droite), "Left" (gauche) ou "Both" (les deux).
    Par défaut, "Right".

.PARAMETER TailFraction
    La fraction des points à utiliser pour l'analyse des extrémités.
    Par défaut, 0.1 (10% des points).

.EXAMPLE
    Test-QQPlotHeavyTail -Data $data -Distribution "Normal" -Tail "Right"
    Détecte si la distribution a une queue droite lourde en utilisant un QQ-plot normal.

.OUTPUTS
    PSObject avec les propriétés suivantes :
    - IsHeavyTailed : Indique si la distribution est à queue lourde
    - TailIndex : L'indice de queue estimé à partir de la pente
    - Slope : La pente de la droite de régression pour les points extrêmes
    - Curvature : La courbure du QQ-plot
    - Distribution : La distribution théorique utilisée
    - Parameters : Les paramètres de la distribution théorique
    - Tail : La queue analysée
    - Interpretation : Une interprétation des résultats
#>
function Test-QQPlotHeavyTail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "Pareto", "Exponential", "LogNormal", "Weibull", "Gamma")]
        [string]$Distribution = "Normal",

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = $null,

        [Parameter(Mandatory = $false)]
        [int]$NumPoints = 100,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Right", "Left", "Both")]
        [string]$Tail = "Right",

        [Parameter(Mandatory = $false)]
        [double]$TailFraction = 0.1
    )

    # Générer les données du QQ-plot
    $qqPlotData = Get-QQPlotData -Data $Data -Distribution $Distribution -Parameters $Parameters -NumPoints $NumPoints -Tail $Tail

    # Analyser les extrémités du QQ-plot
    $tailAnalysis = Get-QQPlotTailAnalysis -QQPlotData $qqPlotData -TailFraction $TailFraction -Tail $Tail

    # Calculer la courbure du QQ-plot
    $curvatureAnalysis = Get-QQPlotCurvature -QQPlotData $qqPlotData -Tail $Tail

    # Combiner les résultats
    $isHeavyTailed = $tailAnalysis.IsHeavyTailed -or $curvatureAnalysis.IsHeavyTailed
    $interpretation = ""

    if ($tailAnalysis.IsHeavyTailed -and $curvatureAnalysis.IsHeavyTailed) {
        $interpretation = "La distribution a une queue lourde selon l'analyse de la pente et de la courbure du QQ-plot. "
        $interpretation += $tailAnalysis.Interpretation
    } elseif ($tailAnalysis.IsHeavyTailed) {
        $interpretation = "La distribution a une queue lourde selon l'analyse de la pente du QQ-plot. "
        $interpretation += $tailAnalysis.Interpretation
    } elseif ($curvatureAnalysis.IsHeavyTailed) {
        $interpretation = "La distribution a une queue lourde selon l'analyse de la courbure du QQ-plot. "
        $interpretation += $curvatureAnalysis.Interpretation
    } else {
        $interpretation = "La distribution n'a pas de queue lourde selon l'analyse du QQ-plot. "
        $interpretation += $tailAnalysis.Interpretation
    }

    # Retourner les résultats
    return [PSCustomObject]@{
        IsHeavyTailed  = $isHeavyTailed
        TailIndex      = $tailAnalysis.TailIndex
        Slope          = $tailAnalysis.Slope
        Curvature      = $curvatureAnalysis.Curvature
        Distribution   = $Distribution
        Parameters     = $qqPlotData.Parameters
        Tail           = $Tail
        Interpretation = $interpretation
    }
}

# Exporter les fonctions si le script est importé comme un module
if ($MyInvocation.Line -match "Import-Module") {
    Export-ModuleMember -Function Get-HillTailIndex, Get-NormalQuantile, Get-HillTailIndexPlot, Test-HeavyTail, Test-KolmogorovSmirnov, Test-HeavyTailComprehensive, Get-TheoreticalQuantiles, Get-EmpiricalQuantiles, Get-QQPlotData, Get-LinearRegression, Get-QQPlotTailAnalysis, Get-QQPlotCurvature, Test-QQPlotHeavyTail
}
