﻿# Test-HierarchicalStructures.ps1
# Script pour tester la génération de structures hiérarchiques
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("BalancedTree", "UnbalancedTree", "Network", "Matrix", "Star", "All")]
    [string]$StructureType = "All",

    [Parameter(Mandatory = $false)]
    [int]$NodeCount = 100,

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "development/scripts/roadmap/tests/data/hierarchical",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeMetadata,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeDependencies,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateVisualization,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"
$hierarchicalStructuresModulePath = Join-Path -Path $utilsPath -ChildPath "Generate-HierarchicalStructures.ps1"
$randomTasksModulePath = Join-Path -Path $utilsPath -ChildPath "Generate-RandomTasks.ps1"

if (-not (Test-Path -Path $hierarchicalStructuresModulePath)) {
    Write-Error "Module de génération de structures hiérarchiques non trouvé: $hierarchicalStructuresModulePath"
    exit 1
}

if (-not (Test-Path -Path $randomTasksModulePath)) {
    Write-Error "Module de génération de tâches aléatoires non trouvé: $randomTasksModulePath"
    exit 1
}

. $hierarchicalStructuresModulePath
. $randomTasksModulePath

# Importer les fonctions utilitaires si elles existent
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"
if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"

        switch ($Level) {
            "Error" { Write-Host $logMessage -ForegroundColor Red }
            "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
            "Success" { Write-Host $logMessage -ForegroundColor Green }
            default { Write-Host $logMessage }
        }
    }
}

# Fonction pour générer une visualisation de la structure hiérarchique
function New-HierarchicalVisualization {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Nodes,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    # Créer le contenu HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
        #graph { width: 100%; height: 800px; border: 1px solid #ddd; }
        .node { cursor: pointer; }
        .node circle { fill: #fff; stroke: #3182bd; stroke-width: 1.5px; }
        .node text { font: 10px sans-serif; }
        .link { fill: none; stroke: #9ecae1; stroke-width: 1.5px; }
        .dependency { fill: none; stroke: #e15759; stroke-width: 1.5px; stroke-dasharray: 3, 3; }
    </style>
</head>
<body>
    <h1>$Title</h1>
    <div id="graph"></div>
    <script>
        // Convertir les données en format D3
        const nodes = [
"@

    # Ajouter les nœuds
    $nodeData = @()

    foreach ($node in $Nodes) {
        $nodeJson = @{
            id           = $node.Id
            name         = $node.Description
            status       = $node.Status
            level        = $node.IndentLevel
            parent       = $node.ParentId
            dependencies = $node.Dependencies
        } | ConvertTo-Json -Compress

        $nodeData += "            $nodeJson"
    }

    $html += $nodeData -join ",`n"

    $html += @"
        ];

        // Créer les liens parent-enfant
        const links = [];
        const dependencies = [];

        nodes.forEach(node => {
            if (node.parent) {
                links.push({
                    source: node.parent,
                    target: node.id,
                    type: "parent-child"
                });
            }

            if (node.dependencies && node.dependencies.length > 0) {
                node.dependencies.forEach(dep => {
                    dependencies.push({
                        source: dep,
                        target: node.id,
                        type: "dependency"
                    });
                });
            }
        });

        // Créer le graphe
        const width = document.getElementById('graph').clientWidth;
        const height = document.getElementById('graph').clientHeight;

        const simulation = d3.forceSimulation()
            .force("link", d3.forceLink().id(d => d.id).distance(100))
            .force("charge", d3.forceManyBody().strength(-300))
            .force("center", d3.forceCenter(width / 2, height / 2))
            .force("x", d3.forceX(width / 2).strength(0.1))
            .force("y", d3.forceY(height / 2).strength(0.1));

        const svg = d3.select("#graph")
            .append("svg")
            .attr("width", width)
            .attr("height", height);

        // Ajouter les liens
        const link = svg.append("g")
            .selectAll("line")
            .data([...links, ...dependencies])
            .enter().append("line")
            .attr("class", d => d.type === "dependency" ? "dependency" : "link");

        // Ajouter les nœuds
        const node = svg.append("g")
            .selectAll(".node")
            .data(nodes)
            .enter().append("g")
            .attr("class", "node")
            .call(d3.drag()
                .on("start", dragstarted)
                .on("drag", dragged)
                .on("end", dragended));

        node.append("circle")
            .attr("r", d => 5 + (4 - d.level))
            .style("fill", d => {
                if (d.status === "Completed") return "#2ca02c";
                if (d.status === "InProgress") return "#1f77b4";
                if (d.status === "Blocked") return "#d62728";
                return "#7f7f7f";
            });

        node.append("text")
            .attr("dx", 12)
            .attr("dy", ".35em")
            .text(d => d.id + ": " + d.name.substring(0, 30));

        // Configurer la simulation
        simulation
            .nodes(nodes)
            .on("tick", ticked);

        simulation.force("link")
            .links([...links, ...dependencies]);

        function ticked() {
            link
                .attr("x1", d => Math.max(10, Math.min(width - 10, d.source.x)))
                .attr("y1", d => Math.max(10, Math.min(height - 10, d.source.y)))
                .attr("x2", d => Math.max(10, Math.min(width - 10, d.target.x)))
                .attr("y2", d => Math.max(10, Math.min(height - 10, d.target.y)));

            node
                .attr("transform", d => `translate(\${Math.max(10, Math.min(width - 10, d.x))},\${Math.max(10, Math.min(height - 10, d.y))})`);
        }

        function dragstarted(event, d) {
            if (!event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x;
            d.fy = d.y;
        }

        function dragged(event, d) {
            d.fx = event.x;
            d.fy = event.y;
        }

        function dragended(event, d) {
            if (!event.active) simulation.alphaTarget(0);
            d.fx = null;
            d.fy = null;
        }
    </script>
</body>
</html>
"@

    # Créer le répertoire parent si nécessaire
    $parentDir = Split-Path -Path $OutputPath -Parent

    if (-not (Test-Path -Path $parentDir -PathType Container)) {
        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
    }

    # Sauvegarder le fichier HTML
    $html | Out-File -FilePath $OutputPath -Encoding UTF8 -Force

    return $OutputPath
}

# Fonction pour tester la génération d'une structure hiérarchique
function Test-HierarchicalStructure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$StructureType,

        [Parameter(Mandatory = $true)]
        [int]$NodeCount,

        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateVisualization,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    Write-Log "Test de la structure hiérarchique '$StructureType'..." -Level Info

    # Mesurer le temps d'exécution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Générer la structure hiérarchique
    $nodes = $null

    switch ($StructureType) {
        "BalancedTree" {
            $nodes = New-BalancedTreeStructure -NodeCount $NodeCount -MaxDepth 4 -BranchingFactor 3 -WithMetadata:$IncludeMetadata -WithDependencies:$IncludeDependencies
        }
        "UnbalancedTree" {
            $nodes = New-UnbalancedTreeStructure -NodeCount $NodeCount -MaxDepth 6 -ImbalanceFactor 0.7 -WithMetadata:$IncludeMetadata -WithDependencies:$IncludeDependencies
        }
        "Network" {
            $nodes = New-NetworkStructure -NodeCount $NodeCount -MaxDepth 3 -ConnectionDensity 0.3 -WithMetadata:$IncludeMetadata
        }
        "Matrix" {
            $nodes = New-MatrixStructure -NodeCount $NodeCount -FunctionalDimension 5 -ProjectDimension 4 -WithMetadata:$IncludeMetadata
        }
        "Star" {
            $nodes = New-StarStructure -NodeCount $NodeCount -CentralNodeCount 3 -WithMetadata:$IncludeMetadata
        }
        default {
            Write-Error "Type de structure non supporté: $StructureType"
            return $null
        }
    }

    $generationTime = $stopwatch.ElapsedMilliseconds

    if (-not $nodes) {
        Write-Log "Échec de la génération de la structure '$StructureType'" -Level Error
        return $null
    }

    # Vérifier les résultats
    $actualNodeCount = $nodes.Count
    $rootNodeCount = ($nodes | Where-Object { $_.IndentLevel -eq 0 }).Count
    $maxDepth = ($nodes | Measure-Object -Property IndentLevel -Maximum).Maximum
    $nodesWithMetadata = ($nodes | Where-Object { $_.Metadata.Count -gt 0 }).Count
    $nodesWithDependencies = ($nodes | Where-Object { $_.Dependencies.Count -gt 0 }).Count
    $totalDependencies = ($nodes | ForEach-Object { $_.Dependencies.Count } | Measure-Object -Sum).Sum

    Write-Log "Génération terminée en $generationTime ms" -Level Success
    Write-Log "Nombre de nœuds générés: $actualNodeCount (demandé: $NodeCount)" -Level Info
    Write-Log "Nombre de nœuds racines: $rootNodeCount" -Level Info
    Write-Log "Profondeur maximale: $maxDepth" -Level Info
    Write-Log "Nœuds avec métadonnées: $nodesWithMetadata" -Level Info
    Write-Log "Nœuds avec dépendances: $nodesWithDependencies" -Level Info
    Write-Log "Nombre total de dépendances: $totalDependencies" -Level Info

    # Sauvegarder la structure en markdown
    $outputFileName = "structure_${StructureType}_${NodeCount}.md"
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath $outputFileName

    $title = "Structure hiérarchique - $StructureType - $NodeCount nœuds"

    $stopwatch.Restart()
    $result = Save-MarkdownRoadmap -Tasks $nodes -OutputPath $outputPath -Title $title -IncludeMetadata:$IncludeMetadata -IncludeDependencies:$true -Force:$Force
    $saveTime = $stopwatch.ElapsedMilliseconds

    if ($result) {
        Write-Log "Structure sauvegardée dans $outputPath en $saveTime ms" -Level Success
    } else {
        Write-Log "Échec de la sauvegarde de la structure" -Level Error
    }

    # Générer une visualisation si demandé
    $visualizationPath = $null
    $visualizationTime = 0

    if ($GenerateVisualization) {
        $visualizationFileName = "structure_${StructureType}_${NodeCount}.html"
        $visualizationPath = Join-Path -Path $OutputDirectory -ChildPath "visualizations" | Join-Path -ChildPath $visualizationFileName

        $stopwatch.Restart()
        $visualizationPath = New-HierarchicalVisualization -Nodes $nodes -OutputPath $visualizationPath -Title $title
        $visualizationTime = $stopwatch.ElapsedMilliseconds

        Write-Log "Visualisation générée dans $visualizationPath en $visualizationTime ms" -Level Success
    }

    # Retourner les résultats du test
    return [PSCustomObject]@{
        StructureType         = $StructureType
        RequestedNodeCount    = $NodeCount
        ActualNodeCount       = $actualNodeCount
        RootNodeCount         = $rootNodeCount
        MaxDepth              = $maxDepth
        NodesWithMetadata     = $nodesWithMetadata
        NodesWithDependencies = $nodesWithDependencies
        TotalDependencies     = $totalDependencies
        GenerationTimeMs      = $generationTime
        SaveTimeMs            = $saveTime
        VisualizationTimeMs   = $visualizationTime
        OutputPath            = $outputPath
        VisualizationPath     = $visualizationPath
        Success               = $true
    }
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    param (
        [Parameter(Mandatory = $true)]
        [string]$StructureType,

        [Parameter(Mandatory = $true)]
        [int]$NodeCount,

        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateVisualization,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $results = @()

    # Définir les types de structure à tester
    $structureTypes = @()

    if ($StructureType -eq "All") {
        $structureTypes = @("BalancedTree", "UnbalancedTree", "Network", "Matrix", "Star")
    } else {
        $structureTypes = @($StructureType)
    }

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        Write-Log "Répertoire de sortie créé: $OutputDirectory" -Level Info
    }

    # Créer le répertoire de visualisations s'il n'existe pas
    if ($GenerateVisualization) {
        $visualizationsDir = Join-Path -Path $OutputDirectory -ChildPath "visualizations"

        if (-not (Test-Path -Path $visualizationsDir -PathType Container)) {
            New-Item -Path $visualizationsDir -ItemType Directory -Force | Out-Null
            Write-Log "Répertoire de visualisations créé: $visualizationsDir" -Level Info
        }
    }

    # Exécuter les tests pour chaque type de structure
    foreach ($type in $structureTypes) {
        $result = Test-HierarchicalStructure -StructureType $type -NodeCount $NodeCount -OutputDirectory $OutputDirectory -IncludeMetadata:$IncludeMetadata -IncludeDependencies:$IncludeDependencies -GenerateVisualization:$GenerateVisualization -Force:$Force

        if ($result) {
            $results += $result
        }
    }

    return $results
}

# Fonction pour générer un rapport de test
function New-TestReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    $report = @()
    $report += "# Rapport de test de génération de structures hiérarchiques"
    $report += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "Nombre de tests: $($Results.Count)"
    $report += ""

    $report += "## Résumé"
    $report += "| Structure | Nœuds | Profondeur | Racines | Dépendances | Génération (ms) | Sauvegarde (ms) |"
    $report += "|-----------|-------|------------|---------|-------------|-----------------|-----------------|"

    foreach ($result in $Results) {
        $report += "| $($result.StructureType) | $($result.ActualNodeCount) | $($result.MaxDepth) | $($result.RootNodeCount) | $($result.TotalDependencies) | $($result.GenerationTimeMs) | $($result.SaveTimeMs) |"
    }

    $report += ""
    $report += "## Détails des tests"

    foreach ($result in $Results) {
        $report += "### Structure: $($result.StructureType)"
        $report += "- **Nœuds demandés**: $($result.RequestedNodeCount)"
        $report += "- **Nœuds générés**: $($result.ActualNodeCount)"
        $report += "- **Profondeur maximale**: $($result.MaxDepth)"
        $report += "- **Nœuds racines**: $($result.RootNodeCount)"
        $report += "- **Nœuds avec métadonnées**: $($result.NodesWithMetadata)"
        $report += "- **Nœuds avec dépendances**: $($result.NodesWithDependencies)"
        $report += "- **Nombre total de dépendances**: $($result.TotalDependencies)"
        $report += "- **Temps de génération**: $($result.GenerationTimeMs) ms"
        $report += "- **Temps de sauvegarde**: $($result.SaveTimeMs) ms"
        $report += "- **Fichier de sortie**: $($result.OutputPath)"

        if ($result.VisualizationPath) {
            $report += "- **Visualisation**: $($result.VisualizationPath)"
            $report += "- **Temps de génération de la visualisation**: $($result.VisualizationTimeMs) ms"
        }

        $report += ""
    }

    $reportText = $report -join "`n"

    if ($OutputPath) {
        $reportText | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Rapport de test sauvegardé dans $OutputPath" -Level Success
    }

    return $reportText
}

# Exécution principale
try {
    Write-Log "Démarrage des tests de génération de structures hiérarchiques..." -Level Info

    $results = Invoke-AllTests -StructureType $StructureType -NodeCount $NodeCount -OutputDirectory $OutputDirectory -IncludeMetadata:$IncludeMetadata -IncludeDependencies:$IncludeDependencies -GenerateVisualization:$GenerateVisualization -Force:$Force

    $reportPath = Join-Path -Path $OutputDirectory -ChildPath "hierarchical_test_report.md"
    $report = New-TestReport -Results $results -OutputPath $reportPath

    Write-Log "Tests terminés avec succès" -Level Success

    return $results
} catch {
    Write-Log "Erreur lors de l'exécution des tests: $_" -Level Error
    exit 1
}
