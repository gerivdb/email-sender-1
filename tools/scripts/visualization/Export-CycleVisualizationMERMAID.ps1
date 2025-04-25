# Fonction pour exporter une visualisation MERMAID des cycles de dependances
function Export-CycleVisualizationMERMAID {
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

    # Verifier si les donnees de cycle sont valides
    if (-not $CycleData.DependencyGraph) {
        Write-Error "Les donnees de cycle ne contiennent pas de graphe de dependances."
        return $null
    }

    # Generer le chemin de sortie par defaut si non specifie
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputPath = "reports/cycle_visualization_${timestamp}.md"
    }

    # Creer le repertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Generer un diagramme Mermaid pour l'integration dans Markdown
    $mermaidContent = "```mermaid`ngraph TD;`n"

    # Definir les noeuds et les aretes
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        $scriptId = $script.Replace(".", "_").Replace(" ", "_").Replace("-", "_")
        $isCyclic = $CycleData.HasCycles -and $CycleData.Cycles -contains $script
        $nodeStyle = if ($isCyclic -and $HighlightCycles) { "style " + $scriptId + " fill:#ffcccc,stroke:#ff0000;`n" } else { "" }
        $mermaidContent += $nodeStyle

        foreach ($dependency in $CycleData.DependencyGraph[$script]) {
            $dependencyId = $dependency.Replace(".", "_").Replace(" ", "_").Replace("-", "_")
            $isCyclicEdge = $CycleData.HasCycles -and $CycleData.Cycles -contains $script -and $CycleData.Cycles -contains $dependency
            $edgeStyle = if ($isCyclicEdge -and $HighlightCycles) { "stroke:#ff0000" } else { "" }
            $mermaidContent += "    $scriptId-->$dependencyId" + (if ($edgeStyle) { "[$edgeStyle]" } else { "" }) + ";`n"
        }
    }

    # Ajouter les statistiques si demande
    if ($IncludeStatistics) {
        $mermaidContent += "`n    %% Statistiques`n"
        $mermaidContent += "    %% Total des scripts: $($CycleData.DependencyGraph.Keys.Count)`n"
        $mermaidContent += "    %% Scripts impliques dans des cycles: $(if ($CycleData.HasCycles) { $CycleData.Cycles.Count } else { 0 })`n"
        $mermaidContent += "    %% Scripts sans cycles: $($CycleData.NonCyclicScripts.Count)`n"

        if ($CycleData.HasCycles) {
            $mermaidContent += "`n    %% Cycles detectes`n"
            foreach ($cycle in $CycleData.Cycles) {
                $cycleStr = $cycle -join " -> "
                $mermaidContent += "    %% $cycleStr`n"
            }
        }
    }

    $mermaidContent += "```"

    # Enregistrer le fichier Mermaid
    $mermaidContent | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "Diagramme Mermaid genere: $OutputPath"

    return $OutputPath
}
