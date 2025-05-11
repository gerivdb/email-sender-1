# Generate-TaskStatus.ps1
# Script pour générer des statuts cohérents pour les tâches
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère des statuts cohérents pour les tâches en fonction de leur structure hiérarchique.

.DESCRIPTION
    Ce script fournit des fonctions pour générer des statuts cohérents pour les tâches,
    en tenant compte de leur structure hiérarchique et des règles de cohérence.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour générer un statut aléatoire
function Get-RandomTaskStatus {
    <#
    .SYNOPSIS
        Génère un statut aléatoire pour une tâche.

    .DESCRIPTION
        Cette fonction génère un statut aléatoire pour une tâche, avec des pondérations
        personnalisables pour chaque statut.

    .PARAMETER Weights
        Les pondérations pour chaque statut. Plus la pondération est élevée, plus le statut
        a de chances d'être sélectionné.
        Format: @{
            "NotStarted" = 40
            "InProgress" = 30
            "Completed" = 25
            "Blocked" = 5
        }

    .PARAMETER ExcludeStatuses
        Les statuts à exclure de la sélection aléatoire.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des statuts identiques à chaque exécution avec la même graine.

    .EXAMPLE
        Get-RandomTaskStatus
        Génère un statut aléatoire avec les pondérations par défaut.

    .EXAMPLE
        Get-RandomTaskStatus -Weights @{ "NotStarted" = 20; "InProgress" = 60; "Completed" = 15; "Blocked" = 5 }
        Génère un statut aléatoire avec des pondérations personnalisées.

    .EXAMPLE
        Get-RandomTaskStatus -ExcludeStatuses @("Completed", "Blocked")
        Génère un statut aléatoire en excluant les statuts "Completed" et "Blocked".

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$Weights = @{
            "NotStarted" = 40
            "InProgress" = 30
            "Completed" = 25
            "Blocked" = 5
        },

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeStatuses = @(),

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    }
    else {
        $random = New-Object System.Random
    }

    # Filtrer les statuts exclus
    $filteredWeights = @{}
    foreach ($status in $Weights.Keys) {
        if ($ExcludeStatuses -notcontains $status) {
            $filteredWeights[$status] = $Weights[$status]
        }
    }

    # Si tous les statuts sont exclus, retourner "NotStarted"
    if ($filteredWeights.Count -eq 0) {
        return "NotStarted"
    }

    # Calculer le poids total
    $totalWeight = ($filteredWeights.Values | Measure-Object -Sum).Sum

    # Générer un nombre aléatoire entre 1 et le poids total
    $randomValue = $random.Next(1, $totalWeight + 1)

    # Sélectionner le statut en fonction du poids
    $cumulativeWeight = 0
    foreach ($status in $filteredWeights.Keys) {
        $cumulativeWeight += $filteredWeights[$status]
        if ($randomValue -le $cumulativeWeight) {
            return $status
        }
    }

    # Par défaut, retourner "NotStarted"
    return "NotStarted"
}

# Fonction pour générer des statuts cohérents pour une hiérarchie de tâches
function New-StatusHierarchy {
    <#
    .SYNOPSIS
        Génère des statuts cohérents pour une hiérarchie de tâches.

    .DESCRIPTION
        Cette fonction génère des statuts cohérents pour une hiérarchie de tâches,
        en tenant compte des règles de cohérence hiérarchique.

    .PARAMETER Tasks
        Les tâches pour lesquelles générer des statuts.

    .PARAMETER StatusField
        Le nom du champ dans lequel stocker le statut dans les tâches.
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

    .PARAMETER Weights
        Les pondérations pour chaque statut. Plus la pondération est élevée, plus le statut
        a de chances d'être sélectionné.
        Format: @{
            "NotStarted" = 40
            "InProgress" = 30
            "Completed" = 25
            "Blocked" = 5
        }

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des statuts identiques à chaque exécution avec la même graine.

    .EXAMPLE
        New-StatusHierarchy -Tasks $tasks
        Génère des statuts cohérents pour les tâches spécifiées.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$StatusField = "Status",

        [Parameter(Mandatory = $false)]
        [string]$ParentIdField = "ParentId",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children",

        [Parameter(Mandatory = $false)]
        [hashtable]$Weights = @{
            "NotStarted" = 40
            "InProgress" = 30
            "Completed" = 25
            "Blocked" = 5
        },

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    }
    else {
        $random = New-Object System.Random
    }

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Fonction récursive pour générer des statuts cohérents
    function Set-StatusRecursively {
        param (
            [PSObject]$Task,
            [string]$ParentStatus = $null
        )

        # Si la tâche a déjà un statut, l'utiliser
        if ($Task.PSObject.Properties.Name.Contains($StatusField) -and $Task.$StatusField) {
            $status = $Task.$StatusField
        }
        else {
            # Déterminer les statuts possibles en fonction du statut du parent
            $excludeStatuses = @()
            
            if ($ParentStatus -eq "Completed") {
                # Si le parent est complété, tous les enfants doivent être complétés
                $status = "Completed"
            }
            elseif ($ParentStatus -eq "NotStarted") {
                # Si le parent n'est pas commencé, les enfants ne peuvent pas être en cours ou complétés
                $excludeStatuses += @("InProgress", "Completed")
                $status = Get-RandomTaskStatus -Weights $Weights -ExcludeStatuses $excludeStatuses -RandomSeed ($RandomSeed + $Task.$IdField.GetHashCode())
            }
            elseif ($ParentStatus -eq "Blocked") {
                # Si le parent est bloqué, certains enfants doivent être bloqués
                $blockProbability = 0.7  # 70% de chance qu'un enfant soit bloqué si le parent est bloqué
                if ($random.NextDouble() -lt $blockProbability) {
                    $status = "Blocked"
                }
                else {
                    $excludeStatuses += @("Completed")
                    $status = Get-RandomTaskStatus -Weights $Weights -ExcludeStatuses $excludeStatuses -RandomSeed ($RandomSeed + $Task.$IdField.GetHashCode())
                }
            }
            else {
                # Sinon, générer un statut aléatoire
                $status = Get-RandomTaskStatus -Weights $Weights -RandomSeed ($RandomSeed + $Task.$IdField.GetHashCode())
            }

            # Assigner le statut à la tâche
            if (-not $Task.PSObject.Properties.Name.Contains($StatusField)) {
                Add-Member -InputObject $Task -MemberType NoteProperty -Name $StatusField -Value $status
            }
            else {
                $Task.$StatusField = $status
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
                Set-StatusRecursively -Task $child -ParentStatus $status
            }
        }
    }

    # Trouver les tâches racines (sans parent)
    $rootTasks = $Tasks | Where-Object { -not $_.$ParentIdField }

    # Générer les statuts pour chaque arbre
    foreach ($rootTask in $rootTasks) {
        Set-StatusRecursively -Task $rootTask
    }

    # Vérifier et ajuster la cohérence
    Update-TaskStatusHierarchy -Tasks $Tasks -StatusField $StatusField -ParentIdField $ParentIdField -IdField $IdField -ChildrenField $ChildrenField

    return $Tasks
}

# Fonction pour mettre à jour les statuts des tâches pour maintenir la cohérence hiérarchique
function Update-TaskStatusHierarchy {
    <#
    .SYNOPSIS
        Met à jour les statuts des tâches pour maintenir la cohérence hiérarchique.

    .DESCRIPTION
        Cette fonction met à jour les statuts des tâches pour maintenir la cohérence hiérarchique,
        en appliquant les règles suivantes :
        - Si une tâche parent est complétée, toutes ses tâches enfants doivent être complétées
        - Si une tâche parent est bloquée, certaines de ses tâches enfants doivent être bloquées
        - Si une tâche enfant est en cours, la tâche parent doit être au moins en cours
        - Si toutes les tâches enfants sont complétées, la tâche parent peut être complétée

    .PARAMETER Tasks
        Les tâches à mettre à jour.

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

    .EXAMPLE
        Update-TaskStatusHierarchy -Tasks $tasks
        Met à jour les statuts des tâches pour maintenir la cohérence hiérarchique.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$StatusField = "Status",

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

    # Fonction pour vérifier si tous les enfants ont un statut spécifique
    function Test-AllChildrenStatus {
        param (
            [PSObject]$Task,
            [string]$Status
        )

        $childrenIds = @()
        if ($Task.PSObject.Properties.Name.Contains($ChildrenField) -and $Task.$ChildrenField) {
            $childrenIds = $Task.$ChildrenField
        }

        if ($childrenIds.Count -eq 0) {
            return $true
        }

        foreach ($childId in $childrenIds) {
            if ($tasksById.ContainsKey($childId)) {
                $child = $tasksById[$childId]
                if ($child.$StatusField -ne $Status) {
                    return $false
                }
            }
        }

        return $true
    }

    # Fonction pour vérifier si au moins un enfant a un statut spécifique
    function Test-AnyChildStatus {
        param (
            [PSObject]$Task,
            [string]$Status
        )

        $childrenIds = @()
        if ($Task.PSObject.Properties.Name.Contains($ChildrenField) -and $Task.$ChildrenField) {
            $childrenIds = $Task.$ChildrenField
        }

        if ($childrenIds.Count -eq 0) {
            return $false
        }

        foreach ($childId in $childrenIds) {
            if ($tasksById.ContainsKey($childId)) {
                $child = $tasksById[$childId]
                if ($child.$StatusField -eq $Status) {
                    return $true
                }
            }
        }

        return $false
    }

    # Première passe : propager les statuts des enfants vers les parents
    foreach ($task in $Tasks) {
        # Si la tâche a des enfants
        if ($task.PSObject.Properties.Name.Contains($ChildrenField) -and $task.$ChildrenField -and $task.$ChildrenField.Count -gt 0) {
            # Si tous les enfants sont complétés, le parent peut être complété
            if (Test-AllChildrenStatus -Task $task -Status "Completed") {
                $task.$StatusField = "Completed"
            }
            # Si au moins un enfant est en cours, le parent doit être au moins en cours
            elseif (Test-AnyChildStatus -Task $task -Status "InProgress") {
                if ($task.$StatusField -eq "NotStarted") {
                    $task.$StatusField = "InProgress"
                }
            }
            # Si au moins un enfant est bloqué, le parent peut être bloqué
            elseif (Test-AnyChildStatus -Task $task -Status "Blocked") {
                if ($task.$StatusField -ne "Completed") {
                    $task.$StatusField = "Blocked"
                }
            }
        }
    }

    # Deuxième passe : propager les statuts des parents vers les enfants
    foreach ($task in $Tasks) {
        # Si la tâche a un parent
        if ($task.PSObject.Properties.Name.Contains($ParentIdField) -and $task.$ParentIdField) {
            $parentId = $task.$ParentIdField
            if ($tasksById.ContainsKey($parentId)) {
                $parent = $tasksById[$parentId]
                
                # Si le parent est complété, tous les enfants doivent être complétés
                if ($parent.$StatusField -eq "Completed") {
                    $task.$StatusField = "Completed"
                }
                # Si le parent n'est pas commencé, les enfants ne peuvent pas être en cours ou complétés
                elseif ($parent.$StatusField -eq "NotStarted") {
                    if ($task.$StatusField -eq "InProgress" -or $task.$StatusField -eq "Completed") {
                        $task.$StatusField = "NotStarted"
                    }
                }
            }
        }
    }

    return $Tasks
}

# Fonction pour générer des statuts cohérents pour une tâche et ses sous-tâches
function New-TaskStatusWithSubtasks {
    <#
    .SYNOPSIS
        Génère des statuts cohérents pour une tâche et ses sous-tâches.

    .DESCRIPTION
        Cette fonction génère des statuts cohérents pour une tâche et ses sous-tâches,
        en tenant compte des règles de cohérence hiérarchique.

    .PARAMETER ParentStatus
        Le statut de la tâche parent.

    .PARAMETER SubtaskCount
        Le nombre de sous-tâches à générer.

    .PARAMETER Weights
        Les pondérations pour chaque statut. Plus la pondération est élevée, plus le statut
        a de chances d'être sélectionné.
        Format: @{
            "NotStarted" = 40
            "InProgress" = 30
            "Completed" = 25
            "Blocked" = 5
        }

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des statuts identiques à chaque exécution avec la même graine.

    .EXAMPLE
        New-TaskStatusWithSubtasks -ParentStatus "InProgress" -SubtaskCount 5
        Génère des statuts cohérents pour une tâche en cours et 5 sous-tâches.

    .OUTPUTS
        System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$ParentStatus,

        [Parameter(Mandatory = $true)]
        [int]$SubtaskCount,

        [Parameter(Mandatory = $false)]
        [hashtable]$Weights = @{
            "NotStarted" = 40
            "InProgress" = 30
            "Completed" = 25
            "Blocked" = 5
        },

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    }
    else {
        $random = New-Object System.Random
    }

    # Générer les statuts des sous-tâches en fonction du statut parent
    $subtaskStatuses = @()

    if ($ParentStatus -eq "Completed") {
        # Si le parent est complété, toutes les sous-tâches doivent être complétées
        for ($i = 0; $i -lt $SubtaskCount; $i++) {
            $subtaskStatuses += "Completed"
        }
    }
    elseif ($ParentStatus -eq "NotStarted") {
        # Si le parent n'est pas commencé, les sous-tâches ne peuvent pas être en cours ou complétées
        for ($i = 0; $i -lt $SubtaskCount; $i++) {
            $excludeStatuses = @("InProgress", "Completed")
            $subtaskStatuses += Get-RandomTaskStatus -Weights $Weights -ExcludeStatuses $excludeStatuses -RandomSeed ($RandomSeed + $i)
        }
    }
    elseif ($ParentStatus -eq "Blocked") {
        # Si le parent est bloqué, certaines sous-tâches doivent être bloquées
        $blockedCount = [Math]::Max(1, [Math]::Round($SubtaskCount * 0.7))  # Au moins 70% des sous-tâches doivent être bloquées
        
        for ($i = 0; $i -lt $SubtaskCount; $i++) {
            if ($i -lt $blockedCount) {
                $subtaskStatuses += "Blocked"
            }
            else {
                $excludeStatuses = @("Completed")
                $subtaskStatuses += Get-RandomTaskStatus -Weights $Weights -ExcludeStatuses $excludeStatuses -RandomSeed ($RandomSeed + $i)
            }
        }
        
        # Mélanger les statuts pour éviter que tous les bloqués soient au début
        $subtaskStatuses = $subtaskStatuses | Sort-Object { $random.Next() }
    }
    elseif ($ParentStatus -eq "InProgress") {
        # Si le parent est en cours, au moins une sous-tâche doit être en cours ou complétée
        $inProgressOrCompletedCount = [Math]::Max(1, [Math]::Round($SubtaskCount * 0.5))  # Au moins 50% des sous-tâches doivent être en cours ou complétées
        
        for ($i = 0; $i -lt $SubtaskCount; $i++) {
            if ($i -lt $inProgressOrCompletedCount) {
                $status = if ($random.Next(0, 2) -eq 0) { "InProgress" } else { "Completed" }
                $subtaskStatuses += $status
            }
            else {
                $subtaskStatuses += Get-RandomTaskStatus -Weights $Weights -RandomSeed ($RandomSeed + $i)
            }
        }
        
        # Mélanger les statuts
        $subtaskStatuses = $subtaskStatuses | Sort-Object { $random.Next() }
    }

    return @{
        ParentStatus = $ParentStatus
        SubtaskStatuses = $subtaskStatuses
    }
}
