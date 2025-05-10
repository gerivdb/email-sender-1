# Register-BulkOperationTrigger.ps1
# Script pour enregistrer des déclencheurs d'opérations en masse
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Import", "Export", "Delete", "Update", "All")]
    [string]$OperationType = "All",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
    [string]$ConfigType = "All",
    
    [Parameter(Mandatory = $false)]
    [int]$ThresholdCount = 10,
    
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
        [Parameter(Mandatory = $true)]
        [string]$OperationType,
        
        [Parameter(Mandatory = $true)]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [int]$ThresholdCount
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    return "BulkOp-$OperationType-$ConfigType-$ThresholdCount-$timestamp"
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
`$operationType = `$EventData.OperationType
`$configType = `$EventData.ConfigType
`$itemCount = `$EventData.ItemCount
`$operationId = `$EventData.OperationId
`$operationDetails = `$EventData.OperationDetails

# Générer un nom pour le point de restauration
`$restorePointName = "Pre-BulkOp-`$operationType-`$configType-`$itemCount-`$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Créer le point de restauration
`$result = New-RestorePoint -Name `$restorePointName -Type "pre-bulk-operation" -Tags @("bulk-operation", `$operationType.ToLower(), `$configType.ToLower()) -Description "Pre-operation restore point for bulk `$operationType of `$itemCount `$configType items" -SystemState @{
    operation_type = `$operationType
    config_type = `$configType
    item_count = `$itemCount
    operation_id = `$operationId
    operation_details = `$operationDetails
}

return `$result
"@
    
    return [scriptblock]::Create($actionScript)
}

# Fonction pour créer une condition de vérification
function New-VerificationCondition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OperationType,
        
        [Parameter(Mandatory = $true)]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [int]$ThresholdCount
    )
    
    $conditionScript = @"
# Condition de vérification
param(`$EventData)

# Vérifier si les données de l'événement sont valides
if (`$null -eq `$EventData) {
    return `$false
}

# Vérifier le type d'opération
if ('$OperationType' -ne 'All' -and `$EventData.OperationType -ne '$OperationType') {
    return `$false
}

# Vérifier le type de configuration
if ('$ConfigType' -ne 'All' -and `$EventData.ConfigType -ne '$ConfigType') {
    return `$false
}

# Vérifier le nombre d'éléments
if (`$null -eq `$EventData.ItemCount -or `$EventData.ItemCount -lt $ThresholdCount) {
    return `$false
}

return `$true
"@
    
    return [scriptblock]::Create($conditionScript)
}

# Fonction pour enregistrer un déclencheur d'opération en masse
function Register-BulkOperationTrigger {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Import", "Export", "Delete", "Update", "All")]
        [string]$OperationType = "All",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All",
        
        [Parameter(Mandatory = $false)]
        [int]$ThresholdCount = 10,
        
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
        $TriggerName = Get-DefaultTriggerName -OperationType $OperationType -ConfigType $ConfigType -ThresholdCount $ThresholdCount
    }
    
    # Générer une description par défaut si non fournie
    if ([string]::IsNullOrEmpty($Description)) {
        $Description = "Bulk operation trigger for $OperationType operations on $ConfigType configurations with at least $ThresholdCount items"
    }
    
    # Créer une condition par défaut si non fournie
    if ($null -eq $Condition) {
        $Condition = New-VerificationCondition -OperationType $OperationType -ConfigType $ConfigType -ThresholdCount $ThresholdCount
    }
    
    # Créer une action par défaut si non fournie et si CreateRestorePoint est activé
    if ($null -eq $Action -and $CreateRestorePoint) {
        $Action = New-RestorePointAction
    }
    
    # Créer les paramètres du déclencheur
    $parameters = @{
        "OperationType" = $OperationType
        "ConfigType" = $ConfigType
        "ThresholdCount" = $ThresholdCount
    }
    
    # Enregistrer le déclencheur
    $result = Register-RestoreTrigger -TriggerType "BulkOperation" -TriggerName $TriggerName -Description $Description -Parameters $parameters -Condition $Condition -Action $Action -Enabled:$Enabled -Force:$Force
    
    if ($result) {
        Write-Log "Bulk operation trigger registered successfully: $TriggerName" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to register bulk operation trigger: $TriggerName" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Register-BulkOperationTrigger -OperationType $OperationType -ConfigType $ConfigType -ThresholdCount $ThresholdCount -TriggerName $TriggerName -Description $Description -Condition $Condition -Action $Action -CreateRestorePoint:$CreateRestorePoint -Enabled:$Enabled -Force:$Force
}
