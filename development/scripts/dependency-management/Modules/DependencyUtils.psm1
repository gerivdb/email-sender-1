#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'utilitaires pour l'analyse des dÃ©pendances.

.DESCRIPTION
    Ce module fournit des fonctions utilitaires pour l'analyse des dÃ©pendances,
    comme la dÃ©tection des modules systÃ¨me, la rÃ©solution des chemins, etc.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
#>

function Test-SystemModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    # Liste des modules systÃ¨me PowerShell
    $systemModules = @(
        'Microsoft.PowerShell.Archive',
        'Microsoft.PowerShell.Core',
        'Microsoft.PowerShell.Diagnostics',
        'Microsoft.PowerShell.Host',
        'Microsoft.PowerShell.Management',
        'Microsoft.PowerShell.Security',
        'Microsoft.PowerShell.Utility',
        'Microsoft.WSMan.Management',
        'PSDesiredStateConfiguration',
        'PSScheduledJob',
        'PSWorkflow',
        'PSWorkflowUtility',
        'CimCmdlets',
        'ISE',
        'PSReadLine',
        'PackageManagement',
        'PowerShellGet',
        'ThreadJob'
    )

    return $systemModules -contains $ModuleName
}

function Find-ModulePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$ModuleVersion
    )

    # Rechercher le module dans les chemins de modules
    $module = $null

    if ($ModuleVersion) {
        # Rechercher une version spÃ©cifique
        $module = Get-Module -Name $ModuleName -ListAvailable | 
            Where-Object { $_.Version -eq $ModuleVersion } | 
            Select-Object -First 1
    } else {
        # Rechercher la derniÃ¨re version
        $module = Get-Module -Name $ModuleName -ListAvailable | 
            Sort-Object -Property Version -Descending | 
            Select-Object -First 1
    }

    if ($module) {
        return $module.Path
    }

    # Si le module n'est pas trouvÃ©, retourner $null
    return $null
}

function Get-ModuleDependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RootModulePath,

        [Parameter(Mandatory = $false)]
        [switch]$SkipSystemModules,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveModulePaths,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10,

        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList]$ProcessedModules = $null,

        [Parameter(Mandatory = $false)]
        [int]$CurrentDepth = 0
    )

    # Initialiser la liste des modules traitÃ©s si c'est le premier appel
    if ($null -eq $ProcessedModules) {
        $ProcessedModules = [System.Collections.ArrayList]::new()
    }

    # VÃ©rifier la profondeur maximale
    if ($CurrentDepth -gt $MaxDepth) {
        Write-Warning "Maximum depth reached ($MaxDepth). Stopping recursion."
        return @()
    }

    # Initialiser le graphe de dÃ©pendances
    $dependencyGraph = [System.Collections.ArrayList]::new()

    # VÃ©rifier si le module existe
    if (-not (Test-Path -Path $RootModulePath)) {
        Write-Warning "Module path does not exist: $RootModulePath"
        return $dependencyGraph
    }

    # DÃ©terminer le type de module
    $moduleType = if ($RootModulePath -match '\.psd1$') { "Manifest" } else { "Script" }

    # Obtenir les dÃ©pendances du module
    $dependencies = @()
    if ($moduleType -eq "Manifest") {
        $dependencies = Get-ModuleDependenciesFromManifest -ManifestPath $RootModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    } else {
        $dependencies = Get-ModuleDependenciesFromCode -ModulePath $RootModulePath -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths
    }

    # Ajouter le module actuel Ã  la liste des modules traitÃ©s
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($RootModulePath)
    [void]$ProcessedModules.Add($moduleName)

    # Ajouter les dÃ©pendances au graphe
    foreach ($dependency in $dependencies) {
        # Ajouter la dÃ©pendance au graphe
        [void]$dependencyGraph.Add([PSCustomObject]@{
                Source      = $moduleName
                Target      = $dependency.Name
                Type        = $dependency.Type
                Version     = $dependency.Version
                Path        = $dependency.Path
                SourcePath  = $RootModulePath
                Depth       = $CurrentDepth
            })

        # Ã‰viter les boucles infinies en vÃ©rifiant si le module a dÃ©jÃ  Ã©tÃ© traitÃ©
        if ($ProcessedModules -contains $dependency.Name) {
            Write-Verbose "Module already processed: $($dependency.Name). Skipping to avoid circular dependencies."
            continue
        }

        # RÃ©cursivement obtenir les dÃ©pendances des dÃ©pendances
        if ($dependency.Path -and (Test-Path -Path $dependency.Path)) {
            $subDependencies = Get-ModuleDependencyGraph -RootModulePath $dependency.Path -SkipSystemModules:$SkipSystemModules -ResolveModulePaths:$ResolveModulePaths -MaxDepth $MaxDepth -ProcessedModules $ProcessedModules -CurrentDepth ($CurrentDepth + 1)
            $dependencyGraph.AddRange($subDependencies)
        }
    }

    return $dependencyGraph
}

function Export-DependencyGraphToJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$DependencyGraph,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Convertir le graphe en JSON
    $json = $DependencyGraph | ConvertTo-Json -Depth 10

    # Ã‰crire le JSON dans un fichier
    $json | Out-File -FilePath $OutputPath -Encoding utf8
}

function Export-DependencyGraphToDOT {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$DependencyGraph,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # CrÃ©er le contenu DOT
    $dotContent = @"
digraph DependencyGraph {
    rankdir=LR;
    node [shape=box, style=filled, fillcolor=lightblue];

"@

    # Ajouter les nÅ“uds et les arÃªtes
    foreach ($edge in $DependencyGraph) {
        $source = $edge.Source -replace '"', '\"'
        $target = $edge.Target -replace '"', '\"'
        $type = $edge.Type
        $version = if ($edge.Version) { $edge.Version } else { "N/A" }

        $dotContent += "    `"$source`" -> `"$target`" [label=`"$type v$version`"]`n"
    }

    $dotContent += "}"

    # Ã‰crire le contenu DOT dans un fichier
    $dotContent | Out-File -FilePath $OutputPath -Encoding utf8
}

function Export-DependencyGraphToHTML {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$DependencyGraph,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # CrÃ©er le contenu HTML avec D3.js pour la visualisation
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Module Dependency Graph</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
        }
        #graph {
            width: 100%;
            height: 800px;
            border: 1px solid #ccc;
        }
        .node {
            fill: #69b3a2;
            stroke: #fff;
            stroke-width: 2px;
        }
        .link {
            stroke: #999;
            stroke-opacity: 0.6;
            stroke-width: 1px;
        }
        .label {
            font-size: 12px;
            fill: #333;
        }
    </style>
</head>
<body>
    <h1>Module Dependency Graph</h1>
    <div id="graph"></div>
    <script>
        // DonnÃ©es du graphe
        const graphData = {
            nodes: [],
            links: []
        };

        // Convertir les donnÃ©es JSON en format D3
        const dependencyGraph = $($DependencyGraph | ConvertTo-Json -Depth 10);
        
        // CrÃ©er un ensemble unique de nÅ“uds
        const nodeSet = new Set();
        dependencyGraph.forEach(edge => {
            nodeSet.add(edge.Source);
            nodeSet.add(edge.Target);
        });
        
        // Ajouter les nÅ“uds au graphe
        nodeSet.forEach(node => {
            graphData.nodes.push({ id: node });
        });
        
        // Ajouter les liens au graphe
        dependencyGraph.forEach(edge => {
            graphData.links.push({
                source: edge.Source,
                target: edge.Target,
                type: edge.Type,
                version: edge.Version || "N/A"
            });
        });
        
        // CrÃ©er la visualisation
        const width = document.getElementById('graph').clientWidth;
        const height = document.getElementById('graph').clientHeight;
        
        const simulation = d3.forceSimulation(graphData.nodes)
            .force("link", d3.forceLink(graphData.links).id(d => d.id).distance(150))
            .force("charge", d3.forceManyBody().strength(-300))
            .force("center", d3.forceCenter(width / 2, height / 2));
        
        const svg = d3.select("#graph")
            .append("svg")
            .attr("width", width)
            .attr("height", height);
        
        // Ajouter les liens
        const link = svg.append("g")
            .selectAll("line")
            .data(graphData.links)
            .enter()
            .append("line")
            .attr("class", "link")
            .attr("stroke-width", 1);
        
        // Ajouter les nÅ“uds
        const node = svg.append("g")
            .selectAll("circle")
            .data(graphData.nodes)
            .enter()
            .append("circle")
            .attr("class", "node")
            .attr("r", 10)
            .call(d3.drag()
                .on("start", dragstarted)
                .on("drag", dragged)
                .on("end", dragended));
        
        // Ajouter les Ã©tiquettes
        const label = svg.append("g")
            .selectAll("text")
            .data(graphData.nodes)
            .enter()
            .append("text")
            .attr("class", "label")
            .attr("dx", 15)
            .attr("dy", 4)
            .text(d => d.id);
        
        // Ajouter les titres pour les infobulles
        link.append("title")
            .text(d => `${d.source.id} -> ${d.target.id}\nType: ${d.type}\nVersion: ${d.version}`);
        
        node.append("title")
            .text(d => d.id);
        
        // Mettre Ã  jour la position des Ã©lÃ©ments Ã  chaque tick
        simulation.on("tick", () => {
            link
                .attr("x1", d => d.source.x)
                .attr("y1", d => d.source.y)
                .attr("x2", d => d.target.x)
                .attr("y2", d => d.target.y);
            
            node
                .attr("cx", d => d.x)
                .attr("cy", d => d.y);
            
            label
                .attr("x", d => d.x)
                .attr("y", d => d.y);
        });
        
        // Fonctions pour le glisser-dÃ©poser
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

    # Ã‰crire le contenu HTML dans un fichier
    $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Test-SystemModule, Find-ModulePath, Get-ModuleDependencyGraph, Export-DependencyGraphToJson, Export-DependencyGraphToDOT, Export-DependencyGraphToHTML
