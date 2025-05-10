# Get-ConfigurationSchema.ps1
# Script pour définir et valider le schéma JSON des configurations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
    [string]$SchemaType = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$AsObject,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $rootPath)) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour obtenir le schéma de configuration des templates
function Get-TemplateSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        '$schema' = "http://json-schema.org/draft-07/schema#"
        title = "Template Configuration Schema"
        description = "Schema for roadmap template configurations"
        type = "object"
        required = @("version", "name", "type", "created_at", "updated_at", "content")
        properties = @{
            version = @{
                type = "string"
                description = "Version of the template configuration"
                pattern = "^\d+\.\d+\.\d+$"
            }
            name = @{
                type = "string"
                description = "Name of the template"
                minLength = 1
                maxLength = 100
            }
            description = @{
                type = "string"
                description = "Description of the template"
                maxLength = 500
            }
            type = @{
                type = "string"
                description = "Type of the template"
                enum = @("markdown", "html", "text")
            }
            author = @{
                type = "string"
                description = "Author of the template"
                maxLength = 100
            }
            created_at = @{
                type = "string"
                description = "Creation timestamp"
                format = "date-time"
            }
            updated_at = @{
                type = "string"
                description = "Last update timestamp"
                format = "date-time"
            }
            tags = @{
                type = "array"
                description = "Tags associated with the template"
                items = @{
                    type = "string"
                    maxLength = 50
                }
            }
            content = @{
                type = "string"
                description = "Content of the template"
                minLength = 1
            }
            variables = @{
                type = "object"
                description = "Variables used in the template"
                additionalProperties = @{
                    type = "object"
                    properties = @{
                        type = @{
                            type = "string"
                            enum = @("string", "number", "boolean", "array", "object")
                        }
                        description = @{
                            type = "string"
                        }
                        default = @{
                            type = @("string", "number", "boolean", "array", "object", "null")
                        }
                    }
                }
            }
            metadata = @{
                type = "object"
                description = "Additional metadata for the template"
                additionalProperties = $true
            }
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de configuration des visualisations
function Get-VisualizationSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        '$schema' = "http://json-schema.org/draft-07/schema#"
        title = "Visualization Configuration Schema"
        description = "Schema for roadmap visualization configurations"
        type = "object"
        required = @("version", "name", "created_at", "updated_at", "chart_configuration", "data_mapping")
        properties = @{
            version = @{
                type = "string"
                description = "Version of the visualization configuration"
                pattern = "^\d+\.\d+\.\d+$"
            }
            name = @{
                type = "string"
                description = "Name of the visualization"
                minLength = 1
                maxLength = 100
            }
            description = @{
                type = "string"
                description = "Description of the visualization"
                maxLength = 500
            }
            author = @{
                type = "string"
                description = "Author of the visualization"
                maxLength = 100
            }
            created_at = @{
                type = "string"
                description = "Creation timestamp"
                format = "date-time"
            }
            updated_at = @{
                type = "string"
                description = "Last update timestamp"
                format = "date-time"
            }
            tags = @{
                type = "array"
                description = "Tags associated with the visualization"
                items = @{
                    type = "string"
                    maxLength = 50
                }
            }
            chart_configuration = @{
                type = "object"
                description = "Chart configuration"
                required = @("chart_type", "data_field", "options")
                properties = @{
                    chart_type = @{
                        type = "string"
                        description = "Type of chart"
                        enum = @("pie", "bar", "line", "radar", "doughnut", "scatter", "bubble", "polarArea", "treemap", "gantt", "network")
                    }
                    data_field = @{
                        type = "string"
                        description = "Field to use for data"
                    }
                    title = @{
                        type = "string"
                        description = "Title of the chart"
                    }
                    colors = @{
                        type = "array"
                        description = "Colors to use for the chart"
                        items = @{
                            type = "string"
                            pattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
                        }
                    }
                    options = @{
                        type = "object"
                        description = "Chart.js options"
                        additionalProperties = $true
                    }
                }
            }
            data_mapping = @{
                type = "object"
                description = "Data mapping configuration"
                required = @("mappings")
                properties = @{
                    version = @{
                        type = "string"
                        description = "Version of the data mapping"
                    }
                    created_date = @{
                        type = "string"
                        description = "Creation date"
                        format = "date-time"
                    }
                    modified_date = @{
                        type = "string"
                        description = "Last modification date"
                        format = "date-time"
                    }
                    mappings = @{
                        type = "array"
                        description = "Data mappings"
                        items = @{
                            type = "object"
                            required = @("name", "type", "data_source", "group_by", "value_field")
                            properties = @{
                                name = @{
                                    type = "string"
                                    description = "Name of the mapping"
                                }
                                description = @{
                                    type = "string"
                                    description = "Description of the mapping"
                                }
                                type = @{
                                    type = "string"
                                    description = "Type of chart for this mapping"
                                    enum = @("PieChart", "BarChart", "LineChart", "RadarChart", "DoughnutChart", "ScatterChart")
                                }
                                data_source = @{
                                    type = "string"
                                    description = "Data source for the mapping"
                                }
                                group_by = @{
                                    type = "string"
                                    description = "Field to group by"
                                }
                                value_field = @{
                                    type = "string"
                                    description = "Field to use for values"
                                }
                                dynamic_labels = @{
                                    type = "boolean"
                                    description = "Whether to use dynamic labels"
                                }
                                dynamic_colors = @{
                                    type = "boolean"
                                    description = "Whether to use dynamic colors"
                                }
                                labels = @{
                                    type = "object"
                                    description = "Label mappings"
                                    additionalProperties = @{
                                        type = "string"
                                    }
                                }
                                colors = @{
                                    type = "object"
                                    description = "Color mappings"
                                    additionalProperties = @{
                                        type = "string"
                                        pattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
                                    }
                                }
                                template_variables = @{
                                    type = "object"
                                    description = "Template variable mappings"
                                    additionalProperties = @{
                                        type = "string"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            template_html = @{
                type = "string"
                description = "HTML template for the visualization"
            }
            metadata = @{
                type = "object"
                description = "Additional metadata for the visualization"
                additionalProperties = $true
            }
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de configuration des mappages de données
function Get-DataMappingSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        '$schema' = "http://json-schema.org/draft-07/schema#"
        title = "Data Mapping Configuration Schema"
        description = "Schema for roadmap data mapping configurations"
        type = "object"
        required = @("version", "created_date", "modified_date", "mappings")
        properties = @{
            version = @{
                type = "string"
                description = "Version of the data mapping configuration"
                pattern = "^\d+\.\d+$"
            }
            created_date = @{
                type = "string"
                description = "Creation timestamp"
                format = "date-time"
            }
            modified_date = @{
                type = "string"
                description = "Last update timestamp"
                format = "date-time"
            }
            mappings = @{
                type = "array"
                description = "Data mappings"
                items = @{
                    type = "object"
                    required = @("name", "type", "data_source", "group_by", "value_field")
                    properties = @{
                        name = @{
                            type = "string"
                            description = "Name of the mapping"
                            minLength = 1
                            maxLength = 100
                        }
                        description = @{
                            type = "string"
                            description = "Description of the mapping"
                            maxLength = 500
                        }
                        type = @{
                            type = "string"
                            description = "Type of chart for this mapping"
                            enum = @("PieChart", "BarChart", "LineChart", "RadarChart", "DoughnutChart", "ScatterChart")
                        }
                        data_source = @{
                            type = "string"
                            description = "Data source for the mapping"
                        }
                        group_by = @{
                            type = "string"
                            description = "Field to group by"
                        }
                        value_field = @{
                            type = "string"
                            description = "Field to use for values"
                            enum = @("Count", "Sum", "Average", "Min", "Max")
                        }
                        time_grouping = @{
                            type = "string"
                            description = "Time grouping for date fields"
                            enum = @("Day", "Week", "Month", "Quarter", "Year")
                        }
                        dynamic_labels = @{
                            type = "boolean"
                            description = "Whether to use dynamic labels"
                        }
                        dynamic_colors = @{
                            type = "boolean"
                            description = "Whether to use dynamic colors"
                        }
                        labels = @{
                            type = "object"
                            description = "Label mappings"
                            additionalProperties = @{
                                type = "string"
                            }
                        }
                        colors = @{
                            type = "object"
                            description = "Color mappings"
                            additionalProperties = @{
                                type = "string"
                                pattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
                            }
                        }
                        template_variables = @{
                            type = "object"
                            description = "Template variable mappings"
                            additionalProperties = @{
                                type = "string"
                            }
                        }
                    }
                }
            }
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de configuration des graphiques
function Get-ChartSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        '$schema' = "http://json-schema.org/draft-07/schema#"
        title = "Chart Configuration Schema"
        description = "Schema for roadmap chart configurations"
        type = "object"
        required = @("chart_type", "data_field", "options")
        properties = @{
            chart_type = @{
                type = "string"
                description = "Type of chart"
                enum = @("pie", "bar", "line", "radar", "doughnut", "scatter", "bubble", "polarArea", "treemap", "gantt", "network")
            }
            data_field = @{
                type = "string"
                description = "Field to use for data"
            }
            title = @{
                type = "string"
                description = "Title of the chart"
                maxLength = 100
            }
            show_legend = @{
                type = "boolean"
                description = "Whether to show the legend"
            }
            enable_animation = @{
                type = "boolean"
                description = "Whether to enable animations"
            }
            colors = @{
                type = "array"
                description = "Colors to use for the chart"
                items = @{
                    type = "string"
                    pattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
                }
            }
            options = @{
                type = "object"
                description = "Chart.js options"
                properties = @{
                    responsive = @{
                        type = "boolean"
                        description = "Whether the chart should be responsive"
                    }
                    maintainAspectRatio = @{
                        type = "boolean"
                        description = "Whether to maintain aspect ratio"
                    }
                    legend = @{
                        type = "object"
                        description = "Legend options"
                        properties = @{
                            display = @{
                                type = "boolean"
                                description = "Whether to display the legend"
                            }
                            position = @{
                                type = "string"
                                description = "Position of the legend"
                                enum = @("top", "right", "bottom", "left")
                            }
                        }
                    }
                    animation = @{
                        type = "object"
                        description = "Animation options"
                        properties = @{
                            duration = @{
                                type = "integer"
                                description = "Duration of the animation in milliseconds"
                                minimum = 0
                            }
                            easing = @{
                                type = "string"
                                description = "Easing function to use"
                            }
                        }
                    }
                    title = @{
                        type = "object"
                        description = "Title options"
                        properties = @{
                            display = @{
                                type = "boolean"
                                description = "Whether to display the title"
                            }
                            text = @{
                                type = "string"
                                description = "Title text"
                            }
                            fontSize = @{
                                type = "integer"
                                description = "Font size for the title"
                                minimum = 1
                            }
                            fontColor = @{
                                type = "string"
                                description = "Font color for the title"
                            }
                        }
                    }
                }
                additionalProperties = $true
            }
            data_mapping = @{
                type = "object"
                description = "Data mapping for different fields"
                additionalProperties = @{
                    type = "object"
                    properties = @{
                        labels = @{
                            type = "array"
                            description = "Labels for the data"
                            items = @{
                                type = "string"
                            }
                        }
                        data_fields = @{
                            type = "array"
                            description = "Data fields to use"
                            items = @{
                                type = "string"
                            }
                        }
                        colors = @{
                            type = "array"
                            description = "Colors for the data"
                            items = @{
                                type = "string"
                                pattern = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
                            }
                        }
                    }
                }
            }
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de configuration des exports
function Get-ExportSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        '$schema' = "http://json-schema.org/draft-07/schema#"
        title = "Export Configuration Schema"
        description = "Schema for roadmap export configurations"
        type = "object"
        required = @("export_type")
        properties = @{
            export_type = @{
                type = "string"
                description = "Type of export"
                enum = @("Image", "HTML", "Embed", "All")
            }
            image_format = @{
                type = "string"
                description = "Format for image export"
                enum = @("PNG", "JPEG", "SVG", "PDF")
            }
            width = @{
                type = "string"
                description = "Width of the export"
                pattern = "^(\d+)(px|%)?$"
            }
            height = @{
                type = "string"
                description = "Height of the export"
                pattern = "^(\d+)(px|%)?$"
            }
            include_timestamp = @{
                type = "boolean"
                description = "Whether to include a timestamp"
            }
            include_watermark = @{
                type = "boolean"
                description = "Whether to include a watermark"
            }
            watermark_text = @{
                type = "string"
                description = "Text for the watermark"
                maxLength = 100
            }
            html_type = @{
                type = "string"
                description = "Type of HTML export"
                enum = @("Standalone", "Embedded", "Interactive")
            }
            include_data = @{
                type = "boolean"
                description = "Whether to include data in HTML export"
            }
            minify_output = @{
                type = "boolean"
                description = "Whether to minify the output"
            }
            embed_type = @{
                type = "string"
                description = "Type of embed code"
                enum = @("Iframe", "JavaScript", "WordPress", "Confluence", "SharePoint", "Teams")
            }
            server_url = @{
                type = "string"
                description = "URL of the server for embed code"
                format = "uri"
            }
            auto_resize = @{
                type = "boolean"
                description = "Whether to enable auto-resize for embed"
            }
            enable_interactivity = @{
                type = "boolean"
                description = "Whether to enable interactivity for embed"
            }
        }
    }
    
    return $schema
}

# Fonction pour obtenir le schéma de configuration des recherches
function Get-SearchSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        '$schema' = "http://json-schema.org/draft-07/schema#"
        title = "Search Configuration Schema"
        description = "Schema for roadmap search configurations"
        type = "object"
        required = @("search_type", "query")
        properties = @{
            search_type = @{
                type = "string"
                description = "Type of search"
                enum = @("Keyword", "Semantic", "Combined")
            }
            query = @{
                type = "string"
                description = "Search query"
                minLength = 1
            }
            filters = @{
                type = "object"
                description = "Search filters"
                properties = @{
                    status = @{
                        type = "array"
                        description = "Status filters"
                        items = @{
                            type = "string"
                        }
                    }
                    priority = @{
                        type = "array"
                        description = "Priority filters"
                        items = @{
                            type = "string"
                        }
                    }
                    assignee = @{
                        type = "array"
                        description = "Assignee filters"
                        items = @{
                            type = "string"
                        }
                    }
                    tags = @{
                        type = "array"
                        description = "Tag filters"
                        items = @{
                            type = "string"
                        }
                    }
                    date_range = @{
                        type = "object"
                        description = "Date range filter"
                        properties = @{
                            start_date = @{
                                type = "string"
                                description = "Start date"
                                format = "date"
                            }
                            end_date = @{
                                type = "string"
                                description = "End date"
                                format = "date"
                            }
                        }
                    }
                }
            }
            sort = @{
                type = "object"
                description = "Sort options"
                properties = @{
                    field = @{
                        type = "string"
                        description = "Field to sort by"
                    }
                    direction = @{
                        type = "string"
                        description = "Sort direction"
                        enum = @("asc", "desc")
                    }
                }
            }
            limit = @{
                type = "integer"
                description = "Maximum number of results"
                minimum = 1
            }
            include_archived = @{
                type = "boolean"
                description = "Whether to include archived items"
            }
            semantic_options = @{
                type = "object"
                description = "Options for semantic search"
                properties = @{
                    model = @{
                        type = "string"
                        description = "Model to use for semantic search"
                    }
                    similarity_threshold = @{
                        type = "number"
                        description = "Similarity threshold for semantic search"
                        minimum = 0
                        maximum = 1
                    }
                    reranking = @{
                        type = "boolean"
                        description = "Whether to enable reranking"
                    }
                }
            }
        }
    }
    
    return $schema
}

# Fonction pour obtenir tous les schémas
function Get-AllSchemas {
    [CmdletBinding()]
    param()
    
    $schemas = @{
        template = Get-TemplateSchema
        visualization = Get-VisualizationSchema
        data_mapping = Get-DataMappingSchema
        chart = Get-ChartSchema
        export = Get-ExportSchema
        search = Get-SearchSchema
    }
    
    return $schemas
}

# Fonction principale
function Get-ConfigurationSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$SchemaType = "All",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Obtenir le schéma demandé
    $schema = $null
    
    switch ($SchemaType) {
        "Template" {
            $schema = Get-TemplateSchema
            Write-Log "Generated template configuration schema" -Level "Info"
        }
        "Visualization" {
            $schema = Get-VisualizationSchema
            Write-Log "Generated visualization configuration schema" -Level "Info"
        }
        "DataMapping" {
            $schema = Get-DataMappingSchema
            Write-Log "Generated data mapping configuration schema" -Level "Info"
        }
        "Chart" {
            $schema = Get-ChartSchema
            Write-Log "Generated chart configuration schema" -Level "Info"
        }
        "Export" {
            $schema = Get-ExportSchema
            Write-Log "Generated export configuration schema" -Level "Info"
        }
        "Search" {
            $schema = Get-SearchSchema
            Write-Log "Generated search configuration schema" -Level "Info"
        }
        "All" {
            $schema = Get-AllSchemas
            Write-Log "Generated all configuration schemas" -Level "Info"
        }
    }
    
    # Sauvegarder le schéma si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $schema | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Schema saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving schema: $_" -Level "Error"
        }
    }
    
    # Retourner le schéma selon le format demandé
    if ($AsObject) {
        return $schema
    } else {
        return $schema | ConvertTo-Json -Depth 10
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Get-ConfigurationSchema -SchemaType $SchemaType -OutputPath $OutputPath -AsObject:$AsObject
}
