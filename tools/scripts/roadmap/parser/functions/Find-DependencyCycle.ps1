<#
.SYNOPSIS
    DÃ©tecte les cycles de dÃ©pendances dans une roadmap.

.DESCRIPTION
    La fonction Find-DependencyCycle analyse une roadmap pour dÃ©tecter les cycles de dÃ©pendances entre les tÃ¢ches.
    Elle utilise un algorithme de dÃ©tection de cycle dans un graphe orientÃ©.

.PARAMETER Roadmap
    L'objet roadmap Ã  analyser.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour la visualisation des cycles.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Find-DependencyCycle -Roadmap $roadmap -OutputPath ".\cycles.md"
    DÃ©tecte les cycles de dÃ©pendances dans la roadmap et gÃ©nÃ¨re une visualisation.

.OUTPUTS
    [PSCustomObject] ReprÃ©sentant les cycles de dÃ©pendances dÃ©tectÃ©s.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
#>
function Find-DependencyCycle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Roadmap,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # CrÃ©er l'objet de rÃ©sultat
    $result = [PSCustomObject]@{
        Cycles        = [System.Collections.ArrayList]::new()
        Visualization = ""
    }

    # VÃ©rifier si la roadmap contient des tÃ¢ches
    if (-not $Roadmap.AllTasks -or $Roadmap.AllTasks.Count -eq 0) {
        Write-Warning "La roadmap ne contient pas de tÃ¢ches."
        return $result
    }

    # Fonction rÃ©cursive pour dÃ©tecter les cycles
    function Test-CycleInTask {
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
            $cycle = Test-CycleInTask -Task $dependency -VisitedTasks $VisitedTasks -Path $Path
            if ($null -ne $cycle) {
                return $cycle
            }
        }

        $Path.Pop() | Out-Null
        return $null
    }

    # DÃ©tecter les cycles pour chaque tÃ¢che
    foreach ($id in $Roadmap.AllTasks.Keys) {
        $task = $Roadmap.AllTasks[$id]
        $cycle = Test-CycleInTask -Task $task

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
                        StartTaskId = $cycle[0]
                    }) | Out-Null
            }
        }
    }

    # GÃ©nÃ©rer une visualisation des cycles si demandÃ©
    if ($result.Cycles.Count -gt 0) {
        $sb = [System.Text.StringBuilder]::new()

        $sb.AppendLine("# Cycles de dÃ©pendances dÃ©tectÃ©s") | Out-Null
        $sb.AppendLine("") | Out-Null

        $sb.AppendLine("## Liste des cycles") | Out-Null
        $sb.AppendLine("") | Out-Null

        foreach ($cycle in $result.Cycles) {
            $sb.AppendLine("- $($cycle.CycleString)") | Out-Null
        }

        $sb.AppendLine("") | Out-Null
        $sb.AppendLine("## Visualisation") | Out-Null
        $sb.AppendLine("") | Out-Null

        $sb.AppendLine('```mermaid') | Out-Null
        $sb.AppendLine('graph TD') | Out-Null

        # Ajouter les nÅ“uds impliquÃ©s dans les cycles
        $nodesInCycles = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($cycle in $result.Cycles) {
            foreach ($node in $cycle.Nodes) {
                $nodesInCycles.Add($node) | Out-Null
            }
        }

        foreach ($nodeId in $nodesInCycles) {
            if ($Roadmap.AllTasks.ContainsKey($nodeId)) {
                $task = $Roadmap.AllTasks[$nodeId]
                $sb.AppendLine("    $nodeId[$($nodeId): $($task.Title)]") | Out-Null
            } else {
                $sb.AppendLine("    $nodeId[$nodeId]") | Out-Null
            }
        }

        # Ajouter les relations de dÃ©pendance impliquÃ©es dans les cycles
        foreach ($cycle in $result.Cycles) {
            for ($i = 0; $i -lt $cycle.Nodes.Count - 1; $i++) {
                $sb.AppendLine("    $($cycle.Nodes[$i]) --> $($cycle.Nodes[$i+1])") | Out-Null
            }
        }

        # Ajouter des styles pour les nÅ“uds impliquÃ©s dans les cycles
        $sb.AppendLine("    classDef cycleNode fill:#f99,stroke:#f66,stroke-width:2px") | Out-Null

        foreach ($nodeId in $nodesInCycles) {
            $sb.AppendLine("    class $nodeId cycleNode") | Out-Null
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
