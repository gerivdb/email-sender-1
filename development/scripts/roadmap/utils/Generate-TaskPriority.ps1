# Generate-TaskPriority.ps1
# Script pour attribuer des niveaux de priorité cohérents aux tâches
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Attribue des niveaux de priorité cohérents aux tâches.

.DESCRIPTION
    Ce script fournit des fonctions pour attribuer des niveaux de priorité cohérents aux tâches,
    en tenant compte de la structure hiérarchique, des dépendances et d'autres critères.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour déterminer le niveau de priorité d'une tâche
function Get-TaskPriorityLevel {
    <#
    .SYNOPSIS
        Détermine le niveau de priorité d'une tâche en fonction de critères multiples.

    .DESCRIPTION
        Cette fonction détermine le niveau de priorité d'une tâche en fonction de critères multiples,
        tels que le niveau hiérarchique, les dépendances, les dates d'échéance et l'importance stratégique.

    .PARAMETER Task
        La tâche pour laquelle déterminer le niveau de priorité.

    .PARAMETER HierarchyLevel
        Le niveau hiérarchique de la tâche. Plus le niveau est bas, plus la priorité est élevée.

    .PARAMETER ParentPriority
        La priorité de la tâche parent. La priorité de la tâche ne peut pas être plus élevée que celle du parent.

    .PARAMETER DependenciesPriorities
        Les priorités des tâches dont dépend cette tâche. La priorité de la tâche doit être cohérente avec ses dépendances.

    .PARAMETER DueDate
        La date d'échéance de la tâche. Plus la date est proche, plus la priorité est élevée.

    .PARAMETER Status
        Le statut de la tâche. Les tâches en cours ont généralement une priorité plus élevée.

    .PARAMETER StrategicImportance
        L'importance stratégique de la tâche. Plus l'importance est élevée, plus la priorité est élevée.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des priorités identiques à chaque exécution avec la même graine.

    .EXAMPLE
        Get-TaskPriorityLevel -Task $task -HierarchyLevel 2 -ParentPriority "High"
        Détermine le niveau de priorité d'une tâche en fonction de son niveau hiérarchique et de la priorité de son parent.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Task,

        [Parameter(Mandatory = $false)]
        [int]$HierarchyLevel = 1,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "High", "Medium", "Low")]
        [string]$ParentPriority = $null,

        [Parameter(Mandatory = $false)]
        [string[]]$DependenciesPriorities = @(),

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$DueDate = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$Status = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "High", "Medium", "Low")]
        [string]$StrategicImportance = $null,

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    } else {
        $random = New-Object System.Random
    }

    # Initialiser les scores pour chaque niveau de priorité
    $scores = @{
        "Critical" = 0
        "High"     = 0
        "Medium"   = 0
        "Low"      = 0
    }

    # Facteur 1: Niveau hiérarchique
    # Plus le niveau est bas, plus la priorité est élevée
    switch ($HierarchyLevel) {
        1 { $scores["Critical"] += 3; $scores["High"] += 2 }
        2 { $scores["High"] += 3; $scores["Medium"] += 2 }
        3 { $scores["Medium"] += 3; $scores["Low"] += 2 }
        default { $scores["Low"] += 3 }
    }

    # Facteur 2: Priorité du parent
    # La priorité de la tâche ne peut pas être plus élevée que celle du parent
    if ($ParentPriority) {
        switch ($ParentPriority) {
            "Critical" { $scores["Critical"] += 2 }
            "High" { $scores["High"] += 2; $scores["Critical"] -= 2 }
            "Medium" { $scores["Medium"] += 2; $scores["High"] -= 1; $scores["Critical"] -= 3 }
            "Low" { $scores["Low"] += 2; $scores["Medium"] -= 1; $scores["High"] -= 2; $scores["Critical"] -= 4 }
        }
    }

    # Facteur 3: Priorités des dépendances
    # La priorité de la tâche doit être cohérente avec ses dépendances
    if ($DependenciesPriorities.Count -gt 0) {
        $dependenciesScores = @{
            "Critical" = 0
            "High"     = 0
            "Medium"   = 0
            "Low"      = 0
        }

        foreach ($priority in $DependenciesPriorities) {
            $dependenciesScores[$priority] += 1
        }

        $maxDependencyScore = ($dependenciesScores.Values | Measure-Object -Maximum).Maximum
        $maxDependencyPriority = $dependenciesScores.Keys | Where-Object { $dependenciesScores[$_] -eq $maxDependencyScore } | Select-Object -First 1

        switch ($maxDependencyPriority) {
            "Critical" { $scores["Critical"] += 2; $scores["High"] += 1 }
            "High" { $scores["High"] += 2; $scores["Medium"] += 1 }
            "Medium" { $scores["Medium"] += 2; $scores["Low"] += 1 }
            "Low" { $scores["Low"] += 2 }
        }
    }

    # Facteur 4: Date d'échéance
    # Plus la date est proche, plus la priorité est élevée
    if ($DueDate) {
        $daysUntilDue = ($DueDate - (Get-Date)).Days

        if ($daysUntilDue -le 7) {
            # Échéance dans la semaine
            $scores["Critical"] += 3
            $scores["High"] += 2
        } elseif ($daysUntilDue -le 14) {
            # Échéance dans les deux semaines
            $scores["High"] += 3
            $scores["Medium"] += 1
        } elseif ($daysUntilDue -le 30) {
            # Échéance dans le mois
            $scores["Medium"] += 3
            $scores["Low"] += 1
        } else {
            # Échéance lointaine
            $scores["Low"] += 3
        }
    }

    # Facteur 5: Statut
    # Les tâches en cours ont généralement une priorité plus élevée
    if ($Status) {
        switch ($Status) {
            "InProgress" { $scores["High"] += 2; $scores["Medium"] += 1 }
            "Blocked" { $scores["Critical"] += 1; $scores["High"] += 2 }
            "NotStarted" { $scores["Medium"] += 1; $scores["Low"] += 1 }
            "Completed" { $scores["Low"] += 3; $scores["Medium"] -= 1; $scores["High"] -= 2; $scores["Critical"] -= 3 }
        }
    }

    # Facteur 6: Importance stratégique
    # Plus l'importance est élevée, plus la priorité est élevée
    if ($StrategicImportance) {
        switch ($StrategicImportance) {
            "Critical" { $scores["Critical"] += 4; $scores["High"] += 2 }
            "High" { $scores["High"] += 4; $scores["Medium"] += 2 }
            "Medium" { $scores["Medium"] += 4; $scores["Low"] += 2 }
            "Low" { $scores["Low"] += 4 }
        }
    }

    # Facteur 7: Aléatoire
    # Ajouter un peu d'aléatoire pour éviter les égalités
    $scores["Critical"] += $random.Next(0, 2)
    $scores["High"] += $random.Next(0, 2)
    $scores["Medium"] += $random.Next(0, 2)
    $scores["Low"] += $random.Next(0, 2)

    # Déterminer la priorité en fonction des scores
    $maxScore = ($scores.Values | Measure-Object -Maximum).Maximum
    $priority = $scores.Keys | Where-Object { $scores[$_] -eq $maxScore } | Select-Object -First 1

    return $priority
}

# Fonction pour attribuer des niveaux de priorité à une hiérarchie de tâches
function New-TaskPriorityAssignment {
    <#
    .SYNOPSIS
        Attribue des niveaux de priorité à une hiérarchie de tâches.

    .DESCRIPTION
        Cette fonction attribue des niveaux de priorité à une hiérarchie de tâches,
        en tenant compte de la structure hiérarchique, des dépendances et d'autres critères.

    .PARAMETER Tasks
        Les tâches auxquelles attribuer des niveaux de priorité.

    .PARAMETER PriorityField
        Le nom du champ dans lequel stocker le niveau de priorité dans les tâches.
        Par défaut: "Priority".

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

    .PARAMETER DueDateField
        Le nom du champ contenant la date d'échéance dans les tâches.
        Par défaut: "DueDate".

    .PARAMETER ImportanceField
        Le nom du champ contenant l'importance stratégique dans les tâches.
        Par défaut: "Importance".

    .PARAMETER DependenciesField
        Le nom du champ contenant les IDs des dépendances dans les tâches.
        Par défaut: "Dependencies".

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des priorités identiques à chaque exécution avec la même graine.

    .EXAMPLE
        New-TaskPriorityAssignment -Tasks $tasks
        Attribue des niveaux de priorité aux tâches spécifiées.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$PriorityField = "Priority",

        [Parameter(Mandatory = $false)]
        [string]$StatusField = "Status",

        [Parameter(Mandatory = $false)]
        [string]$ParentIdField = "ParentId",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children",

        [Parameter(Mandatory = $false)]
        [string]$DueDateField = "DueDate",

        [Parameter(Mandatory = $false)]
        [string]$ImportanceField = "Importance",

        [Parameter(Mandatory = $false)]
        [string]$DependenciesField = "Dependencies",

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Fonction récursive pour attribuer des priorités
    function Set-PriorityRecursively {
        param (
            [PSObject]$Task,
            [int]$Level = 1,
            [string]$ParentPriority = $null
        )

        # Si la tâche a déjà une priorité, l'utiliser
        if ($Task.PSObject.Properties.Name.Contains($PriorityField) -and $null -ne $Task.$PriorityField) {
            $priority = $Task.$PriorityField
        } else {
            # Déterminer le statut de la tâche
            $status = if ($Task.PSObject.Properties.Name.Contains($StatusField) -and $Task.$StatusField) {
                $Task.$StatusField
            } else {
                "NotStarted"
            }

            # Déterminer la date d'échéance de la tâche
            $dueDate = if ($Task.PSObject.Properties.Name.Contains($DueDateField) -and $Task.$DueDateField) {
                $Task.$DueDateField
            } else {
                $null
            }

            # Déterminer l'importance stratégique de la tâche
            $importance = if ($Task.PSObject.Properties.Name.Contains($ImportanceField) -and $Task.$ImportanceField) {
                $Task.$ImportanceField
            } else {
                $null
            }

            # Déterminer les dépendances de la tâche
            $dependencies = @()
            if ($Task.PSObject.Properties.Name.Contains($DependenciesField) -and $Task.$DependenciesField) {
                foreach ($depId in $Task.$DependenciesField) {
                    if ($tasksById.ContainsKey($depId) -and $tasksById[$depId].PSObject.Properties.Name.Contains($PriorityField)) {
                        $dependencies += $tasksById[$depId].$PriorityField
                    }
                }
            }

            # Générer une priorité en fonction des critères
            $priority = Get-TaskPriorityLevel -Task $Task -HierarchyLevel $Level -ParentPriority $ParentPriority -DependenciesPriorities $dependencies -DueDate $dueDate -Status $status -StrategicImportance $importance -RandomSeed ($RandomSeed + $Task.$IdField.GetHashCode())

            # Assigner la priorité à la tâche
            if (-not $Task.PSObject.Properties.Name.Contains($PriorityField)) {
                Add-Member -InputObject $Task -MemberType NoteProperty -Name $PriorityField -Value $priority
            } else {
                $Task.$PriorityField = $priority
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
                Set-PriorityRecursively -Task $child -Level ($Level + 1) -ParentPriority $priority
            }
        }
    }

    # Trouver les tâches racines (sans parent)
    $rootTasks = $Tasks | Where-Object { -not $_.$ParentIdField }

    # Attribuer des priorités pour chaque arbre
    foreach ($rootTask in $rootTasks) {
        Set-PriorityRecursively -Task $rootTask
    }

    # Vérifier et ajuster la cohérence
    Update-TaskPriorityHierarchy -Tasks $Tasks -PriorityField $PriorityField -ParentIdField $ParentIdField -IdField $IdField -ChildrenField $ChildrenField -DependenciesField $DependenciesField

    return $Tasks
}

# Fonction pour mettre à jour les priorités pour maintenir la cohérence hiérarchique
function Update-TaskPriorityHierarchy {
    <#
    .SYNOPSIS
        Met à jour les priorités pour maintenir la cohérence hiérarchique.

    .DESCRIPTION
        Cette fonction met à jour les priorités pour maintenir la cohérence hiérarchique,
        en appliquant les règles suivantes :
        - Les tâches enfants ne peuvent pas avoir une priorité plus élevée que leur parent
        - Les tâches dépendantes doivent avoir une priorité cohérente avec leurs dépendances
        - Les priorités doivent être équilibrées dans l'ensemble du projet

    .PARAMETER Tasks
        Les tâches à mettre à jour.

    .PARAMETER PriorityField
        Le nom du champ contenant le niveau de priorité dans les tâches.
        Par défaut: "Priority".

    .PARAMETER ParentIdField
        Le nom du champ contenant l'ID du parent dans les tâches.
        Par défaut: "ParentId".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER ChildrenField
        Le nom du champ contenant les IDs des enfants dans les tâches.
        Par défaut: "Children".

    .PARAMETER DependenciesField
        Le nom du champ contenant les IDs des dépendances dans les tâches.
        Par défaut: "Dependencies".

    .EXAMPLE
        Update-TaskPriorityHierarchy -Tasks $tasks
        Met à jour les priorités des tâches pour maintenir la cohérence hiérarchique.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$PriorityField = "Priority",

        [Parameter(Mandatory = $false)]
        [string]$ParentIdField = "ParentId",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children",

        [Parameter(Mandatory = $false)]
        [string]$DependenciesField = "Dependencies"
    )

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Définir l'ordre des priorités (du plus élevé au plus bas)
    $priorityOrder = @("Critical", "High", "Medium", "Low")

    # Première passe : ajuster les priorités des enfants en fonction des parents
    foreach ($task in $Tasks) {
        # Si la tâche a un parent
        if ($task.PSObject.Properties.Name.Contains($ParentIdField) -and $task.$ParentIdField) {
            $parentId = $task.$ParentIdField
            if ($tasksById.ContainsKey($parentId)) {
                $parent = $tasksById[$parentId]

                # Si le parent a une priorité
                if ($parent.PSObject.Properties.Name.Contains($PriorityField) -and $parent.$PriorityField) {
                    $parentPriority = $parent.$PriorityField
                    $childPriority = $task.$PriorityField

                    # Si la priorité de l'enfant est plus élevée que celle du parent
                    $parentPriorityIndex = $priorityOrder.IndexOf($parentPriority)
                    $childPriorityIndex = $priorityOrder.IndexOf($childPriority)

                    if ($childPriorityIndex -lt $parentPriorityIndex) {
                        # Ajuster la priorité de l'enfant pour qu'elle ne soit pas plus élevée que celle du parent
                        $task.$PriorityField = $parentPriority
                    }
                }
            }
        }
    }

    # Deuxième passe : ajuster les priorités en fonction des dépendances
    foreach ($task in $Tasks) {
        # Si la tâche a des dépendances
        if ($task.PSObject.Properties.Name.Contains($DependenciesField) -and $task.$DependenciesField) {
            $dependencies = $task.$DependenciesField
            $dependenciesPriorities = @()

            # Collecter les priorités des dépendances
            foreach ($depId in $dependencies) {
                if ($tasksById.ContainsKey($depId) -and $tasksById[$depId].PSObject.Properties.Name.Contains($PriorityField)) {
                    $dependenciesPriorities += $tasksById[$depId].$PriorityField
                }
            }

            # Si la tâche a des dépendances avec des priorités
            if ($dependenciesPriorities.Count -gt 0) {
                # Trouver la priorité la plus élevée parmi les dépendances
                $highestDependencyPriorityIndex = ($dependenciesPriorities | ForEach-Object { $priorityOrder.IndexOf($_) } | Measure-Object -Minimum).Minimum
                $highestDependencyPriority = $priorityOrder[$highestDependencyPriorityIndex]

                # Si la priorité de la tâche est plus basse que la priorité la plus élevée parmi les dépendances
                $taskPriorityIndex = $priorityOrder.IndexOf($task.$PriorityField)

                if ($taskPriorityIndex -gt $highestDependencyPriorityIndex) {
                    # Ajuster la priorité de la tâche pour qu'elle soit au moins aussi élevée que la priorité la plus élevée parmi les dépendances
                    $task.$PriorityField = $highestDependencyPriority
                }
            }
        }
    }

    # Troisième passe : équilibrer les priorités dans l'ensemble du projet
    $priorityCounts = @{
        "Critical" = 0
        "High"     = 0
        "Medium"   = 0
        "Low"      = 0
    }

    # Compter les priorités
    foreach ($task in $Tasks) {
        if ($task.PSObject.Properties.Name.Contains($PriorityField) -and $task.$PriorityField) {
            $priorityCounts[$task.$PriorityField] += 1
        }
    }

    # Calculer le pourcentage de chaque priorité
    $totalTasks = $Tasks.Count
    $priorityPercentages = @{}
    foreach ($priority in $priorityCounts.Keys) {
        $priorityPercentages[$priority] = [Math]::Round(($priorityCounts[$priority] / $totalTasks) * 100)
    }

    # Vérifier si les pourcentages sont équilibrés
    $targetPercentages = @{
        "Critical" = 10
        "High"     = 20
        "Medium"   = 40
        "Low"      = 30
    }

    $adjustments = @{}
    foreach ($priority in $priorityPercentages.Keys) {
        $diff = $priorityPercentages[$priority] - $targetPercentages[$priority]
        $adjustments[$priority] = $diff
    }

    # Si des ajustements sont nécessaires, ajuster les priorités des tâches sans parent ni dépendances
    if (($adjustments.Values | ForEach-Object { [Math]::Abs($_) } | Measure-Object -Sum).Sum -gt 20) {
        $independentTasks = $Tasks | Where-Object {
            (-not $_.PSObject.Properties.Name.Contains($ParentIdField) -or -not $_.$ParentIdField) -and
            (-not $_.PSObject.Properties.Name.Contains($DependenciesField) -or -not $_.$DependenciesField -or $_.$DependenciesField.Count -eq 0)
        }

        # Trier les priorités par ajustement (du plus grand au plus petit)
        $prioritiesToAdjust = $adjustments.Keys | Sort-Object { $adjustments[$_] } -Descending

        # Pour chaque priorité à ajuster
        foreach ($priority in $prioritiesToAdjust) {
            $adjustment = $adjustments[$priority]

            # Si l'ajustement est positif (trop de tâches avec cette priorité)
            if ($adjustment -gt 5) {
                $tasksToAdjust = $independentTasks | Where-Object { $_.$PriorityField -eq $priority }
                $tasksToAdjustCount = [Math]::Min($tasksToAdjust.Count, [Math]::Round(($adjustment / 100) * $totalTasks))

                # Trouver la priorité la plus proche avec un ajustement négatif
                $targetPriority = $prioritiesToAdjust | Where-Object { $adjustments[$_] -lt 0 } | Select-Object -First 1

                # Ajuster les priorités
                for ($i = 0; $i -lt $tasksToAdjustCount; $i++) {
                    if ($i -lt $tasksToAdjust.Count) {
                        $tasksToAdjust[$i].$PriorityField = $targetPriority
                    }
                }
            }
        }
    }

    return $Tasks
}
