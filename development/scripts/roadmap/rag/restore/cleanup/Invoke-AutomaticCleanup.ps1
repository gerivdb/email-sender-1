# Invoke-AutomaticCleanup.ps1
# Script principal pour orchestrer le système de nettoyage automatique des points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigName = "default",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "TimeBasedRetention", "VersionBasedRetention", "ImportanceBasedRetention", "UsageBasedRetention", "CompositeRetention")]
    [string[]]$PolicyTypes = @("All"),
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Basic", "Standard", "Thorough")]
    [string]$ConsistencyCheckLevel = "Standard",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipConsistencyCheck,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableNotifications,
    
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

# Importer les scripts nécessaires
$retentionPoliciesPath = Join-Path -Path $parentPath -ChildPath "retention\Invoke-RetentionPolicies.ps1"
$consistencyCheckPath = Join-Path -Path $scriptPath -ChildPath "Test-RestorePointConsistency.ps1"
$deletionLogPath = Join-Path -Path $scriptPath -ChildPath "Write-DeletionLog.ps1"
$notificationPath = Join-Path -Path $scriptPath -ChildPath "Send-CleanupNotification.ps1"

# Vérifier et importer les scripts
$requiredScripts = @(
    @{ Path = $retentionPoliciesPath; Name = "Invoke-RetentionPolicies.ps1" },
    @{ Path = $consistencyCheckPath; Name = "Test-RestorePointConsistency.ps1" },
    @{ Path = $deletionLogPath; Name = "Write-DeletionLog.ps1" },
    @{ Path = $notificationPath; Name = "Send-CleanupNotification.ps1" }
)

foreach ($script in $requiredScripts) {
    if (Test-Path -Path $script.Path) {
        . $script.Path
    } else {
        Write-Log "Required script not found: $($script.Name)" -Level "Error"
        exit 1
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

# Fonction pour obtenir le chemin du fichier de configuration du nettoyage
function Get-CleanupConfigPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    
    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }
    
    $cleanupPath = Join-Path -Path $configPath -ChildPath "cleanup"
    
    if (-not (Test-Path -Path $cleanupPath)) {
        New-Item -Path $cleanupPath -ItemType Directory -Force | Out-Null
    }
    
    return Join-Path -Path $cleanupPath -ChildPath "$ConfigName.json"
}

# Fonction pour charger la configuration du nettoyage
function Get-CleanupConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )
    
    $configPath = Get-CleanupConfigPath -ConfigName $ConfigName
    
    if (Test-Path -Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading cleanup configuration: $_" -Level "Error"
            return $null
        }
    } else {
        # Créer une configuration par défaut
        $defaultConfig = @{
            name = $ConfigName
            created_at = (Get-Date).ToString("o")
            last_modified = (Get-Date).ToString("o")
            consistency_check = @{
                enabled = $true
                level = "Standard"
                skip_for_policies = @()
            }
            logging = @{
                enabled = $true
                include_content = $true
                format = "Both"
            }
            notifications = @{
                enabled = $true
                channels = @("Console", "Log")
            }
            policies = @{
                enabled = @("All")
            }
        }
        
        # Sauvegarder la configuration par défaut
        try {
            $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
            Write-Log "Created default cleanup configuration: $configPath" -Level "Info"
        } catch {
            Write-Log "Error creating default cleanup configuration: $_" -Level "Error"
        }
        
        return $defaultConfig
    }
}

# Fonction pour vérifier et supprimer un point de restauration
function Remove-RestorePointWithChecks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RestorePointPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Standard", "Thorough")]
        [string]$ConsistencyCheckLevel = "Standard",
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipConsistencyCheck,
        
        [Parameter(Mandatory = $false)]
        [string]$DeletionReason = "Retention policy",
        
        [Parameter(Mandatory = $false)]
        [string]$PolicyName = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableLogging,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "Both")]
        [string]$LogFormat = "Both",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $RestorePointPath)) {
        Write-Log "Restore point file not found: $RestorePointPath" -Level "Warning"
        return $false
    }
    
    # Charger le point de restauration
    try {
        $restorePoint = Get-Content -Path $RestorePointPath -Raw | ConvertFrom-Json
    } catch {
        Write-Log "Error loading restore point: $($_.Exception.Message)" -Level "Error"
        return $false
    }
    
    # Extraire les informations du point de restauration
    $restorePointId = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                          $restorePoint.metadata.PSObject.Properties.Name.Contains("id")) {
        $restorePoint.metadata.id
    } else {
        [System.IO.Path]::GetFileNameWithoutExtension($RestorePointPath)
    }
    
    $restorePointName = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                            $restorePoint.metadata.PSObject.Properties.Name.Contains("name")) {
        $restorePoint.metadata.name
    } else {
        ""
    }
    
    $restorePointType = if ($restorePoint.PSObject.Properties.Name.Contains("metadata") -and 
                            $restorePoint.metadata.PSObject.Properties.Name.Contains("type")) {
        $restorePoint.metadata.type
    } else {
        ""
    }
    
    # Vérifier la cohérence du point de restauration
    if (-not $SkipConsistencyCheck) {
        $consistencyResult = Test-RestorePointConsistency -RestorePointPath $RestorePointPath -VerificationLevel $ConsistencyCheckLevel
        
        if (-not $consistencyResult.IsConsistent) {
            Write-Log "Restore point is inconsistent: $RestorePointPath" -Level "Warning"
            
            foreach ($error in $consistencyResult.Errors) {
                Write-Log "  - $error" -Level "Warning"
            }
            
            if (-not $Force) {
                Write-Log "Skipping deletion of inconsistent restore point. Use -Force to override." -Level "Warning"
                return $false
            } else {
                Write-Log "Forcing deletion of inconsistent restore point" -Level "Warning"
            }
        }
        
        # Vérifier les références
        if ($consistencyResult.References.Count -gt 0 -and -not $Force) {
            Write-Log "Restore point is referenced by $($consistencyResult.References.Count) other restore points" -Level "Warning"
            Write-Log "Skipping deletion of referenced restore point. Use -Force to override." -Level "Warning"
            return $false
        }
    }
    
    # Journaliser la suppression
    if ($EnableLogging) {
        $additionalInfo = @{
            consistency_check = if ($SkipConsistencyCheck) { "Skipped" } else { $ConsistencyCheckLevel }
            forced = $Force.IsPresent
            what_if = $WhatIf.IsPresent
        }
        
        Write-DeletionLog -RestorePointId $restorePointId -RestorePointName $restorePointName -RestorePointType $restorePointType -DeletionReason $DeletionReason -PolicyName $PolicyName -AdditionalInfo $additionalInfo -LogFormat $LogFormat -IncludeContent:$IncludeContent
    }
    
    # Supprimer le fichier
    if (-not $WhatIf) {
        try {
            Remove-Item -Path $RestorePointPath -Force
            Write-Log "Deleted restore point: $RestorePointPath" -Level "Info"
            return $true
        } catch {
            Write-Log "Error deleting restore point: $($_.Exception.Message)" -Level "Error"
            return $false
        }
    } else {
        Write-Log "WhatIf: Would delete restore point: $RestorePointPath" -Level "Info"
        return $true
    }
}

# Fonction principale pour le nettoyage automatique
function Invoke-AutomaticCleanup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "TimeBasedRetention", "VersionBasedRetention", "ImportanceBasedRetention", "UsageBasedRetention", "CompositeRetention")]
        [string[]]$PolicyTypes = @("All"),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Standard", "Thorough")]
        [string]$ConsistencyCheckLevel = "Standard",
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipConsistencyCheck,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableNotifications
    )
    
    # Charger la configuration
    $config = Get-CleanupConfig -ConfigName $ConfigName
    
    if ($null -eq $config) {
        Write-Log "Failed to load cleanup configuration" -Level "Error"
        return $false
    }
    
    # Fusionner les paramètres avec la configuration
    if ($PolicyTypes.Count -eq 0 -or ($PolicyTypes.Count -eq 1 -and $PolicyTypes[0] -eq "All")) {
        $PolicyTypes = $config.policies.enabled
    }
    
    if (-not $PSBoundParameters.ContainsKey("ConsistencyCheckLevel") -and $config.consistency_check.PSObject.Properties.Name.Contains("level")) {
        $ConsistencyCheckLevel = $config.consistency_check.level
    }
    
    if (-not $PSBoundParameters.ContainsKey("SkipConsistencyCheck") -and $config.consistency_check.PSObject.Properties.Name.Contains("enabled")) {
        $SkipConsistencyCheck = -not $config.consistency_check.enabled
    }
    
    if (-not $PSBoundParameters.ContainsKey("EnableNotifications") -and $config.notifications.PSObject.Properties.Name.Contains("enabled")) {
        $EnableNotifications = $config.notifications.enabled
    }
    
    # Initialiser les compteurs
    $startTime = Get-Date
    $totalPoints = 0
    $processedPoints = 0
    $deletedPoints = 0
    $errorCount = 0
    
    # Envoyer une notification de début
    if ($EnableNotifications) {
        $details = @{
            "Configuration" = $ConfigName
            "Policies" = $PolicyTypes -join ", "
            "Consistency Check" = if ($SkipConsistencyCheck) { "Skipped" } else { $ConsistencyCheckLevel }
            "Force" = $Force.ToString()
            "WhatIf" = $WhatIf.ToString()
        }
        
        Send-CleanupNotification -NotificationType "Start" -Details $details
    }
    
    try {
        # Appliquer les politiques de rétention
        Write-Log "Applying retention policies: $($PolicyTypes -join ', ')" -Level "Info"
        
        $result = Invoke-RetentionPolicies -ConfigName $ConfigName -PolicyTypes $PolicyTypes -WhatIf:$WhatIf -Force:$Force
        
        if (-not $result) {
            Write-Log "Errors occurred while applying retention policies" -Level "Warning"
            $errorCount++
        }
        
        # Obtenir le chemin du répertoire des points de restauration
        $pointsPath = Get-RestorePointsPath
        
        # Obtenir tous les fichiers de points de restauration
        $restorePointFiles = Get-ChildItem -Path $pointsPath -Filter "*.json"
        $totalPoints = $restorePointFiles.Count
        
        Write-Log "Found $totalPoints restore points" -Level "Info"
        
        # Traiter chaque fichier de point de restauration
        foreach ($file in $restorePointFiles) {
            $processedPoints++
            
            # Vérifier si le fichier existe toujours (il peut avoir été supprimé par les politiques de rétention)
            if (-not (Test-Path -Path $file.FullName)) {
                continue
            }
            
            # Supprimer le point de restauration avec les vérifications
            $result = Remove-RestorePointWithChecks -RestorePointPath $file.FullName -ConsistencyCheckLevel $ConsistencyCheckLevel -SkipConsistencyCheck:$SkipConsistencyCheck -DeletionReason "Automatic cleanup" -PolicyName "Cleanup" -Force:$Force -WhatIf:$WhatIf -EnableLogging:$true -LogFormat "Both" -IncludeContent:$true
            
            if ($result) {
                $deletedPoints++
            } else {
                $errorCount++
            }
        }
    } catch {
        Write-Log "Error during automatic cleanup: $($_.Exception.Message)" -Level "Error"
        $errorCount++
        
        # Envoyer une notification d'erreur
        if ($EnableNotifications) {
            $details = @{
                "Error" = $_.Exception.Message
                "Stack Trace" = $_.ScriptStackTrace
            }
            
            Send-CleanupNotification -NotificationType "Error" -Details $details
        }
    } finally {
        # Calculer les statistiques
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Envoyer une notification de fin
        if ($EnableNotifications) {
            $notificationType = if ($errorCount -gt 0) { "Warning" } else { "Complete" }
            
            $details = @{
                "Total Points" = $totalPoints
                "Processed Points" = $processedPoints
                "Deleted Points" = $deletedPoints
                "Errors" = $errorCount
                "Duration" = "$($duration.Minutes) minutes, $($duration.Seconds) seconds"
                "Start Time" = $startTime.ToString("yyyy-MM-dd HH:mm:ss")
                "End Time" = $endTime.ToString("yyyy-MM-dd HH:mm:ss")
            }
            
            Send-CleanupNotification -NotificationType $notificationType -Details $details
        }
    }
    
    # Afficher le résumé
    Write-Log "Automatic cleanup completed: $deletedPoints points deleted, $errorCount errors" -Level "Info"
    Write-Log "Duration: $($duration.Minutes) minutes, $($duration.Seconds) seconds" -Level "Info"
    
    return $errorCount -eq 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-AutomaticCleanup -ConfigName $ConfigName -PolicyTypes $PolicyTypes -ConsistencyCheckLevel $ConsistencyCheckLevel -SkipConsistencyCheck:$SkipConsistencyCheck -Force:$Force -WhatIf:$WhatIf -EnableNotifications:$EnableNotifications
}
