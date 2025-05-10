# Register-DataMigrationTrigger.ps1
# Script pour enregistrer des déclencheurs de migrations de données
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourceType = "",
    
    [Parameter(Mandatory = $false)]
    [string]$TargetType = "",
    
    [Parameter(Mandatory = $false)]
    [int]$ThresholdCount = 0,
    
    [Parameter(Mandatory = $false)]
    [string]$TriggerName,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Condition,
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Action,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateRestorePoint = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$Enabled = $true,
    
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

# Importer le script d'enregistrement de déclencheur
$registerTriggerPath = Join-Path -Path $scriptPath -ChildPath "Register-RestoreTrigger.ps1"

if (Test-Path -Path $registerTriggerPath) {
    . $registerTriggerPath
} else {
    Write-Log "Required script not found: $registerTriggerPath" -Level "Error"
    exit 1
}

# Fonction pour générer un nom de déclencheur par défaut
function Get-DefaultTriggerName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SourceType = "",
        
        [Parameter(Mandatory = $false)]
        [string]$TargetType = ""
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    if ([string]::IsNullOrEmpty($SourceType) -and [string]::IsNullOrEmpty($TargetType)) {
        return "DataMigration-$timestamp"
    } elseif ([string]::IsNullOrEmpty($TargetType)) {
        $sourceShort = $SourceType -replace "[^a-zA-Z0-9]", ""
        
        if ($sourceShort.Length -gt 10) {
            $sourceShort = $sourceShort.Substring(0, 10)
        }
        
        return "DataMigration-$sourceShort-$timestamp"
    } else {
        $sourceShort = $SourceType -replace "[^a-zA-Z0-9]", ""
        $targetShort = $TargetType -replace "[^a-zA-Z0-9]", ""
        
        if ($sourceShort.Length -gt 10) {
            $sourceShort = $sourceShort.Substring(0, 10)
        }
        
        if ($targetShort.Length -gt 10) {
            $targetShort = $targetShort.Substring(0, 10)
        }
        
        return "DataMigration-$sourceShort-to-$targetShort-$timestamp"
    }
}

# Fonction pour créer une action de création de point de restauration
function New-RestorePointAction {
    [CmdletBinding()]
    param()
    
    $actionScript = @"
# Action de création de point de restauration
param(`$EventData)

# Importer le script de création de point de restauration
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$createRestorePointPath = Join-Path -Path `$scriptPath -ChildPath "..\..\New-RestorePoint.ps1"

if (Test-Path -Path `$createRestorePointPath) {
    . `$createRestorePointPath
} else {
    Write-Host "Required script not found: `$createRestorePointPath" -ForegroundColor Red
    return `$false
}

# Extraire les données de l'événement
`$sourceType = `$EventData.SourceType
`$targetType = `$EventData.TargetType
`$itemCount = `$EventData.ItemCount
`$migrationId = `$EventData.MigrationId
`$migrationDetails = `$EventData.MigrationDetails

# Générer un nom pour le point de restauration
`$restorePointName = "Pre-Migration-`$sourceType-to-`$targetType-`$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Créer le point de restauration
`$result = New-RestorePoint -Name `$restorePointName -Type "pre-migration" -Tags @("data-migration", `$sourceType, `$targetType) -Description "Pre-migration restore point for data migration from `$sourceType to `$targetType (`$itemCount items)" -SystemState @{
    source_type = `$sourceType
    target_type = `$targetType
    item_count = `$itemCount
    migration_id = `$migrationId
    migration_details = `$migrationDetails
}

return `$result
"@
    
    return [scriptblock]::Create($actionScript)
}

# Fonction pour créer une condition de vérification
function New-VerificationCondition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SourceType = "",
        
        [Parameter(Mandatory = $false)]
        [string]$TargetType = "",
        
        [Parameter(Mandatory = $false)]
        [int]$ThresholdCount = 0
    )
    
    $conditionScript = @"
# Condition de vérification
param(`$EventData)

# Vérifier si les données de l'événement sont valides
if (`$null -eq `$EventData) {
    return `$false
}

# Vérifier le type source si spécifié
if ('$SourceType' -ne '' -and `$EventData.SourceType -ne '$SourceType') {
    return `$false
}

# Vérifier le type cible si spécifié
if ('$TargetType' -ne '' -and `$EventData.TargetType -ne '$TargetType') {
    return `$false
}

# Vérifier le nombre d'éléments si un seuil est spécifié
if ($ThresholdCount -gt 0) {
    if (`$null -eq `$EventData.ItemCount -or `$EventData.ItemCount -lt $ThresholdCount) {
        return `$false
    }
}

return `$true
"@
    
    return [scriptblock]::Create($conditionScript)
}

# Fonction pour enregistrer un déclencheur de migration de données
function Register-DataMigrationTrigger {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SourceType = "",
        
        [Parameter(Mandatory = $false)]
        [string]$TargetType = "",
        
        [Parameter(Mandatory = $false)]
        [int]$ThresholdCount = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$TriggerName,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Condition,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Action,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateRestorePoint = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enabled = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Générer un nom de déclencheur par défaut si non fourni
    if ([string]::IsNullOrEmpty($TriggerName)) {
        $TriggerName = Get-DefaultTriggerName -SourceType $SourceType -TargetType $TargetType
    }
    
    # Générer une description par défaut si non fournie
    if ([string]::IsNullOrEmpty($Description)) {
        if ([string]::IsNullOrEmpty($SourceType) -and [string]::IsNullOrEmpty($TargetType)) {
            $Description = "Data migration trigger for all migrations"
        } elseif ([string]::IsNullOrEmpty($TargetType)) {
            $Description = "Data migration trigger for migrations from '$SourceType'"
        } else {
            $Description = "Data migration trigger for migrations from '$SourceType' to '$TargetType'"
        }
        
        if ($ThresholdCount -gt 0) {
            $Description += " with at least $ThresholdCount items"
        }
    }
    
    # Créer une condition par défaut si non fournie
    if ($null -eq $Condition) {
        $Condition = New-VerificationCondition -SourceType $SourceType -TargetType $TargetType -ThresholdCount $ThresholdCount
    }
    
    # Créer une action par défaut si non fournie et si CreateRestorePoint est activé
    if ($null -eq $Action -and $CreateRestorePoint) {
        $Action = New-RestorePointAction
    }
    
    # Créer les paramètres du déclencheur
    $parameters = @{}
    
    if (-not [string]::IsNullOrEmpty($SourceType)) {
        $parameters["SourceType"] = $SourceType
    }
    
    if (-not [string]::IsNullOrEmpty($TargetType)) {
        $parameters["TargetType"] = $TargetType
    }
    
    if ($ThresholdCount -gt 0) {
        $parameters["ThresholdCount"] = $ThresholdCount
    }
    
    # Enregistrer le déclencheur
    $result = Register-RestoreTrigger -TriggerType "DataMigration" -TriggerName $TriggerName -Description $Description -Parameters $parameters -Condition $Condition -Action $Action -Enabled:$Enabled -Force:$Force
    
    if ($result) {
        Write-Log "Data migration trigger registered successfully: $TriggerName" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to register data migration trigger: $TriggerName" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Register-DataMigrationTrigger -SourceType $SourceType -TargetType $TargetType -ThresholdCount $ThresholdCount -TriggerName $TriggerName -Description $Description -Condition $Condition -Action $Action -CreateRestorePoint:$CreateRestorePoint -Enabled:$Enabled -Force:$Force
}
