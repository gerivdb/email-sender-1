#Requires -Version 5.1
<#
.SYNOPSIS
    Exporte un graphique de flamme (flamegraph) Ã  partir des donnÃ©es de traÃ§age.

.DESCRIPTION
    Ce script gÃ©nÃ¨re un graphique de flamme HTML interactif Ã  partir des donnÃ©es
    de traÃ§age collectÃ©es par le module PRPerformanceTracer.

.PARAMETER Tracer
    L'objet traceur contenant les donnÃ©es de traÃ§age.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer le graphique de flamme.
    Par dÃ©faut: "reports\pr-analysis\profiling\flamegraph.html"

.EXAMPLE
    Export-PRPerformanceFlameGraph -Tracer $tracer -OutputPath "reports\flamegraph_pr42.html"
    GÃ©nÃ¨re un graphique de flamme Ã  partir des donnÃ©es du traceur et l'enregistre dans le fichier spÃ©cifiÃ©.

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

# Fonction pour convertir les donnÃ©es de traÃ§age en format compatible avec d3-flame-graph
function ConvertTo-FlameGraphData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$TracingData
    )

    # Fonction rÃ©cursive pour construire l'arbre
    function Build-FlameNode {
        param(
            [Parameter(Mandatory = $true)]
            [object]$Operation,
            
            [Parameter()]
            [string]$ParentName = "root"
        )

        # CrÃ©er le nÅ“ud
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

    # Construire l'arbre Ã  partir des opÃ©rations
    $root = [PSCustomObject]@{
        name = "PR Analysis"
        value = [int]($TracingData.Duration.TotalMilliseconds)
        children = @()
    }

    # Ajouter les opÃ©rations de premier niveau
    foreach ($operation in $TracingData.Operations) {
        if ($null -eq $operation.Parent) {
            $node = Build-FlameNode -Operation $operation
            $root.children += $node
        }
    }

    return $root
}

# Fonction pour gÃ©nÃ©rer le HTML du graphique de flamme
function New-FlameGraphHtml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$FlameData
    )

    # Convertir les donnÃ©es en JSON
    $dataJson = $FlameData | ConvertTo-Json -Depth 10

    # CrÃ©er le HTML
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
            <button id="resetBtn">RÃ©initialiser</button>
            <button id="searchBtn">Rechercher</button>
        </div>
        <div id="chart"></div>
    </div>

    <script>
        // DonnÃ©es du graphique de flamme
        const flameData = $dataJson;

        // CrÃ©er le graphique de flamme
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

        // Bouton de rÃ©initialisation
        document.getElementById('resetBtn').addEventListener('click', function() {
            flamegraph.resetZoom();
        });

        // Bouton de recherche
        document.getElementById('searchBtn').addEventListener('click', function() {
            const term = prompt('Entrez un terme Ã  rechercher:');
            if (term) {
                flamegraph.search(term);
            }
        });

        // Redimensionner le graphique lors du redimensionnement de la fenÃªtre
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

# Point d'entrÃ©e principal
try {
    # VÃ©rifier que le traceur est valide
    if ($null -eq $Tracer) {
        throw "L'objet traceur est null."
    }

    # Obtenir les donnÃ©es de traÃ§age
    $tracingData = $Tracer.GetTracingData()
    if ($null -eq $tracingData) {
        throw "Impossible d'obtenir les donnÃ©es de traÃ§age."
    }

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Convertir les donnÃ©es pour le graphique de flamme
    $flameData = ConvertTo-FlameGraphData -TracingData $tracingData

    # GÃ©nÃ©rer le HTML
    $html = New-FlameGraphHtml -FlameData $flameData

    # Enregistrer le fichier HTML
    Set-Content -Path $OutputPath -Value $html -Encoding UTF8

    Write-Host "Graphique de flamme gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -ForegroundColor Green
    return $OutputPath
} catch {
    Write-Error "Erreur lors de la gÃ©nÃ©ration du graphique de flamme: $_"
    return $null
}
