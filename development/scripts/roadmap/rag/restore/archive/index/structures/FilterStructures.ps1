# FilterStructures.ps1
# Script implémentant les structures pour le filtrage des métadonnées
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$invertedIndexPath = Join-Path -Path $scriptPath -ChildPath "InvertedIndex.ps1"

if (Test-Path -Path $invertedIndexPath) {
    . $invertedIndexPath
} else {
    Write-Error "Le fichier InvertedIndex.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un filtre
class Filter {
    # Type de filtre
    [string]$Type
    
    # Champ sur lequel appliquer le filtre
    [string]$Field
    
    # Constructeur par défaut
    Filter() {
        $this.Type = "base"
        $this.Field = ""
    }
    
    # Constructeur avec champ
    Filter([string]$field) {
        $this.Type = "base"
        $this.Field = $field
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        # Méthode de base, à surcharger dans les classes dérivées
        return @()
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "Filter($($this.Type), $($this.Field))"
    }
}

# Classe pour représenter un filtre de terme exact
class TermFilter : Filter {
    # Terme à rechercher
    [string]$Term
    
    # Constructeur par défaut
    TermFilter() : base() {
        $this.Type = "term"
        $this.Term = ""
    }
    
    # Constructeur avec champ et terme
    TermFilter([string]$field, [string]$term) : base($field) {
        $this.Type = "term"
        $this.Term = $term
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        return $index.SearchExact($this.Field, $this.Term)
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "TermFilter($($this.Field):$($this.Term))"
    }
}

# Classe pour représenter un filtre de préfixe
class PrefixFilter : Filter {
    # Préfixe à rechercher
    [string]$Prefix
    
    # Constructeur par défaut
    PrefixFilter() : base() {
        $this.Type = "prefix"
        $this.Prefix = ""
    }
    
    # Constructeur avec champ et préfixe
    PrefixFilter([string]$field, [string]$prefix) : base($field) {
        $this.Type = "prefix"
        $this.Prefix = $prefix
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        return $index.SearchPrefix($this.Field, $this.Prefix)
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "PrefixFilter($($this.Field):$($this.Prefix)*)"
    }
}

# Classe pour représenter un filtre d'expression régulière
class RegexFilter : Filter {
    # Motif à rechercher
    [string]$Pattern
    
    # Constructeur par défaut
    RegexFilter() : base() {
        $this.Type = "regex"
        $this.Pattern = ""
    }
    
    # Constructeur avec champ et motif
    RegexFilter([string]$field, [string]$pattern) : base($field) {
        $this.Type = "regex"
        $this.Pattern = $pattern
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        return $index.SearchRegex($this.Field, $this.Pattern)
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "RegexFilter($($this.Field):/$($this.Pattern)/)"
    }
}

# Classe pour représenter un filtre de plage
class RangeFilter : Filter {
    # Valeur minimale
    [object]$Min
    
    # Valeur maximale
    [object]$Max
    
    # Constructeur par défaut
    RangeFilter() : base() {
        $this.Type = "range"
        $this.Min = $null
        $this.Max = $null
    }
    
    # Constructeur avec champ et plage
    RangeFilter([string]$field, [object]$min, [object]$max) : base($field) {
        $this.Type = "range"
        $this.Min = $min
        $this.Max = $max
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        return $index.SearchRange($this.Field, $this.Min, $this.Max)
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "RangeFilter($($this.Field):[$($this.Min) TO $($this.Max)])"
    }
}

# Classe pour représenter un filtre de texte
class TextFilter : Filter {
    # Requête à rechercher
    [string]$Query
    
    # Score minimal
    [double]$MinScore
    
    # Constructeur par défaut
    TextFilter() : base() {
        $this.Type = "text"
        $this.Query = ""
        $this.MinScore = 0.0
    }
    
    # Constructeur avec champ et requête
    TextFilter([string]$field, [string]$query) : base($field) {
        $this.Type = "text"
        $this.Query = $query
        $this.MinScore = 0.0
    }
    
    # Constructeur avec champ, requête et score minimal
    TextFilter([string]$field, [string]$query, [double]$minScore) : base($field) {
        $this.Type = "text"
        $this.Query = $query
        $this.MinScore = $minScore
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        $results = $index.SearchText($this.Field, $this.Query)
        
        # Filtrer par score minimal
        $filteredResults = [System.Collections.Generic.List[string]]::new()
        
        foreach ($docId in $results.Keys) {
            if ($results[$docId] -ge $this.MinScore) {
                $filteredResults.Add($docId)
            }
        }
        
        return $filteredResults.ToArray()
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "TextFilter($($this.Field):""$($this.Query)"", MinScore=$($this.MinScore))"
    }
}

# Classe pour représenter un filtre booléen
class BooleanFilter : Filter {
    # Valeur à rechercher
    [bool]$Value
    
    # Constructeur par défaut
    BooleanFilter() : base() {
        $this.Type = "boolean"
        $this.Value = $false
    }
    
    # Constructeur avec champ et valeur
    BooleanFilter([string]$field, [bool]$value) : base($field) {
        $this.Type = "boolean"
        $this.Value = $value
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        return $index.SearchExact($this.Field, $this.Value.ToString().ToLower())
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "BooleanFilter($($this.Field):$($this.Value))"
    }
}

# Classe pour représenter un filtre composite (AND)
class AndFilter : Filter {
    # Liste des filtres à combiner
    [System.Collections.Generic.List[Filter]]$Filters
    
    # Constructeur par défaut
    AndFilter() : base() {
        $this.Type = "and"
        $this.Filters = [System.Collections.Generic.List[Filter]]::new()
    }
    
    # Constructeur avec filtres
    AndFilter([Filter[]]$filters) : base() {
        $this.Type = "and"
        $this.Filters = [System.Collections.Generic.List[Filter]]::new($filters)
    }
    
    # Méthode pour ajouter un filtre
    [void] AddFilter([Filter]$filter) {
        $this.Filters.Add($filter)
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        # Si aucun filtre, retourner un ensemble vide
        if ($this.Filters.Count -eq 0) {
            return @()
        }
        
        # Appliquer le premier filtre
        $result = $this.Filters[0].Apply($index)
        
        # Si le résultat est vide, retourner un ensemble vide
        if ($result.Count -eq 0) {
            return @()
        }
        
        # Créer un ensemble à partir du résultat
        $resultSet = [System.Collections.Generic.HashSet[string]]::new($result)
        
        # Appliquer les filtres suivants
        for ($i = 1; $i -lt $this.Filters.Count; $i++) {
            $filter = $this.Filters[$i]
            $filterResult = $filter.Apply($index)
            
            # Si le résultat est vide, retourner un ensemble vide
            if ($filterResult.Count -eq 0) {
                return @()
            }
            
            # Créer un ensemble à partir du résultat du filtre
            $filterSet = [System.Collections.Generic.HashSet[string]]::new($filterResult)
            
            # Intersection avec le résultat précédent
            $resultSet.IntersectWith($filterSet)
            
            # Si le résultat est vide, retourner un ensemble vide
            if ($resultSet.Count -eq 0) {
                return @()
            }
        }
        
        # Retourner le résultat
        return $resultSet.ToArray()
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $filterStrings = $this.Filters | ForEach-Object { $_.ToString() }
        return "AndFilter($($filterStrings -join ' AND '))"
    }
}

# Classe pour représenter un filtre composite (OR)
class OrFilter : Filter {
    # Liste des filtres à combiner
    [System.Collections.Generic.List[Filter]]$Filters
    
    # Constructeur par défaut
    OrFilter() : base() {
        $this.Type = "or"
        $this.Filters = [System.Collections.Generic.List[Filter]]::new()
    }
    
    # Constructeur avec filtres
    OrFilter([Filter[]]$filters) : base() {
        $this.Type = "or"
        $this.Filters = [System.Collections.Generic.List[Filter]]::new($filters)
    }
    
    # Méthode pour ajouter un filtre
    [void] AddFilter([Filter]$filter) {
        $this.Filters.Add($filter)
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        # Si aucun filtre, retourner un ensemble vide
        if ($this.Filters.Count -eq 0) {
            return @()
        }
        
        # Créer un ensemble pour le résultat
        $resultSet = [System.Collections.Generic.HashSet[string]]::new()
        
        # Appliquer tous les filtres
        foreach ($filter in $this.Filters) {
            $filterResult = $filter.Apply($index)
            
            # Ajouter les résultats à l'ensemble
            foreach ($docId in $filterResult) {
                $resultSet.Add($docId)
            }
        }
        
        # Retourner le résultat
        return $resultSet.ToArray()
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $filterStrings = $this.Filters | ForEach-Object { $_.ToString() }
        return "OrFilter($($filterStrings -join ' OR '))"
    }
}

# Classe pour représenter un filtre composite (NOT)
class NotFilter : Filter {
    # Filtre à inverser
    [Filter]$Filter
    
    # Constructeur par défaut
    NotFilter() : base() {
        $this.Type = "not"
        $this.Filter = $null
    }
    
    # Constructeur avec filtre
    NotFilter([Filter]$filter) : base() {
        $this.Type = "not"
        $this.Filter = $filter
    }
    
    # Méthode pour appliquer le filtre
    [string[]] Apply([InvertedIndex]$index) {
        # Si aucun filtre, retourner un ensemble vide
        if ($null -eq $this.Filter) {
            return @()
        }
        
        # Obtenir tous les documents
        $allDocs = [System.Collections.Generic.HashSet[string]]::new()
        
        # Parcourir tous les termes
        foreach ($termKey in $index.Terms.Keys) {
            foreach ($docId in $index.Terms[$termKey]) {
                $allDocs.Add($docId)
            }
        }
        
        # Appliquer le filtre
        $filterResult = $this.Filter.Apply($index)
        
        # Créer un ensemble à partir du résultat du filtre
        $filterSet = [System.Collections.Generic.HashSet[string]]::new($filterResult)
        
        # Différence avec tous les documents
        $allDocs.ExceptWith($filterSet)
        
        # Retourner le résultat
        return $allDocs.ToArray()
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "NotFilter(NOT $($this.Filter.ToString()))"
    }
}

# Fonction pour créer un filtre de terme
function New-TermFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $true)]
        [string]$Term
    )
    
    return [TermFilter]::new($Field, $Term)
}

# Fonction pour créer un filtre de préfixe
function New-PrefixFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $true)]
        [string]$Prefix
    )
    
    return [PrefixFilter]::new($Field, $Prefix)
}

# Fonction pour créer un filtre d'expression régulière
function New-RegexFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )
    
    return [RegexFilter]::new($Field, $Pattern)
}

# Fonction pour créer un filtre de plage
function New-RangeFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $false)]
        [object]$Min = $null,
        
        [Parameter(Mandatory = $false)]
        [object]$Max = $null
    )
    
    return [RangeFilter]::new($Field, $Min, $Max)
}

# Fonction pour créer un filtre de texte
function New-TextFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [double]$MinScore = 0.0
    )
    
    return [TextFilter]::new($Field, $Query, $MinScore)
}

# Fonction pour créer un filtre booléen
function New-BooleanFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $true)]
        [bool]$Value
    )
    
    return [BooleanFilter]::new($Field, $Value)
}

# Fonction pour créer un filtre AND
function New-AndFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Filter[]]$Filters
    )
    
    return [AndFilter]::new($Filters)
}

# Fonction pour créer un filtre OR
function New-OrFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Filter[]]$Filters
    )
    
    return [OrFilter]::new($Filters)
}

# Fonction pour créer un filtre NOT
function New-NotFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Filter]$Filter
    )
    
    return [NotFilter]::new($Filter)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-TermFilter, New-PrefixFilter, New-RegexFilter, New-RangeFilter, New-TextFilter, New-BooleanFilter, New-AndFilter, New-OrFilter, New-NotFilter
