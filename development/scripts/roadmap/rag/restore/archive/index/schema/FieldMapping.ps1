# FieldMapping.ps1
# Script définissant la structure de mapping des champs pour l'indexation des métadonnées
# Version: 1.0
# Date: 2025-05-15

# Importer le module des champs indexables
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexableFieldsPath = Join-Path -Path $scriptPath -ChildPath "IndexableFields.ps1"

if (Test-Path -Path $indexableFieldsPath) {
    . $indexableFieldsPath
} else {
    Write-Error "Le fichier IndexableFields.ps1 est introuvable."
    exit 1
}

# Structure définissant le mapping des champs pour différents moteurs d'indexation
$script:FieldMappings = @{
    # Mapping pour le moteur d'indexation interne (fichiers JSON)
    Internal = @{
        # Mapping des types de champs
        TypeMapping = @{
            "Keyword" = @{
                Type = "string"
                Analyzer = "keyword"
                IndexOptions = @{
                    Tokenize = $false
                    LowerCase = $true
                    Stemming = $false
                    StopWords = $false
                }
            }
            "Text" = @{
                Type = "string"
                Analyzer = "standard"
                IndexOptions = @{
                    Tokenize = $true
                    LowerCase = $true
                    Stemming = $true
                    StopWords = $true
                }
            }
            "Numeric" = @{
                Type = "number"
                IndexOptions = @{
                    Precision = "double"
                    Range = $true
                }
            }
            "Date" = @{
                Type = "date"
                Format = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                IndexOptions = @{
                    Range = $true
                }
            }
            "Boolean" = @{
                Type = "boolean"
                IndexOptions = @{
                    Exact = $true
                }
            }
        }
        
        # Options d'indexation par défaut
        DefaultOptions = @{
            EnableHighlighting = $true
            EnableFaceting = $true
            EnableSorting = $true
            EnableFiltering = $true
            MaxFieldLength = 32768
        }
        
        # Fonctions de conversion des valeurs
        ValueConverters = @{
            "Keyword" = {
                param($value)
                if ($null -eq $value) { return $null }
                return [string]$value
            }
            "Text" = {
                param($value)
                if ($null -eq $value) { return $null }
                return [string]$value
            }
            "Numeric" = {
                param($value)
                if ($null -eq $value) { return $null }
                if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) { return $null }
                return [double]$value
            }
            "Date" = {
                param($value)
                if ($null -eq $value) { return $null }
                if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) { return $null }
                if ($value -is [DateTime]) {
                    return $value.ToString("o")
                }
                try {
                    $date = [DateTime]::Parse($value)
                    return $date.ToString("o")
                } catch {
                    return $null
                }
            }
            "Boolean" = {
                param($value)
                if ($null -eq $value) { return $null }
                if ($value -is [string]) {
                    return @("true", "yes", "1", "on") -contains $value.ToLower()
                }
                return [bool]$value
            }
        }
    }
    
    # Mapping pour Elasticsearch (si utilisé)
    Elasticsearch = @{
        # Mapping des types de champs
        TypeMapping = @{
            "Keyword" = @{
                Type = "keyword"
                IndexOptions = @{
                    Index = $true
                    DocValues = $true
                }
            }
            "Text" = @{
                Type = "text"
                IndexOptions = @{
                    Index = $true
                    Analyzer = "standard"
                    SearchAnalyzer = "standard"
                    TermVector = "with_positions_offsets"
                }
            }
            "Numeric" = @{
                Type = "double"
                IndexOptions = @{
                    Index = $true
                    DocValues = $true
                }
            }
            "Date" = @{
                Type = "date"
                Format = "strict_date_optional_time||epoch_millis"
                IndexOptions = @{
                    Index = $true
                    DocValues = $true
                }
            }
            "Boolean" = @{
                Type = "boolean"
                IndexOptions = @{
                    Index = $true
                    DocValues = $true
                }
            }
        }
        
        # Template pour la création d'index
        IndexTemplate = @{
            Settings = @{
                NumberOfShards = 1
                NumberOfReplicas = 0
                Analysis = @{
                    Analyzer = @{
                        RestorePointAnalyzer = @{
                            Type = "custom"
                            Tokenizer = "standard"
                            Filter = @("lowercase", "asciifolding", "stop", "snowball")
                        }
                    }
                }
            }
        }
    }
    
    # Mapping pour Qdrant (si utilisé)
    Qdrant = @{
        # Mapping des types de champs
        TypeMapping = @{
            "Keyword" = @{
                Type = "keyword"
                IndexOptions = @{
                    Indexed = $true
                    Filterable = $true
                }
            }
            "Text" = @{
                Type = "text"
                IndexOptions = @{
                    Indexed = $true
                    Tokenized = $true
                }
            }
            "Numeric" = @{
                Type = "float"
                IndexOptions = @{
                    Indexed = $true
                    Filterable = $true
                }
            }
            "Date" = @{
                Type = "datetime"
                IndexOptions = @{
                    Indexed = $true
                    Filterable = $true
                }
            }
            "Boolean" = @{
                Type = "bool"
                IndexOptions = @{
                    Indexed = $true
                    Filterable = $true
                }
            }
        }
        
        # Configuration de la collection
        CollectionConfig = @{
            VectorSize = 384
            Distance = "Cosine"
            OnDiskPayload = $true
        }
    }
}

# Fonction pour générer un mapping de champs pour un moteur d'indexation spécifique
function New-FieldMapping {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Internal", "Elasticsearch", "Qdrant")]
        [string]$Engine = "Internal"
    )
    
    if (-not $script:FieldMappings.ContainsKey($Engine)) {
        Write-Error "Moteur d'indexation non pris en charge: $Engine"
        return $null
    }
    
    $engineMapping = $script:FieldMappings[$Engine]
    $typeMapping = $engineMapping.TypeMapping
    
    # Obtenir tous les champs indexables
    $indexableFields = Get-IndexableFields
    
    # Créer le mapping
    $mapping = @{}
    
    foreach ($field in $indexableFields) {
        $fieldType = $field.Type
        
        if (-not $typeMapping.ContainsKey($fieldType)) {
            Write-Warning "Type de champ non pris en charge: $fieldType pour le champ $($field.Name)"
            continue
        }
        
        $typeDef = $typeMapping[$fieldType]
        
        # Créer la définition du champ
        $fieldDef = @{
            Name = $field.Name
            Type = $typeDef.Type
            Searchable = $field.Searchable
            Filterable = $field.Filterable
            Sortable = $field.Sortable
            Required = $field.Required
            IsArray = if ($field.PSObject.Properties.Name.Contains("IsArray")) { $field.IsArray } else { $false }
        }
        
        # Ajouter les options d'indexation spécifiques au type
        if ($typeDef.PSObject.Properties.Name.Contains("IndexOptions")) {
            $fieldDef.IndexOptions = $typeDef.IndexOptions
        }
        
        # Ajouter le format pour les dates
        if ($fieldType -eq "Date" -and $typeDef.PSObject.Properties.Name.Contains("Format")) {
            $fieldDef.Format = $typeDef.Format
        }
        
        # Ajouter l'analyseur pour le texte
        if ($fieldType -in @("Text", "Keyword") -and $typeDef.PSObject.Properties.Name.Contains("Analyzer")) {
            $fieldDef.Analyzer = $typeDef.Analyzer
        }
        
        # Ajouter la définition du champ au mapping
        $mapping[$field.Name] = $fieldDef
    }
    
    # Ajouter les options par défaut pour le moteur interne
    if ($Engine -eq "Internal" -and $engineMapping.PSObject.Properties.Name.Contains("DefaultOptions")) {
        $mapping._options = $engineMapping.DefaultOptions
    }
    
    # Ajouter le template d'index pour Elasticsearch
    if ($Engine -eq "Elasticsearch" -and $engineMapping.PSObject.Properties.Name.Contains("IndexTemplate")) {
        $mapping._template = $engineMapping.IndexTemplate
    }
    
    # Ajouter la configuration de collection pour Qdrant
    if ($Engine -eq "Qdrant" -and $engineMapping.PSObject.Properties.Name.Contains("CollectionConfig")) {
        $mapping._config = $engineMapping.CollectionConfig
    }
    
    return $mapping
}

# Fonction pour convertir une valeur selon le type de champ
function ConvertTo-IndexValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Keyword", "Text", "Numeric", "Date", "Boolean")]
        [string]$Type,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Internal", "Elasticsearch", "Qdrant")]
        [string]$Engine = "Internal"
    )
    
    if (-not $script:FieldMappings.ContainsKey($Engine)) {
        Write-Error "Moteur d'indexation non pris en charge: $Engine"
        return $Value
    }
    
    $engineMapping = $script:FieldMappings[$Engine]
    
    if (-not $engineMapping.PSObject.Properties.Name.Contains("ValueConverters")) {
        return $Value
    }
    
    $valueConverters = $engineMapping.ValueConverters
    
    if (-not $valueConverters.ContainsKey($Type)) {
        return $Value
    }
    
    $converter = $valueConverters[$Type]
    return & $converter $Value
}

# Fonction pour générer un schéma d'index complet
function New-IndexSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Internal", "Elasticsearch", "Qdrant")]
        [string]$Engine = "Internal",
        
        [Parameter(Mandatory = $false)]
        [string]$Name = "restore_points",
        
        [Parameter(Mandatory = $false)]
        [string]$Version = "1.0"
    )
    
    $mapping = New-FieldMapping -Engine $Engine
    
    if ($null -eq $mapping) {
        return $null
    }
    
    $schema = @{
        Name = $Name
        Version = $Version
        Engine = $Engine
        CreatedAt = (Get-Date).ToString("o")
        Mapping = $mapping
    }
    
    return $schema
}

# Fonction pour sauvegarder un schéma d'index dans un fichier
function Save-IndexSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Schema,
        
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        $Schema | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        return $true
    } catch {
        Write-Error "Erreur lors de la sauvegarde du schéma: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-FieldMapping, ConvertTo-IndexValue, New-IndexSchema, Save-IndexSchema
