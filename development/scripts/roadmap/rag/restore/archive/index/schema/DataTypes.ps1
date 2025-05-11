# DataTypes.ps1
# Script définissant les types de données et formats pour l'indexation des métadonnées
# Version: 1.0
# Date: 2025-05-15

# Structure définissant les types de données et leurs formats
$script:DataTypes = @{
    # Type Keyword - chaînes de caractères non tokenisées
    Keyword = @{
        # Nom du type
        Name = "Keyword"
        
        # Description du type
        Description = "Chaîne de caractères non tokenisée, utilisée pour les identifiants, codes, etc."
        
        # Type .NET correspondant
        DotNetType = "System.String"
        
        # Valeur par défaut
        DefaultValue = ""
        
        # Formats acceptés (expressions régulières)
        AcceptedFormats = @(
            "^.*$"  # Tout format accepté
        )
        
        # Fonctions de validation
        Validators = @(
            {
                param($value)
                return $value -is [string] -or $null -eq $value
            }
        )
        
        # Fonctions de normalisation
        Normalizers = @(
            {
                param($value)
                if ($null -eq $value) { return "" }
                return [string]$value
            }
        )
        
        # Options d'indexation
        IndexOptions = @{
            Tokenize = $false
            LowerCase = $true
            Stemming = $false
            StopWords = $false
            MaxLength = 256
        }
        
        # Options de recherche
        SearchOptions = @{
            ExactMatch = $true
            PrefixMatch = $true
            WildcardMatch = $true
            FuzzyMatch = $false
        }
    }
    
    # Type Text - chaînes de caractères tokenisées
    Text = @{
        Name = "Text"
        Description = "Chaîne de caractères tokenisée, utilisée pour le texte libre"
        DotNetType = "System.String"
        DefaultValue = ""
        AcceptedFormats = @(
            "^.*$"  # Tout format accepté
        )
        Validators = @(
            {
                param($value)
                return $value -is [string] -or $null -eq $value
            }
        )
        Normalizers = @(
            {
                param($value)
                if ($null -eq $value) { return "" }
                return [string]$value
            }
        )
        IndexOptions = @{
            Tokenize = $true
            LowerCase = $true
            Stemming = $true
            StopWords = $true
            MaxLength = 32768
        }
        SearchOptions = @{
            ExactMatch = $false
            PrefixMatch = $true
            WildcardMatch = $true
            FuzzyMatch = $true
        }
    }
    
    # Type Numeric - valeurs numériques
    Numeric = @{
        Name = "Numeric"
        Description = "Valeur numérique, utilisée pour les nombres, compteurs, etc."
        DotNetType = "System.Double"
        DefaultValue = 0
        AcceptedFormats = @(
            "^-?\d+(\.\d+)?$"  # Nombres décimaux
        )
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                if ($value -is [string]) {
                    return $value -match "^-?\d+(\.\d+)?$"
                }
                return $value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal]
            }
        )
        Normalizers = @(
            {
                param($value)
                if ($null -eq $value) { return 0 }
                if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) { return 0 }
                return [double]$value
            }
        )
        IndexOptions = @{
            Range = $true
            Precision = "double"
        }
        SearchOptions = @{
            ExactMatch = $true
            RangeMatch = $true
        }
    }
    
    # Type Date - valeurs de date et heure
    Date = @{
        Name = "Date"
        Description = "Valeur de date et heure, utilisée pour les horodatages"
        DotNetType = "System.DateTime"
        DefaultValue = [DateTime]::MinValue
        AcceptedFormats = @(
            # Format ISO 8601
            "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$",
            # Format date simple
            "^\d{4}-\d{2}-\d{2}$",
            # Format date et heure simple
            "^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$"
        )
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                if ($value -is [DateTime]) { return $true }
                if ($value -is [string]) {
                    try {
                        $date = [DateTime]::Parse($value)
                        return $true
                    } catch {
                        return $false
                    }
                }
                return $false
            }
        )
        Normalizers = @(
            {
                param($value)
                if ($null -eq $value) { return [DateTime]::MinValue }
                if ($value -is [DateTime]) { return $value }
                if ($value -is [string] -and [string]::IsNullOrWhiteSpace($value)) { return [DateTime]::MinValue }
                try {
                    return [DateTime]::Parse($value)
                } catch {
                    return [DateTime]::MinValue
                }
            }
        )
        IndexOptions = @{
            Range = $true
            Format = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        }
        SearchOptions = @{
            ExactMatch = $true
            RangeMatch = $true
        }
    }
    
    # Type Boolean - valeurs booléennes
    Boolean = @{
        Name = "Boolean"
        Description = "Valeur booléenne, utilisée pour les indicateurs, options, etc."
        DotNetType = "System.Boolean"
        DefaultValue = $false
        AcceptedFormats = @(
            "^(true|false|yes|no|1|0|on|off)$"  # Formats booléens courants
        )
        Validators = @(
            {
                param($value)
                if ($null -eq $value) { return $true }
                if ($value -is [bool]) { return $true }
                if ($value -is [string]) {
                    return $value -match "^(true|false|yes|no|1|0|on|off)$"
                }
                if ($value -is [int] -or $value -is [long]) {
                    return $value -eq 0 -or $value -eq 1
                }
                return $false
            }
        )
        Normalizers = @(
            {
                param($value)
                if ($null -eq $value) { return $false }
                if ($value -is [bool]) { return $value }
                if ($value -is [string]) {
                    return @("true", "yes", "1", "on") -contains $value.ToLower()
                }
                if ($value -is [int] -or $value -is [long]) {
                    return $value -ne 0
                }
                return $false
            }
        )
        IndexOptions = @{
            Exact = $true
        }
        SearchOptions = @{
            ExactMatch = $true
        }
    }
}

# Fonction pour obtenir tous les types de données
function Get-DataTypes {
    [CmdletBinding()]
    param()
    
    $result = @{}
    
    foreach ($typeName in $script:DataTypes.Keys) {
        $result[$typeName] = $script:DataTypes[$typeName]
    }
    
    return $result
}

# Fonction pour obtenir un type de données spécifique
function Get-DataType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Keyword", "Text", "Numeric", "Date", "Boolean")]
        [string]$TypeName
    )
    
    if (-not $script:DataTypes.ContainsKey($TypeName)) {
        Write-Error "Type de données non trouvé: $TypeName"
        return $null
    }
    
    return $script:DataTypes[$TypeName]
}

# Fonction pour valider une valeur selon un type de données
function Test-DataTypeValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Keyword", "Text", "Numeric", "Date", "Boolean")]
        [string]$TypeName
    )
    
    $dataType = Get-DataType -TypeName $TypeName
    
    if ($null -eq $dataType) {
        return $false
    }
    
    foreach ($validator in $dataType.Validators) {
        $result = & $validator $Value
        
        if (-not $result) {
            return $false
        }
    }
    
    return $true
}

# Fonction pour normaliser une valeur selon un type de données
function ConvertTo-DataTypeValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Keyword", "Text", "Numeric", "Date", "Boolean")]
        [string]$TypeName
    )
    
    $dataType = Get-DataType -TypeName $TypeName
    
    if ($null -eq $dataType) {
        return $Value
    }
    
    $result = $Value
    
    foreach ($normalizer in $dataType.Normalizers) {
        $result = & $normalizer $result
    }
    
    return $result
}

# Fonction pour obtenir la valeur par défaut d'un type de données
function Get-DataTypeDefaultValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Keyword", "Text", "Numeric", "Date", "Boolean")]
        [string]$TypeName
    )
    
    $dataType = Get-DataType -TypeName $TypeName
    
    if ($null -eq $dataType) {
        return $null
    }
    
    return $dataType.DefaultValue
}

# Exporter les fonctions
Export-ModuleMember -Function Get-DataTypes, Get-DataType, Test-DataTypeValue, ConvertTo-DataTypeValue, Get-DataTypeDefaultValue
