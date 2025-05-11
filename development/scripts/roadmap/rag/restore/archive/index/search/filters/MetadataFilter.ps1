# MetadataFilter.ps1
# Script implémentant les filtres par métadonnées pour la recherche avancée
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$searchPath = Split-Path -Parent $parentPath
$indexPath = Split-Path -Parent $searchPath
$performancePath = Join-Path -Path $indexPath -ChildPath "performance\PerformanceMetrics.ps1"

if (Test-Path -Path $performancePath) {
    . $performancePath
} else {
    Write-Error "Le fichier PerformanceMetrics.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une condition de filtre
class FilterCondition {
    # Champ à filtrer
    [string]$Field
    
    # Opérateur de comparaison (EQ, NE, GT, GE, LT, LE, CONTAINS, STARTS_WITH, ENDS_WITH, MATCHES)
    [string]$Operator
    
    # Valeur à comparer
    [object]$Value
    
    # Constructeur par défaut
    FilterCondition() {
        $this.Field = ""
        $this.Operator = "EQ"
        $this.Value = $null
    }
    
    # Constructeur avec champ et valeur
    FilterCondition([string]$field, [object]$value) {
        $this.Field = $field
        $this.Operator = "EQ"
        $this.Value = $value
    }
    
    # Constructeur complet
    FilterCondition([string]$field, [string]$operator, [object]$value) {
        $this.Field = $field
        $this.Operator = $operator
        $this.Value = $value
    }
    
    # Méthode pour vérifier si une valeur correspond à la condition
    [bool] Matches([object]$fieldValue) {
        # Si la valeur du champ est null, elle ne correspond que si la valeur à comparer est également null
        if ($null -eq $fieldValue) {
            return $null -eq $this.Value
        }
        
        # Si la valeur à comparer est null, elle ne correspond que si la valeur du champ est également null
        if ($null -eq $this.Value) {
            return $null -eq $fieldValue
        }
        
        # Comparer les valeurs selon l'opérateur
        switch ($this.Operator) {
            "EQ" { return $fieldValue -eq $this.Value }
            "NE" { return $fieldValue -ne $this.Value }
            "GT" { return $fieldValue -gt $this.Value }
            "GE" { return $fieldValue -ge $this.Value }
            "LT" { return $fieldValue -lt $this.Value }
            "LE" { return $fieldValue -le $this.Value }
            "CONTAINS" {
                if ($fieldValue -is [string] -and $this.Value -is [string]) {
                    return $fieldValue.Contains($this.Value)
                } elseif ($fieldValue -is [array] -or $fieldValue -is [System.Collections.IList]) {
                    return $fieldValue -contains $this.Value
                } else {
                    return $false
                }
            }
            "STARTS_WITH" {
                if ($fieldValue -is [string] -and $this.Value -is [string]) {
                    return $fieldValue.StartsWith($this.Value)
                } else {
                    return $false
                }
            }
            "ENDS_WITH" {
                if ($fieldValue -is [string] -and $this.Value -is [string]) {
                    return $fieldValue.EndsWith($this.Value)
                } else {
                    return $false
                }
            }
            "MATCHES" {
                if ($fieldValue -is [string] -and $this.Value -is [string]) {
                    return $fieldValue -match $this.Value
                } else {
                    return $false
                }
            }
            default { return $fieldValue -eq $this.Value }
        }
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $valueStr = if ($null -eq $this.Value) {
            "null"
        } elseif ($this.Value -is [string]) {
            "'$($this.Value)'"
        } else {
            $this.Value.ToString()
        }
        
        return "$($this.Field) $($this.Operator) $valueStr"
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            field = $this.Field
            operator = $this.Operator
            value = $this.Value
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [FilterCondition] FromHashtable([hashtable]$data) {
        $field = if ($data.ContainsKey("field")) { $data.field } else { "" }
        $operator = if ($data.ContainsKey("operator")) { $data.operator } else { "EQ" }
        $value = if ($data.ContainsKey("value")) { $data.value } else { $null }
        
        return [FilterCondition]::new($field, $operator, $value)
    }
}

# Classe pour représenter un filtre par métadonnées
class MetadataFilter {
    # Liste des conditions
    [System.Collections.Generic.List[FilterCondition]]$Conditions
    
    # Opérateur logique (AND, OR)
    [string]$LogicalOperator
    
    # Constructeur par défaut
    MetadataFilter() {
        $this.Conditions = [System.Collections.Generic.List[FilterCondition]]::new()
        $this.LogicalOperator = "AND"
    }
    
    # Constructeur avec opérateur logique
    MetadataFilter([string]$logicalOperator) {
        $this.Conditions = [System.Collections.Generic.List[FilterCondition]]::new()
        $this.LogicalOperator = $logicalOperator
    }
    
    # Méthode pour ajouter une condition
    [void] AddCondition([FilterCondition]$condition) {
        $this.Conditions.Add($condition)
    }
    
    # Méthode pour ajouter une condition avec champ et valeur
    [void] AddCondition([string]$field, [object]$value) {
        $this.Conditions.Add([FilterCondition]::new($field, $value))
    }
    
    # Méthode pour ajouter une condition avec champ, opérateur et valeur
    [void] AddCondition([string]$field, [string]$operator, [object]$value) {
        $this.Conditions.Add([FilterCondition]::new($field, $operator, $value))
    }
    
    # Méthode pour vérifier si un document correspond au filtre
    [bool] Matches([IndexDocument]$document) {
        # Si aucune condition n'est spécifiée, le document correspond
        if ($this.Conditions.Count -eq 0) {
            return $true
        }
        
        # Vérifier chaque condition
        foreach ($condition in $this.Conditions) {
            # Vérifier si le document a le champ
            $hasField = $document.Content.ContainsKey($condition.Field)
            
            # Récupérer la valeur du champ
            $fieldValue = if ($hasField) { $document.Content[$condition.Field] } else { $null }
            
            # Vérifier si la valeur correspond à la condition
            $matches = $condition.Matches($fieldValue)
            
            # Appliquer l'opérateur logique
            if ($this.LogicalOperator -eq "AND" -and -not $matches) {
                return $false
            } elseif ($this.LogicalOperator -eq "OR" -and $matches) {
                return $true
            }
        }
        
        # Si l'opérateur est AND, toutes les conditions doivent correspondre
        # Si l'opérateur est OR, au moins une condition doit correspondre
        return $this.LogicalOperator -eq "AND"
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $conditionsStr = $this.Conditions | ForEach-Object { $_.ToString() }
        return "($($conditionsStr -join " $($this.LogicalOperator) "))"
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            conditions = $this.Conditions | ForEach-Object { $_.ToHashtable() }
            logical_operator = $this.LogicalOperator
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [MetadataFilter] FromHashtable([hashtable]$data) {
        $logicalOperator = if ($data.ContainsKey("logical_operator")) { $data.logical_operator } else { "AND" }
        $filter = [MetadataFilter]::new($logicalOperator)
        
        if ($data.ContainsKey("conditions")) {
            foreach ($conditionData in $data.conditions) {
                $condition = [FilterCondition]::FromHashtable($conditionData)
                $filter.AddCondition($condition)
            }
        }
        
        return $filter
    }
}

# Classe pour représenter un gestionnaire de filtres par métadonnées
class MetadataFilterManager {
    # Dictionnaire des champs de métadonnées disponibles
    [System.Collections.Generic.Dictionary[string, hashtable]]$AvailableFields
    
    # Métriques de performance
    [PerformanceMetricsManager]$Metrics
    
    # Constructeur par défaut
    MetadataFilterManager() {
        $this.AvailableFields = [System.Collections.Generic.Dictionary[string, hashtable]]::new()
        $this.Metrics = [PerformanceMetricsManager]::new()
        
        # Initialiser les champs par défaut
        $this.InitializeDefaultFields()
    }
    
    # Méthode pour initialiser les champs par défaut
    [void] InitializeDefaultFields() {
        # Champ: title
        $this.RegisterField("title", "Titre", @{
            description = "Titre du document"
            type = "string"
        })
        
        # Champ: description
        $this.RegisterField("description", "Description", @{
            description = "Description du document"
            type = "string"
        })
        
        # Champ: author
        $this.RegisterField("author", "Auteur", @{
            description = "Auteur du document"
            type = "string"
        })
        
        # Champ: tags
        $this.RegisterField("tags", "Tags", @{
            description = "Tags associés au document"
            type = "array"
        })
        
        # Champ: category
        $this.RegisterField("category", "Catégorie", @{
            description = "Catégorie du document"
            type = "string"
        })
        
        # Champ: status
        $this.RegisterField("status", "Statut", @{
            description = "Statut du document"
            type = "string"
        })
        
        # Champ: priority
        $this.RegisterField("priority", "Priorité", @{
            description = "Priorité du document"
            type = "number"
        })
        
        # Champ: size
        $this.RegisterField("size", "Taille", @{
            description = "Taille du document en octets"
            type = "number"
        })
        
        # Champ: language
        $this.RegisterField("language", "Langue", @{
            description = "Langue du document"
            type = "string"
        })
        
        # Champ: version
        $this.RegisterField("version", "Version", @{
            description = "Version du document"
            type = "string"
        })
    }
    
    # Méthode pour enregistrer un champ
    [void] RegisterField([string]$id, [string]$name, [hashtable]$metadata = @{}) {
        $field = @{
            id = $id
            name = $name
            metadata = $metadata
        }
        
        $this.AvailableFields[$id] = $field
    }
    
    # Méthode pour obtenir un champ
    [hashtable] GetField([string]$id) {
        if (-not $this.AvailableFields.ContainsKey($id)) {
            return $null
        }
        
        return $this.AvailableFields[$id]
    }
    
    # Méthode pour supprimer un champ
    [bool] RemoveField([string]$id) {
        return $this.AvailableFields.Remove($id)
    }
    
    # Méthode pour obtenir tous les champs
    [hashtable[]] GetAllFields() {
        return $this.AvailableFields.Values
    }
    
    # Méthode pour créer une condition
    [FilterCondition] CreateCondition([string]$field, [string]$operator, [object]$value) {
        return [FilterCondition]::new($field, $operator, $value)
    }
    
    # Méthode pour créer un filtre
    [MetadataFilter] CreateFilter([string]$logicalOperator = "AND") {
        return [MetadataFilter]::new($logicalOperator)
    }
    
    # Méthode pour appliquer un filtre à une liste de documents
    [IndexDocument[]] ApplyFilter([MetadataFilter]$filter, [IndexDocument[]]$documents) {
        $timer = $this.Metrics.GetTimer("metadata_filter.apply_filter")
        $timer.Start()
        
        $result = $documents | Where-Object { $filter.Matches($_) }
        
        $timer.Stop()
        
        # Incrémenter les compteurs
        $this.Metrics.IncrementCounter("metadata_filter.documents_filtered", $documents.Count)
        $this.Metrics.IncrementCounter("metadata_filter.documents_matched", $result.Count)
        
        return $result
    }
    
    # Méthode pour obtenir les statistiques du filtre
    [hashtable] GetStats() {
        return @{
            available_fields = $this.AvailableFields.Count
            metrics = $this.Metrics.GetAllMetrics()
        }
    }
}

# Fonction pour créer une condition de filtre
function New-FilterCondition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("EQ", "NE", "GT", "GE", "LT", "LE", "CONTAINS", "STARTS_WITH", "ENDS_WITH", "MATCHES")]
        [string]$Operator = "EQ",
        
        [Parameter(Mandatory = $false)]
        [object]$Value = $null
    )
    
    return [FilterCondition]::new($Field, $Operator, $Value)
}

# Fonction pour créer un filtre par métadonnées
function New-MetadataFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("AND", "OR")]
        [string]$LogicalOperator = "AND"
    )
    
    return [MetadataFilter]::new($LogicalOperator)
}

# Fonction pour créer un gestionnaire de filtres par métadonnées
function New-MetadataFilterManager {
    [CmdletBinding()]
    param ()
    
    return [MetadataFilterManager]::new()
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-FilterCondition, New-MetadataFilter, New-MetadataFilterManager
