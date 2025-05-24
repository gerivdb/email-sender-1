# Set-ImportanceBasedRetention.ps1
# Script pour configurer et appliquer la rétention basée sur l'importance des points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Critical", "High", "Medium", "Low", "All")]
    [string]$ImportanceLevel = "All",
    
    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 0,
    
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

# Importer le script de classification des points par importance
$importancePath = Join-Path -Path $rootPath -ChildPath "intelligence\Set-RestorePointImportance.ps1"

if (Test-Path -Path $importancePath) {
    . $importancePath
} else {
    Write-Log "Required script not found: $importancePath" -Level "Warning"
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

# Fonction pour configurer la rétention basée sur l'importance
function Set-ImportanceBasedRetention {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "High", "Medium", "Low", "All")]
        [string]$ImportanceLevel = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 0,
        
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
    
    # Normaliser le niveau d'importance
    $normalizedLevel = $ImportanceLevel.ToLower()
    
    # Mettre à jour ou ajouter la politique de rétention basée sur l'importance
    if (-not $config.policies.ContainsKey("importance_based")) {
        $config.policies.importance_based = @{}
    }
    
    if (-not $config.policies.importance_based.ContainsKey($normalizedLevel)) {
        $config.policies.importance_based.$normalizedLevel = @{}
    }
    
    $config.policies.importance_based.$normalizedLevel.retention_days = $RetentionDays
    $config.policies.importance_based.$normalizedLevel.last_updated = (Get-Date).ToString("o")
    
    # Sauvegarder la configuration
    $result = Save-RetentionConfig -Config $config -ConfigName $ConfigName
    
    if (-not $result) {
        return $false
    }
    
    $retentionDescription = if ($RetentionDays -eq 0) {
        "keep forever"
    } else {
        "$RetentionDays days"
    }
    
    Write-Log "Importance-based retention policy configured: $retentionDescription for $ImportanceLevel importance restore points" -Level "Info"
    
    # Appliquer la politique si demandé
    if ($Apply) {
        return Set-ImportanceBasedRetention -ImportanceLevel $ImportanceLevel -RetentionDays $RetentionDays -WhatIf:$WhatIf -Force:$Force
    }
    
    return $true
}

# Fonction pour appliquer la rétention basée sur l'importance
function Set-ImportanceBasedRetention {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "High", "Medium", "Low", "All")]
        [string]$ImportanceLevel = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$RetentionDays = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Si la rétention est définie à 0 (conserver indéfiniment), ne rien faire
    if ($RetentionDays -eq 0) {
        Write-Log "Retention days set to 0 (keep forever) for $ImportanceLevel importance restore points" -Level "Info"
        return $true
    }
    
    # Obtenir le chemin des points de restauration
    $pointsPath = Get-RestorePointsPath
    
    # Obtenir tous les fichiers de points de restauration
    $restorePointFiles = Get-ChildItem -Path $pointsPath -Filter "*.json"
    
    if ($restorePointFiles.Count -eq 0) {
        Write-Log "No restore points found" -Level "Warning"
        return $true
    }
    
    Write-Log "Found $($restorePointFiles.Count) restore points" -Level "Info"
    
    # Calculer la date limite
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    
    # Initialiser les compteurs
    $expiredCount = 0
    $deletedCount = 0
    $errorCount = 0
    $recalculatedCount = 0
    
    # Traiter chaque fichier de point de restauration
    foreach ($file in $restorePointFiles) {
        try {
            # Charger le point de restauration
            $restorePoint = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Vérifier si le point de restauration a une importance définie
            $hasImportance = $restorePoint.metadata.PSObject.Properties.Name.Contains("importance") -and 
                            $restorePoint.metadata.importance.PSObject.Properties.Name.Contains("level")
            
            # Si l'importance n'est pas définie et que la fonction de calcul est disponible, la calculer
            if (-not $hasImportance -and (Get-Command -Name "Set-RestorePointImportance" -ErrorAction SilentlyContinue)) {
                Write-Log "Calculating importance for restore point: $($restorePoint.metadata.id)" -Level "Debug"
                $importanceResult = Set-RestorePointImportance -RestorePointPath $file.FullName -Importance "Auto" -Force
                
                if ($importanceResult -ne $false) {
                    # Recharger le point de restauration avec l'importance calculée
                    $restorePoint = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                    $hasImportance = $true
                    $recalculatedCount++
                }
            }
            
            # Si l'importance est définie, vérifier si elle correspond au niveau spécifié
            if ($hasImportance) {
                $importance = $restorePoint.metadata.importance.level
                
                # Vérifier si le niveau d'importance correspond
                if ($ImportanceLevel -ne "All" -and $importance -ne $ImportanceLevel) {
                    continue
                }
                
                # Vérifier si le point de restauration est expiré
                $createdAt = [DateTime]::Parse($restorePoint.metadata.created_at)
                
                if ($createdAt -lt $cutoffDate) {
                    $expiredCount++
                    
                    # Afficher les informations sur le point de restauration expiré
                    Write-Log "Expired restore point: $($restorePoint.metadata.id) ($($restorePoint.metadata.name)) - Created: $createdAt, Importance: $importance" -Level "Info"
                    
                    # Supprimer le fichier si ce n'est pas un test
                    if (-not $WhatIf) {
                        # Vérifier si le point de restauration est protégé
                        $isProtected = $false
                        
                        if ($restorePoint.metadata.PSObject.Properties.Name.Contains("protected") -and $restorePoint.metadata.protected -eq $true) {
                            $isProtected = $true
                        }
                        
                        # Ne pas supprimer les points protégés sauf si forcé
                        if ($isProtected -and -not $Force) {
                            Write-Log "Skipping protected restore point: $($restorePoint.metadata.id)" -Level "Warning"
                            continue
                        }
                        
                        # Ne jamais supprimer les points critiques sauf si explicitement ciblés
                        if ($importance -eq "Critical" -and $ImportanceLevel -ne "Critical" -and -not $Force) {
                            Write-Log "Skipping critical restore point: $($restorePoint.metadata.id)" -Level "Warning"
                            continue
                        }
                        
                        # Supprimer le fichier
                        Remove-Item -Path $file.FullName -Force
                        $deletedCount++
                        
                        Write-Log "Deleted restore point: $($restorePoint.metadata.id)" -Level "Info"
                    }
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
        Write-Log "Applied importance-based retention: $deletedCount restore points deleted, $recalculatedCount importance recalculated, $errorCount errors" -Level "Info"
    }
    
    return $errorCount -eq 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Set-ImportanceBasedRetention -ImportanceLevel $ImportanceLevel -RetentionDays $RetentionDays -ConfigName $ConfigName -Apply:$Apply -WhatIf:$WhatIf -Force:$Force
}

