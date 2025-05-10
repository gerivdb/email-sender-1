# New-IntelligentRestorePoint.ps1
# Script pour créer intelligemment des points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
    [string]$ConfigType,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigId,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [object]$Configuration,
    
    [Parameter(Mandatory = $false)]
    [string]$Name,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Tags = @(),
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Strict", "Normal", "Relaxed", "Custom")]
    [string]$Sensitivity = "Normal",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipAnalysis,
    
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
$newRestorePointPath = Join-Path -Path $rootPath -ChildPath "New-RestorePoint.ps1"
$significantChangePath = Join-Path -Path $scriptPath -ChildPath "Test-SignificantChange.ps1"
$changeImpactPath = Join-Path -Path $scriptPath -ChildPath "Get-ChangeImpactAnalysis.ps1"
$adaptiveThresholdsPath = Join-Path -Path $scriptPath -ChildPath "Set-AdaptiveThresholds.ps1"
$importancePath = Join-Path -Path $scriptPath -ChildPath "Set-RestorePointImportance.ps1"

# Vérifier et importer les scripts
$requiredScripts = @(
    @{ Path = $newRestorePointPath; Name = "New-RestorePoint.ps1" },
    @{ Path = $significantChangePath; Name = "Test-SignificantChange.ps1" },
    @{ Path = $changeImpactPath; Name = "Get-ChangeImpactAnalysis.ps1" },
    @{ Path = $adaptiveThresholdsPath; Name = "Set-AdaptiveThresholds.ps1" },
    @{ Path = $importancePath; Name = "Set-RestorePointImportance.ps1" }
)

foreach ($script in $requiredScripts) {
    if (Test-Path -Path $script.Path) {
        . $script.Path
    } else {
        Write-Log "Required script not found: $($script.Name)" -Level "Error"
        exit 1
    }
}

# Fonction pour charger une configuration à partir d'un fichier
function Get-ConfigurationFromPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Log "Configuration file not found: $ConfigPath" -Level "Error"
        return $null
    }
    
    try {
        $configuration = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $configuration
    } catch {
        Write-Log "Error loading configuration from file: $_" -Level "Error"
        return $null
    }
}

# Fonction pour obtenir la dernière version d'une configuration
function Get-LastConfigurationState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$ConfigId
    )
    
    # Obtenir le chemin du répertoire des états de configuration
    $statesPath = Join-Path -Path $rootPath -ChildPath "states"
    
    if (-not (Test-Path -Path $statesPath)) {
        Write-Log "States directory not found: $statesPath" -Level "Warning"
        return $null
    }
    
    # Rechercher le fichier d'état le plus récent pour cette configuration
    $stateFileName = "$($ConfigType.ToLower())_$ConfigId"
    $stateFiles = Get-ChildItem -Path $statesPath -Filter "$stateFileName*_state.json" | Sort-Object LastWriteTime -Descending
    
    if ($stateFiles.Count -eq 0) {
        Write-Log "No previous state found for $ConfigType:$ConfigId" -Level "Warning"
        return $null
    }
    
    # Charger l'état le plus récent
    try {
        $state = Get-Content -Path $stateFiles[0].FullName -Raw | ConvertFrom-Json
        return $state.state
    } catch {
        Write-Log "Error loading previous state: $_" -Level "Error"
        return $null
    }
}

# Fonction pour créer intelligemment un point de restauration
function New-IntelligentRestorePoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigId,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Strict", "Normal", "Relaxed", "Custom")]
        [string]$Sensitivity = "Normal",
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipAnalysis
    )
    
    # Charger la configuration à partir du fichier si nécessaire
    if ($null -eq $Configuration -and -not [string]::IsNullOrEmpty($ConfigPath)) {
        $Configuration = Get-ConfigurationFromPath -ConfigPath $ConfigPath
        
        if ($null -eq $Configuration) {
            return $false
        }
    }
    
    # Vérifier si la configuration est disponible
    if ($null -eq $Configuration) {
        Write-Log "Configuration must be provided" -Level "Error"
        return $false
    }
    
    # Déterminer le type de configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigType)) {
        if ($Configuration.PSObject.Properties.Name.Contains("type")) {
            $ConfigType = $Configuration.type
        } else {
            Write-Log "Configuration type must be specified" -Level "Error"
            return $false
        }
    }
    
    # Déterminer l'ID de la configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigId)) {
        if ($Configuration.PSObject.Properties.Name.Contains("id")) {
            $ConfigId = $Configuration.id
        } else {
            Write-Log "Configuration ID must be specified" -Level "Error"
            return $false
        }
    }
    
    # Obtenir la dernière version de la configuration
    $lastConfiguration = Get-LastConfigurationState -ConfigType $ConfigType -ConfigId $ConfigId
    
    # Si aucune version précédente n'est trouvée ou si l'analyse est ignorée, créer un point de restauration
    if ($null -eq $lastConfiguration -or $SkipAnalysis -or $Force) {
        $createReason = if ($null -eq $lastConfiguration) {
            "No previous state found"
        } elseif ($SkipAnalysis) {
            "Analysis skipped"
        } else {
            "Forced creation"
        }
        
        Write-Log "Creating restore point for $ConfigType:$ConfigId - $createReason" -Level "Info"
        
        # Ajouter un tag indiquant la raison de la création
        $Tags += "intelligent"
        $Tags += $createReason.ToLower().Replace(" ", "_")
        
        # Créer le point de restauration
        $restorePoint = New-RestorePoint -ConfigType $ConfigType -ConfigId $ConfigId -Configuration $Configuration -Name $Name -Description $Description -Tags $Tags -Type "intelligent"
        
        if ($null -ne $restorePoint) {
            # Définir l'importance du point de restauration
            Set-RestorePointImportance -RestorePointId $restorePoint.metadata.id -Importance "Auto"
            
            Write-Log "Restore point created successfully: $($restorePoint.metadata.id)" -Level "Info"
            return $restorePoint
        } else {
            Write-Log "Failed to create restore point" -Level "Error"
            return $false
        }
    }
    
    # Analyser les changements
    Write-Log "Analyzing changes for $ConfigType:$ConfigId" -Level "Info"
    
    # Obtenir les seuils adaptatifs ou par défaut
    $thresholds = Get-Thresholds -ConfigType $ConfigType
    
    if ($null -eq $thresholds) {
        Write-Log "No thresholds found for $ConfigType. Using default thresholds with $Sensitivity sensitivity." -Level "Info"
        $thresholds = Get-SensitivityThresholds -Sensitivity $Sensitivity -ConfigType $ConfigType
    }
    
    # Vérifier si les changements sont significatifs
    $changeAnalysis = Test-SignificantChange -ConfigType $ConfigType -ConfigId $ConfigId -OldConfiguration $lastConfiguration -NewConfiguration $Configuration -Thresholds $thresholds -Detailed
    
    if (-not $changeAnalysis.is_significant -and -not $Force) {
        Write-Log "No significant changes detected for $ConfigType:$ConfigId. Skipping restore point creation." -Level "Info"
        return @{
            created = $false
            reason = "No significant changes"
            change_analysis = $changeAnalysis
        }
    }
    
    # Analyser l'impact des changements
    $impactAnalysis = Get-ChangeImpactAnalysis -ConfigType $ConfigType -ConfigId $ConfigId -OldConfiguration $lastConfiguration -NewConfiguration $Configuration -IncludeDependencies -IncludeReverseDependencies
    
    # Déterminer si un point de restauration doit être créé en fonction de l'impact
    $createPoint = $Force -or $changeAnalysis.is_significant
    $createReason = if ($Force) {
        "Forced creation"
    } elseif ($changeAnalysis.is_significant) {
        "Significant changes detected"
    } else {
        "No significant changes"
    }
    
    if ($createPoint) {
        Write-Log "Creating restore point for $ConfigType:$ConfigId - $createReason" -Level "Info"
        
        # Générer un nom par défaut si non fourni
        if ([string]::IsNullOrEmpty($Name)) {
            $Name = "Intelligent-$ConfigType-$ConfigId-$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        }
        
        # Générer une description par défaut si non fournie
        if ([string]::IsNullOrEmpty($Description)) {
            $Description = "Intelligent restore point created for $ConfigType:$ConfigId - $createReason"
            
            if ($changeAnalysis.is_significant) {
                $Description += " - Changes: $($changeAnalysis.global_change_percent)% global change, $($changeAnalysis.modified_count) modified, $($changeAnalysis.added_count) added, $($changeAnalysis.removed_count) removed"
            }
        }
        
        # Ajouter des tags basés sur l'analyse
        $Tags += "intelligent"
        
        if ($changeAnalysis.is_significant) {
            $Tags += "significant_changes"
            
            if ($changeAnalysis.global_change_percent -ge 50) {
                $Tags += "major_changes"
            } elseif ($changeAnalysis.global_change_percent -ge 30) {
                $Tags += "moderate_changes"
            } else {
                $Tags += "minor_changes"
            }
            
            if ($changeAnalysis.critical_changes.Count -gt 0) {
                $Tags += "critical_changes"
            }
        }
        
        # Créer le point de restauration
        $restorePoint = New-RestorePoint -ConfigType $ConfigType -ConfigId $ConfigId -Configuration $Configuration -Name $Name -Description $Description -Tags $Tags -Type "intelligent"
        
        if ($null -ne $restorePoint) {
            # Ajouter les informations d'analyse au point de restauration
            if (-not $restorePoint.PSObject.Properties.Name.Contains("analysis")) {
                $restorePoint | Add-Member -MemberType NoteProperty -Name "analysis" -Value @{
                    change_analysis = $changeAnalysis
                    impact_analysis = $impactAnalysis
                    thresholds = $thresholds
                }
            } else {
                $restorePoint.analysis = @{
                    change_analysis = $changeAnalysis
                    impact_analysis = $impactAnalysis
                    thresholds = $thresholds
                }
            }
            
            # Sauvegarder le point de restauration mis à jour
            $pointsPath = Get-RestorePointsPath
            $restorePointPath = Join-Path -Path $pointsPath -ChildPath "$($restorePoint.metadata.id).json"
            $restorePoint | ConvertTo-Json -Depth 10 | Out-File -FilePath $restorePointPath -Encoding UTF8
            
            # Définir l'importance du point de restauration
            Set-RestorePointImportance -RestorePointId $restorePoint.metadata.id -Importance "Auto"
            
            Write-Log "Restore point created successfully: $($restorePoint.metadata.id)" -Level "Info"
            return $restorePoint
        } else {
            Write-Log "Failed to create restore point" -Level "Error"
            return $false
        }
    } else {
        Write-Log "Skipping restore point creation for $ConfigType:$ConfigId - $createReason" -Level "Info"
        return @{
            created = $false
            reason = $createReason
            change_analysis = $changeAnalysis
            impact_analysis = $impactAnalysis
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    New-IntelligentRestorePoint -ConfigType $ConfigType -ConfigId $ConfigId -ConfigPath $ConfigPath -Configuration $Configuration -Name $Name -Description $Description -Tags $Tags -Sensitivity $Sensitivity -Force:$Force -SkipAnalysis:$SkipAnalysis
}
