# Fonction pour exporter une visualisation DOT des cycles de dÃ©pendances
function Export-CycleVisualizationDOT {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$CycleData,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStatistics
    )

    # VÃ©rifier si les donnÃ©es de cycle sont valides
    if (-not $CycleData.DependencyGraph) {
        Write-Error "Les donnÃ©es de cycle ne contiennent pas de graphe de dÃ©pendances."
        return $null
    }

    # GÃ©nÃ©rer le chemin de sortie par dÃ©faut si non spÃ©cifiÃ©
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputPath = "reports/cycle_visualization_${timestamp}.dot"
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # GÃ©nÃ©rer un fichier DOT pour GraphViz
    $dotContent = "digraph DependencyGraph {`n"
    $dotContent += "    rankdir=LR;`n"
    $dotContent += "    node [shape=box, style=filled, fillcolor=white];`n"
    
    # DÃ©finir les nÅ“uds
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        $isCyclic = $CycleData.HasCycles -and $CycleData.Cycles -contains $script
        $nodeStyle = if ($isCyclic -and $HighlightCycles) { "fillcolor=`"#ffcccc`"" } else { "fillcolor=white" }
        $dotContent += "    `"$script`" [$nodeStyle];`n"
    }
    
    # DÃ©finir les arÃªtes
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        foreach ($dependency in $CycleData.DependencyGraph[$script]) {
            $isCyclicEdge = $CycleData.HasCycles -and $CycleData.Cycles -contains $script -and $CycleData.Cycles -contains $dependency
            $edgeStyle = if ($isCyclicEdge -and $HighlightCycles) { "color=`"#ff0000`"" } else { "" }
            $dotContent += "    `"$script`" -> `"$dependency`" [$edgeStyle];`n"
        }
    }
    
    # Ajouter les statistiques en commentaire si demandÃ©
    if ($IncludeStatistics) {
        $dotContent += "`n    // Statistiques`n"
        $dotContent += "    // Total des scripts: $($CycleData.DependencyGraph.Keys.Count)`n"
        $dotContent += "    // Scripts impliquÃ©s dans des cycles: $(if ($CycleData.HasCycles) { $CycleData.Cycles.Count } else { 0 })`n"
        $dotContent += "    // Scripts sans cycles: $($CycleData.NonCyclicScripts.Count)`n"
        
        if ($CycleData.HasCycles) {
            $dotContent += "`n    // Cycles dÃ©tectÃ©s`n"
            foreach ($cycle in $CycleData.Cycles) {
                $cycleStr = $cycle -join " -> "
                $dotContent += "    // $cycleStr`n"
            }
        }
    }
    
    $dotContent += "}"
    
    # Enregistrer le fichier DOT
    $dotContent | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "Fichier DOT gÃ©nÃ©rÃ©: $OutputPath"

    return $OutputPath
}
