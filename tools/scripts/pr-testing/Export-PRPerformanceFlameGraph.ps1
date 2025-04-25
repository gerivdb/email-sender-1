#Requires -Version 5.1
<#
.SYNOPSIS
    Exporte un graphique de flamme (flamegraph) à partir des données de traçage.

.DESCRIPTION
    Ce script génère un graphique de flamme HTML interactif à partir des données
    de traçage collectées par le module PRPerformanceTracer.

.PARAMETER Tracer
    L'objet traceur contenant les données de traçage.

.PARAMETER OutputPath
    Le chemin où enregistrer le graphique de flamme.
    Par défaut: "reports\pr-analysis\profiling\flamegraph.html"

.EXAMPLE
    Export-PRPerformanceFlameGraph -Tracer $tracer -OutputPath "reports\flamegraph_pr42.html"
    Génère un graphique de flamme à partir des données du traceur et l'enregistre dans le fichier spécifié.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [object]$Tracer,

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis\profiling\flamegraph.html"
)

# Fonction pour convertir les données de traçage en format compatible avec d3-flame-graph
function ConvertTo-FlameGraphData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TracingData
    )

    # Fonction récursive pour construire l'arbre
    function Build-FlameNode {
        param(
            [Parameter(Mandatory = $true)]
            [object]$Operation,
            
            [Parameter()]
            [string]$ParentName = "root"
        )

        # Créer le nœud
        $node = [PSCustomObject]@{
            name = $Operation.Name
            value = [Math]::Max(1, [int]($Operation.Duration.TotalMilliseconds))
            children = @()
        }

        # Ajouter les enfants
        foreach ($child in $Operation.Children) {
            $childNode = Build-FlameNode -Operation $child -ParentName $Operation.Name
            $node.children += $childNode
        }

        return $node
    }

    # Construire l'arbre à partir des opérations
    $root = [PSCustomObject]@{
        name = "PR Analysis"
        value = [int]($TracingData.Duration.TotalMilliseconds)
        children = @()
    }

    # Ajouter les opérations de premier niveau
    foreach ($operation in $TracingData.Operations) {
        if ($null -eq $operation.Parent) {
            $node = Build-FlameNode -Operation $operation
            $root.children += $node
        }
    }

    return $root
}

# Fonction pour générer le HTML du graphique de flamme
function New-FlameGraphHtml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$FlameData
    )

    # Convertir les données en JSON
    $dataJson = $FlameData | ConvertTo-Json -Depth 10

    # Créer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Graphique de Flamme - Analyse PR</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/d3-flame-graph@4.1.3/dist/d3-flamegraph.min.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/d3-flame-graph@4.1.3/dist/d3-flamegraph.css">
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            margin-top: 0;
        }
        .controls {
            margin-bottom: 10px;
        }
        button {
            padding: 5px 10px;
            margin-right: 5px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 3px;
            cursor: pointer;
        }
        button:hover {
            background-color: #45a049;
        }
        #chart {
            width: 100%;
            height: 500px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Graphique de Flamme - Analyse de Pull Request</h1>
        <div class="controls">
            <button id="resetBtn">Réinitialiser</button>
            <button id="searchBtn">Rechercher</button>
        </div>
        <div id="chart"></div>
    </div>

    <script>
        // Données du graphique de flamme
        const flameData = $dataJson;

        // Créer le graphique de flamme
        const flamegraph = d3.flamegraph()
            .width(document.getElementById('chart').clientWidth)
            .cellHeight(20)
            .transitionDuration(750)
            .minFrameSize(1)
            .title("")
            .tooltip(true);

        // Rendre le graphique
        d3.select("#chart")
            .datum(flameData)
            .call(flamegraph);

        // Bouton de réinitialisation
        document.getElementById('resetBtn').addEventListener('click', function() {
            flamegraph.resetZoom();
        });

        // Bouton de recherche
        document.getElementById('searchBtn').addEventListener('click', function() {
            const term = prompt('Entrez un terme à rechercher:');
            if (term) {
                flamegraph.search(term);
            }
        });

        // Redimensionner le graphique lors du redimensionnement de la fenêtre
        window.addEventListener('resize', function() {
            flamegraph.width(document.getElementById('chart').clientWidth);
            d3.select("#chart").call(flamegraph);
        });
    </script>
</body>
</html>
"@

    return $html
}

# Point d'entrée principal
try {
    # Vérifier que le traceur est valide
    if ($null -eq $Tracer) {
        throw "L'objet traceur est null."
    }

    # Obtenir les données de traçage
    $tracingData = $Tracer.GetTracingData()
    if ($null -eq $tracingData) {
        throw "Impossible d'obtenir les données de traçage."
    }

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Convertir les données pour le graphique de flamme
    $flameData = ConvertTo-FlameGraphData -TracingData $tracingData

    # Générer le HTML
    $html = New-FlameGraphHtml -FlameData $flameData

    # Enregistrer le fichier HTML
    Set-Content -Path $OutputPath -Value $html -Encoding UTF8

    Write-Host "Graphique de flamme généré avec succès: $OutputPath" -ForegroundColor Green
    return $OutputPath
} catch {
    Write-Error "Erreur lors de la génération du graphique de flamme: $_"
    return $null
}
