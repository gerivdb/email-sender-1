# SortingPagination.ps1
# Script implémentant les mécanismes de tri et pagination pour les résultats de recherche
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexStructuresPath = Join-Path -Path $scriptPath -ChildPath "IndexStructures.ps1"

if (Test-Path -Path $indexStructuresPath) {
    . $indexStructuresPath
} else {
    Write-Error "Le fichier IndexStructures.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un critère de tri
class SortCriterion {
    # Champ sur lequel trier
    [string]$Field
    
    # Direction du tri (asc ou desc)
    [string]$Direction
    
    # Constructeur par défaut
    SortCriterion() {
        $this.Field = ""
        $this.Direction = "asc"
    }
    
    # Constructeur avec champ
    SortCriterion([string]$field) {
        $this.Field = $field
        $this.Direction = "asc"
    }
    
    # Constructeur avec champ et direction
    SortCriterion([string]$field, [string]$direction) {
        $this.Field = $field
        $this.Direction = $direction.ToLower()
        
        # Valider la direction
        if ($this.Direction -notin @("asc", "desc")) {
            $this.Direction = "asc"
        }
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "$($this.Field):$($this.Direction)"
    }
}

# Classe pour représenter une requête de pagination
class PaginationRequest {
    # Numéro de page (1-based)
    [int]$Page
    
    # Taille de la page
    [int]$PageSize
    
    # Constructeur par défaut
    PaginationRequest() {
        $this.Page = 1
        $this.PageSize = 10
    }
    
    # Constructeur avec page et taille
    PaginationRequest([int]$page, [int]$pageSize) {
        $this.Page = [Math]::Max(1, $page)
        $this.PageSize = [Math]::Max(1, [Math]::Min(1000, $pageSize))
    }
    
    # Méthode pour obtenir l'offset
    [int] GetOffset() {
        return ($this.Page - 1) * $this.PageSize
    }
    
    # Méthode pour obtenir la limite
    [int] GetLimit() {
        return $this.PageSize
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "Page $($this.Page), Size $($this.PageSize)"
    }
}

# Classe pour représenter un résultat paginé
class PaginatedResult {
    # Éléments de la page courante
    [object[]]$Items
    
    # Nombre total d'éléments
    [int]$TotalItems
    
    # Nombre total de pages
    [int]$TotalPages
    
    # Numéro de la page courante
    [int]$CurrentPage
    
    # Taille de la page
    [int]$PageSize
    
    # Constructeur par défaut
    PaginatedResult() {
        $this.Items = @()
        $this.TotalItems = 0
        $this.TotalPages = 0
        $this.CurrentPage = 1
        $this.PageSize = 10
    }
    
    # Constructeur avec éléments et pagination
    PaginatedResult([object[]]$items, [int]$totalItems, [PaginationRequest]$pagination) {
        $this.Items = $items
        $this.TotalItems = $totalItems
        $this.CurrentPage = $pagination.Page
        $this.PageSize = $pagination.PageSize
        $this.TotalPages = [Math]::Ceiling($totalItems / $pagination.PageSize)
    }
    
    # Méthode pour vérifier s'il y a une page précédente
    [bool] HasPreviousPage() {
        return $this.CurrentPage -gt 1
    }
    
    # Méthode pour vérifier s'il y a une page suivante
    [bool] HasNextPage() {
        return $this.CurrentPage -lt $this.TotalPages
    }
    
    # Méthode pour obtenir le numéro de la page précédente
    [int] GetPreviousPage() {
        return [Math]::Max(1, $this.CurrentPage - 1)
    }
    
    # Méthode pour obtenir le numéro de la page suivante
    [int] GetNextPage() {
        return [Math]::Min($this.TotalPages, $this.CurrentPage + 1)
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "Page $($this.CurrentPage) of $($this.TotalPages) (Total items: $($this.TotalItems))"
    }
}

# Fonction pour trier des documents
function Sort-Documents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$DocumentIds,
        
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.Dictionary[string, IndexDocument]]$Documents,
        
        [Parameter(Mandatory = $true)]
        [SortCriterion[]]$SortCriteria
    )
    
    # Si aucun critère de tri, retourner les documents tels quels
    if ($SortCriteria.Count -eq 0) {
        return $DocumentIds
    }
    
    # Créer une liste d'objets à trier
    $sortableItems = [System.Collections.Generic.List[PSObject]]::new()
    
    foreach ($docId in $DocumentIds) {
        if (-not $Documents.ContainsKey($docId)) {
            continue
        }
        
        $doc = $Documents[$docId]
        
        $item = [PSCustomObject]@{
            Id = $docId
            Document = $doc
        }
        
        $sortableItems.Add($item)
    }
    
    # Trier les documents selon les critères
    $sortedItems = $sortableItems
    
    foreach ($criterion in $SortCriteria) {
        $field = $criterion.Field
        $direction = $criterion.Direction
        
        # Déterminer la direction du tri
        $descending = $direction -eq "desc"
        
        # Trier les documents
        $sortedItems = if ($descending) {
            $sortedItems | Sort-Object -Property { 
                $doc = $_.Document
                if ($doc.Content.ContainsKey($field)) {
                    $doc.Content[$field]
                } else {
                    $null
                }
            } -Descending
        } else {
            $sortedItems | Sort-Object -Property { 
                $doc = $_.Document
                if ($doc.Content.ContainsKey($field)) {
                    $doc.Content[$field]
                } else {
                    $null
                }
            }
        }
    }
    
    # Extraire les IDs des documents triés
    $sortedIds = $sortedItems | ForEach-Object { $_.Id }
    
    return $sortedIds
}

# Fonction pour paginer des documents
function Get-PaginatedDocuments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$DocumentIds,
        
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.Dictionary[string, IndexDocument]]$Documents,
        
        [Parameter(Mandatory = $false)]
        [PaginationRequest]$Pagination = [PaginationRequest]::new()
    )
    
    # Calculer l'offset et la limite
    $offset = $Pagination.GetOffset()
    $limit = $Pagination.GetLimit()
    
    # Extraire les documents de la page
    $pageDocumentIds = $DocumentIds | Select-Object -Skip $offset -First $limit
    
    # Créer les éléments de la page
    $pageItems = [System.Collections.Generic.List[object]]::new()
    
    foreach ($docId in $pageDocumentIds) {
        if (-not $Documents.ContainsKey($docId)) {
            continue
        }
        
        $doc = $Documents[$docId]
        $pageItems.Add($doc)
    }
    
    # Créer le résultat paginé
    $result = [PaginatedResult]::new($pageItems.ToArray(), $DocumentIds.Count, $Pagination)
    
    return $result
}

# Fonction pour créer un critère de tri
function New-SortCriterion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("asc", "desc")]
        [string]$Direction = "asc"
    )
    
    return [SortCriterion]::new($Field, $Direction)
}

# Fonction pour créer une requête de pagination
function New-PaginationRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Page = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$PageSize = 10
    )
    
    return [PaginationRequest]::new($Page, $PageSize)
}

# Fonction pour trier et paginer des documents
function Get-SortedPaginatedDocuments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$DocumentIds,
        
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.Dictionary[string, IndexDocument]]$Documents,
        
        [Parameter(Mandatory = $false)]
        [SortCriterion[]]$SortCriteria = @(),
        
        [Parameter(Mandatory = $false)]
        [PaginationRequest]$Pagination = [PaginationRequest]::new()
    )
    
    # Trier les documents
    $sortedIds = Sort-Documents -DocumentIds $DocumentIds -Documents $Documents -SortCriteria $SortCriteria
    
    # Paginer les documents
    $result = Get-PaginatedDocuments -DocumentIds $sortedIds -Documents $Documents -Pagination $Pagination
    
    return $result
}

# Exporter les fonctions et classes
Export-ModuleMember -Function Sort-Documents, Get-PaginatedDocuments, New-SortCriterion, New-PaginationRequest, Get-SortedPaginatedDocuments
