<#
.SYNOPSIS
    Crée un objet d'options avancées pour la sélection de la largeur de bande.

.DESCRIPTION
    Cette fonction crée un objet d'options avancées pour la sélection de la largeur de bande
    dans l'estimation de densité par noyau (KDE). Ces options permettent de personnaliser
    le comportement de la fonction Get-OptimalBandwidthMethod.

.PARAMETER OptimizationStrategy
    La stratégie d'optimisation à utiliser pour la sélection de la largeur de bande.
    - "Standard": Stratégie standard (équilibre entre précision et performance)
    - "Precision": Privilégie la précision des résultats
    - "Performance": Privilégie la performance (vitesse d'exécution)
    - "Robustness": Privilégie la robustesse face aux valeurs aberrantes
    - "Adaptability": Privilégie l'adaptabilité à différents types de distributions

.PARAMETER CrossValidationFolds
    Le nombre de plis (folds) à utiliser pour la validation croisée par k-fold.
    Applicable uniquement pour les méthodes "KFold" et "Optimized".

.PARAMETER MaxIterations
    Le nombre maximum d'itérations pour les méthodes d'optimisation.
    Applicable uniquement pour les méthodes "LeaveOneOut", "KFold" et "Optimized".

.PARAMETER Tolerance
    La tolérance pour la convergence des méthodes d'optimisation.
    Applicable uniquement pour les méthodes "LeaveOneOut", "KFold" et "Optimized".

.PARAMETER BandwidthRange
    La plage de largeurs de bande à explorer pour les méthodes d'optimisation.
    Format: @(min, max, step)
    Si non spécifiée, elle sera calculée automatiquement.

.PARAMETER OutlierHandling
    La méthode de gestion des valeurs aberrantes.
    - "None": Aucun traitement spécial pour les valeurs aberrantes
    - "Trim": Supprime les valeurs aberrantes avant le calcul
    - "Winsorize": Remplace les valeurs aberrantes par les valeurs aux percentiles spécifiés
    - "Robust": Utilise des méthodes robustes pour réduire l'influence des valeurs aberrantes

.PARAMETER OutlierThreshold
    Le seuil pour la détection des valeurs aberrantes (en multiples de l'IQR).
    Applicable uniquement si OutlierHandling n'est pas "None".

.PARAMETER SamplingStrategy
    La stratégie d'échantillonnage à utiliser pour les grands ensembles de données.
    - "None": Aucun échantillonnage
    - "Random": Échantillonnage aléatoire
    - "Stratified": Échantillonnage stratifié
    - "Adaptive": Échantillonnage adaptatif (préserve les caractéristiques importantes)

.PARAMETER MaxSampleSize
    La taille maximale de l'échantillon si SamplingStrategy n'est pas "None".

.PARAMETER ParallelProcessing
    Indique si le traitement parallèle doit être utilisé pour accélérer les calculs.

.PARAMETER MaxParallelJobs
    Le nombre maximum de jobs parallèles si ParallelProcessing est $true.

.PARAMETER CacheResults
    Indique si les résultats doivent être mis en cache pour une réutilisation ultérieure.

.PARAMETER CacheMaxSize
    La taille maximale du cache (nombre d'entrées) si CacheResults est $true.

.PARAMETER CacheExpirationMinutes
    Le délai d'expiration des entrées du cache en minutes si CacheResults est $true.

.PARAMETER PreferredMethods
    Les méthodes à privilégier pour la sélection de la largeur de bande.
    Si non spécifiées, toutes les méthodes disponibles seront considérées.

.PARAMETER ExcludedMethods
    Les méthodes à exclure de la sélection de la largeur de bande.

.PARAMETER CustomWeights
    Les poids personnalisés à utiliser pour le scoring des méthodes.
    Format: @{Accuracy = 1; Speed = 1; Robustness = 1; Adaptability = 1}
    Si non spécifiés, les poids seront déterminés en fonction de OptimizationStrategy.

.PARAMETER VerboseOutput
    Indique si des informations détaillées doivent être affichées pendant le calcul.

.PARAMETER DiagnosticMode
    Indique si le mode diagnostic doit être activé (collecte d'informations supplémentaires).

.PARAMETER DiagnosticOutputPath
    Le chemin où enregistrer les informations de diagnostic si DiagnosticMode est $true.

.EXAMPLE
    $options = Get-BandwidthSelectionAdvancedOptions -OptimizationStrategy "Precision" -CrossValidationFolds 10 -MaxIterations 50
    Get-OptimalBandwidthMethod -Data $data -AdvancedOptions $options
    Sélectionne automatiquement la méthode de sélection de largeur de bande optimale pour les données fournies,
    en utilisant une stratégie d'optimisation privilégiant la précision, 10 plis pour la validation croisée
    et 50 itérations maximum pour les méthodes d'optimisation.

.EXAMPLE
    $options = Get-BandwidthSelectionAdvancedOptions -SamplingStrategy "Adaptive" -MaxSampleSize 1000 -ParallelProcessing $true
    Get-OptimalBandwidthMethod -Data $data -AdvancedOptions $options
    Sélectionne automatiquement la méthode de sélection de largeur de bande optimale pour les données fournies,
    en utilisant un échantillonnage adaptatif avec une taille maximale de 1000 points et le traitement parallèle.

.OUTPUTS
    PSCustomObject
#>
function Get-BandwidthSelectionAdvancedOptions {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Standard", "Precision", "Performance", "Robustness", "Adaptability")]
        [string]$OptimizationStrategy = "Standard",

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 20)]
        [int]$CrossValidationFolds = 5,

        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 100)]
        [int]$MaxIterations = 20,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.001, 0.5)]
        [double]$Tolerance = 0.01,

        [Parameter(Mandatory = $false)]
        [double[]]$BandwidthRange = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Trim", "Winsorize", "Robust")]
        [string]$OutlierHandling = "None",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [double]$OutlierThreshold = 1.5,

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Random", "Stratified", "Adaptive")]
        [string]$SamplingStrategy = "None",

        [Parameter(Mandatory = $false)]
        [ValidateRange(100, 10000)]
        [int]$MaxSampleSize = 1000,

        [Parameter(Mandatory = $false)]
        [bool]$ParallelProcessing = $false,

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 16)]
        [int]$MaxParallelJobs = 4,

        [Parameter(Mandatory = $false)]
        [bool]$CacheResults = $false,

        [Parameter(Mandatory = $false)]
        [ValidateRange(10, 1000)]
        [int]$CacheMaxSize = 100,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1440)]
        [int]$CacheExpirationMinutes = 60,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized")]
        [string[]]$PreferredMethods = @(),

        [Parameter(Mandatory = $false)]
        [ValidateSet("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized")]
        [string[]]$ExcludedMethods = @(),

        [Parameter(Mandatory = $false)]
        [hashtable]$CustomWeights = $null,

        [Parameter(Mandatory = $false)]
        [bool]$VerboseOutput = $false,

        [Parameter(Mandatory = $false)]
        [bool]$DiagnosticMode = $false,

        [Parameter(Mandatory = $false)]
        [string]$DiagnosticOutputPath = ""
    )

    # Déterminer les poids en fonction de la stratégie d'optimisation
    $weights = @{}
    switch ($OptimizationStrategy) {
        "Precision" {
            $weights = @{
                Accuracy     = 3
                Speed        = 1
                Robustness   = 1
                Adaptability = 1
            }
        }
        "Performance" {
            $weights = @{
                Accuracy     = 1
                Speed        = 3
                Robustness   = 1
                Adaptability = 1
            }
        }
        "Robustness" {
            $weights = @{
                Accuracy     = 1
                Speed        = 1
                Robustness   = 3
                Adaptability = 1
            }
        }
        "Adaptability" {
            $weights = @{
                Accuracy     = 1
                Speed        = 1
                Robustness   = 1
                Adaptability = 3
            }
        }
        default {
            $weights = @{
                Accuracy     = 1
                Speed        = 1
                Robustness   = 1
                Adaptability = 1
            }
        }
    }

    # Utiliser les poids personnalisés s'ils sont spécifiés
    if ($null -ne $CustomWeights) {
        $weights = $CustomWeights
    }

    # Déterminer les méthodes à utiliser
    $methods = @("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized")
    
    # Filtrer les méthodes exclues
    if ($ExcludedMethods.Count -gt 0) {
        $methods = $methods | Where-Object { $_ -notin $ExcludedMethods }
    }
    
    # Utiliser uniquement les méthodes préférées si spécifiées
    if ($PreferredMethods.Count -gt 0) {
        $methods = $PreferredMethods | Where-Object { $_ -in $methods }
    }

    # Créer l'objet d'options
    $options = [PSCustomObject]@{
        OptimizationStrategy   = $OptimizationStrategy
        CrossValidationFolds   = $CrossValidationFolds
        MaxIterations          = $MaxIterations
        Tolerance              = $Tolerance
        BandwidthRange         = $BandwidthRange
        OutlierHandling        = $OutlierHandling
        OutlierThreshold       = $OutlierThreshold
        SamplingStrategy       = $SamplingStrategy
        MaxSampleSize          = $MaxSampleSize
        ParallelProcessing     = $ParallelProcessing
        MaxParallelJobs        = $MaxParallelJobs
        CacheResults           = $CacheResults
        CacheMaxSize           = $CacheMaxSize
        CacheExpirationMinutes = $CacheExpirationMinutes
        Methods                = $methods
        Weights                = $weights
        VerboseOutput          = $VerboseOutput
        DiagnosticMode         = $DiagnosticMode
        DiagnosticOutputPath   = $DiagnosticOutputPath
        AutoDetect             = $true
    }

    # Ajouter des méthodes à l'objet d'options
    $options | Add-Member -MemberType ScriptMethod -Name "GetFilteredMethods" -Value {
        param (
            [int]$DataCount,
            [string]$Complexity = "Medium"
        )

        $filteredMethods = @()

        # Pour les données simples (normales, sans valeurs aberrantes), privilégier Silverman et Scott
        if ($Complexity -eq "Low") {
            if ($this.Methods -contains "Silverman") {
                $filteredMethods += "Silverman"
            }
            if ($this.Methods -contains "Scott") {
                $filteredMethods += "Scott"
            }

            # Si l'objectif est la performance, ne considérer que Silverman et Scott
            if ($this.OptimizationStrategy -eq "Performance") {
                return $filteredMethods.Count -gt 0 ? $filteredMethods : @("Silverman")
            }
        }
        # Pour les données moyennement complexes, privilégier la validation croisée
        elseif ($Complexity -eq "Medium") {
            if ($DataCount -lt 100) {
                if ($this.Methods -contains "LeaveOneOut") {
                    $filteredMethods += "LeaveOneOut"
                }
            } else {
                if ($this.Methods -contains "KFold") {
                    $filteredMethods += "KFold"
                }
            }

            # Ajouter Silverman et Scott si disponibles
            if ($this.Methods -contains "Silverman") {
                $filteredMethods += "Silverman"
            }
            if ($this.Methods -contains "Scott") {
                $filteredMethods += "Scott"
            }
        }
        # Pour les données complexes, privilégier l'optimisation par validation croisée
        else {
            if ($this.Methods -contains "Optimized") {
                $filteredMethods += "Optimized"
            }
            if ($this.Methods -contains "KFold") {
                $filteredMethods += "KFold"
            }
            if ($this.Methods -contains "LeaveOneOut") {
                $filteredMethods += "LeaveOneOut"
            }
        }

        # Si aucune méthode n'a été filtrée, utiliser toutes les méthodes disponibles
        if ($filteredMethods.Count -eq 0) {
            $filteredMethods = $this.Methods
        }

        return $filteredMethods
    }

    return $options
}
