# VisualizationTechnologies.ps1
# Script définissant les technologies de visualisation pour les roadmaps
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Définit les technologies de visualisation pour les roadmaps.

.DESCRIPTION
    Ce script définit les technologies de visualisation pour les roadmaps,
    notamment D3.js, Mermaid et Chart.js, avec leurs caractéristiques,
    avantages et cas d'utilisation recommandés.

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

# Importer les types de visualisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$visualizationTypesPath = Join-Path -Path $scriptPath -ChildPath "VisualizationTypes.ps1"

if (Test-Path -Path $visualizationTypesPath) {
    . $visualizationTypesPath
}
else {
    Write-Error "Le fichier VisualizationTypes.ps1 est introuvable."
    exit 1
}

# Structure définissant les propriétés d'une technologie de visualisation
class VisualizationTechnologyDefinition {
    [string]$Name
    [string]$Description
    [VisualizationTechnology]$Technology
    [string]$Version
    [string]$Website
    [string]$DocumentationUrl
    [string]$CDNUrl
    [string]$NPMPackage
    [string[]]$Dependencies
    [hashtable]$Advantages
    [hashtable]$Limitations
    [VisualizationType[]]$RecommendedForTypes
    [hashtable]$ConfigurationOptions

    # Constructeur
    VisualizationTechnologyDefinition(
        [string]$name,
        [string]$description,
        [VisualizationTechnology]$technology,
        [string]$version,
        [string]$website
    ) {
        $this.Name = $name
        $this.Description = $description
        $this.Technology = $technology
        $this.Version = $version
        $this.Website = $website
        $this.DocumentationUrl = ""
        $this.CDNUrl = ""
        $this.NPMPackage = ""
        $this.Dependencies = @()
        $this.Advantages = @{}
        $this.Limitations = @{}
        $this.RecommendedForTypes = @()
        $this.ConfigurationOptions = @{}
    }

    # Méthode pour vérifier si la technologie est recommandée pour un type de visualisation
    [bool] IsRecommendedFor([VisualizationType]$type) {
        return $this.RecommendedForTypes -contains $type
    }

    # Méthode pour obtenir les options de configuration
    [hashtable] GetConfigurationOptions([VisualizationType]$type) {
        if ($this.ConfigurationOptions.ContainsKey($type)) {
            return $this.ConfigurationOptions[$type]
        }
        
        return @{}
    }

    # Méthode pour obtenir le script d'initialisation
    [string] GetInitializationScript([VisualizationType]$type, [hashtable]$options = @{}) {
        $script = "// Initialisation de $($this.Name) pour $type`n"
        
        switch ($this.Technology) {
            ([VisualizationTechnology]::D3js) {
                $script += "import * as d3 from 'd3';"
                $script += "`n`nconst svg = d3.select('#visualization-container').append('svg')"
                $script += "`n  .attr('width', width)"
                $script += "`n  .attr('height', height);"
            }
            
            ([VisualizationTechnology]::Mermaid) {
                $script += "<div class='mermaid'>"
                
                switch ($type) {
                    ([VisualizationType]::HierarchicalDiagram) {
                        $script += "`n  graph TD;"
                        $script += "`n  %% Contenu du diagramme hiérarchique"
                    }
                    
                    ([VisualizationType]::GanttChart) {
                        $script += "`n  gantt"
                        $script += "`n    title Diagramme de Gantt"
                        $script += "`n    dateFormat YYYY-MM-DD"
                        $script += "`n    %% Contenu du diagramme de Gantt"
                    }
                    
                    default {
                        $script += "`n  %% Type de diagramme non supporté par Mermaid"
                    }
                }
                
                $script += "`n</div>"
                $script += "`n`n<script>"
                $script += "`n  mermaid.initialize({ startOnLoad: true });"
                $script += "`n</script>"
            }
            
            ([VisualizationTechnology]::ChartJs) {
                $script += "<canvas id='visualization-chart'></canvas>"
                $script += "`n`n<script>"
                $script += "`n  const ctx = document.getElementById('visualization-chart').getContext('2d');"
                $script += "`n  const chart = new Chart(ctx, {"
                $script += "`n    type: 'treemap',"  # Type par défaut pour PriorityHeatmap
                $script += "`n    data: { /* Données à remplir */ },"
                $script += "`n    options: { /* Options à configurer */ }"
                $script += "`n  });"
                $script += "`n</script>"
            }
            
            default {
                $script += "// Technologie non reconnue"
            }
        }
        
        return $script
    }
}

# Définition des technologies de visualisation disponibles
$script:VisualizationTechnologies = @{
    # D3.js
    D3js = [VisualizationTechnologyDefinition]::new(
        "D3.js",
        "Bibliothèque JavaScript puissante et flexible pour la visualisation de données.",
        [VisualizationTechnology]::D3js,
        "7.8.5",
        "https://d3js.org/"
    )

    # Mermaid
    Mermaid = [VisualizationTechnologyDefinition]::new(
        "Mermaid",
        "Outil de génération de diagrammes et graphiques à partir d'une syntaxe similaire à Markdown.",
        [VisualizationTechnology]::Mermaid,
        "10.2.4",
        "https://mermaid.js.org/"
    )

    # Chart.js
    ChartJs = [VisualizationTechnologyDefinition]::new(
        "Chart.js",
        "Bibliothèque JavaScript simple et flexible pour créer des graphiques interactifs.",
        [VisualizationTechnology]::ChartJs,
        "4.3.0",
        "https://www.chartjs.org/"
    )
}

# Configuration des propriétés supplémentaires pour chaque technologie

# D3.js
$script:VisualizationTechnologies.D3js.DocumentationUrl = "https://d3js.org/getting-started"
$script:VisualizationTechnologies.D3js.CDNUrl = "https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js"
$script:VisualizationTechnologies.D3js.NPMPackage = "d3"
$script:VisualizationTechnologies.D3js.Dependencies = @()
$script:VisualizationTechnologies.D3js.Advantages = @{
    Flexibilité = "Contrôle total sur tous les aspects de la visualisation"
    Performance = "Excellente performance même avec de grands ensembles de données"
    Écosystème = "Large communauté et nombreux exemples disponibles"
    Interactivité = "Capacités avancées d'interaction et d'animation"
}
$script:VisualizationTechnologies.D3js.Limitations = @{
    Complexité = "Courbe d'apprentissage abrupte"
    TempsDedéveloppement = "Nécessite plus de temps pour implémenter des visualisations"
    Abstraction = "Niveau d'abstraction bas, nécessite beaucoup de code"
}
$script:VisualizationTechnologies.D3js.RecommendedForTypes = @(
    [VisualizationType]::HierarchicalDiagram,
    [VisualizationType]::DependencyGraph,
    [VisualizationType]::GanttChart,
    [VisualizationType]::PriorityHeatmap
)
$script:VisualizationTechnologies.D3js.ConfigurationOptions = @{
    ([VisualizationType]::HierarchicalDiagram) = @{
        margin = @{top = 20; right = 90; bottom = 30; left = 90}
        nodeRadius = 5
        linkStroke = "#ccc"
        linkStrokeWidth = 1.5
        transitionDuration = 750
    }
    ([VisualizationType]::DependencyGraph) = @{
        forceStrength = 0.05
        forceDistance = 100
        nodeFill = "#69b3a2"
        nodeStroke = "#fff"
        nodeStrokeWidth = 2
        arrowSize = 10
    }
    ([VisualizationType]::GanttChart) = @{
        barHeight = 20
        barPadding = 5
        timeFormat = "%Y-%m-%d"
        axisHeight = 50
        tooltipEnabled = $true
    }
    ([VisualizationType]::PriorityHeatmap) = @{
        colorRange = @("#d8e1e8", "#97b4c9", "#4281a4", "#2c4a52")
        padding = 1
        borderRadius = 4
        textColor = "#fff"
        textShadow = "0 1px 2px rgba(0,0,0,0.5)"
    }
}

# Mermaid
$script:VisualizationTechnologies.Mermaid.DocumentationUrl = "https://mermaid.js.org/intro/"
$script:VisualizationTechnologies.Mermaid.CDNUrl = "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"
$script:VisualizationTechnologies.Mermaid.NPMPackage = "mermaid"
$script:VisualizationTechnologies.Mermaid.Dependencies = @()
$script:VisualizationTechnologies.Mermaid.Advantages = @{
    Simplicité = "Syntaxe simple basée sur le texte"
    IntégrationMarkdown = "Intégration facile dans les documents Markdown"
    RenduStatique = "Génération de diagrammes sans JavaScript côté client"
    SupportNatif = "Prise en charge native des diagrammes de Gantt et des organigrammes"
}
$script:VisualizationTechnologies.Mermaid.Limitations = @{
    Personnalisation = "Options de personnalisation limitées"
    Interactivité = "Capacités d'interaction réduites"
    ComplexitéDesGraphes = "Difficile à utiliser pour des graphes très complexes"
}
$script:VisualizationTechnologies.Mermaid.RecommendedForTypes = @(
    [VisualizationType]::HierarchicalDiagram,
    [VisualizationType]::GanttChart
)
$script:VisualizationTechnologies.Mermaid.ConfigurationOptions = @{
    ([VisualizationType]::HierarchicalDiagram) = @{
        theme = "default"
        flowchart = @{
            htmlLabels = $true
            curve = "basis"
        }
    }
    ([VisualizationType]::GanttChart) = @{
        theme = "default"
        gantt = @{
            titleTopMargin = 25
            barHeight = 20
            barGap = 4
            topPadding = 50
            sidePadding = 75
        }
    }
}

# Chart.js
$script:VisualizationTechnologies.ChartJs.DocumentationUrl = "https://www.chartjs.org/docs/latest/"
$script:VisualizationTechnologies.ChartJs.CDNUrl = "https://cdn.jsdelivr.net/npm/chart.js"
$script:VisualizationTechnologies.ChartJs.NPMPackage = "chart.js"
$script:VisualizationTechnologies.ChartJs.Dependencies = @("chartjs-chart-treemap")
$script:VisualizationTechnologies.ChartJs.Advantages = @{
    Simplicité = "API simple et intuitive"
    Performance = "Bonne performance avec des ensembles de données moyens"
    Responsive = "Responsive et compatible mobile par défaut"
    Animation = "Animations fluides et esthétique moderne"
}
$script:VisualizationTechnologies.ChartJs.Limitations = @{
    TypesDeGraphes = "Types de visualisations limités par défaut"
    Personnalisation = "Personnalisation avancée plus difficile qu'avec D3.js"
    GrandsEnsemblesDeDonnées = "Performance réduite avec de très grands ensembles de données"
}
$script:VisualizationTechnologies.ChartJs.RecommendedForTypes = @(
    [VisualizationType]::PriorityHeatmap
)
$script:VisualizationTechnologies.ChartJs.ConfigurationOptions = @{
    ([VisualizationType]::PriorityHeatmap) = @{
        plugins = @{
            title = @{
                display = $true
                text = "Carte de chaleur des priorités"
            }
            tooltip = @{
                enabled = $true
            }
            legend = @{
                display = $true
                position = "bottom"
            }
        }
        treemap = @{
            captions = @{
                display = $true
                color = "white"
            }
            labels = @{
                display = $true
            }
        }
    }
}

# Fonction pour obtenir toutes les technologies de visualisation
function Get-VisualizationTechnologies {
    [CmdletBinding()]
    param()
    
    return $script:VisualizationTechnologies
}

# Fonction pour obtenir une technologie de visualisation spécifique
function Get-VisualizationTechnology {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [VisualizationTechnology]$Technology
    )
    
    switch ($Technology) {
        ([VisualizationTechnology]::D3js) { return $script:VisualizationTechnologies.D3js }
        ([VisualizationTechnology]::Mermaid) { return $script:VisualizationTechnologies.Mermaid }
        ([VisualizationTechnology]::ChartJs) { return $script:VisualizationTechnologies.ChartJs }
        default {
            Write-Error "Technologie de visualisation non reconnue: $Technology"
            return $null
        }
    }
}

# Fonction pour obtenir les technologies recommandées pour un type de visualisation
function Get-TechnologiesForVisualizationType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [VisualizationType]$Type
    )
    
    $recommendedTechnologies = @()
    
    foreach ($tech in $script:VisualizationTechnologies.Values) {
        if ($tech.IsRecommendedFor($Type)) {
            $recommendedTechnologies += $tech
        }
    }
    
    return $recommendedTechnologies
}

# Fonction pour générer un script d'initialisation pour une visualisation
function Get-VisualizationInitScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [VisualizationType]$Type,
        
        [Parameter(Mandatory = $true)]
        [VisualizationTechnology]$Technology,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Options = @{}
    )
    
    $tech = Get-VisualizationTechnology -Technology $Technology
    
    if ($null -eq $tech) {
        Write-Error "Technologie non reconnue: $Technology"
        return ""
    }
    
    if (-not $tech.IsRecommendedFor($Type)) {
        Write-Warning "La technologie $Technology n'est pas recommandée pour le type de visualisation $Type"
    }
    
    return $tech.GetInitializationScript($Type, $Options)
}

# Exporter les fonctions
Export-ModuleMember -Function Get-VisualizationTechnologies, Get-VisualizationTechnology, Get-TechnologiesForVisualizationType, Get-VisualizationInitScript
