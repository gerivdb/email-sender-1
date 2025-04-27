<#
.SYNOPSIS
    Analyse et gÃ¨re les dÃ©pendances entre les tÃ¢ches d'une roadmap.

.DESCRIPTION
    La fonction Get-RoadmapDependencies analyse une roadmap pour dÃ©tecter et gÃ©rer les dÃ©pendances entre les tÃ¢ches.
    Elle peut dÃ©tecter les dÃ©pendances explicites (via mÃ©tadonnÃ©es) et implicites (via rÃ©fÃ©rences dans le titre),
    valider la cohÃ©rence des dÃ©pendances, dÃ©tecter les cycles, et gÃ©nÃ©rer des visualisations des dÃ©pendances.

.PARAMETER Roadmap
    L'objet roadmap Ã  analyser.

.PARAMETER DetectionMode
    Mode de dÃ©tection des dÃ©pendances. Valeurs possibles : "Explicit", "Implicit", "All". Par dÃ©faut, "All".

.PARAMETER ValidateDependencies
    Indique si les dÃ©pendances doivent Ãªtre validÃ©es.

.PARAMETER DetectCycles
    Indique si les cycles de dÃ©pendances doivent Ãªtre dÃ©tectÃ©s.

.PARAMETER GenerateVisualization
    Indique si une visualisation des dÃ©pendances doit Ãªtre gÃ©nÃ©rÃ©e.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour la visualisation des dÃ©pendances.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md"
    Get-RoadmapDependencies -Roadmap $roadmap -DetectCycles -GenerateVisualization -OutputPath ".\dependencies.md"
    Analyse les dÃ©pendances de la roadmap, dÃ©tecte les cycles et gÃ©nÃ¨re une visualisation.

.OUTPUTS
    [PSCustomObject] ReprÃ©sentant les dÃ©pendances de la roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
#>
function Get-RoadmapDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Roadmap,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Explicit", "Implicit", "All")]
        [string]$DetectionMode = "All",

        [Parameter(Mandatory = $false)]
        [switch]$ValidateDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$DetectCycles,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateVisualization,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # CrÃ©er l'objet de rÃ©sultat
    $result = [PSCustomObject]@{
        DependencyCount      = 0
        ExplicitDependencies = [System.Collections.ArrayList]::new()
        ImplicitDependencies = [System.Collections.ArrayList]::new()
        ValidationIssues     = [System.Collections.ArrayList]::new()
        Cycles               = [System.Collections.ArrayList]::new()
        Visualization        = ""
    }

    # VÃ©rifier si la roadmap contient des tÃ¢ches
    if (-not $Roadmap.AllTasks -or $Roadmap.AllTasks.Count -eq 0) {
        $result.ValidationIssues.Add("La roadmap ne contient pas de tÃ¢ches.") | Out-Null
        return $result
    }

    # RÃ©initialiser les dÃ©pendances existantes
    foreach ($id in $Roadmap.AllTasks.Keys) {
        $task = $Roadmap.AllTasks[$id]
        $task.Dependencies = [System.Collections.ArrayList]::new()
        $task.DependentTasks = [System.Collections.ArrayList]::new()
    }

    # DÃ©tecter les dÃ©pendances explicites (via mÃ©tadonnÃ©es)
    if ($DetectionMode -eq "Explicit" -or $DetectionMode -eq "All") {
        foreach ($id in $Roadmap.AllTasks.Keys) {
            $task = $Roadmap.AllTasks[$id]
            if ($task.Metadata.ContainsKey("DependsOn")) {
                foreach ($dependencyId in $task.Metadata["DependsOn"]) {
                    if ($Roadmap.AllTasks.ContainsKey($dependencyId)) {
                        $dependency = $Roadmap.AllTasks[$dependencyId]
                        $task.Dependencies.Add($dependency) | Out-Null
                        $dependency.DependentTasks.Add($task) | Out-Null

                        $result.ExplicitDependencies.Add([PSCustomObject]@{
                                TaskId    = $task.Id
                                DependsOn = $dependencyId
                            }) | Out-Null
                    } elseif ($ValidateDependencies) {
                        $result.ValidationIssues.Add("La tÃ¢che $id dÃ©pend de la tÃ¢che inexistante $dependencyId.") | Out-Null
                    }
                }
            }
        }
    }

    # DÃ©tecter les dÃ©pendances implicites (via rÃ©fÃ©rences dans le titre ou la description)
    if ($DetectionMode -eq "Implicit" -or $DetectionMode -eq "All") {
        $refRegex = [regex]::new('\bref:([a-zA-Z0-9_.-]+)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)

        foreach ($id in $Roadmap.AllTasks.Keys) {
            $task = $Roadmap.AllTasks[$id]

            # Chercher les rÃ©fÃ©rences dans le titre
            $titleMatches = $refRegex.Matches($task.Title)
            foreach ($match in $titleMatches) {
                $refId = $match.Groups[1].Value
                if ($Roadmap.AllTasks.ContainsKey($refId) -and $refId -ne $id) {
                    $dependency = $Roadmap.AllTasks[$refId]
                    if (-not $task.Dependencies.Contains($dependency)) {
                        $task.Dependencies.Add($dependency) | Out-Null
                        $dependency.DependentTasks.Add($task) | Out-Null

                        $result.ImplicitDependencies.Add([PSCustomObject]@{
                                TaskId    = $task.Id
                                DependsOn = $refId
                                Source    = "Title"
                            }) | Out-Null
                    }
                } elseif ($ValidateDependencies -and $refId -ne $id) {
                    $result.ValidationIssues.Add("La tÃ¢che $id fait rÃ©fÃ©rence Ã  la tÃ¢che inexistante $refId.") | Out-Null
                }
            }

            # Chercher les rÃ©fÃ©rences dans la description (si elle existe)
            if ($task.PSObject.Properties.Name -contains "Description" -and -not [string]::IsNullOrEmpty($task.Description)) {
                $descMatches = $refRegex.Matches($task.Description)
                foreach ($match in $descMatches) {
                    $refId = $match.Groups[1].Value
                    if ($Roadmap.AllTasks.ContainsKey($refId) -and $refId -ne $id) {
                        $dependency = $Roadmap.AllTasks[$refId]
                        if (-not $task.Dependencies.Contains($dependency)) {
                            $task.Dependencies.Add($dependency) | Out-Null
                            $dependency.DependentTasks.Add($task) | Out-Null

                            $result.ImplicitDependencies.Add([PSCustomObject]@{
                                    TaskId    = $task.Id
                                    DependsOn = $refId
                                    Source    = "Description"
                                }) | Out-Null
                        }
                    } elseif ($ValidateDependencies -and $refId -ne $id) {
                        $result.ValidationIssues.Add("La tÃ¢che $id fait rÃ©fÃ©rence Ã  la tÃ¢che inexistante $refId dans sa description.") | Out-Null
                    }
                }
            }

            # DÃ©tecter les dÃ©pendances basÃ©es sur les identifiants hiÃ©rarchiques
            if ($id -match '^(.+)\.\d+$') {
                $parentId = $matches[1]
                if ($Roadmap.AllTasks.ContainsKey($parentId) -and $parentId -ne $id) {
                    $dependency = $Roadmap.AllTasks[$parentId]
                    if (-not $task.Dependencies.Contains($dependency)) {
                        $task.Dependencies.Add($dependency) | Out-Null
                        $dependency.DependentTasks.Add($task) | Out-Null

                        $result.ImplicitDependencies.Add([PSCustomObject]@{
                                TaskId    = $task.Id
                                DependsOn = $parentId
                                Source    = "Hierarchy"
                            }) | Out-Null
                    }
                }
            }
        }
    }

    # Calculer le nombre total de dÃ©pendances
    $result.DependencyCount = $result.ExplicitDependencies.Count + $result.ImplicitDependencies.Count

    # DÃ©tecter les cycles de dÃ©pendances si demandÃ©
    if ($DetectCycles) {
        function Find-DependencyCycle {
            param (
                [PSCustomObject]$Task,
                [System.Collections.Generic.HashSet[string]]$VisitedTasks = (New-Object System.Collections.Generic.HashSet[string]),
                [System.Collections.Generic.Stack[string]]$Path = (New-Object System.Collections.Generic.Stack[string])
            )

            if ($VisitedTasks.Contains($Task.Id)) {
                if ($Path.Contains($Task.Id)) {
                    # Cycle dÃ©tectÃ©
                    $cycle = @()
                    $found = $false

                    foreach ($node in $Path) {
                        if ($node -eq $Task.Id) {
                            $found = $true
                        }

                        if ($found) {
                            $cycle += $node
                        }
                    }

                    $cycle += $Task.Id
                    return $cycle
                }

                return $null
            }

            $VisitedTasks.Add($Task.Id) | Out-Null
            $Path.Push($Task.Id)

            foreach ($dependency in $Task.Dependencies) {
                $cycle = Find-DependencyCycle -Task $dependency -VisitedTasks $VisitedTasks -Path $Path
                if ($null -ne $cycle) {
                    return $cycle
                }
            }

            $Path.Pop() | Out-Null
            return $null
        }

        foreach ($id in $Roadmap.AllTasks.Keys) {
            $task = $Roadmap.AllTasks[$id]
            $cycle = Find-DependencyCycle -Task $task

            if ($null -ne $cycle -and $cycle.Count -gt 0) {
                $cycleStr = $cycle -join " -> "

                # VÃ©rifier si ce cycle a dÃ©jÃ  Ã©tÃ© dÃ©tectÃ©
                $cycleExists = $false
                foreach ($existingCycle in $result.Cycles) {
                    if ($existingCycle.CycleString -eq $cycleStr) {
                        $cycleExists = $true
                        break
                    }
                }

                if (-not $cycleExists) {
                    $result.Cycles.Add([PSCustomObject]@{
                            Nodes       = $cycle
                            CycleString = $cycleStr
                        }) | Out-Null

                    $result.ValidationIssues.Add("Cycle de dÃ©pendances dÃ©tectÃ©: $cycleStr") | Out-Null
                }
            }
        }
    }

    # GÃ©nÃ©rer une visualisation des dÃ©pendances si demandÃ©
    if ($GenerateVisualization) {
        $sb = [System.Text.StringBuilder]::new()

        $sb.AppendLine("```mermaid") | Out-Null
        $sb.AppendLine("graph TD") | Out-Null

        # Ajouter les nÅ“uds
        foreach ($id in $Roadmap.AllTasks.Keys) {
            $task = $Roadmap.AllTasks[$id]
            $status = $task.Status.ToString()
            $sb.AppendLine("    $($task.Id)[$($task.Id): $($task.Title)]:::$status") | Out-Null
        }

        # Ajouter les relations de dÃ©pendance
        foreach ($id in $Roadmap.AllTasks.Keys) {
            $task = $Roadmap.AllTasks[$id]
            foreach ($dependency in $task.Dependencies) {
                $sb.AppendLine("    $($dependency.Id) --> $($task.Id)") | Out-Null
            }
        }

        # Ajouter les styles
        $sb.AppendLine("    classDef Complete fill:#9f9,stroke:#6c6") | Out-Null
        $sb.AppendLine("    classDef InProgress fill:#ff9,stroke:#cc6") | Out-Null
        $sb.AppendLine("    classDef Blocked fill:#f99,stroke:#c66") | Out-Null
        $sb.AppendLine("    classDef Incomplete fill:#eee,stroke:#999") | Out-Null

        # Mettre en Ã©vidence les cycles
        if ($result.Cycles.Count -gt 0) {
            $sb.AppendLine("    %% Cycles de dÃ©pendances") | Out-Null
            foreach ($cycle in $result.Cycles) {
                for ($i = 0; $i -lt $cycle.Nodes.Count - 1; $i++) {
                    $sb.AppendLine("    $($cycle.Nodes[$i]) --> $($cycle.Nodes[$i+1]):::cycle") | Out-Null
                }
            }
            $sb.AppendLine("    classDef cycle stroke:#f00,stroke-width:2px") | Out-Null
        }

        $sb.AppendLine('```') | Out-Null

        $result.Visualization = $sb.ToString()

        # Ã‰crire la visualisation dans un fichier si demandÃ©
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            $result.Visualization | Out-File -FilePath $OutputPath -Encoding UTF8
        }
    }

    return $result
}
