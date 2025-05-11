# Test-RestorePointConsistency.ps1
# Script pour vérifier la cohérence des points de restauration avant suppression
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$RestorePointPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Standard", "Thorough")]
    [string]$VerificationLevel = "Standard",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDependencyCheck,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipIntegrityCheck,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipReferenceCheck,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour obtenir le chemin du répertoire des points de restauration
function Get-RestorePointsPath {
    [CmdletBinding()]
    param()
    
    $pointsPath = Join-Path -Path $rootPath -ChildPath "points"
    
    if (-not (Test-Path -Path $pointsPath)) {
        New-Item -Path $pointsPath -ItemType Directory -Force | Out-Null
    }
    
    return $pointsPath
}

# Fonction pour vérifier l'intégrité structurelle du point de restauration
function Test-StructuralIntegrity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$RestorePoint
    )
    
    $errors = @()
    
    # Vérifier les sections obligatoires
    $requiredSections = @("metadata", "content", "restore_info")
    
    foreach ($section in $requiredSections) {
        if (-not $RestorePoint.PSObject.Properties.Name.Contains($section)) {
            $errors += "Missing required section: $section"
        }
    }
    
    # Vérifier les champs obligatoires dans les métadonnées
    if ($RestorePoint.PSObject.Properties.Name.Contains("metadata")) {
        $requiredMetadataFields = @("id", "name", "type", "created_at")
        
        foreach ($field in $requiredMetadataFields) {
            if (-not $RestorePoint.metadata.PSObject.Properties.Name.Contains($field)) {
                $errors += "Missing required metadata field: $field"
            }
        }
    }
    
    # Vérifier les champs obligatoires dans le contenu
    if ($RestorePoint.PSObject.Properties.Name.Contains("content")) {
        $requiredContentFields = @("configurations")
        
        foreach ($field in $requiredContentFields) {
            if (-not $RestorePoint.content.PSObject.Properties.Name.Contains($field)) {
                $errors += "Missing required content field: $field"
            }
        }
    }
    
    # Vérifier les champs obligatoires dans les informations de restauration
    if ($RestorePoint.PSObject.Properties.Name.Contains("restore_info")) {
        $requiredRestoreInfoFields = @("last_restored", "restore_count")
        
        foreach ($field in $requiredRestoreInfoFields) {
            if (-not $RestorePoint.restore_info.PSObject.Properties.Name.Contains($field)) {
                $errors += "Missing required restore_info field: $field"
            }
        }
    }
    
    return $errors
}

# Fonction pour vérifier l'intégrité des données du point de restauration
function Test-DataIntegrity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$RestorePoint,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Standard", "Thorough")]
        [string]$VerificationLevel = "Standard"
    )
    
    $errors = @()
    
    # Vérification de base
    if ($VerificationLevel -in @("Basic", "Standard", "Thorough")) {
        # Vérifier les formats de date
        if ($RestorePoint.metadata.PSObject.Properties.Name.Contains("created_at")) {
            try {
                $createdAt = [DateTime]::Parse($RestorePoint.metadata.created_at)
            } catch {
                $errors += "Invalid created_at date format: $($RestorePoint.metadata.created_at)"
            }
        }
        
        if ($RestorePoint.restore_info.PSObject.Properties.Name.Contains("last_restored") -and 
            -not [string]::IsNullOrEmpty($RestorePoint.restore_info.last_restored)) {
            try {
                $lastRestored = [DateTime]::Parse($RestorePoint.restore_info.last_restored)
            } catch {
                $errors += "Invalid last_restored date format: $($RestorePoint.restore_info.last_restored)"
            }
        }
        
        # Vérifier les types de données
        if ($RestorePoint.restore_info.PSObject.Properties.Name.Contains("restore_count")) {
            if (-not ($RestorePoint.restore_info.restore_count -is [int] -or $RestorePoint.restore_info.restore_count -is [long])) {
                $errors += "Invalid restore_count type: $($RestorePoint.restore_info.restore_count.GetType().Name)"
            }
        }
    }
    
    # Vérification standard
    if ($VerificationLevel -in @("Standard", "Thorough")) {
        # Vérifier les configurations
        if ($RestorePoint.content.PSObject.Properties.Name.Contains("configurations") -and 
            $RestorePoint.content.configurations -is [array]) {
            
            foreach ($config in $RestorePoint.content.configurations) {
                if (-not $config.PSObject.Properties.Name.Contains("type")) {
                    $errors += "Configuration missing type field"
                }
                
                if (-not $config.PSObject.Properties.Name.Contains("id")) {
                    $errors += "Configuration missing id field"
                }
                
                if (-not $config.PSObject.Properties.Name.Contains("data")) {
                    $errors += "Configuration missing data field"
                }
            }
        }
        
        # Vérifier l'historique de restauration
        if ($RestorePoint.restore_info.PSObject.Properties.Name.Contains("restore_history") -and 
            $RestorePoint.restore_info.restore_history -is [array]) {
            
            foreach ($entry in $RestorePoint.restore_info.restore_history) {
                if (-not $entry.PSObject.Properties.Name.Contains("timestamp")) {
                    $errors += "Restore history entry missing timestamp field"
                } else {
                    try {
                        $timestamp = [DateTime]::Parse($entry.timestamp)
                    } catch {
                        $errors += "Invalid restore history timestamp format: $($entry.timestamp)"
                    }
                }
            }
        }
    }
    
    # Vérification approfondie
    if ($VerificationLevel -eq "Thorough") {
        # Vérifier la cohérence des données de configuration
        if ($RestorePoint.content.PSObject.Properties.Name.Contains("configurations") -and 
            $RestorePoint.content.configurations -is [array]) {
            
            foreach ($config in $RestorePoint.content.configurations) {
                if ($config.PSObject.Properties.Name.Contains("data")) {
                    # Vérifier si les données sont un objet JSON valide
                    if ($config.data -is [string]) {
                        try {
                            $jsonData = $config.data | ConvertFrom-Json
                        } catch {
                            $errors += "Invalid JSON data in configuration $($config.type):$($config.id)"
                        }
                    }
                    
                    # Vérifier si les données sont complètes (contiennent au moins un champ)
                    if ($config.data -is [object] -and $config.data.PSObject.Properties.Count -eq 0) {
                        $errors += "Empty data object in configuration $($config.type):$($config.id)"
                    }
                }
            }
        }
    }
    
    return $errors
}

# Fonction pour vérifier les dépendances du point de restauration
function Test-Dependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$RestorePoint,
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointsDirectory
    )
    
    $errors = @()
    
    # Vérifier si le point de restauration a des dépendances
    if (-not $RestorePoint.PSObject.Properties.Name.Contains("dependencies") -or 
        -not $RestorePoint.dependencies -is [array] -or 
        $RestorePoint.dependencies.Count -eq 0) {
        return $errors
    }
    
    # Vérifier chaque dépendance
    foreach ($dependency in $RestorePoint.dependencies) {
        if (-not $dependency.PSObject.Properties.Name.Contains("id")) {
            $errors += "Dependency missing id field"
            continue
        }
        
        $dependencyId = $dependency.id
        $dependencyPath = Join-Path -Path $RestorePointsDirectory -ChildPath "$dependencyId.json"
        
        if (-not (Test-Path -Path $dependencyPath)) {
            $errors += "Dependency not found: $dependencyId"
            continue
        }
        
        # Vérifier si la dépendance est valide
        try {
            $dependencyPoint = Get-Content -Path $dependencyPath -Raw | ConvertFrom-Json
            
            if (-not $dependencyPoint.PSObject.Properties.Name.Contains("metadata") -or 
                -not $dependencyPoint.metadata.PSObject.Properties.Name.Contains("id") -or 
                $dependencyPoint.metadata.id -ne $dependencyId) {
                $errors += "Invalid dependency: $dependencyId"
            }
        } catch {
            $errors += "Error loading dependency $dependencyId: $($_.Exception.Message)"
        }
    }
    
    return $errors
}

# Fonction pour vérifier les références au point de restauration
function Test-References {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RestorePointId,
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointsDirectory
    )
    
    $references = @()
    
    # Obtenir tous les fichiers de points de restauration
    $restorePointFiles = Get-ChildItem -Path $RestorePointsDirectory -Filter "*.json"
    
    foreach ($file in $restorePointFiles) {
        try {
            $point = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Vérifier si ce point fait référence au point de restauration spécifié
            if ($point.PSObject.Properties.Name.Contains("dependencies") -and 
                $point.dependencies -is [array]) {
                
                foreach ($dependency in $point.dependencies) {
                    if ($dependency.PSObject.Properties.Name.Contains("id") -and $dependency.id -eq $RestorePointId) {
                        $references += @{
                            id = $point.metadata.id
                            name = $point.metadata.name
                            type = $point.metadata.type
                            path = $file.FullName
                        }
                        break
                    }
                }
            }
        } catch {
            Write-Log "Error checking references in $($file.Name): $($_.Exception.Message)" -Level "Warning"
        }
    }
    
    return $references
}

# Fonction principale pour vérifier la cohérence d'un point de restauration
function Test-RestorePointConsistency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RestorePointPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Standard", "Thorough")]
        [string]$VerificationLevel = "Standard",
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipDependencyCheck,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipIntegrityCheck,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipReferenceCheck
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $RestorePointPath)) {
        Write-Log "Restore point file not found: $RestorePointPath" -Level "Error"
        return @{
            IsConsistent = $false
            Errors = @("File not found")
            Warnings = @()
            References = @()
        }
    }
    
    # Charger le point de restauration
    try {
        $restorePoint = Get-Content -Path $RestorePointPath -Raw | ConvertFrom-Json
    } catch {
        Write-Log "Error loading restore point: $($_.Exception.Message)" -Level "Error"
        return @{
            IsConsistent = $false
            Errors = @("Invalid JSON format: $($_.Exception.Message)")
            Warnings = @()
            References = @()
        }
    }
    
    # Initialiser les tableaux d'erreurs et d'avertissements
    $errors = @()
    $warnings = @()
    $references = @()
    
    # Vérifier l'intégrité structurelle
    if (-not $SkipIntegrityCheck) {
        $structuralErrors = Test-StructuralIntegrity -RestorePoint $restorePoint
        $errors += $structuralErrors
        
        # Vérifier l'intégrité des données si la structure est valide
        if ($structuralErrors.Count -eq 0) {
            $dataErrors = Test-DataIntegrity -RestorePoint $restorePoint -VerificationLevel $VerificationLevel
            $errors += $dataErrors
        }
    }
    
    # Vérifier les dépendances
    if (-not $SkipDependencyCheck -and $errors.Count -eq 0) {
        $restorePointsDirectory = Get-RestorePointsPath
        $dependencyErrors = Test-Dependencies -RestorePoint $restorePoint -RestorePointsDirectory $restorePointsDirectory
        
        if ($dependencyErrors.Count -gt 0) {
            $warnings += $dependencyErrors
        }
    }
    
    # Vérifier les références
    if (-not $SkipReferenceCheck -and $errors.Count -eq 0 -and $restorePoint.PSObject.Properties.Name.Contains("metadata") -and $restorePoint.metadata.PSObject.Properties.Name.Contains("id")) {
        $restorePointsDirectory = Get-RestorePointsPath
        $references = Test-References -RestorePointId $restorePoint.metadata.id -RestorePointsDirectory $restorePointsDirectory
        
        if ($references.Count -gt 0) {
            $warnings += "This restore point is referenced by $($references.Count) other restore points"
        }
    }
    
    # Déterminer si le point de restauration est cohérent
    $isConsistent = $errors.Count -eq 0
    
    # Journaliser les résultats
    if ($isConsistent) {
        Write-Log "Restore point is consistent: $RestorePointPath" -Level "Info"
        
        if ($warnings.Count -gt 0) {
            Write-Log "Warnings: $($warnings.Count)" -Level "Warning"
            foreach ($warning in $warnings) {
                Write-Log "  - $warning" -Level "Warning"
            }
        }
        
        if ($references.Count -gt 0) {
            Write-Log "References: $($references.Count)" -Level "Info"
            foreach ($ref in $references) {
                Write-Log "  - $($ref.id) ($($ref.name))" -Level "Debug"
            }
        }
    } else {
        Write-Log "Restore point is inconsistent: $RestorePointPath" -Level "Error"
        
        foreach ($error in $errors) {
            Write-Log "  - $error" -Level "Error"
        }
    }
    
    # Retourner les résultats
    return @{
        IsConsistent = $isConsistent
        Errors = $errors
        Warnings = $warnings
        References = $references
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Test-RestorePointConsistency -RestorePointPath $RestorePointPath -VerificationLevel $VerificationLevel -SkipDependencyCheck:$SkipDependencyCheck -SkipIntegrityCheck:$SkipIntegrityCheck -SkipReferenceCheck:$SkipReferenceCheck
}
