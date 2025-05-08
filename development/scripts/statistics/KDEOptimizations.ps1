<#
.SYNOPSIS
    Fournit des fonctions d'optimisation pour l'estimation de densité par noyau.

.DESCRIPTION
    Ce module fournit des fonctions d'optimisation pour l'estimation de densité par noyau,
    notamment des optimisations mathématiques comme la transformée de Fourier rapide (FFT)
    et le binning pour accélérer les calculs.

.NOTES
    Certaines fonctions nécessitent des bibliothèques externes comme MathNet.Numerics.
#>

<#
.SYNOPSIS
    Effectue l'estimation de densité par noyau en utilisant le binning pour accélérer les calculs.

.DESCRIPTION
    Cette fonction effectue l'estimation de densité par noyau en utilisant le binning pour accélérer les calculs.
    Au lieu de calculer la contribution de chaque point de données à chaque point d'évaluation,
    les données sont d'abord regroupées en bins, puis la densité est calculée à partir des bins.

.PARAMETER Data
    Les données d'entrée pour l'estimation de densité.

.PARAMETER EvaluationPoints
    Les points où la densité sera évaluée.

.PARAMETER Bandwidth
    La largeur de bande à utiliser pour l'estimation de densité.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").

.PARAMETER BinCount
    Le nombre de bins à utiliser pour le binning (par défaut 100).

.EXAMPLE
    $data = 1..1000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $evalPoints = 0..100
    $bandwidth = 5
    $densities = Get-BinnedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth -BinCount 200

.OUTPUTS
    System.Double[]
#>
function Get-BinnedKDE {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $true)]
        [double[]]$EvaluationPoints,

        [Parameter(Mandatory = $true)]
        [double]$Bandwidth,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Uniform", "Triangular", "Biweight", "Triweight", "Cosine")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [int]$BinCount = 100
    )

    # Calculer les limites des données
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    
    # Ajouter une marge pour éviter les effets de bord
    $range = $max - $min
    $min = $min - 0.1 * $range
    $max = $max + 0.1 * $range
    
    # Créer les bins
    $binWidth = ($max - $min) / $BinCount
    $bins = New-Object 'double[]' $BinCount
    
    # Compter les points dans chaque bin
    foreach ($point in $Data) {
        $binIndex = [Math]::Floor(($point - $min) / $binWidth)
        
        # S'assurer que l'index est dans les limites
        if ($binIndex -lt 0) {
            $binIndex = 0
        }
        elseif ($binIndex -ge $BinCount) {
            $binIndex = $BinCount - 1
        }
        
        $bins[$binIndex] += 1
    }
    
    # Normaliser les bins
    $bins = $bins | ForEach-Object { $_ / ($Data.Count * $binWidth) }
    
    # Définir la fonction de noyau
    $kernelFunction = switch ($KernelType) {
        "Gaussian" {
            # Noyau gaussien: (1/sqrt(2π)) * exp(-0.5 * x^2)
            [scriptblock]{ param($x) (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x) }
        }
        "Epanechnikov" {
            # Noyau d'Epanechnikov: 0.75 * (1 - x^2) pour |x| <= 1, 0 sinon
            [scriptblock]{ param($x) if ([Math]::Abs($x) -le 1) { 0.75 * (1 - $x * $x) } else { 0 } }
        }
        "Uniform" {
            # Noyau uniforme: 0.5 pour |x| <= 1, 0 sinon
            [scriptblock]{ param($x) if ([Math]::Abs($x) -le 1) { 0.5 } else { 0 } }
        }
        "Triangular" {
            # Noyau triangulaire: (1 - |x|) pour |x| <= 1, 0 sinon
            [scriptblock]{ param($x) if ([Math]::Abs($x) -le 1) { 1 - [Math]::Abs($x) } else { 0 } }
        }
        default {
            # Par défaut, utiliser le noyau gaussien
            [scriptblock]{ param($x) (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x) }
        }
    }
    
    # Calculer les centres des bins
    $binCenters = 0..($BinCount - 1) | ForEach-Object { $min + ($_ + 0.5) * $binWidth }
    
    # Calculer la densité pour chaque point d'évaluation
    $densityEstimates = @()
    foreach ($point in $EvaluationPoints) {
        $density = 0
        
        foreach ($i in 0..($BinCount - 1)) {
            $binCenter = $binCenters[$i]
            $binCount = $bins[$i]
            
            $x = ($point - $binCenter) / $Bandwidth
            $kernelValue = & $kernelFunction $x
            
            $density += $binCount * $kernelValue
        }
        
        $density /= $Bandwidth
        $densityEstimates += $density
    }
    
    return $densityEstimates
}

<#
.SYNOPSIS
    Effectue l'estimation de densité par noyau en utilisant la transformée de Fourier rapide (FFT).

.DESCRIPTION
    Cette fonction effectue l'estimation de densité par noyau en utilisant la transformée de Fourier rapide (FFT)
    pour accélérer les calculs. Cette méthode est particulièrement efficace pour les grands ensembles de données
    et les grilles d'évaluation régulières.

.PARAMETER Data
    Les données d'entrée pour l'estimation de densité.

.PARAMETER Bandwidth
    La largeur de bande à utiliser pour l'estimation de densité.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").

.PARAMETER GridSize
    La taille de la grille pour l'estimation de densité (par défaut 512).
    Doit être une puissance de 2 pour une efficacité optimale.

.PARAMETER Range
    La plage de valeurs à couvrir. Si non spécifiée, elle sera déterminée automatiquement
    à partir des données.

.EXAMPLE
    $data = 1..1000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $bandwidth = 5
    $result = Get-FFTKDE -Data $data -Bandwidth $bandwidth -GridSize 1024
    $evalPoints = $result.EvaluationPoints
    $densities = $result.DensityEstimates

.OUTPUTS
    System.Management.Automation.PSObject
#>
function Get-FFTKDE {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $true)]
        [double]$Bandwidth,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Uniform", "Triangular", "Biweight", "Triweight", "Cosine")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [ValidateScript({ $_ -band ($_ - 1) -eq 0 })]  # Vérifier que c'est une puissance de 2
        [int]$GridSize = 512,

        [Parameter(Mandatory = $false)]
        [double[]]$Range = $null
    )

    # Vérifier si MathNet.Numerics est disponible
    $mathNetAvailable = $false
    try {
        Add-Type -Path "MathNet.Numerics.dll"
        $mathNetAvailable = $true
    }
    catch {
        Write-Warning "La bibliothèque MathNet.Numerics n'est pas disponible. Utilisation d'une implémentation alternative."
    }

    # Si MathNet.Numerics n'est pas disponible, utiliser une méthode alternative
    if (-not $mathNetAvailable) {
        return Get-BinnedKDE -Data $Data -EvaluationPoints (0..100) -Bandwidth $Bandwidth -KernelType $KernelType -BinCount $GridSize
    }

    # Calculer les limites des données si non spécifiées
    if ($null -eq $Range) {
        $min = ($Data | Measure-Object -Minimum).Minimum
        $max = ($Data | Measure-Object -Maximum).Maximum
        
        # Ajouter une marge pour éviter les effets de bord
        $dataRange = $max - $min
        $min = $min - 0.1 * $dataRange
        $max = $max + 0.1 * $dataRange
        
        $Range = @($min, $max)
    }
    
    # Créer la grille d'évaluation
    $gridStep = ($Range[1] - $Range[0]) / $GridSize
    $evaluationPoints = 0..($GridSize - 1) | ForEach-Object { $Range[0] + $_ * $gridStep }
    
    # Créer les bins
    $bins = New-Object 'double[]' $GridSize
    
    # Compter les points dans chaque bin
    foreach ($point in $Data) {
        $binIndex = [Math]::Floor(($point - $Range[0]) / $gridStep)
        
        # S'assurer que l'index est dans les limites
        if ($binIndex -ge 0 -and $binIndex -lt $GridSize) {
            $bins[$binIndex] += 1
        }
    }
    
    # Appliquer la FFT
    $fftResult = [MathNet.Numerics.IntegralTransforms.Fourier]::Forward($bins)
    
    # Créer le noyau dans le domaine fréquentiel
    $kernel = New-Object 'System.Numerics.Complex[]' $GridSize
    
    switch ($KernelType) {
        "Gaussian" {
            # Noyau gaussien dans le domaine fréquentiel
            for ($i = 0; $i -lt $GridSize; $i++) {
                $freq = $i / $GridSize
                if ($i -gt $GridSize / 2) {
                    $freq = ($GridSize - $i) / $GridSize
                }
                $kernel[$i] = [System.Numerics.Complex]::Exp(-2 * [Math]::PI * [Math]::PI * $freq * $freq * $Bandwidth * $Bandwidth)
            }
        }
        default {
            # Par défaut, utiliser le noyau gaussien
            for ($i = 0; $i -lt $GridSize; $i++) {
                $freq = $i / $GridSize
                if ($i -gt $GridSize / 2) {
                    $freq = ($GridSize - $i) / $GridSize
                }
                $kernel[$i] = [System.Numerics.Complex]::Exp(-2 * [Math]::PI * [Math]::PI * $freq * $freq * $Bandwidth * $Bandwidth)
            }
        }
    }
    
    # Multiplier les transformées
    for ($i = 0; $i -lt $GridSize; $i++) {
        $fftResult[$i] *= $kernel[$i]
    }
    
    # Appliquer la FFT inverse
    [MathNet.Numerics.IntegralTransforms.Fourier]::Inverse($fftResult)
    
    # Extraire les parties réelles et normaliser
    $densityEstimates = $fftResult | ForEach-Object { $_.Real / ($Data.Count * $gridStep) }
    
    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        EvaluationPoints = $evaluationPoints
        DensityEstimates = $densityEstimates
        Bandwidth = $Bandwidth
        KernelType = $KernelType
        GridSize = $GridSize
        Range = $Range
    }
    
    return $result
}

<#
.SYNOPSIS
    Effectue l'estimation de densité par noyau en utilisant une mise en cache des résultats intermédiaires.

.DESCRIPTION
    Cette fonction effectue l'estimation de densité par noyau en utilisant une mise en cache des résultats intermédiaires
    pour éviter de recalculer les mêmes valeurs plusieurs fois.

.PARAMETER Data
    Les données d'entrée pour l'estimation de densité.

.PARAMETER EvaluationPoints
    Les points où la densité sera évaluée.

.PARAMETER Bandwidth
    La largeur de bande à utiliser pour l'estimation de densité.

.PARAMETER KernelType
    Le type de noyau à utiliser (par défaut "Gaussian").

.PARAMETER CacheSize
    La taille maximale du cache (par défaut 1000).

.EXAMPLE
    $data = 1..1000 | ForEach-Object { Get-Random -Minimum 0 -Maximum 100 }
    $evalPoints = 0..100
    $bandwidth = 5
    $densities = Get-CachedKDE -Data $data -EvaluationPoints $evalPoints -Bandwidth $bandwidth

.OUTPUTS
    System.Double[]
#>
function Get-CachedKDE {
    [CmdletBinding()]
    [OutputType([double[]])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $true)]
        [double[]]$EvaluationPoints,

        [Parameter(Mandatory = $true)]
        [double]$Bandwidth,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Uniform", "Triangular", "Biweight", "Triweight", "Cosine")]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [int]$CacheSize = 1000
    )

    # Définir la fonction de noyau
    $kernelFunction = switch ($KernelType) {
        "Gaussian" {
            # Noyau gaussien: (1/sqrt(2π)) * exp(-0.5 * x^2)
            [scriptblock]{ param($x) (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x) }
        }
        default {
            # Par défaut, utiliser le noyau gaussien
            [scriptblock]{ param($x) (1 / [Math]::Sqrt(2 * [Math]::PI)) * [Math]::Exp(-0.5 * $x * $x) }
        }
    }
    
    # Créer le cache
    $cache = @{}
    
    # Calculer la densité pour chaque point d'évaluation
    $densityEstimates = @()
    foreach ($point in $EvaluationPoints) {
        $density = 0
        
        foreach ($dataPoint in $Data) {
            $x = ($point - $dataPoint) / $Bandwidth
            
            # Arrondir x pour le cache
            $xRounded = [Math]::Round($x, 4)
            
            # Vérifier si la valeur est dans le cache
            if ($cache.ContainsKey($xRounded)) {
                $kernelValue = $cache[$xRounded]
            }
            else {
                # Calculer la valeur et l'ajouter au cache
                $kernelValue = & $kernelFunction $x
                
                # Limiter la taille du cache
                if ($cache.Count -lt $CacheSize) {
                    $cache[$xRounded] = $kernelValue
                }
            }
            
            $density += $kernelValue
        }
        
        $density /= ($Bandwidth * $Data.Count)
        $densityEstimates += $density
    }
    
    return $densityEstimates
}
