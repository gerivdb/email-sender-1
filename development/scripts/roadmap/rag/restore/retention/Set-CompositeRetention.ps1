# Set-CompositeRetention.ps1
# Script pour configurer et appliquer des règles de rétention composites pour les points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RuleName,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Manual", "Automatic", "Scheduled", "Pre-Update", "Pre-Migration", "Git-Commit", "Intelligent")]
    [string]$RestorePointType = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigType = "",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigId = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Critical", "High", "Medium", "Low", "All")]
    [string]$ImportanceLevel = "All",
    
    [Parameter(Mandatory = $false)]
    [int]$MinimumUsageCount = 0,
    
    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 30,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxVersions = 0,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("AND", "OR")]
    [string]$ConditionOperator = "AND",
    
    [Parameter(Mandatory = $false)]
    [int]$Priority = 100,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigName = "default",
    
    [Parameter(Mandatory = $false)]
    [switch]$Apply,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
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

# Fonction pour obtenir le chemin du fichier de configuration des politiques de rétention
function Get-RetentionConfigPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    
    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }
    
    $retentionPath = Join-Path -Path $configPath -ChildPath "retention"
    
    if (-not (Test-Path -Path $retentionPath)) {
        New-Item -Path $retentionPath -ItemType Directory -Force | Out-Null
    }
    
    return Join-Path -Path $retentionPath -ChildPath "$ConfigName.json"
}

# Fonction pour charger la configuration de rétention
function Get-RetentionConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Get-RetentionConfigPath -ConfigName $ConfigName
    
    if (Test-Path -Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading retention configuration: $_" -Level "Error"
            return $null
        }
    } else {
        return $null
    }
}

# Fonction pour sauvegarder la configuration de rétention
function Save-RetentionConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Get-RetentionConfigPath -ConfigName $ConfigName
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        Write-Log "Retention configuration saved to: $configPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving retention configuration: $_" -Level "Error"
        return $false
    }
}

# Fonction pour générer un nom de règle par défaut
function Get-DefaultRuleName {
    [CmdletBinding()]
    param()
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    return "CompositeRule-$timestamp"
}

# Fonction pour configurer une règle de rétention composite
function Set-CompositeRetention {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RuleName,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Manual", "Automatic", "Scheduled", "Pre-Update", "Pre-Migration", "Git-Commit", "Intelligent")]
        [string]$RestorePointType = "All",
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigType = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigId = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "High", "Medium", "Low", "All")]
        [string]$ImportanceLevel = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$MinimumUsageCount = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 30,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxVersions = 0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("AND", "OR")]
        [string]$ConditionOperator = "AND",
        
        [Parameter(Mandatory = $false)]
        [int]$Priority = 100,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",
        
        [Parameter(Mandatory = $false)]
        [switch]$Apply,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Valider les paramètres
    if ($RetentionDays -lt 0) {
        Write-Log "RetentionDays must be at least 0 (0 means keep forever)" -Level "Error"
        return $false
    }
    
    if ($MaxVersions -lt 0) {
        Write-Log "MaxVersions must be at least 0 (0 means no version limit)" -Level "Error"
        return $false
    }
    
    if ($MinimumUsageCount -lt 0) {
        Write-Log "MinimumUsageCount must be at least 0" -Level "Error"
        return $false
    }
    
    # Générer un nom de règle par défaut si non fourni
    if ([string]::IsNullOrEmpty($RuleName)) {
        $RuleName = Get-DefaultRuleName
    }
    
    # Générer une description par défaut si non fournie
    if ([string]::IsNullOrEmpty($Description)) {
        $Description = "Composite retention rule for $RestorePointType restore points"
        
        if (-not [string]::IsNullOrEmpty($ConfigType)) {
            $Description += " of type $ConfigType"
            
            if (-not [string]::IsNullOrEmpty($ConfigId)) {
                $Description += " with ID $ConfigId"
            }
        }
        
        if ($ImportanceLevel -ne "All") {
            $Description += " with $ImportanceLevel importance"
        }
        
        if ($MinimumUsageCount -gt 0) {
            $Description += " used at least $MinimumUsageCount times"
        }
        
        $Description += " - Keep for $RetentionDays days"
        
        if ($MaxVersions -gt 0) {
            $Description += ", max $MaxVersions versions"
        }
    }
    
    # Charger la configuration existante ou créer une nouvelle
    $config = Get-RetentionConfig -ConfigName $ConfigName
    
    if ($null -eq $config) {
        $config = @{
            name = $ConfigName
            created_at = (Get-Date).ToString("o")
            last_modified = (Get-Date).ToString("o")
            policies = @{}
        }
    } else {
        $config.last_modified = (Get-Date).ToString("o")
    }
    
    # Mettre à jour ou ajouter la politique de rétention composite
    if (-not $config.policies.ContainsKey("composite")) {
        $config.policies.composite = @{}
    }
    
    # Vérifier si la règle existe déjà
    if ($config.policies.composite.ContainsKey($RuleName) -and -not $Force) {
        Write-Log "Composite rule already exists: $RuleName. Use -Force to overwrite." -Level "Warning"
        return $false
    }
    
    # Créer la règle composite
    $rule = @{
        name = $RuleName
        description = $Description
        created_at = (Get-Date).ToString("o")
        last_modified = (Get-Date).ToString("o")
        priority = $Priority
        condition_operator = $ConditionOperator
        conditions = @{
            restore_point_type = $RestorePointType
            config_type = $ConfigType
            config_id = $ConfigId
            importance_level = $ImportanceLevel
            minimum_usage_count = $MinimumUsageCount
        }
        actions = @{
            retention_days = $RetentionDays
            max_versions = $MaxVersions
        }
    }
    
    # Ajouter la règle à la configuration
    $config.policies.composite[$RuleName] = $rule
    
    # Sauvegarder la configuration
    $result = Save-RetentionConfig -Config $config -ConfigName $ConfigName
    
    if (-not $result) {
        return $false
    }
    
    Write-Log "Composite retention rule configured: $RuleName" -Level "Info"
    
    # Appliquer la règle si demandé
    if ($Apply) {
        return Set-CompositeRetention -RuleName $RuleName -ConfigName $ConfigName -WhatIf:$WhatIf -Force:$Force
    }
    
    return $true
}

# Fonction pour appliquer une règle de rétention composite
function Set-CompositeRetention {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RuleName,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Charger la configuration de rétention
    $config = Get-RetentionConfig -ConfigName $ConfigName
    
    if ($null -eq $config) {
        Write-Log "No retention configuration found for $ConfigName" -Level "Error"
        return $false
    }
    
    # Vérifier si la configuration contient des règles composites
    if (-not $config.policies.ContainsKey("composite") -or -not $config.policies.composite.ContainsKey($RuleName)) {
        Write-Log "Composite rule not found: $RuleName" -Level "Error"
        return $false
    }
    
    # Obtenir la règle composite
    $rule = $config.policies.composite[$RuleName]
    
    # Obtenir le chemin des points de restauration
    $pointsPath = Get-RestorePointsPath
    
    # Obtenir tous les fichiers de points de restauration
    $restorePointFiles = Get-ChildItem -Path $pointsPath -Filter "*.json"
    
    if ($restorePointFiles.Count -eq 0) {
        Write-Log "No restore points found" -Level "Warning"
        return $true
    }
    
    Write-Log "Found $($restorePointFiles.Count) restore points" -Level "Info"
    
    # Extraire les conditions et actions de la règle
    $restorePointType = $rule.conditions.restore_point_type
    $configType = $rule.conditions.config_type
    $configId = $rule.conditions.config_id
    $importanceLevel = $rule.conditions.importance_level
    $minimumUsageCount = $rule.conditions.minimum_usage_count
    $retentionDays = $rule.actions.retention_days
    $maxVersions = $rule.actions.max_versions
    $conditionOperator = $rule.condition_operator
    
    # Calculer la date limite
    $cutoffDate = (Get-Date).AddDays(-$retentionDays)
    
    # Initialiser les compteurs
    $expiredCount = 0
    $deletedCount = 0
    $errorCount = 0
    
    # Créer un dictionnaire pour regrouper les points de restauration par configuration
    $restorePointsByConfig = @{}
    
    # Traiter chaque fichier de point de restauration
    foreach ($file in $restorePointFiles) {
        try {
            # Charger le point de restauration
            $restorePoint = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Vérifier si le point de restauration correspond aux conditions
            $matchesConditions = $true
            $conditionResults = @{}
            
            # Vérifier le type de point de restauration
            $type = $restorePoint.metadata.type
            $conditionResults["type"] = ($restorePointType -eq "All" -or $type -eq $restorePointType.ToLower())
            
            # Extraire les informations de configuration
            $currentConfigType = ""
            $currentConfigId = ""
            
            if ($restorePoint.content.PSObject.Properties.Name.Contains("configurations") -and 
                $restorePoint.content.configurations.Count -gt 0) {
                $currentConfigType = $restorePoint.content.configurations[0].type
                $currentConfigId = $restorePoint.content.configurations[0].id
            }
            
            # Vérifier le type de configuration
            $conditionResults["config_type"] = ([string]::IsNullOrEmpty($configType) -or $currentConfigType -eq $configType)
            
            # Vérifier l'ID de configuration
            $conditionResults["config_id"] = ([string]::IsNullOrEmpty($configId) -or $currentConfigId -eq $configId)
            
            # Vérifier le niveau d'importance
            $importance = "Low" # Valeur par défaut
            
            if ($restorePoint.metadata.PSObject.Properties.Name.Contains("importance") -and 
                $restorePoint.metadata.importance.PSObject.Properties.Name.Contains("level")) {
                $importance = $restorePoint.metadata.importance.level
            }
            
            $conditionResults["importance"] = ($importanceLevel -eq "All" -or $importance -eq $importanceLevel)
            
            # Vérifier le nombre d'utilisations
            $usageCount = 0
            
            if ($restorePoint.restore_info.PSObject.Properties.Name.Contains("restore_history") -and 
                $restorePoint.restore_info.restore_history -is [array]) {
                $usageCount = $restorePoint.restore_info.restore_history.Count
            }
            
            $conditionResults["usage"] = ($minimumUsageCount -eq 0 -or $usageCount -ge $minimumUsageCount)
            
            # Déterminer si toutes les conditions sont remplies en fonction de l'opérateur
            if ($conditionOperator -eq "AND") {
                $matchesConditions = $conditionResults.Values -notcontains $false
            } else {
                $matchesConditions = $conditionResults.Values -contains $true
            }
            
            if ($matchesConditions) {
                # Vérifier si le point de restauration est expiré en fonction de la date
                $createdAt = [DateTime]::Parse($restorePoint.metadata.created_at)
                
                if ($createdAt -lt $cutoffDate) {
                    $expiredCount++
                    
                    # Afficher les informations sur le point de restauration expiré
                    Write-Log "Expired restore point: $($restorePoint.metadata.id) ($($restorePoint.metadata.name)) - Created: $createdAt" -Level "Info"
                    
                    # Supprimer le fichier si ce n'est pas un test
                    if (-not $WhatIf) {
                        # Vérifier si le point de restauration est protégé
                        $isProtected = $false
                        
                        if ($restorePoint.metadata.PSObject.Properties.Name.Contains("protected") -and $restorePoint.metadata.protected -eq $true) {
                            $isProtected = $true
                        }
                        
                        # Vérifier si le point de restauration a une importance critique
                        $isCritical = $importance -eq "Critical"
                        
                        # Ne pas supprimer les points protégés ou critiques sauf si forcé
                        if (($isProtected -or $isCritical) -and -not $Force) {
                            Write-Log "Skipping protected or critical restore point: $($restorePoint.metadata.id)" -Level "Warning"
                            continue
                        }
                        
                        # Supprimer le fichier
                        Remove-Item -Path $file.FullName -Force
                        $deletedCount++
                        
                        Write-Log "Deleted restore point: $($restorePoint.metadata.id)" -Level "Info"
                    }
                }
                
                # Si une limite de versions est spécifiée, ajouter le point de restauration au dictionnaire
                if ($maxVersions -gt 0) {
                    # Créer une clé unique pour cette configuration
                    $configKey = if (-not [string]::IsNullOrEmpty($currentConfigType) -and -not [string]::IsNullOrEmpty($currentConfigId)) {
                        "$type-$currentConfigType-$currentConfigId"
                    } elseif (-not [string]::IsNullOrEmpty($currentConfigType)) {
                        "$type-$currentConfigType"
                    } else {
                        $type
                    }
                    
                    # Ajouter le point de restauration au dictionnaire
                    if (-not $restorePointsByConfig.ContainsKey($configKey)) {
                        $restorePointsByConfig[$configKey] = @()
                    }
                    
                    $restorePointsByConfig[$configKey] += @{
                        file = $file
                        restore_point = $restorePoint
                        created_at = $createdAt
                    }
                }
            }
        } catch {
            Write-Log "Error processing restore point $($file.Name): $_" -Level "Error"
            $errorCount++
        }
    }
    
    # Traiter la limite de versions si spécifiée
    if ($maxVersions -gt 0) {
        foreach ($configKey in $restorePointsByConfig.Keys) {
            # Trier les points de restauration par date de création (du plus récent au plus ancien)
            $sortedPoints = $restorePointsByConfig[$configKey] | Sort-Object -Property created_at -Descending
            
            # Déterminer les points de restauration à supprimer
            if ($sortedPoints.Count -gt $maxVersions) {
                $pointsToDelete = $sortedPoints[$maxVersions..($sortedPoints.Count - 1)]
                
                foreach ($point in $pointsToDelete) {
                    # Vérifier si le point a déjà été supprimé (par la rétention basée sur le temps)
                    if (-not (Test-Path -Path $point.file.FullName)) {
                        continue
                    }
                    
                    $expiredCount++
                    
                    # Afficher les informations sur le point de restauration expiré
                    Write-Log "Version limit exceeded: $($point.restore_point.metadata.id) ($($point.restore_point.metadata.name)) - Created: $($point.created_at)" -Level "Info"
                    
                    # Supprimer le fichier si ce n'est pas un test
                    if (-not $WhatIf) {
                        # Vérifier si le point de restauration est protégé
                        $isProtected = $false
                        
                        if ($point.restore_point.metadata.PSObject.Properties.Name.Contains("protected") -and $point.restore_point.metadata.protected -eq $true) {
                            $isProtected = $true
                        }
                        
                        # Vérifier si le point de restauration a une importance critique
                        $isCritical = $false
                        
                        if ($point.restore_point.metadata.PSObject.Properties.Name.Contains("importance") -and 
                            $point.restore_point.metadata.importance.PSObject.Properties.Name.Contains("level") -and 
                            $point.restore_point.metadata.importance.level -eq "Critical") {
                            $isCritical = $true
                        }
                        
                        # Ne pas supprimer les points protégés ou critiques sauf si forcé
                        if (($isProtected -or $isCritical) -and -not $Force) {
                            Write-Log "Skipping protected or critical restore point: $($point.restore_point.metadata.id)" -Level "Warning"
                            continue
                        }
                        
                        # Supprimer le fichier
                        Remove-Item -Path $point.file.FullName -Force
                        $deletedCount++
                        
                        Write-Log "Deleted restore point: $($point.restore_point.metadata.id)" -Level "Info"
                    }
                }
            }
        }
    }
    
    # Afficher le résumé
    if ($WhatIf) {
        Write-Log "WhatIf: $expiredCount restore points would be expired" -Level "Info"
    } else {
        Write-Log "Applied composite retention rule: $deletedCount restore points deleted, $errorCount errors" -Level "Info"
    }
    
    return $errorCount -eq 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Set-CompositeRetention -RuleName $RuleName -Description $Description -RestorePointType $RestorePointType -ConfigType $ConfigType -ConfigId $ConfigId -ImportanceLevel $ImportanceLevel -MinimumUsageCount $MinimumUsageCount -RetentionDays $RetentionDays -MaxVersions $MaxVersions -ConditionOperator $ConditionOperator -Priority $Priority -ConfigName $ConfigName -Apply:$Apply -WhatIf:$WhatIf -Force:$Force
}

