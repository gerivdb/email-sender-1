<#
.SYNOPSIS
    Modifie une tÃ¢che dans une roadmap.

.DESCRIPTION
    La fonction Edit-RoadmapTask permet de modifier une tÃ¢che dans une roadmap.
    Elle peut modifier le titre, le statut, les mÃ©tadonnÃ©es, etc.

.PARAMETER Roadmap
    L'objet roadmap contenant la tÃ¢che Ã  modifier.

.PARAMETER TaskId
    L'identifiant de la tÃ¢che Ã  modifier.

.PARAMETER Title
    Le nouveau titre de la tÃ¢che.

.PARAMETER Status
    Le nouveau statut de la tÃ¢che. Valeurs possibles : "Complete", "Incomplete", "InProgress", "Blocked".

.PARAMETER Metadata
    Les nouvelles mÃ©tadonnÃ©es de la tÃ¢che.

.PARAMETER AddDependency
    L'identifiant d'une tÃ¢che dont la tÃ¢che Ã  modifier dÃ©pendra.

.PARAMETER RemoveDependency
    L'identifiant d'une tÃ¢che dont la dÃ©pendance doit Ãªtre supprimÃ©e.

.PARAMETER PassThru
    Indique si la roadmap modifiÃ©e doit Ãªtre retournÃ©e.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Edit-RoadmapTask -Roadmap $roadmap -TaskId "1.1" -Title "Nouveau titre" -Status "Complete"
    Modifie le titre et le statut de la tÃ¢che 1.1.

.OUTPUTS
    [PSCustomObject] ReprÃ©sentant la roadmap modifiÃ©e si PassThru est spÃ©cifiÃ©.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
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

    # VÃ©rifier si la tÃ¢che existe
    if (-not $Roadmap.AllTasks.ContainsKey($TaskId)) {
        throw "La tÃ¢che '$TaskId' n'existe pas dans la roadmap."
    }

    $task = $Roadmap.AllTasks[$TaskId]

    # Modifier le titre si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($Title)) {
        $task.Title = $Title
    }

    # Modifier le statut si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($Status)) {
        $task.Status = $Status
    }

    # Modifier les mÃ©tadonnÃ©es si spÃ©cifiÃ©es
    if ($null -ne $Metadata) {
        foreach ($key in $Metadata.Keys) {
            $task.Metadata[$key] = $Metadata[$key]
        }
    }

    # Ajouter une dÃ©pendance si spÃ©cifiÃ©e
    if (-not [string]::IsNullOrEmpty($AddDependency)) {
        if (-not $Roadmap.AllTasks.ContainsKey($AddDependency)) {
            throw "La tÃ¢che dÃ©pendante '$AddDependency' n'existe pas dans la roadmap."
        }

        $dependency = $Roadmap.AllTasks[$AddDependency]

        # VÃ©rifier si la dÃ©pendance existe dÃ©jÃ 
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

            # Ajouter aux mÃ©tadonnÃ©es si elles existent
            if ($task.Metadata.ContainsKey("DependsOn")) {
                if (-not $task.Metadata["DependsOn"].Contains($AddDependency)) {
                    $task.Metadata["DependsOn"] += $AddDependency
                }
            } else {
                $task.Metadata["DependsOn"] = @($AddDependency)
            }
        }
    }

    # Supprimer une dÃ©pendance si spÃ©cifiÃ©e
    if (-not [string]::IsNullOrEmpty($RemoveDependency)) {
        # Trouver la dÃ©pendance Ã  supprimer
        $dependencyToRemove = $null
        foreach ($dep in $task.Dependencies) {
            if ($dep.Id -eq $RemoveDependency) {
                $dependencyToRemove = $dep
                break
            }
        }

        if ($null -ne $dependencyToRemove) {
            # Supprimer la dÃ©pendance de la liste des dÃ©pendances de la tÃ¢che
            $newDependencies = [System.Collections.ArrayList]::new()
            foreach ($dep in $task.Dependencies) {
                if ($dep.Id -ne $RemoveDependency) {
                    $newDependencies.Add($dep) | Out-Null
                }
            }
            $task.Dependencies = $newDependencies

            # Supprimer la tÃ¢che de la liste des tÃ¢ches dÃ©pendantes de la dÃ©pendance
            $dependencyTask = $Roadmap.AllTasks[$RemoveDependency]
            $newDependentTasks = [System.Collections.ArrayList]::new()
            foreach ($depTask in $dependencyTask.DependentTasks) {
                if ($depTask.Id -ne $TaskId) {
                    $newDependentTasks.Add($depTask) | Out-Null
                }
            }
            $dependencyTask.DependentTasks = $newDependentTasks

            # Supprimer des mÃ©tadonnÃ©es si elles existent
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

    # Retourner la roadmap si PassThru est spÃ©cifiÃ©
    if ($PassThru) {
        return $Roadmap
    }
}
