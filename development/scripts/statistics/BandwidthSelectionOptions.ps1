<#
.SYNOPSIS
    Crée un objet d'options pour la sélection automatique de la largeur de bande dans l'estimation de densité par noyau (KDE).

.DESCRIPTION
    Cette fonction crée un objet d'options pour la sélection automatique de la largeur de bande dans l'estimation de densité par noyau (KDE).
    Cet objet contient des options pour configurer les méthodes à considérer, les critères de sélection, les paramètres spécifiques à chaque méthode,
    les options de détection automatique des caractéristiques des données et les options de performance.

.PARAMETER Methods
    Les méthodes à considérer pour la sélection automatique (par défaut toutes les méthodes disponibles).
    - "Silverman": Règle de Silverman
    - "Scott": Méthode de Scott
    - "LeaveOneOut": Validation croisée par leave-one-out
    - "KFold": Validation croisée par k-fold
    - "Optimized": Optimisation par validation croisée

.PARAMETER AccuracyWeight
    Le poids accordé à la précision de l'estimation (par défaut 1).
    Valeur entre 0 et 3, où 0 signifie ignorer ce critère et 3 signifie lui accorder une importance maximale.

.PARAMETER SpeedWeight
    Le poids accordé à la vitesse d'exécution (par défaut 1).
    Valeur entre 0 et 3, où 0 signifie ignorer ce critère et 3 signifie lui accorder une importance maximale.

.PARAMETER RobustnessWeight
    Le poids accordé à la robustesse face aux valeurs aberrantes (par défaut 1).
    Valeur entre 0 et 3, où 0 signifie ignorer ce critère et 3 signifie lui accorder une importance maximale.

.PARAMETER AdaptabilityWeight
    Le poids accordé à l'adaptabilité à différents types de distributions (par défaut 1).
    Valeur entre 0 et 3, où 0 signifie ignorer ce critère et 3 signifie lui accorder une importance maximale.

.PARAMETER AutoDetect
    Indique si la fonction doit détecter automatiquement les caractéristiques des données (par défaut $true).
    Si $false, la fonction utilisera uniquement le système de scoring pour sélectionner la méthode optimale.

.PARAMETER KFoldCount
    Le nombre de plis (folds) à utiliser pour la validation croisée par k-fold (par défaut 5).

.PARAMETER MaxIterations
    Le nombre maximal d'itérations pour les méthodes d'optimisation (par défaut 20).

.PARAMETER Tolerance
    La tolérance pour la convergence des méthodes d'optimisation (par défaut 0.1).

.PARAMETER TimeoutSeconds
    Le délai maximal en secondes pour l'exécution de chaque méthode (par défaut 30).
    Si une méthode dépasse ce délai, elle sera ignorée.

.PARAMETER BandwidthRange
    La plage de largeurs de bande à considérer pour les méthodes de validation croisée (par défaut $null).
    Si $null, la plage sera déterminée automatiquement en fonction des données.
    Format: @(min, max, step) ou @(min, max) pour utiliser 10 pas.

.PARAMETER PreferSimpleMethods
    Indique si les méthodes simples (Silverman, Scott) doivent être privilégiées pour les petits ensembles de données (par défaut $true).

.PARAMETER SmallDatasetThreshold
    Le seuil en dessous duquel un ensemble de données est considéré comme petit (par défaut 20).

.PARAMETER LargeDatasetThreshold
    Le seuil au-dessus duquel un ensemble de données est considéré comme grand (par défaut 1000).

.PARAMETER CacheResults
    Indique si les résultats intermédiaires doivent être mis en cache pour accélérer les calculs ultérieurs (par défaut $false).

.EXAMPLE
    $options = Get-BandwidthSelectionOptions -Methods @("Silverman", "Scott") -SpeedWeight 3 -AccuracyWeight 1
    $kde = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -BandwidthSelectionOptions $options
    Effectue une estimation de densité par noyau en utilisant la sélection automatique de la largeur de bande,
    en considérant uniquement les méthodes de Silverman et de Scott, et en privilégiant la vitesse d'exécution.

.EXAMPLE
    $options = Get-BandwidthSelectionOptions -AutoDetect $false -KFoldCount 10 -MaxIterations 50
    $kde = Get-KernelDensityEstimation -Data $data -BandwidthMethod "Auto" -BandwidthSelectionOptions $options
    Effectue une estimation de densité par noyau en utilisant la sélection automatique de la largeur de bande,
    sans détection automatique des caractéristiques des données, avec 10 plis pour la validation croisée
    et un maximum de 50 itérations pour les méthodes d'optimisation.

.OUTPUTS
    PSCustomObject
#>
function Get-BandwidthSelectionOptions {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized")]
        [string[]]$Methods = @("Silverman", "Scott", "LeaveOneOut", "KFold", "Optimized"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 3)]
        [double]$AccuracyWeight = 1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 3)]
        [double]$SpeedWeight = 1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 3)]
        [double]$RobustnessWeight = 1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 3)]
        [double]$AdaptabilityWeight = 1,

        [Parameter(Mandatory = $false)]
        [bool]$AutoDetect = $true,

        [Parameter(Mandatory = $false)]
        [ValidateRange(2, 20)]
        [int]$KFoldCount = 5,

        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 100)]
        [int]$MaxIterations = 20,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.001, 1.0)]
        [double]$Tolerance = 0.1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 30,

        [Parameter(Mandatory = $false)]
        [double[]]$BandwidthRange = $null,

        [Parameter(Mandatory = $false)]
        [bool]$PreferSimpleMethods = $true,

        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 100)]
        [int]$SmallDatasetThreshold = 20,

        [Parameter(Mandatory = $false)]
        [ValidateRange(100, 10000)]
        [int]$LargeDatasetThreshold = 1000,

        [Parameter(Mandatory = $false)]
        [bool]$CacheResults = $false
    )

    # Créer l'objet d'options
    $options = [PSCustomObject]@{
        Methods                = $Methods
        Weights               = @{
            Accuracy     = $AccuracyWeight
            Speed        = $SpeedWeight
            Robustness   = $RobustnessWeight
            Adaptability = $AdaptabilityWeight
        }
        AutoDetect            = $AutoDetect
        KFoldCount            = $KFoldCount
        MaxIterations         = $MaxIterations
        Tolerance             = $Tolerance
        TimeoutSeconds        = $TimeoutSeconds
        BandwidthRange        = $BandwidthRange
        PreferSimpleMethods   = $PreferSimpleMethods
        SmallDatasetThreshold = $SmallDatasetThreshold
        LargeDatasetThreshold = $LargeDatasetThreshold
        CacheResults          = $CacheResults
    }

    # Ajouter des propriétés calculées
    $options | Add-Member -MemberType NoteProperty -Name "ObjectiveProfile" -Value $(
        if ($AccuracyWeight -gt [Math]::Max($SpeedWeight, [Math]::Max($RobustnessWeight, $AdaptabilityWeight))) {
            "Accuracy"
        }
        elseif ($SpeedWeight -gt [Math]::Max($AccuracyWeight, [Math]::Max($RobustnessWeight, $AdaptabilityWeight))) {
            "Speed"
        }
        elseif ($RobustnessWeight -gt [Math]::Max($AccuracyWeight, [Math]::Max($SpeedWeight, $AdaptabilityWeight))) {
            "Robustness"
        }
        elseif ($AdaptabilityWeight -gt [Math]::Max($AccuracyWeight, [Math]::Max($SpeedWeight, $RobustnessWeight))) {
            "Adaptability"
        }
        else {
            "Balanced"
        }
    )

    # Ajouter une méthode pour obtenir les méthodes filtrées en fonction de la taille des données
    $options | Add-Member -MemberType ScriptMethod -Name "GetFilteredMethods" -Value {
        param (
            [int]$DataCount,
            [string]$Complexity = "Medium"
        )

        $filteredMethods = @()

        # Pour les petits ensembles de données
        if ($DataCount -lt $this.SmallDatasetThreshold) {
            if ($this.PreferSimpleMethods) {
                # Privilégier les méthodes simples pour les petits ensembles de données
                if ($this.Methods -contains "Silverman") {
                    $filteredMethods += "Silverman"
                }
                if ($this.Methods -contains "Scott") {
                    $filteredMethods += "Scott"
                }
                
                # Si l'objectif est la vitesse, ne considérer que Silverman et Scott
                if ($this.ObjectiveProfile -eq "Speed" -and $filteredMethods.Count -gt 0) {
                    return $filteredMethods
                }
            }
        }
        
        # Pour les ensembles de données de taille moyenne
        if ($DataCount -ge $this.SmallDatasetThreshold -and $DataCount -lt $this.LargeDatasetThreshold) {
            if ($this.Methods -contains "LeaveOneOut") {
                $filteredMethods += "LeaveOneOut"
            }
            if ($this.Methods -contains "KFold") {
                $filteredMethods += "KFold"
            }
            
            # Ajouter Silverman et Scott si disponibles
            if ($this.Methods -contains "Silverman") {
                $filteredMethods += "Silverman"
            }
            if ($this.Methods -contains "Scott") {
                $filteredMethods += "Scott"
            }
        }
        
        # Pour les grands ensembles de données
        if ($DataCount -ge $this.LargeDatasetThreshold) {
            if ($this.Methods -contains "KFold") {
                $filteredMethods += "KFold"
            }
            if ($this.Methods -contains "Silverman") {
                $filteredMethods += "Silverman"
            }
            if ($this.Methods -contains "Scott") {
                $filteredMethods += "Scott"
            }
            
            # Éviter LeaveOneOut pour les grands ensembles de données (trop lent)
            # Éviter Optimized pour les grands ensembles de données sauf si la complexité est élevée
            if ($Complexity -eq "High" -and $this.Methods -contains "Optimized") {
                $filteredMethods += "Optimized"
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
