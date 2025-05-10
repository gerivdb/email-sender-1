# Get-RestorePointSchema.ps1
# Script pour définir le schéma des points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
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

# Fonction pour obtenir le schéma des points de restauration
function Get-RestorePointSchema {
    [CmdletBinding()]
    param()
    
    $schema = @{
        # Métadonnées du point de restauration
        metadata = @{
            # Identifiant unique du point de restauration
            id = @{
                type = "string"
                format = "uuid"
                description = "Identifiant unique du point de restauration"
                required = $true
                example = "550e8400-e29b-41d4-a716-446655440000"
            }
            
            # Nom du point de restauration
            name = @{
                type = "string"
                description = "Nom du point de restauration"
                required = $true
                max_length = 100
                example = "Avant refactoring du module de visualisation"
            }
            
            # Description du point de restauration
            description = @{
                type = "string"
                description = "Description détaillée du point de restauration"
                required = $false
                max_length = 1000
                example = "Point de restauration créé avant de refactorer le module de visualisation pour améliorer les performances."
            }
            
            # Type de point de restauration
            type = @{
                type = "string"
                description = "Type de point de restauration"
                required = $true
                allowed_values = @(
                    "manual", # Créé manuellement par l'utilisateur
                    "automatic", # Créé automatiquement par le système
                    "scheduled", # Créé selon une planification
                    "pre-update", # Créé avant une mise à jour
                    "pre-migration", # Créé avant une migration
                    "git-commit" # Associé à un commit Git
                )
                example = "manual"
            }
            
            # Date de création
            created_at = @{
                type = "string"
                format = "date-time"
                description = "Date et heure de création du point de restauration"
                required = $true
                example = "2025-05-15T14:30:00Z"
            }
            
            # Utilisateur qui a créé le point de restauration
            created_by = @{
                type = "string"
                description = "Utilisateur qui a créé le point de restauration"
                required = $false
                example = "john.doe@example.com"
            }
            
            # Tags pour la catégorisation
            tags = @{
                type = "array"
                description = "Tags pour la catégorisation du point de restauration"
                required = $false
                items = @{
                    type = "string"
                    example = "refactoring"
                }
                example = @("refactoring", "performance", "visualisation")
            }
            
            # Informations sur l'expiration
            expiration = @{
                type = "object"
                description = "Informations sur l'expiration du point de restauration"
                required = $false
                properties = @{
                    # Date d'expiration
                    expires_at = @{
                        type = "string"
                        format = "date-time"
                        description = "Date et heure d'expiration du point de restauration"
                        required = $false
                        example = "2025-06-15T14:30:00Z"
                    }
                    
                    # Politique de rétention
                    retention_policy = @{
                        type = "string"
                        description = "Politique de rétention du point de restauration"
                        required = $false
                        allowed_values = @(
                            "keep-forever", # Conserver indéfiniment
                            "keep-for-duration", # Conserver pour une durée spécifiée
                            "keep-until-date", # Conserver jusqu'à une date spécifiée
                            "keep-n-versions" # Conserver un nombre spécifié de versions
                        )
                        example = "keep-for-duration"
                    }
                    
                    # Durée de rétention (en jours)
                    retention_days = @{
                        type = "integer"
                        description = "Durée de rétention en jours"
                        required = $false
                        minimum = 1
                        example = 30
                    }
                }
            }
            
            # Informations sur Git (si applicable)
            git_info = @{
                type = "object"
                description = "Informations sur le commit Git associé (si applicable)"
                required = $false
                properties = @{
                    # Hash du commit
                    commit_hash = @{
                        type = "string"
                        description = "Hash du commit Git associé"
                        required = $false
                        example = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0"
                    }
                    
                    # Branche
                    branch = @{
                        type = "string"
                        description = "Branche Git associée"
                        required = $false
                        example = "feature/new-visualization"
                    }
                    
                    # Message du commit
                    commit_message = @{
                        type = "string"
                        description = "Message du commit Git associé"
                        required = $false
                        example = "feat(visualization): improve performance of chart rendering"
                    }
                }
            }
            
            # État de validation
            validation = @{
                type = "object"
                description = "État de validation du point de restauration"
                required = $false
                properties = @{
                    # État de validation
                    status = @{
                        type = "string"
                        description = "État de validation du point de restauration"
                        required = $false
                        allowed_values = @(
                            "pending", # En attente de validation
                            "validated", # Validé
                            "invalid", # Invalide
                            "corrupted" # Corrompu
                        )
                        example = "validated"
                    }
                    
                    # Date de validation
                    validated_at = @{
                        type = "string"
                        format = "date-time"
                        description = "Date et heure de validation du point de restauration"
                        required = $false
                        example = "2025-05-15T14:35:00Z"
                    }
                    
                    # Utilisateur qui a validé le point de restauration
                    validated_by = @{
                        type = "string"
                        description = "Utilisateur qui a validé le point de restauration"
                        required = $false
                        example = "jane.doe@example.com"
                    }
                    
                    # Message de validation
                    validation_message = @{
                        type = "string"
                        description = "Message de validation du point de restauration"
                        required = $false
                        example = "Point de restauration validé avec succès."
                    }
                }
            }
        }
        
        # Contenu du point de restauration
        content = @{
            # Configurations sauvegardées
            configurations = @{
                type = "array"
                description = "Configurations sauvegardées dans le point de restauration"
                required = $true
                items = @{
                    type = "object"
                    properties = @{
                        # Type de configuration
                        type = @{
                            type = "string"
                            description = "Type de configuration"
                            required = $true
                            allowed_values = @(
                                "Template",
                                "Visualization",
                                "DataMapping",
                                "Chart",
                                "Export",
                                "Search"
                            )
                            example = "Visualization"
                        }
                        
                        # Identifiant de la configuration
                        id = @{
                            type = "string"
                            description = "Identifiant unique de la configuration"
                            required = $true
                            example = "visualization_performance_v1.0"
                        }
                        
                        # Version de la configuration
                        version = @{
                            type = "string"
                            description = "Version de la configuration"
                            required = $true
                            example = "1.0"
                        }
                        
                        # État de la configuration
                        state = @{
                            type = "object"
                            description = "État complet de la configuration"
                            required = $true
                            example = "{ ... }" # Contenu complet de la configuration
                        }
                        
                        # Dépendances
                        dependencies = @{
                            type = "array"
                            description = "Dépendances de la configuration"
                            required = $false
                            items = @{
                                type = "object"
                                properties = @{
                                    # Type de configuration dépendante
                                    type = @{
                                        type = "string"
                                        description = "Type de configuration dépendante"
                                        required = $true
                                        example = "DataMapping"
                                    }
                                    
                                    # Identifiant de la configuration dépendante
                                    id = @{
                                        type = "string"
                                        description = "Identifiant unique de la configuration dépendante"
                                        required = $true
                                        example = "data_mapping_performance_v1.0"
                                    }
                                    
                                    # Type de dépendance
                                    dependency_type = @{
                                        type = "string"
                                        description = "Type de dépendance"
                                        required = $true
                                        allowed_values = @(
                                            "required", # Dépendance requise
                                            "optional", # Dépendance optionnelle
                                            "recommended" # Dépendance recommandée
                                        )
                                        example = "required"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            # Métadonnées du système
            system_state = @{
                type = "object"
                description = "État du système au moment de la création du point de restauration"
                required = $false
                properties = @{
                    # Version du système
                    system_version = @{
                        type = "string"
                        description = "Version du système"
                        required = $false
                        example = "2.3.0"
                    }
                    
                    # Environnement
                    environment = @{
                        type = "string"
                        description = "Environnement du système"
                        required = $false
                        example = "production"
                    }
                    
                    # Informations sur la base de données
                    database_info = @{
                        type = "object"
                        description = "Informations sur la base de données"
                        required = $false
                        properties = @{
                            # Type de base de données
                            type = @{
                                type = "string"
                                description = "Type de base de données"
                                required = $false
                                example = "Qdrant"
                            }
                            
                            # Version de la base de données
                            version = @{
                                type = "string"
                                description = "Version de la base de données"
                                required = $false
                                example = "1.2.3"
                            }
                            
                            # Collections
                            collections = @{
                                type = "array"
                                description = "Collections de la base de données"
                                required = $false
                                items = @{
                                    type = "string"
                                    example = "roadmap_templates"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        # Informations sur la restauration
        restore_info = @{
            # Historique des restaurations
            restore_history = @{
                type = "array"
                description = "Historique des restaurations de ce point"
                required = $false
                items = @{
                    type = "object"
                    properties = @{
                        # Date de restauration
                        restored_at = @{
                            type = "string"
                            format = "date-time"
                            description = "Date et heure de restauration"
                            required = $true
                            example = "2025-05-20T10:15:00Z"
                        }
                        
                        # Utilisateur qui a effectué la restauration
                        restored_by = @{
                            type = "string"
                            description = "Utilisateur qui a effectué la restauration"
                            required = $false
                            example = "john.doe@example.com"
                        }
                        
                        # Raison de la restauration
                        reason = @{
                            type = "string"
                            description = "Raison de la restauration"
                            required = $false
                            example = "Correction d'un bug dans le module de visualisation"
                        }
                        
                        # Configurations restaurées
                        restored_configurations = @{
                            type = "array"
                            description = "Configurations restaurées"
                            required = $false
                            items = @{
                                type = "string"
                                example = "visualization_performance_v1.0"
                            }
                        }
                        
                        # Statut de la restauration
                        status = @{
                            type = "string"
                            description = "Statut de la restauration"
                            required = $true
                            allowed_values = @(
                                "success", # Restauration réussie
                                "partial", # Restauration partielle
                                "failed" # Restauration échouée
                            )
                            example = "success"
                        }
                        
                        # Message de statut
                        status_message = @{
                            type = "string"
                            description = "Message de statut de la restauration"
                            required = $false
                            example = "Restauration réussie de toutes les configurations"
                        }
                    }
                }
            }
            
            # Options de restauration recommandées
            restore_options = @{
                type = "object"
                description = "Options de restauration recommandées"
                required = $false
                properties = @{
                    # Méthode de restauration recommandée
                    recommended_method = @{
                        type = "string"
                        description = "Méthode de restauration recommandée"
                        required = $false
                        allowed_values = @(
                            "full", # Restauration complète
                            "selective", # Restauration sélective
                            "git-branch" # Restauration via branche Git
                        )
                        example = "selective"
                    }
                    
                    # Configurations à restaurer en priorité
                    priority_configurations = @{
                        type = "array"
                        description = "Configurations à restaurer en priorité"
                        required = $false
                        items = @{
                            type = "string"
                            example = "visualization_performance_v1.0"
                        }
                    }
                    
                    # Avertissements
                    warnings = @{
                        type = "array"
                        description = "Avertissements concernant la restauration"
                        required = $false
                        items = @{
                            type = "string"
                            example = "La restauration de cette configuration peut affecter les performances du système"
                        }
                    }
                }
            }
        }
    }
    
    return $schema
}

# Fonction pour générer un exemple de point de restauration
function Get-RestorePointExample {
    [CmdletBinding()]
    param()
    
    $example = @{
        metadata = @{
            id = [Guid]::NewGuid().ToString()
            name = "Avant refactoring du module de visualisation"
            description = "Point de restauration créé avant de refactorer le module de visualisation pour améliorer les performances."
            type = "manual"
            created_at = (Get-Date).ToString("o")
            created_by = "john.doe@example.com"
            tags = @("refactoring", "performance", "visualisation")
            expiration = @{
                expires_at = (Get-Date).AddDays(30).ToString("o")
                retention_policy = "keep-for-duration"
                retention_days = 30
            }
            git_info = @{
                commit_hash = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0"
                branch = "feature/new-visualization"
                commit_message = "feat(visualization): improve performance of chart rendering"
            }
            validation = @{
                status = "validated"
                validated_at = (Get-Date).AddMinutes(5).ToString("o")
                validated_by = "jane.doe@example.com"
                validation_message = "Point de restauration validé avec succès."
            }
        }
        content = @{
            configurations = @(
                @{
                    type = "Visualization"
                    id = "visualization_performance_v1.0"
                    version = "1.0"
                    state = @{
                        name = "Performance Visualization"
                        description = "Visualization for performance metrics"
                        chart_type = "line"
                        data_field = "performance_metrics"
                        # Autres propriétés de la configuration...
                    }
                    dependencies = @(
                        @{
                            type = "DataMapping"
                            id = "data_mapping_performance_v1.0"
                            dependency_type = "required"
                        }
                    )
                },
                @{
                    type = "DataMapping"
                    id = "data_mapping_performance_v1.0"
                    version = "1.0"
                    state = @{
                        name = "Performance Data Mapping"
                        description = "Data mapping for performance metrics"
                        mappings = @(
                            @{
                                source = "performance_data"
                                target = "performance_metrics"
                                transformation = "identity"
                            }
                        )
                        # Autres propriétés de la configuration...
                    }
                    dependencies = @()
                }
            )
            system_state = @{
                system_version = "2.3.0"
                environment = "production"
                database_info = @{
                    type = "Qdrant"
                    version = "1.2.3"
                    collections = @(
                        "roadmap_templates",
                        "roadmap_visualizations",
                        "roadmap_data_mappings"
                    )
                }
            }
        }
        restore_info = @{
            restore_history = @(
                @{
                    restored_at = (Get-Date).AddDays(5).ToString("o")
                    restored_by = "john.doe@example.com"
                    reason = "Correction d'un bug dans le module de visualisation"
                    restored_configurations = @(
                        "visualization_performance_v1.0"
                    )
                    status = "success"
                    status_message = "Restauration réussie de toutes les configurations"
                }
            )
            restore_options = @{
                recommended_method = "selective"
                priority_configurations = @(
                    "visualization_performance_v1.0"
                )
                warnings = @(
                    "La restauration de cette configuration peut affecter les performances du système"
                )
            }
        }
    }
    
    return $example
}

# Fonction pour générer un fichier JSON Schema
function Get-JsonSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Schema
    )
    
    $jsonSchema = @{
        '$schema' = "http://json-schema.org/draft-07/schema#"
        title = "Restore Point Schema"
        description = "Schema for restore points in the roadmap management system"
        type = "object"
        required = @("metadata", "content")
        properties = @{
            metadata = @{
                type = "object"
                required = @("id", "name", "type", "created_at")
                properties = @{}
            }
            content = @{
                type = "object"
                required = @("configurations")
                properties = @{}
            }
            restore_info = @{
                type = "object"
                properties = @{}
            }
        }
    }
    
    # Ajouter les propriétés de métadonnées
    foreach ($key in $Schema.metadata.Keys) {
        $property = $Schema.metadata[$key]
        $jsonProperty = @{
            type = $property.type
            description = $property.description
        }
        
        if ($property.ContainsKey("format")) {
            $jsonProperty.format = $property.format
        }
        
        if ($property.ContainsKey("example")) {
            $jsonProperty.example = $property.example
        }
        
        if ($property.ContainsKey("allowed_values")) {
            $jsonProperty.enum = $property.allowed_values
        }
        
        if ($property.ContainsKey("max_length")) {
            $jsonProperty.maxLength = $property.max_length
        }
        
        if ($property.type -eq "object" -and $property.ContainsKey("properties")) {
            $jsonProperty.properties = @{}
            $jsonProperty.required = @()
            
            foreach ($subKey in $property.properties.Keys) {
                $subProperty = $property.properties[$subKey]
                $jsonSubProperty = @{
                    type = $subProperty.type
                    description = $subProperty.description
                }
                
                if ($subProperty.ContainsKey("format")) {
                    $jsonSubProperty.format = $subProperty.format
                }
                
                if ($subProperty.ContainsKey("example")) {
                    $jsonSubProperty.example = $subProperty.example
                }
                
                if ($subProperty.ContainsKey("allowed_values")) {
                    $jsonSubProperty.enum = $subProperty.allowed_values
                }
                
                if ($subProperty.ContainsKey("required") -and $subProperty.required) {
                    $jsonProperty.required += $subKey
                }
                
                $jsonProperty.properties[$subKey] = $jsonSubProperty
            }
        }
        
        if ($property.type -eq "array") {
            $jsonProperty.items = $property.items
        }
        
        $jsonSchema.properties.metadata.properties[$key] = $jsonProperty
    }
    
    # Ajouter les propriétés de contenu
    foreach ($key in $Schema.content.Keys) {
        $jsonSchema.properties.content.properties[$key] = $Schema.content[$key]
    }
    
    # Ajouter les propriétés de restauration
    foreach ($key in $Schema.restore_info.Keys) {
        $jsonSchema.properties.restore_info.properties[$key] = $Schema.restore_info[$key]
    }
    
    return $jsonSchema
}

# Fonction principale
function Get-RestorePointSchemaFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Obtenir le schéma
    $schema = Get-RestorePointSchema
    
    # Obtenir un exemple
    $example = Get-RestorePointExample
    
    # Générer le JSON Schema
    $jsonSchema = Get-JsonSchema -Schema $schema
    
    # Créer les fichiers de sortie
    $files = @{
        schema = $schema
        example = $example
        json_schema = $jsonSchema
    }
    
    # Sauvegarder les fichiers si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            # Créer le répertoire de sortie s'il n'existe pas
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            }
            
            # Sauvegarder le schéma
            $schema | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "restore-point-schema.json") -Encoding UTF8
            Write-Log "Schema saved to: $(Join-Path -Path $OutputPath -ChildPath "restore-point-schema.json")" -Level "Info"
            
            # Sauvegarder l'exemple
            $example | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "restore-point-example.json") -Encoding UTF8
            Write-Log "Example saved to: $(Join-Path -Path $OutputPath -ChildPath "restore-point-example.json")" -Level "Info"
            
            # Sauvegarder le JSON Schema
            $jsonSchema | ConvertTo-Json -Depth 10 | Out-File -FilePath (Join-Path -Path $OutputPath -ChildPath "restore-point-json-schema.json") -Encoding UTF8
            Write-Log "JSON Schema saved to: $(Join-Path -Path $OutputPath -ChildPath "restore-point-json-schema.json")" -Level "Info"
        } catch {
            Write-Log "Error saving files: $_" -Level "Error"
        }
    }
    
    # Retourner les fichiers selon le format demandé
    if ($AsObject) {
        return $files
    } else {
        return $files | ConvertTo-Json -Depth 10
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Get-RestorePointSchemaFiles -OutputPath $OutputPath -AsObject:$AsObject
}
