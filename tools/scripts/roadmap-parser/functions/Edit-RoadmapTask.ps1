<#
.SYNOPSIS
    Modifie une tâche dans une roadmap.

.DESCRIPTION
    La fonction Edit-RoadmapTask permet de modifier une tâche dans une roadmap.
    Elle peut modifier le titre, le statut, les métadonnées, etc.

.PARAMETER Roadmap
    L'objet roadmap contenant la tâche à modifier.

.PARAMETER TaskId
    L'identifiant de la tâche à modifier.

.PARAMETER Title
    Le nouveau titre de la tâche.

.PARAMETER Status
    Le nouveau statut de la tâche. Valeurs possibles : "Complete", "Incomplete", "InProgress", "Blocked".

.PARAMETER Metadata
    Les nouvelles métadonnées de la tâche.

.PARAMETER AddDependency
    L'identifiant d'une tâche dont la tâche à modifier dépendra.

.PARAMETER RemoveDependency
    L'identifiant d'une tâche dont la dépendance doit être supprimée.

.PARAMETER PassThru
    Indique si la roadmap modifiée doit être retournée.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.1" -Title "Nouveau titre" -Status "Complete"
    Modifie le titre et le statut de la tâche 1.1.

.OUTPUTS
    [PSCustomObject] Représentant la roadmap modifiée si PassThru est spécifié.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function Edit-RoadmapTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Roadmap,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TaskId,

        [Parameter(Mandatory = $false)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Complete", "Incomplete", "InProgress", "Blocked")]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata,

        [Parameter(Mandatory = $false)]
        [string]$AddDependency,

        [Parameter(Mandatory = $false)]
        [string]$RemoveDependency,

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    # Vérifier si la tâche existe
    if (-not $Roadmap.AllTasks.ContainsKey($TaskId)) {
        throw "La tâche '$TaskId' n'existe pas dans la roadmap."
    }

    $task = $Roadmap.AllTasks[$TaskId]

    # Modifier le titre si spécifié
    if (-not [string]::IsNullOrEmpty($Title)) {
        $task.Title = $Title
    }

    # Modifier le statut si spécifié
    if (-not [string]::IsNullOrEmpty($Status)) {
        $task.Status = $Status
    }

    # Modifier les métadonnées si spécifiées
    if ($null -ne $Metadata) {
        foreach ($key in $Metadata.Keys) {
            $task.Metadata[$key] = $Metadata[$key]
        }
    }

    # Ajouter une dépendance si spécifiée
    if (-not [string]::IsNullOrEmpty($AddDependency)) {
        if (-not $Roadmap.AllTasks.ContainsKey($AddDependency)) {
            throw "La tâche dépendante '$AddDependency' n'existe pas dans la roadmap."
        }

        $dependency = $Roadmap.AllTasks[$AddDependency]

        # Vérifier si la dépendance existe déjà
        $dependencyExists = $false
        foreach ($dep in $task.Dependencies) {
            if ($dep.Id -eq $AddDependency) {
                $dependencyExists = $true
                break
            }
        }

        if (-not $dependencyExists) {
            $task.Dependencies.Add($dependency) | Out-Null
            $dependency.DependentTasks.Add($task) | Out-Null

            # Ajouter aux métadonnées si elles existent
            if ($task.Metadata.ContainsKey("DependsOn")) {
                if (-not $task.Metadata["DependsOn"].Contains($AddDependency)) {
                    $task.Metadata["DependsOn"] += $AddDependency
                }
            } else {
                $task.Metadata["DependsOn"] = @($AddDependency)
            }
        }
    }

    # Supprimer une dépendance si spécifiée
    if (-not [string]::IsNullOrEmpty($RemoveDependency)) {
        # Trouver la dépendance à supprimer
        $dependencyToRemove = $null
        foreach ($dep in $task.Dependencies) {
            if ($dep.Id -eq $RemoveDependency) {
                $dependencyToRemove = $dep
                break
            }
        }

        if ($null -ne $dependencyToRemove) {
            # Supprimer la dépendance de la liste des dépendances de la tâche
            $newDependencies = [System.Collections.ArrayList]::new()
            foreach ($dep in $task.Dependencies) {
                if ($dep.Id -ne $RemoveDependency) {
                    $newDependencies.Add($dep) | Out-Null
                }
            }
            $task.Dependencies = $newDependencies

            # Supprimer la tâche de la liste des tâches dépendantes de la dépendance
            $dependencyTask = $Roadmap.AllTasks[$RemoveDependency]
            $newDependentTasks = [System.Collections.ArrayList]::new()
            foreach ($depTask in $dependencyTask.DependentTasks) {
                if ($depTask.Id -ne $TaskId) {
                    $newDependentTasks.Add($depTask) | Out-Null
                }
            }
            $dependencyTask.DependentTasks = $newDependentTasks

            # Supprimer des métadonnées si elles existent
            if ($task.Metadata.ContainsKey("DependsOn")) {
                $newDependsOn = [System.Collections.ArrayList]::new()
                foreach ($depId in $task.Metadata["DependsOn"]) {
                    if ($depId -ne $RemoveDependency) {
                        $newDependsOn.Add($depId) | Out-Null
                    }
                }

                if ($newDependsOn.Count -gt 0) {
                    $task.Metadata["DependsOn"] = $newDependsOn
                } else {
                    $task.Metadata.Remove("DependsOn")
                }
            }
        }
    }

    # Retourner la roadmap si PassThru est spécifié
    if ($PassThru) {
        return $Roadmap
    }
}
