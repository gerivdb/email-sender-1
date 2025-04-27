<#
.SYNOPSIS
    SÃ©lectionne des tÃ¢ches dans une roadmap selon diffÃ©rents critÃ¨res.

.DESCRIPTION
    La fonction Select-RoadmapTask permet de sÃ©lectionner des tÃ¢ches dans une roadmap
    selon diffÃ©rents critÃ¨res comme le statut, l'identifiant, le titre, les mÃ©tadonnÃ©es, etc.
    Elle retourne un tableau de tÃ¢ches correspondant aux critÃ¨res spÃ©cifiÃ©s.

.PARAMETER Roadmap
    L'objet roadmap contenant les tÃ¢ches Ã  sÃ©lectionner.

.PARAMETER Id
    L'identifiant ou le modÃ¨le d'identifiant des tÃ¢ches Ã  sÃ©lectionner.
    Accepte les caractÃ¨res gÃ©nÃ©riques (* et ?).

.PARAMETER Title
    Le titre ou le modÃ¨le de titre des tÃ¢ches Ã  sÃ©lectionner.
    Accepte les caractÃ¨res gÃ©nÃ©riques (* et ?).

.PARAMETER Status
    Le statut des tÃ¢ches Ã  sÃ©lectionner.
    Valeurs possibles : "Complete", "Incomplete", "InProgress", "Blocked", "All".

.PARAMETER Level
    Le niveau hiÃ©rarchique des tÃ¢ches Ã  sÃ©lectionner.
    0 = tÃ¢ches de premier niveau, 1 = sous-tÃ¢ches, etc.

.PARAMETER HasDependencies
    Indique si les tÃ¢ches sÃ©lectionnÃ©es doivent avoir des dÃ©pendances.

.PARAMETER HasDependentTasks
    Indique si les tÃ¢ches sÃ©lectionnÃ©es doivent avoir des tÃ¢ches dÃ©pendantes.

.PARAMETER HasMetadata
    Indique si les tÃ¢ches sÃ©lectionnÃ©es doivent avoir des mÃ©tadonnÃ©es.

.PARAMETER MetadataKey
    La clÃ© de mÃ©tadonnÃ©e que les tÃ¢ches sÃ©lectionnÃ©es doivent avoir.

.PARAMETER MetadataValue
    La valeur de mÃ©tadonnÃ©e que les tÃ¢ches sÃ©lectionnÃ©es doivent avoir.

.PARAMETER SectionTitle
    Le titre ou le modÃ¨le de titre des sections dans lesquelles rechercher les tÃ¢ches.
    Accepte les caractÃ¨res gÃ©nÃ©riques (* et ?).

.PARAMETER IncludeSubTasks
    Indique si les sous-tÃ¢ches des tÃ¢ches correspondantes doivent Ãªtre incluses dans les rÃ©sultats.

.PARAMETER Flatten
    Indique si les rÃ©sultats doivent Ãªtre aplatis (liste plate de tÃ¢ches sans hiÃ©rarchie).

.PARAMETER First
    Nombre de tÃ¢ches Ã  retourner (prend les premiÃ¨res tÃ¢ches correspondantes).

.PARAMETER Last
    Nombre de tÃ¢ches Ã  retourner (prend les derniÃ¨res tÃ¢ches correspondantes).

.PARAMETER Skip
    Nombre de tÃ¢ches Ã  ignorer avant de commencer Ã  retourner des rÃ©sultats.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Select-RoadmapTask -Roadmap $roadmap -Status "Complete"
    SÃ©lectionne toutes les tÃ¢ches complÃ©tÃ©es dans la roadmap.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Select-RoadmapTask -Roadmap $roadmap -Id "1.*" -Status "Incomplete" -HasDependencies
    SÃ©lectionne toutes les tÃ¢ches incomplÃ¨tes dont l'identifiant commence par "1." et qui ont des dÃ©pendances.

.OUTPUTS
    [PSCustomObject[]] Tableau de tÃ¢ches correspondant aux critÃ¨res spÃ©cifiÃ©s.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
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

    # VÃ©rifier si la roadmap contient des tÃ¢ches
    if (-not $Roadmap.AllTasks -or $Roadmap.AllTasks.Count -eq 0) {
        Write-Warning "La roadmap ne contient pas de tÃ¢ches."
        return @()
    }

    # Fonction rÃ©cursive pour filtrer les tÃ¢ches
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

            # Filtrer par prÃ©sence de dÃ©pendances
            if ($HasDependencies) {
                if (-not $task.Dependencies -or $task.Dependencies.Count -eq 0) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par prÃ©sence de tÃ¢ches dÃ©pendantes
            if ($HasDependentTasks) {
                if (-not $task.DependentTasks -or $task.DependentTasks.Count -eq 0) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par prÃ©sence de mÃ©tadonnÃ©es
            if ($HasMetadata) {
                if (-not $task.Metadata -or $task.Metadata.Count -eq 0) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par clÃ© de mÃ©tadonnÃ©e
            if (-not [string]::IsNullOrEmpty($MetadataKey)) {
                if (-not $task.Metadata -or -not $task.Metadata.ContainsKey($MetadataKey)) {
                    $matchesFilter = $false
                }
            }

            # Filtrer par valeur de mÃ©tadonnÃ©e
            if (-not [string]::IsNullOrEmpty($MetadataValue)) {
                if (-not $task.Metadata -or -not $task.Metadata.Values.Contains($MetadataValue)) {
                    $matchesFilter = $false
                }
            }

            # Ajouter la tÃ¢che si elle correspond aux critÃ¨res
            if ($matchesFilter) {
                $filteredTasks.Add($task) | Out-Null
            }

            # Traiter les sous-tÃ¢ches si demandÃ©
            if ($ProcessSubTasks -and $task.SubTasks.Count -gt 0) {
                $subTasksToProcess = $true

                # Si la tÃ¢che correspond aux critÃ¨res et qu'on veut inclure les sous-tÃ¢ches,
                # on ajoute toutes les sous-tÃ¢ches sans filtrage
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

                # Sinon, on filtre les sous-tÃ¢ches normalement
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

    # Filtrer les tÃ¢ches par section
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

    # Filtrer les tÃ¢ches selon les critÃ¨res
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

    # Remplacer la liste filtrÃ©e par le tableau filtrÃ©
    $filteredTasks = $filteredTasksArray

    # Aplatir les rÃ©sultats si demandÃ©
    if ($Flatten) {
        return $filteredTasks
    } else {
        # Reconstruire la hiÃ©rarchie
        $result = [System.Collections.ArrayList]::new()
        $processedIds = [System.Collections.Generic.HashSet[string]]::new()

        foreach ($task in $filteredTasks) {
            # Ne traiter que les tÃ¢ches qui n'ont pas dÃ©jÃ  Ã©tÃ© ajoutÃ©es
            if (-not $processedIds.Contains($task.Id)) {
                $processedIds.Add($task.Id) | Out-Null

                # CrÃ©er une copie de la tÃ¢che avec ses sous-tÃ¢ches
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

                # Ajouter les sous-tÃ¢ches qui sont dans les rÃ©sultats filtrÃ©s
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
