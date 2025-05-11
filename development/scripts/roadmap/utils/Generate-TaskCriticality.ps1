# Generate-TaskCriticality.ps1
# Script pour calculer la criticité des tâches en fonction de leurs dépendances
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Calcule la criticité des tâches en fonction de leurs dépendances.

.DESCRIPTION
    Ce script fournit des fonctions pour calculer la criticité des tâches en fonction de leurs dépendances,
    identifier les chemins critiques et attribuer des niveaux de criticité aux tâches.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour déterminer le niveau de criticité d'une tâche
function Get-TaskCriticalityLevel {
    <#
    .SYNOPSIS
        Détermine le niveau de criticité d'une tâche en fonction de ses dépendances.

    .DESCRIPTION
        Cette fonction détermine le niveau de criticité d'une tâche en fonction de ses dépendances,
        du nombre de tâches qui en dépendent, de sa position dans le chemin critique et d'autres facteurs.

    .PARAMETER Task
        La tâche pour laquelle déterminer le niveau de criticité.

    .PARAMETER DependentTasksCount
        Le nombre de tâches qui dépendent de cette tâche. Plus ce nombre est élevé, plus la tâche est critique.

    .PARAMETER IsOnCriticalPath
        Indique si la tâche est sur le chemin critique. Les tâches sur le chemin critique sont plus critiques.

    .PARAMETER DueDate
        La date d'échéance de la tâche. Plus la date est proche, plus la tâche est critique.

    .PARAMETER Priority
        La priorité de la tâche. Les tâches de priorité élevée sont généralement plus critiques.

    .PARAMETER BlockerCount
        Le nombre de tâches bloquées par cette tâche. Plus ce nombre est élevé, plus la tâche est critique.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des niveaux de criticité identiques à chaque exécution avec la même graine.

    .EXAMPLE
        Get-TaskCriticalityLevel -Task $task -DependentTasksCount 5 -IsOnCriticalPath $true
        Détermine le niveau de criticité d'une tâche qui a 5 tâches dépendantes et qui est sur le chemin critique.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Task,

        [Parameter(Mandatory = $false)]
        [int]$DependentTasksCount = 0,

        [Parameter(Mandatory = $false)]
        [bool]$IsOnCriticalPath = $false,

        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$DueDate = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "High", "Medium", "Low")]
        [string]$Priority = $null,

        [Parameter(Mandatory = $false)]
        [int]$BlockerCount = 0,

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    } else {
        $random = New-Object System.Random
    }

    # Initialiser les scores pour chaque niveau de criticité
    $scores = @{
        "Critical" = 0
        "High"     = 0
        "Medium"   = 0
        "Low"      = 0
    }

    # Facteur 1: Nombre de tâches dépendantes
    # Plus il y a de tâches qui dépendent de cette tâche, plus elle est critique
    if ($DependentTasksCount -ge 10) {
        $scores["Critical"] += 3
        $scores["High"] += 2
    } elseif ($DependentTasksCount -ge 5) {
        $scores["High"] += 3
        $scores["Medium"] += 1
    } elseif ($DependentTasksCount -ge 2) {
        $scores["Medium"] += 3
        $scores["Low"] += 1
    } else {
        $scores["Low"] += 3
    }

    # Facteur 2: Position sur le chemin critique
    # Les tâches sur le chemin critique sont plus critiques
    if ($IsOnCriticalPath) {
        $scores["Critical"] += 4
        $scores["High"] += 2
    }

    # Facteur 3: Date d'échéance
    # Plus la date est proche, plus la tâche est critique
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

    # Facteur 4: Priorité
    # Les tâches de priorité élevée sont généralement plus critiques
    if ($Priority) {
        switch ($Priority) {
            "Critical" { $scores["Critical"] += 3; $scores["High"] += 1 }
            "High" { $scores["High"] += 3; $scores["Medium"] += 1 }
            "Medium" { $scores["Medium"] += 3; $scores["Low"] += 1 }
            "Low" { $scores["Low"] += 3 }
        }
    }

    # Facteur 5: Nombre de tâches bloquées
    # Plus il y a de tâches bloquées par cette tâche, plus elle est critique
    if ($BlockerCount -ge 5) {
        $scores["Critical"] += 3
        $scores["High"] += 1
    } elseif ($BlockerCount -ge 2) {
        $scores["High"] += 3
        $scores["Medium"] += 1
    } elseif ($BlockerCount -ge 1) {
        $scores["Medium"] += 3
        $scores["Low"] += 1
    } else {
        $scores["Low"] += 2
    }

    # Facteur 6: Aléatoire
    # Ajouter un peu d'aléatoire pour éviter les égalités
    $scores["Critical"] += $random.Next(0, 2)
    $scores["High"] += $random.Next(0, 2)
    $scores["Medium"] += $random.Next(0, 2)
    $scores["Low"] += $random.Next(0, 2)

    # Déterminer la criticité en fonction des scores
    $maxScore = ($scores.Values | Measure-Object -Maximum).Maximum
    $criticality = $scores.Keys | Where-Object { $scores[$_] -eq $maxScore } | Select-Object -First 1

    # Forcer la criticité en fonction des facteurs dominants
    if ($IsOnCriticalPath -and $DependentTasksCount -ge 5) {
        $criticality = "Critical"
    } elseif ($IsOnCriticalPath -or $DependentTasksCount -ge 10 -or $BlockerCount -ge 5) {
        $criticality = "High"
    } elseif ($DependentTasksCount -ge 3 -or $BlockerCount -ge 2) {
        $criticality = "Medium"
    }

    # Forcer la criticité en fonction de la priorité
    if ($Priority -eq "Critical") {
        $criticality = "Critical"
    } elseif ($Priority -eq "High" -and $criticality -eq "Low") {
        $criticality = "Medium"
    }

    # Forcer la criticité en fonction de la date d'échéance
    if ($DueDate -and ($DueDate - (Get-Date)).Days -le 7) {
        $criticality = "Critical"
    }

    return $criticality
}

# Fonction pour attribuer des niveaux de criticité à une hiérarchie de tâches
function New-TaskCriticalityAssignment {
    <#
    .SYNOPSIS
        Attribue des niveaux de criticité à une hiérarchie de tâches.

    .DESCRIPTION
        Cette fonction attribue des niveaux de criticité à une hiérarchie de tâches,
        en tenant compte des dépendances entre les tâches et d'autres facteurs.

    .PARAMETER Tasks
        Les tâches auxquelles attribuer des niveaux de criticité.

    .PARAMETER CriticalityField
        Le nom du champ dans lequel stocker le niveau de criticité dans les tâches.
        Par défaut: "Criticality".

    .PARAMETER PriorityField
        Le nom du champ contenant la priorité dans les tâches.
        Par défaut: "Priority".

    .PARAMETER DueDateField
        Le nom du champ contenant la date d'échéance dans les tâches.
        Par défaut: "DueDate".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER DependenciesField
        Le nom du champ contenant les IDs des dépendances dans les tâches.
        Par défaut: "Dependencies".

    .PARAMETER DependentsField
        Le nom du champ contenant les IDs des tâches dépendantes dans les tâches.
        Par défaut: "Dependents".

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des niveaux de criticité identiques à chaque exécution avec la même graine.

    .EXAMPLE
        New-TaskCriticalityAssignment -Tasks $tasks
        Attribue des niveaux de criticité aux tâches spécifiées.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$CriticalityField = "Criticality",

        [Parameter(Mandatory = $false)]
        [string]$PriorityField = "Priority",

        [Parameter(Mandatory = $false)]
        [string]$DueDateField = "DueDate",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$DependenciesField = "Dependencies",

        [Parameter(Mandatory = $false)]
        [string]$DependentsField = "Dependents",

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Construire le graphe de dépendances
    $dependencyGraph = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $dependencyGraph[$id] = @()

        # Ajouter les dépendances explicites
        if ($task.PSObject.Properties.Name.Contains($DependenciesField) -and $task.$DependenciesField) {
            foreach ($depId in $task.$DependenciesField) {
                if ($tasksById.ContainsKey($depId)) {
                    $dependencyGraph[$id] += $depId
                }
            }
        }
    }

    # Identifier le chemin critique
    $criticalPath = Find-CriticalPath -DependencyGraph $dependencyGraph -Tasks $tasksById

    # Calculer le nombre de tâches dépendantes pour chaque tâche
    $dependentCounts = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $dependentCounts[$id] = 0
    }

    foreach ($task in $Tasks) {
        $id = $task.$IdField
        if ($task.PSObject.Properties.Name.Contains($DependenciesField) -and $task.$DependenciesField) {
            foreach ($depId in $task.$DependenciesField) {
                if ($dependentCounts.ContainsKey($depId)) {
                    $dependentCounts[$depId] += 1
                }
            }
        }
    }

    # Calculer le nombre de tâches bloquées par chaque tâche
    $blockerCounts = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $blockerCounts[$id] = 0
    }

    foreach ($task in $Tasks) {
        $id = $task.$IdField
        if ($task.PSObject.Properties.Name.Contains($DependenciesField) -and $task.$DependenciesField) {
            foreach ($depId in $task.$DependenciesField) {
                if ($blockerCounts.ContainsKey($depId)) {
                    $blockerCounts[$depId] += 1
                }
            }
        }
    }

    # Attribuer des niveaux de criticité à chaque tâche
    foreach ($task in $Tasks) {
        $id = $task.$IdField

        # Déterminer la priorité de la tâche
        $priority = if ($task.PSObject.Properties.Name.Contains($PriorityField) -and $task.$PriorityField) {
            $task.$PriorityField
        } else {
            $null
        }

        # Déterminer la date d'échéance de la tâche
        $dueDate = if ($task.PSObject.Properties.Name.Contains($DueDateField) -and $task.$DueDateField) {
            $task.$DueDateField
        } else {
            $null
        }

        # Déterminer si la tâche est sur le chemin critique
        $isOnCriticalPath = $criticalPath -contains $id

        # Calculer le niveau de criticité
        $criticality = Get-TaskCriticalityLevel -Task $task -DependentTasksCount $dependentCounts[$id] -IsOnCriticalPath $isOnCriticalPath -DueDate $dueDate -Priority $priority -BlockerCount $blockerCounts[$id] -RandomSeed ($RandomSeed + $id.GetHashCode())

        # Assigner le niveau de criticité à la tâche
        if (-not $task.PSObject.Properties.Name.Contains($CriticalityField)) {
            Add-Member -InputObject $task -MemberType NoteProperty -Name $CriticalityField -Value $criticality
        } else {
            $task.$CriticalityField = $criticality
        }
    }

    return $Tasks
}

# Fonction pour identifier le chemin critique dans un graphe de dépendances
function Find-CriticalPath {
    <#
    .SYNOPSIS
        Identifie le chemin critique dans un graphe de dépendances de tâches.

    .DESCRIPTION
        Cette fonction identifie le chemin critique dans un graphe de dépendances de tâches,
        c'est-à-dire le chemin le plus long du début à la fin du projet.

    .PARAMETER DependencyGraph
        Le graphe de dépendances des tâches.

    .PARAMETER Tasks
        Les tâches du projet.

    .PARAMETER DurationField
        Le nom du champ contenant la durée des tâches.
        Par défaut: "Duration".

    .EXAMPLE
        Find-CriticalPath -DependencyGraph $dependencyGraph -Tasks $tasks
        Identifie le chemin critique dans le graphe de dépendances spécifié.

    .OUTPUTS
        System.String[]
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DependencyGraph,

        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$DurationField = "Duration"
    )

    # Trouver les tâches de début (sans dépendances)
    $startTasks = @()
    foreach ($taskId in $DependencyGraph.Keys) {
        $hasDependencies = $false
        foreach ($dependencies in $DependencyGraph.Values) {
            if ($dependencies -contains $taskId) {
                $hasDependencies = $true
                break
            }
        }
        if (-not $hasDependencies) {
            $startTasks += $taskId
        }
    }

    # Trouver les tâches de fin (sans tâches dépendantes)
    $endTasks = @()
    foreach ($taskId in $DependencyGraph.Keys) {
        if ($DependencyGraph[$taskId].Count -eq 0) {
            $endTasks += $taskId
        }
    }

    # Si aucune tâche de début ou de fin n'est trouvée, retourner un tableau vide
    if ($startTasks.Count -eq 0 -or $endTasks.Count -eq 0) {
        return @()
    }

    # Calculer les durées des tâches
    $durations = @{}
    foreach ($taskId in $DependencyGraph.Keys) {
        $task = $Tasks[$taskId]
        $duration = if ($task.PSObject.Properties.Name.Contains($DurationField) -and $task.$DurationField) {
            $task.$DurationField
        } else {
            1  # Durée par défaut
        }
        $durations[$taskId] = $duration
    }

    # Calculer les dates au plus tôt (early start/finish)
    $earlyStart = @{}
    $earlyFinish = @{}
    foreach ($taskId in $DependencyGraph.Keys) {
        $earlyStart[$taskId] = 0
        $earlyFinish[$taskId] = 0
    }

    # Calculer les dates au plus tôt en parcourant le graphe
    $changed = $true
    while ($changed) {
        $changed = $false
        foreach ($taskId in $DependencyGraph.Keys) {
            $maxEarlyFinish = 0
            foreach ($dependencies in $DependencyGraph.Values) {
                if ($dependencies -contains $taskId) {
                    foreach ($depId in $DependencyGraph.Keys) {
                        if ($DependencyGraph[$depId] -contains $taskId) {
                            $depEarlyFinish = $earlyFinish[$depId]
                            if ($depEarlyFinish -gt $maxEarlyFinish) {
                                $maxEarlyFinish = $depEarlyFinish
                            }
                        }
                    }
                }
            }
            if ($earlyStart[$taskId] -ne $maxEarlyFinish) {
                $earlyStart[$taskId] = $maxEarlyFinish
                $earlyFinish[$taskId] = $maxEarlyFinish + $durations[$taskId]
                $changed = $true
            }
        }
    }

    # Calculer les dates au plus tard (late start/finish)
    $lateStart = @{}
    $lateFinish = @{}
    $maxEarlyFinish = 0
    foreach ($taskId in $endTasks) {
        if ($earlyFinish[$taskId] -gt $maxEarlyFinish) {
            $maxEarlyFinish = $earlyFinish[$taskId]
        }
    }
    foreach ($taskId in $DependencyGraph.Keys) {
        $lateFinish[$taskId] = $maxEarlyFinish
        $lateStart[$taskId] = $maxEarlyFinish - $durations[$taskId]
    }

    # Calculer les dates au plus tard en parcourant le graphe à l'envers
    $changed = $true
    while ($changed) {
        $changed = $false
        foreach ($taskId in $DependencyGraph.Keys) {
            $minLateStart = $maxEarlyFinish
            foreach ($depId in $DependencyGraph[$taskId]) {
                $depLateStart = $lateStart[$depId]
                if ($depLateStart -lt $minLateStart) {
                    $minLateStart = $depLateStart
                }
            }
            if ($DependencyGraph[$taskId].Count -gt 0 -and $lateFinish[$taskId] -ne $minLateStart) {
                $lateFinish[$taskId] = $minLateStart
                $lateStart[$taskId] = $minLateStart - $durations[$taskId]
                $changed = $true
            }
        }
    }

    # Calculer les marges (slack)
    $slack = @{}
    foreach ($taskId in $DependencyGraph.Keys) {
        $slack[$taskId] = $lateStart[$taskId] - $earlyStart[$taskId]
    }

    # Identifier les tâches sur le chemin critique (marge = 0)
    $criticalPath = @()
    foreach ($taskId in $DependencyGraph.Keys) {
        if ($slack[$taskId] -eq 0) {
            $criticalPath += $taskId
        }
    }

    return $criticalPath
}
