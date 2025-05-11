# IndexableFields.ps1
# Script définissant les champs indexables prioritaires pour les métadonnées des points de restauration
# Version: 1.0
# Date: 2025-05-15

# Structure définissant les champs indexables prioritaires
# Cette structure est utilisée pour configurer le moteur d'indexation
# et déterminer quels champs des métadonnées doivent être indexés
$script:IndexableFields = @{
    # Champs d'identification
    Identity = @{
        # Identifiant unique du point de restauration
        Id = @{
            Name = "id"                      # Nom du champ dans les métadonnées
            Type = "Keyword"                 # Type d'indexation (Keyword, Text, Numeric, Date, Boolean)
            Priority = 100                   # Priorité (plus élevée = plus important)
            Searchable = $true               # Peut être recherché directement
            Filterable = $true               # Peut être utilisé comme filtre
            Sortable = $true                 # Peut être utilisé pour trier les résultats
            Required = $true                 # Champ obligatoire
            Description = "Identifiant unique du point de restauration"
        }
        
        # Nom du point de restauration
        Name = @{
            Name = "name"
            Type = "Text"
            Priority = 90
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Nom du point de restauration"
        }
        
        # Type du point de restauration
        Type = @{
            Name = "type"
            Type = "Keyword"
            Priority = 85
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Type du point de restauration (manuel, automatique, etc.)"
        }
    }
    
    # Champs temporels
    Temporal = @{
        # Date de création du point de restauration
        CreatedAt = @{
            Name = "created_at"
            Type = "Date"
            Priority = 95
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $true
            Description = "Date de création du point de restauration"
        }
        
        # Année de création (pour filtrage rapide)
        CreatedYear = @{
            Name = "created_year"
            Type = "Numeric"
            Priority = 80
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Année de création du point de restauration"
        }
        
        # Mois de création (pour filtrage rapide)
        CreatedMonth = @{
            Name = "created_month"
            Type = "Numeric"
            Priority = 75
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Mois de création du point de restauration (1-12)"
        }
        
        # Jour de création (pour filtrage rapide)
        CreatedDay = @{
            Name = "created_day"
            Type = "Numeric"
            Priority = 70
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Jour de création du point de restauration (1-31)"
        }
        
        # Date de dernière restauration
        LastRestored = @{
            Name = "restore_info.last_restored"
            Type = "Date"
            Priority = 65
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Date de dernière restauration du point"
        }
    }
    
    # Champs de contenu
    Content = @{
        # Configurations incluses dans le point de restauration
        ConfigurationTypes = @{
            Name = "configuration_types"
            Type = "Keyword"
            Priority = 85
            Searchable = $true
            Filterable = $true
            Sortable = $false
            Required = $false
            Description = "Types de configurations incluses dans le point de restauration"
            IsArray = $true
        }
        
        # Identifiants des configurations
        ConfigurationIds = @{
            Name = "configuration_ids"
            Type = "Keyword"
            Priority = 80
            Searchable = $true
            Filterable = $true
            Sortable = $false
            Required = $false
            Description = "Identifiants des configurations incluses dans le point de restauration"
            IsArray = $true
        }
        
        # Niveau d'importance du point de restauration
        Importance = @{
            Name = "importance"
            Type = "Keyword"
            Priority = 85
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Niveau d'importance du point de restauration (Critical, High, Medium, Low)"
        }
        
        # Nombre de restaurations effectuées
        RestoreCount = @{
            Name = "restore_info.restore_count"
            Type = "Numeric"
            Priority = 60
            Searchable = $false
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Nombre de fois que le point a été restauré"
        }
        
        # Texte de recherche (combinaison de plusieurs champs)
        SearchText = @{
            Name = "search_text"
            Type = "Text"
            Priority = 100
            Searchable = $true
            Filterable = $false
            Sortable = $false
            Required = $false
            Description = "Texte de recherche combinant plusieurs champs pour la recherche full-text"
        }
    }
    
    # Champs d'archive
    Archive = @{
        # Identifiant de l'archive contenant le point de restauration
        ArchiveId = @{
            Name = "archive_id"
            Type = "Keyword"
            Priority = 75
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $true
            Description = "Identifiant de l'archive contenant le point de restauration"
        }
        
        # Chemin de l'archive
        ArchivePath = @{
            Name = "archive_path"
            Type = "Keyword"
            Priority = 70
            Searchable = $true
            Filterable = $true
            Sortable = $false
            Required = $true
            Description = "Chemin de l'archive contenant le point de restauration"
        }
        
        # Nom du fichier dans l'archive
        FileName = @{
            Name = "file_name"
            Type = "Keyword"
            Priority = 65
            Searchable = $true
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Nom du fichier du point de restauration dans l'archive"
        }
        
        # Taille du fichier
        FileSize = @{
            Name = "file_size"
            Type = "Numeric"
            Priority = 50
            Searchable = $false
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Taille du fichier du point de restauration en octets"
        }
        
        # Taille du fichier en KB (pour filtrage plus facile)
        FileSizeKB = @{
            Name = "file_size_kb"
            Type = "Numeric"
            Priority = 45
            Searchable = $false
            Filterable = $true
            Sortable = $true
            Required = $false
            Description = "Taille du fichier du point de restauration en kilooctets"
        }
    }
}

# Fonction pour obtenir tous les champs indexables
function Get-IndexableFields {
    [CmdletBinding()]
    param()
    
    $allFields = @()
    
    # Parcourir toutes les catégories
    foreach ($category in $script:IndexableFields.Keys) {
        $categoryFields = $script:IndexableFields[$category]
        
        # Parcourir tous les champs de la catégorie
        foreach ($fieldName in $categoryFields.Keys) {
            $field = $categoryFields[$fieldName]
            
            # Ajouter le nom de la catégorie et du champ
            $field.Category = $category
            $field.FieldName = $fieldName
            
            $allFields += $field
        }
    }
    
    # Trier les champs par priorité (décroissante)
    return $allFields | Sort-Object -Property Priority -Descending
}

# Fonction pour obtenir les champs indexables par catégorie
function Get-IndexableFieldsByCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Category = ""
    )
    
    if ([string]::IsNullOrEmpty($Category)) {
        $result = @{}
        
        foreach ($cat in $script:IndexableFields.Keys) {
            $result[$cat] = Get-IndexableFieldsByCategory -Category $cat
        }
        
        return $result
    } else {
        if (-not $script:IndexableFields.ContainsKey($Category)) {
            return @()
        }
        
        $categoryFields = $script:IndexableFields[$Category]
        $result = @()
        
        foreach ($fieldName in $categoryFields.Keys) {
            $field = $categoryFields[$fieldName]
            $field.Category = $Category
            $field.FieldName = $fieldName
            $result += $field
        }
        
        return $result | Sort-Object -Property Priority -Descending
    }
}

# Fonction pour obtenir les champs indexables par type
function Get-IndexableFieldsByType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Keyword", "Text", "Numeric", "Date", "Boolean")]
        [string]$Type
    )
    
    $allFields = Get-IndexableFields
    return $allFields | Where-Object { $_.Type -eq $Type }
}

# Fonction pour obtenir les champs indexables par propriété
function Get-IndexableFieldsByProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Searchable", "Filterable", "Sortable", "Required")]
        [string]$Property,
        
        [Parameter(Mandatory = $true)]
        [bool]$Value
    )
    
    $allFields = Get-IndexableFields
    return $allFields | Where-Object { $_.$Property -eq $Value }
}

# Fonction pour obtenir un champ indexable spécifique
function Get-IndexableField {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FieldPath
    )
    
    $parts = $FieldPath -split '\.'
    
    if ($parts.Count -lt 2) {
        Write-Error "Le chemin du champ doit être au format 'Catégorie.NomChamp'"
        return $null
    }
    
    $category = $parts[0]
    $fieldName = $parts[1]
    
    if (-not $script:IndexableFields.ContainsKey($category)) {
        Write-Error "Catégorie non trouvée: $category"
        return $null
    }
    
    $categoryFields = $script:IndexableFields[$category]
    
    if (-not $categoryFields.ContainsKey($fieldName)) {
        Write-Error "Champ non trouvé: $fieldName dans la catégorie $category"
        return $null
    }
    
    $field = $categoryFields[$fieldName]
    $field.Category = $category
    $field.FieldName = $fieldName
    
    return $field
}

# Exporter les fonctions
Export-ModuleMember -Function Get-IndexableFields, Get-IndexableFieldsByCategory, Get-IndexableFieldsByType, Get-IndexableFieldsByProperty, Get-IndexableField
