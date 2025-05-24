# Set-VersionBasedRetention.ps1
# Script pour configurer et appliquer la rétention basée sur le nombre de versions pour les points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Manual", "Automatic", "Scheduled", "Pre-Update", "Pre-Migration", "Git-Commit", "Intelligent")]
    [string]$RestorePointType = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigType = "",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigId = "",
    
    [Parameter(Mandatory = $false)]
    [int]$MaxVersions = 10,
    
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

# Fonction pour configurer la rétention basée sur le nombre de versions
function Set-VersionBasedRetention {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Manual", "Automatic", "Scheduled", "Pre-Update", "Pre-Migration", "Git-Commit", "Intelligent")]
        [string]$RestorePointType = "All",
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigType = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigId = "",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxVersions = 10,
        
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
    if ($MaxVersions -lt 1) {
        Write-Log "MaxVersions must be at least 1" -Level "Error"
        return $false
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
    
    # Normaliser le type de point de restauration
    $normalizedType = $RestorePointType.ToLower()
    
    # Mettre à jour ou ajouter la politique de rétention basée sur le nombre de versions
    if (-not $config.policies.ContainsKey("version_based")) {
        $config.policies.version_based = @{}
    }
    
    # Créer une clé unique pour cette politique
    $policyKey = $normalizedType
    
    if (-not [string]::IsNullOrEmpty($ConfigType) -and -not [string]::IsNullOrEmpty($ConfigId)) {
        $policyKey = "$normalizedType-$($ConfigType.ToLower())-$ConfigId"
    } elseif (-not [string]::IsNullOrEmpty($ConfigType)) {
        $policyKey = "$normalizedType-$($ConfigType.ToLower())"
    }
    
    if (-not $config.policies.version_based.ContainsKey($policyKey)) {
        $config.policies.version_based.$policyKey = @{}
    }
    
    $config.policies.version_based.$policyKey.max_versions = $MaxVersions
    $config.policies.version_based.$policyKey.config_type = $ConfigType
    $config.policies.version_based.$policyKey.config_id = $ConfigId
    $config.policies.version_based.$policyKey.last_updated = (Get-Date).ToString("o")
    
    # Sauvegarder la configuration
    $result = Save-RetentionConfig -Config $config -ConfigName $ConfigName
    
    if (-not $result) {
        return $false
    }
    
    $targetDescription = if (-not [string]::IsNullOrEmpty($ConfigType) -and -not [string]::IsNullOrEmpty($ConfigId)) {
        "$ConfigType:$ConfigId"
    } elseif (-not [string]::IsNullOrEmpty($ConfigType)) {
        "$ConfigType"
    } else {
        "all configurations"
    }
    
    Write-Log "Version-based retention policy configured: $MaxVersions versions for $RestorePointType restore points of $targetDescription" -Level "Info"
    
    # Appliquer la politique si demandé
    if ($Apply) {
        return Set-VersionBasedRetention -RestorePointType $RestorePointType -ConfigType $ConfigType -ConfigId $ConfigId -MaxVersions $MaxVersions -WhatIf:$WhatIf -Force:$Force
    }
    
    return $true
}

# Fonction pour appliquer la rétention basée sur le nombre de versions
function Set-VersionBasedRetention {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "Manual", "Automatic", "Scheduled", "Pre-Update", "Pre-Migration", "Git-Commit", "Intelligent")]
        [string]$RestorePointType = "All",
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigType = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigId = "",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxVersions = 10,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Obtenir le chemin des points de restauration
    $pointsPath = Get-RestorePointsPath
    
    # Obtenir tous les fichiers de points de restauration
    $restorePointFiles = Get-ChildItem -Path $pointsPath -Filter "*.json"
    
    if ($restorePointFiles.Count -eq 0) {
        Write-Log "No restore points found" -Level "Warning"
        return $true
    }
    
    Write-Log "Found $($restorePointFiles.Count) restore points" -Level "Info"
    
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
            
            # Vérifier si le point de restauration correspond au type spécifié
            $type = $restorePoint.metadata.type
            
            if ($RestorePointType -ne "All" -and $type -ne $RestorePointType.ToLower()) {
                continue
            }
            
            # Extraire les informations de configuration
            $configType = ""
            $configId = ""
            
            if ($restorePoint.content.PSObject.Properties.Name.Contains("configurations") -and 
                $restorePoint.content.configurations.Count -gt 0) {
                $configType = $restorePoint.content.configurations[0].type
                $configId = $restorePoint.content.configurations[0].id
            }
            
            # Vérifier si la configuration correspond aux critères spécifiés
            if (-not [string]::IsNullOrEmpty($ConfigType) -and $configType -ne $ConfigType) {
                continue
            }
            
            if (-not [string]::IsNullOrEmpty($ConfigId) -and $configId -ne $ConfigId) {
                continue
            }
            
            # Créer une clé unique pour cette configuration
            $configKey = if (-not [string]::IsNullOrEmpty($configType) -and -not [string]::IsNullOrEmpty($configId)) {
                "$type-$configType-$configId"
            } elseif (-not [string]::IsNullOrEmpty($configType)) {
                "$type-$configType"
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
                created_at = [DateTime]::Parse($restorePoint.metadata.created_at)
            }
        } catch {
            Write-Log "Error processing restore point $($file.Name): $_" -Level "Error"
            $errorCount++
        }
    }
    
    # Traiter chaque groupe de points de restauration
    foreach ($configKey in $restorePointsByConfig.Keys) {
        # Trier les points de restauration par date de création (du plus récent au plus ancien)
        $sortedPoints = $restorePointsByConfig[$configKey] | Sort-Object -Property created_at -Descending
        
        # Déterminer les points de restauration à supprimer
        if ($sortedPoints.Count -gt $MaxVersions) {
            $pointsToDelete = $sortedPoints[$MaxVersions..($sortedPoints.Count - 1)]
            
            foreach ($point in $pointsToDelete) {
                $expiredCount++
                
                # Afficher les informations sur le point de restauration expiré
                Write-Log "Expired restore point: $($point.restore_point.metadata.id) ($($point.restore_point.metadata.name)) - Created: $($point.created_at)" -Level "Info"
                
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
    
    # Afficher le résumé
    if ($WhatIf) {
        Write-Log "WhatIf: $expiredCount restore points would be expired" -Level "Info"
    } else {
        Write-Log "Applied version-based retention: $deletedCount restore points deleted, $errorCount errors" -Level "Info"
    }
    
    return $errorCount -eq 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Set-VersionBasedRetention -RestorePointType $RestorePointType -ConfigType $ConfigType -ConfigId $ConfigId -MaxVersions $MaxVersions -ConfigName $ConfigName -Apply:$Apply -WhatIf:$WhatIf -Force:$Force
}

