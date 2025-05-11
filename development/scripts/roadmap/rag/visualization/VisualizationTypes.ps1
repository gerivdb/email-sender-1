# VisualizationTypes.ps1
# Script définissant les types de visualisations pour les roadmaps
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Définit les types de visualisations graphiques pour les roadmaps.

.DESCRIPTION
    Ce script définit les types de visualisations graphiques pour les roadmaps,
    notamment les diagrammes hiérarchiques, les diagrammes de Gantt, les graphes
    de dépendances et les cartes de chaleur des priorités.

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-05-15
    Version: 1.0
#>

# Énumération des types de visualisations
enum VisualizationType {
    HierarchicalDiagram  # Diagramme hiérarchique (arborescence)
    GanttChart           # Diagramme de Gantt simplifié
    DependencyGraph      # Graphe de dépendances
    PriorityHeatmap      # Carte de chaleur des priorités
}

# Énumération des technologies de visualisation
enum VisualizationTechnology {
    D3js      # D3.js - Bibliothèque JavaScript pour visualisations complexes
    Mermaid   # Mermaid - Génération de diagrammes à partir de texte
    ChartJs   # Chart.js - Bibliothèque JavaScript pour graphiques simples
    Custom    # Implémentation personnalisée
}

# Énumération des niveaux d'interactivité
enum InteractivityLevel {
    Basic        # Niveau 1: Interactivité basique
    Intermediate # Niveau 2: Interactivité intermédiaire
    Advanced     # Niveau 3: Interactivité avancée
}

# Structure définissant les propriétés d'un type de visualisation
class VisualizationTypeDefinition {
    [string]$Name
    [string]$Description
    [VisualizationType]$Type
    [VisualizationTechnology[]]$SupportedTechnologies
    [InteractivityLevel]$DefaultInteractivityLevel
    [hashtable]$DefaultOptions
    [string[]]$RequiredDataFields
    [string[]]$OptionalDataFields
    [string]$DefaultTemplate
    [string]$DocumentationUrl

    # Constructeur
    VisualizationTypeDefinition(
        [string]$name,
        [string]$description,
        [VisualizationType]$type,
        [VisualizationTechnology[]]$supportedTechnologies,
        [InteractivityLevel]$defaultInteractivityLevel
    ) {
        $this.Name = $name
        $this.Description = $description
        $this.Type = $type
        $this.SupportedTechnologies = $supportedTechnologies
        $this.DefaultInteractivityLevel = $defaultInteractivityLevel
        $this.DefaultOptions = @{}
        $this.RequiredDataFields = @()
        $this.OptionalDataFields = @()
        $this.DefaultTemplate = ""
        $this.DocumentationUrl = ""
    }

    # Méthode pour vérifier si une technologie est supportée
    [bool] SupportsTechnology([VisualizationTechnology]$technology) {
        return $this.SupportedTechnologies -contains $technology
    }

    # Méthode pour obtenir les options de configuration
    [hashtable] GetOptions([hashtable]$customOptions = @{}) {
        $options = $this.DefaultOptions.Clone()
        
        foreach ($key in $customOptions.Keys) {
            $options[$key] = $customOptions[$key]
        }
        
        return $options
    }

    # Méthode pour valider les données
    [bool] ValidateData([hashtable]$data) {
        foreach ($field in $this.RequiredDataFields) {
            if (-not $data.ContainsKey($field)) {
                Write-Warning "Champ requis manquant: $field"
                return $false
            }
        }
        
        return $true
    }
}

# Définition des types de visualisations disponibles
$script:VisualizationTypes = @{
    # Diagramme hiérarchique (arborescence)
    HierarchicalDiagram = [VisualizationTypeDefinition]::new(
        "Diagramme Hiérarchique",
        "Représentation visuelle de la structure hiérarchique des tâches de la roadmap, montrant les relations parent-enfant entre les tâches.",
        [VisualizationType]::HierarchicalDiagram,
        @([VisualizationTechnology]::D3js, [VisualizationTechnology]::Mermaid),
        [InteractivityLevel]::Intermediate
    )

    # Diagramme de Gantt simplifié
    GanttChart = [VisualizationTypeDefinition]::new(
        "Diagramme de Gantt",
        "Représentation temporelle des tâches, montrant leur durée prévue, dates de début et de fin, ainsi que les dépendances temporelles.",
        [VisualizationType]::GanttChart,
        @([VisualizationTechnology]::D3js, [VisualizationTechnology]::Mermaid),
        [InteractivityLevel]::Intermediate
    )

    # Graphe de dépendances
    DependencyGraph = [VisualizationTypeDefinition]::new(
        "Graphe de Dépendances",
        "Visualisation des relations de dépendance entre les tâches, indépendamment de leur position dans la hiérarchie.",
        [VisualizationType]::DependencyGraph,
        @([VisualizationTechnology]::D3js),
        [InteractivityLevel]::Advanced
    )

    # Carte de chaleur des priorités
    PriorityHeatmap = [VisualizationTypeDefinition]::new(
        "Carte de Chaleur des Priorités",
        "Visualisation de la distribution des priorités dans la roadmap, permettant d'identifier rapidement les zones nécessitant une attention particulière.",
        [VisualizationType]::PriorityHeatmap,
        @([VisualizationTechnology]::D3js, [VisualizationTechnology]::ChartJs),
        [InteractivityLevel]::Basic
    )
}

# Configuration des propriétés supplémentaires pour chaque type de visualisation

# Diagramme hiérarchique
$script:VisualizationTypes.HierarchicalDiagram.RequiredDataFields = @("id", "title", "status", "parentId")
$script:VisualizationTypes.HierarchicalDiagram.OptionalDataFields = @("priority", "progress", "description", "tags")
$script:VisualizationTypes.HierarchicalDiagram.DefaultOptions = @{
    orientation = "vertical"  # vertical ou horizontal
    nodeSize = @{width = 200; height = 80}
    showStatus = $true
    showPriority = $true
    showProgress = $true
    expandToLevel = 2  # Niveau d'expansion par défaut
    colorScheme = "status"  # status, priority, ou custom
}
$script:VisualizationTypes.HierarchicalDiagram.DefaultTemplate = "templates/hierarchical-diagram.html"
$script:VisualizationTypes.HierarchicalDiagram.DocumentationUrl = "docs/visualizations/hierarchical-diagram.md"

# Diagramme de Gantt
$script:VisualizationTypes.GanttChart.RequiredDataFields = @("id", "title", "status")
$script:VisualizationTypes.GanttChart.OptionalDataFields = @("startDate", "dueDate", "completionDate", "dependencies", "progress")
$script:VisualizationTypes.GanttChart.DefaultOptions = @{
    timeUnit = "day"  # day, week, month
    showToday = $true
    showProgress = $true
    showDependencies = $true
    groupBy = "none"  # none, category, priority
    barHeight = 30
    barSpacing = 10
}
$script:VisualizationTypes.GanttChart.DefaultTemplate = "templates/gantt-chart.html"
$script:VisualizationTypes.GanttChart.DocumentationUrl = "docs/visualizations/gantt-chart.md"

# Graphe de dépendances
$script:VisualizationTypes.DependencyGraph.RequiredDataFields = @("id", "title", "dependencies")
$script:VisualizationTypes.DependencyGraph.OptionalDataFields = @("status", "priority", "category")
$script:VisualizationTypes.DependencyGraph.DefaultOptions = @{
    layout = "force"  # force, radial, hierarchical
    nodeSize = @{width = 150; height = 60}
    showLabels = $true
    highlightCriticalPath = $true
    detectCycles = $true
    directedEdges = $true
}
$script:VisualizationTypes.DependencyGraph.DefaultTemplate = "templates/dependency-graph.html"
$script:VisualizationTypes.DependencyGraph.DocumentationUrl = "docs/visualizations/dependency-graph.md"

# Carte de chaleur des priorités
$script:VisualizationTypes.PriorityHeatmap.RequiredDataFields = @("id", "title", "priority")
$script:VisualizationTypes.PriorityHeatmap.OptionalDataFields = @("status", "category", "tags", "progress")
$script:VisualizationTypes.PriorityHeatmap.DefaultOptions = @{
    layout = "treemap"  # treemap, grid
    colorScale = "sequential"  # sequential, diverging
    groupBy = "category"  # category, status, none
    showLabels = $true
    labelThreshold = 30  # Taille minimale pour afficher les labels
}
$script:VisualizationTypes.PriorityHeatmap.DefaultTemplate = "templates/priority-heatmap.html"
$script:VisualizationTypes.PriorityHeatmap.DocumentationUrl = "docs/visualizations/priority-heatmap.md"

# Fonction pour obtenir tous les types de visualisations
function Get-VisualizationTypes {
    [CmdletBinding()]
    param()
    
    return $script:VisualizationTypes
}

# Fonction pour obtenir un type de visualisation spécifique
function Get-VisualizationType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [VisualizationType]$Type
    )
    
    switch ($Type) {
        ([VisualizationType]::HierarchicalDiagram) { return $script:VisualizationTypes.HierarchicalDiagram }
        ([VisualizationType]::GanttChart) { return $script:VisualizationTypes.GanttChart }
        ([VisualizationType]::DependencyGraph) { return $script:VisualizationTypes.DependencyGraph }
        ([VisualizationType]::PriorityHeatmap) { return $script:VisualizationTypes.PriorityHeatmap }
        default {
            Write-Error "Type de visualisation non reconnu: $Type"
            return $null
        }
    }
}

# Fonction pour obtenir les technologies recommandées pour un type de visualisation
function Get-RecommendedTechnologies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [VisualizationType]$Type
    )
    
    $visualizationType = Get-VisualizationType -Type $Type
    
    if ($null -eq $visualizationType) {
        return @()
    }
    
    return $visualizationType.SupportedTechnologies
}

# Exporter les fonctions
Export-ModuleMember -Function Get-VisualizationTypes, Get-VisualizationType, Get-RecommendedTechnologies
