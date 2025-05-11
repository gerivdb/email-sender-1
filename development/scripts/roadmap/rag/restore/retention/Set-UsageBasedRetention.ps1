# Set-UsageBasedRetention.ps1
# Script pour configurer et appliquer la rétention basée sur l'utilisation des points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$MinimumUsageCount = 1,
    
    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 90,
    
    [Parameter(Mandatory = $false)]
    [int]$UnusedRetentionDays = 30,
    
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

# Fonction pour configurer la rétention basée sur l'utilisation
function Set-UsageBasedRetention {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MinimumUsageCount = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 90,
        
        [Parameter(Mandatory = $false)]
        [int]$UnusedRetentionDays = 30,
        
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
    if ($MinimumUsageCount -lt 0) {
        Write-Log "MinimumUsageCount must be at least 0" -Level "Error"
        return $false
    }
    
    if ($RetentionDays -lt 1) {
        Write-Log "RetentionDays must be at least 1" -Level "Error"
        return $false
    }
    
    if ($UnusedRetentionDays -lt 1) {
        Write-Log "UnusedRetentionDays must be at least 1" -Level "Error"
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
    
    # Mettre à jour ou ajouter la politique de rétention basée sur l'utilisation
    if (-not $config.policies.ContainsKey("usage_based")) {
        $config.policies.usage_based = @{}
    }
    
    $config.policies.usage_based.minimum_usage_count = $MinimumUsageCount
    $config.policies.usage_based.retention_days = $RetentionDays
    $config.policies.usage_based.unused_retention_days = $UnusedRetentionDays
    $config.policies.usage_based.last_updated = (Get-Date).ToString("o")
    
    # Sauvegarder la configuration
    $result = Save-RetentionConfig -Config $config -ConfigName $ConfigName
    
    if (-not $result) {
        return $false
    }
    
    Write-Log "Usage-based retention policy configured: Keep points with $MinimumUsageCount+ uses for $RetentionDays days, unused points for $UnusedRetentionDays days" -Level "Info"
    
    # Appliquer la politique si demandé
    if ($Apply) {
        return Apply-UsageBasedRetention -MinimumUsageCount $MinimumUsageCount -RetentionDays $RetentionDays -UnusedRetentionDays $UnusedRetentionDays -WhatIf:$WhatIf -Force:$Force
    }
    
    return $true
}

# Fonction pour appliquer la rétention basée sur l'utilisation
function Apply-UsageBasedRetention {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MinimumUsageCount = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 90,
        
        [Parameter(Mandatory = $false)]
        [int]$UnusedRetentionDays = 30,
        
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
    
    # Calculer les dates limites
    $usedCutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $unusedCutoffDate = (Get-Date).AddDays(-$UnusedRetentionDays)
    
    # Initialiser les compteurs
    $expiredCount = 0
    $deletedCount = 0
    $errorCount = 0
    
    # Traiter chaque fichier de point de restauration
    foreach ($file in $restorePointFiles) {
        try {
            # Charger le point de restauration
            $restorePoint = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Vérifier si le point de restauration a un historique de restauration
            $hasRestoreHistory = $restorePoint.restore_info.PSObject.Properties.Name.Contains("restore_history") -and 
                                $restorePoint.restore_info.restore_history -is [array]
            
            # Déterminer le nombre d'utilisations
            $usageCount = 0
            
            if ($hasRestoreHistory) {
                $usageCount = $restorePoint.restore_info.restore_history.Count
            }
            
            # Déterminer la date de création
            $createdAt = [DateTime]::Parse($restorePoint.metadata.created_at)
            
            # Déterminer si le point de restauration est expiré
            $isExpired = $false
            $expirationReason = ""
            
            if ($usageCount -ge $MinimumUsageCount) {
                # Point utilisé - vérifier par rapport à la période de rétention des points utilisés
                if ($createdAt -lt $usedCutoffDate) {
                    $isExpired = $true
                    $expirationReason = "Used restore point ($usageCount uses) older than $RetentionDays days"
                }
            } else {
                # Point non utilisé - vérifier par rapport à la période de rétention des points non utilisés
                if ($createdAt -lt $unusedCutoffDate) {
                    $isExpired = $true
                    $expirationReason = "Unused restore point older than $UnusedRetentionDays days"
                }
            }
            
            # Traiter les points expirés
            if ($isExpired) {
                $expiredCount++
                
                # Afficher les informations sur le point de restauration expiré
                Write-Log "Expired restore point: $($restorePoint.metadata.id) ($($restorePoint.metadata.name)) - Created: $createdAt, Usage: $usageCount - $expirationReason" -Level "Info"
                
                # Supprimer le fichier si ce n'est pas un test
                if (-not $WhatIf) {
                    # Vérifier si le point de restauration est protégé
                    $isProtected = $false
                    
                    if ($restorePoint.metadata.PSObject.Properties.Name.Contains("protected") -and $restorePoint.metadata.protected -eq $true) {
                        $isProtected = $true
                    }
                    
                    # Vérifier si le point de restauration a une importance critique
                    $isCritical = $false
                    
                    if ($restorePoint.metadata.PSObject.Properties.Name.Contains("importance") -and 
                        $restorePoint.metadata.importance.PSObject.Properties.Name.Contains("level") -and 
                        $restorePoint.metadata.importance.level -eq "Critical") {
                        $isCritical = $true
                    }
                    
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
        } catch {
            Write-Log "Error processing restore point $($file.Name): $_" -Level "Error"
            $errorCount++
        }
    }
    
    # Afficher le résumé
    if ($WhatIf) {
        Write-Log "WhatIf: $expiredCount restore points would be expired" -Level "Info"
    } else {
        Write-Log "Applied usage-based retention: $deletedCount restore points deleted, $errorCount errors" -Level "Info"
    }
    
    return $errorCount -eq 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Set-UsageBasedRetention -MinimumUsageCount $MinimumUsageCount -RetentionDays $RetentionDays -UnusedRetentionDays $UnusedRetentionDays -ConfigName $ConfigName -Apply:$Apply -WhatIf:$WhatIf -Force:$Force
}
