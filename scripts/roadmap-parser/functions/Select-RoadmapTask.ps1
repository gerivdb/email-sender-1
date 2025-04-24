<#
.SYNOPSIS
    Sélectionne des tâches dans une roadmap selon différents critères.

.DESCRIPTION
    La fonction Select-RoadmapTask permet de sélectionner des tâches dans une roadmap
    selon différents critères comme le statut, l'identifiant, le titre, les métadonnées, etc.
    Elle retourne un tableau de tâches correspondant aux critères spécifiés.

.PARAMETER Roadmap
    L'objet roadmap contenant les tâches à sélectionner.

.PARAMETER Id
    L'identifiant ou le modèle d'identifiant des tâches à sélectionner.
    Accepte les caractères génériques (* et ?).

.PARAMETER Title
    Le titre ou le modèle de titre des tâches à sélectionner.
    Accepte les caractères génériques (* et ?).

.PARAMETER Status
    Le statut des tâches à sélectionner.
    Valeurs possibles : "Complete", "Incomplete", "InProgress", "Blocked", "All".

.PARAMETER Level
    Le niveau hiérarchique des tâches à sélectionner.
    0 = tâches de premier niveau, 1 = sous-tâches, etc.

.PARAMETER HasDependencies
    Indique si les tâches sélectionnées doivent avoir des dépendances.

.PARAMETER HasDependentTasks
    Indique si les tâches sélectionnées doivent avoir des tâches dépendantes.

.PARAMETER HasMetadata
    Indique si les tâches sélectionnées doivent avoir des métadonnées.

.PARAMETER MetadataKey
    La clé de métadonnée que les tâches sélectionnées doivent avoir.

.PARAMETER MetadataValue
    La valeur de métadonnée que les tâches sélectionnées doivent avoir.

.PARAMETER SectionTitle
    Le titre ou le modèle de titre des sections dans lesquelles rechercher les tâches.
    Accepte les caractères génériques (* et ?).

.PARAMETER IncludeSubTasks
    Indique si les sous-tâches des tâches correspondantes doivent être incluses dans les résultats.

.PARAMETER Flatten
    Indique si les résultats doivent être aplatis (liste plate de tâches sans hiérarchie).

.PARAMETER First
    Nombre de tâches à retourner (prend les premières tâches correspondantes).

.PARAMETER Last
    Nombre de tâches à retourner (prend les dernières tâches correspondantes).

.PARAMETER Skip
    Nombre de tâches à ignorer avant de commencer à retourner des résultats.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Select-RoadmapTask -Roadmap $roadmap -Status "Complete"
    Sélectionne toutes les tâches complétées dans la roadmap.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Select-RoadmapTask -Roadmap $roadmap -Id "1.*" -Status "Incomplete" -HasDependencies
    Sélectionne toutes les tâches incomplètes dont l'identifiant commence par "1." et qui ont des dépendances.

.OUTPUTS
    [PSCustomObject[]] Tableau de tâches correspondant aux critères spécifiés.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function Select-RoadmapTask {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Roadmap,

        [Parameter(Mandatory = $false)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [string]$Title,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Complete", "Incomplete", "InProgress", "Blocked", "All")]
        [string]$Status = "All",

        [Parameter(Mandatory = $false)]
        [int]$Level = -1,

        [Parameter(Mandatory = $false)]
        [switch]$HasDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$HasDependentTasks,

        [Parameter(Mandatory = $false)]
        [switch]$HasMetadata,

        [Parameter(Mandatory = $false)]
        [string]$MetadataKey,

        [Parameter(Mandatory = $false)]
        [string]$MetadataValue,

        [Parameter(Mandatory = $false)]
        [string]$SectionTitle,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubTasks,

        [Parameter(Mandatory = $false)]
        [switch]$Flatten,

        [Parameter(Mandatory = $false, ParameterSetName = "First")]
        [int]$First,

        [Parameter(Mandatory = $false, ParameterSetName = "Last")]
        [int]$Last,

        [Parameter(Mandatory = $false)]
        [int]$Skip = 0
    )

    # Vérifier si la roadmap contient des tâches
    if (-not $Roadmap.AllTasks -or $Roadmap.AllTasks.Count -eq 0) {
        Write-Warning "La roadmap ne contient pas de tâches."
        return @()
    }

    # Fonction récursive pour filtrer les tâches
    function Filter-Tasks {
        param (
            [PSCustomObject[]]$Tasks,
            [bool]$ProcessSubTasks = $true
        )

        $filteredTasks = [System.Collections.ArrayList]::new()

        foreach ($task in $Tasks) {
            $matchesFilter = $true

            # Filtrer par ID
            if (-not [string]::IsNullOrEmpty($Id)) {
                if (-not ($task.Id -like $Id)) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par titre
            if (-not [string]::IsNullOrEmpty($Title)) {
                if (-not ($task.Title -like $Title)) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par statut
            if ($Status -ne "All") {
                if ($task.Status -ne $Status) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par niveau
            if ($Level -ge 0) {
                if ($task.Level -ne $Level) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par présence de dépendances
            if ($HasDependencies) {
                if (-not $task.Dependencies -or $task.Dependencies.Count -eq 0) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par présence de tâches dépendantes
            if ($HasDependentTasks) {
                if (-not $task.DependentTasks -or $task.DependentTasks.Count -eq 0) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par présence de métadonnées
            if ($HasMetadata) {
                if (-not $task.Metadata -or $task.Metadata.Count -eq 0) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par clé de métadonnée
            if (-not [string]::IsNullOrEmpty($MetadataKey)) {
                if (-not $task.Metadata -or -not $task.Metadata.ContainsKey($MetadataKey)) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par valeur de métadonnée
            if (-not [string]::IsNullOrEmpty($MetadataValue)) {
                if (-not $task.Metadata -or -not $task.Metadata.Values.Contains($MetadataValue)) {
                    $matchesFilter = $false
                }
            }

            # Ajouter la tâche si elle correspond aux critères
            if ($matchesFilter) {
                $filteredTasks.Add($task) | Out-Null
            }

            # Traiter les sous-tâches si demandé
            if ($ProcessSubTasks -and $task.SubTasks.Count -gt 0) {
                $subTasksToProcess = $true

                # Si la tâche correspond aux critères et qu'on veut inclure les sous-tâches,
                # on ajoute toutes les sous-tâches sans filtrage
                if ($matchesFilter -and $IncludeSubTasks) {
                    $subTasksToProcess = $false

                    function Add-AllSubTasks {
                        param (
                            [PSCustomObject]$ParentTask,
                            [System.Collections.ArrayList]$ResultList
                        )

                        foreach ($subTask in $ParentTask.SubTasks) {
                            $ResultList.Add($subTask) | Out-Null
                            Add-AllSubTasks -ParentTask $subTask -ResultList $ResultList
                        }
                    }

                    Add-AllSubTasks -ParentTask $task -ResultList $filteredTasks
                }

                # Sinon, on filtre les sous-tâches normalement
                if ($subTasksToProcess) {
                    $subTaskResults = Filter-Tasks -Tasks $task.SubTasks -ProcessSubTasks $true
                    if ($null -ne $subTaskResults -and $subTaskResults.Count -gt 0) {
                        foreach ($subTask in $subTaskResults) {
                            $filteredTasks.Add($subTask) | Out-Null
                        }
                    }
                }
            }
        }

        return $filteredTasks
    }

    # Filtrer les tâches par section
    $tasksToProcess = [System.Collections.ArrayList]::new()

    foreach ($section in $Roadmap.Sections) {
        # Filtrer par titre de section
        if (-not [string]::IsNullOrEmpty($SectionTitle)) {
            if (-not ($section.Title -like $SectionTitle)) {
                continue
            }
        }

        $tasksToProcess.AddRange($section.Tasks)
    }

    # Filtrer les tâches selon les critères
    $filteredTasks = Filter-Tasks -Tasks $tasksToProcess

    # Convertir en tableau pour pouvoir utiliser Select-Object
    $filteredTasksArray = @($filteredTasks)

    # Appliquer Skip, First ou Last
    if ($Skip -gt 0) {
        $filteredTasksArray = $filteredTasksArray | Select-Object -Skip $Skip
    }

    if ($PSCmdlet.ParameterSetName -eq "First" -and $First -gt 0) {
        $filteredTasksArray = $filteredTasksArray | Select-Object -First $First
    } elseif ($PSCmdlet.ParameterSetName -eq "Last" -and $Last -gt 0) {
        $filteredTasksArray = $filteredTasksArray | Select-Object -Last $Last
    }

    # Remplacer la liste filtrée par le tableau filtré
    $filteredTasks = $filteredTasksArray

    # Aplatir les résultats si demandé
    if ($Flatten) {
        return $filteredTasks
    } else {
        # Reconstruire la hiérarchie
        $result = [System.Collections.ArrayList]::new()
        $processedIds = [System.Collections.Generic.HashSet[string]]::new()

        foreach ($task in $filteredTasks) {
            # Ne traiter que les tâches qui n'ont pas déjà été ajoutées
            if (-not $processedIds.Contains($task.Id)) {
                $processedIds.Add($task.Id) | Out-Null

                # Créer une copie de la tâche avec ses sous-tâches
                $taskCopy = [PSCustomObject]@{
                    Id             = $task.Id
                    Title          = $task.Title
                    Status         = $task.Status
                    Level          = $task.Level
                    SubTasks       = [System.Collections.ArrayList]::new()
                    Dependencies   = $task.Dependencies
                    DependentTasks = $task.DependentTasks
                    Metadata       = $task.Metadata
                }

                # Ajouter les sous-tâches qui sont dans les résultats filtrés
                function Add-FilteredSubTasks {
                    param (
                        [PSCustomObject]$OriginalTask,
                        [PSCustomObject]$CopyTask,
                        [System.Collections.Generic.HashSet[string]]$ProcessedIds
                    )

                    foreach ($subTask in $OriginalTask.SubTasks) {
                        if ($filteredTasks.Contains($subTask) -or $IncludeSubTasks) {
                            $ProcessedIds.Add($subTask.Id) | Out-Null

                            $subTaskCopy = [PSCustomObject]@{
                                Id             = $subTask.Id
                                Title          = $subTask.Title
                                Status         = $subTask.Status
                                Level          = $subTask.Level
                                SubTasks       = [System.Collections.ArrayList]::new()
                                Dependencies   = $subTask.Dependencies
                                DependentTasks = $subTask.DependentTasks
                                Metadata       = $subTask.Metadata
                            }

                            $CopyTask.SubTasks.Add($subTaskCopy) | Out-Null

                            Add-FilteredSubTasks -OriginalTask $subTask -CopyTask $subTaskCopy -ProcessedIds $ProcessedIds
                        }
                    }
                }

                Add-FilteredSubTasks -OriginalTask $task -CopyTask $taskCopy -ProcessedIds $processedIds

                $result.Add($taskCopy) | Out-Null
            }
        }

        return $result
    }
}
