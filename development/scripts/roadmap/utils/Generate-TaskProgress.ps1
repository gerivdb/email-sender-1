# Generate-TaskProgress.ps1
# Script pour générer des pourcentages d'avancement pour les tâches
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère des pourcentages d'avancement pour les tâches en fonction de leur structure hiérarchique.

.DESCRIPTION
    Ce script fournit des fonctions pour générer des pourcentages d'avancement pour les tâches,
    en tenant compte de leur structure hiérarchique et des règles de cohérence.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour générer un pourcentage d'avancement aléatoire
function Get-RandomProgress {
    <#
    .SYNOPSIS
        Génère un pourcentage d'avancement aléatoire pour une tâche.

    .DESCRIPTION
        Cette fonction génère un pourcentage d'avancement aléatoire pour une tâche, avec des pondérations
        personnalisables pour différentes plages de pourcentages.

    .PARAMETER Weights
        Les pondérations pour chaque plage de pourcentages. Plus la pondération est élevée, plus la plage
        a de chances d'être sélectionnée.
        Format: @{
            "0-25" = 40
            "26-50" = 30
            "51-75" = 20
            "76-99" = 10
        }

    .PARAMETER ExcludeRanges
        Les plages de pourcentages à exclure de la sélection aléatoire.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des pourcentages identiques à chaque exécution avec la même graine.

    .PARAMETER Status
        Le statut de la tâche, qui influence le pourcentage d'avancement généré.
        Valeurs possibles: "NotStarted", "InProgress", "Completed", "Blocked"

    .EXAMPLE
        Get-RandomProgress
        Génère un pourcentage d'avancement aléatoire avec les pondérations par défaut.

    .EXAMPLE
        Get-RandomProgress -Status "InProgress"
        Génère un pourcentage d'avancement aléatoire pour une tâche en cours.

    .EXAMPLE
        Get-RandomProgress -Weights @{ "0-25" = 20; "26-50" = 40; "51-75" = 30; "76-99" = 10 }
        Génère un pourcentage d'avancement aléatoire avec des pondérations personnalisées.

    .OUTPUTS
        System.Int32
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$Weights = @{
            "0-25"  = 40
            "26-50" = 30
            "51-75" = 20
            "76-99" = 10
        },

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeRanges = @(),

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$Status = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    } else {
        $random = New-Object System.Random
    }

    # Ajuster les pondérations en fonction du statut
    if ($Status) {
        switch ($Status) {
            "NotStarted" {
                $Weights = @{
                    "0-25"  = 90
                    "26-50" = 10
                    "51-75" = 0
                    "76-99" = 0
                }
            }
            "InProgress" {
                $Weights = @{
                    "0-25"  = 20
                    "26-50" = 40
                    "51-75" = 30
                    "76-99" = 10
                }
            }
            "Completed" {
                return 100
            }
            "Blocked" {
                $Weights = @{
                    "0-25"  = 50
                    "26-50" = 30
                    "51-75" = 15
                    "76-99" = 5
                }
            }
        }
    }

    # Filtrer les plages exclues
    $filteredWeights = @{}
    foreach ($range in $Weights.Keys) {
        if ($ExcludeRanges -notcontains $range) {
            $filteredWeights[$range] = $Weights[$range]
        }
    }

    # Si toutes les plages sont exclues, retourner 0
    if ($filteredWeights.Count -eq 0) {
        return 0
    }

    # Calculer le poids total
    $totalWeight = ($filteredWeights.Values | Measure-Object -Sum).Sum

    # Générer un nombre aléatoire entre 1 et le poids total
    $randomValue = $random.Next(1, $totalWeight + 1)

    # Sélectionner la plage en fonction du poids
    $cumulativeWeight = 0
    $selectedRange = $null
    foreach ($range in $filteredWeights.Keys) {
        $cumulativeWeight += $filteredWeights[$range]
        if ($randomValue -le $cumulativeWeight) {
            $selectedRange = $range
            break
        }
    }

    # Si aucune plage n'est sélectionnée, retourner 0
    if (-not $selectedRange) {
        return 0
    }

    # Extraire les limites de la plage
    $limits = $selectedRange -split '-'
    $min = [int]$limits[0]
    $max = [int]$limits[1]

    # Générer un pourcentage aléatoire dans la plage sélectionnée
    return $random.Next($min, $max + 1)
}

# Fonction pour générer des pourcentages d'avancement pour une hiérarchie de tâches
function New-TaskProgress {
    <#
    .SYNOPSIS
        Génère des pourcentages d'avancement pour une hiérarchie de tâches.

    .DESCRIPTION
        Cette fonction génère des pourcentages d'avancement pour une hiérarchie de tâches,
        en tenant compte des règles de cohérence hiérarchique.

    .PARAMETER Tasks
        Les tâches pour lesquelles générer des pourcentages d'avancement.

    .PARAMETER ProgressField
        Le nom du champ dans lequel stocker le pourcentage d'avancement dans les tâches.
        Par défaut: "Progress".

    .PARAMETER StatusField
        Le nom du champ contenant le statut dans les tâches.
        Par défaut: "Status".

    .PARAMETER ParentIdField
        Le nom du champ contenant l'ID du parent dans les tâches.
        Par défaut: "ParentId".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER ChildrenField
        Le nom du champ contenant les IDs des enfants dans les tâches.
        Par défaut: "Children".

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des pourcentages identiques à chaque exécution avec la même graine.

    .EXAMPLE
        New-TaskProgress -Tasks $tasks
        Génère des pourcentages d'avancement pour les tâches spécifiées.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$ProgressField = "Progress",

        [Parameter(Mandatory = $false)]
        [string]$StatusField = "Status",

        [Parameter(Mandatory = $false)]
        [string]$ParentIdField = "ParentId",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children",

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    } else {
        $random = New-Object System.Random
    }

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Fonction récursive pour générer des pourcentages d'avancement
    function Set-ProgressRecursively {
        param (
            [PSObject]$Task,
            [int]$ParentProgress = $null
        )

        # Si la tâche a déjà un pourcentage d'avancement, l'utiliser
        if ($Task.PSObject.Properties.Name.Contains($ProgressField) -and $null -ne $Task.$ProgressField) {
            $progress = $Task.$ProgressField
        } else {
            # Déterminer le statut de la tâche
            $status = if ($Task.PSObject.Properties.Name.Contains($StatusField) -and $Task.$StatusField) {
                $Task.$StatusField
            } else {
                "InProgress"
            }

            # Générer un pourcentage d'avancement en fonction du statut et du pourcentage du parent
            if ($status -eq "Completed") {
                $progress = 100
            } elseif ($status -eq "NotStarted") {
                $progress = 0
            } elseif ($null -ne $ParentProgress) {
                # Générer un pourcentage cohérent avec le parent
                if ($ParentProgress -eq 100) {
                    $progress = 100
                } elseif ($ParentProgress -eq 0) {
                    $progress = 0
                } else {
                    # Générer un pourcentage aléatoire autour du pourcentage du parent
                    $minProgress = [Math]::Max(0, $ParentProgress - 20)
                    $maxProgress = [Math]::Min(99, $ParentProgress + 20)
                    $progress = $random.Next($minProgress, $maxProgress + 1)
                }
            } else {
                # Générer un pourcentage aléatoire en fonction du statut
                $progress = Get-RandomProgress -Status $status -RandomSeed ($RandomSeed + $Task.$IdField.GetHashCode())
            }

            # Assigner le pourcentage d'avancement à la tâche
            if (-not $Task.PSObject.Properties.Name.Contains($ProgressField)) {
                Add-Member -InputObject $Task -MemberType NoteProperty -Name $ProgressField -Value $progress
            } else {
                $Task.$ProgressField = $progress
            }
        }

        # Traiter les enfants
        $childrenIds = @()
        if ($Task.PSObject.Properties.Name.Contains($ChildrenField) -and $Task.$ChildrenField) {
            $childrenIds = $Task.$ChildrenField
        }

        foreach ($childId in $childrenIds) {
            if ($tasksById.ContainsKey($childId)) {
                $child = $tasksById[$childId]
                Set-ProgressRecursively -Task $child -ParentProgress $progress
            }
        }
    }

    # Trouver les tâches racines (sans parent)
    $rootTasks = $Tasks | Where-Object { -not $_.$ParentIdField }

    # Générer les pourcentages d'avancement pour chaque arbre
    foreach ($rootTask in $rootTasks) {
        Set-ProgressRecursively -Task $rootTask
    }

    # Vérifier et ajuster la cohérence
    Update-TaskProgressHierarchy -Tasks $Tasks -ProgressField $ProgressField -ParentIdField $ParentIdField -IdField $IdField -ChildrenField $ChildrenField

    return $Tasks
}

# Fonction pour mettre à jour les pourcentages d'avancement pour maintenir la cohérence hiérarchique
function Update-TaskProgressHierarchy {
    <#
    .SYNOPSIS
        Met à jour les pourcentages d'avancement pour maintenir la cohérence hiérarchique.

    .DESCRIPTION
        Cette fonction met à jour les pourcentages d'avancement pour maintenir la cohérence hiérarchique,
        en appliquant les règles suivantes :
        - Si une tâche parent est complétée à 100%, toutes ses tâches enfants doivent être complétées à 100%
        - Si une tâche parent a un pourcentage d'avancement, celui-ci doit être cohérent avec l'avancement moyen de ses tâches enfants
        - Si toutes les tâches enfants sont complétées à 100%, la tâche parent doit être complétée à 100%

    .PARAMETER Tasks
        Les tâches à mettre à jour.

    .PARAMETER ProgressField
        Le nom du champ contenant le pourcentage d'avancement dans les tâches.
        Par défaut: "Progress".

    .PARAMETER ParentIdField
        Le nom du champ contenant l'ID du parent dans les tâches.
        Par défaut: "ParentId".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER ChildrenField
        Le nom du champ contenant les IDs des enfants dans les tâches.
        Par défaut: "Children".

    .EXAMPLE
        Update-TaskProgressHierarchy -Tasks $tasks
        Met à jour les pourcentages d'avancement des tâches pour maintenir la cohérence hiérarchique.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$ProgressField = "Progress",

        [Parameter(Mandatory = $false)]
        [string]$ParentIdField = "ParentId",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children"
    )

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Première passe : propager les pourcentages d'avancement des enfants vers les parents
    foreach ($task in $Tasks) {
        # Si la tâche a des enfants
        if ($task.PSObject.Properties.Name.Contains($ChildrenField) -and $task.$ChildrenField -and $task.$ChildrenField.Count -gt 0) {
            $childrenIds = $task.$ChildrenField
            $childrenProgress = @()

            # Collecter les pourcentages d'avancement des enfants
            foreach ($childId in $childrenIds) {
                if ($tasksById.ContainsKey($childId)) {
                    $child = $tasksById[$childId]
                    if ($child.PSObject.Properties.Name.Contains($ProgressField) -and $null -ne $child.$ProgressField) {
                        $childrenProgress += $child.$ProgressField
                    }
                }
            }

            # Calculer le pourcentage d'avancement moyen des enfants
            if ($childrenProgress.Count -gt 0) {
                $averageProgress = ($childrenProgress | Measure-Object -Average).Average
                $averageProgress = [Math]::Round($averageProgress)

                # Si tous les enfants sont à 100%, le parent doit être à 100%
                if (($childrenProgress | Where-Object { $_ -lt 100 }).Count -eq 0) {
                    $task.$ProgressField = 100
                }
                # Sinon, ajuster le pourcentage du parent pour qu'il soit cohérent avec la moyenne des enfants
                elseif ([Math]::Abs($task.$ProgressField - $averageProgress) -gt 10) {
                    $task.$ProgressField = $averageProgress
                }
            }
        }
    }

    # Deuxième passe : propager les pourcentages d'avancement des parents vers les enfants
    foreach ($task in $Tasks) {
        # Si la tâche a un parent
        if ($task.PSObject.Properties.Name.Contains($ParentIdField) -and $task.$ParentIdField) {
            $parentId = $task.$ParentIdField
            if ($tasksById.ContainsKey($parentId)) {
                $parent = $tasksById[$parentId]

                # Si le parent est à 100%, tous les enfants doivent être à 100%
                if ($parent.$ProgressField -eq 100) {
                    $task.$ProgressField = 100
                }
                # Si le parent est à 0%, les enfants ne peuvent pas avoir un pourcentage élevé
                elseif ($parent.$ProgressField -eq 0 -and $task.$ProgressField -gt 20) {
                    $task.$ProgressField = [Math]::Min($task.$ProgressField, 20)
                }
            }
        }
    }

    return $Tasks
}

# Fonction pour calculer le pourcentage d'avancement pondéré
function Get-WeightedTaskProgress {
    <#
    .SYNOPSIS
        Calcule le pourcentage d'avancement pondéré pour une tâche et ses sous-tâches.

    .DESCRIPTION
        Cette fonction calcule le pourcentage d'avancement pondéré pour une tâche et ses sous-tâches,
        en tenant compte de différents critères de pondération.

    .PARAMETER Tasks
        Les tâches pour lesquelles calculer le pourcentage d'avancement pondéré.

    .PARAMETER RootTaskId
        L'ID de la tâche racine pour laquelle calculer le pourcentage d'avancement pondéré.

    .PARAMETER ProgressField
        Le nom du champ contenant le pourcentage d'avancement dans les tâches.
        Par défaut: "Progress".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER ChildrenField
        Le nom du champ contenant les IDs des enfants dans les tâches.
        Par défaut: "Children".

    .PARAMETER WeightingStrategy
        La stratégie de pondération à utiliser pour le calcul du pourcentage d'avancement.
        Valeurs possibles: "Equal", "ByLevel", "ByComplexity", "Custom"
        Par défaut: "Equal"

    .PARAMETER CustomWeights
        Les poids personnalisés à utiliser pour chaque tâche. Utilisé uniquement avec la stratégie "Custom".
        Format: @{
            "TaskId1" = 10
            "TaskId2" = 5
            "TaskId3" = 2
        }

    .EXAMPLE
        Get-WeightedTaskProgress -Tasks $tasks -RootTaskId "1"
        Calcule le pourcentage d'avancement pondéré pour la tâche avec l'ID "1" et ses sous-tâches.

    .EXAMPLE
        Get-WeightedTaskProgress -Tasks $tasks -RootTaskId "1" -WeightingStrategy "ByLevel"
        Calcule le pourcentage d'avancement pondéré en utilisant une pondération par niveau hiérarchique.

    .OUTPUTS
        System.Int32
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $true)]
        [string]$RootTaskId,

        [Parameter(Mandatory = $false)]
        [string]$ProgressField = "Progress",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Equal", "ByLevel", "ByComplexity", "Custom")]
        [string]$WeightingStrategy = "Equal",

        [Parameter(Mandatory = $false)]
        [hashtable]$CustomWeights = @{}
    )

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Vérifier si la tâche racine existe
    if (-not $tasksById.ContainsKey($RootTaskId)) {
        Write-Error "La tâche racine avec l'ID '$RootTaskId' n'existe pas."
        return 0
    }

    # Fonction récursive pour calculer le pourcentage d'avancement pondéré
    function Get-WeightedProgressRecursively {
        param (
            [string]$TaskId,
            [int]$Level = 0,
            [hashtable]$Weights = @{}
        )

        $task = $tasksById[$TaskId]
        $progress = if ($task.PSObject.Properties.Name.Contains($ProgressField) -and $null -ne $task.$ProgressField) {
            $task.$ProgressField
        } else {
            0
        }

        # Si la tâche n'a pas d'enfants, retourner son pourcentage d'avancement
        if (-not $task.PSObject.Properties.Name.Contains($ChildrenField) -or -not $task.$ChildrenField -or $task.$ChildrenField.Count -eq 0) {
            return @{
                Progress = $progress
                Weight   = if ($Weights.ContainsKey($TaskId)) { $Weights[$TaskId] } else { 1 }
            }
        }

        # Calculer les poids pour les enfants
        $childrenWeights = @{}
        $childrenIds = $task.$ChildrenField

        switch ($WeightingStrategy) {
            "Equal" {
                # Poids égaux pour tous les enfants
                foreach ($childId in $childrenIds) {
                    $childrenWeights[$childId] = 1
                }
            }
            "ByLevel" {
                # Poids inversement proportionnels au niveau hiérarchique
                foreach ($childId in $childrenIds) {
                    $childrenWeights[$childId] = 10 / ($Level + 1)
                }
            }
            "ByComplexity" {
                # Poids proportionnels au nombre de sous-tâches
                foreach ($childId in $childrenIds) {
                    $child = $tasksById[$childId]
                    $subtaskCount = if ($child.PSObject.Properties.Name.Contains($ChildrenField) -and $child.$ChildrenField) {
                        $child.$ChildrenField.Count
                    } else {
                        0
                    }
                    $childrenWeights[$childId] = 1 + $subtaskCount
                }
            }
            "Custom" {
                # Utiliser les poids personnalisés
                foreach ($childId in $childrenIds) {
                    $childrenWeights[$childId] = if ($CustomWeights.ContainsKey($childId)) { $CustomWeights[$childId] } else { 1 }
                }
            }
        }

        # Calculer le pourcentage d'avancement pondéré pour les enfants
        $weightedSum = 0
        $totalWeight = 0

        foreach ($childId in $childrenIds) {
            $result = Get-WeightedProgressRecursively -TaskId $childId -Level ($Level + 1) -Weights $childrenWeights
            $weightedSum += $result.Progress * $result.Weight
            $totalWeight += $result.Weight
        }

        # Calculer le pourcentage d'avancement pondéré
        $weightedProgress = if ($totalWeight -gt 0) {
            [Math]::Round($weightedSum / $totalWeight)
        } else {
            $progress
        }

        return @{
            Progress = $weightedProgress
            Weight   = if ($Weights.ContainsKey($TaskId)) { $Weights[$TaskId] } else { 1 }
        }
    }

    # Calculer le pourcentage d'avancement pondéré pour la tâche racine
    $result = Get-WeightedProgressRecursively -TaskId $RootTaskId
    return $result.Progress
}
