# IndexSchema.ps1
# Script définissant le schéma de stockage JSON pour l'index des métadonnées
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexableFieldsPath = Join-Path -Path $scriptPath -ChildPath "IndexableFields.ps1"
$fieldMappingPath = Join-Path -Path $scriptPath -ChildPath "FieldMapping.ps1"
$dataTypesPath = Join-Path -Path $scriptPath -ChildPath "DataTypes.ps1"

if (Test-Path -Path $indexableFieldsPath) {
    . $indexableFieldsPath
} else {
    Write-Error "Le fichier IndexableFields.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $fieldMappingPath) {
    . $fieldMappingPath
} else {
    Write-Error "Le fichier FieldMapping.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $dataTypesPath) {
    . $dataTypesPath
} else {
    Write-Error "Le fichier DataTypes.ps1 est introuvable."
    exit 1
}

# Structure définissant le schéma de l'index
$script:IndexSchema = @{
    # Métadonnées du schéma
    Metadata = @{
        Name = "restore_points_index"
        Version = "1.0"
        Description = "Schéma d'index pour les métadonnées des points de restauration"
        CreatedAt = (Get-Date).ToString("o")
        UpdatedAt = (Get-Date).ToString("o")
        Author = "System"
    }
    
    # Configuration de l'index
    Config = @{
        # Type de moteur d'indexation
        Engine = "Internal"
        
        # Options de stockage
        Storage = @{
            # Type de stockage (File, Memory, Database)
            Type = "File"
            
            # Chemin du répertoire de stockage (pour le type File)
            Path = "index"
            
            # Format de fichier (JSON, Binary)
            Format = "JSON"
            
            # Compression (None, GZip, Deflate)
            Compression = "GZip"
            
            # Chiffrement (None, AES)
            Encryption = "None"
            
            # Segmentation (taille maximale d'un segment en Mo)
            SegmentSize = 10
            
            # Nombre maximal de documents par segment
            MaxDocumentsPerSegment = 1000
        }
        
        # Options d'indexation
        Indexing = @{
            # Indexation asynchrone
            Async = $true
            
            # Intervalle de commit (en secondes)
            CommitInterval = 60
            
            # Nombre maximal de documents en mémoire avant commit
            MaxPendingDocuments = 100
            
            # Optimisation automatique
            AutoOptimize = $true
            
            # Intervalle d'optimisation (en heures)
            OptimizeInterval = 24
            
            # Seuil de fusion des segments (pourcentage de documents supprimés)
            MergeThreshold = 20
        }
        
        # Options de recherche
        Search = @{
            # Nombre maximal de résultats par requête
            MaxResults = 1000
            
            # Délai d'expiration des requêtes (en secondes)
            Timeout = 30
            
            # Score minimal pour les résultats
            MinScore = 0.1
            
            # Mise en cache des requêtes
            CacheEnabled = $true
            
            # Taille du cache (nombre de requêtes)
            CacheSize = 100
            
            # Durée de vie du cache (en minutes)
            CacheTTL = 15
        }
    }
    
    # Structure des documents
    Documents = @{
        # Champ d'identifiant unique
        IdField = "id"
        
        # Champs obligatoires
        RequiredFields = @(
            "id",
            "created_at",
            "archive_id",
            "archive_path"
        )
        
        # Champs indexés
        IndexedFields = @()  # Sera rempli dynamiquement
        
        # Champs stockés mais non indexés
        StoredFields = @(
            "file_path"
        )
        
        # Champs calculés
        ComputedFields = @{
            "search_text" = @{
                Type = "Text"
                Sources = @("id", "name", "type", "configuration_types")
                Generator = {
                    param($doc)
                    $text = ""
                    if ($doc.PSObject.Properties.Name.Contains("id")) { $text += "$($doc.id) " }
                    if ($doc.PSObject.Properties.Name.Contains("name")) { $text += "$($doc.name) " }
                    if ($doc.PSObject.Properties.Name.Contains("type")) { $text += "$($doc.type) " }
                    if ($doc.PSObject.Properties.Name.Contains("configuration_types")) {
                        foreach ($type in $doc.configuration_types) {
                            $text += "$type "
                        }
                    }
                    return $text.Trim()
                }
            }
        }
    }
    
    # Mappings des champs
    Mappings = @{}  # Sera rempli dynamiquement
    
    # Analyseurs de texte
    Analyzers = @{
        # Analyseur standard
        Standard = @{
            Type = "standard"
            Tokenizer = "standard"
            Filters = @("lowercase", "stop", "stemmer")
        }
        
        # Analyseur pour mots-clés
        Keyword = @{
            Type = "keyword"
            Tokenizer = "keyword"
            Filters = @("lowercase")
        }
        
        # Analyseur pour recherche
        Search = @{
            Type = "search"
            Tokenizer = "standard"
            Filters = @("lowercase", "stop", "stemmer", "synonym")
        }
    }
    
    # Filtres de texte
    Filters = @{
        # Filtre pour mots vides
        Stop = @{
            Type = "stop"
            StopWords = @("a", "an", "and", "are", "as", "at", "be", "but", "by", "for", "if", "in", "into", "is", "it", "no", "not", "of", "on", "or", "such", "that", "the", "their", "then", "there", "these", "they", "this", "to", "was", "will", "with")
        }
        
        # Filtre pour racinisation
        Stemmer = @{
            Type = "stemmer"
            Language = "english"
        }
        
        # Filtre pour synonymes
        Synonym = @{
            Type = "synonym"
            Synonyms = @(
                "restore, backup, save",
                "config, configuration, setting",
                "archive, compress, zip"
            )
        }
    }
}

# Fonction pour initialiser le schéma d'index
function Initialize-IndexSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Internal", "Elasticsearch", "Qdrant")]
        [string]$Engine = "Internal"
    )
    
    # Mettre à jour le moteur d'indexation
    $script:IndexSchema.Config.Engine = $Engine
    
    # Obtenir tous les champs indexables
    $indexableFields = Get-IndexableFields
    
    # Remplir les champs indexés
    $script:IndexSchema.Documents.IndexedFields = $indexableFields | Where-Object { $_.Searchable -or $_.Filterable -or $_.Sortable } | ForEach-Object { $_.Name }
    
    # Générer le mapping des champs
    $mapping = New-FieldMapping -Engine $Engine
    
    if ($null -ne $mapping) {
        $script:IndexSchema.Mappings = $mapping
    }
    
    # Mettre à jour les dates
    $script:IndexSchema.Metadata.UpdatedAt = (Get-Date).ToString("o")
    
    return $script:IndexSchema
}

# Fonction pour obtenir le schéma d'index
function Get-IndexSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Internal", "Elasticsearch", "Qdrant")]
        [string]$Engine = "Internal"
    )
    
    # Initialiser le schéma si nécessaire
    if ($script:IndexSchema.Mappings.Count -eq 0 -or $script:IndexSchema.Config.Engine -ne $Engine) {
        Initialize-IndexSchema -Engine $Engine
    }
    
    return $script:IndexSchema
}

# Fonction pour sauvegarder le schéma d'index dans un fichier
function Save-IndexSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Internal", "Elasticsearch", "Qdrant")]
        [string]$Engine = "Internal"
    )
    
    # Obtenir le schéma d'index
    $schema = Get-IndexSchema -Engine $Engine
    
    # Sauvegarder le schéma
    try {
        $schema | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        Write-Verbose "Schéma d'index sauvegardé dans $Path"
        return $true
    } catch {
        Write-Error "Erreur lors de la sauvegarde du schéma d'index: $_"
        return $false
    }
}

# Fonction pour charger un schéma d'index depuis un fichier
function Import-IndexSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier de schéma d'index n'existe pas: $Path"
        return $false
    }
    
    # Charger le schéma
    try {
        $schema = Get-Content -Path $Path -Raw | ConvertFrom-Json
        
        # Convertir le schéma en hashtable
        $script:IndexSchema = @{}
        
        foreach ($property in $schema.PSObject.Properties) {
            $script:IndexSchema[$property.Name] = $property.Value
        }
        
        Write-Verbose "Schéma d'index chargé depuis $Path"
        return $true
    } catch {
        Write-Error "Erreur lors du chargement du schéma d'index: $_"
        return $false
    }
}

# Fonction pour valider un document selon le schéma
function Test-DocumentAgainstSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Document,
        
        [Parameter(Mandatory = $false)]
        [switch]$Strict
    )
    
    # Vérifier les champs obligatoires
    foreach ($field in $script:IndexSchema.Documents.RequiredFields) {
        if (-not $Document.PSObject.Properties.Name.Contains($field) -or $null -eq $Document.$field) {
            Write-Error "Champ obligatoire manquant: $field"
            return $false
        }
    }
    
    # Vérifier les types de données si mode strict
    if ($Strict) {
        foreach ($fieldName in $script:IndexSchema.Mappings.Keys) {
            # Ignorer les champs spéciaux commençant par _
            if ($fieldName.StartsWith("_")) {
                continue
            }
            
            $fieldDef = $script:IndexSchema.Mappings[$fieldName]
            
            # Ignorer les champs non présents dans le document
            if (-not $Document.PSObject.Properties.Name.Contains($fieldName)) {
                continue
            }
            
            $value = $Document.$fieldName
            
            # Vérifier le type de données
            $typeName = switch ($fieldDef.Type) {
                "string" { if ($fieldDef.Analyzer -eq "keyword") { "Keyword" } else { "Text" } }
                "keyword" { "Keyword" }
                "text" { "Text" }
                "number" { "Numeric" }
                "double" { "Numeric" }
                "float" { "Numeric" }
                "date" { "Date" }
                "datetime" { "Date" }
                "boolean" { "Boolean" }
                "bool" { "Boolean" }
                default { "Text" }
            }
            
            if (-not (Test-DataTypeValue -Value $value -TypeName $typeName)) {
                Write-Error "Valeur invalide pour le champ $fieldName: $value (type attendu: $typeName)"
                return $false
            }
        }
    }
    
    return $true
}

# Fonction pour normaliser un document selon le schéma
function ConvertTo-NormalizedDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Document
    )
    
    # Créer un nouveau document normalisé
    $normalizedDoc = @{}
    
    # Copier les champs existants
    foreach ($property in $Document.PSObject.Properties) {
        $normalizedDoc[$property.Name] = $property.Value
    }
    
    # Normaliser les champs selon leur type
    foreach ($fieldName in $script:IndexSchema.Mappings.Keys) {
        # Ignorer les champs spéciaux commençant par _
        if ($fieldName.StartsWith("_")) {
            continue
        }
        
        $fieldDef = $script:IndexSchema.Mappings[$fieldName]
        
        # Ignorer les champs non présents dans le document
        if (-not $normalizedDoc.ContainsKey($fieldName)) {
            continue
        }
        
        $value = $normalizedDoc[$fieldName]
        
        # Déterminer le type de données
        $typeName = switch ($fieldDef.Type) {
            "string" { if ($fieldDef.Analyzer -eq "keyword") { "Keyword" } else { "Text" } }
            "keyword" { "Keyword" }
            "text" { "Text" }
            "number" { "Numeric" }
            "double" { "Numeric" }
            "float" { "Numeric" }
            "date" { "Date" }
            "datetime" { "Date" }
            "boolean" { "Boolean" }
            "bool" { "Boolean" }
            default { "Text" }
        }
        
        # Normaliser la valeur
        $normalizedDoc[$fieldName] = ConvertTo-DataTypeValue -Value $value -TypeName $typeName
    }
    
    # Ajouter les champs calculés
    foreach ($fieldName in $script:IndexSchema.Documents.ComputedFields.Keys) {
        $computedField = $script:IndexSchema.Documents.ComputedFields[$fieldName]
        $generator = $computedField.Generator
        
        $normalizedDoc[$fieldName] = & $generator $normalizedDoc
    }
    
    return $normalizedDoc
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-IndexSchema, Get-IndexSchema, Save-IndexSchema, Import-IndexSchema, Test-DocumentAgainstSchema, ConvertTo-NormalizedDocument
