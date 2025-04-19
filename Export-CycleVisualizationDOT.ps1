# Fonction pour exporter une visualisation DOT des cycles de dépendances
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

    # Vérifier si les données de cycle sont valides
    if (-not $CycleData.DependencyGraph) {
        Write-Error "Les données de cycle ne contiennent pas de graphe de dépendances."
        return $null
    }

    # Générer le chemin de sortie par défaut si non spécifié
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputPath = "reports/cycle_visualization_${timestamp}.dot"
    }

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Générer un fichier DOT pour GraphViz
    $dotContent = "digraph DependencyGraph {`n"
    $dotContent += "    rankdir=LR;`n"
    $dotContent += "    node [shape=box, style=filled, fillcolor=white];`n"
    
    # Définir les nœuds
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        $isCyclic = $CycleData.HasCycles -and $CycleData.Cycles -contains $script
        $nodeStyle = if ($isCyclic -and $HighlightCycles) { "fillcolor=`"#ffcccc`"" } else { "fillcolor=white" }
        $dotContent += "    `"$script`" [$nodeStyle];`n"
    }
    
    # Définir les arêtes
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        foreach ($dependency in $CycleData.DependencyGraph[$script]) {
            $isCyclicEdge = $CycleData.HasCycles -and $CycleData.Cycles -contains $script -and $CycleData.Cycles -contains $dependency
            $edgeStyle = if ($isCyclicEdge -and $HighlightCycles) { "color=`"#ff0000`"" } else { "" }
            $dotContent += "    `"$script`" -> `"$dependency`" [$edgeStyle];`n"
        }
    }
    
    # Ajouter les statistiques en commentaire si demandé
    if ($IncludeStatistics) {
        $dotContent += "`n    // Statistiques`n"
        $dotContent += "    // Total des scripts: $($CycleData.DependencyGraph.Keys.Count)`n"
        $dotContent += "    // Scripts impliqués dans des cycles: $(if ($CycleData.HasCycles) { $CycleData.Cycles.Count } else { 0 })`n"
        $dotContent += "    // Scripts sans cycles: $($CycleData.NonCyclicScripts.Count)`n"
        
        if ($CycleData.HasCycles) {
            $dotContent += "`n    // Cycles détectés`n"
            foreach ($cycle in $CycleData.Cycles) {
                $cycleStr = $cycle -join " -> "
                $dotContent += "    // $cycleStr`n"
            }
        }
    }
    
    $dotContent += "}"
    
    # Enregistrer le fichier DOT
    $dotContent | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "Fichier DOT généré: $OutputPath"

    return $OutputPath
}
