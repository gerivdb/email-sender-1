# Script pour améliorer la catégorisation des erreurs

# Hiérarchie des catégories d'erreurs
$script:ErrorCategories = @{
    # Catégories principales
    "Syntax" = @{
        Description = "Erreurs de syntaxe dans le code"
        Parent = $null
        Children = @("SyntaxError", "ParsingError", "TokenError")
        Severity = "Error"
    }
    "Runtime" = @{
        Description = "Erreurs qui se produisent pendant l'exécution"
        Parent = $null
        Children = @("NullReference", "OutOfBounds", "DivisionByZero", "Overflow", "Timeout")
        Severity = "Error"
    }
    "Logic" = @{
        Description = "Erreurs de logique dans le code"
        Parent = $null
        Children = @("ConditionError", "LoopError", "StateError", "ValidationError")
        Severity = "Error"
    }
    "Resource" = @{
        Description = "Erreurs liées aux ressources"
        Parent = $null
        Children = @("FileSystem", "Network", "Memory", "Database", "API")
        Severity = "Error"
    }
    "Configuration" = @{
        Description = "Erreurs de configuration"
        Parent = $null
        Children = @("SettingError", "EnvironmentError", "PermissionError", "CredentialError")
        Severity = "Error"
    }
    "Data" = @{
        Description = "Erreurs liées aux données"
        Parent = $null
        Children = @("DataFormat", "DataValidation", "DataIntegrity", "DataAccess")
        Severity = "Error"
    }
    "Security" = @{
        Description = "Erreurs de sécurité"
        Parent = $null
        Children = @("Authentication", "Authorization", "Encryption", "Injection")
        Severity = "Error"
    }
    "Performance" = @{
        Description = "Problèmes de performance"
        Parent = $null
        Children = @("MemoryLeak", "CPUUsage", "DiskIO", "NetworkLatency")
        Severity = "Warning"
    }
    "Compatibility" = @{
        Description = "Problèmes de compatibilité"
        Parent = $null
        Children = @("BrowserCompatibility", "OSCompatibility", "APICompatibility", "VersionCompatibility")
        Severity = "Warning"
    }
    "Deprecation" = @{
        Description = "Utilisation de fonctionnalités obsolètes"
        Parent = $null
        Children = @("DeprecatedAPI", "DeprecatedMethod", "DeprecatedLibrary")
        Severity = "Warning"
    }
    
    # Sous-catégories
    "SyntaxError" = @{
        Description = "Erreurs de syntaxe générales"
        Parent = "Syntax"
        Children = @()
        Severity = "Error"
    }
    "ParsingError" = @{
        Description = "Erreurs lors de l'analyse du code"
        Parent = "Syntax"
        Children = @()
        Severity = "Error"
    }
    "TokenError" = @{
        Description = "Erreurs liées aux tokens"
        Parent = "Syntax"
        Children = @()
        Severity = "Error"
    }
    "NullReference" = @{
        Description = "Références à des objets null"
        Parent = "Runtime"
        Children = @()
        Severity = "Error"
    }
    "OutOfBounds" = @{
        Description = "Accès hors limites (tableaux, listes, etc.)"
        Parent = "Runtime"
        Children = @()
        Severity = "Error"
    }
    "DivisionByZero" = @{
        Description = "Division par zéro"
        Parent = "Runtime"
        Children = @()
        Severity = "Error"
    }
    "Overflow" = @{
        Description = "Dépassement de capacité"
        Parent = "Runtime"
        Children = @()
        Severity = "Error"
    }
    "Timeout" = @{
        Description = "Dépassement de délai"
        Parent = "Runtime"
        Children = @()
        Severity = "Error"
    }
    "ConditionError" = @{
        Description = "Erreurs dans les conditions"
        Parent = "Logic"
        Children = @()
        Severity = "Error"
    }
    "LoopError" = @{
        Description = "Erreurs dans les boucles"
        Parent = "Logic"
        Children = @()
        Severity = "Error"
    }
    "StateError" = @{
        Description = "Erreurs d'état"
        Parent = "Logic"
        Children = @()
        Severity = "Error"
    }
    "ValidationError" = @{
        Description = "Erreurs de validation"
        Parent = "Logic"
        Children = @()
        Severity = "Error"
    }
    "FileSystem" = @{
        Description = "Erreurs liées au système de fichiers"
        Parent = "Resource"
        Children = @()
        Severity = "Error"
    }
    "Network" = @{
        Description = "Erreurs réseau"
        Parent = "Resource"
        Children = @()
        Severity = "Error"
    }
    "Memory" = @{
        Description = "Erreurs de mémoire"
        Parent = "Resource"
        Children = @()
        Severity = "Error"
    }
    "Database" = @{
        Description = "Erreurs de base de données"
        Parent = "Resource"
        Children = @()
        Severity = "Error"
    }
    "API" = @{
        Description = "Erreurs d'API"
        Parent = "Resource"
        Children = @()
        Severity = "Error"
    }
    "SettingError" = @{
        Description = "Erreurs de paramètres de configuration"
        Parent = "Configuration"
        Children = @()
        Severity = "Error"
    }
    "EnvironmentError" = @{
        Description = "Erreurs d'environnement"
        Parent = "Configuration"
        Children = @()
        Severity = "Error"
    }
    "PermissionError" = @{
        Description = "Erreurs de permissions"
        Parent = "Configuration"
        Children = @()
        Severity = "Error"
    }
    "CredentialError" = @{
        Description = "Erreurs de credentials"
        Parent = "Configuration"
        Children = @()
        Severity = "Error"
    }
    "DataFormat" = @{
        Description = "Erreurs de format de données"
        Parent = "Data"
        Children = @()
        Severity = "Error"
    }
    "DataValidation" = @{
        Description = "Erreurs de validation de données"
        Parent = "Data"
        Children = @()
        Severity = "Error"
    }
    "DataIntegrity" = @{
        Description = "Erreurs d'intégrité des données"
        Parent = "Data"
        Children = @()
        Severity = "Error"
    }
    "DataAccess" = @{
        Description = "Erreurs d'accès aux données"
        Parent = "Data"
        Children = @()
        Severity = "Error"
    }
    "Authentication" = @{
        Description = "Erreurs d'authentification"
        Parent = "Security"
        Children = @()
        Severity = "Error"
    }
    "Authorization" = @{
        Description = "Erreurs d'autorisation"
        Parent = "Security"
        Children = @()
        Severity = "Error"
    }
    "Encryption" = @{
        Description = "Erreurs de chiffrement"
        Parent = "Security"
        Children = @()
        Severity = "Error"
    }
    "Injection" = @{
        Description = "Vulnérabilités d'injection"
        Parent = "Security"
        Children = @()
        Severity = "Error"
    }
    "MemoryLeak" = @{
        Description = "Fuites de mémoire"
        Parent = "Performance"
        Children = @()
        Severity = "Warning"
    }
    "CPUUsage" = @{
        Description = "Utilisation excessive du CPU"
        Parent = "Performance"
        Children = @()
        Severity = "Warning"
    }
    "DiskIO" = @{
        Description = "Problèmes d'E/S disque"
        Parent = "Performance"
        Children = @()
        Severity = "Warning"
    }
    "NetworkLatency" = @{
        Description = "Latence réseau"
        Parent = "Performance"
        Children = @()
        Severity = "Warning"
    }
    "BrowserCompatibility" = @{
        Description = "Problèmes de compatibilité avec les navigateurs"
        Parent = "Compatibility"
        Children = @()
        Severity = "Warning"
    }
    "OSCompatibility" = @{
        Description = "Problèmes de compatibilité avec les systèmes d'exploitation"
        Parent = "Compatibility"
        Children = @()
        Severity = "Warning"
    }
    "APICompatibility" = @{
        Description = "Problèmes de compatibilité avec les API"
        Parent = "Compatibility"
        Children = @()
        Severity = "Warning"
    }
    "VersionCompatibility" = @{
        Description = "Problèmes de compatibilité de version"
        Parent = "Compatibility"
        Children = @()
        Severity = "Warning"
    }
    "DeprecatedAPI" = @{
        Description = "Utilisation d'API obsolètes"
        Parent = "Deprecation"
        Children = @()
        Severity = "Warning"
    }
    "DeprecatedMethod" = @{
        Description = "Utilisation de méthodes obsolètes"
        Parent = "Deprecation"
        Children = @()
        Severity = "Warning"
    }
    "DeprecatedLibrary" = @{
        Description = "Utilisation de bibliothèques obsolètes"
        Parent = "Deprecation"
        Children = @()
        Severity = "Warning"
    }
}

# Système de score de sévérité
$script:SeverityScores = @{
    "Critical" = 100
    "Error" = 75
    "Warning" = 50
    "Info" = 25
    "Debug" = 10
}

# Fonction pour obtenir la hiérarchie complète d'une catégorie
function Get-ErrorCategoryHierarchy {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Category
    )
    
    if (-not $script:ErrorCategories.ContainsKey($Category)) {
        Write-Error "Catégorie d'erreur inconnue: $Category"
        return $null
    }
    
    $hierarchy = @($Category)
    $currentCategory = $Category
    
    # Remonter la hiérarchie jusqu'à la racine
    while ($script:ErrorCategories[$currentCategory].Parent -ne $null) {
        $currentCategory = $script:ErrorCategories[$currentCategory].Parent
        $hierarchy = @($currentCategory) + $hierarchy
    }
    
    return $hierarchy
}

# Fonction pour obtenir toutes les sous-catégories d'une catégorie
function Get-ErrorSubcategories {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive
    )
    
    if (-not $script:ErrorCategories.ContainsKey($Category)) {
        Write-Error "Catégorie d'erreur inconnue: $Category"
        return $null
    }
    
    $subcategories = $script:ErrorCategories[$Category].Children
    
    if ($Recursive) {
        $allSubcategories = $subcategories.Clone()
        
        foreach ($subcategory in $subcategories) {
            $childSubcategories = Get-ErrorSubcategories -Category $subcategory -Recursive
            if ($childSubcategories) {
                $allSubcategories += $childSubcategories
            }
        }
        
        return $allSubcategories
    }
    else {
        return $subcategories
    }
}

# Fonction pour ajouter une nouvelle catégorie d'erreur
function Add-ErrorCategory {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Category,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [string]$Parent = $null,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Children = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "Error", "Warning", "Info", "Debug")]
        [string]$Severity = "Error"
    )
    
    # Vérifier si la catégorie existe déjà
    if ($script:ErrorCategories.ContainsKey($Category)) {
        Write-Error "La catégorie d'erreur '$Category' existe déjà."
        return $false
    }
    
    # Vérifier si le parent existe
    if ($Parent -ne $null -and -not $script:ErrorCategories.ContainsKey($Parent)) {
        Write-Error "La catégorie parent '$Parent' n'existe pas."
        return $false
    }
    
    # Créer la nouvelle catégorie
    $script:ErrorCategories[$Category] = @{
        Description = $Description
        Parent = $Parent
        Children = $Children
        Severity = $Severity
    }
    
    # Mettre à jour la liste des enfants du parent
    if ($Parent -ne $null) {
        $script:ErrorCategories[$Parent].Children += $Category
    }
    
    return $true
}

# Fonction pour calculer le score de sévérité d'une erreur
function Get-ErrorSeverityScore {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Critical", "Error", "Warning", "Info", "Debug")]
        [string]$Severity,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Score de base basé sur la sévérité
    $score = $script:SeverityScores[$Severity]
    
    # Ajustement basé sur la catégorie
    if (-not [string]::IsNullOrEmpty($Category) -and $script:ErrorCategories.ContainsKey($Category)) {
        $categoryHierarchy = Get-ErrorCategoryHierarchy -Category $Category
        
        # Plus la hiérarchie est profonde, plus le score est précis
        $hierarchyDepth = $categoryHierarchy.Count
        $score += $hierarchyDepth * 5
        
        # Ajustement basé sur la sévérité de la catégorie
        $categorySeverity = $script:ErrorCategories[$Category].Severity
        if ($categorySeverity -ne $Severity) {
            $categoryScore = $script:SeverityScores[$categorySeverity]
            $score = [Math]::Max($score, $categoryScore)
        }
    }
    
    # Ajustements basés sur les métadonnées
    if ($Metadata.ContainsKey("Frequency") -and $Metadata["Frequency"] -gt 1) {
        # Augmenter le score pour les erreurs fréquentes
        $score += [Math]::Min($Metadata["Frequency"] * 2, 20)
    }
    
    if ($Metadata.ContainsKey("Impact") -and $Metadata["Impact"] -is [int]) {
        # Ajuster en fonction de l'impact (1-10)
        $score += $Metadata["Impact"] * 5
    }
    
    if ($Metadata.ContainsKey("IsBlocking") -and $Metadata["IsBlocking"] -eq $true) {
        # Augmenter le score pour les erreurs bloquantes
        $score += 25
    }
    
    return $score
}

# Fonction pour catégoriser une erreur
function Get-ErrorCategorization {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $false)]
        [string]$Language = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Patterns pour la catégorisation automatique
    $patterns = @(
        # Erreurs de syntaxe
        @{
            Pattern = "syntax error|unexpected token|unexpected character|invalid syntax|parsing error"
            Category = "SyntaxError"
            Severity = "Error"
        },
        # Erreurs de référence null
        @{
            Pattern = "null reference|object reference not set|cannot call method on null|undefined is not an object|cannot read property of null|null pointer"
            Category = "NullReference"
            Severity = "Error"
        },
        # Erreurs de dépassement d'index
        @{
            Pattern = "index out of range|index out of bounds|array index out of bounds|list index out of range"
            Category = "OutOfBounds"
            Severity = "Error"
        },
        # Erreurs de division par zéro
        @{
            Pattern = "division by zero|divide by zero"
            Category = "DivisionByZero"
            Severity = "Error"
        },
        # Erreurs de fichier
        @{
            Pattern = "file not found|cannot find file|no such file|path not found|directory not found|cannot access file"
            Category = "FileSystem"
            Severity = "Error"
        },
        # Erreurs réseau
        @{
            Pattern = "network error|connection refused|connection timeout|host not found|socket error|network is unreachable"
            Category = "Network"
            Severity = "Error"
        },
        # Erreurs de base de données
        @{
            Pattern = "database error|sql error|query error|connection string|database connection|constraint violation"
            Category = "Database"
            Severity = "Error"
        },
        # Erreurs d'API
        @{
            Pattern = "api error|api request failed|api response|status code|endpoint not found|api key|api token"
            Category = "API"
            Severity = "Error"
        },
        # Erreurs de permission
        @{
            Pattern = "access denied|permission denied|unauthorized|forbidden|not allowed|insufficient privileges"
            Category = "PermissionError"
            Severity = "Error"
        },
        # Erreurs d'authentification
        @{
            Pattern = "authentication failed|invalid credentials|login failed|password incorrect|invalid token|expired token"
            Category = "Authentication"
            Severity = "Error"
        },
        # Erreurs de format de données
        @{
            Pattern = "invalid format|malformed|invalid json|invalid xml|invalid csv|invalid data format"
            Category = "DataFormat"
            Severity = "Error"
        },
        # Erreurs de validation de données
        @{
            Pattern = "validation error|invalid input|invalid value|invalid parameter|constraint violation|required field"
            Category = "DataValidation"
            Severity = "Error"
        },
        # Erreurs de timeout
        @{
            Pattern = "timeout|timed out|deadline exceeded|operation timed out|request timeout"
            Category = "Timeout"
            Severity = "Error"
        },
        # Erreurs de mémoire
        @{
            Pattern = "out of memory|memory allocation|memory leak|insufficient memory|memory exhausted"
            Category = "Memory"
            Severity = "Error"
        },
        # Erreurs de configuration
        @{
            Pattern = "configuration error|invalid configuration|missing configuration|config file|setting not found"
            Category = "SettingError"
            Severity = "Error"
        },
        # Erreurs d'environnement
        @{
            Pattern = "environment variable|environment not set|missing environment|invalid environment"
            Category = "EnvironmentError"
            Severity = "Error"
        },
        # Erreurs de compatibilité
        @{
            Pattern = "compatibility issue|not compatible with|requires version|unsupported version|incompatible"
            Category = "VersionCompatibility"
            Severity = "Warning"
        },
        # Fonctionnalités obsolètes
        @{
            Pattern = "deprecated|obsolete|will be removed|use instead|no longer supported"
            Category = "DeprecatedAPI"
            Severity = "Warning"
        }
    )
    
    # Rechercher les correspondances
    $matchedCategories = @()
    
    foreach ($pattern in $patterns) {
        if ($ErrorMessage -match $pattern.Pattern) {
            $matchedCategories += [PSCustomObject]@{
                Category = $pattern.Category
                Severity = $pattern.Severity
                Confidence = 0.8 # Valeur par défaut
            }
        }
    }
    
    # Si aucune correspondance n'est trouvée, utiliser une catégorie générique
    if ($matchedCategories.Count -eq 0) {
        $matchedCategories += [PSCustomObject]@{
            Category = "Runtime"
            Severity = "Error"
            Confidence = 0.5
        }
    }
    
    # Trier par confiance
    $matchedCategories = $matchedCategories | Sort-Object -Property Confidence -Descending
    
    # Obtenir la catégorie la plus probable
    $bestMatch = $matchedCategories[0]
    
    # Calculer le score de sévérité
    $severityScore = Get-ErrorSeverityScore -Severity $bestMatch.Severity -Category $bestMatch.Category -Metadata $Metadata
    
    # Créer le résultat
    $result = [PSCustomObject]@{
        ErrorMessage = $ErrorMessage
        Category = $bestMatch.Category
        Severity = $bestMatch.Severity
        SeverityScore = $severityScore
        Confidence = $bestMatch.Confidence
        Hierarchy = Get-ErrorCategoryHierarchy -Category $bestMatch.Category
        AllMatches = $matchedCategories
        Metadata = $Metadata
    }
    
    return $result
}

# Fonction pour ajouter des métadonnées à une erreur
function Add-ErrorMetadata {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Error,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Metadata
    )
    
    # Créer une copie de l'erreur
    $updatedError = $Error.PSObject.Copy()
    
    # Mettre à jour les métadonnées
    $updatedMetadata = $Error.Metadata.Clone()
    
    foreach ($key in $Metadata.Keys) {
        $updatedMetadata[$key] = $Metadata[$key]
    }
    
    $updatedError.Metadata = $updatedMetadata
    
    # Recalculer le score de sévérité
    $updatedError.SeverityScore = Get-ErrorSeverityScore -Severity $updatedError.Severity -Category $updatedError.Category -Metadata $updatedMetadata
    
    return $updatedError
}

# Fonction pour obtenir toutes les catégories d'erreur
function Get-AllErrorCategories {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$TopLevelOnly,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "Error", "Warning", "Info", "Debug")]
        [string]$SeverityFilter
    )
    
    $categories = @()
    
    foreach ($categoryName in $script:ErrorCategories.Keys) {
        $category = $script:ErrorCategories[$categoryName]
        
        # Filtrer par niveau
        if ($TopLevelOnly -and $category.Parent -ne $null) {
            continue
        }
        
        # Filtrer par sévérité
        if ($SeverityFilter -and $category.Severity -ne $SeverityFilter) {
            continue
        }
        
        $categories += [PSCustomObject]@{
            Name = $categoryName
            Description = $category.Description
            Parent = $category.Parent
            Children = $category.Children
            Severity = $category.Severity
        }
    }
    
    return $categories
}

# Exporter les fonctions
Export-ModuleMember -Function Get-ErrorCategoryHierarchy, Get-ErrorSubcategories, Add-ErrorCategory
Export-ModuleMember -Function Get-ErrorSeverityScore, Get-ErrorCategorization, Add-ErrorMetadata
Export-ModuleMember -Function Get-AllErrorCategories
