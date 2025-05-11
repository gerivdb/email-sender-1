# HierarchicalDiagramGenerator.ps1
# Script pour générer des diagrammes hiérarchiques à partir des données de roadmap
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère des diagrammes hiérarchiques à partir des données de roadmap.

.DESCRIPTION
    Ce script contient les fonctions nécessaires pour convertir les données de roadmap
    en format compatible avec les bibliothèques de visualisation (D3.js, Mermaid),
    et générer des diagrammes hiérarchiques interactifs.

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$visualizationTypesPath = Join-Path -Path $scriptPath -ChildPath "..\VisualizationTypes.ps1"
$visualizationTechnologiesPath = Join-Path -Path $scriptPath -ChildPath "..\VisualizationTechnologies.ps1"
$roadmapParserPath = Join-Path -Path $scriptPath -ChildPath "..\..\parser\RoadmapParser.ps1"

if (Test-Path -Path $visualizationTypesPath) {
    . $visualizationTypesPath
}
else {
    Write-Error "Le fichier VisualizationTypes.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $visualizationTechnologiesPath) {
    . $visualizationTechnologiesPath
}
else {
    Write-Error "Le fichier VisualizationTechnologies.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $roadmapParserPath) {
    . $roadmapParserPath
}
else {
    Write-Error "Le fichier RoadmapParser.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un nœud dans le diagramme hiérarchique
class HierarchicalNode {
    [string]$Id
    [string]$Title
    [string]$Status
    [string]$Priority
    [int]$Level
    [int]$Progress
    [string]$Description
    [System.Collections.ArrayList]$Children
    [hashtable]$Metadata

    # Constructeur
    HierarchicalNode([string]$id, [string]$title, [string]$status, [string]$priority, [int]$level) {
        $this.Id = $id
        $this.Title = $title
        $this.Status = $status
        $this.Priority = $priority
        $this.Level = $level
        $this.Progress = 0
        $this.Description = ""
        $this.Children = [System.Collections.ArrayList]::new()
        $this.Metadata = @{}
    }

    # Méthode pour ajouter un enfant
    [void] AddChild([HierarchicalNode]$child) {
        $this.Children.Add($child)
    }

    # Méthode pour calculer la progression basée sur les enfants
    [int] CalculateProgress() {
        if ($this.Children.Count -eq 0) {
            return $this.Progress
        }

        $totalProgress = 0
        foreach ($child in $this.Children) {
            $totalProgress += $child.CalculateProgress()
        }

        $this.Progress = [Math]::Round($totalProgress / $this.Children.Count)
        return $this.Progress
    }

    # Méthode pour convertir en format JSON
    [string] ToJson() {
        $jsonObject = @{
            id = $this.Id
            title = $this.Title
            status = $this.Status
            priority = $this.Priority
            level = $this.Level
            progress = $this.Progress
            description = $this.Description
            children = @()
            metadata = $this.Metadata
        }

        foreach ($child in $this.Children) {
            $jsonObject.children += $child.ToJson() | ConvertFrom-Json
        }

        return $jsonObject | ConvertTo-Json -Depth 10
    }
}

# Fonction pour convertir les données de roadmap en structure hiérarchique
function Convert-RoadmapToHierarchy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$RoadmapData,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCompleted = $true
    )

    # Créer le nœud racine
    $rootNode = [HierarchicalNode]::new("root", "Roadmap", "En cours", "Haute", 0)
    $rootNode.Description = "Vue d'ensemble de la roadmap"

    # Fonction récursive pour construire l'arborescence
    function Add-NodesToHierarchy {
        param (
            [Parameter(Mandatory = $true)]
            [object]$ParentNode,

            [Parameter(Mandatory = $true)]
            [object[]]$Items,

            [Parameter(Mandatory = $true)]
            [int]$CurrentLevel
        )

        foreach ($item in $Items) {
            # Vérifier si l'élément est complété et si on doit l'inclure
            if (-not $IncludeCompleted -and $item.IsCompleted) {
                continue
            }

            # Déterminer le statut
            $status = if ($item.IsCompleted) { "Terminé" } elseif ($item.IsBlocked) { "Bloqué" } else { "En cours" }

            # Déterminer la priorité basée sur les métadonnées ou le niveau
            $priority = if ($item.Metadata.ContainsKey("priority")) {
                $item.Metadata.priority
            }
            else {
                switch ($CurrentLevel) {
                    { $_ -le 1 } { "Critique" }
                    { $_ -eq 2 } { "Haute" }
                    { $_ -eq 3 } { "Moyenne" }
                    default { "Basse" }
                }
            }

            # Créer le nœud
            $node = [HierarchicalNode]::new($item.Id, $item.Title, $status, $priority, $CurrentLevel)
            $node.Description = $item.Description
            $node.Progress = if ($item.IsCompleted) { 100 } else { $item.Progress }
            $node.Metadata = $item.Metadata

            # Ajouter le nœud au parent
            $ParentNode.AddChild($node)

            # Traiter les enfants récursivement
            if ($item.Children -and $item.Children.Count -gt 0) {
                Add-NodesToHierarchy -ParentNode $node -Items $item.Children -CurrentLevel ($CurrentLevel + 1)
            }
        }
    }

    # Construire l'arborescence
    Add-NodesToHierarchy -ParentNode $rootNode -Items $RoadmapData.Items -CurrentLevel 1

    # Calculer la progression globale
    $rootNode.CalculateProgress()

    return $rootNode
}

# Fonction pour générer le code D3.js pour le diagramme hiérarchique
function Convert-HierarchyToD3 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [HierarchicalNode]$HierarchyData,

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{}
    )

    # Options par défaut
    $defaultOptions = @{
        width = 1200
        height = 800
        margin = @{
            top = 20
            right = 90
            bottom = 30
            left = 90
        }
        nodeSize = @{
            width = 200
            height = 80
        }
        orientation = "vertical"  # vertical ou horizontal
        nodeRadius = 5
        linkStroke = "#ccc"
        linkStrokeWidth = 1.5
        transitionDuration = 750
        statusColors = @{
            "À faire" = "#D3D3D3"
            "En cours" = "#4A86E8"
            "Bloqué" = "#E74C3C"
            "Terminé" = "#2ECC71"
        }
        priorityColors = @{
            "Basse" = "#A9DFBF"
            "Moyenne" = "#F9E79F"
            "Haute" = "#F5B041"
            "Critique" = "#E74C3C"
        }
    }

    # Fusionner les options par défaut avec les options fournies
    foreach ($key in $Options.Keys) {
        if ($key -eq "margin" -or $key -eq "nodeSize" -or $key -eq "statusColors" -or $key -eq "priorityColors") {
            foreach ($subKey in $Options[$key].Keys) {
                $defaultOptions[$key][$subKey] = $Options[$key][$subKey]
            }
        }
        else {
            $defaultOptions[$key] = $Options[$key]
        }
    }

    $options = $defaultOptions

    # Convertir les données hiérarchiques en format JSON pour D3.js
    $jsonData = $HierarchyData.ToJson()

    # Générer le code JavaScript pour D3.js
    $d3Code = @"
// Données du diagramme hiérarchique
const hierarchyData = $jsonData;

// Configuration
const width = $($options.width);
const height = $($options.height);
const margin = {
    top: $($options.margin.top),
    right: $($options.margin.right),
    bottom: $($options.margin.bottom),
    left: $($options.margin.left)
};
const nodeWidth = $($options.nodeSize.width);
const nodeHeight = $($options.nodeSize.height);
const orientation = "$($options.orientation)";

// Créer le conteneur SVG
const svg = d3.select("#hierarchy-container")
    .append("svg")
    .attr("width", width)
    .attr("height", height)
    .append("g")
    .attr("transform", `translate(\${margin.left},\${margin.top})`);

// Définir les couleurs de statut et priorité
const statusColors = {
    "À faire": "$($options.statusColors["À faire"])",
    "En cours": "$($options.statusColors["En cours"])",
    "Bloqué": "$($options.statusColors["Bloqué"])",
    "Terminé": "$($options.statusColors["Terminé"])"
};

const priorityColors = {
    "Basse": "$($options.priorityColors["Basse"])",
    "Moyenne": "$($options.priorityColors["Moyenne"])",
    "Haute": "$($options.priorityColors["Haute"])",
    "Critique": "$($options.priorityColors["Critique"])"
};

// Créer la hiérarchie D3
const root = d3.hierarchy(hierarchyData);

// Définir le layout de l'arbre
let treeLayout;
if (orientation === "vertical") {
    treeLayout = d3.tree()
        .size([width - margin.left - margin.right, height - margin.top - margin.bottom]);
} else {
    treeLayout = d3.tree()
        .size([height - margin.top - margin.bottom, width - margin.left - margin.right]);
}

// Calculer les positions des nœuds
treeLayout(root);

// Créer les liens entre les nœuds
let linkGenerator;
if (orientation === "vertical") {
    linkGenerator = d3.linkVertical()
        .x(d => d.x)
        .y(d => d.y);
} else {
    linkGenerator = d3.linkHorizontal()
        .x(d => d.y)
        .y(d => d.x);
}

// Ajouter les liens
svg.selectAll(".link")
    .data(root.links())
    .enter()
    .append("path")
    .attr("class", "link")
    .attr("d", linkGenerator)
    .attr("fill", "none")
    .attr("stroke", "$($options.linkStroke)")
    .attr("stroke-width", $($options.linkStrokeWidth));

// Créer les groupes de nœuds
const nodes = svg.selectAll(".node")
    .data(root.descendants())
    .enter()
    .append("g")
    .attr("class", d => `node \${d.children ? "node--internal" : "node--leaf"}`)
    .attr("transform", d => {
        if (orientation === "vertical") {
            return `translate(\${d.x},\${d.y})`;
        } else {
            return `translate(\${d.y},\${d.x})`;
        }
    })
    .on("click", function(event, d) {
        // Toggle des enfants au clic
        if (d.children) {
            d._children = d.children;
            d.children = null;
        } else {
            d.children = d._children;
            d._children = null;
        }
        update(d);
    });

// Ajouter les rectangles des nœuds
nodes.append("rect")
    .attr("width", nodeWidth)
    .attr("height", nodeHeight)
    .attr("x", -nodeWidth / 2)
    .attr("y", -nodeHeight / 2)
    .attr("rx", $($options.nodeRadius))
    .attr("ry", $($options.nodeRadius))
    .attr("fill", d => statusColors[d.data.status] || "#ccc")
    .attr("stroke", d => priorityColors[d.data.priority] || "#999")
    .attr("stroke-width", 3);

// Ajouter les identifiants
nodes.append("text")
    .attr("x", -nodeWidth / 2 + 10)
    .attr("y", -nodeHeight / 2 + 15)
    .attr("font-size", "10px")
    .attr("fill", "#666")
    .text(d => d.data.id);

// Ajouter les titres
nodes.append("text")
    .attr("x", 0)
    .attr("y", 0)
    .attr("text-anchor", "middle")
    .attr("dominant-baseline", "middle")
    .attr("font-weight", "bold")
    .attr("fill", "#333")
    .text(d => {
        // Tronquer le titre s'il est trop long
        const maxLength = 25;
        return d.data.title.length > maxLength 
            ? d.data.title.substring(0, maxLength) + "..." 
            : d.data.title;
    });

// Ajouter les barres de progression
nodes.append("rect")
    .attr("class", "progress-bar-bg")
    .attr("width", nodeWidth - 20)
    .attr("height", 5)
    .attr("x", -nodeWidth / 2 + 10)
    .attr("y", nodeHeight / 2 - 10)
    .attr("rx", 2)
    .attr("ry", 2)
    .attr("fill", "#eee");

nodes.append("rect")
    .attr("class", "progress-bar")
    .attr("width", d => (nodeWidth - 20) * (d.data.progress / 100))
    .attr("height", 5)
    .attr("x", -nodeWidth / 2 + 10)
    .attr("y", nodeHeight / 2 - 10)
    .attr("rx", 2)
    .attr("ry", 2)
    .attr("fill", d => {
        // Couleur basée sur la progression
        if (d.data.progress < 30) return "#E74C3C";
        if (d.data.progress < 70) return "#F5B041";
        return "#2ECC71";
    });

// Ajouter le pourcentage de progression
nodes.append("text")
    .attr("x", nodeWidth / 2 - 25)
    .attr("y", nodeHeight / 2 - 12)
    .attr("font-size", "10px")
    .attr("fill", "#666")
    .text(d => `\${d.data.progress}%`);

// Fonction pour mettre à jour le diagramme
function update(source) {
    // Transition
    const transition = svg.transition()
        .duration($($options.transitionDuration));

    // Recalculer le layout
    treeLayout(root);

    // Mettre à jour les liens
    svg.selectAll(".link")
        .data(root.links())
        .join(
            enter => enter.append("path")
                .attr("class", "link")
                .attr("d", linkGenerator)
                .attr("fill", "none")
                .attr("stroke", "$($options.linkStroke)")
                .attr("stroke-width", $($options.linkStrokeWidth))
                .attr("opacity", 0)
                .call(enter => enter.transition(transition)
                    .attr("opacity", 1)),
            update => update.transition(transition)
                .attr("d", linkGenerator),
            exit => exit.transition(transition)
                .attr("opacity", 0)
                .remove()
        );

    // Mettre à jour les nœuds
    svg.selectAll(".node")
        .data(root.descendants())
        .join(
            enter => enter.append("g")
                .attr("class", d => `node \${d.children ? "node--internal" : "node--leaf"}`)
                .attr("transform", d => {
                    if (orientation === "vertical") {
                        return `translate(\${source.x},\${source.y})`;
                    } else {
                        return `translate(\${source.y},\${source.x})`;
                    }
                })
                .attr("opacity", 0)
                .call(enter => {
                    // Ajouter les rectangles
                    enter.append("rect")
                        .attr("width", nodeWidth)
                        .attr("height", nodeHeight)
                        .attr("x", -nodeWidth / 2)
                        .attr("y", -nodeHeight / 2)
                        .attr("rx", $($options.nodeRadius))
                        .attr("ry", $($options.nodeRadius))
                        .attr("fill", d => statusColors[d.data.status] || "#ccc")
                        .attr("stroke", d => priorityColors[d.data.priority] || "#999")
                        .attr("stroke-width", 3);

                    // Ajouter les identifiants
                    enter.append("text")
                        .attr("x", -nodeWidth / 2 + 10)
                        .attr("y", -nodeHeight / 2 + 15)
                        .attr("font-size", "10px")
                        .attr("fill", "#666")
                        .text(d => d.data.id);

                    // Ajouter les titres
                    enter.append("text")
                        .attr("x", 0)
                        .attr("y", 0)
                        .attr("text-anchor", "middle")
                        .attr("dominant-baseline", "middle")
                        .attr("font-weight", "bold")
                        .attr("fill", "#333")
                        .text(d => {
                            const maxLength = 25;
                            return d.data.title.length > maxLength 
                                ? d.data.title.substring(0, maxLength) + "..." 
                                : d.data.title;
                        });

                    // Ajouter les barres de progression
                    enter.append("rect")
                        .attr("class", "progress-bar-bg")
                        .attr("width", nodeWidth - 20)
                        .attr("height", 5)
                        .attr("x", -nodeWidth / 2 + 10)
                        .attr("y", nodeHeight / 2 - 10)
                        .attr("rx", 2)
                        .attr("ry", 2)
                        .attr("fill", "#eee");

                    enter.append("rect")
                        .attr("class", "progress-bar")
                        .attr("width", d => (nodeWidth - 20) * (d.data.progress / 100))
                        .attr("height", 5)
                        .attr("x", -nodeWidth / 2 + 10)
                        .attr("y", nodeHeight / 2 - 10)
                        .attr("rx", 2)
                        .attr("ry", 2)
                        .attr("fill", d => {
                            if (d.data.progress < 30) return "#E74C3C";
                            if (d.data.progress < 70) return "#F5B041";
                            return "#2ECC71";
                        });

                    // Ajouter le pourcentage de progression
                    enter.append("text")
                        .attr("x", nodeWidth / 2 - 25)
                        .attr("y", nodeHeight / 2 - 12)
                        .attr("font-size", "10px")
                        .attr("fill", "#666")
                        .text(d => `\${d.data.progress}%`);

                    // Animer l'entrée
                    enter.transition(transition)
                        .attr("transform", d => {
                            if (orientation === "vertical") {
                                return `translate(\${d.x},\${d.y})`;
                            } else {
                                return `translate(\${d.y},\${d.x})`;
                            }
                        })
                        .attr("opacity", 1);
                }),
            update => update.transition(transition)
                .attr("transform", d => {
                    if (orientation === "vertical") {
                        return `translate(\${d.x},\${d.y})`;
                    } else {
                        return `translate(\${d.y},\${d.x})`;
                    }
                })
                .attr("opacity", 1)
                .selection()
                .select(".progress-bar")
                .transition(transition)
                .attr("width", d => (nodeWidth - 20) * (d.data.progress / 100)),
            exit => exit.transition(transition)
                .attr("transform", d => {
                    if (orientation === "vertical") {
                        return `translate(\${source.x},\${source.y})`;
                    } else {
                        return `translate(\${source.y},\${source.x})`;
                    }
                })
                .attr("opacity", 0)
                .remove()
        );
}
"@

    return $d3Code
}

# Fonction pour générer le code Mermaid pour le diagramme hiérarchique
function Convert-HierarchyToMermaid {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [HierarchicalNode]$HierarchyData,

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{}
    )

    # Options par défaut
    $defaultOptions = @{
        direction = "TD"  # TD (top-down) ou LR (left-right)
        includeStatus = $true
        includePriority = $true
        includeProgress = $true
        maxDepth = 5  # Profondeur maximale à afficher
    }

    # Fusionner les options par défaut avec les options fournies
    foreach ($key in $Options.Keys) {
        $defaultOptions[$key] = $Options[$key]
    }

    $options = $defaultOptions

    # Générer le code Mermaid
    $mermaidCode = "graph $($options.direction)`n"

    # Fonction récursive pour ajouter les nœuds et les liens
    function Add-MermaidNodes {
        param (
            [Parameter(Mandatory = $true)]
            [HierarchicalNode]$Node,

            [Parameter(Mandatory = $true)]
            [int]$CurrentDepth,

            [Parameter(Mandatory = $false)]
            [string]$ParentId = ""
        )

        # Vérifier la profondeur maximale
        if ($CurrentDepth > $options.maxDepth) {
            return
        }

        # Créer l'identifiant Mermaid (remplacer les caractères spéciaux)
        $mermaidId = $Node.Id -replace '\.', '_'

        # Déterminer le style du nœud en fonction du statut
        $style = ""
        switch ($Node.Status) {
            "Terminé" { $style = "fill:#2ECC71,stroke:#27AE60" }
            "En cours" { $style = "fill:#4A86E8,stroke:#3A76D8" }
            "Bloqué" { $style = "fill:#E74C3C,stroke:#C0392B" }
            default { $style = "fill:#D3D3D3,stroke:#A9A9A9" }
        }

        # Ajouter la priorité au style si demandé
        if ($options.includePriority) {
            $borderWidth = switch ($Node.Priority) {
                "Critique" { 4 }
                "Haute" { 3 }
                "Moyenne" { 2 }
                default { 1 }
            }
            $style += ",stroke-width:$borderWidth"
        }

        # Construire le label du nœud
        $label = $Node.Title

        # Ajouter le statut si demandé
        if ($options.includeStatus) {
            $label += "<br>[$($Node.Status)]"
        }

        # Ajouter la progression si demandée
        if ($options.includeProgress) {
            $label += "<br>$($Node.Progress)%"
        }

        # Ajouter le nœud au code Mermaid
        $mermaidCode += "    $mermaidId[$label]:::$($Node.Status.ToLower()) style $mermaidId {$style}`n"

        # Ajouter le lien avec le parent si ce n'est pas le nœud racine
        if ($ParentId -ne "") {
            $mermaidCode += "    $ParentId --> $mermaidId`n"
        }

        # Traiter les enfants récursivement
        foreach ($child in $Node.Children) {
            $mermaidCode = Add-MermaidNodes -Node $child -CurrentDepth ($CurrentDepth + 1) -ParentId $mermaidId
        }

        return $mermaidCode
    }

    # Générer le code Mermaid pour l'ensemble de la hiérarchie
    $mermaidCode = Add-MermaidNodes -Node $HierarchyData -CurrentDepth 0

    # Ajouter les classes pour les statuts
    $mermaidCode += "`n    classDef terminé fill:#2ECC71,stroke:#27AE60,color:white"
    $mermaidCode += "`n    classDef encours fill:#4A86E8,stroke:#3A76D8,color:white"
    $mermaidCode += "`n    classDef bloqué fill:#E74C3C,stroke:#C0392B,color:white"
    $mermaidCode += "`n    classDef àfaire fill:#D3D3D3,stroke:#A9A9A9,color:black"

    return $mermaidCode
}

# Fonction principale pour générer un diagramme hiérarchique
function New-HierarchicalDiagram {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapFilePath,

        [Parameter(Mandatory = $false)]
        [VisualizationTechnology]$Technology = [VisualizationTechnology]::D3js,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{},

        [Parameter(Mandatory = $false)]
        [switch]$IncludeCompleted = $true
    )

    # Vérifier que le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapFilePath)) {
        Write-Error "Le fichier de roadmap '$RoadmapFilePath' est introuvable."
        return $null
    }

    # Analyser le fichier de roadmap
    $roadmapData = Parse-RoadmapFile -FilePath $RoadmapFilePath

    # Convertir les données en structure hiérarchique
    $hierarchyData = Convert-RoadmapToHierarchy -RoadmapData $roadmapData -IncludeCompleted:$IncludeCompleted

    # Générer le code de visualisation selon la technologie choisie
    $visualizationCode = ""
    $fileExtension = ""

    switch ($Technology) {
        ([VisualizationTechnology]::D3js) {
            $visualizationCode = Convert-HierarchyToD3 -HierarchyData $hierarchyData -Options $Options
            $fileExtension = "js"
        }
        ([VisualizationTechnology]::Mermaid) {
            $visualizationCode = Convert-HierarchyToMermaid -HierarchyData $hierarchyData -Options $Options
            $fileExtension = "mmd"
        }
        default {
            Write-Error "Technologie de visualisation non prise en charge: $Technology"
            return $null
        }
    }

    # Enregistrer le code généré si un chemin de sortie est spécifié
    if ($OutputPath) {
        $outputFilePath = if ($OutputPath -match "\.$fileExtension$") {
            $OutputPath
        }
        else {
            Join-Path -Path $OutputPath -ChildPath "hierarchical_diagram.$fileExtension"
        }

        $visualizationCode | Out-File -FilePath $outputFilePath -Encoding utf8
        Write-Host "Diagramme hiérarchique généré avec succès: $outputFilePath"
    }

    return $visualizationCode
}

# Exporter les fonctions
Export-ModuleMember -Function New-HierarchicalDiagram, Convert-RoadmapToHierarchy, Convert-HierarchyToD3, Convert-HierarchyToMermaid
