<#
.SYNOPSIS
    Module pour la sélection du noyau optimal par validation croisée pour l'estimation de densité par noyau.

.DESCRIPTION
    Ce module implémente les fonctions nécessaires pour la sélection du noyau optimal par validation croisée
    pour l'estimation de densité par noyau. Il utilise les méthodes de validation croisée leave-one-out et k-fold
    pour évaluer les performances de différents noyaux sur les données.

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-17
#>

<#
.SYNOPSIS
    Calcule l'erreur de validation croisée leave-one-out pour un noyau donné.

.DESCRIPTION
    Cette fonction calcule l'erreur de validation croisée leave-one-out pour un noyau donné.
    Elle exclut chaque point des données à tour de rôle, calcule la densité en ce point en utilisant
    les données restantes, et calcule l'erreur quadratique moyenne.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelType
    Le type de noyau à utiliser.
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire
    - "Uniform": Noyau uniforme
    - "Biweight": Noyau biweight (quartic)
    - "Triweight": Noyau triweight (cubic)
    - "Cosine": Noyau cosinus

.PARAMETER Bandwidth
    La largeur de bande à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman.

.EXAMPLE
    Get-LeaveOneOutCVError -Data $data -KernelType "Gaussian"
    Calcule l'erreur de validation croisée leave-one-out pour le noyau gaussien.

.OUTPUTS
    System.Double
#>
function Get-LeaveOneOutCVError {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")]
        [string]$KernelType,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0
    )

    # Vérifier que les données contiennent au moins 3 points
    if ($Data.Count -lt 3) {
        throw "Les données doivent contenir au moins 3 points pour la validation croisée leave-one-out."
    }

    # Calculer la largeur de bande optimale si non spécifiée
    if ($Bandwidth -le 0) {
        # Calculer l'écart-type des données
        $mean = ($Data | Measure-Object -Average).Average
        $variance = ($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
        $sigma = [Math]::Sqrt($variance)

        # Nombre de points
        $n = $Data.Count

        # Règle de Silverman
        $Bandwidth = 1.06 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Calculer l'erreur de validation croisée leave-one-out
    $n = $Data.Count
    $cvError = 0

    for ($i = 0; $i -lt $n; $i++) {
        # Exclure le point i
        $trainingData = @()
        for ($j = 0; $j -lt $n; $j++) {
            if ($j -ne $i) {
                $trainingData += $Data[$j]
            }
        }

        # Calculer la densité au point i en utilisant les données d'entraînement
        $density = 0
        switch ($KernelType) {
            "Gaussian" {
                $density = Get-GaussianKernelDensity -X $Data[$i] -Data $trainingData -Bandwidth $Bandwidth
            }
            "Epanechnikov" {
                $density = Get-EpanechnikovKernelDensity -X $Data[$i] -Data $trainingData -Bandwidth $Bandwidth
            }
            "Triangular" {
                $density = Get-TriangularKernelDensity -X $Data[$i] -Data $trainingData -Bandwidth $Bandwidth
            }
            "Uniform" {
                $density = Get-UniformKernelDensity -X $Data[$i] -Data $trainingData -Bandwidth $Bandwidth
            }
            "Biweight" {
                $density = Get-BiweightKernelDensity -X $Data[$i] -Data $trainingData -Bandwidth $Bandwidth
            }
            "Triweight" {
                $density = Get-TriweightKernelDensity -X $Data[$i] -Data $trainingData -Bandwidth $Bandwidth
            }
            "Cosine" {
                $density = Get-CosineKernelDensity -X $Data[$i] -Data $trainingData -Bandwidth $Bandwidth
            }
        }

        # Calculer l'erreur quadratique
        $cvError += [Math]::Pow(1 - $density, 2)
    }

    # Calculer l'erreur quadratique moyenne
    $cvError = $cvError / $n

    return $cvError
}

<#
.SYNOPSIS
    Calcule l'erreur de validation croisée k-fold pour un noyau donné.

.DESCRIPTION
    Cette fonction calcule l'erreur de validation croisée k-fold pour un noyau donné.
    Elle divise les données en k plis, utilise k-1 plis comme données d'entraînement et le pli restant
    comme données de test, et calcule l'erreur quadratique moyenne.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelType
    Le type de noyau à utiliser.
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire
    - "Uniform": Noyau uniforme
    - "Biweight": Noyau biweight (quartic)
    - "Triweight": Noyau triweight (cubic)
    - "Cosine": Noyau cosinus

.PARAMETER Bandwidth
    La largeur de bande à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée en utilisant la règle de Silverman.

.PARAMETER K
    Le nombre de plis (folds) à utiliser pour la validation croisée (par défaut 5).

.EXAMPLE
    Get-KFoldCVError -Data $data -KernelType "Gaussian" -K 10
    Calcule l'erreur de validation croisée 10-fold pour le noyau gaussien.

.OUTPUTS
    System.Double
#>
function Get-KFoldCVError {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")]
        [string]$KernelType,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 100)]
        [int]$K = 5
    )

    # Vérifier que les données contiennent au moins K points
    if ($Data.Count -lt $K) {
        throw "Les données doivent contenir au moins $K points pour la validation croisée par $K-fold."
    }

    # Calculer la largeur de bande optimale si non spécifiée
    if ($Bandwidth -le 0) {
        # Calculer l'écart-type des données
        $mean = ($Data | Measure-Object -Average).Average
        $variance = ($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average
        $sigma = [Math]::Sqrt($variance)

        # Nombre de points
        $n = $Data.Count

        # Règle de Silverman
        $Bandwidth = 1.06 * $sigma * [Math]::Pow($n, -0.2)
    }

    # Diviser les données en K plis
    $folds = @()
    $n = $Data.Count
    $foldSize = [Math]::Floor($n / $K)
    $remainder = $n % $K

    # Mélanger les données
    $shuffledData = $Data | Get-Random -Count $n

    # Créer les plis
    $startIndex = 0
    for ($i = 0; $i -lt $K; $i++) {
        $currentFoldSize = $foldSize
        if ($i -lt $remainder) {
            $currentFoldSize++
        }

        $fold = @()
        for ($j = 0; $j -lt $currentFoldSize; $j++) {
            $fold += $shuffledData[$startIndex + $j]
        }

        $folds += , $fold
        $startIndex += $currentFoldSize
    }

    # Calculer l'erreur de validation croisée k-fold
    $cvError = 0

    for ($i = 0; $i -lt $K; $i++) {
        # Utiliser le pli i comme données de test
        $testData = $folds[$i]

        # Utiliser les autres plis comme données d'entraînement
        $trainingData = @()
        for ($j = 0; $j -lt $K; $j++) {
            if ($j -ne $i) {
                $trainingData += $folds[$j]
            }
        }

        # Calculer l'erreur pour chaque point de test
        foreach ($testPoint in $testData) {
            # Calculer la densité au point de test en utilisant les données d'entraînement
            $density = 0
            switch ($KernelType) {
                "Gaussian" {
                    $density = Get-GaussianKernelDensity -X $testPoint -Data $trainingData -Bandwidth $Bandwidth
                }
                "Epanechnikov" {
                    $density = Get-EpanechnikovKernelDensity -X $testPoint -Data $trainingData -Bandwidth $Bandwidth
                }
                "Triangular" {
                    $density = Get-TriangularKernelDensity -X $testPoint -Data $trainingData -Bandwidth $Bandwidth
                }
                "Uniform" {
                    $density = Get-UniformKernelDensity -X $testPoint -Data $trainingData -Bandwidth $Bandwidth
                }
                "Biweight" {
                    $density = Get-BiweightKernelDensity -X $testPoint -Data $trainingData -Bandwidth $Bandwidth
                }
                "Triweight" {
                    $density = Get-TriweightKernelDensity -X $testPoint -Data $trainingData -Bandwidth $Bandwidth
                }
                "Cosine" {
                    $density = Get-CosineKernelDensity -X $testPoint -Data $trainingData -Bandwidth $Bandwidth
                }
            }

            # Calculer l'erreur quadratique
            $cvError += [Math]::Pow(1 - $density, 2)
        }
    }

    # Calculer l'erreur quadratique moyenne
    $cvError = $cvError / $n

    return $cvError
}

<#
.SYNOPSIS
    Sélectionne le noyau optimal par validation croisée pour l'estimation de densité par noyau.

.DESCRIPTION
    Cette fonction sélectionne le noyau optimal par validation croisée pour l'estimation de densité par noyau.
    Elle évalue les performances de différents noyaux sur les données en utilisant la validation croisée
    leave-one-out ou k-fold, et sélectionne le noyau avec l'erreur la plus faible.

.PARAMETER Data
    Les données de la distribution.

.PARAMETER KernelTypes
    Les types de noyaux à évaluer (par défaut tous les noyaux disponibles).
    - "Gaussian": Noyau gaussien
    - "Epanechnikov": Noyau d'Epanechnikov
    - "Triangular": Noyau triangulaire
    - "Uniform": Noyau uniforme
    - "Biweight": Noyau biweight (quartic)
    - "Triweight": Noyau triweight (cubic)
    - "Cosine": Noyau cosinus

.PARAMETER ValidationMethod
    La méthode de validation croisée à utiliser (par défaut "KFold").
    - "LeaveOneOut": Validation croisée leave-one-out
    - "KFold": Validation croisée k-fold

.PARAMETER K
    Le nombre de plis (folds) à utiliser pour la validation croisée k-fold (par défaut 5).
    Ignoré si ValidationMethod est "LeaveOneOut".

.PARAMETER Bandwidth
    La largeur de bande à utiliser. Si non spécifiée, une largeur de bande optimale
    sera calculée pour chaque noyau en utilisant la règle de Silverman.

.EXAMPLE
    Get-CrossValidationOptimalKernel -Data $data
    Sélectionne le noyau optimal par validation croisée k-fold avec 5 plis.

.EXAMPLE
    Get-CrossValidationOptimalKernel -Data $data -ValidationMethod "LeaveOneOut"
    Sélectionne le noyau optimal par validation croisée leave-one-out.

.EXAMPLE
    Get-CrossValidationOptimalKernel -Data $data -KernelTypes @("Gaussian", "Epanechnikov", "Triangular")
    Sélectionne le noyau optimal parmi les noyaux gaussien, d'Epanechnikov et triangulaire.

.OUTPUTS
    System.String
#>
function Get-CrossValidationOptimalKernel {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")]
        [string[]]$KernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("LeaveOneOut", "KFold")]
        [string]$ValidationMethod = "KFold",

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 100)]
        [int]$K = 5,

        [Parameter(Mandatory = $false)]
        [double]$Bandwidth = 0
    )

    # Vérifier que les données contiennent au moins 3 points
    if ($Data.Count -lt 3) {
        throw "Les données doivent contenir au moins 3 points pour la validation croisée."
    }

    # Calculer l'erreur de validation croisée pour chaque noyau
    $kernelErrors = @{}

    foreach ($kernelType in $KernelTypes) {
        if ($ValidationMethod -eq "LeaveOneOut") {
            $kernelErrors[$kernelType] = Get-LeaveOneOutCVError -Data $Data -KernelType $kernelType -Bandwidth $Bandwidth
        } else {
            $kernelErrors[$kernelType] = Get-KFoldCVError -Data $Data -KernelType $kernelType -Bandwidth $Bandwidth -K $K
        }
    }

    # Sélectionner le noyau avec l'erreur la plus faible
    $optimalKernel = $kernelErrors.GetEnumerator() | Sort-Object -Property Value | Select-Object -First 1 -ExpandProperty Name

    return $optimalKernel
}
