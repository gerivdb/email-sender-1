# FinalSearchFilters.ps1
# Module de filtres de recherche avancee pour l'indexation
# Version: 1.0
# Date: 2025-05-15

# Fonction pour filtrer par type
function Filter-ByType {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [Parameter(Mandatory = $false)]
        [string[]]$IncludeTypes = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeTypes = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$TypeField = "type"
    )
    
    process {
        # Verifier si le document a un type
        if (-not $Document.PSObject.Properties.Match($TypeField).Count) {
            return
        }
        
        $documentType = $Document.$TypeField
        
        # Verifier si le type est exclu
        if ($ExcludeTypes.Count -gt 0 -and $ExcludeTypes -contains $documentType) {
            return
        }
        
        # Verifier si le type est inclus
        if ($IncludeTypes.Count -gt 0) {
            if ($IncludeTypes -contains $documentType) {
                return $Document
            }
            return
        }
        
        # Si aucun type n'est specifie a inclure, tous les types non exclus sont inclus
        return $Document
    }
}

# Fonction pour filtrer par date
function Filter-ByDate {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [Parameter(Mandatory = $false)]
        [string]$Field = "created_at",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate = [DateTime]::MinValue,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = [DateTime]::MaxValue
    )
    
    process {
        # Verifier si le document a le champ de date
        if (-not $Document.PSObject.Properties.Match($Field).Count) {
            return
        }
        
        # Recuperer la valeur du champ
        $dateValue = $Document.$Field
        
        # Verifier si la valeur est une date
        if ($null -eq $dateValue) {
            return
        }
        
        # Convertir la valeur en date
        $date = $null
        
        if ($dateValue -is [DateTime]) {
            $date = $dateValue
        } elseif ($dateValue -is [string]) {
            try {
                $date = [DateTime]::Parse($dateValue)
            } catch {
                return
            }
        } else {
            return
        }
        
        # Verifier si la date est dans la plage
        if ($date -ge $StartDate -and $date -le $EndDate) {
            return $Document
        }
    }
}

# Fonction pour filtrer par metadonnees
function Filter-ByMetadata {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("EQ", "NE", "GT", "GE", "LT", "LE", "CONTAINS", "STARTS_WITH", "ENDS_WITH", "MATCHES")]
        [string]$Operator = "EQ",
        
        [Parameter(Mandatory = $false)]
        [object]$Value = $null,
        
        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive
    )
    
    process {
        # Verifier si le document a le champ
        if (-not $Document.PSObject.Properties.Match($Field).Count) {
            return
        }
        
        # Recuperer la valeur du champ
        $fieldValue = $Document.$Field
        
        # Si la valeur du champ est null, elle ne correspond que si la valeur a comparer est egalement null
        if ($null -eq $fieldValue) {
            if ($null -eq $Value -and $Operator -in @("EQ", "CONTAINS")) {
                return $Document
            }
            return
        }
        
        # Si la valeur a comparer est null, elle ne correspond que si la valeur du champ est egalement null
        if ($null -eq $Value) {
            if ($Operator -eq "NE") {
                return $Document
            }
            return
        }
        
        # Preparer les valeurs pour la comparaison
        $compareValue = $Value
        $compareFieldValue = $fieldValue
        
        # Convertir en chaine pour les operations de texte
        if (-not $CaseSensitive -and $Operator -in @("CONTAINS", "STARTS_WITH", "ENDS_WITH", "MATCHES") -and $fieldValue -is [string]) {
            $compareValue = if ($Value -is [string]) { $Value.ToLower() } else { $Value }
            $compareFieldValue = $fieldValue.ToLower()
        }
        
        # Comparer les valeurs selon l'operateur
        $matches = switch ($Operator) {
            "EQ" { $compareFieldValue -eq $compareValue }
            "NE" { $compareFieldValue -ne $compareValue }
            "GT" { $compareFieldValue -gt $compareValue }
            "GE" { $compareFieldValue -ge $compareValue }
            "LT" { $compareFieldValue -lt $compareValue }
            "LE" { $compareFieldValue -le $compareValue }
            "CONTAINS" {
                if ($compareFieldValue -is [string] -and $compareValue -is [string]) {
                    $compareFieldValue.Contains($compareValue)
                } elseif ($compareFieldValue -is [array] -or $compareFieldValue -is [System.Collections.IList]) {
                    $compareFieldValue -contains $compareValue
                } else {
                    $false
                }
            }
            "STARTS_WITH" {
                if ($compareFieldValue -is [string] -and $compareValue -is [string]) {
                    $compareFieldValue.StartsWith($compareValue)
                } else {
                    $false
                }
            }
            "ENDS_WITH" {
                if ($compareFieldValue -is [string] -and $compareValue -is [string]) {
                    $compareFieldValue.EndsWith($compareValue)
                } else {
                    $false
                }
            }
            "MATCHES" {
                if ($compareFieldValue -is [string] -and $compareValue -is [string]) {
                    $compareFieldValue -match $compareValue
                } else {
                    $false
                }
            }
            default { $compareFieldValue -eq $compareValue }
        }
        
        if ($matches) {
            return $Document
        }
    }
}

# Fonction pour filtrer par texte
function Filter-ByText {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$Document,
        
        [Parameter(Mandatory = $false)]
        [string]$Field = "content",
        
        [Parameter(Mandatory = $false)]
        [string]$Text = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("EXACT", "CONTAINS", "STARTS_WITH", "ENDS_WITH", "MATCHES")]
        [string]$SearchType = "CONTAINS",
        
        [Parameter(Mandatory = $false)]
        [switch]$CaseSensitive
    )
    
    process {
        # Verifier si le document a le champ
        if (-not $Document.PSObject.Properties.Match($Field).Count) {
            return
        }
        
        # Recuperer la valeur du champ
        $fieldValue = $Document.$Field
        
        # Verifier si la valeur est une chaine
        if ($null -eq $fieldValue -or -not ($fieldValue -is [string])) {
            return
        }
        
        # Preparer les valeurs pour la comparaison
        $compareText = $Text
        $compareValue = $fieldValue
        
        if (-not $CaseSensitive) {
            $compareText = $Text.ToLower()
            $compareValue = $fieldValue.ToLower()
        }
        
        # Comparer selon le type de recherche
        $matches = switch ($SearchType) {
            "EXACT" { $compareValue -eq $compareText }
            "CONTAINS" { $compareValue.Contains($compareText) }
            "STARTS_WITH" { $compareValue.StartsWith($compareText) }
            "ENDS_WITH" { $compareValue.EndsWith($compareText) }
            "MATCHES" { $compareValue -match $compareText }
            default { $compareValue.Contains($compareText) }
        }
        
        if ($matches) {
            return $Document
        }
    }
}
