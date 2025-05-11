# FilterCombiner.ps1
# Script implémentant le combinateur de filtres pour la recherche avancée
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$typeFilterPath = Join-Path -Path $scriptPath -ChildPath "TypeFilter.ps1"
$dateFilterPath = Join-Path -Path $scriptPath -ChildPath "DateFilter.ps1"
$metadataFilterPath = Join-Path -Path $scriptPath -ChildPath "MetadataFilter.ps1"
$textFilterPath = Join-Path -Path $scriptPath -ChildPath "TextFilter.ps1"

if (Test-Path -Path $typeFilterPath) {
    . $typeFilterPath
} else {
    Write-Error "Le fichier TypeFilter.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $dateFilterPath) {
    . $dateFilterPath
} else {
    Write-Error "Le fichier DateFilter.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $metadataFilterPath) {
    . $metadataFilterPath
} else {
    Write-Error "Le fichier MetadataFilter.ps1 est introuvable."
    exit 1
}

if (Test-Path -Path $textFilterPath) {
    . $textFilterPath
} else {
    Write-Error "Le fichier TextFilter.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un filtre combiné
class CombinedFilter {
    # Liste des filtres par type
    [System.Collections.Generic.List[TypeFilter]]$TypeFilters
    
    # Liste des filtres par date
    [System.Collections.Generic.List[DateFilter]]$DateFilters
    
    # Liste des filtres par métadonnées
    [System.Collections.Generic.List[MetadataFilter]]$MetadataFilters
    
    # Liste des filtres par texte
    [System.Collections.Generic.List[TextFilter]]$TextFilters
    
    # Opérateur logique (AND, OR)
    [string]$LogicalOperator
    
    # Constructeur par défaut
    CombinedFilter() {
        $this.TypeFilters = [System.Collections.Generic.List[TypeFilter]]::new()
        $this.DateFilters = [System.Collections.Generic.List[DateFilter]]::new()
        $this.MetadataFilters = [System.Collections.Generic.List[MetadataFilter]]::new()
        $this.TextFilters = [System.Collections.Generic.List[TextFilter]]::new()
        $this.LogicalOperator = "AND"
    }
    
    # Constructeur avec opérateur logique
    CombinedFilter([string]$logicalOperator) {
        $this.TypeFilters = [System.Collections.Generic.List[TypeFilter]]::new()
        $this.DateFilters = [System.Collections.Generic.List[DateFilter]]::new()
        $this.MetadataFilters = [System.Collections.Generic.List[MetadataFilter]]::new()
        $this.TextFilters = [System.Collections.Generic.List[TextFilter]]::new()
        $this.LogicalOperator = $logicalOperator
    }
    
    # Méthode pour ajouter un filtre par type
    [void] AddTypeFilter([TypeFilter]$filter) {
        $this.TypeFilters.Add($filter)
    }
    
    # Méthode pour ajouter un filtre par date
    [void] AddDateFilter([DateFilter]$filter) {
        $this.DateFilters.Add($filter)
    }
    
    # Méthode pour ajouter un filtre par métadonnées
    [void] AddMetadataFilter([MetadataFilter]$filter) {
        $this.MetadataFilters.Add($filter)
    }
    
    # Méthode pour ajouter un filtre par texte
    [void] AddTextFilter([TextFilter]$filter) {
        $this.TextFilters.Add($filter)
    }
    
    # Méthode pour vérifier si un document correspond au filtre
    [bool] Matches([IndexDocument]$document) {
        # Si aucun filtre n'est spécifié, le document correspond
        if ($this.TypeFilters.Count -eq 0 -and $this.DateFilters.Count -eq 0 -and $this.MetadataFilters.Count -eq 0 -and $this.TextFilters.Count -eq 0) {
            return $true
        }
        
        # Vérifier les filtres par type
        foreach ($filter in $this.TypeFilters) {
            $matches = $filter.Matches($document)
            
            # Appliquer l'opérateur logique
            if ($this.LogicalOperator -eq "AND" -and -not $matches) {
                return $false
            } elseif ($this.LogicalOperator -eq "OR" -and $matches) {
                return $true
            }
        }
        
        # Vérifier les filtres par date
        foreach ($filter in $this.DateFilters) {
            $matches = $filter.Matches($document)
            
            # Appliquer l'opérateur logique
            if ($this.LogicalOperator -eq "AND" -and -not $matches) {
                return $false
            } elseif ($this.LogicalOperator -eq "OR" -and $matches) {
                return $true
            }
        }
        
        # Vérifier les filtres par métadonnées
        foreach ($filter in $this.MetadataFilters) {
            $matches = $filter.Matches($document)
            
            # Appliquer l'opérateur logique
            if ($this.LogicalOperator -eq "AND" -and -not $matches) {
                return $false
            } elseif ($this.LogicalOperator -eq "OR" -and $matches) {
                return $true
            }
        }
        
        # Vérifier les filtres par texte
        foreach ($filter in $this.TextFilters) {
            $matches = $filter.Matches($document)
            
            # Appliquer l'opérateur logique
            if ($this.LogicalOperator -eq "AND" -and -not $matches) {
                return $false
            } elseif ($this.LogicalOperator -eq "OR" -and $matches) {
                return $true
            }
        }
        
        # Si l'opérateur est AND, tous les filtres doivent correspondre
        # Si l'opérateur est OR, au moins un filtre doit correspondre
        return $this.LogicalOperator -eq "AND"
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $parts = @()
        
        if ($this.TypeFilters.Count -gt 0) {
            $parts += "TypeFilters: $($this.TypeFilters.Count)"
        }
        
        if ($this.DateFilters.Count -gt 0) {
            $parts += "DateFilters: $($this.DateFilters.Count)"
        }
        
        if ($this.MetadataFilters.Count -gt 0) {
            $parts += "MetadataFilters: $($this.MetadataFilters.Count)"
        }
        
        if ($this.TextFilters.Count -gt 0) {
            $parts += "TextFilters: $($this.TextFilters.Count)"
        }
        
        return "CombinedFilter[$($parts -join ", ")] ($($this.LogicalOperator))"
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            type_filters = $this.TypeFilters | ForEach-Object { $_.ToHashtable() }
            date_filters = $this.DateFilters | ForEach-Object { $_.ToHashtable() }
            metadata_filters = $this.MetadataFilters | ForEach-Object { $_.ToHashtable() }
            text_filters = $this.TextFilters | ForEach-Object { $_.ToHashtable() }
            logical_operator = $this.LogicalOperator
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [CombinedFilter] FromHashtable([hashtable]$data) {
        $logicalOperator = if ($data.ContainsKey("logical_operator")) { $data.logical_operator } else { "AND" }
        $filter = [CombinedFilter]::new($logicalOperator)
        
        if ($data.ContainsKey("type_filters")) {
            foreach ($filterData in $data.type_filters) {
                $typeFilter = [TypeFilter]::FromHashtable($filterData)
                $filter.AddTypeFilter($typeFilter)
            }
        }
        
        if ($data.ContainsKey("date_filters")) {
            foreach ($filterData in $data.date_filters) {
                $dateFilter = [DateFilter]::FromHashtable($filterData)
                $filter.AddDateFilter($dateFilter)
            }
        }
        
        if ($data.ContainsKey("metadata_filters")) {
            foreach ($filterData in $data.metadata_filters) {
                $metadataFilter = [MetadataFilter]::FromHashtable($filterData)
                $filter.AddMetadataFilter($metadataFilter)
            }
        }
        
        if ($data.ContainsKey("text_filters")) {
            foreach ($filterData in $data.text_filters) {
                $textFilter = [TextFilter]::FromHashtable($filterData)
                $filter.AddTextFilter($textFilter)
            }
        }
        
        return $filter
    }
}

# Classe pour représenter un gestionnaire de filtres combinés
class FilterCombiner {
    # Gestionnaire de filtres par type
    [TypeFilterManager]$TypeFilterManager
    
    # Gestionnaire de filtres par date
    [DateFilterManager]$DateFilterManager
    
    # Gestionnaire de filtres par métadonnées
    [MetadataFilterManager]$MetadataFilterManager
    
    # Gestionnaire de filtres par texte
    [TextFilterManager]$TextFilterManager
    
    # Métriques de performance
    [PerformanceMetricsManager]$Metrics
    
    # Constructeur par défaut
    FilterCombiner() {
        $this.TypeFilterManager = [TypeFilterManager]::new()
        $this.DateFilterManager = [DateFilterManager]::new()
        $this.MetadataFilterManager = [MetadataFilterManager]::new()
        $this.TextFilterManager = [TextFilterManager]::new()
        $this.Metrics = [PerformanceMetricsManager]::new()
    }
    
    # Constructeur avec gestionnaires
    FilterCombiner([TypeFilterManager]$typeFilterManager, [DateFilterManager]$dateFilterManager, [MetadataFilterManager]$metadataFilterManager, [TextFilterManager]$textFilterManager) {
        $this.TypeFilterManager = $typeFilterManager
        $this.DateFilterManager = $dateFilterManager
        $this.MetadataFilterManager = $metadataFilterManager
        $this.TextFilterManager = $textFilterManager
        $this.Metrics = [PerformanceMetricsManager]::new()
    }
    
    # Méthode pour créer un filtre combiné
    [CombinedFilter] CreateFilter([string]$logicalOperator = "AND") {
        return [CombinedFilter]::new($logicalOperator)
    }
    
    # Méthode pour appliquer un filtre à une liste de documents
    [IndexDocument[]] ApplyFilter([CombinedFilter]$filter, [IndexDocument[]]$documents) {
        $timer = $this.Metrics.GetTimer("filter_combiner.apply_filter")
        $timer.Start()
        
        $result = $documents | Where-Object { $filter.Matches($_) }
        
        $timer.Stop()
        
        # Incrémenter les compteurs
        $this.Metrics.IncrementCounter("filter_combiner.documents_filtered", $documents.Count)
        $this.Metrics.IncrementCounter("filter_combiner.documents_matched", $result.Count)
        
        return $result
    }
    
    # Méthode pour obtenir les statistiques du combinateur
    [hashtable] GetStats() {
        return @{
            type_filter_manager = $this.TypeFilterManager.GetStats()
            date_filter_manager = $this.DateFilterManager.GetStats()
            metadata_filter_manager = $this.MetadataFilterManager.GetStats()
            text_filter_manager = $this.TextFilterManager.GetStats()
            metrics = $this.Metrics.GetAllMetrics()
        }
    }
}

# Fonction pour créer un filtre combiné
function New-CombinedFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("AND", "OR")]
        [string]$LogicalOperator = "AND"
    )
    
    return [CombinedFilter]::new($LogicalOperator)
}

# Fonction pour créer un combinateur de filtres
function New-FilterCombiner {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [TypeFilterManager]$TypeFilterManager = (New-TypeFilterManager),
        
        [Parameter(Mandatory = $false)]
        [DateFilterManager]$DateFilterManager = (New-DateFilterManager),
        
        [Parameter(Mandatory = $false)]
        [MetadataFilterManager]$MetadataFilterManager = (New-MetadataFilterManager),
        
        [Parameter(Mandatory = $false)]
        [TextFilterManager]$TextFilterManager = (New-TextFilterManager)
    )
    
    return [FilterCombiner]::new($TypeFilterManager, $DateFilterManager, $MetadataFilterManager, $TextFilterManager)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-CombinedFilter, New-FilterCombiner
