# Get-VersioningRules.ps1
# Script pour établir les règles de versionnage des configurations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
    [string]$ConfigType = "All",
    
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

# Fonction pour obtenir les règles de versionnage des templates
function Get-TemplateVersioningRules {
    [CmdletBinding()]
    param()
    
    $rules = @{
        version_format = "MAJOR.MINOR.PATCH"
        version_pattern = "^\d+\.\d+\.\d+$"
        initial_version = "1.0.0"
        rules = @(
            @{
                type = "MAJOR"
                description = "Changements incompatibles avec les versions précédentes"
                examples = @(
                    "Modification du format de base du template",
                    "Suppression de variables requises",
                    "Changement de la structure fondamentale"
                )
            },
            @{
                type = "MINOR"
                description = "Ajouts de fonctionnalités rétrocompatibles"
                examples = @(
                    "Ajout de nouvelles variables optionnelles",
                    "Ajout de nouvelles sections au template",
                    "Amélioration de la mise en forme"
                )
            },
            @{
                type = "PATCH"
                description = "Corrections de bugs rétrocompatibles"
                examples = @(
                    "Correction de fautes d'orthographe",
                    "Correction de problèmes de mise en forme",
                    "Optimisation des performances"
                )
            }
        )
        storage = @{
            naming_convention = "template_{name}_v{version}.json"
            history_folder = "history"
            max_history_versions = 10
            auto_backup = $true
        }
        metadata = @{
            required_fields = @(
                "version",
                "name",
                "type",
                "created_at",
                "updated_at",
                "content"
            )
            changelog_format = @{
                date = "yyyy-MM-dd"
                author = "required"
                description = "required"
                version = "required"
                changes = "array of changes"
            }
        }
    }
    
    return $rules
}

# Fonction pour obtenir les règles de versionnage des visualisations
function Get-VisualizationVersioningRules {
    [CmdletBinding()]
    param()
    
    $rules = @{
        version_format = "MAJOR.MINOR.PATCH"
        version_pattern = "^\d+\.\d+\.\d+$"
        initial_version = "1.0.0"
        rules = @(
            @{
                type = "MAJOR"
                description = "Changements incompatibles avec les versions précédentes"
                examples = @(
                    "Modification de la structure des données",
                    "Changement du type de graphique principal",
                    "Suppression de fonctionnalités essentielles"
                )
            },
            @{
                type = "MINOR"
                description = "Ajouts de fonctionnalités rétrocompatibles"
                examples = @(
                    "Ajout de nouveaux types de graphiques",
                    "Ajout de nouvelles options de personnalisation",
                    "Amélioration des interactions"
                )
            },
            @{
                type = "PATCH"
                description = "Corrections de bugs rétrocompatibles"
                examples = @(
                    "Correction de problèmes d'affichage",
                    "Correction de problèmes de données",
                    "Optimisation des performances"
                )
            }
        )
        storage = @{
            naming_convention = "visualization_{name}_v{version}.json"
            history_folder = "history"
            max_history_versions = 10
            auto_backup = $true
        }
        metadata = @{
            required_fields = @(
                "version",
                "name",
                "created_at",
                "updated_at",
                "chart_configuration",
                "data_mapping"
            )
            changelog_format = @{
                date = "yyyy-MM-dd"
                author = "required"
                description = "required"
                version = "required"
                changes = "array of changes"
            }
        }
    }
    
    return $rules
}

# Fonction pour obtenir les règles de versionnage des mappages de données
function Get-DataMappingVersioningRules {
    [CmdletBinding()]
    param()
    
    $rules = @{
        version_format = "MAJOR.MINOR"
        version_pattern = "^\d+\.\d+$"
        initial_version = "1.0"
        rules = @(
            @{
                type = "MAJOR"
                description = "Changements incompatibles avec les versions précédentes"
                examples = @(
                    "Modification de la structure des mappages",
                    "Changement des champs requis",
                    "Suppression de mappages essentiels"
                )
            },
            @{
                type = "MINOR"
                description = "Ajouts de fonctionnalités rétrocompatibles"
                examples = @(
                    "Ajout de nouveaux mappages",
                    "Ajout de nouvelles options de personnalisation",
                    "Amélioration des transformations"
                )
            }
        )
        storage = @{
            naming_convention = "data_mapping_{name}_v{version}.json"
            history_folder = "history"
            max_history_versions = 5
            auto_backup = $true
        }
        metadata = @{
            required_fields = @(
                "version",
                "created_date",
                "modified_date",
                "mappings"
            )
            changelog_format = @{
                date = "yyyy-MM-dd"
                author = "required"
                description = "required"
                version = "required"
                changes = "array of changes"
            }
        }
    }
    
    return $rules
}

# Fonction pour obtenir les règles de versionnage des graphiques
function Get-ChartVersioningRules {
    [CmdletBinding()]
    param()
    
    $rules = @{
        version_format = "MAJOR.MINOR"
        version_pattern = "^\d+\.\d+$"
        initial_version = "1.0"
        rules = @(
            @{
                type = "MAJOR"
                description = "Changements incompatibles avec les versions précédentes"
                examples = @(
                    "Modification du type de graphique",
                    "Changement des options fondamentales",
                    "Suppression de fonctionnalités essentielles"
                )
            },
            @{
                type = "MINOR"
                description = "Ajouts de fonctionnalités rétrocompatibles"
                examples = @(
                    "Ajout de nouvelles options de personnalisation",
                    "Amélioration des interactions",
                    "Optimisation des performances"
                )
            }
        )
        storage = @{
            naming_convention = "chart_{name}_v{version}.json"
            history_folder = "history"
            max_history_versions = 5
            auto_backup = $true
        }
        metadata = @{
            required_fields = @(
                "chart_type",
                "data_field",
                "options"
            )
            changelog_format = @{
                date = "yyyy-MM-dd"
                author = "optional"
                description = "required"
                version = "required"
                changes = "array of changes"
            }
        }
    }
    
    return $rules
}

# Fonction pour obtenir les règles de versionnage des exports
function Get-ExportVersioningRules {
    [CmdletBinding()]
    param()
    
    $rules = @{
        version_format = "MAJOR.MINOR"
        version_pattern = "^\d+\.\d+$"
        initial_version = "1.0"
        rules = @(
            @{
                type = "MAJOR"
                description = "Changements incompatibles avec les versions précédentes"
                examples = @(
                    "Modification du format d'export",
                    "Changement des options fondamentales",
                    "Suppression de fonctionnalités essentielles"
                )
            },
            @{
                type = "MINOR"
                description = "Ajouts de fonctionnalités rétrocompatibles"
                examples = @(
                    "Ajout de nouveaux formats d'export",
                    "Ajout de nouvelles options de personnalisation",
                    "Amélioration de la qualité"
                )
            }
        )
        storage = @{
            naming_convention = "export_{name}_v{version}.json"
            history_folder = "history"
            max_history_versions = 3
            auto_backup = $false
        }
        metadata = @{
            required_fields = @(
                "export_type"
            )
            changelog_format = @{
                date = "yyyy-MM-dd"
                author = "optional"
                description = "optional"
                version = "required"
                changes = "array of changes"
            }
        }
    }
    
    return $rules
}

# Fonction pour obtenir les règles de versionnage des recherches
function Get-SearchVersioningRules {
    [CmdletBinding()]
    param()
    
    $rules = @{
        version_format = "MAJOR.MINOR"
        version_pattern = "^\d+\.\d+$"
        initial_version = "1.0"
        rules = @(
            @{
                type = "MAJOR"
                description = "Changements incompatibles avec les versions précédentes"
                examples = @(
                    "Modification du type de recherche",
                    "Changement des filtres fondamentaux",
                    "Suppression de fonctionnalités essentielles"
                )
            },
            @{
                type = "MINOR"
                description = "Ajouts de fonctionnalités rétrocompatibles"
                examples = @(
                    "Ajout de nouveaux filtres",
                    "Ajout de nouvelles options de tri",
                    "Amélioration de la pertinence"
                )
            }
        )
        storage = @{
            naming_convention = "search_{name}_v{version}.json"
            history_folder = "history"
            max_history_versions = 3
            auto_backup = $false
        }
        metadata = @{
            required_fields = @(
                "search_type",
                "query"
            )
            changelog_format = @{
                date = "yyyy-MM-dd"
                author = "optional"
                description = "optional"
                version = "required"
                changes = "array of changes"
            }
        }
    }
    
    return $rules
}

# Fonction pour obtenir toutes les règles de versionnage
function Get-AllVersioningRules {
    [CmdletBinding()]
    param()
    
    $rules = @{
        template = Get-TemplateVersioningRules
        visualization = Get-VisualizationVersioningRules
        data_mapping = Get-DataMappingVersioningRules
        chart = Get-ChartVersioningRules
        export = Get-ExportVersioningRules
        search = Get-SearchVersioningRules
        global = @{
            version_format = "MAJOR.MINOR.PATCH"
            version_pattern = "^\d+\.\d+\.\d+$"
            initial_version = "1.0.0"
            storage = @{
                base_folder = "configurations"
                history_folder = "history"
                backup_folder = "backups"
                auto_backup_interval = "1d"
                backup_retention = "30d"
                naming_convention = "{type}_{name}_v{version}.json"
            }
            metadata = @{
                common_fields = @(
                    "version",
                    "name",
                    "description",
                    "author",
                    "created_at",
                    "updated_at",
                    "tags"
                )
                changelog_location = "metadata.changelog"
                changelog_format = @{
                    date = "yyyy-MM-dd"
                    author = "required"
                    description = "required"
                    version = "required"
                    changes = "array of changes"
                }
            }
            migration = @{
                auto_migration = $true
                migration_scripts_folder = "migrations"
                migration_naming = "migrate_{from_version}_to_{to_version}.ps1"
                validation_required = $true
            }
        }
    }
    
    return $rules
}

# Fonction principale
function Get-VersioningRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Obtenir les règles demandées
    $rules = $null
    
    switch ($ConfigType) {
        "Template" {
            $rules = Get-TemplateVersioningRules
            Write-Log "Generated template versioning rules" -Level "Info"
        }
        "Visualization" {
            $rules = Get-VisualizationVersioningRules
            Write-Log "Generated visualization versioning rules" -Level "Info"
        }
        "DataMapping" {
            $rules = Get-DataMappingVersioningRules
            Write-Log "Generated data mapping versioning rules" -Level "Info"
        }
        "Chart" {
            $rules = Get-ChartVersioningRules
            Write-Log "Generated chart versioning rules" -Level "Info"
        }
        "Export" {
            $rules = Get-ExportVersioningRules
            Write-Log "Generated export versioning rules" -Level "Info"
        }
        "Search" {
            $rules = Get-SearchVersioningRules
            Write-Log "Generated search versioning rules" -Level "Info"
        }
        "All" {
            $rules = Get-AllVersioningRules
            Write-Log "Generated all versioning rules" -Level "Info"
        }
    }
    
    # Sauvegarder les règles si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $rules | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Versioning rules saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving versioning rules: $_" -Level "Error"
        }
    }
    
    # Retourner les règles selon le format demandé
    if ($AsObject) {
        return $rules
    } else {
        return $rules | ConvertTo-Json -Depth 10
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Get-VersioningRules -ConfigType $ConfigType -OutputPath $OutputPath -AsObject:$AsObject
}
