# SimpleFilterModule.ps1
# Module de filtres de recherche avancee simplifie
# Version: 1.0
# Date: 2025-05-15

# Fonction pour filtrer par type
function Filter-ByType {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [string[]]$IncludeTypes = @()
    )
    
    process {
        if ($IncludeTypes -contains $Document.type) {
            return $Document
        }
    }
}

# Fonction pour filtrer par date
function Filter-ByDate {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [string]$Field = "created_at",
        
        [DateTime]$StartDate,
        
        [DateTime]$EndDate
    )
    
    process {
        $dateStr = $Document.$Field
        if ($dateStr) {
            $date = [DateTime]::Parse($dateStr)
            if ($date -ge $StartDate -and $date -le $EndDate) {
                return $Document
            }
        }
    }
}

# Fonction pour filtrer par metadonnees
function Filter-ByMetadata {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [string]$Field,
        
        [object]$Value
    )
    
    process {
        if ($Document.$Field -eq $Value) {
            return $Document
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Filter-ByType, Filter-ByDate, Filter-ByMetadata
