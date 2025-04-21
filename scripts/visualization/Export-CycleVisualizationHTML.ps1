# Fonction pour exporter une visualisation HTML des cycles de dependances
function Export-CycleVisualizationHTML {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$CycleData,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$HighlightCycles,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStatistics,

        [Parameter(Mandatory = $false)]
        [switch]$OpenInBrowser
    )

    # Verifier si les donnees de cycle sont valides
    if (-not $CycleData.DependencyGraph) {
        Write-Error "Les donnees de cycle ne contiennent pas de graphe de dependances."
        return $null
    }

    # Generer le chemin de sortie par defaut si non specifie
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputPath = "reports/cycle_visualization_${timestamp}.html"
    }

    # Creer le repertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Preparer les donnees pour JavaScript
    $nodes = @()
    $edges = @()
    $nodeId = 0
    $nodeIds = @{}

    # Creer les noeuds
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        $isCyclic = $CycleData.HasCycles -and $CycleData.Cycles -contains $script
        $nodeClass = if ($isCyclic -and $HighlightCycles) { "cyclic" } else { "" }
        $nodes += @{
            id = $nodeId
            label = $script
            group = $nodeClass
        }
        $nodeIds[$script] = $nodeId
        $nodeId++
    }

    # Creer les aretes
    $edgeId = 0
    foreach ($script in $CycleData.DependencyGraph.Keys) {
        $sourceId = $nodeIds[$script]
        foreach ($dependency in $CycleData.DependencyGraph[$script]) {
            if ($nodeIds.ContainsKey($dependency)) {
                $targetId = $nodeIds[$dependency]
                $isCyclicEdge = $CycleData.HasCycles -and $CycleData.Cycles -contains $script -and $CycleData.Cycles -contains $dependency
                $color = if ($isCyclicEdge -and $HighlightCycles) { "#ff0000" } else { "#848484" }
                $edges += @{
                    id = $edgeId
                    from = $sourceId
                    to = $targetId
                    arrows = "to"
                    color = $color
                }
                $edgeId++
            }
        }
    }

    # Convertir les donnees en JSON pour JavaScript
    $nodesJson = $nodes | ConvertTo-Json
    $edgesJson = $edges | ConvertTo-Json
    $cyclesJson = if ($CycleData.HasCycles) { $CycleData.Cycles | ConvertTo-Json } else { "[]" }

    # Preparer les statistiques si demande
    $statsHtml = ""
    if ($IncludeStatistics) {
        # Calculer les statistiques
        $totalScripts = $CycleData.DependencyGraph.Keys.Count
        $cyclicScripts = if ($CycleData.HasCycles) { $CycleData.Cycles.Count } else { 0 }
        $nonCyclicScripts = $CycleData.NonCyclicScripts.Count
        
        # Calculer la moyenne des dependances
        $totalDeps = 0
        foreach ($script in $CycleData.DependencyGraph.Keys) {
            $totalDeps += $CycleData.DependencyGraph[$script].Count
        }
        $avgDeps = if ($totalScripts -gt 0) { [math]::Round($totalDeps / $totalScripts, 2) } else { 0 }
        
        # Trouver le script avec le plus de dependances
        $maxDeps = 0
        $scriptWithMaxDeps = ""
        foreach ($script in $CycleData.DependencyGraph.Keys) {
            if ($CycleData.DependencyGraph[$script].Count -gt $maxDeps) {
                $maxDeps = $CycleData.DependencyGraph[$script].Count
                $scriptWithMaxDeps = $script
            }
        }
        
        $statsHtml = "<div class='stats'>`n"
        $statsHtml += "    <h3>Statistiques</h3>`n"
        $statsHtml += "    <p>Total des scripts: $totalScripts</p>`n"
        $statsHtml += "    <p>Scripts impliques dans des cycles: $cyclicScripts</p>`n"
        $statsHtml += "    <p>Scripts sans cycles: $nonCyclicScripts</p>`n"
        $statsHtml += "    <p>Moyenne des dependances par script: $avgDeps</p>`n"
        $statsHtml += "    <p>Script avec le plus de dependances: $scriptWithMaxDeps ($maxDeps dependances)</p>`n"

        # Ajouter la liste des cycles detectes si presents
        if ($CycleData.HasCycles) {
            $statsHtml += "    <h3>Cycles detectes</h3>`n    <ul>`n"
            foreach ($cycle in $CycleData.Cycles) {
                $cycleStr = $cycle -join " -> "
                $statsHtml += "        <li>$cycleStr</li>`n"
            }
            $statsHtml += "    </ul>`n"
        }
        
        $statsHtml += "</div>`n"
    }

    # Creer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Visualisation des cycles de dependances</title>
    <meta charset="UTF-8">
    <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style>
        body, html { height: 100%; margin: 0; padding: 0; font-family: Arial, sans-serif; }
        #mynetwork { height: 80%; border: 1px solid lightgray; }
        .controls { padding: 10px; background-color: #f0f0f0; }
        .stats { margin-top: 10px; padding: 10px; background-color: #f8f9fa; border: 1px solid #ddd; }
        .cyclic { background-color: #ffcccc; }
    </style>
</head>
<body>
    <div class="controls">
        <button onclick="zoomIn()">Zoom +</button>
        <button onclick="zoomOut()">Zoom -</button>
        <button onclick="resetView()">Reinitialiser</button>
        <button onclick="highlightCycles()">Mettre en evidence les cycles</button>
    </div>
    <div id="mynetwork"></div>
    $statsHtml
    <script>
        // Donnees du graphe
        var nodes = new vis.DataSet($nodesJson);
        var edges = new vis.DataSet($edgesJson);
        var cyclicNodes = $cyclesJson;

        // Configuration du graphe
        var container = document.getElementById('mynetwork');
        var data = { nodes: nodes, edges: edges };
        var options = {
            nodes: { shape: 'box', font: { size: 14 } },
            edges: { width: 2 },
            groups: { cyclic: { color: {background: '#ffcccc', border: '#ff0000'} } },
            physics: { stabilization: true }
        };

        // Creer le graphe
        var network = new vis.Network(container, data, options);

        // Fonctions pour les controles
        function zoomIn() {
            var scale = network.getScale() * 1.2;
            network.moveTo({ scale: scale });
        }

        function zoomOut() {
            var scale = network.getScale() * 0.8;
            network.moveTo({ scale: scale });
        }

        function resetView() {
            network.fit();
        }

        function highlightCycles() {
            nodes.forEach(function(node) {
                var isCyclic = cyclicNodes.includes(node.label);
                nodes.update({
                    id: node.id,
                    group: isCyclic ? 'cyclic' : ''
                });
            });

            edges.forEach(function(edge) {
                var fromNode = nodes.get(edge.from);
                var toNode = nodes.get(edge.to);
                var isCyclicEdge = cyclicNodes.includes(fromNode.label) && cyclicNodes.includes(toNode.label);
                edges.update({
                    id: edge.id,
                    color: isCyclicEdge ? '#ff0000' : '#848484'
                });
            });
        }
    </script>
</body>
</html>
"@

    # Enregistrer le fichier HTML
    $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "Visualisation HTML generee: $OutputPath"

    # Ouvrir dans le navigateur si demande
    if ($OpenInBrowser) {
        Start-Process $OutputPath
    }

    return $OutputPath
}
